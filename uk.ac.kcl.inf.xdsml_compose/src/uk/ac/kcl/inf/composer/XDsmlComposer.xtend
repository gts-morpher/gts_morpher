package uk.ac.kcl.inf.composer

import java.util.HashMap
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.emf.henshin.model.Node
import org.eclipse.xtext.generator.IFileSystemAccess2
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static extension uk.ac.kcl.inf.util.BasicMappingChecker.*
import static extension uk.ac.kcl.inf.util.EMFHelper.*
import org.eclipse.emf.henshin.model.Edge

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
// FIXME: The current mapping approach assumes that source and target GTS are strictly different models. If they're the same model (as in my simple test case), the mapping approach won't work properly
class XDsmlComposer {

	/**
	 * Perform the composition.
	 * 
	 * @param resource a resource with the morphism specification. If source is <code>interface_of</code> performs a 
	 * full pushout, otherwise assumes that interface and full language are identical for the source. Currently does 
	 * not support use of <code>interface_of</code> in the target GTS.
	 * 
	 * @param fsa used for file-system access
	 */
	def doCompose(Resource resource, IFileSystemAccess2 fsa) {
		try {
			val mapping = resource.contents.head as GTSMapping

			if (mapping.target.interface_mapping) {
				throw new UnsupportedOperationException(
					"Target GTS for a weave cannot currently be an interface_of mapping.")
			}

			// TODO Handle auto-complete and non-unique auto-completes
			val tgWeaver = new TGWeaver
			val composedTG = tgWeaver.weaveTG(mapping)
			val composedTGResource = resource.resourceSet.createResource(
				fsa.getURI(resource.URI.trimFileExtension.lastSegment + "_composed_tg.ecore"))
			composedTGResource.contents.clear
			composedTGResource.contents.add(composedTG)
			composedTGResource.save(emptyMap)

			val composedModule = mapping.composeBehaviour(tgWeaver)
			if (composedModule !== null) {
				val composedBehaviourResource = resource.resourceSet.createResource(
					fsa.getURI(resource.URI.trimFileExtension.lastSegment + "_composed_rules.henshin"))
				composedBehaviourResource.contents.clear
				composedBehaviourResource.contents.add(composedModule)
				composedBehaviourResource.save(emptyMap)
			}
		} catch (Exception e) {
			e.printStackTrace
		}
	}

	/**
	 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
	 * will act as a Map from source EObjects to the corresponding woven EObjects. 
	 */
	private static class TGWeaver extends HashMap<EObject, EObject> {
		/**
		 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
		 */
		def EPackage weaveTG(GTSMapping mapping) {
			// TODO Handle sub-packages?
			val EPackage result = EcoreFactory.eINSTANCE.createEPackage
			result.name = '''«mapping.source.metamodel.name»_«mapping.target.metamodel.name»'''
			result.nsPrefix = '''«mapping.source.metamodel.nsPrefix»_«mapping.target.metamodel.nsPrefix»'''
			// TODO We can probably do better here :-)
			result.nsURI = '''https://metamodel.woven/«mapping.source.metamodel.nsPrefix»/«mapping.target.metamodel.nsPrefix»'''
			put(mapping.source.metamodel, result)
			put(mapping.target.metamodel, result)

			val tgMapping = mapping.typeMapping.extractMapping(null)

			weaveMappedElements(tgMapping, result)
			weaveUnmappedElements(mapping, tgMapping, result)

			weaveInheritance

			return result
		}
		
		override def put(EObject k, EObject v) {
			super.put(k,v)
		}

		private def weaveMappedElements(Map<EObject, EObject> tgMapping, EPackage composedPackage) {
			tgMapping.entrySet.filter[e|e.key instanceof EClass].forEach [ e |
				val EClass composed = composedPackage.createEClass('''«e.key.name»_«e.value.name»''')

				put(e.key, composed)
				put(e.value, composed)
			]
			// Because the mapping is a morphism, this must work :-)
			tgMapping.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
				val EReference composed = createEReference(e.key as EReference, '''«e.key.name»_«e.value.name»''')

				put(e.key, composed)
				put(e.value, composed)
			]

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveUnmappedElements(GTSMapping mapping, Map<EObject, EObject> tgMapping,
			EPackage composedPackage) {
			// Deal with unmapped source elements
			mapping.source.metamodel.eAllContents.reject[eo|tgMapping.containsKey(eo)].toList.
				doWeaveUnmappedElements(composedPackage, "source")

			// Deal with unmapped target elements
			mapping.target.metamodel.eAllContents.reject[eo|tgMapping.values.contains(eo)].toList.
				doWeaveUnmappedElements(composedPackage, "target")

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveInheritance() {
			keySet.filter(EClass).forEach [ ec |
				val composed = get(ec) as EClass
				composed.ESuperTypes.addAll(ec.ESuperTypes.map[ec2|get(ec2) as EClass].reject [ ec2 |
					composed.ESuperTypes.contains(ec2)
				])
			]
		}

		private def doWeaveUnmappedElements(Iterable<EObject> unmappedElements, EPackage composedPackage,
			String srcLabel) {
			unmappedElements.filter(EClass).forEach[ec|put(ec, composedPackage.createEClass(srcLabel + "__" + ec.name))]
			unmappedElements.filter(EReference).forEach[er|put(er, er.createEReference(srcLabel + "__" + er.name))]
		}

		private def createEClass(EPackage container, String name) {
			val EClass result = EcoreFactory.eINSTANCE.createEClass
			container.EClassifiers.add(result)
			result.name = name
			result
		}

		private def createEReference(EReference source, String name) {
			val EReference result = EcoreFactory.eINSTANCE.createEReference;

			(get(source.EContainingClass) as EClass).EStructuralFeatures.add(result)
			result.EType = get(source.EType) as EClass

			result.name = name
			result.changeable = source.changeable
			result.containment = source.containment
			result.derived = source.derived
			result.EOpposite = get(source.EOpposite) as EReference
			result.lowerBound = source.lowerBound
			result.ordered = source.ordered
			result.transient = source.transient
			result.unique = source.unique
			result.unsettable = source.unsettable
			result.upperBound = source.upperBound
			result.volatile = source.volatile

			result
		}
	}

