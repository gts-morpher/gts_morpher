package uk.ac.kcl.inf.util

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
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.util.OnChangeEvictingCache
import uk.ac.kcl.inf.util.henshinsupport.HenshinQualifiedNameProvider
import uk.ac.kcl.inf.xDsmlCompose.AttributeMapping
import uk.ac.kcl.inf.xDsmlCompose.BehaviourMapping
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecification
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.RuleElementMapping
import uk.ac.kcl.inf.xDsmlCompose.RuleMapping
import uk.ac.kcl.inf.xDsmlCompose.SlotMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposeFactory
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static org.eclipse.xtext.scoping.Scopes.*

import static extension uk.ac.kcl.inf.util.EMFHelper.isInterfaceElement
import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.util.HenshinChecker.isIdentityRule
import static extension uk.ac.kcl.inf.util.henshinsupport.NamingHelper.*
import javax.sound.sampled.BooleanControl.Type

/**
 * Basic util methods for extracting mappings from GTSMappings and vice versa.
 */
class MappingConverter {
	public static val DUPLICATE_CLASS_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_CLASS_MAPPING'
	public static val DUPLICATE_REFERENCE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_REFERENCE_MAPPING'
	public static val DUPLICATE_ATTRIBUTE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_ATTRIBUTE_MAPPING'
	public static val DUPLICATE_RULE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_RULE_MAPPING'
	public static val DUPLICATE_OBJECT_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_OBJECT_MAPPING'
	public static val DUPLICATE_LINK_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_LINK_MAPPING'
	public static val DUPLICATE_SLOT_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_SLOT_MAPPING'
	public static val NON_INTERFACE_CLASS_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.xdsml_compose.NON_INTERFACE_CLASS_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.xdsml_compose.NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.xdsml_compose.NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_OBJECT_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.xdsml_compose.NON_INTERFACE_OBJECT_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_LINK_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.xdsml_compose.NON_INTERFACE_LINK_MAPPING_ATTEMPT'
	public static val NON_INTERFACE_SLOT_MAPPING_ATTEMPT = 'uk.ac.kcl.inf.xdsml_compose.NON_INTERFACE_SLOT_MAPPING_ATTEMPT'

	public static interface IssueAcceptor {
		def void error(String message, EObject source, EStructuralFeature feature, String code, String... issueData)
	}

	/**
	 * Extract the type mapping specified as a map object. Report duplicate entries as errors via the IssueAcceptor provided, if any.
	 */
	public static def Map<EObject, EObject> extractMapping(TypeGraphMapping mapping, IssueAcceptor issues) {
		val Map<EObject, EObject> _mapping = new HashMap

		val srcIsInterface = (mapping.eContainer as GTSMapping).source.interface_mapping
		val tgtIsInterface = (mapping.eContainer as GTSMapping).target.interface_mapping

		mapping.mappings.filter(ClassMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				issues.safeError('''Duplicate mapping for EClassifier «cm.source.name».''', cm,
					XDsmlComposePackage.Literals.CLASS_MAPPING__SOURCE, DUPLICATE_CLASS_MAPPING)
			} else {
				if ((srcIsInterface) && (!cm.source.isInterfaceElement)) {
					issues.safeError('''EClassifier «cm.source.name» must be annotated as interface to be mapped.''',
						cm, XDsmlComposePackage.Literals.CLASS_MAPPING__SOURCE, NON_INTERFACE_CLASS_MAPPING_ATTEMPT)
				} else if ((tgtIsInterface) && (!cm.target.isInterfaceElement)) {
					issues.safeError('''EClassifier «cm.target.name» must be annotated as interface to be mapped.''',
						cm, XDsmlComposePackage.Literals.CLASS_MAPPING__TARGET, NON_INTERFACE_CLASS_MAPPING_ATTEMPT)
				} else {
					_mapping.put(cm.source, cm.target)
				}
			}
		]

