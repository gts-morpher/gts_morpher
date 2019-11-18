package uk.ac.kcl.inf.gts_morpher.composer.helpers

import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.emf.henshin.model.Attribute

/**
 * A set of already decided names in whose context the name to be produced by a naming strategy should be unique. 
 */
abstract class UniquenessContext {
	def Iterable<? extends EObject> contextElements()

	def boolean considerIdentical(EObject eo1, EObject eo2) {
		eo1 === eo2
	}

	static def UniquenessContext emptyContext() { [emptyList] }

	static dispatch def UniquenessContext uniquenessContext(EObject eo) { emptyContext }

	static dispatch def UniquenessContext uniquenessContext(EClass ec) {
		[(ec.eContainer as EPackage).EClassifiers.filter(EClass)]
	}

	static dispatch def UniquenessContext uniquenessContext(EStructuralFeature ef) {
		[(ef.eContainer as EClass).EAllStructuralFeatures]
	}

	static dispatch def UniquenessContext uniquenessContext(Node n) {
		val rule = n.findContainingRule

		// FIXME: should also include names in application conditions
		return new UniquenessContext {

			override contextElements() {
				val left = rule?.lhs?.nodes
				val right = rule?.rhs?.nodes

				if ((left !== null) && (right !== null)) {
					left + right
				} else {
					if (left !== null) {
						left
					} else if (right !== null) {
						right
					} else {
						emptyList
					}
				}
			}

			override considerIdentical(EObject eo1, EObject eo2) {
				super.considerIdentical(eo1, eo2) ||
				rule?.mappings.exists[mp | 
					((mp.origin === eo1) && (mp.image === eo2)) ||
					((mp.origin === eo2) && (mp.image === eo1))
				]
			}
		}
	}

	private static def findContainingRule(Node n) {
		var EObject container = n.eContainer
		while ((container !== null) && !(container instanceof Rule)) {
			container = container.eContainer
		}

		container as Rule
	}
}
