package uk.ac.kcl.inf.gts_morpher.shifter

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Formula
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.HenshinPackage
import org.eclipse.emf.henshin.model.NestedCondition
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Not
import org.eclipse.xtend.lib.annotations.Accessors
import uk.ac.kcl.inf.gts_morpher.composer.helpers.MergeSet
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import uk.ac.kcl.inf.gts_morpher.composer.weavers.AbstractWeaver

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*

import static uk.ac.kcl.inf.gts_morpher.composer.helpers.ContentsEnumerators.*

/**
 * An application condition is two graphs and a morphism between them. 
 */
class ApplicationCondition {

	/**
	 * True if this is a NAC
	 */
	@Accessors
	var boolean isNegative = false

	/**
	 * Mapping from host-graph elements to elements in the AC graph. keySet elements always come from the host graph and will cover the host graph completely.
	 * value elements may come from the host graph (if no explicit representation and mapping provided in the rule), or from the application condition (if an
	 * explicit mapping was provided).
	 */
	@Accessors(PUBLIC_GETTER)
	val Map<GraphElement, GraphElement> morphism = new HashMap

	/**
	 * Elements added by the application-condition graph. Should not be empty. 
	 */
	@Accessors(PUBLIC_GETTER)
	val Set<GraphElement> unmappedElements = new HashSet

	new(Formula formula) {
		super()

		formula.assertCanHandle

		formula.extract
	}

	private new() {
	}

	def ApplicationCondition shift(Map<EObject, EObject> tgMapping, Map<EObject, EObject> behaviourMapping, boolean srcIsInterface) {
		val kernelGraph = morphism.keySet.head.graph
		val acGraph = unmappedElements.head.graph
		val targetGraph = behaviourMapping.get(kernelGraph) as Graph
		val modelSpan = new ModelSpan(morphism, behaviourMapping, kernelGraph, acGraph, targetGraph, graphEnumerator(srcIsInterface))
		val shifterTGMapping = new HashMap<Pair<Origin, EObject>, EObject>()
		unmappedElements.forEach [
			val type = it.TGElement
			shifterTGMapping.put(type.leftKey, type)
		]
		morphism.keySet.forEach [
			val type = it.TGElement
			shifterTGMapping.put(type.leftKey, type)
			shifterTGMapping.put(type.kernelKey, type)
		]
		tgMapping.forEach[k, v|
			shifterTGMapping.put(k.rightKey, v)
			shifterTGMapping.put(k.kernelKey, v)
		]

		val shifter = new ACShifter(modelSpan.calculateMergeSet, unmappedElements, (targetGraph.nodes +
			targetGraph.edges + targetGraph.nodes.flatMap[attributes]).map[it as GraphElement].reject [
			behaviourMapping.containsValue(it)
		], shifterTGMapping)

		new ApplicationCondition => [
			isNegative = this.isNegative

			morphism.putAll(shifter.wovenElements)
			unmappedElements += shifter.unmappedElements
		]
	}

	private dispatch def EObject getTGElement(GraphElement ge) { throw new IllegalArgumentException }

	private dispatch def EObject getTGElement(Node n) { n.type }

	private dispatch def EObject getTGElement(Edge e) { e.type }

	private dispatch def EObject getTGElement(Attribute a) { a.type }

	private static class ACShifter extends AbstractWeaver {
		val Map<Pair<Origin, EObject>, EObject> tgMapping

		val Graph wovenGraph

		extension val HenshinPackage henshin = HenshinPackage.eINSTANCE

		protected new(Set<MergeSet> mergeSets, Set<GraphElement> unmappedACElements,
			Iterable<GraphElement> unmappedTargetGraphElements, Map<Pair<Origin, EObject>, EObject> tgMapping) {
			super(mergeSets, new ArrayList<EObject>(unmappedACElements),
				new ArrayList<EObject>(unmappedTargetGraphElements.toList))

			this.tgMapping = tgMapping

			wovenGraph = HenshinFactory.eINSTANCE.createGraph

			weaveNodes
			weaveEdges
			weaveSlots
			
			weaveNames
		}

		def Map<GraphElement, GraphElement> wovenElements() {
			val result = new HashMap<GraphElement, GraphElement>

			filter[k, v|k.key === Origin.RIGHT].forEach[k, v|result.put(k.value as GraphElement, v as GraphElement)]

			result
		}

		def Set<GraphElement> unmappedElements() {
			val modelElements = wovenGraph.nodes + wovenGraph.edges + wovenGraph.nodes.flatMap[attributes]
			val graphElements = modelElements.map[it as GraphElement]
			graphElements.reject [ filter[k, v|k.key === Origin.RIGHT].containsValue(it) ].toSet
		}

		private def weaveNames() {
			val invertedMap = keySet.groupBy[get(it)]
			
			invertedMap.keySet.filter(org.eclipse.emf.henshin.model.Node).forEach[n |
				val nameSources = invertedMap.get(n)
				var orig = Origin.LEFT
				if (nameSources.exists[ns | ns.key === Origin.RIGHT]) {
					orig = Origin.RIGHT
				}
				val o = orig

				n.name = nameSources.findFirst[ns | ns.key === o].value.name.toString					
			]
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

	private dispatch def void assertCanHandle(Formula f) {
		throw new UnsupportedOperationException("Cannot yet handle arbitrary formulae")
	}

	private dispatch def void assertCanHandle(Not n) {
		n.child.assertCanHandle
	}

	private dispatch def void assertCanHandle(NestedCondition nc) {
		if (nc.conclusion.formula !== null) {
			throw new UnsupportedOperationException("Cannot yet handle nested formulae")
		}
	}

	private dispatch def void extract(Formula f) {
		throw new UnsupportedOperationException("Unsupported type of application condition")
	}

	private dispatch def void extract(Not n) {
		isNegative = !isNegative
		n.child.extract
	}

	private dispatch def void extract(NestedCondition nc) {
		nc.host.nodes.forEach [ n |
			val nodeMapping = nc.mappings.findFirst[origin === n]
			if (nodeMapping !== null) {
				morphism.put(nodeMapping.origin, nodeMapping.image)
			} else {
				morphism.put(n, n)
			}
			val mappedNode = morphism.get(n) as Node

			n.attributes.forEach [ a |
				val mappedAttribute = mappedNode.attributes.findFirst[type === a.type]
				if (mappedAttribute !== null) {
					morphism.put(a, mappedAttribute)
				} else {
					morphism.put(a, a)
				}
			]
		]

		nc.host.edges.forEach [ e |
			val srcNodeMapping = nc.mappings.findFirst[origin === e.source]
			val tgtNodeMapping = nc.mappings.findFirst[origin === e.target]
			val mappedEdge = nc.conclusion.edges.findFirst [
				(source === srcNodeMapping?.image) && (target === tgtNodeMapping?.image)
			]

			if (mappedEdge !== null) {
				morphism.put(e, mappedEdge)
			} else {
				morphism.put(e, e)
			}
		]

		// Add unmapped elements from conclusion to set of unmapped elements
		unmappedElements += (nc.conclusion.edges + nc.conclusion.nodes + nc.conclusion.nodes.flatMap[attributes]).reject [
			morphism.containsValue(it)
		].map[it as GraphElement]
	}

}
