package uk.ac.kcl.inf.util

import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule

/**
 * Utility class to check type mappings for morphism properties.
 * 
 * Based on code by Kinga Bojarczuk
 */
class MorphismChecker {

	public static interface IssueAcceptor {
		def void issue(EObject object, String message)
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
	 * @param issues an acceptor for reporting any issues in more detail. Can be <code>null</code> to prevent issue reporting.
	 * 
	 * @return true if all checks succeeded  
	 */
	static def boolean checkValidMaybeIncompleteClanMorphism(Map<EObject, EObject> mapping, IssueAcceptor issues) {
		mapping.checkModelInheritance(issues) && mapping.checkModelAssociations(issues) &&
			mapping.checkModelAttributes(issues)
	}

	/**
	 * Check that the given mapping does not break the rules of behaviour morphisms (i.e., sets of rule morphisms). The objects 
	 * in the map may be Rules, Objects, or Links. All non-Rule objects in <code>mapping.keySet</code> 
	 * are assumed to be from a source GTS, all those in the value set are expected to 
	 * be from a target GTS. Rule objects are expected to be the other way around. There may be elements that are not 
	 * yet mapped by the given mapping. This will be accepted by the checker and the checker 
	 * will return true as long as the mappings provided do not break morphism constraints.
	 * 
	 * TODO: Provide reference to paper with morphism definition as part of the documentation
	 * 
	 * @param typeMapping the meta-model--mapping information. Assumed to be valid wrt clan-morphism rules
	 * @param behaviourMapping the mapping information to be validated
	 * @param issues an acceptor for reporting any issues in more detail. Can be <code>null</code> to prevent issue reporting.
	 * 
	 * @return true if all checks succeeded  
	 */
	static def boolean checkValidMaybeIncompleteBehaviourMorphism(Map<EObject, EObject> typeMapping,
		Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {
		!behaviourMapping.keySet.filter(Rule).exists [ r |
			!checkRuleMorphism(r, behaviourMapping.get(r) as Rule, typeMapping, behaviourMapping, issues)
		]
	}

	/**
	 * Check whether inheritance is preserved in the model mapping
	 */
	static private def boolean checkModelInheritance(Map<EObject, EObject> mapping, IssueAcceptor issues) {
		!mapping.entrySet.filter[e|e.key instanceof EClass].exists [ e |
			!mapping.checkClassInheritance(e.key as EClass, e.value as EClass, issues)
		]
	}

	/**
	 * Check whether a single EClass mapping is valid according to inheritance rules
	 */
	static private def boolean checkClassInheritance(Map<EObject, EObject> mapping, EClass source, EClass target,
		IssueAcceptor issues) {
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
						issues.issue(source,
							"Target class's inheritance hierarchy not compatible with mapped parts of source class's inheritance hierarchy")
					}
				]
				result.value
			} else {
				issues.issue(source, "No target mapping")
				false
			}
		}
	}

	/**
	 * Check whether associations are preserved in the model mapping
	 */
	static private def boolean checkModelAssociations(Map<EObject, EObject> mapping, IssueAcceptor issues) {
		if (issues === null) {
			// Fast check
			!mapping.entrySet.filter[e|e.key instanceof EReference].exists [ e |
				!mapping.checkReferenceMapping(e.key as EReference, e.value as EReference, issues)
			]
		} else {
			// Slower check finding all issues
			val result = new ValueHolder<Boolean>(true)
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
		EReference tgtReference, IssueAcceptor issues) {
		if (tgtReference === null) {
			if (issues !== null) {
				issues.issue(srcReference, "No target mapping")
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
					issues.issue(srcReference, "Source class mapping does not respect inheritance hierarchy")
				}
				return false
			}
		}

		// def 5.1 check trgKeyValue must belong to a clan of trgValue
		if (mapping.containsKey(srcTgtClass)) {
			val EClass srcTgtClassMapping = mapping.get(srcTgtClass) as EClass
			if (!checkInClanOf(srcTgtClassMapping, tgtTgtClass)) {
				if (issues !== null) {
					issues.issue(srcReference, "Target class mapping does not respect inheritance hierarchy")
				}
				return false
			}
		}

		true
	}

	/**
	 * Checks whether attributes are preserved in the model mapping
	 */
	static private def boolean checkModelAttributes(Map<EObject, EObject> mapping, IssueAcceptor issues) {
		!mapping.entrySet.filter[e|e.key instanceof EAttribute].exists [ e |
			!mapping.checkAttributeMapping(e.key as EAttribute, e.value as EAttribute, issues)
		]
	}

	static private def boolean checkAttributeMapping(Map<EObject, EObject> mapping, EAttribute srcAttribute,
		EAttribute tgtAttribute, IssueAcceptor issues) {
		if (tgtAttribute === null) {
			if (issues !== null) {
				issues.issue(srcAttribute, "No target mapping")
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
					issues.issue(srcAttribute, "Containing class mapping does not respect inheritance hierarchy")
				}
				return false
			}
		}

		// def 5.2 check that Data types are the same
		// FIXME This check might not actually work
		if (!srcType.equals(tgtType)) {
			if (issues !== null) {
				issues.issue(srcAttribute, "Attribute type mapping error")
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

	/**
	 * Check if tgtRule -> srcRule is a valid mapping (i.e., the mapped elements do not stop srcRule -> tgtRule from being a rule morphism). List any issues in the issues list provided.
	 */
	static private def boolean checkRuleMorphism(Rule tgtRule, Rule srcRule, Map<EObject, EObject> typeMapping,
		Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {

		val srcLhsPattern = srcRule.lhs
		val srcRhsPattern = srcRule.rhs
		val tgtLhsPattern = tgtRule.lhs
		val tgtRhsPattern = tgtRule.rhs

		// TODO: Consider adding checks for the actual patterns. We don't explicitly map them at the moment (and this only really makes sense for NACs/PACs, but Kinga's original code checked this nonetheless
		checkPatternMorphism(srcLhsPattern, tgtLhsPattern, typeMapping, behaviourMapping, issues) &&
			checkPatternMorphism(srcRhsPattern, tgtRhsPattern, typeMapping, behaviourMapping, issues) &&
			checkKPatternMorphism(srcRule, tgtRule, typeMapping, behaviourMapping, issues)
	}

	static private def boolean checkPatternMorphism(Pattern srcPattern, Pattern tgtPattern,
		Map<EObject, EObject> typeMapping, Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {

		srcPattern.objects.filter[o|behaviourMapping.containsKey(o)].fold(true, [ acc, o |
			checkObjectMorphism(o, behaviourMapping.get(o) as Object,
				srcPattern, tgtPattern, typeMapping, behaviourMapping, issues) && acc
		]) && srcPattern.links.filter[l|behaviourMapping.containsKey(l)].fold(true, [ acc, l |
			checkLinkMorphism(l, behaviourMapping.get(l) as Link, srcPattern, tgtPattern, typeMapping, behaviourMapping,
				issues) && acc
		])
	}

	static private def boolean checkObjectMorphism(Object srcObject,
		Object tgtObject, Pattern srcPattern, Pattern tgtPattern,
		Map<EObject, EObject> typeMapping, Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {
		if (tgtObject === null) {
			return false
		}

		if (!tgtPattern.objects.contains(tgtObject)) {
			if (issues !== null) {
				issues.issue(srcObject, "Mapped object is in a different rule pattern.")				
			}
			return false
		}

		val srcClassMap = typeMapping.get(srcObject.type)

		if (srcClassMap === null) {
			if (issues !== null) {
				issues.issue(srcObject, "Type of object not mapped by type mapping.")				
			}
			return false
		}

		if (srcClassMap !== tgtObject.type) {
			if (issues !== null) {
				issues.issue(srcObject, "Types of mapped objects don't match according to type mapping.")				
			}
			return false;
		}

		true
	}

	static private def boolean checkLinkMorphism(Link srcLink, Link tgtLink, Pattern srcPattern, Pattern tgtPattern,
		Map<EObject, EObject> typeMapping, Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {
		if (tgtLink === null) {
			return false;
		}

		if (!tgtPattern.links.contains(tgtLink)) {
			if (issues !== null) {
				issues.issue(srcLink, "Mapped link is in a different rule pattern.")				
			}
			return false
		}

		val srcRefMap = typeMapping.get(srcLink.type)

		if (srcRefMap === null) {
			if (issues !== null) {
				issues.issue(srcLink, "Type of link not mapped by type mapping.")				
			}
			return false
		}

		if (srcRefMap !== tgtLink.type) {
			if (issues !== null) {
				issues.issue(srcLink, "Types of mapped links don't match according to type mapping.")				
			}
			return false;
		}

		true
	}

	static private def boolean checkKPatternMorphism(Rule srcRule, Rule tgtRule, Map<EObject, EObject> typeMapping,
		Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {
		// FIXME: What's needed here with the new encoding?
		true
	}
}
