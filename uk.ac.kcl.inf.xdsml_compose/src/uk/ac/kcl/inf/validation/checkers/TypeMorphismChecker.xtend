package uk.ac.kcl.inf.validation.checkers

import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtend.lib.annotations.Data
import uk.ac.kcl.inf.util.ValueHolder

/**
 * Utility class to check type mappings for morphism properties.
 * 
 * Based on code by Kinga Bojarczuk
 */
class TypeMorphismChecker {

	/**
	 * Instances of Issue will be used to report any issues found during checking
	 */
	@Data
	public static class Issue {
		private EObject sourceModelElement
		private String message
	}
	
	/**
	 * Check that the given mapping does not break the rules of clan morphisms. The objects 
	 * in the map may be EClassifiers or EReferences. All objects in <code>mapping.keySet</code> 
	 * are assumed to be from a source meta-model, all those in the value set are expected to 
	 * be from a target meta-model. There may be elements in the source metamodel that are not 
	 * yet mapped by the given mapping. This will be accepted by the checker and the checker 
	 * will return true as long as the mappings provided do not break clan-morphism constraints.
	 * 
	 * TODO: Provide reference to paper with clan-morphism definition as part of the documentation
	 * 
	 * @param mapping the mapping information to be validated
	 * @param issues an, initially empty, list to which to add information about any issues to report. 
	 * Can be <code>null</code> to prevent issue reporting.
	 * 
	 * @return true if all checks succeeded  
	 */
	static def boolean checkValidMaybeIncompleteClanMorphism(Map<EObject, EObject> mapping, List<Issue> issues) {
		mapping.checkModelInheritance(issues) && mapping.checkModelAssociations(issues) &&
			mapping.checkModelAttributes(issues)
	}

	/**
	 * Check whether inheritance is preserved in the model mapping
	 */
	static private def boolean checkModelInheritance(Map<EObject, EObject> mapping, List<Issue> issues) {
		!mapping.entrySet.filter[e|e.key instanceof EClass].exists [ e |
			!mapping.checkClassInheritance(e.key as EClass, e.value as EClass, issues)
		]
	}

	/**
	 * Check whether a single EClass mapping is valid according to inheritance rules
	 */
	static private def boolean checkClassInheritance(Map<EObject, EObject> mapping, EClass source, EClass target,
		List<Issue> issues) {
		if (issues === null) {
			// Do quick check
			(target !== null) && (!source.ESuperTypes.filter[c|mapping.containsKey(c)].exists [ c |
				!checkInClanOf(target, mapping.get(c) as EClass)
			])
		} else {
			// Potentially slightly slower, but collecting all issues, rather than stopping after the first one
			if (target !== null) {
				val result = new ValueHolder<Boolean>(true)
				source.ESuperTypes.filter[c|mapping.containsKey(c)].forEach [ c |
					if (!checkInClanOf(target, mapping.get(c) as EClass)) {
						result.value = false
						issues.add(
							new Issue(source,
								"Target class's inheritance hierarchy not compatible with mapped parts of source class's inheritance hierarchy"))
					}
				]
				result.value
			} else {
				issues.add(new Issue(source, "No target mapping"))
				false
			}
		}
	}

	/**
	 * Check whether associations are preserved in the model mapping
	 */
	static private def boolean checkModelAssociations(Map<EObject, EObject> mapping, List<Issue> issues) {
		if (issues === null) {
			// Fast check
			!mapping.entrySet.filter[e|e.key instanceof EReference].exists [ e |
				!mapping.checkReferenceMapping(e.key as EReference, e.value as EReference, issues)
			]
		} else {
			// Slower check finding all issues
			val result = new ValueHolder<Boolean> (true)
			mapping.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
				if (!mapping.checkReferenceMapping(e.key as EReference, e.value as EReference, issues)) {
					result.value = false
				} 
			]
			result.value
		}
	}

	/**
	 * Check whether a mapping between the two references satisfies the rules for a clan morphism.
	 */
	static private def boolean checkReferenceMapping(Map<EObject, EObject> mapping, EReference srcReference,
		EReference tgtReference, List<Issue> issues) {
		if (tgtReference === null) {
			if (issues !== null) {
				issues.add(new Issue(srcReference, "No target mapping"))
			}
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
				if (issues !== null) {
					issues.add(new Issue(srcReference, "Source class mapping does not respect inheritance hierarchy"))
				}
				return false
			}
		}

		// def 5.1 check trgKeyValue must belong to a clan of trgValue
		if (mapping.containsKey(srcTgtClass)) {
			val EClass srcTgtClassMapping = mapping.get(srcTgtClass) as EClass
			if (!checkInClanOf(srcTgtClassMapping, tgtTgtClass)) {
				if (issues !== null) {
					issues.add(new Issue(srcReference, "Target class mapping does not respect inheritance hierarchy"))
				}
				return false
			}
		}

		true
	}

	/**
	 * Checks whether attributes are preserved in the model mapping
	 */
	static private def boolean checkModelAttributes(Map<EObject, EObject> mapping, List<Issue> issues) {
		!mapping.entrySet.filter[e|e.key instanceof EAttribute].exists [ e |
			!mapping.checkAttributeMapping(e.key as EAttribute, e.value as EAttribute, issues)
		]
	}

	static private def boolean checkAttributeMapping(Map<EObject, EObject> mapping, EAttribute srcAttribute,
		EAttribute tgtAttribute, List<Issue> issues) {
		if (tgtAttribute === null) {
			if (issues !== null) {
				issues.add(new Issue(srcAttribute, "No target mapping"))
			}
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
				if (issues !== null) {
					issues.add(
						new Issue(srcAttribute, "Containing class mapping does not respect inheritance hierarchy"))
				}
				return false
			}
		}

		// def 5.2 check that Data types are the same
		// FIXME This check might not actually work
		if (!srcType.equals(tgtType)) {
			if (issues !== null) {
				issues.add(new Issue(srcAttribute, "Attribute type mapping error"))
			}
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
