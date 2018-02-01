package uk.ac.kcl.inf.composer

import com.google.inject.Inject
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.generator.IFileSystemAccess2
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import org.eclipse.xtext.validation.IResourceValidator
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.validation.CheckMode

import static extension uk.ac.kcl.inf.util.BasicMappingChecker.*
import static extension uk.ac.kcl.inf.util.EMFHelper.*

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
class XDsmlComposer {

	public interface Issue {
		def String getMessage()
	}

	private static class ExceptionIssue implements Issue {
		val Exception exception

		new(Exception e) {
			exception = e
		}

		override getMessage() '''Exception occurred during language composition: «exception.message».'''
	}

	private static class IssueIssue implements Issue {
		val org.eclipse.xtext.validation.Issue issue

		new(org.eclipse.xtext.validation.Issue issue) {
			this.issue = issue
		}

		override getMessage() '''«issue.severityLabel»: «issue.message» at «issue.lineNumber»:«issue.column».'''

		private def severityLabel(org.eclipse.xtext.validation.Issue issue) {
			switch (issue.severity) {
				case ERROR: return "Error"
				case WARNING: return "Warning"
				case INFO: return "Information"
				case IGNORE: return "Ignore"
				default: return ""
			}
		}
	}

	private static class MessageIssue implements Issue {
		val String message

		new(String message) {
			this.message = message
		}

		override getMessage() { message }
	}

	@Inject
	private IResourceValidator resourceValidator

