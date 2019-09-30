package uk.ac.kcl.inf.gts_morpher.composer.helpers

import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EStructuralFeature

/**
 * A set of already decided names in whose context the name to be produced by a naming strategy should be unique. 
 */
abstract class UniquenessContext {
	def Iterable<? extends EObject> contextElements()
	
	static def UniquenessContext emptyContext() { [emptyList] }
	static dispatch def UniquenessContext uniquenessContext(EObject eo) { emptyContext }
	static dispatch def UniquenessContext uniquenessContext(EClass ec) {
		[(ec.eContainer as EPackage).EClassifiers.filter(EClass)]
	}
	static dispatch def UniquenessContext uniquenessContext(EStructuralFeature ef) {
		[(ef.eContainer as EClass).EAllStructuralFeatures]
	}
}