package uk.ac.kcl.inf.gts_morpher.util

import java.util.HashMap
import java.util.Map
import java.util.Map.Entry
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.henshin.adapters.xtext.HenshinQualifiedNameProvider
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Parameter
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.scoping.IScope
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.AttributeMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.BehaviourMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.ClassMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationOrReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GtsMorpherFactory
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GtsMorpherPackage
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.LinkMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.ObjectMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.ReferenceMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.RuleElementMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.RuleMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.RuleParameterMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.SlotMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.TypeGraphMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.TypeMapping

import static org.eclipse.xtext.scoping.Scopes.*

import static extension org.eclipse.emf.henshin.adapters.xtext.NamingHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.isInterfaceElement
import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.HenshinChecker.isIdentityRule

/**
 * Basic util methods for extracting mappings from GTSMappings and vice versa.
 */
class MappingConverter {
	public static val DUPLICATE_CLASS_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_CLASS_MAPPING'
	public static val DUPLICATE_REFERENCE_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_REFERENCE_MAPPING'
	public static val DUPLICATE_ATTRIBUTE_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_ATTRIBUTE_MAPPING'
	public static val DUPLICATE_RULE_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_RULE_MAPPING'
	public static val DUPLICATE_OBJECT_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_OBJECT_MAPPING'
	public static val DUPLICATE_PARAMETER_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_PARAMETER_MAPPING'
	public static val DUPLICATE_LINK_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_LINK_MAPPING'
	public static val DUPLICATE_SLOT_MAPPING = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.DUPLICATE_SLOT_MAPPING'
	public static val NON_INTERFACE_CLASS_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.NON_INTERFACE_CLASS_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_OBJECT_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.NON_INTERFACE_OBJECT_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_LINK_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.NON_INTERFACE_LINK_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_SLOT_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.gts_morpher.xdsml_compose.NON_INTERFACE_SLOT_MAPPING_ATTEMPT'

	static interface IssueAcceptor {
		def void error(String message, EObject source, EStructuralFeature feature, String code, String... issueData)
	}

	/**
	 * Extract the type mapping specified as a map object. Report duplicate entries as errors via the IssueAcceptor provided, if any.
	 */
	static def Map<EObject, EObject> extractMapping(TypeGraphMapping mapping, IssueAcceptor issues) {
		val Map<EObject, EObject> _mapping = new HashMap

		val srcIsInterface = (mapping.eContainer as GTSMapping).source.interface_mapping
		val tgtIsInterface = (mapping.eContainer as GTSMapping).target.interface_mapping

		mapping.mappings.filter(ClassMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				issues.safeError('''Duplicate mapping for EClassifier «cm.source.name».''', cm,
					GtsMorpherPackage.Literals.CLASS_MAPPING__SOURCE, DUPLICATE_CLASS_MAPPING)
			} else {
				if ((srcIsInterface) && (!cm.source.isInterfaceElement)) {
					issues.safeError('''EClassifier «cm.source.name» must be annotated as interface to be mapped.''',
						cm, GtsMorpherPackage.Literals.CLASS_MAPPING__SOURCE, NON_INTERFACE_CLASS_MAPPING_ATTEMPT)
				} else if ((tgtIsInterface) && (!cm.target.isInterfaceElement)) {
					issues.safeError('''EClassifier «cm.target.name» must be annotated as interface to be mapped.''',
						cm, GtsMorpherPackage.Literals.CLASS_MAPPING__TARGET, NON_INTERFACE_CLASS_MAPPING_ATTEMPT)
				} else {
					_mapping.put(cm.source, cm.target)
				}
			}
		]

