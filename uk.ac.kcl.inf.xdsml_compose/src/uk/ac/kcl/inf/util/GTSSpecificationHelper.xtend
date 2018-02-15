package uk.ac.kcl.inf.util

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceFactoryImpl
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.henshin.interpreter.Engine
import org.eclipse.emf.henshin.interpreter.impl.EGraphImpl
import org.eclipse.emf.henshin.interpreter.impl.EngineImpl
import org.eclipse.emf.henshin.interpreter.impl.UnitApplicationImpl
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.ParameterKind
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtend.lib.annotations.Data
import uk.ac.kcl.inf.xDsmlCompose.EObjectReferenceParameter
import uk.ac.kcl.inf.xDsmlCompose.GTSFamilyChoice
import uk.ac.kcl.inf.xDsmlCompose.GTSLiteral
import uk.ac.kcl.inf.xDsmlCompose.GTSSelection
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecification
import uk.ac.kcl.inf.xDsmlCompose.StringParameter
import uk.ac.kcl.inf.xDsmlCompose.UnitCall
import uk.ac.kcl.inf.xDsmlCompose.UnitParameter

import static extension uk.ac.kcl.inf.util.EMFHelper.*
import uk.ac.kcl.inf.util.MultiResourceOnChangeEvictingCache.IClearableItem

class GTSSpecificationHelper {
	static dispatch def EPackage getMetamodel(GTSSpecification spec) {
		spec.gts.metamodel
	}

	static dispatch def EPackage getMetamodel(GTSSelection gts) { null }

	static dispatch def EPackage getMetamodel(GTSLiteral gts) { gts.metamodel }

	static dispatch def EPackage getMetamodel(GTSFamilyChoice gts) {
		gts.derivePickedGTS.tg
	}

	static dispatch def EPackage getMetamodel(Void spec) { null }

	static dispatch def Module getBehaviour(GTSSpecification spec) {
		spec.gts.behaviour
	}

	static dispatch def Module getBehaviour(GTSSelection gts) { null }

	static dispatch def Module getBehaviour(GTSLiteral gts) { gts.behaviour }

	static dispatch def Module getBehaviour(GTSFamilyChoice gts) {
		gts.derivePickedGTS.rules
	}

	static dispatch def Module getBehaviour(Void spec) { null }

	private static val familyCache = new MultiResourceOnChangeEvictingCache
	private static val FAMILY_CONTENTS_KEY = "FAMILY_CONTENTS_KEY"
	private static val SYNTHETIC_RESOURCE_BASE_NAME = "___gts_synthetic___"
	private static val DERIVED_GTS_CONTENT_TYPE = GTSSpecificationHelper.name + ".DERIVED_GTS_CONTENT_TYPE"
	private static val DERIVED_GTS_RESOURCE_FACTORY = new ResourceFactoryImpl

	static interface Issue {
		def String getMessage()

		def UnitCall unitCall()
	}

	@Data
	private static class PickedGTSInfo implements IClearableItem {
		private val EPackage tg
		private val Module rules
		private val List<Issue> issues
		private val Resource res
		
		override onClearedFromCache() {
			if (res !== null) {
				res.resourceSet.resources.remove(res)
			}
		}
	}

