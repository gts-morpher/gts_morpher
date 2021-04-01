package uk.ac.kcl.inf.gts_morpher.util

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
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
import org.eclipse.xtext.util.OnChangeEvictingCache
import uk.ac.kcl.inf.gts_morpher.composer.GTSComposer
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.EObjectReferenceParameter
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilyChoice
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilyReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilySpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSLiteral
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRef
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRefOrInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSelection
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationOrReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSWeave
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GtsMorpherFactory
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.NumericParameter
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.StringParameter
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.UnitCall
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.UnitParameter
import uk.ac.kcl.inf.gts_morpher.util.MultiResourceOnChangeEvictingCache.IClearableItem

import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.ModelCast

class GTSSpecificationHelper {

	static def getGtss (GTSSpecificationModule module) { module.members.filter(GTSSpecification) }
	static def getModelCasts (GTSSpecificationModule module) { module.members.filter(ModelCast) }
	
	static def getGts_families (GTSSpecificationModule module) { module.members.filter(GTSFamilySpecification) }
	
	static def getMappings (GTSSpecificationModule module) { module.members.filter(GTSMapping) }
	
	static dispatch def GTSSpecificationOrReference getRoot(Void gts) { null }
	static dispatch def GTSSpecificationOrReference getRoot(GTSFamilyChoice gfc) { gfc.family.root }
	static dispatch def GTSSpecificationOrReference getRoot(GTSFamilySpecification gfs) { gfs.root_gts }
	static dispatch def GTSSpecificationOrReference getRoot(GTSFamilyReference gfr) { gfr.ref.root }

	static dispatch def Module getTransformers(Void gts) { null }
	static dispatch def Module getTransformers(GTSFamilyChoice gfc) { gfc.family.transformers }
	static dispatch def Module getTransformers(GTSFamilySpecification gfs) { gfs.transformers }
	static dispatch def Module getTransformers(GTSFamilyReference gfr) { gfr.ref.transformers }

	static dispatch def GTSSpecificationOrReference getSource(Void spec) { null }
	static dispatch def GTSSpecificationOrReference getSource(GTSMappingRefOrInterfaceSpec spec) { null }
	static dispatch def GTSSpecificationOrReference getSource(GTSMappingRef ref) { ref.ref.source }
	static dispatch def GTSSpecificationOrReference getSource(GTSMappingInterfaceSpec spec) {
		// TODO: Should probably cache this suitably
		extension val GtsMorpherFactory factory = GtsMorpherFactory.eINSTANCE	
		
		val gtsref = createGTSReference => [
			ref = spec.gts_ref
		]
		createGTSSpecification => [
			interface_mapping = true
			gts = gtsref			
		]
	}

	static dispatch def GTSSpecificationOrReference getTarget(Void spec) { null }
	static dispatch def GTSSpecificationOrReference getTarget(GTSMappingRefOrInterfaceSpec spec) { null }
	static dispatch def GTSSpecificationOrReference getTarget(GTSMappingRef ref) { ref.ref.target }
	static dispatch def GTSSpecificationOrReference getTarget(GTSMappingInterfaceSpec spec) {
		// TODO: Should probably cache this suitably
		extension val GtsMorpherFactory factory = GtsMorpherFactory.eINSTANCE
		
		val gtsref = createGTSReference => [
			ref = spec.gts_ref
		]
		createGTSSpecification => [
			interface_mapping = false // interface_of means the source if interface, the target isn't
			gts = gtsref
		]
	}

	static dispatch def GTSSelection getGts(Void spec) { null }
	static dispatch def GTSSelection getGts(GTSSpecificationOrReference spec) { null }
	static dispatch def GTSSelection getGts(GTSReference ref) { ref.ref.gts } 
	static dispatch def GTSSelection getGts(GTSSpecification spec) { spec.gts }

	static dispatch def boolean getInterface_mapping(Void spec) { false }
	static dispatch def boolean getInterface_mapping(GTSSpecificationOrReference spec) { false }
	static dispatch def boolean getInterface_mapping(GTSReference ref) { ref.ref.interface_mapping } 
	static dispatch def boolean getInterface_mapping(GTSSpecification spec) { spec.interface_mapping }

	static dispatch def EPackage getMetamodel(Void spec) { null }
	static dispatch def EPackage getMetamodel(GTSSpecificationOrReference spec) { null }
	static dispatch def EPackage getMetamodel(GTSReference ref) { ref.ref.metamodel }
	static dispatch def EPackage getMetamodel(GTSSpecification spec) { spec.gts.metamodel }
	static dispatch def EPackage getMetamodel(GTSSelection gts) { null }
	static dispatch def EPackage getMetamodel(GTSLiteral gts) { gts.metamodel }
	static dispatch def EPackage getMetamodel(GTSFamilyChoice gts) { gts.derivePickedGTS.getTg() }
	static dispatch def EPackage getMetamodel(GTSWeave weave) { weave.derivedWovenGTS.getTg() }

	static dispatch def Module getBehaviour(Void spec) { null }
	static dispatch def Module getBehaviour(GTSSpecificationOrReference spec) { null }
	static dispatch def Module getBehaviour(GTSReference ref) { ref.ref.behaviour }
	static dispatch def Module getBehaviour(GTSSpecification spec) { spec.gts.behaviour }
	static dispatch def Module getBehaviour(GTSSelection gts) { null }
	static dispatch def Module getBehaviour(GTSLiteral gts) { gts.behaviour }
	static dispatch def Module getBehaviour(GTSFamilyChoice gts) { gts.derivePickedGTS.getRules() }
	static dispatch def Module getBehaviour(GTSWeave weave) { weave.derivedWovenGTS.getRules() }