		mapping.mappings.filter(ReferenceMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				issues.safeError('''Duplicate mapping for EReference «cm.source.name».''', cm,
					XDsmlComposePackage.Literals.REFERENCE_MAPPING__SOURCE, DUPLICATE_REFERENCE_MAPPING)
			} else {
				if ((srcIsInterface) && (!cm.source.isInterfaceElement)) {
					issues.safeError('''EReference «cm.source.name» must be annotated as interface to be mapped.''', cm,
						XDsmlComposePackage.Literals.REFERENCE_MAPPING__SOURCE, NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT)
				} else if ((tgtIsInterface) && (!cm.target.isInterfaceElement)) {
					issues.safeError('''EReference «cm.target.name» must be annotated as interface to be mapped.''', cm,
						XDsmlComposePackage.Literals.REFERENCE_MAPPING__TARGET, NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT)
				} else {
					_mapping.put(cm.source, cm.target)
				}
			}
		]

		mapping.mappings.filter(AttributeMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				issues.safeError('''Duplicate mapping for EAttribute «cm.source.name».''', cm,
					XDsmlComposePackage.Literals.ATTRIBUTE_MAPPING__SOURCE, DUPLICATE_ATTRIBUTE_MAPPING)
			} else {
				if ((srcIsInterface) && (!cm.source.isInterfaceElement)) {
					issues.safeError('''EAttribute «cm.source.name» must be annotated as interface to be mapped.''', cm,
						XDsmlComposePackage.Literals.ATTRIBUTE_MAPPING__SOURCE, NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT)
				} else if ((tgtIsInterface) && (!cm.target.isInterfaceElement)) {
					issues.safeError('''EAttribute «cm.target.name» must be annotated as interface to be mapped.''', cm,
						XDsmlComposePackage.Literals.ATTRIBUTE_MAPPING__TARGET, NON_INTERFACE_ATTRIBUTE_MAPPING_ATTEMPT)
				} else {
					_mapping.put(cm.source, cm.target)
				}
			}
		]

		_mapping
	}

	/**
	 * Extract the rule mapping specified as a map object. Report duplicate entries as errors via the IssueAcceptor provided, if any.
	 */
	public static def Map<EObject, EObject> extractMapping(BehaviourMapping mapping, IssueAcceptor issues) {
		val _mapping = new HashMap<EObject, EObject>

		if (mapping === null) {
			return _mapping
		}

		val srcIsInterface = (mapping.eContainer as GTSMapping).source.interface_mapping
		val tgtIsInterface = (mapping.eContainer as GTSMapping).target.interface_mapping

		mapping.mappings.forEach [ rm |
			if (_mapping.containsKey(rm.target)) {
				issues.safeError("Duplicate mapping for Rule " + rm.target.name + ".", rm,
					XDsmlComposePackage.Literals.RULE_MAPPING__REAL_TARGET, DUPLICATE_RULE_MAPPING)
			} else {
				_mapping.put(rm.target, rm.source)

				if (rm.target_identity) {
					rm.extractTgtIdentityMapping(_mapping, srcIsInterface, tgtIsInterface, issues)
				} else {
					rm.extractMapping(_mapping, srcIsInterface, tgtIsInterface, issues)
				}
			}
		]

		_mapping
	}

	private static def extractTgtIdentityMapping(RuleMapping rm, HashMap<EObject, EObject> _mapping, boolean srcIsInterface,
		boolean tgtIsInterface, IssueAcceptor issues) {
		if (!rm.target_identity) {
			throw new IllegalStateException
		}
		
		rm.source.lhs.nodes.filter[n | !srcIsInterface || n.type.isInterfaceElement].forEach[n | 
			// TODO: Find matching target node and store the mapping
			// TODO: For all slots in n (and it's corresponding RHS node) find matching target slot and store mapping
		]
		rm.source.lhs.edges.filter[e  | !srcIsInterface || e.type.isInterfaceElement].forEach[e | 
			// TODO: Find matching target edge and store the mapping
		]
	}
	
	private static def extractMapping(RuleMapping rm, HashMap<EObject, EObject> _mapping, boolean srcIsInterface,
		boolean tgtIsInterface, IssueAcceptor issues) {
		rm.element_mappings.filter(ObjectMapping).forEach [ em |
			if (_mapping.containsKey(em.source)) {
				issues.safeError("Duplicate mapping for Object " + em.source.name + ".", em,
					XDsmlComposePackage.Literals.OBJECT_MAPPING__SOURCE, DUPLICATE_OBJECT_MAPPING)
			} else if (srcIsInterface && !em.source.type.isInterfaceElement) {
				issues.safeError('''Object «em.source.name» must be an interface element to be mapped.''', em,
					XDsmlComposePackage.Literals.OBJECT_MAPPING__SOURCE, NON_INTERFACE_OBJECT_MAPPING_ATTEMPT)
			} else if (tgtIsInterface && !em.target.type.isInterfaceElement) {
				issues.safeError('''Object «em.target.name» must be an interface element to be mapped.''', em,
					XDsmlComposePackage.Literals.OBJECT_MAPPING__TARGET, NON_INTERFACE_OBJECT_MAPPING_ATTEMPT)
			} else {
				_mapping.put(em.source, em.target)
				val srcPattern = em.source.eContainer as Graph
				val srcRule = srcPattern.eContainer as Rule
				val tgtRule = em.target.eContainer.eContainer as Rule
				if (srcPattern == srcRule.lhs) {
					// Also add corresponding RHS object, if any
					_mapping.putIfNotNull(
						srcRule.rhs.nodes.findFirst[o|o.name.equals(em.source.name)],
						tgtRule.rhs.nodes.findFirst[o|o.name.equals(em.target.name)]
					)
				} else if (srcPattern == srcRule.rhs) {
					// Also add corresponding LHS object, if any							
					_mapping.putIfNotNull(
						srcRule.lhs.nodes.findFirst[o|o.name.equals(em.source.name)],
						tgtRule.lhs.nodes.findFirst[o|o.name.equals(em.target.name)]
					)
				}
			}
		]
		rm.element_mappings.filter(LinkMapping).forEach [ em |
			if (_mapping.containsKey(em.source)) {
				issues.safeError("Duplicate mapping for Link " + em.source.name + ".", em,
					XDsmlComposePackage.Literals.LINK_MAPPING__SOURCE, DUPLICATE_LINK_MAPPING)
			} else if (srcIsInterface && !em.source.type.isInterfaceElement) {
				issues.safeError('''Link «em.source.name» must be an interface element to be mapped.''', em,
					XDsmlComposePackage.Literals.LINK_MAPPING__SOURCE, NON_INTERFACE_LINK_MAPPING_ATTEMPT)
			} else if (tgtIsInterface && !em.target.type.isInterfaceElement) {
				issues.safeError('''Link «em.target.name» must be an interface element to be mapped.''', em,
					XDsmlComposePackage.Literals.LINK_MAPPING__TARGET, NON_INTERFACE_LINK_MAPPING_ATTEMPT)
			} else {
				_mapping.put(em.source, em.target)
				val srcPattern = em.source.eContainer as Graph
				val srcRule = srcPattern.eContainer as Rule
				val tgtRule = em.target.eContainer.eContainer as Rule
				if (srcPattern == srcRule.lhs) {
					// Also add corresponding RHS link, if any
					_mapping.putIfNotNull(
						srcRule.rhs.edges.findFirst[o|o.name.equals(em.source.name)],
						tgtRule.rhs.edges.findFirst[o|o.name.equals(em.target.name)]
					)
				} else if (srcPattern == srcRule.rhs) {
					// Also add corresponding LHS link, if any							
					_mapping.putIfNotNull(
						srcRule.lhs.edges.findFirst[o|o.name.equals(em.source.name)],
						tgtRule.lhs.edges.findFirst[o|o.name.equals(em.target.name)]
					)
				}
			}
		]
		rm.element_mappings.filter(SlotMapping).forEach [ em |
			if (_mapping.containsKey(em.source)) {
				issues.safeError("Duplicate mapping for Slot " + em.source.name + ".", em,
					XDsmlComposePackage.Literals.SLOT_MAPPING__SOURCE, DUPLICATE_SLOT_MAPPING)
			} else if (srcIsInterface && !em.source.type.isInterfaceElement) {
				issues.safeError('''Slot «em.source.name» must be an interface element to be mapped.''', em,
					XDsmlComposePackage.Literals.SLOT_MAPPING__SOURCE, NON_INTERFACE_SLOT_MAPPING_ATTEMPT)
			} else if (tgtIsInterface && !em.target.type.isInterfaceElement) {
				issues.safeError('''Slot «em.target.name» must be an interface element to be mapped.''', em,
					XDsmlComposePackage.Literals.SLOT_MAPPING__TARGET, NON_INTERFACE_SLOT_MAPPING_ATTEMPT)
			} else {
				_mapping.put(em.source, em.target)

				val srcNode = em.source.eContainer as Node
				val tgtNode = em.target.eContainer as Node

				val srcPattern = srcNode.eContainer as Graph
				val srcRule = srcPattern.eContainer as Rule

				val tgtRule = tgtNode.eContainer.eContainer as Rule

				if (srcPattern == srcRule.lhs) {
					// Also add corresponding RHS attribute, if any
					_mapping.putIfNotNull(
						srcRule.rhs.nodes.findFirst[o|o.name.equals(srcNode.name)].attributes.findFirst [ a |
							a.type === em.source.type
						],
						tgtRule.rhs.nodes.findFirst[o|o.name.equals(tgtNode.name)].attributes.findFirst [ a |
							a.type === em.target.type
						]
					)
				} else if (srcPattern == srcRule.rhs) {
					// Also add corresponding LHS attribute, if any							
					_mapping.putIfNotNull(
						srcRule.lhs.nodes.findFirst[o|o.name.equals(srcNode.name)].attributes.findFirst [ a |
							a.type === em.source.type
						],
						tgtRule.lhs.nodes.findFirst[o|o.name.equals(tgtNode.name)].attributes.findFirst [ a |
							a.type === em.target.type
						]
					)
				}
			}
		]
	}

	private static val ruleMappingTargetCache = new OnChangeEvictingCache

	public static def getTarget(RuleMapping rm) {
		if (!rm.target_identity) {
			rm.realTarget
		} else {
			ruleMappingTargetCache.get(rm, rm.eResource, [
				rm.deriveIdentityTargetRule
			])
		}
	}

	public static def setTarget(RuleMapping rm, Rule r) {
		rm.realTarget = r
		rm.target_identity = false
		println("Called to set the target of a rule mapping... Need to enhance this to support to identity mappings.")
	}

	/**
	 * Extract a GTSMapping from the given map, using the given from and to as source and target respectively (which 
	 * should be taken from the original GTSMapping). Place the new mapping in the given resource.
	 */
	// TODO Write tests for this to see why the resulting GTSMapping is still internally inconsistent.
	static def GTSMapping extractGTSMapping(Map<? extends EObject, ? extends EObject> mapping, GTSSpecification from,
		GTSSpecification to, Resource res) {
		if (res === null) {
			throw new IllegalArgumentException("res must not be null")
		}

		val result = XDsmlComposeFactory.eINSTANCE.createGTSMapping
		res.contents.add(result)

		result.source = from.resourceLocalCopy
		result.target = to.resourceLocalCopy

		result.typeMapping = XDsmlComposeFactory.eINSTANCE.createTypeGraphMapping
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
			result.behaviourMapping = XDsmlComposeFactory.eINSTANCE.createBehaviourMapping
			result.behaviourMapping.mappings.addAll(behaviourMappings.filter[e|e.key instanceof Rule].map [ e |
				(e.key as Rule).extractRuleMapping(e.value as Rule, behaviourMappings, result)
			])
		}

		result
	}

	private static dispatch def TypeMapping extractTypeMapping(EObject src, EObject tgt, GTSMapping mapping) { null }

	private static dispatch def TypeMapping extractTypeMapping(EClass srcClass, EClass tgtClass, GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createClassMapping
		result.source = srcClass.correspondingSourceElement(mapping)
		result.target = tgtClass.correspondingTargetElement(mapping)

		result
	}

	private static dispatch def TypeMapping extractTypeMapping(EReference srcReference, EReference tgtReference,
		GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createReferenceMapping
		result.source = srcReference.correspondingSourceElement(mapping)
		result.target = tgtReference.correspondingTargetElement(mapping)

		result
	}

	private static dispatch def TypeMapping extractTypeMapping(EAttribute srcAttribute, EAttribute tgtAttribute,
		GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createAttributeMapping
		result.source = srcAttribute.correspondingSourceElement(mapping)
		result.target = tgtAttribute.correspondingTargetElement(mapping)

		result
	}

	private static def RuleMapping extractRuleMapping(Rule tgtRule, Rule srcRule,
		Iterable<? extends Entry<? extends EObject, ? extends EObject>> behaviourMappings, GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createRuleMapping

		result.source = srcRule.correspondingSourceElement(mapping)
		// FIXME: Need to handle this differently depending on whether the original mapping was to identity or not
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
						(n.name == e.key.eContainer.name) && n.attributes.exists[a|a.type === (e.key as Attribute).type]
					])
				} else {
					true
				}
			} else {
				false
			}
		].map [ e |
			e.key.extractRuleElementMapping(e.value, mapping)
		])

		result
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(EObject src, EObject tgt,
		GTSMapping mapping) {
		null
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Node srcNode, Node tgtNode,
		GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createObjectMapping
		result.source = srcNode.correspondingSourceElement(mapping)
		result.target = tgtNode.correspondingTargetElement(mapping)

		result
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Edge srcEdge, Edge tgtEdge,
		GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createLinkMapping
		result.source = srcEdge.correspondingSourceElement(mapping)
		result.target = tgtEdge.correspondingTargetElement(mapping)

		result
	}

	private static dispatch def RuleElementMapping extractRuleElementMapping(Attribute srcAttribute,
		Attribute tgtAttribute, GTSMapping mapping) {
		val result = XDsmlComposeFactory.eINSTANCE.createSlotMapping
		result.source = srcAttribute.correspondingSourceElement(mapping)
		result.target = tgtAttribute.correspondingTargetElement(mapping)

		result
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

	private static val IQualifiedNameProvider nameProvider = new DefaultDeclarativeQualifiedNameProvider
	private static val IQualifiedNameProvider henshinNameProvider = new HenshinQualifiedNameProvider

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

	private static extension val HenshinFactory FACTORY = HenshinFactory.eINSTANCE

	/**
	 * Generate a virtual rule to map to for this rule mapping
	 */
	private static def Rule deriveIdentityTargetRule(RuleMapping rm) {
		val gtsMapping = rm.eContainer.eContainer as GTSMapping
		val isInterfaceMapping = gtsMapping.source.interface_mapping
		if (rm.source.isIdentityRule(isInterfaceMapping)) {
			// Generate a suitable identity rule
			// Note this works here only using the information that's explictly available in the type mapping. 
			// Need to consider what to do with auto-completion cases.
			// TODO May need to cache this against the target metamodel resource, if any
			val virtualRule = createRule(rm.source.name)
			val lhs = createGraph("Lhs")
			val rhs = createGraph("Rhs")

			virtualRule.lhs = lhs
			virtualRule.rhs = rhs

			// Make sure rule is properly contained in some containment hierarchy
			val targetGTS = gtsMapping.target
			if (targetGTS === null) {
				return null
			}

			val targetBehaviour = targetGTS.behaviour
			var Resource targetBehaviourResource
			if (targetBehaviour === null) {
				targetBehaviourResource = targetGTS.metamodel.eResource
				var module = (targetBehaviourResource.allContents.findFirst[eo|eo instanceof Module] as Module)

				if (module === null) {
					module = createModule
					targetBehaviourResource.contents.add(module)
				}

				module.units.add(virtualRule)
			} else {
				targetBehaviourResource = targetBehaviour.eResource;
				(targetBehaviourResource.allContents.head as Module).units.add(virtualRule)
			}

			// Generate all the nodes
			val nodesMap = new HashMap<Node, Pair<Node, Node>>
			rm.source.lhs.nodes.filter[n|!isInterfaceMapping || n.isInterfaceElement].forEach [ n |
				val lhsNode = createNode(lhs, n.type.getMapped(gtsMapping), n.name)
				val rhsNode = createNode(lhs, n.type.getMapped(gtsMapping), n.name)

				lhs.nodes.add(lhsNode)
				rhs.nodes.add(rhsNode)

				nodesMap.put(n, new Pair(lhsNode, rhsNode))

				virtualRule.mappings.add(createMapping(lhsNode, rhsNode))
			]

			// Generate all edges
			rm.source.lhs.edges.filter[e|!isInterfaceMapping || e.isInterfaceElement].forEach [ e |
				val srcNodes = nodesMap.get(e.source)
				val tgtNodes = nodesMap.get(e.target)

				val lhsEdge = createEdge(srcNodes.key, tgtNodes.value, e.type.getMapped(gtsMapping))
				val rhsEdge = createEdge(srcNodes.key, tgtNodes.value, e.type.getMapped(gtsMapping))

				lhs.edges.add(lhsEdge)
				rhs.edges.add(rhsEdge)
			]

			virtualRule
		} else {
			null
		}
	}

	private static def getMapped(EClass srcClass, GTSMapping gtsMapping) {
		val mapping = gtsMapping.typeMapping.mappings.filter(ClassMapping).findFirst[mp|mp.source === srcClass]

		if (mapping !== null) {
			mapping.target as EClass
		} else {
			null
		}
	}

	private static def getMapped(EReference srcRef, GTSMapping gtsMapping) {
		val mapping = gtsMapping.typeMapping.mappings.filter(ReferenceMapping).findFirst[mp|mp.source === srcRef]

		if (mapping !== null) {
			mapping.target
		} else {
			null
		}
	}
}
