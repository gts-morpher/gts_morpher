package uk.ac.kcl.inf.gts_morpher.util

import java.util.HashMap
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.ModelElement
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule

import static extension uk.ac.kcl.inf.util.henshinsupport.NamingHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.isVirtualRule

/**
 * Utility class to check type mappings for morphism properties.
 * 
 * Based on code by Kinga Bojarczuk
 */
class MorphismChecker {

	public static val GENERAL_KERNEL_MISMATCH = "General kernel mismatch"

	static interface IssueAcceptor {
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
		
		// Multiplicities must match
		if (srcReference.lowerBound != tgtReference.lowerBound) {
			if (issues !== null) {
				issues.issue(srcReference, "Target reference must have same lower-bound multiplicity.")
			}
			return false
		}
		if (srcReference.upperBound != tgtReference.upperBound) {
			if (issues !== null) {
				issues.issue(srcReference, "Target reference must have same upper-bound multiplicity.")
			}
			return false
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
		val srcContainingClass = srcAttribute.eContainer as EClass
		val srcType = srcAttribute.EType

		val tgtContainingClass = tgtAttribute.eContainer as EClass
		val tgtType = tgtAttribute.EType

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
	static def boolean checkRuleMorphism(Rule tgtRule, Rule srcRule, Map<EObject, EObject> typeMapping,
		Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {

		if (!tgtRule.isVirtualRule) {
			val srcLhsPattern = srcRule.lhs
			val srcRhsPattern = srcRule.rhs
			val tgtLhsPattern = tgtRule.lhs
			val tgtRhsPattern = tgtRule.rhs
	
			// TODO: Consider adding checks for the actual patterns. We don't explicitly map them at the moment (and this only really makes sense for NACs/PACs, but Kinga's original code checked this nonetheless
			checkPatternMorphism(srcLhsPattern, tgtLhsPattern, typeMapping, behaviourMapping, issues) &&
				checkPatternMorphism(srcRhsPattern, tgtRhsPattern, typeMapping, behaviourMapping, issues) &&
				checkKPatternMorphism(srcRule, tgtRule, typeMapping, behaviourMapping, issues)
				
		} else {
			// to-virtual rule mappings are valid by default, so no need to check in detail
			true
		}
	}

	static private def boolean checkPatternMorphism(Graph srcPattern, Graph tgtPattern,
		Map<EObject, EObject> typeMapping, Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {

		srcPattern.nodes.filter[o|behaviourMapping.containsKey(o)].fold(true, [ acc, o |
			checkObjectMorphism(o, behaviourMapping.get(o) as Node, srcPattern, tgtPattern, typeMapping,
				behaviourMapping, issues) && acc
		]) && srcPattern.edges.filter[l|behaviourMapping.containsKey(l)].fold(true, [ acc, l |
			checkLinkMorphism(l, behaviourMapping.get(l) as Edge, srcPattern, tgtPattern, typeMapping, behaviourMapping,
				issues) && acc
		])
	}

	static private def boolean checkObjectMorphism(Node srcObject, Node tgtObject, Graph srcPattern,
		Graph tgtPattern, Map<EObject, EObject> typeMapping, Map<EObject, EObject> behaviourMapping,
		IssueAcceptor issues) {
		if (tgtObject === null) {
			return false
		}

		if (!tgtPattern.nodes.contains(tgtObject)) {
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
		
		// Check attribute mappings, if any
		val result = new ValueHolder(true)
		srcObject.attributes.forEach[srcAttribute | 
			if (behaviourMapping.containsKey(srcAttribute)) {
				result.value = result.value && checkSlotMorphism(srcAttribute, behaviourMapping.get(srcAttribute) as Attribute, srcObject, tgtObject, typeMapping, issues)
			}
		]

		result.value
	}
	
	static private def boolean checkSlotMorphism(Attribute srcAttribute, Attribute tgtAttribute, Node srcObject, Node tgtObject, Map<EObject, EObject> typeMapping, IssueAcceptor issues) {
		if ((srcAttribute.eContainer === srcObject) && (tgtAttribute.eContainer === tgtObject)) {
			val srcEAttribute = srcAttribute.type
			val mappedSrcEAttribute = typeMapping.get(srcEAttribute)
			
			if ((mappedSrcEAttribute !== null) && (mappedSrcEAttribute !== tgtAttribute.type)) {
				if (issues !== null) {
					issues.issue(srcAttribute, "Mapped slots must be for mapped attributes.")
				}

				false
			} else {
				if (srcAttribute.value == tgtAttribute.value) {
					true
				} else {
					if (issues !== null) {
						issues.issue(srcAttribute, "Mapped slots must have the (syntactically) same value expressions.")
					}

					false
				}
			}
		} else {
			if (issues !== null) {
				issues.issue(srcAttribute, "Mapped slots must be for mapped objects.")
			}
			
			false
		}
	}

	static private def boolean checkLinkMorphism(Edge srcLink, Edge tgtLink, Graph srcPattern, Graph tgtPattern,
		Map<EObject, EObject> typeMapping, Map<EObject, EObject> behaviourMapping, IssueAcceptor issues) {
		if (tgtLink === null) {
			return false;
		}

		if (!tgtPattern.edges.contains(tgtLink)) {
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
		val srcKernel = srcRule.kernel
		val tgtKernel = tgtRule.kernel

		val _result = new ValueHolder(true)
		srcKernel.entrySet.forEach [ e |
			val srcO1 = e.value.key
			val srcO2 = e.value.value

			val srcO1Mapped = typeMapping.get(srcO1)
			val srcO2Mapped = typeMapping.get(srcO2)

			if ((srcO1Mapped !== null) && (srcO2Mapped !== null)) {
				/*
				 * If only one of them is null, we've constructed the mapping wrong -- or this is a partially constructed completion
				 */
				if (!srcO1Mapped.name.equals(srcO2Mapped.name)) {
					if (issues !== null) {
						issues.issue(srcO1, "Element of kernel rule mapped to different elements in target rule")
						issues.issue(srcO2, "Element of kernel rule mapped to different elements in target rule")
					}
					_result.value = false
				} else {
					val tgtKernelElements = tgtKernel.get(srcO1Mapped.name)
					if (!((tgtKernelElements !== null) &&
						((tgtKernelElements.key == srcO1Mapped) && (tgtKernelElements.value == srcO2Mapped) ||
							(tgtKernelElements.key == srcO2Mapped) && (tgtKernelElements.value == srcO1Mapped)))) {
						if (issues !== null) {
							issues.issue(srcO1, "Element of kernel rule mapped to non-kernel element in target rule")
							issues.issue(srcO2, "Element of kernel rule mapped to non-kernel element in target rule")
						}
						_result.value = false
					}
				}
			}
		]

		_result.value
	}

	static private def Map<String, Pair<ModelElement, ModelElement>> getKernel(Rule rule) {
		val _kernel = new ValueHolder(new HashMap<String, Pair<ModelElement, ModelElement>>)

		rule.lhs.nodes.forEach [ lo |
			val ro = rule.rhs.nodes.findFirst[ro|ro.name.equals(lo.name)]
			if (ro !== null) {
				_kernel.value.put(lo.name, new Pair(lo, ro))
			}
		]
		rule.lhs.edges.forEach [ ll |
			val rl = rule.rhs.edges.findFirst[rl|rl.name.equals(ll.name)]
			if (rl !== null) {
				_kernel.value.put(ll.name, new Pair(ll, rl))
			}
		]

		_kernel.value
	}
}