		mapping.mappings.filter(ReferenceMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				issues.safeError('''Duplicate mapping for EReference «cm.source.name».''', cm,
					GtsMorpherPackage.Literals.REFERENCE_MAPPING__SOURCE, DUPLICATE_REFERENCE_MAPPING)
			} else {
				if ((srcIsInterface) && (!cm.source.isInterfaceElement)) {
					issues.safeError('''EReference «cm.source.name» must be annotated as interface to be mapped.''', cm,
						GtsMorpherPackage.Literals.REFERENCE_MAPPING__SOURCE, NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT)
				} else if ((tgtIsInterface) && (!cm.target.isInterfaceElement)) {
					issues.safeError('''EReference «cm.target.name» must be annotated as interface to be mapped.''', cm,
						GtsMorpherPackage.Literals.REFERENCE_MAPPING__TARGET, NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT)
				} else {
					_mapping.put(cm.source, cm.target)
				}
			}
		]

		mapping.mappings.filter(AttributeMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				issues.safeError('''Duplicate mapping for EAttribute «cm.source.name».''', cm,
					GtsMorpherPackage.Literals.ATTRIBUTE_MAPPING__SOURCE, DUPLICATE_ATTRIBUTE_MAPPING)
			} else {
				if ((srcIsInterface) && (!cm.source.isInterfaceElement)) {
					issues.safeError('''EAttribute «cm.source.name» must be annotated as interface to be mapped.''', cm,
						GtsMorpherPackage.Literals.ATTRIBUTE_MAPPING__SOURCE, NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT)
				} else if ((tgtIsInterface) && (!cm.target.isInterfaceElement)) {
					issues.safeError('''EAttribute «cm.target.name» must be annotated as interface to be mapped.''', cm,
						GtsMorpherPackage.Literals.ATTRIBUTE_MAPPING__TARGET, NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT)
				} else {
					_mapping.put(cm.source, cm.target)
				}
			}
		]

		_mapping
	}

	/**
	 * Extract the rule mapping specified as a map object. Report duplicate entries as errors via the IssueAcceptor provided, if any. 
	 * 
	 * Mapping extraction will create virtual rules for to-identity mappings. To inform the types to be used in these virtual rules, 
	 * it will use the type mapping provided, which should be derived from the typemapping in the GTSSpecification of the behaviour mapping given.
	 */
	static def Map<EObject, EObject> extractMapping(BehaviourMapping mapping, Map<EObject, EObject> typeGraphMapping,
		IssueAcceptor issues) {
		val _mapping = new HashMap<EObject, EObject>

		if (mapping === null) {
			return _mapping
		}

		val srcIsInterface = (mapping.eContainer as GTSMapping).source.interface_mapping
		val tgtIsInterface = (mapping.eContainer as GTSMapping).target.interface_mapping

		mapping.mappings.forEach [ rm |
			if (_mapping.containsKey(rm.target)) {
				issues.safeError("Duplicate mapping for Rule " + rm.target.name + ".", rm,
					GtsMorpherPackage.Literals.RULE_MAPPING__TARGET, DUPLICATE_RULE_MAPPING)
			} else {
				if (rm.target_virtual) {
					if (rm.target_identity) {
						rm.extractTgtIdentityMapping(_mapping, srcIsInterface, typeGraphMapping)
					} else {
						rm.extractTgtVirtualMapping(_mapping, srcIsInterface, typeGraphMapping)
					}
				} else if (rm.source_empty) {
					rm.extractSrcEmptyMapping(_mapping)
				} else {
					rm.extractMapping(_mapping, srcIsInterface, tgtIsInterface, issues)
				}
			}
		]

		_mapping
	}

	static def GTSMapping extractGTSMapping(Map<? extends EObject, ? extends EObject> mapping,
		GTSSpecificationOrReference from, GTSSpecificationOrReference to, Resource res) {
		if (res === null) {
			throw new IllegalArgumentException("res must not be null")
		}

		val module = GtsMorpherFactory.eINSTANCE.createGTSSpecificationModule
		res.contents.add(module)

		val result = GtsMorpherFactory.eINSTANCE.createGTSMapping
		module.members.add(result)

		result.source = from.resourceLocalCopy
		result.target = to.resourceLocalCopy

		result.typeMapping = GtsMorpherFactory.eINSTANCE.createTypeGraphMapping
		result.typeMapping.mappings.addAll(
					mapping.entrySet.filter [ e |
			(e.key instanceof EClass) || (e.key instanceof EStructuralFeature)
		].map [ e |
			e.key.extractTypeMapping(e.value, result)
		])

		val behaviourMappings = mapping.entrySet.reject [ e |
			(e.key instanceof EClass) || (e.key instanceof EStructuralFeature)
		]
		if (!behaviourMappings.empty) {
			result.behaviourMapping = GtsMorpherFactory.eINSTANCE.createBehaviourMapping
			result.behaviourMapping.mappings.addAll(behaviourMappings.filter[e|e.key instanceof Rule].map [ e |
				(e.key as Rule).extractRuleMapping(e.value as Rule, behaviourMappings, result)
			])
		}

		result
	}

	private static dispatch def TypeMapping extractTypeMapping(EObject src, EObject tgt, GTSMapping mapping) { null }

	private static dispatch def TypeMapping extractTypeMapping(EClass srcClass, EClass tgtClass, GTSMapping mapping) {
		val result = GtsMorpherFactory.eINSTANCE.createClassMapping
		result.source = srcClass.correspondingSourceElement(mapping)
		result.target = tgtClass.correspondingTargetElement(mapping)

		result
	}

	private static dispatch def TypeMapping extractTypeMapping(EReference srcReference, EReference tgtReference,
		GTSMapping mapping) {
		val result = GtsMorpherFactory.eINSTANCE.createReferenceMapping
		result.source = srcReference.correspondingSourceElement(mapping)
		result.target = tgtReference.correspondingTargetElement(mapping)

		result
	}

	private static dispatch def TypeMapping extractTypeMapping(EAttribute srcAttribute, EAttribute tgtAttribute,
		GTSMapping mapping) {
		val result = GtsMorpherFactory.eINSTANCE.createAttributeMapping
		result.source = srcAttribute.correspondingSourceElement(mapping)
		result.target = tgtAttribute.correspondingTargetElement(mapping)

		result
	}

	private static def RuleMapping extractRuleMapping(Rule tgtRule, Rule srcRule,
		Iterable<? extends Entry<? extends EObject, ? extends EObject>> behaviourMappings, GTSMapping mapping) {
		val result = GtsMorpherFactory.eINSTANCE.createRuleMapping

		if (srcRule.isEmptyRule) {
			result.source_empty = true
			result.target = tgtRule.correspondingTargetElement(mapping)
		} else {
			result.source = srcRule.correspondingSourceElement(mapping)

			if (tgtRule.isVirtualRule) {
				result.target_virtual = true

				if (tgtRule.isVirtualIdentityRule) {
					result.target_identity = true
				}
			} else {
				result.target = tgtRule.correspondingTargetElement(mapping)

				result.element_mappings.addAll(behaviourMappings.filter [ e |
					// Ensure kernel elements are included only once in the mapping and with their lhs representative
					if ((e.key instanceof GraphElement) && (e.key.eContainer.eContainer === srcRule)) {
						if (e.key.eContainer === srcRule.rhs) {
							!(srcRule.lhs.nodes.exists[n|n.name == e.key.name] || srcRule.lhs.edges.exists [ ed |
								ed.name == e.key.name
							])
						} else {
							true
						}
					} else if ((e.key instanceof Attribute) && (e.key.eContainer.eContainer.eContainer === srcRule)) {
						if (e.key.eContainer.eContainer == srcRule.rhs) {
							!(srcRule.lhs.nodes.exists [ n |
								(n.name == e.key.eContainer.name) && n.attributes.exists [ a |
									a.type === (e.key as Attribute).type
								]
							])
						} else {
							true
						}
					} else if ((e.key instanceof Parameter) && (e.key.eContainer === srcRule)) {
						true
					} else {
						false
					}
				].map [ e |
					e.key.extractRuleElementMapping(e.value, mapping)
				])
			}
		}

		result
	}

	static val IDENTITY_RULE_ANNOTATION_KEY = "uk.ac.kcl.inf.gts_morpher.xdsml_compose.rule_mappings.virtual.identity"
	static val VIRTUAL_RULE_ANNOTATION_KEY = "uk.ac.kcl.inf.gts_morpher.xdsml_compose.rule_mappings.virtual"
	static val EMPTY_RULE_ANNOTATION_KEY = "uk.ac.kcl.inf.gts_morpher.xdsml_compose.rule_mappings.empty"

	private static def hasAnnotation(Rule r, String sAnnotation) {
		r.annotations.exists[a|a.key == sAnnotation]
	}

	private static def setAnnotation(Rule r, String sAnnotation, boolean set) {
		r.annotations.removeIf([a|a.key == sAnnotation])
		if (set) {
			val annotation = createAnnotation
			annotation.key = sAnnotation
			r.annotations.add(annotation)
		}
	}

	static def isEmptyRule(Rule r) {
		r.hasAnnotation(EMPTY_RULE_ANNOTATION_KEY)
	}

	static def setIsEmptyRule(Rule r, boolean b) {
		r.setAnnotation(EMPTY_RULE_ANNOTATION_KEY, b)
	}

	static def isVirtualRule(Rule r) {
		r.hasAnnotation(VIRTUAL_RULE_ANNOTATION_KEY)
	}

	static def setIsVirtualRule(Rule r, boolean b) {
		r.setAnnotation(VIRTUAL_RULE_ANNOTATION_KEY, b)
	}

	static def isVirtualIdentityRule(Rule r) {
		r.hasAnnotation(IDENTITY_RULE_ANNOTATION_KEY)
	}

	static def setIsVirtualIdentityRule(Rule r, boolean b) {
		r.setAnnotation(IDENTITY_RULE_ANNOTATION_KEY, b)
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(EObject src, EObject tgt,
		GTSMapping mapping) {
		null
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Node srcNode, Node tgtNode,
		GTSMapping mapping) {
		GtsMorpherFactory.eINSTANCE.createObjectMapping => [
			source = srcNode.correspondingSourceElement(mapping)
			target = tgtNode.correspondingTargetElement(mapping)
		]
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Edge srcEdge, Edge tgtEdge,
		GTSMapping mapping) {
		GtsMorpherFactory.eINSTANCE.createLinkMapping => [
			source = srcEdge.correspondingSourceElement(mapping)
			target = tgtEdge.correspondingTargetElement(mapping)
		]
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Attribute srcAttribute,
		Attribute tgtAttribute, GTSMapping mapping) {
		GtsMorpherFactory.eINSTANCE.createSlotMapping => [
			source = srcAttribute.correspondingSourceElement(mapping)
			target = tgtAttribute.correspondingTargetElement(mapping)
		]
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Parameter srcParameter,
		Parameter tgtParameter, GTSMapping mapping) {
		GtsMorpherFactory.eINSTANCE.createRuleParameterMapping => [
			source = srcParameter.correspondingSourceElement(mapping)
			target = tgtParameter.correspondingTargetElement(mapping)
		]
	}

	/**
	 * Create a copy up to the end of the containing resource, if any.
	 */
	static def <T extends EObject> T getResourceLocalCopy(T object) {
		val copier = new EcoreUtil.Copier()
		val copy = copier.copy(object) as T
		copier.copyReferences

		copy
	}

	static val IQualifiedNameProvider nameProvider = new DefaultDeclarativeQualifiedNameProvider
	static val IQualifiedNameProvider henshinNameProvider = new HenshinQualifiedNameProvider

	/**
	 * Find the corresponding element in the given GTS specification. This is necessary as some parts of the type graph and rules will be virtual (e.g., generated from a family choice) 
	 * and the actual objects will be different when we reconstruct the GTSMapping from the Map. 
	 */
	private static def <T extends EObject> T correspondingSourceElement(T object, GTSMapping mapping) {
		object.correspondingElement(mapping.source) as T
	}

	private static def <T extends EObject> T correspondingTargetElement(T object, GTSMapping mapping) {
		object.correspondingElement(mapping.target) as T
	}

	private static dispatch def EObject correspondingElement(EObject object, GTSReference specification) {
		object.correspondingElement(specification.ref)
	}

	private static dispatch def EObject correspondingElement(EObject object, GTSSpecification specification) { null }

	private static dispatch def EObject correspondingElement(EClass clazz, GTSSpecification specification) {
		clazz.getCorrespondingElement(specification.metamodel)
	}

	private static dispatch def EObject correspondingElement(EReference ref, GTSSpecification specification) {
		ref.getCorrespondingElement(specification.metamodel)
	}

	private static dispatch def EObject correspondingElement(EAttribute attr, GTSSpecification specification) {
		attr.getCorrespondingElement(specification.metamodel)
	}

	private static dispatch def EObject correspondingElement(Module module, GTSSpecification specification) {
		module.getCorrespondingElement(specification.behaviour)
	}

	private static dispatch def EObject correspondingElement(Rule rule, GTSSpecification specification) {
		rule.getCorrespondingElement(specification.behaviour)
	}

	private static dispatch def EObject correspondingElement(GraphElement ge, GTSSpecification specification) {
		ge.getCorrespondingElement(specification.behaviour)
	}

	private static dispatch def EObject correspondingElement(Attribute attr, GTSSpecification specification) {
		attr.getCorrespondingElement(specification.behaviour)
	}

	private static dispatch def EObject correspondingElement(Parameter param, GTSSpecification specification) {
		param.getCorrespondingElement(specification.behaviour)
	}

	private static def EObject getCorrespondingElement(EObject object, EPackage pck) {
		val scope = scopeFor([pck.eAllContents], nameProvider, IScope.NULLSCOPE)
		val name = nameProvider.getFullyQualifiedName(object)

		scope.getSingleElement(name).EObjectOrProxy
	}

	private static def EObject getCorrespondingElement(EObject object, Module module) {
		val scope = scopeFor([module.eAllContents], henshinNameProvider, IScope.NULLSCOPE)
		val name = henshinNameProvider.getFullyQualifiedName(object)

		scope.getSingleElement(name).EObjectOrProxy
	}

	private static def <K, V> void putIfNotNull(HashMap<K, V> map, K key, V value) {
		if ((key !== null) && (value !== null)) {
			map.put(key, value)
		}
	}

	private static def void safeError(IssueAcceptor issues, String message, EObject source, EStructuralFeature feature,
		String code, String... issueData) {
		if (issues !== null) {
			issues.error(message, source, feature, code, issueData)
		}
	}

	private static def extractMapping(RuleMapping rm, HashMap<EObject, EObject> _mapping, boolean srcIsInterface,
		boolean tgtIsInterface, IssueAcceptor issues) {
		_mapping.put(rm.target, rm.source)

		rm.element_mappings.filter(RuleParameterMapping).forEach [ rpm |
			if (_mapping.containsKey(rpm.source)) {
				issues.safeError("Duplicate mapping for Parameter " + rpm.source.name + ".", rpm,
					GtsMorpherPackage.Literals.OBJECT_MAPPING__SOURCE, DUPLICATE_PARAMETER_MAPPING)
			} else {
				_mapping.put(rpm.source, rpm.target)
			}
		]
		rm.element_mappings.filter(ObjectMapping).forEach [ em |
			if (_mapping.containsKey(em.source)) {
				issues.safeError("Duplicate mapping for Object " + em.source.name + ".", em,
					GtsMorpherPackage.Literals.OBJECT_MAPPING__SOURCE, DUPLICATE_OBJECT_MAPPING)
			} else if (srcIsInterface && !em.source.type.isInterfaceElement) {
				issues.safeError('''Object «em.source.name» must be an interface element to be mapped.''', em,
					GtsMorpherPackage.Literals.OBJECT_MAPPING__SOURCE, NON_INTERFACE_OBJECT_MAPPING_ATTEMPT)
			} else if (tgtIsInterface && !em.target.type.isInterfaceElement) {
				issues.safeError('''Object «em.target.name» must be an interface element to be mapped.''', em,
					GtsMorpherPackage.Literals.OBJECT_MAPPING__TARGET, NON_INTERFACE_OBJECT_MAPPING_ATTEMPT)
			} else {
				_mapping.put(em.source, em.target)

				val srcRule = em.source.eContainer.eContainer as Rule
				val tgtRule = em.target.eContainer.eContainer as Rule

				val srcNodeAlias = srcRule.getKernelAliasFor(em.source)
				val tgtNodeAlias = tgtRule.getKernelAliasFor(em.target)

				_mapping.putIfNotNull(srcNodeAlias, tgtNodeAlias)
			}
		]
		rm.element_mappings.filter(LinkMapping).forEach [ em |
			if (_mapping.containsKey(em.source)) {
				issues.safeError("Duplicate mapping for Link " + em.source.name + ".", em,
					GtsMorpherPackage.Literals.LINK_MAPPING__SOURCE, DUPLICATE_LINK_MAPPING)
			} else if (srcIsInterface && !em.source.type.isInterfaceElement) {
				issues.safeError('''Link «em.source.name» must be an interface element to be mapped.''', em,
					GtsMorpherPackage.Literals.LINK_MAPPING__SOURCE, NON_INTERFACE_LINK_MAPPING_ATTEMPT)
			} else if (tgtIsInterface && !em.target.type.isInterfaceElement) {
				issues.safeError('''Link «em.target.name» must be an interface element to be mapped.''', em,
					GtsMorpherPackage.Literals.LINK_MAPPING__TARGET, NON_INTERFACE_LINK_MAPPING_ATTEMPT)
			} else {
				_mapping.put(em.source, em.target)

				val srcPattern = em.source.eContainer as Graph
				val srcRule = em.source.eContainer.eContainer as Rule
				val tgtRule = em.target.eContainer.eContainer as Rule

				val srcSrcNodeAlias = srcRule.getKernelAliasFor(em.source.source)
				val srcTgtNodeAlias = srcRule.getKernelAliasFor(em.source.target)
				val tgtSrcNodeAlias = tgtRule.getKernelAliasFor(em.target.source)
				val tgtTgtNodeAlias = tgtRule.getKernelAliasFor(em.target.target)

				if (srcPattern == srcRule.lhs) {
					// Also add corresponding RHS link, if any
					_mapping.putIfNotNull(
						srcRule.rhs.edges.findFirst[(source === srcSrcNodeAlias) && (target === srcTgtNodeAlias)],
						tgtRule.rhs.edges.findFirst[(source === tgtSrcNodeAlias) && (target === tgtTgtNodeAlias)]
					)
				} else if (srcPattern == srcRule.rhs) {
					// Also add corresponding LHS link, if any							
					_mapping.putIfNotNull(
						srcRule.lhs.edges.findFirst[(source === srcSrcNodeAlias) && (target === srcTgtNodeAlias)],
						tgtRule.lhs.edges.findFirst[(source === tgtSrcNodeAlias) && (target === tgtTgtNodeAlias)]
					)
				}
			}
		]
		rm.element_mappings.filter(SlotMapping).forEach [ em |
			if (_mapping.containsKey(em.source)) {
				issues.safeError("Duplicate mapping for Slot " + em.source.name + ".", em,
					GtsMorpherPackage.Literals.SLOT_MAPPING__SOURCE, DUPLICATE_SLOT_MAPPING)
			} else if (srcIsInterface && !em.source.type.isInterfaceElement) {
				issues.safeError('''Slot «em.source.name» must be an interface element to be mapped.''', em,
					GtsMorpherPackage.Literals.SLOT_MAPPING__SOURCE, NON_INTERFACE_SLOT_MAPPING_ATTEMPT)
			} else if (tgtIsInterface && !em.target.type.isInterfaceElement) {
				issues.safeError('''Slot «em.target.name» must be an interface element to be mapped.''', em,
					GtsMorpherPackage.Literals.SLOT_MAPPING__TARGET, NON_INTERFACE_SLOT_MAPPING_ATTEMPT)
			} else {
				_mapping.put(em.source, em.target)

				val srcNode = em.source.eContainer as Node
				val tgtNode = em.target.eContainer as Node

				val srcPattern = srcNode.eContainer as Graph
				val srcRule = srcPattern.eContainer as Rule

				val tgtRule = tgtNode.eContainer.eContainer as Rule

				val srcNodeAlias = srcRule.getKernelAliasFor(srcNode)
				val tgtNodeAlias = tgtRule.getKernelAliasFor(tgtNode)

				_mapping.putIfNotNull(
					srcNodeAlias?.attributes?.findFirst[a|a.type === em.source.type], tgtNodeAlias?.attributes?.
					findFirst[a|a.type === em.target.type])
			}
		]
	}

	static extension val HenshinFactory FACTORY = HenshinFactory.eINSTANCE

	/**
	 * Generate a mapping from a virtual empty rule for this rule mapping
	 */
	private static def extractSrcEmptyMapping(RuleMapping rm, HashMap<EObject, EObject> _mapping) {
		// Just in case...
		if (!rm.source_empty) {
			throw new IllegalStateException
		}

		_mapping.putAll(rm.target.extractSrcEmptyMapping)
	}

	static def extractSrcEmptyMapping(Rule targetRule) {
		// Generate a suitable virtual rule
		val virtualRule = createRule(targetRule.name)
		virtualRule.isEmptyRule = true

		// Must add the rule to some module, even if we just make it up... 
		// Weaving will assume to be able to navigate up from rules, but will actually never use the module
		val module = createModule
		module.units.add(virtualRule)

		val lhs = createGraph("Lhs")
		val rhs = createGraph("Rhs")

		virtualRule.lhs = lhs
		virtualRule.rhs = rhs

		val result = new HashMap<EObject, EObject>
		result.putIfNotNull(targetRule, virtualRule)
		result
	}

	/**
	 * Generate a virtual identity rule to map to for this rule mapping
	 */
	private static def extractTgtIdentityMapping(RuleMapping rm, HashMap<EObject, EObject> _mapping,
		boolean srcIsInterface, Map<EObject, EObject> tgMapping) {
		// Just in case...
		if (!rm.target_identity) {
			throw new IllegalStateException
		}

		_mapping.putAll(rm.source.extractTgtIdentityMapping(srcIsInterface, tgMapping))
	}

	/**
	 * Generate a virtual rule to map to for this rule mapping
	 */
	private static def extractTgtVirtualMapping(RuleMapping rm, HashMap<EObject, EObject> _mapping,
		boolean srcIsInterface, Map<EObject, EObject> tgMapping) {
		// Just in case...
		if (!rm.target_virtual) {
			throw new IllegalStateException
		}

		_mapping.putAll(rm.source.extractTgtVirtualMapping(srcIsInterface, tgMapping))
	}

	/**
	 * Generate a virtual identity rule to map to for this rule mapping
	 */
	static def extractTgtIdentityMapping(Rule r, boolean srcIsInterface, Map<EObject, EObject> tgMapping) {
		if (r.isIdentityRule(srcIsInterface)) {
			val result = r.extractTgtVirtualMapping(srcIsInterface, tgMapping)

			(result.keySet.findFirst[vr|result.get(vr) == r] as Rule).isVirtualIdentityRule = true

			result
		} else {
			emptyMap
		}
	}

	/**
	 * Generate a virtual rule to map to for this rule mapping
	 */
	static def extractTgtVirtualMapping(Rule r, boolean srcIsInterface, Map<EObject, EObject> tgMapping) {
		var result = new HashMap<EObject, EObject>

		// Generate a suitable virtual rule
		val virtualRule = createRule(r.name)
		result.putIfNotNull(virtualRule, r)
		virtualRule.isVirtualRule = true

		// Must add the rule to some module, even if we just make it up... 
		// Weaving will assume to be able to navigate up from rules, but will actually never use the module
		val module = createModule
		module.units.add(virtualRule)

		val lhs = createGraph("Lhs")
		val rhs = createGraph("Rhs")

		virtualRule.lhs = lhs
		virtualRule.rhs = rhs

		// Generate all the nodes
		result.createVirtualNodesFor(r.lhs, lhs, tgMapping, srcIsInterface)
		result.createVirtualNodesFor(r.rhs, rhs, tgMapping, srcIsInterface)
		result.createVirtualMappings(r, virtualRule)

		// Generate all edges
		result.createVirtualEdges(r.lhs, lhs, tgMapping, srcIsInterface)
		result.createVirtualEdges(r.rhs, rhs, tgMapping, srcIsInterface)

		result.createVirtualParameters(r, virtualRule, tgMapping, srcIsInterface)

		result
	}

	private static def createVirtualParameters(Map<EObject, EObject> _mapping, Rule srcRule, Rule tgtRule,
		Map<EObject, EObject> tgMapping, boolean interfaceOnly) {
		// TODO: Account for interfaceOnly parameter
		srcRule.parameters.forEach [ p |
			_mapping.put(p, createParameter => [
				unit = tgtRule
				if (p.type instanceof EClass) {
					type = p.type.getMapped(tgMapping)				
				} else {
					type = p.type
				}
				name = p.name
				kind = p.kind
				description = p.description
			])
		]
	}

	private static def createVirtualNodesFor(Map<EObject, EObject> _mapping, Graph srcGraph, Graph tgtGraph,
		Map<EObject, EObject> tgMapping, boolean interfaceOnly) {
		srcGraph.nodes.filter[n|!interfaceOnly || n.isInterfaceElement].forEach [ n |
			val newNode = createNode(tgtGraph, n.type.getMapped(tgMapping), n.name)
			_mapping.put(n, newNode)

			n.attributes.filter[a|!interfaceOnly || a.type.isInterfaceElement].forEach [ a |
				val newAttribute = createAttribute(newNode, a.type.getMapped(tgMapping), a.value)
				_mapping.put(a, newAttribute)
			]
		]
	}

	private static def createVirtualMappings(Map<EObject, EObject> _mapping, Rule srcRule, Rule tgtRule) {
		srcRule.mappings.forEach [ mp |
			if (_mapping.containsKey(mp.origin)) {
				tgtRule.mappings.add(createMapping(_mapping.get(mp.origin) as Node, _mapping.get(mp.image) as Node))
			}
		]
	}

	private static def createVirtualEdges(Map<EObject, EObject> _mapping, Graph srcGraph, Graph tgtGraph,
		Map<EObject, EObject> tgMapping, boolean interfaceOnly) {
		srcGraph.edges.filter[e|!interfaceOnly || e.isInterfaceElement].forEach [ e |
			if (_mapping.containsKey(e.source) && _mapping.containsKey(e.target)) {
				val newEdge = createEdge(_mapping.get(e.source) as Node, _mapping.get(e.target) as Node,
					e.type.getMapped(tgMapping))
				_mapping.put(e, newEdge)

			}
		]
	}

	private static def <T extends EObject> T getMapped(T src, Map<EObject, EObject> tgMapping) {
		tgMapping.get(src) as T
	}

	private static def getKernelAliasFor(Rule r, Node n) {
		r.mappings.map [
			if (origin === n) {
				image
			} else if (image === n) {
				origin
			} else {
				null
			}
		].filterNull.head
	}
}
