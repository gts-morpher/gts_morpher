package uk.ac.kcl.inf.util

import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule

import static extension uk.ac.kcl.inf.util.EMFHelper.isInterfaceElement

class HenshinChecker {
	public static def isIdentityRule(Rule rule, boolean isInterface) {
		// All LHS nodes are mapped
		rule.lhs.nodes.filter[n|(!isInterface) || n.interfaceElement].forall [ n |
			rule.mappings.exists [ m |
				(m.origin === n) && // All attribute values remain unchanged
				n.attributes.forall [ a |
					m.image.attributes.exists [ a2 |
						(a.type === a2.type) && (a.value == a2.value)
					]
				]
			]
		] && // All RHS nodes are mapped
		rule.rhs.nodes.filter[n|(!isInterface) || n.interfaceElement].forall [ n |
			rule.mappings.exists [ m |
				(m.image === n) && // All attribute values remain unchanged
				n.attributes.forall [ a |
					m.origin.attributes.exists [ a2 |
						(a.type === a2.type) && (a.value == a2.value)
					]
				]
			]
		] && // All LHS edges exist on RHS side of the rule
		rule.lhs.edges.filter[e|(!isInterface) || e.interfaceElement].forall [ e |
			rule.rhs.edges.exists [ e2 |
				e.type === e2.type && e.source.mapped === e2.source && e.target.mapped === e2.target
			]
		] && // All RHS edges exist on LHS side of the rule
		rule.rhs.edges.filter[e|(!isInterface) || e.interfaceElement].forall [ e |
			rule.lhs.edges.exists [ e2 |
				e.type === e2.type && e.source.mapped === e2.source && e.target.mapped === e2.target
			]
		]
	}

	private static def getMapped(Node node) {
		val mappings = (node.eContainer.eContainer as Rule).mappings
		if (node.eContainer === (node.eContainer.eContainer as Rule).lhs) {
			mappings.findFirst[mp|mp.origin === node].image
		} else {
			mappings.findFirst[mp|mp.image === node].origin
		}
	}
}