	static def PickedGTSInfo derivePickedGTS(GTSFamilyChoice gts) {
		familyCache.get(new Pair(FAMILY_CONTENTS_KEY, gts),
			getSetOfResources(gts.root.metamodel, gts.root.behaviour, gts.transformers), [
				if ((gts.transformers !== null) && (!gts.transformationSteps.steps.empty)) {
					// Create a copy of the metamodel and behaviour (if any) from the specification ready to be transformed
					val copier = new EcoreUtil.Copier

					val tg = copier.copy(gts.root.metamodel) as EPackage
					val rules = copier.copy(gts.root.behaviour) as Module

					copier.copyReferences

					val engine = new EngineImpl
					engine.options.put(Engine.OPTION_DETERMINISTIC, false)
					val graph = new EGraphImpl(#[tg, rules].filter[eo|eo !== null].toList)

					val issues = new ArrayList<Issue>

					try {
						gts.transformationSteps.steps.forEach [ transformerCall |
							// Invoke the unit as specified
							val unitRunner = new UnitApplicationImpl(engine)
							unitRunner.EGraph = graph
							unitRunner.unit = transformerCall.unit
							transformerCall.unit.parameters.filter [p |
								(p.kind === ParameterKind.IN) || (p.kind === ParameterKind.INOUT)
							].forEach [ p, idx |
								try {
									val actualParameter = transformerCall.params.parameters.get(idx)
									val parameterValue = actualParameter.getParameterValue(graph.roots)
									if (parameterValue !== null) {
										unitRunner.setParameterValue(p.name, parameterValue)
									} else {
										issues.add(new Issue() {
											override getMessage() '''Could not resolve parameter «p.name».'''

											override unitCall() { transformerCall }
										})
										throw new InterruptedException
									}
								} catch (RuntimeException re) {
									// These are thrown by setParameterValue
									issues.add(new Issue() {
										override getMessage() '''Could not set parameter: «re.message».'''

										override unitCall() { transformerCall }
									})
									throw new InterruptedException
								}
							]

							// Execute transformation step or throw exception if impossible (need to find a way to tie this into validation somehow)
							if (!unitRunner.execute(null)) {
								issues.add(new Issue() {
									override getMessage() '''Could not apply transformer «transformerCall.unit.name».'''

									override unitCall() { transformerCall }
								})

								throw new InterruptedException
							}
						]
					} catch (InterruptedException ie) {
					}

					if (issues.empty) {
						// Add the newly created elements to a fresh synthetic resource
						// See https://www.eclipse.org/forums/index.php/t/209411/ for a discussion of why
						val resourceSet = gts.eResource.resourceSet
						val nameIdx = resourceSet.resources.fold(
							0,
							[ acc, r |
								if (r.URI.toString.startsWith(SYNTHETIC_RESOURCE_BASE_NAME)) {
									val idx = Integer.parseInt(
										r.URI.toString.substring(SYNTHETIC_RESOURCE_BASE_NAME.length))
									if (idx > acc) {
										return idx
									}
								}

								acc
							]
						) + 1
						
						resourceSet.resourceFactoryRegistry.contentTypeToFactoryMap.put(DERIVED_GTS_CONTENT_TYPE, DERIVED_GTS_RESOURCE_FACTORY)
						val resource = resourceSet.createResource(URI.createFileURI(SYNTHETIC_RESOURCE_BASE_NAME + nameIdx), DERIVED_GTS_CONTENT_TYPE)
						resource.contents.addAll(#[tg, rules].reject[o | o === null].toList)
 
						new PickedGTSInfo(tg, rules, issues, resource)
					} else {
						// FIXME: null is not a good choice for the first two parameters here. Perhaps use the original metamodel and rules instead?
						new PickedGTSInfo(null, null, issues, null)
					}
				} else {
					// No transformation specified, so nothing we can do...
					new PickedGTSInfo(gts.root.metamodel, gts.root.behaviour, emptyList, null)
				}
			])
	}

	private static dispatch def Object getParameterValue(Void p, List<EObject> graphRoots) { null }

	private static dispatch def Object getParameterValue(UnitParameter p, List<EObject> graphRoots) { null }

	private static dispatch def Object getParameterValue(EObjectReferenceParameter p, List<EObject> graphRoots) {
		val nameSegments = new ArrayList<String>(p.qualifiedName.split('\\.'))

		val tg = graphRoots.filter(EPackage).head
		if (nameSegments.head == tg.name) {
			// Resolve object from tg
			// TODO Should probably actually refer to the relevant qualified name provider / resource description etc.
			return tg.findWithQualifiedName(p.qualifiedName)
		} else {
			val rules = graphRoots.filter(Module).head

			if (rules !== null) {
				if (nameSegments.head == rules.name) {
					// Resolve object from rule set
					// TODO Should probably actually refer to the relevant qualified name provider / resource description etc.
					return rules.findWithQualifiedName(nameSegments)
				}
			}
		}

		null
	}

	private static dispatch def Object getParameterValue(StringParameter p, List<EObject> graphRoots) { p.value }

	private static def EObject findWithQualifiedName(Module m, List<String> nameSegments) {
		val segments = new ArrayList(nameSegments)
		if (!segments.remove(0).equals(m.name)) {
			return null
		}

		val unitName = segments.remove(0)
		if (unitName === null) {
			return null
		}

		val unit = m.units.findFirst[u|unitName.equals(u.name)]

		if (unit === null) {
			return null
		}

		val elementName = segments.remove(0)
		if (elementName === null) {
			return unit
		}

		if (unit instanceof Rule) {
			// TODO: We should probably actually change this to return all elements of this name...
			val lhsNodes = unit.lhs.nodes.findFirst[n|elementName.equals(n.name)]
			val rhsNodes = unit.rhs.nodes.findFirst[n|elementName.equals(n.name)]
			val lhsEdges = unit.lhs.edges.findFirst[e|elementName.equals(e.name)]
			val rhsEdges = unit.rhs.edges.findFirst[e|elementName.equals(e.name)]

			#[lhsNodes, rhsNodes, lhsEdges, rhsEdges].filter[o|o !== null].head
		} else {
			null
		}
	}

	private static def getSetOfResources(EPackage metamodel, Module behaviour, Module transformers) {
		val resources = new HashSet<Resource>
		#[metamodel, behaviour, transformers].forEach [ eo |
			if (eo !== null) {
				resources.add(eo.eResource)
			}
		]

		resources
	}
}
