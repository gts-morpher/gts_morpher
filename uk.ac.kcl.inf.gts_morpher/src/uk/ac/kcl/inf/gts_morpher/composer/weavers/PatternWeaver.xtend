package uk.ac.kcl.inf.gts_morpher.composer.weavers

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.NamedElement
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*

/**
	 * Helper class for weaving a rule pattern. Acts as a map remembering the mappings established. 
	 */
class PatternWeaver extends HashMap<Pair<Origin, GraphElement>, GraphElement> {

		var Graph srcPattern
		var Graph tgtPattern
		var Map<EObject, EObject> behaviourMapping
		var Map<Pair<Origin, EObject>, EObject> tgMapping

		var Graph wovenGraph

		extension val NamingStrategy naming

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

			weaveAllNames

			wovenGraph
		}

		/**
		 * Fix names of all elements produced...
		 */
		private def weaveAllNames() {
			// 1. Invert the weaving
			val invertedMapping = keySet.groupBy[p|get(p)]

			// 2. For every key in keyset of inversion, define the name based on names of all the sources that were merged into this
			invertedMapping.keySet.forEach [ eo |
				if (eo instanceof NamedElement) {
					eo.name = naming.weaveNames(invertedMapping, eo, eo.uniquenessContext)
				}
			]
		}

		private def weaveMappedElements() {
			// Construct inverted index, then compose from that
			val invertedIndex = new HashMap<EObject, List<EObject>>()
			behaviourMapping.forEach [ k, v |
				invertedIndex.putIfAbsent(v, new ArrayList<EObject>)
				invertedIndex.get(v).add(k)
			]

			invertedIndex.entrySet.filter[e|e.key instanceof org.eclipse.emf.henshin.model.Node].forEach [ e |
				val composed = createNode(e.key as org.eclipse.emf.henshin.model.Node)

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
				put(n.sourceKey, n.createNode(Origin.SOURCE))
			]
			tgtPattern.nodes.reject[n|behaviourMapping.values.contains(n)].forEach [ n |
				put(n.targetKey, n.createNode(Origin.TARGET))
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

		private def createNode(org.eclipse.emf.henshin.model.Node nSrc) {
			// Origin doesn't matter for mapped elements, must be target because we've decided to copy data from target TG
			createNode(nSrc, Origin.TARGET)
		}

		private def createNode(org.eclipse.emf.henshin.model.Node nSrc, Origin origin) {
			val result = HenshinFactory.eINSTANCE.createNode => [
				type = tgMapping.get(nSrc.type.origKey(origin)) as EClass
			]

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