	static val familyCache = new MultiResourceOnChangeEvictingCache
	static val weaveCache = new OnChangeEvictingCache

	static val extension GTSComposer composer = new GTSComposer

	static val WEAVING_CONTENTS_KEY = "WEAVING_CONTENTS_KEY"
	static val FAMILY_CONTENTS_KEY = "FAMILY_CONTENTS_KEY"
	static val SYNTHETIC_RESOURCE_BASE_NAME = "___gts_synthetic___"
	static val DERIVED_GTS_CONTENT_TYPE = GTSSpecificationHelper.name + ".DERIVED_GTS_CONTENT_TYPE"
	static val DERIVED_GTS_RESOURCE_FACTORY = new ResourceFactoryImpl

	static def derivedWovenGTS(GTSWeave weave) {
		// FIXME: Pair doesn't have a good hash method, so no good as a key
		weaveCache.get(new Pair(WEAVING_CONTENTS_KEY, weave), weave.eResource) [
			val result = weave.doCompose(IProgressMonitor.NULL_IMPL)
			
			val issues = result.a.map[new Issue() {
				override getMessage() {
					it.message
				}
			}].toList
			
			if (issues.empty) {
				val resource = weave.eResource.resourceSet.putInSyntheticResource(result.b, result.c)
				new GTSInfo(result.b, result.c, resource, issues)
			} else {
				new GTSInfo(null, null, null, issues)
			}		]
	}


	static interface Issue {
		def String getMessage()
	}
	static interface UnitCallIssue extends Issue {
		def UnitCall unitCall()
	}

	static dispatch def List<? extends Issue> getIssues(Void spec) { emptyList }
	static dispatch def List<? extends Issue> getIssues(GTSSpecification spec) { spec.gts.issues }
	static dispatch def List<? extends Issue> getIssues(GTSSelection gts) { emptyList }
	static dispatch def List<? extends Issue> getIssues(GTSLiteral gts) { emptyList }
	static dispatch def List<? extends Issue> getIssues(GTSFamilyChoice gts) { gts.derivePickedGTS.issues }
	static dispatch def List<? extends Issue> getIssues(GTSWeave weave) { weave.derivedWovenGTS.issues }

	@Data
	private static class GTSInfo implements IClearableItem {
		val EPackage tg
		val Module rules
		val Resource res
		val List<? extends Issue> issues
		
		override onClearedFromCache() {
			if (res !== null) {
				val resourceSet = res.resourceSet
				if (resourceSet !== null) {
					val resources = resourceSet.resources
					if (resources !== null) {
						resources.remove(res)
					}	
				}
			}
		}
	}
	
	static def GTSInfo derivePickedGTS(GTSFamilyChoice gts) {
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

					val issues = new ArrayList<UnitCallIssue >

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
										issues.add(new UnitCallIssue() {
											override getMessage() '''Could not resolve parameter «p.name».'''

											override unitCall() { transformerCall }
										})
										throw new InterruptedException
									}
								} catch (RuntimeException re) {
									// These are thrown by setParameterValue
									issues.add(new UnitCallIssue() {
										override getMessage() '''Could not set parameter: «re.message».'''

										override unitCall() { transformerCall }
									})
									throw new InterruptedException
								}
							]

							// Execute transformation step or throw exception if impossible (need to find a way to tie this into validation somehow)
							if (!unitRunner.execute(null)) {
								issues.add(new UnitCallIssue() {
									override getMessage() '''Could not apply transformer «transformerCall.unit.name».'''

									override unitCall() { transformerCall }
								})

								throw new InterruptedException
							}
						]
					} catch (InterruptedException ie) {
					}

					if (issues.empty) {
						val resource = gts.eResource.resourceSet.putInSyntheticResource(tg, rules)
 
						new GTSInfo(tg, rules, resource, issues)
					} else {
						new GTSInfo(gts.root.metamodel, gts.root.behaviour, null, issues)
					}
				} else {
					// No transformation specified, so nothing we can do...
					new GTSInfo(gts.root.metamodel, gts.root.behaviour, null, emptyList)
				}
			])
	}

	// See https://www.eclipse.org/forums/index.php/t/209411/ for a discussion of why this is needed
	private static def putInSyntheticResource(ResourceSet resourceSet, EPackage tg, Module rules) {
		val nameIdx = resourceSet.resources.fold(0)[ acc, r |
			if (r.URI.toString.startsWith(SYNTHETIC_RESOURCE_BASE_NAME)) {
				val idx = Integer.parseInt(r.URI.toString.substring(SYNTHETIC_RESOURCE_BASE_NAME.length))
				if (idx > acc) {
					return idx
				}
			}
			
			acc] + 1
			
		resourceSet.resourceFactoryRegistry.contentTypeToFactoryMap.put(DERIVED_GTS_CONTENT_TYPE, DERIVED_GTS_RESOURCE_FACTORY)
		val resource = resourceSet.createResource(URI.createFileURI(SYNTHETIC_RESOURCE_BASE_NAME + nameIdx), DERIVED_GTS_CONTENT_TYPE)
		resource.contents.addAll(#[tg, rules].reject[o | o === null].toList)
		
		resource
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
	private static dispatch def Object getParameterValue(NumericParameter p, List<EObject> graphRoots) { p.value }

	private static def EObject findWithQualifiedName(Module m, List<String> nameSegments) {
		val segments = new ArrayList(nameSegments)
		if ((segments.empty) || (!segments.remove(0).equals(m.name))) {
			return null
		}

		if (segments.empty) {
			return null
		}
		val unitName = segments.remove(0)

		val unit = m.units.findFirst[u|unitName.equals(u.name)]
		if (unit === null) {
			return null
		}

		if (segments.empty) {
			return unit
		}
		val elementName = segments.remove(0)

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
