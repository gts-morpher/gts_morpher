package uk.ac.kcl.inf.validation.checkers

import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EAttribute

/**
 * Utility class to check type mappings for morphism properties.
 * 
 * Based on code by Kinga Bojarczuk
 */
class TypeMorphismChecker {

	/**
	 * Check that the given mapping does not break the rules of clan morphisms. The objects 
	 * in the map may be EClassifiers or EReferences. All objects in <code>mapping.keySet</code> 
	 * are assumed to be from a source meta-model, all those in the value set are expected to 
	 * be from a target meta-model. There may be elements in the source metamodel that are not 
	 * yet mapped by the given mapping. This will be accepted by the checker and the checker 
	 * will return true as long as the mappings provided do not break clan-morphism constraints.
	 * 
	 * TODO: Provide reference to paper with clan-morphism definition as part of the documentation  
	 */
	static def boolean checkValidMaybeIncompleteClanMorphism(Map<EObject, EObject> mapping) {
		mapping.checkModelInheritance && mapping.checkModelAssociations && mapping.checkModelAttributes
	}

	/**
	 * Check whether inheritance is preserved in the model mapping
	 */
	static private def boolean checkModelInheritance(Map<EObject, EObject> mapping) {
		!mapping.entrySet.filter[e|e.key instanceof EClass].exists [ e |
			!mapping.checkClassInheritance(e.key as EClass, e.value as EClass)
		]
	}

	/**
	 * Check whether a single EClass mapping is valid according to inheritance rules
	 */
	static private def boolean checkClassInheritance(Map<EObject, EObject> mapping, EClass source, EClass target) {
		(target !== null) && (!source.ESuperTypes.filter[c|mapping.containsKey(c)].exists [ c |
			!checkInClanOf(target, mapping.get(c) as EClass)
		])
	}

	/**
	 * Check whether associations are preserved in the model mapping
	 */
	static private def boolean checkModelAssociations(Map<EObject, EObject> mapping) {
		!mapping.entrySet.filter[e|e.key instanceof EReference].exists [ e |
			!mapping.checkReferenceMapping(e.key as EReference, e.value as EReference)
		]
	}

	/**
	 * Check whether a mapping between the two references satisfies the rules for a clan morphism.
	 */
	static private def boolean checkReferenceMapping(Map<EObject, EObject> mapping, EReference srcReference,
		EReference tgtReference) {
		if (tgtReference === null) {
			return false
		}

		val EClass srcSrcClass = srcReference.eContainer as EClass
		val EClass srcTgtClass = srcReference.EType as EClass

		val EClass tgtSrcClass = tgtReference.eContainer() as EClass
		val EClass tgtTgtClass = tgtReference.getEType() as EClass

		// def 5.1 check mapping of src class must belong to a clan of target src class
		if (mapping.containsKey(srcSrcClass)) {
			val EClass srcSrcClassMapping = mapping.get(srcSrcClass) as EClass
			if (!checkInClanOf(srcSrcClassMapping, tgtSrcClass)) {
				return false
			}
		}

		// def 5.1 check trgKeyValue must belong to a clan of trgValue
		if (mapping.containsKey(srcTgtClass)) {
			val EClass srcTgtClassMapping = mapping.get(srcTgtClass) as EClass
			if (!checkInClanOf(srcTgtClassMapping, tgtTgtClass)) {
				return false
			}
		}

		true
	}

	/**
	 * Checks whether attributes are preserved in the model mapping
	 */
	static private def boolean checkModelAttributes(Map<EObject, EObject> mapping) {
		!mapping.entrySet.filter[e|e.key instanceof EAttribute].exists [ e |
			!mapping.checkAttributeMapping(e.key as EAttribute, e.value as EAttribute)
		]
	}

	static private def boolean checkAttributeMapping(Map<EObject, EObject> mapping, EAttribute srcAttribute,
		EAttribute tgtAttribute) {
		if (tgtAttribute === null) {
			return false
		}

		// get src nodes and Data types for both EAttributes
		val EClass srcContainingClass = srcAttribute.eContainer as EClass
		val EClass srcType = srcAttribute.EType as EClass
		
		val EClass tgtContainingClass = tgtAttribute.eContainer as EClass
		val EClass tgtType = tgtAttribute.EType as EClass

		// def 5.2 check srcKeyValue must belong to a clan of srcValue
		if (mapping.containsKey(srcContainingClass)) {
			val EClass srcContainingClassMapping = mapping.get(srcContainingClass) as EClass
			if (!checkInClanOf(srcContainingClassMapping, tgtContainingClass)) {
				return false
			}
		}

		// def 5.2 check that Data types are the same
		// FIXME This check might not actually work
		if (!srcType.equals(tgtType)) {
			return false
		}

		true
	}

	/**
	 * Checks whether the clan of {@code clanClass} contains {@code clazz}. The clan
	 * of a class is the set of all sub-classes, including the class itself.
	 */
	static private def boolean checkInClanOf(EClass clazz, EClass clanClass) {
		// if they're equal then they're in the same clan
		(clazz == clanClass) || // go through all supertypes of clazz and their supertypes and check if any of
		// them are equal to clanClass
		clazz.ESuperTypes.exists[sc|checkInClanOf(sc, clanClass)]
	}
}
