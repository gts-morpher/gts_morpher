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

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import org.eclipse.emf.henshin.model.HenshinPackage

/**
 * Helper class for weaving a rule pattern. Acts as a map remembering the mappings established. 
 */
class PatternWeaver extends AbstractWeaver {

	val Map<Pair<Origin, EObject>, EObject> tgMapping

	var Graph wovenGraph

	extension val NamingStrategy naming

	extension val HenshinPackage henshin = HenshinPackage.eINSTANCE

	new(Graph kernelPattern, Graph leftPattern, Graph rightPattern, Map<EObject, EObject> leftBehaviourMapping,
		Map<EObject, EObject> rightBehaviourMapping, Map<Pair<Origin, EObject>, EObject> tgMapping, String patternLabel,
		NamingStrategy naming) {
		super(
			new ModelSpan(leftBehaviourMapping.filteredMapping(leftPattern),
				rightBehaviourMapping.filteredMapping(rightPattern), kernelPattern, leftPattern, rightPattern).
				calculateMergeSet,
			leftBehaviourMapping.unmappedElements(leftPattern),
			rightBehaviourMapping.unmappedElements(rightPattern)
		)

		this.naming = naming
		this.tgMapping = tgMapping

		wovenGraph = HenshinFactory.eINSTANCE.createGraph
		wovenGraph.name = patternLabel
	}

	private static def filteredMapping(Map<EObject, EObject> originalMapping, Graph pattern) {
		new HashMap(originalMapping.filter [ key, value |
			(value instanceof GraphElement) &&
				((value.eContainer === pattern) || (value.eContainer.eContainer === pattern)) // to include slots
		])
	}

	private static def List<EObject> unmappedElements(Map<EObject, EObject> originalMapping, Graph pattern) {
		if (pattern !== null) {
			pattern.eAllContents.filter(GraphElement).reject [ ge |
				originalMapping.containsValue(ge)
			].toList
		} else {
			emptyList
		}
	}

	def Graph weavePattern() {
		weaveNodes
		weaveEdges
		weaveSlots

		weaveAllNames

		wovenGraph
	}

	private def weaveNodes() {
		doWeave(org.eclipse.emf.henshin.model.Node, node, [ n, ms |
			n.createNode
		], [ n, o |
			n.createNode(o)
		])
	}

	private def weaveEdges() {
		doWeave(Edge, edge, [ e, ms |
			e.createEdge
		], [ e, o |
			e.createEdge(o)
		])
	}

	private def weaveSlots() {
		doWeave(Attribute, attribute, [ a, ms |
			a.createSlot
		], [ a, o |
			a.createSlot(o)
		])
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
}
