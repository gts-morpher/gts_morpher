/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.validation

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set
import java.util.function.Function
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.CheckType
import uk.ac.kcl.inf.util.BasicMappingChecker
import uk.ac.kcl.inf.util.BasicMappingChecker.IssueAcceptor
import uk.ac.kcl.inf.util.MorphismCompleter
import uk.ac.kcl.inf.util.ValueHolder
import uk.ac.kcl.inf.xDsmlCompose.BehaviourMapping
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecification
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.RuleMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static uk.ac.kcl.inf.util.BasicMappingChecker.*
import static uk.ac.kcl.inf.util.MorphismChecker.*

import static extension uk.ac.kcl.inf.util.EMFHelper.*

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class XDsmlComposeValidator extends AbstractXDsmlComposeValidator {
	public static val DUPLICATE_CLASS_MAPPING = BasicMappingChecker.DUPLICATE_CLASS_MAPPING
	public static val DUPLICATE_REFERENCE_MAPPING = BasicMappingChecker.DUPLICATE_REFERENCE_MAPPING
	public static val NOT_A_CLAN_MORPHISM = 'uk.ac.kcl.inf.xdsml_compose.NOT_A_CLAN_MORPHISM'
	public static val INCOMPLETE_TYPE_GRAPH_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.INCOMPLETE_TYPE_GRAPH_MAPPING'
	public static val UNCOMPLETABLE_TYPE_GRAPH_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.UNCOMPLETABLE_TYPE_GRAPH_MAPPING'
	public static val UNCOMPLETABLE_BEHAVIOUR_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.UNCOMPLETABLE_BEHAVIOUR_MAPPING'
	public static val NO_UNIQUE_COMPLETION = 'uk.ac.kcl.inf.xdsml_compose.NO_UNIQUE_COMPLETION'
	public static val UNIQUE_COMPLETION_NOT_CHECKED = 'uk.ac.kcl.inf.xdsml_compose.UNIQUE_COMPLETION_NOT_CHECKED'
	public static val DUPLICATE_RULE_MAPPING = BasicMappingChecker.DUPLICATE_RULE_MAPPING
	public static val DUPLICATE_OBJECT_MAPPING = BasicMappingChecker.DUPLICATE_OBJECT_MAPPING
	public static val DUPLICATE_LINK_MAPPING = BasicMappingChecker.DUPLICATE_LINK_MAPPING
	public static val INVALID_BEHAVIOUR_SPEC = 'uk.ac.kcl.inf.xdsml_compose.INVALID_BEHAVIOUR_SPEC'
	public static val NOT_A_RULE_MORPHISM = 'uk.ac.kcl.inf.xdsml_compose.NOT_A_RULE_MORPHISM'
	public static val INCOMPLETE_RULE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.INCOMPLETE_RULE_MAPPING'
	public static val INCOMPLETE_BEHAVIOUR_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.INCOMPLETE_BEHAVIOUR_MAPPING'

	/**
	 * Check that the rules in a GTS specification refer to the metamodel package
	 */
	@Check
	def checkGTSSpecConsistent(GTSSpecification gts) {
		if (gts.behaviour !== null) {
			if (!gts.behaviour.imports.contains(gts.metamodel)) {
				error("Inconsistent GTS specification: Rules need to be typed over metamodel.",
					XDsmlComposePackage.Literals.GTS_SPECIFICATION__BEHAVIOUR, INVALID_BEHAVIOUR_SPEC)
			}
		}
	}

	/**
	 * Check that no source EClass or EReference is mapped more than once in the given mapping.
	 */
	@Check
	def checkMapsUniqueSources(TypeGraphMapping mapping) {
		mapping.extractMapping
	}

	/**
	 * Check that no rule is mapped more than once in the given mapping.
	 */
	@Check
	def checkMapsUniqueRules(BehaviourMapping mapping) {
		mapping.extractMapping
	}

	/**
	 * Check that the given mappings do not violate the rules for clan morphisms
	 */
	@Check
	def checkIsMorphismMaybeIncomplete(GTSMapping mapping) {
		var typeMapping = extractMapping(mapping.typeMapping)
		val isValidTypeMorphism = checkValidMaybeIncompleteClanMorphism(typeMapping, [ object, message |
			if (object instanceof EClassifier) {
				error(message, mapping.typeMapping.mappings.filter(ClassMapping).findFirst[m|m.source == object],
					XDsmlComposePackage.Literals.CLASS_MAPPING__TARGET, NOT_A_CLAN_MORPHISM)
			} else if (object instanceof EReference) {
				error(message, mapping.typeMapping.mappings.filter(ReferenceMapping).findFirst [ m |
					m.source == object
				], XDsmlComposePackage.Literals.REFERENCE_MAPPING__TARGET, NOT_A_CLAN_MORPHISM)
			}
		])

		if (isValidTypeMorphism) {
			checkValidMaybeIncompleteBehaviourMorphism(typeMapping,
				extractMapping(mapping.behaviourMapping), [ object, message |
					if (object instanceof Rule) {
						error(message, mapping.behaviourMapping.mappings.findFirst [ rm |
							rm.source == object as Rule
						], XDsmlComposePackage.Literals.RULE_MAPPING__TARGET, NOT_A_RULE_MORPHISM)
					} else if (object instanceof Edge) {
						error(message, mapping.behaviourMapping.mappings.
							map[rm|rm.element_mappings.filter(LinkMapping)].flatten.findFirst [ lm |
								lm.source == object as Edge
							], XDsmlComposePackage.Literals.LINK_MAPPING__SOURCE, NOT_A_RULE_MORPHISM)
					} else if (object instanceof Object) {
						error(message, mapping.behaviourMapping.mappings.map [ rm |
							rm.element_mappings.filter(ObjectMapping)
						].flatten.findFirst [ om |
							om.source == object as Object
						], XDsmlComposePackage.Literals.OBJECT_MAPPING__SOURCE, NOT_A_RULE_MORPHISM)
					}
				])
		}
	}

	/**
	 * Check that the given mapping is a complete type mapping
	 */
	@Check
	def checkIsCompleteTypeMapping(GTSMapping mapping) {
		if (!mapping.autoComplete && mapping.typeMapping.isInCompleteMapping) {
			warning("Incomplete mapping. Ensure all elements of the source metamodel are mapped.", mapping,
				XDsmlComposePackage.Literals.GTS_MAPPING__SOURCE, INCOMPLETE_TYPE_GRAPH_MAPPING)
		}
	}

	/**
	 * Check that the given behaviour mapping maps all rules and maps them completely
	 */
	@Check
	def checkIsCompleteBehaviourMapping(GTSMapping mapping) {
		if (!mapping.autoComplete) {
			doCheckIsCompleteBehaviourMapping(mapping, this)
		}
	}

	private def doCheckIsCompleteBehaviourMapping(GTSMapping mapping, XDsmlComposeValidator validator) {
		val result = new ValueHolder(true)
		
		if (mapping.target.behaviour !== null) {
			result.value = checkIsCompletelyCovered(mapping.target, mapping.behaviourMapping, [rm|rm.target], validator) && result.value
		}
		if (mapping.source.behaviour !== null) {
			result.value = checkIsCompletelyCovered(mapping.source, mapping.behaviourMapping, [rm|rm.source], validator) && result.value
		}
		
		mapping.behaviourMapping.mappings.forEach[rm | result.value = rm.checkIsCompleteRuleMapping (validator) && result.value] 
		
		result.value
	}
	
	private def boolean checkIsCompletelyCovered(GTSSpecification gts, BehaviourMapping behaviourMapping,
		Function<RuleMapping, Rule> ruleGetter, XDsmlComposeValidator validator) {
		val Iterable<Rule> rules = gts.behaviour.units.filter(Rule)
		if (rules.empty) {
			return true
		}
		
		var result = true
		
		if (behaviourMapping === null) {
			// Really should have some behaviour mappings if there are any rules at all...
			if (validator !== null) {
				validator.warning("Incomplete mapping. Ensure all rules in this behaviour are mapped.", gts,
					XDsmlComposePackage.Literals.GTS_SPECIFICATION__BEHAVIOUR, INCOMPLETE_BEHAVIOUR_MAPPING)
			}
			result = false
		}
		
		val mappedRules = behaviourMapping.mappings.map[rm | ruleGetter.apply(rm)].toList
		if (rules.exists[r | !mappedRules.contains(r)]) {
			if (validator !== null) {
				validator.warning("Incomplete mapping. Ensure all rules in this behaviour are mapped.", gts,
						XDsmlComposePackage.Literals.GTS_SPECIFICATION__BEHAVIOUR, INCOMPLETE_BEHAVIOUR_MAPPING)				
			}
			result = false
		}
		
		result
	}

	/**
	 * Check that the given rule mapping is complete
	 */
	def checkIsCompleteRuleMapping(RuleMapping mapping, XDsmlComposeValidator validator) {
		if (!(mapping.eContainer.eContainer as GTSMapping).autoComplete) {
			val elementIndex = new HashMap<String, List<GraphElement>>()
			mapping.source.lhs.addAllUnique(elementIndex)
			mapping.source.rhs.addAllUnique(elementIndex)
			
			val inComplete = elementIndex.entrySet.exists[e | 
				!mapping.element_mappings.exists[em |
					((em instanceof ObjectMapping) && (e.value.contains((em as ObjectMapping).source))) ||
					((em instanceof LinkMapping) && (e.value.contains((em as LinkMapping).source)))
				]
			]
			
			if (inComplete) {
				if (validator !== null) {
					validator.warning("Incomplete mapping. Ensure all elements of the source rule are mapped.", mapping,
						XDsmlComposePackage.Literals.RULE_MAPPING__SOURCE, INCOMPLETE_RULE_MAPPING)
				}
					
				return false
			}
		}
		
		true
	}
	
	private def void addAllUnique(Graph graph, HashMap<String, List<GraphElement>> map) {
		graph.eContents.forEach[eo | 
			val ge = eo as GraphElement
			var list = map.get(ge.name.toString)
			if (list === null) {
				list = new ArrayList<GraphElement>()
				map.put(ge.name.toString, list)
			}
			list.add(ge)
		]
	}

	/**
	 * Check that we can auto-complete, if requested to do so
	 */
	@Check
	def checkCanAutoCompleteMapping(GTSMapping mapping) {
		if (mapping.autoComplete) {
			// Check we can auto-complete type mapping
			val typeMapping = mapping.typeMapping
			val behaviourMapping = mapping.behaviourMapping
			val _typeMapping = typeMapping.extractMapping
			val _behaviourMapping = behaviourMapping.extractMapping
			if (typeMapping.isInCompleteMapping || !mapping.doCheckIsCompleteBehaviourMapping(null)) {
				if (checkValidMaybeIncompleteClanMorphism(_typeMapping, null)) {
					val morphismCompleter = new MorphismCompleter(_typeMapping, mapping.source.metamodel,
						mapping.target.metamodel,_behaviourMapping, mapping.source.behaviour, mapping.target.behaviour)
					if (morphismCompleter.tryCompleteMorphism != 0) {
						if (!morphismCompleter.completedTypeMapping) {
							error("Cannot complete type mapping to a valid morphism", mapping,
								XDsmlComposePackage.Literals.GTS_MAPPING__TYPE_MAPPING, UNCOMPLETABLE_TYPE_GRAPH_MAPPING)							
						} else {
							error("Cannot complete behaviour mapping to a valid morphism", mapping,
								XDsmlComposePackage.Literals.GTS_MAPPING__BEHAVIOUR_MAPPING, UNCOMPLETABLE_BEHAVIOUR_MAPPING)
						}
					} else if (mapping.uniqueCompletion) {
						// TODO It would be good to remove this warning again when we're running the expensive check. The Eclipse API isn't available from here, for good reason. Not sure how to do this with Xtext means
						if (!checkMode.shouldCheck(CheckType.EXPENSIVE)) {
							warning(
								"Uniqueness of mapping has not been checked. Please run explicit validation from editor context menu to check this.",
								mapping, XDsmlComposePackage.Literals.GTS_MAPPING__UNIQUE_COMPLETION,
								UNIQUE_COMPLETION_NOT_CHECKED)
							}
						}
					}
				} else {
					warning("Type morphism is already complete", mapping,
						XDsmlComposePackage.Literals.GTS_MAPPING__AUTO_COMPLETE)
				}
			}
		}

		/**
		 * Check that we can uniquely auto-complete, if requested to do so
		 */
		@Check(EXPENSIVE)
		def checkCanUniqleyAutoCompleteMapping(GTSMapping mapping) {
			if (mapping.autoComplete && mapping.uniqueCompletion) {
				// Check we can auto-complete type mapping
				val typeMapping = mapping.typeMapping
				val behaviourMapping = mapping.behaviourMapping
				val _typeMapping = typeMapping.extractMapping
				val _behaviourMapping = behaviourMapping.extractMapping
				if ((typeMapping.isInCompleteMapping || !mapping.doCheckIsCompleteBehaviourMapping(null)) && checkValidMaybeIncompleteClanMorphism(_typeMapping, null)) {
					val morphismCompleter = new MorphismCompleter(_typeMapping, mapping.source.metamodel,
						mapping.target.metamodel, _behaviourMapping, mapping.source.behaviour, mapping.target.behaviour)

					if ((morphismCompleter.findMorphismCompletions(true) == 0) &&
						(morphismCompleter.completedMappings.size > 1)) {
						// Found more than one mapping (this can only happen if we were looking for all mappings), so need to report this as an error
						val sortedImprovements = morphismCompleter.findImprovementOptions

						// TODO Propose fixes for behaviour mapping completions, too
						error('''Found «morphismCompleter.completedMappings.size» potential completions. Consider mapping «sortedImprovements.head.mapMessage» to improve uniqueness.''',
							mapping, XDsmlComposePackage.Literals.GTS_MAPPING__UNIQUE_COMPLETION, NO_UNIQUE_COMPLETION,
							sortedImprovements.map [ e |
								e.value.map[eo|e.key.issueData(eo).toString]
							].flatten)
					}
				}
			}
		}

		private def findImprovementOptions(MorphismCompleter morphismCompleter) {
			// Sort all newly mapped elements by number of potential mappings, descending
			// and remove those elements with only one mapping
			morphismCompleter.completedMappings.fold(new HashMap<EObject, Set<EObject>>, [ _acc, mp |
				mp.entrySet.fold(_acc, [ acc, e |
					if (!acc.containsKey(e.key)) {
						acc.put(e.key, new HashSet<EObject>)
					}
					acc.get(e.key).add(e.value)

					acc
				])
			]).entrySet.filter[e|e.value.size > 1].sortWith[e1, e2|-(e1.value.size <=> e2.value.size)]
		}

		private def mapMessage(
			Entry<EObject, Set<EObject>> mappingChoices) '''«if (mappingChoices.key instanceof EClass) {'''class'''} else {'''reference'''}» «mappingChoices.key.qualifiedName» to any of [«mappingChoices.value.map[eo | eo.qualifiedName].join(', ')»]'''

		private def issueData(EObject source,
			EObject target) '''«if (source instanceof EClass) {'''class'''} else {'''reference'''}»:«source.qualifiedName»=>«target.qualifiedName»'''

		private static val TYPE_MAPPINGS = XDsmlComposeValidator.canonicalName + ".typeMappings"
		private static val RULE_MAPPINGS = XDsmlComposeValidator.canonicalName + ".ruleMappings"

		/**
		 * Extract the type mapping information as a Map. Also ensure no element is mapped more than once; report errors 
		 * otherwise. Expects to be called in a validation context.
		 */
		private def extractMapping(TypeGraphMapping mapping) {
			if (context.containsKey(TYPE_MAPPINGS)) {
				return context.get(TYPE_MAPPINGS) as Map<EObject, EObject>
			}

			val Map<EObject, EObject> _mapping = extractMapping(mapping, new IssueAcceptor() {
				override error(String message, EObject source, EStructuralFeature feature, String code,
					String... issueData) {
					XDsmlComposeValidator.this.error(message, source, feature, code, issueData)
				}
			})

			context.put(TYPE_MAPPINGS, _mapping)

			_mapping
		}

		/**
		 * Extract the type mapping information as a Map. Also ensure no element is mapped more than once; report errors 
		 * otherwise. Expects to be called in a validation context.
		 */
		private def extractMapping(BehaviourMapping mapping) {
			if (context.containsKey(RULE_MAPPINGS)) {
				return context.get(RULE_MAPPINGS) as Map<EObject, EObject>
			}

			val Map<EObject, EObject> _mapping = extractMapping(mapping, new IssueAcceptor() {
				override error(String message, EObject source, EStructuralFeature feature, String code,
					String... issueData) {
					XDsmlComposeValidator.this.error(message, source, feature, code, issueData)
				}
			})

			context.put(RULE_MAPPINGS, _mapping)

			_mapping
		}

		/**
		 * Return true if the given mapping is incomplete
		 */
		private def isInCompleteMapping(TypeGraphMapping mapping) {
			val _mapping = mapping.extractMapping;
			(mapping.eContainer as GTSMapping).source.metamodel.eAllContents.filter [ me |
				me instanceof EClassifier || me instanceof EReference
			].exists [ me |
				!_mapping.containsKey(me)
			]
		}
	}
	