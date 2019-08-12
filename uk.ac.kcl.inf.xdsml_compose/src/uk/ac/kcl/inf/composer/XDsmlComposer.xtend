package uk.ac.kcl.inf.composer

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.function.Function
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.ENamedElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.InternalEObject
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Rule
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.util.Triple
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMappingInterfaceSpec
import uk.ac.kcl.inf.xDsmlCompose.GTSMappingRef
import uk.ac.kcl.inf.xDsmlCompose.GTSWeave

import static extension uk.ac.kcl.inf.util.EMFHelper.*
import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.util.MappingConverter.*
import static extension uk.ac.kcl.inf.util.MorphismCompleter.createMorphismCompleter
import uk.ac.kcl.inf.xDsmlCompose.WeaveOption

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
class XDsmlComposer {

	interface Issue {
		def String getMessage()
	}

	private static class ExceptionIssue implements XDsmlComposer.Issue {
		val Exception exception

		new(Exception e) {
			exception = e
		}

		override getMessage() '''Exception occurred during language composition: «exception.message».'''
	}

	private static class IssueIssue implements XDsmlComposer.Issue {
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

	private static class MessageIssue implements XDsmlComposer.Issue {
		val String message

		new(String message) {
			this.message = message
		}

		override getMessage() { message }
	}

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
	def Triple<List<XDsmlComposer.Issue>, EPackage, Module> doCompose(GTSWeave weaving, IProgressMonitor monitor) {
		val result = new ArrayList<XDsmlComposer.Issue>
		var Module composedModule = null
		var EPackage composedTG = null

		try {
			val _monitor = monitor.convert(4)

			// TODO: Should probably validate weaving before going on...
			// Assume one mapping is an interface_of mapping, then find the other one and use it to do the weave
			var GTSMapping mapping
			if (weaving.mapping1 instanceof GTSMappingInterfaceSpec) {
				mapping = (weaving.mapping2 as GTSMappingRef).ref
			} else {
				mapping = (weaving.mapping1 as GTSMappingRef).ref
			}

			if (mapping.target.interface_mapping) {
				result.add(new MessageIssue("Target GTS for a weave cannot currently be an interface_of mapping."))
			} else {
				var tgMapping = mapping.typeMapping.extractMapping(null)
				var behaviourMapping = mapping.behaviourMapping.extractMapping(tgMapping, null)

				if (mapping.autoComplete) {
					_monitor.split("Autocompleting.", 1)

					if (!mapping.uniqueCompletion) {
						result.add(new MessageIssue("Can only weave based on unique auto-completions."))
						return new Triple(result, null, null)
					}

					// Auto-complete
					val completer = mapping.createMorphismCompleter
					if (completer.findMorphismCompletions(false) == 0) {
						if (completer.completedMappings.size == 1) {
							tgMapping = new HashMap(completer.completedMappings.head.filter [ k, v |
								(k instanceof EClass) || (k instanceof EReference) || (k instanceof EAttribute)
							] as Map<EObject, EObject>)
							behaviourMapping = new HashMap(completer.completedMappings.head.filter [ k, v |
								!((k instanceof EClass) || (k instanceof EReference || (k instanceof EAttribute)))
							] as Map<EObject, EObject>)
						} else {
							result.add(new MessageIssue("There is no unique auto-completion for this morphism."))
							return new Triple(result, null, null)
						}
					} else {
						result.add(new MessageIssue("Was unable to auto-complete the morphism."))
						return new Triple(result, null, null)
					}
				} else {
					_monitor.split("", 1)
				}

				val namingStrategy = weaving.options.fold(new DefaultNamingStrategy as NamingStrategy, [acc, opt | opt.generateNamingStrategy(acc)]) 
				
				// Weave
				_monitor.split("Composing type graph.", 1)
				val tgWeaver = new TGWeaver
				composedTG = tgWeaver.weaveTG(tgMapping, mapping.source.metamodel, mapping.target.metamodel, namingStrategy)

				_monitor.split("Composing rules.", 1)
				composedModule = composeBehaviour(mapping.source.behaviour, mapping.target.behaviour, behaviourMapping,
					mapping.source.metamodel, tgWeaver, namingStrategy)
			}
		} catch (Exception e) {
			result.add(new ExceptionIssue(e))
			e.printStackTrace
		}

		new Triple(result, composedTG, composedModule)
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
	 * A strategy to use when deciding on the names of new model elements created by composition.
	 */
	private static interface NamingStrategy {
		/**
		 * TODO: This will need to be enriched with some sort of context information to allow checking whether the name-weaving rule would create duplicate names.
		 */
		def String weaveNames(CharSequence srcName, CharSequence tgtName)
		def String weaveURIs(EPackage srcPackage, EPackage tgtPackage)
	}
	
	private static class DefaultNamingStrategy implements NamingStrategy {
		override String weaveNames(CharSequence sourceName, CharSequence targetName) {
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

		// TODO We can probably do better here :-)
		override String weaveURIs(EPackage srcPackage, EPackage tgtPackage) '''https://metamodel.woven/«srcPackage.nsPrefix»/«tgtPackage.nsPrefix»'''			
	}

	private static class PreferTargetNames implements NamingStrategy {
		val NamingStrategy fallback
		
		new (NamingStrategy fallback) {
			this.fallback = fallback
		}
		
		override String weaveNames(CharSequence sourceName, CharSequence targetName) {
			// FIXME: May need to fall back on fallback if choosing this name would produce a violation of uniqueness constraints
			targetName.toString
		}		

		override String weaveURIs(EPackage srcPackage, EPackage tgtPackage) {
			tgtPackage.nsURI
		}			
	}
	
	private def NamingStrategy generateNamingStrategy(WeaveOption option, NamingStrategy existingStrategy) {
		switch (option) {
			case DONT_LABEL_NON_KERNEL_ELEMENTS:
				return existingStrategy
			case PREFER_KERNEL_NAMES:
				return existingStrategy
			// FIXME: This isn't correct: need to take into account what map1 and map2 actually are and differentiate the naming accordingly.
			case PREFER_MAP1_TARGET_NAMES:
				return new PreferTargetNames(existingStrategy)
			case PREFER_MAP2_TARGET_NAMES:
				return new PreferTargetNames(existingStrategy)
			default:
				return existingStrategy
		}
	}

	/**
	 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
	 * will act as a Map from source EObjects to the corresponding woven EObjects. 
	 */
	private static class TGWeaver extends HashMap<Pair<Origin, EObject>, EObject> {
		/**
		 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
		 */
		def EPackage weaveTG(Map<EObject, EObject> tgMapping, EPackage srcPackage, EPackage tgtPackage, extension NamingStrategy naming) {
			// TODO Handle sub-packages?
			val EPackage result = EcoreFactory.eINSTANCE.createEPackage => [
				name = weaveNames(srcPackage.name, tgtPackage.name)
				nsPrefix = weaveNames(srcPackage.nsPrefix, tgtPackage.nsPrefix)
				nsURI = weaveURIs(srcPackage, tgtPackage)				
			]
			
			put(srcPackage.sourceKey, result)
			put(tgtPackage.targetKey, result)

			val invertedIndex = tgMapping.invertedIndex
			val unmappedSrcElements = srcPackage.eAllContents.reject[eo|tgMapping.containsKey(eo)].toList
			val unmappedTgtElements = tgtPackage.eAllContents.reject[eo|tgMapping.values.contains(eo)].toList
			weaveClasses(invertedIndex, unmappedSrcElements, unmappedTgtElements, result, naming)
			weaveInheritance
			weaveReferences(invertedIndex, unmappedSrcElements, unmappedTgtElements, naming)
			weaveAttributes(invertedIndex, unmappedSrcElements, unmappedTgtElements, naming)

			return result
		}

		private def invertedIndex(Map<EObject, EObject> tgMapping) {
			// Build inverted index so that we can merge objects as required
			val invertedIndex = new HashMap<EObject, List<EObject>>()
			tgMapping.forEach [ k, v |
				invertedIndex.putIfAbsent(v, new ArrayList<EObject>)
				invertedIndex.get(v).add(k)
			]
			invertedIndex
		}

		private def weaveClasses(Map<EObject, List<EObject>> invertedIndex, List<EObject> unmappedSrcElements,
			List<EObject> unmappedTgtElements, EPackage composedPackage, NamingStrategy naming) {
			// Weave from inverted index for mapped classes 
			invertedIndex.entrySet.filter[e|e.key instanceof EClass].forEach [ e |
				val EClass composed = e.value.createWithWovenName(e.key.name.toString, [ n |
					composedPackage.createEClass(n)
				], naming)

				put(e.key.targetKey, composed)
				e.value.forEach[eo|put(eo.sourceKey, composed)]
			]

			// Create copies for all unmapped classes
			composedPackage.createForEachEClass(unmappedSrcElements, Origin.SOURCE)
			composedPackage.createForEachEClass(unmappedTgtElements, Origin.TARGET)
		}

		private def weaveReferences(Map<EObject, List<EObject>> invertedIndex, List<EObject> unmappedSrcElements,
			List<EObject> unmappedTgtElements, NamingStrategy naming) {
			// Weave mapped references
			// Because the mapping is a morphism, this must work :-)
			invertedIndex.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
				val EReference composed = e.value.createWithWovenName(e.key.name.toString, [ n |
					createEReference(e.key as EReference, n)
				], naming)

				put(e.key.targetKey, composed)
				e.value.forEach[eo|put(eo.sourceKey, composed)]
			]

			// Create copied for unmapped references
			unmappedSrcElements.createForEachEReference(Origin.SOURCE)
			unmappedTgtElements.createForEachEReference(Origin.TARGET)
		}

		private def weaveAttributes(Map<EObject, List<EObject>> invertedIndex, List<EObject> unmappedSrcElements,
			List<EObject> unmappedTgtElements, NamingStrategy naming) {
			// Weave mapped attributes
			// Because the mapping is a morphism, this must work :-)
			invertedIndex.entrySet.filter[e|e.key instanceof EAttribute].forEach [ e |
				val EAttribute composed = e.value.createWithWovenName(e.key.name.toString, [ n |
					createEAttribute(e.key as EAttribute, n)
				], naming)

				put(e.key.targetKey, composed)
				e.value.forEach[eo|put(eo.sourceKey, composed)]
			]

			// Create copies for unmapped attributes
			unmappedSrcElements.createForEachEAttribute(Origin.SOURCE)
			unmappedTgtElements.createForEachEAttribute(Origin.TARGET)
		}

		private def createForEachEClass(EPackage composedPackage, List<EObject> elements, Origin origin) {
			elements.createForEach(EClass, origin, [eo|composedPackage.createEClass(eo.name.originName(origin))])
		}

		private def createForEachEReference(List<EObject> elements, Origin origin) {
			elements.createForEach(EReference, origin, [er|er.createEReference(er.name.originName(origin), origin)])
		}

		private def createForEachEAttribute(List<EObject> elements, Origin origin) {
			elements.createForEach(EAttribute, origin, [er|er.createEAttribute(er.name.originName(origin), origin)])
		}

		private def <T extends ENamedElement> createForEach(List<EObject> elements, Class<T> clazz, Origin origin,
			Function<T, T> creator) {
			elements.filter(clazz).forEach [ eo |
				put(eo.origKey(origin), creator.apply(eo))
			]
		}

		private def weaveInheritance() {
			keySet.filter[p|p.value instanceof EClass].forEach [ p |
				val composed = get(p) as EClass
				composed.ESuperTypes.addAll((p.value as EClass).ESuperTypes.map[ec2|get(ec2.origKey(p.key)) as EClass].
					reject [ ec2 |
						composed === ec2 || composed.ESuperTypes.contains(ec2)
					])
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

		private def createEAttribute(EAttribute source, String name) {
			// Origin doesn't matter in this case, but must be TARGET because we've previously decided to copy from target references
			createEAttribute(source, name, Origin.TARGET)
		}

		private def createEAttribute(EAttribute source, String name, Origin origin) {
			val EAttribute result = EcoreFactory.eINSTANCE.createEAttribute;

			(get(source.EContainingClass.origKey(origin)) as EClass).EStructuralFeatures.add(result)
			/*
			 * TODO This will work well with datatypes that are centrally shared, but not with datatypes defined in a model. However,
			 * at the moment such datatypes wouldn't pass the morphism checker code either, so this is probably safe for now.
			 */
			result.EType = source.EType

			result.name = name
			result.changeable = source.changeable
			result.derived = source.derived
			result.lowerBound = source.lowerBound
			result.ordered = source.ordered
			result.transient = source.transient
			result.unique = source.unique
			result.unsettable = source.unsettable
			result.upperBound = source.upperBound
			result.volatile = source.volatile

			result
		}

		/**
		 * Separate map for keeping mappings established for proxies. Needs to be kept separately to avoid concurrent modifications when get transparently creates copies of proxies on demand.
		 */
		var proxyMapper = new HashMap<Pair<EObject, Origin>, InternalEObject>

		override EObject get(Object key) {
			if (key instanceof Pair) {
				if ((key.key instanceof Origin) && (key.value instanceof EObject)) {
					val result = super.get(key)

					if ((result === null) && (!(key.value instanceof EReference))) {
						val object = key.value as EObject

						if (object.eIsProxy()) {
							// Proxies wouldn't have been found when navigating the containment hierarchy, so we add them lazily as we come across them
							var proxyCopy = proxyMapper.get(key)

							if (proxyCopy === null) {
								proxyCopy = (EcoreFactory.eINSTANCE.create(object.eClass) as InternalEObject)
								proxyCopy.eSetProxyURI((object as InternalEObject).eProxyURI)
								proxyMapper.put(key, proxyCopy)
							}

							return proxyCopy
						}

						System.err.println('''Couldn't find «object» in «key.key».''')
					}

					return result
				}
			} else {
				throw new IllegalArgumentException("Requiring a pair in call to get!")
			}
		}
	}

	private def Module composeBehaviour(Module srcBehaviour, Module tgtBehaviour,
		Map<EObject, EObject> behaviourMapping, EPackage srcPackage, Map<Pair<Origin, EObject>, EObject> tgMapping, NamingStrategy naming) {
		if (behaviourMapping.empty) {
			return null
		}

		val result = HenshinFactory.eINSTANCE.createModule
		result.description = weaveDescriptions(srcBehaviour, tgtBehaviour)
		result.imports.add(tgMapping.get(srcPackage.sourceKey) as EPackage)
		result.name = weaveNames(srcBehaviour, tgtBehaviour, naming)

		result.units.addAll(behaviourMapping.keySet.filter(Rule).map[r|r.createComposed(behaviourMapping, tgMapping, naming)])

		result
	}

	def Rule createComposed(Rule tgtRule, Map<EObject, EObject> behaviourMapping,
		Map<Pair<Origin, EObject>, EObject> tgMapping, extension NamingStrategy naming) {
		val srcRule = behaviourMapping.get(tgtRule) as Rule
		val result = HenshinFactory.eINSTANCE.createRule

		result.name = weaveNames(tgtRule.name, srcRule.name)
		result.description = weaveDescriptions(tgtRule.description, srcRule.description)
		result.injectiveMatching = srcRule.injectiveMatching
		// TODO Should probably copy parameters, too
		result.lhs = new PatternWeaver(srcRule.lhs, tgtRule.lhs, behaviourMapping, tgMapping, "Lhs", naming).weavePattern
		result.rhs = new PatternWeaver(srcRule.rhs, tgtRule.rhs, behaviourMapping, tgMapping, "Rhs", naming).weavePattern

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

		var Graph srcPattern
		var Graph tgtPattern
		var Map<EObject, EObject> behaviourMapping
		var Map<Pair<Origin, EObject>, EObject> tgMapping

		var Graph wovenGraph
		
		val NamingStrategy naming 

		new(Graph srcPattern, Graph tgtPattern, Map<EObject, EObject> behaviourMapping,
			Map<Pair<Origin, EObject>, EObject> tgMapping, String patternLabel, NamingStrategy naming) {
			this.naming = naming
			this.srcPattern = srcPattern
			this.tgtPattern = tgtPattern
			this.behaviourMapping = behaviourMapping.filter [ key, value |
				(key.eContainer === srcPattern) || (key.eContainer.eContainer === srcPattern) // to include slots 
			]
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
			// Construct inverted index, then compose from that
			val invertedIndex = new HashMap<EObject, List<EObject>>()
			behaviourMapping.forEach [ k, v |
				invertedIndex.putIfAbsent(v, new ArrayList<EObject>)
				invertedIndex.get(v).add(k)
			]

			invertedIndex.entrySet.filter[e|e.key instanceof org.eclipse.emf.henshin.model.Node].forEach [ e |
				val composed = e.value.createWithWovenName(e.key.name.toString, [ n |
					createNode(e.key as org.eclipse.emf.henshin.model.Node, n)
				], naming)

				put((e.key as org.eclipse.emf.henshin.model.Node).targetKey, composed)
				e.value.forEach[eo|put((eo as org.eclipse.emf.henshin.model.Node).sourceKey, composed)]
			]

			invertedIndex.entrySet.filter[e|e.key instanceof Edge].forEach [ e |
				val composed = createEdge(e.key as Edge)

				put((e.key as Edge).targetKey, composed)
				e.value.forEach[eo|put((eo as Edge).sourceKey, composed)]
			]

			invertedIndex.entrySet.filter[e|e.key instanceof Attribute].forEach [ e |
				val composed = createSlot(e.key as Attribute)

				put((e.key as Attribute).targetKey, composed)
				e.value.forEach[eo|put((eo as Attribute).sourceKey, composed)]
			]
		}

		private def weaveUnmappedElements() {
			srcPattern.nodes.reject[n|behaviourMapping.containsKey(n)].forEach [ n |
				put(n.sourceKey, n.createNode(n.name.originName(Origin.SOURCE), Origin.SOURCE))
			]
			tgtPattern.nodes.reject[n|behaviourMapping.values.contains(n)].forEach [ n |
				put(n.targetKey, n.createNode(n.name.originName(Origin.TARGET), Origin.TARGET))
			]

			srcPattern.edges.reject[e|behaviourMapping.containsKey(e)].forEach [ e |
				put(e.sourceKey, e.createEdge(Origin.SOURCE))
			]
			tgtPattern.edges.reject[e|behaviourMapping.values.contains(e)].forEach [ e |
				put(e.targetKey, e.createEdge(Origin.TARGET))
			]

			srcPattern.nodes.map[n|n.attributes.reject[a|behaviourMapping.containsKey(a)]].flatten.forEach [ a |
				put(a.sourceKey, a.createSlot(Origin.SOURCE))
			]
			tgtPattern.nodes.map[n|n.attributes.reject[a|behaviourMapping.values.contains(a)]].flatten.forEach [ a |
				put(a.sourceKey, a.createSlot(Origin.TARGET))
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

		private def Attribute createSlot(Attribute aSrc) {
			// Origin doesn't matter for mapped elements, must be target because we've decided to copy data from target edge
			createSlot(aSrc, Origin.TARGET)
		}

		private def Attribute createSlot(Attribute aSrc, Origin origin) {
			val result = HenshinFactory.eINSTANCE.createAttribute

			val containingNode = get(aSrc.eContainer.origKey(origin)) as org.eclipse.emf.henshin.model.Node
			if (containingNode !== null) {
				containingNode.attributes.add(result)
			}

			result.type = tgMapping.get(aSrc.type.origKey(origin)) as EAttribute
			result.value = aSrc.value

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

	private static def <T extends EObject> T createWithWovenName(List<? extends EObject> objects, String startName,
		Function<String, T> creator, extension NamingStrategy naming) {
		creator.apply(objects.map[eo|eo.name.toString].sort.reverseView.fold(startName, [acc, n|weaveNames(n, acc)]))
	}

	private static def String weaveNames(Module sourceModule, Module targetModule, extension NamingStrategy naming) {
		weaveNames(if(sourceModule !== null) sourceModule.name else null,
			if(targetModule !== null) targetModule.name else null)
	}

	private static def String weaveDescriptions(Module sourceModule, Module targetModule) {
		weaveDescriptions(if(sourceModule !== null) sourceModule.description else null,
			if(targetModule !== null) targetModule.description else null)
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
