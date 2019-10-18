package uk.ac.kcl.inf.gts_morpher.composer.weavers

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
import uk.ac.kcl.inf.gts_morpher.composer.helpers.MergeSet
import java.util.Set

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import org.eclipse.emf.henshin.model.HenshinPackage

/**
	 * Helper class for weaving a rule pattern. Acts as a map remembering the mappings established. 
	 */
class PatternWeaver extends HashMap<Pair<Origin, EObject>, GraphElement> {

		val Map<Pair<Origin, EObject>, EObject> tgMapping
		val Set<MergeSet> mergeSets
		val List<GraphElement> leftUnmappedElements
		val List<GraphElement> rightUnmappedElements

		var Graph wovenGraph

		extension val NamingStrategy naming
		
		extension val HenshinPackage henshin = HenshinPackage.eINSTANCE

		new (Graph kernelPattern, Graph leftPattern, Graph rightPattern, Map<EObject, EObject> leftBehaviourMapping, Map<EObject, EObject> rightBehaviourMapping, Map<Pair<Origin, EObject>, EObject> tgMapping, String patternLabel, NamingStrategy naming) {
			this.naming = naming
			this.tgMapping = tgMapping

			val leftMapping = new HashMap(leftBehaviourMapping.filter [ key, value |
				(value instanceof GraphElement) &&
				((value.eContainer === leftPattern) || (value.eContainer.eContainer === leftPattern)) // to include slots
			])
			val rightMapping = new HashMap(rightBehaviourMapping.filter [ key, value |
				(value instanceof GraphElement) &&
				((value.eContainer === rightPattern) || (value.eContainer.eContainer === rightPattern)) // to include slots 
			])

			mergeSets = new ModelSpan(leftMapping, rightMapping, kernelPattern, leftPattern, rightPattern).calculateMergeSet

			if (leftPattern !== null) {
				leftUnmappedElements = leftPattern.eAllContents.filter(GraphElement).reject[ge | 
					leftBehaviourMapping.containsValue(ge)
				].toList				
			} else {
				leftUnmappedElements = emptyList
			}
			
			if (rightPattern !== null) {
				rightUnmappedElements = rightPattern.eAllContents.filter(GraphElement).reject[ge | 
					rightBehaviourMapping.containsValue(ge)
				].toList				
			} else {
				rightUnmappedElements = emptyList
			}

			wovenGraph = HenshinFactory.eINSTANCE.createGraph
			wovenGraph.name = patternLabel
		}

		def Graph weavePattern() {
			weaveMappedElements
			weaveUnmappedElements

			weaveAllNames

			wovenGraph
		}

		private def weaveMappedElements() {
			mergeSets.filter[hasType(node)].forEach[ms |
				val keyedMergeList = ms.keyedMergeList
				
				val mergedNode = (ms.kernel.head as org.eclipse.emf.henshin.model.Node).createNode
				
				keyedMergeList.forEach [ kep |
					put(kep, mergedNode)
				]
			]
			
			mergeSets.filter[hasType(edge)].forEach[ms |
				val keyedMergeList = ms.keyedMergeList
				
				val mergedNode = (ms.kernel.head as Edge).createEdge
				
				keyedMergeList.forEach [ kep |
					put(kep, mergedNode)
				]
			]

			mergeSets.filter[hasType(attribute)].forEach[ms |
				val keyedMergeList = ms.keyedMergeList
				
				val mergedNode = (ms.kernel.head as Attribute).createSlot
				
				keyedMergeList.forEach [ kep |
					put(kep, mergedNode)
				]
			]
		}

		private def weaveUnmappedElements() {
			leftUnmappedElements.filter(org.eclipse.emf.henshin.model.Node).forEach [ n |
				put(n.leftKey, n.createNode(Origin.LEFT))
			]
			rightUnmappedElements.filter(org.eclipse.emf.henshin.model.Node).forEach [ n |
				put(n.rightKey, n.createNode(Origin.RIGHT))
			]

			leftUnmappedElements.filter(Edge).forEach [ e |
				put(e.leftKey, e.createEdge(Origin.LEFT))
			]
			rightUnmappedElements.filter(Edge).forEach [ e |
				put(e.rightKey, e.createEdge(Origin.RIGHT))
			]

			leftUnmappedElements.filter(Attribute).forEach [ a |
				put(a.leftKey, a.createSlot(Origin.LEFT))
			]
			rightUnmappedElements.filter(Attribute).forEach [ a |
				put(a.rightKey, a.createSlot(Origin.RIGHT))
			]
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

		private def createNode(org.eclipse.emf.henshin.model.Node nSrc) {
			// Origin doesn't matter for mapped elements, must be target because we've decided to copy data from target TG
			createNode(nSrc, Origin.KERNEL)
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
			createEdge(eSrc, Origin.KERNEL)
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
			createSlot(aSrc, Origin.KERNEL)
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