	private def Module composeBehaviour(GTSMapping mapping, Map<EObject, EObject> tgMapping) {
		if ((mapping.source.behaviour === null) || (mapping.target.behaviour === null)) {
			return null
		}

		val result = HenshinFactory.eINSTANCE.createModule
		result.description = '''Merged from «mapping.source.behaviour.description» and «mapping.target.behaviour.description».'''
		result.imports.add(tgMapping.get(mapping.source.metamodel) as EPackage)
		result.name = '''«mapping.source.behaviour.name»_«mapping.target.behaviour.name»'''

		val _mapping = mapping.behaviourMapping.extractMapping(null)

		result.units.addAll(_mapping.keySet.filter(Rule).map[r|r.createComposed(_mapping, tgMapping)])

		result
	}

	def Rule createComposed(Rule tgtRule, Map<EObject, EObject> behaviourMapping, Map<EObject, EObject> tgMapping) {
		val srcRule = behaviourMapping.get(tgtRule) as Rule
		val result = HenshinFactory.eINSTANCE.createRule

		result.name = '''«tgtRule.name»_«srcRule.name»'''
		result.description = '''Merged from «tgtRule.description» and «srcRule.description».'''
		result.injectiveMatching = srcRule.injectiveMatching
		// TODO Should probably copy parameters, too
		result.lhs = new PatternWeaver(srcRule.lhs, tgtRule.lhs, behaviourMapping, tgMapping, "lhs").weavePattern
		result.rhs = new PatternWeaver(srcRule.rhs, tgtRule.rhs, behaviourMapping, tgMapping, "rhs").weavePattern

		// Weave kernel
		result.lhs.nodes.map[n | 
			val n2 = result.rhs.nodes.findFirst[n2 | n.name.equals(n2.name)]
			if (n2 !== null) {
				new Pair(n, n2)
			} else {
				null
			}
		].reject[n | n === null].forEach[p |
			result.mappings.add(HenshinFactory.eINSTANCE.createMapping(p.key, p.value))
		]

		result
	}

	/**
	 * Helper class for weaving a rule pattern. Acts as a map remembering the mappings established. 
	 */
	private static class PatternWeaver extends HashMap<GraphElement, GraphElement> {

		private var Graph srcPattern
		private var Graph tgtPattern
		private var Map<EObject, EObject> behaviourMapping
		private var Map<EObject, EObject> tgMapping

		private var Graph wovenGraph

		new(Graph srcPattern, Graph tgtPattern, Map<EObject, EObject> behaviourMapping, Map<EObject, EObject> tgMapping,
			String patternLabel) {
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
				val composed = createNode(
					e.key as org.eclipse.emf.henshin.model.Node, '''«e.key.name»_«e.value.name»''')

				put(e.key as org.eclipse.emf.henshin.model.Node, composed)
				put(e.value as org.eclipse.emf.henshin.model.Node, composed)
			]
			behaviourMapping.entrySet.filter[e|e.key instanceof Edge].forEach [ e |
				val composed = createEdge(e.key as Edge)

				put(e.key as Edge, composed)
				put(e.value as Edge, composed)
			]
		}

		private def weaveUnmappedElements() {
			srcPattern.nodes.reject[n|behaviourMapping.containsKey(n)].forEach [n | put(n, n.createNode('''source__«n.name»'''))]
			tgtPattern.nodes.reject[n|behaviourMapping.values.contains(n)].forEach [n | put(n, n.createNode('''target__«n.name»'''))]

			srcPattern.edges.reject[e|behaviourMapping.containsKey(e)].forEach[e|put(e, e.createEdge)]
			tgtPattern.edges.reject[e|behaviourMapping.values.contains(e)].forEach[e|put(e, e.createEdge)]
		}
		
		private def org.eclipse.emf.henshin.model.Node createNode(org.eclipse.emf.henshin.model.Node nSrc,
			String name) {
			val result = HenshinFactory.eINSTANCE.createNode

			result.name = name
			result.type = tgMapping.get(nSrc.type) as EClass

			wovenGraph.nodes.add(result)

			result
		}

		private def Edge createEdge(Edge eSrc) {
			val result = HenshinFactory.eINSTANCE.createEdge

			result.source = get(eSrc.source) as org.eclipse.emf.henshin.model.Node
			result.target = get(eSrc.target) as org.eclipse.emf.henshin.model.Node
			result.type = tgMapping.get(eSrc.type) as EReference

			wovenGraph.edges.add(result)

			result
		}
	}
}