	/**
	 * Perform the composition.
	 * 
	 * @param resource a resource with the morphism specification. If source is <code>interface_of</code> performs a 
	 * full pushout, otherwise assumes that interface and full language are identical for the source. Currently does 
	 * not support use of <code>interface_of</code> in the target GTS.
	 * 
	 * @param fsa used for file-system access
	 * 
	 * @return a list of issues that occurred when trying to do the composition. Empty rather than null if no issues have occurred.
	 */
	def List<Issue> doCompose(Resource resource, IFileSystemAccess2 fsa) {
		val result = new ArrayList<Issue>
		try {
			val issues = resourceValidator.validate(resource, CheckMode.ALL, CancelIndicator.NullImpl)

			if (!issues.empty) {
				result.addAll(issues.map[i|new IssueIssue(i)])
			} else {
				val mapping = resource.contents.head as GTSMapping

				if (mapping.target.interface_mapping) {
					result.add(new MessageIssue("Target GTS for a weave cannot currently be an interface_of mapping."))
				} else {
					// TODO Handle auto-complete and non-unique auto-completes
					val tgWeaver = new TGWeaver
					val composedTG = tgWeaver.weaveTG(mapping)
					val composedTGResource = resource.resourceSet.createResource(
						fsa.getURI(resource.URI.trimFileExtension.lastSegment + "_composed/tg.ecore"))
					composedTGResource.contents.clear
					composedTGResource.contents.add(composedTG)
					composedTGResource.save(emptyMap)

					val composedModule = mapping.composeBehaviour(tgWeaver)
					if (composedModule !== null) {
						val composedBehaviourResource = resource.resourceSet.createResource(
							fsa.getURI(resource.URI.trimFileExtension.lastSegment + "_composed/rules.henshin"))
						composedBehaviourResource.contents.clear
						composedBehaviourResource.contents.add(composedModule)
						composedBehaviourResource.save(emptyMap)
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace
			result.add(new ExceptionIssue(e))
		}

		result
	}

	private enum Origin {
		SOURCE,
		TARGET
	}

	private static def getLabel(Origin origin) {
		switch (origin) {
			case SOURCE: return "source"
			case TARGET: return "target"
			default: return ""
		}
	}

	private static def <T extends EObject> Pair<Origin, T> sourceKey(T object) { object.origKey(Origin.SOURCE) }

	private static def <T extends EObject> Pair<Origin, T> targetKey(T object) { object.origKey(Origin.TARGET) }

	private static def <T extends EObject> Pair<Origin, T> origKey(T object, Origin origin) { new Pair(origin, object) }

	/**
	 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
	 * will act as a Map from source EObjects to the corresponding woven EObjects. 
	 */
	private static class TGWeaver extends HashMap<Pair<Origin, EObject>, EObject> {
		/**
		 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
		 */
		def EPackage weaveTG(GTSMapping mapping) {
			// TODO Handle sub-packages?
			val EPackage result = EcoreFactory.eINSTANCE.createEPackage
			result.name = weaveNames(mapping.source.metamodel.name, mapping.target.metamodel.name)
			result.nsPrefix = weaveNames(mapping.source.metamodel.nsPrefix, mapping.target.metamodel.nsPrefix)
			// TODO We can probably do better here :-)
			result.nsURI = '''https://metamodel.woven/«mapping.source.metamodel.nsPrefix»/«mapping.target.metamodel.nsPrefix»'''
			put(mapping.source.metamodel.sourceKey, result)
			put(mapping.target.metamodel.targetKey, result)

			val tgMapping = mapping.typeMapping.extractMapping(null)

			weaveMappedElements(tgMapping, result)
			weaveUnmappedElements(mapping, tgMapping, result)

			weaveInheritance

			return result
		}

		private def weaveMappedElements(Map<EObject, EObject> tgMapping, EPackage composedPackage) {
			tgMapping.entrySet.filter[e|e.key instanceof EClass].forEach [ e |
				val EClass composed = composedPackage.createEClass(weaveNames(e.key.name, e.value.name))

				put(e.key.sourceKey, composed)
				put(e.value.targetKey, composed)
			]
			// Because the mapping is a morphism, this must work :-)
			tgMapping.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
				val EReference composed = createEReference(e.key as EReference, weaveNames(e.key.name, e.value.name))

				put(e.key.sourceKey, composed)
				put(e.value.targetKey, composed)
			]

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveUnmappedElements(GTSMapping mapping, Map<EObject, EObject> tgMapping,
			EPackage composedPackage) {
			// Deal with unmapped source elements
			mapping.source.metamodel.eAllContents.reject[eo|tgMapping.containsKey(eo)].toList.
				doWeaveUnmappedElements(composedPackage, Origin.SOURCE)

			// Deal with unmapped target elements
			mapping.target.metamodel.eAllContents.reject[eo|tgMapping.values.contains(eo)].toList.
				doWeaveUnmappedElements(composedPackage, Origin.TARGET)

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveInheritance() {
			keySet.filter[p|p.value instanceof EClass].forEach [ p |
				val composed = get(p) as EClass
				composed.ESuperTypes.addAll((p.value as EClass).ESuperTypes.map[ec2|get(ec2.origKey(p.key)) as EClass].
					reject [ ec2 |
						composed.ESuperTypes.contains(ec2)
					])
			]
		}

		private def doWeaveUnmappedElements(Iterable<EObject> unmappedElements, EPackage composedPackage,
			Origin origin) {
			unmappedElements.filter(EClass).forEach [ec|
				put(ec.origKey(origin), composedPackage.createEClass(ec.name.originName(origin)))
			]
			unmappedElements.filter(EReference).forEach [er|
				put(er.origKey(origin), er.createEReference(er.name.originName(origin), origin))
			]
		}

		private def createEClass(EPackage container, String name) {
			val EClass result = EcoreFactory.eINSTANCE.createEClass
			container.EClassifiers.add(result)
			result.name = name
			result
		}

		private def createEReference(EReference source, String name) {
			// Origin doesn't matter in this case
			createEReference(source, name, Origin.SOURCE)
		}

		private def createEReference(EReference source, String name, Origin origin) {
			val EReference result = EcoreFactory.eINSTANCE.createEReference;

			(get(source.EContainingClass.origKey(origin)) as EClass).EStructuralFeatures.add(result)
			result.EType = get(source.EType.origKey(origin)) as EClass

			result.name = name
			result.changeable = source.changeable
			result.containment = source.containment
			result.derived = source.derived
			result.EOpposite = get(source.EOpposite.origKey(origin)) as EReference
			result.lowerBound = source.lowerBound
			result.ordered = source.ordered
			result.transient = source.transient
			result.unique = source.unique
			result.unsettable = source.unsettable
			result.upperBound = source.upperBound
			result.volatile = source.volatile

			result
		}

		override EObject get(Object key) {
			if (key instanceof Pair) {
				if ((key.key instanceof Origin) && (key.value instanceof EObject)) {
					return super.get(key)
				}
			} else {
				throw new IllegalArgumentException("Requiring a pair in call to get!")
			}
		}
	}

	private def Module composeBehaviour(GTSMapping mapping, Map<Pair<Origin, EObject>, EObject> tgMapping) {
		if ((mapping.source.behaviour === null) || (mapping.target.behaviour === null)) {
			return null
		}

		val result = HenshinFactory.eINSTANCE.createModule
		result.description = weaveDescriptions(mapping.source.behaviour.description,
			mapping.target.behaviour.description)
		result.imports.add(tgMapping.get(mapping.source.metamodel.sourceKey) as EPackage)
		result.name = XDsmlComposer.weaveNames(mapping.source.behaviour.name, mapping.target.behaviour.name)

		val _mapping = mapping.behaviourMapping.extractMapping(null)

		result.units.addAll(_mapping.keySet.filter(Rule).map[r|r.createComposed(_mapping, tgMapping)])

		result
	}

	def Rule createComposed(Rule tgtRule, Map<EObject, EObject> behaviourMapping,
		Map<Pair<Origin, EObject>, EObject> tgMapping) {
		val srcRule = behaviourMapping.get(tgtRule) as Rule
		val result = HenshinFactory.eINSTANCE.createRule

		result.name = XDsmlComposer.weaveNames(tgtRule.name, srcRule.name)
		result.description = weaveDescriptions(tgtRule.description, srcRule.description)
		result.injectiveMatching = srcRule.injectiveMatching
		// TODO Should probably copy parameters, too
		result.lhs = new PatternWeaver(srcRule.lhs, tgtRule.lhs, behaviourMapping, tgMapping, "lhs").weavePattern
		result.rhs = new PatternWeaver(srcRule.rhs, tgtRule.rhs, behaviourMapping, tgMapping, "rhs").weavePattern

		// Weave kernel
		result.lhs.nodes.map [ n |
			val n2 = result.rhs.nodes.findFirst[n2|n.name.equals(n2.name)]
			if (n2 !== null) {
				new Pair(n, n2)
			} else {
				null
			}
		].reject[n|n === null].forEach [ p |
			result.mappings.add(HenshinFactory.eINSTANCE.createMapping(p.key, p.value))
		]

		result
	}

	/**
	 * Helper class for weaving a rule pattern. Acts as a map remembering the mappings established. 
	 */
	private static class PatternWeaver extends HashMap<Pair<Origin, GraphElement>, GraphElement> {

		private var Graph srcPattern
		private var Graph tgtPattern
		private var Map<EObject, EObject> behaviourMapping
		private var Map<Pair<Origin, EObject>, EObject> tgMapping

		private var Graph wovenGraph

		new(Graph srcPattern, Graph tgtPattern, Map<EObject, EObject> behaviourMapping,
			Map<Pair<Origin, EObject>, EObject> tgMapping, String patternLabel) {
			this.srcPattern = srcPattern
			this.tgtPattern = tgtPattern
			this.behaviourMapping = behaviourMapping.filter[key, value|key.eContainer == srcPattern]
			this.tgMapping = tgMapping

			wovenGraph = HenshinFactory.eINSTANCE.createGraph
			wovenGraph.name = patternLabel
		}

		def Graph weavePattern() {
			weaveMappedElements
			weaveUnmappedElements

			wovenGraph
		}

		private def weaveMappedElements() {
			behaviourMapping.entrySet.filter[e|e.key instanceof org.eclipse.emf.henshin.model.Node].forEach [ e |
				val composed = createNode(e.key as org.eclipse.emf.henshin.model.Node,
					weaveNames(e.key.name, e.value.name))

				put((e.key as org.eclipse.emf.henshin.model.Node).sourceKey, composed)
				put((e.value as org.eclipse.emf.henshin.model.Node).targetKey, composed)
			]
			behaviourMapping.entrySet.filter[e|e.key instanceof Edge].forEach [ e |
				val composed = createEdge(e.key as Edge)

				put((e.key as Edge).sourceKey, composed)
				put((e.value as Edge).targetKey, composed)
			]
		}

		private def weaveUnmappedElements() {
			srcPattern.nodes.reject[n|behaviourMapping.containsKey(n)].forEach [n |
				put(n.sourceKey, n.createNode(n.name.originName(Origin.SOURCE), Origin.SOURCE))
			]
			tgtPattern.nodes.reject[n|behaviourMapping.values.contains(n)].forEach [n |
				put(n.targetKey, n.createNode(n.name.originName(Origin.TARGET), Origin.TARGET))
			]

			srcPattern.edges.reject[e|behaviourMapping.containsKey(e)].forEach [e|
				put(e.sourceKey, e.createEdge(Origin.SOURCE))
			]
			tgtPattern.edges.reject[e|behaviourMapping.values.contains(e)].forEach [e|
				put(e.targetKey, e.createEdge(Origin.TARGET))
			]
		}

		private def org.eclipse.emf.henshin.model.Node createNode(org.eclipse.emf.henshin.model.Node nSrc,
			String name) {
			// Origin doesn't matter for mapped elements
			createNode(nSrc, name, Origin.SOURCE)
		}

		private def org.eclipse.emf.henshin.model.Node createNode(org.eclipse.emf.henshin.model.Node nSrc, String name,
			Origin origin) {
			val result = HenshinFactory.eINSTANCE.createNode

			result.name = name
			result.type = tgMapping.get(nSrc.type.origKey(origin)) as EClass

			wovenGraph.nodes.add(result)

			result
		}

		private def Edge createEdge(Edge eSrc) {
			// Origin doesn't matter for mapped elements
			createEdge(eSrc, Origin.SOURCE)
		}

		private def Edge createEdge(Edge eSrc, Origin origin) {
			val result = HenshinFactory.eINSTANCE.createEdge

			result.source = get(eSrc.source.origKey(origin)) as org.eclipse.emf.henshin.model.Node
			result.target = get(eSrc.target.origKey(origin)) as org.eclipse.emf.henshin.model.Node
			result.type = tgMapping.get(eSrc.type.origKey(origin)) as EReference

			wovenGraph.edges.add(result)

			result
		}

		override GraphElement get(Object key) {
			if (key instanceof Pair) {
				if ((key.key instanceof Origin) && (key.value instanceof GraphElement)) {
					return super.get(key)
				}
			} else {
				throw new IllegalArgumentException("Requiring a pair in call to get!")
			}
		}
	}

	private static def String weaveNames(CharSequence sourceName, CharSequence targetName) {
		if (sourceName === null) {
			if (targetName !== null) {
				targetName.toString
			} else {
				null
			}
		} else if ((targetName === null) || (sourceName.equals(targetName))) {
			sourceName.toString
		} else
			'''«sourceName»_«targetName»'''
	}

	private static def String weaveDescriptions(CharSequence sourceDescription, CharSequence targetDescription) {
		if (sourceDescription === null) {
			if (targetDescription !== null) {
				targetDescription.toString
			} else {
				null
			}
		} else if ((targetDescription === null) || (sourceDescription.equals(targetDescription))) {
			sourceDescription.toString
		} else
			'''Merged from «sourceDescription» and «targetDescription».'''
	}

	private static def String originName(String name, Origin origin) '''«origin.label»__«name»'''
}
