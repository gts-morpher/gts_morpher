package uk.ac.kcl.inf.composer

import com.google.inject.Inject
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.function.Function
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
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.util.MorphismCompleter
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static extension uk.ac.kcl.inf.util.BasicMappingChecker.*
import static extension uk.ac.kcl.inf.util.EMFHelper.*
import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
class XDsmlComposer {

	public interface Issue {
		def String getMessage()
	}

	private static class ExceptionIssue implements XDsmlComposer.Issue {
		val Exception exception

		new(Exception e) {
			exception = e
		}

		override getMessage() '''Exception occurred during language composition: �exception.message�.'''
	}

	private static class IssueIssue implements XDsmlComposer.Issue {
		val org.eclipse.xtext.validation.Issue issue

		new(org.eclipse.xtext.validation.Issue issue) {
			this.issue = issue
		}

		override getMessage() '''�issue.severityLabel�: �issue.message� at �issue.lineNumber�:�issue.column�.'''

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

	private static class MessageIssue implements XDsmlComposer.Issue {
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
	def List<XDsmlComposer.Issue> doCompose(Resource resource, IFileSystemAccess2 fsa, IProgressMonitor monitor) {
		val result = new ArrayList<XDsmlComposer.Issue>
		val _monitor = monitor.convert(4)
		try {
			val issues = resourceValidator.validate(resource, CheckMode.ALL, _monitor.split("Validating resource.", 1))

			if (!issues.empty) {
				result.addAll(issues.map[i|new IssueIssue(i)])
			} else {
				val mapping = resource.contents.head as GTSMapping

				if (mapping.target.interface_mapping) {
					result.add(new MessageIssue("Target GTS for a weave cannot currently be an interface_of mapping."))
				} else {
					var tgMapping = mapping.typeMapping.extractMapping(null)
					var behaviourMapping = mapping.behaviourMapping.extractMapping(null)

					if (mapping.autoComplete) {
						_monitor.split("Autocompleting.", 1)
						
						if (!mapping.uniqueCompletion) {
							result.add(new MessageIssue("Can only weave based on unique auto-completions."))
							return result
						}

						// Auto-complete
						val completer = new MorphismCompleter(tgMapping, mapping.source.metamodel, mapping.target.metamodel, 
			                                  behaviourMapping, mapping.source.behaviour, mapping.target.behaviour,
											  mapping.source.interface_mapping, mapping.target.interface_mapping)
						if (completer.findMorphismCompletions(false) == 0) {
							if (completer.completedMappings.size == 1) {
								tgMapping = new HashMap(completer.completedMappings.head.filter[k, v | (k instanceof EClass) || (k instanceof EReference)] as Map<EObject, EObject>)
								behaviourMapping = new HashMap(completer.completedMappings.head.filter[k, v | !((k instanceof EClass) || (k instanceof EReference))] as Map<EObject, EObject>)
							} else {
								result.add(new MessageIssue("There is no unique auto-completion for this morphism."))
								return result								
							}
						} else {
							result.add(new MessageIssue("Was unable to auto-complete the morphism."))
							return result
						}
					} else {
						_monitor.split("", 1)
					}

					// Weave
					_monitor.split("Composing type graph.", 1)
					val tgWeaver = new TGWeaver
					val composedTG = tgWeaver.weaveTG(tgMapping, mapping.source.metamodel, mapping.target.metamodel)
					composedTG.saveModel(fsa, resource, "tg.ecore")

					_monitor.split("Composing rules.", 1)
					val composedModule = composeBehaviour(mapping.source.behaviour, mapping.target.behaviour, behaviourMapping, mapping.source.metamodel, tgWeaver)
					if (composedModule !== null) {
						composedModule.saveModel(fsa, resource, "rules.henshin")
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace
			result.add(new ExceptionIssue(e))
		}

		result
	}
	
	private def void saveModel(EObject model, IFileSystemAccess2 fsa, Resource baseResource, String fileName) {
		val composedTGResource = baseResource.resourceSet.createResource(
			fsa.getURI(baseResource.URI.trimFileExtension.lastSegment + "_composed/" + fileName))
		composedTGResource.contents.clear
		composedTGResource.contents.add(model)
		composedTGResource.save(emptyMap)
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
		def EPackage weaveTG(Map<EObject, EObject> tgMapping, EPackage srcPackage, EPackage tgtPackage) {
			// TODO Handle sub-packages?
			val EPackage result = EcoreFactory.eINSTANCE.createEPackage
			result.name = weaveNames(srcPackage.name, tgtPackage.name)
			result.nsPrefix = weaveNames(srcPackage.nsPrefix, tgtPackage.nsPrefix)
			// TODO We can probably do better here :-)
			result.nsURI = '''https://metamodel.woven/�srcPackage.nsPrefix�/�tgtPackage.nsPrefix�'''
			put(srcPackage.sourceKey, result)
			put(tgtPackage.targetKey, result)

			weaveMappedElements(tgMapping, result)
			weaveUnmappedElements(srcPackage, tgtPackage, tgMapping, result)

			weaveInheritance

			return result
		}

		private def weaveMappedElements(Map<EObject, EObject> tgMapping, EPackage composedPackage) {
			// Build inverted index so that we can merge objects as required
			val invertedIndex = new HashMap<EObject, List<EObject>>()
			tgMapping.forEach[k, v|
				invertedIndex.putIfAbsent(v, new ArrayList<EObject>)
				invertedIndex.get(v).add(k)
			]
			
			// Now build mappings from inverted index
			invertedIndex.entrySet.filter[e | e.key instanceof EClass].forEach[e |
				val EClass composed = e.value.createWithWovenName(e.key.name.toString, [n | composedPackage.createEClass(n)])
							
				put(e.key.targetKey, composed)
				e.value.forEach[eo | put(eo.sourceKey, composed)]
			]
//			tgMapping.entrySet.filter[e|e.key instanceof EClass].forEach [ e |
//				val EClass composed = composedPackage.createEClass(weaveNames(e.key.name, e.value.name))
//
//				put(e.key.sourceKey, composed)
//				put(e.value.targetKey, composed)
//			]
			// Because the mapping is a morphism, this must work :-)
			invertedIndex.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
				val EReference composed = e.value.createWithWovenName(e.key.name.toString, [n | createEReference(e.key as EReference, n)])
				
				put(e.key.targetKey, composed)
				e.value.forEach[eo | put(eo.sourceKey, composed)]
			]
//			tgMapping.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
//				val EReference composed = createEReference(e.key as EReference, weaveNames(e.key.name, e.value.name))
//
//				put(e.key.sourceKey, composed)
//				put(e.value.targetKey, composed)
//			]

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveUnmappedElements(EPackage srcPackage, EPackage tgtPackage, Map<EObject, EObject> tgMapping,
			EPackage composedPackage) {
			// Deal with unmapped source elements
			srcPackage.eAllContents.reject[eo|tgMapping.containsKey(eo)].toList.
				doWeaveUnmappedElements(composedPackage, Origin.SOURCE)

			// Deal with unmapped target elements
			tgtPackage.eAllContents.reject[eo|tgMapping.values.contains(eo)].toList.
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
			// Origin doesn't matter in this case, but must be TARGET because we've previously decided to copy from target references
			createEReference(source, name, Origin.TARGET)
		}

		private def createEReference(EReference source, String name, Origin origin) {
			val EReference result = EcoreFactory.eINSTANCE.createEReference;

			(get(source.EContainingClass.origKey(origin)) as EClass).EStructuralFeatures.add(result)
			result.EType = get(source.EType.origKey(origin)) as EClass

			result.name = name
			result.changeable = source.changeable
			result.containment = source.containment
			result.derived = source.derived
			val opposite = get(source.EOpposite.origKey(origin)) as EReference
			if (opposite !== null) {
				result.EOpposite = opposite
				opposite.EOpposite = result			
			}
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

	private def Module composeBehaviour(Module srcBehaviour, Module tgtBehaviour, Map<EObject, EObject> behaviourMapping, EPackage srcPackage, Map<Pair<Origin, EObject>, EObject> tgMapping) {
		if ((srcBehaviour === null) || (tgtBehaviour === null)) {
			return null
		}

		val result = HenshinFactory.eINSTANCE.createModule
		result.description = weaveDescriptions(srcBehaviour.description,
			tgtBehaviour.description)
		result.imports.add(tgMapping.get(srcPackage.sourceKey) as EPackage)
		result.name = XDsmlComposer.weaveNames(srcBehaviour.name, tgtBehaviour.name)

		result.units.addAll(behaviourMapping.keySet.filter(Rule).map[r|r.createComposed(behaviourMapping, tgMapping)])

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
		result.lhs = new PatternWeaver(srcRule.lhs, tgtRule.lhs, behaviourMapping, tgMapping, "Lhs").weavePattern
		result.rhs = new PatternWeaver(srcRule.rhs, tgtRule.rhs, behaviourMapping, tgMapping, "Rhs").weavePattern

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
			// TODO: Construct inverted index, then compose from that
			val invertedIndex = new HashMap<EObject, List<EObject>>()
			behaviourMapping.forEach[k, v|
				invertedIndex.putIfAbsent(v, new ArrayList<EObject>)
				invertedIndex.get(v).add(k)
			]
			
			invertedIndex.entrySet.filter[e|e.key instanceof org.eclipse.emf.henshin.model.Node].forEach [ e |
				val composed = e.value.createWithWovenName(e.key.name.toString, [n | createNode(e.key as org.eclipse.emf.henshin.model.Node, n)])
							
				put((e.key as org.eclipse.emf.henshin.model.Node).targetKey, composed)
				e.value.forEach[eo | put((eo as org.eclipse.emf.henshin.model.Node).sourceKey, composed)]
			]			
//			behaviourMapping.entrySet.filter[e|e.key instanceof org.eclipse.emf.henshin.model.Node].forEach [ e |
//				val composed = createNode(e.key as org.eclipse.emf.henshin.model.Node,
//					weaveNames(e.key.name, e.value.name))
//
//				put((e.key as org.eclipse.emf.henshin.model.Node).sourceKey, composed)
//				put((e.value as org.eclipse.emf.henshin.model.Node).targetKey, composed)
//			]

			invertedIndex.entrySet.filter[e|e.key instanceof Edge].forEach [ e |
				val composed = createEdge(e.key as Edge)
				
				put((e.key as Edge).targetKey, composed)
				e.value.forEach[eo | put((eo as Edge).sourceKey, composed)]
			]
//			behaviourMapping.entrySet.filter[e|e.key instanceof Edge].forEach [ e |
//				val composed = createEdge(e.key as Edge)
//
//				put((e.key as Edge).sourceKey, composed)
//				put((e.value as Edge).targetKey, composed)
//			]
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
			// Origin doesn't matter for mapped elements, must be target because we've decided to copy data from target TG
			createNode(nSrc, name, Origin.TARGET)
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
			// Origin doesn't matter for mapped elements, must be target because we've decided to copy data from target edge
			createEdge(eSrc, Origin.TARGET)
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

	private static def <T extends EObject> T createWithWovenName(List<? extends EObject> objects, String startName, Function<String, T> creator) {
		creator.apply(objects.map[eo | eo.name.toString].sort.reverseView.fold(startName, [acc, n | weaveNames(n, acc)]))
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
			'''�sourceName�_�targetName�'''
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
			'''Merged from �sourceDescription� and �targetDescription�.'''
	}

	private static def String originName(String name, Origin origin) '''�origin.label�__�name�'''
}