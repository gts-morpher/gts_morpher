package uk.ac.kcl.inf.gts_morpher.shifter

import java.util.HashMap
import java.util.HashSet
import java.util.Map
import java.util.Set
import org.eclipse.emf.henshin.model.Formula
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.NestedCondition
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Not
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * An application condition is two graphs and a morphism between them. 
 */
class ApplicationCondition {

	@Accessors
	var boolean isNegative = false

	@Accessors(PUBLIC_GETTER)
	val Map<GraphElement, GraphElement> morphism = new HashMap

	@Accessors(PUBLIC_GETTER)
	val Set<GraphElement> unmappedElements = new HashSet

	new(Formula formula) {
		super()

		formula.assertCanHandle

		formula.extract
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
		unmappedElements +=
			(nc.conclusion.edges + nc.conclusion.nodes + nc.conclusion.nodes.flatMap[attributes]).reject [
				morphism.containsValue(it)
			].map[it as GraphElement]
	}

}
