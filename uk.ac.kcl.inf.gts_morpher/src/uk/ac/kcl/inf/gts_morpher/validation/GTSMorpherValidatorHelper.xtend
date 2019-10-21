package uk.ac.kcl.inf.gts_morpher.validation

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.function.Function
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.BehaviourMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationOrReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GtsMorpherPackage
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.LinkMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.ObjectMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.RuleMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.SlotMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.TypeGraphMapping
import uk.ac.kcl.inf.gts_morpher.util.ValueHolder

import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import org.eclipse.emf.ecore.EStructuralFeature

class GTSMorpherValidatorHelper {

	static interface IssueAcceptor {
		def void warning(String message, EObject source, EStructuralFeature feature, String code)
	}

	/**
	 * Check the given mapping. Expects the mapping to have been extracted already and passed in as the second parameter.
	 */
	static def isInCompleteMapping(TypeGraphMapping mapping, Map<EObject, EObject> extractedMapping) {
		val gtsMapping = mapping.eContainer as GTSMapping
		val srcIsInterface = gtsMapping.source.interface_mapping
		gtsMapping.source?.metamodel?.eAllContents?.filter [ me |
			(me instanceof EClassifier || me instanceof EReference) &&
				(!srcIsInterface || isInterfaceElement(me as EModelElement))
		]?.exists [ me |
			!extractedMapping.containsKey(me)
		]
	}

	static def doCheckIsCompleteBehaviourMapping(GTSMapping mapping, IssueAcceptor validator) {
		val result = new ValueHolder(true)

		if (mapping.target.behaviour !== null) {
			result.value = checkIsCompletelyCovered(mapping.target, mapping.behaviourMapping, [rm|rm.target],
				validator) && result.value
		}
		if (mapping.source.behaviour !== null) {
			result.value = checkIsCompletelyCovered(mapping.source, mapping.behaviourMapping, [rm|rm.source],
				validator) && result.value
		}

		if (mapping.behaviourMapping !== null) {
			mapping.behaviourMapping.mappings.forEach [ rm |
				result.value = rm.checkIsCompleteRuleMapping(validator) && result.value
			]
		}

		result.value
	}

	private static def boolean checkIsCompletelyCovered(GTSSpecificationOrReference gts,
		BehaviourMapping behaviourMapping, Function<RuleMapping, Rule> ruleGetter, IssueAcceptor validator) {
		val Iterable<Rule> rules = gts.behaviour.units.filter(Rule)
		if (rules.empty) {
			return true
		}

		var result = true

		if (behaviourMapping === null) {
			// Really should have some behaviour mappings if there are any rules at all...
			gts.incompleteBehaviourMappingWarning(validator,
				"Incomplete mapping. Ensure all rules in this behaviour are mapped.")
			result = false
		} else {
			val mappedRules = behaviourMapping.mappings.map[rm|ruleGetter.apply(rm)].toList
			if (rules.exists[r|!mappedRules.contains(r)]) {
				gts.incompleteBehaviourMappingWarning(validator,
					"Incomplete mapping. Ensure all rules in this behaviour are mapped.")
				result = false
			}
		}

		result
	}

	private static def dispatch incompleteBehaviourMappingWarning(GTSSpecificationOrReference gts,
		IssueAcceptor validator, String message) {}

	private static def dispatch incompleteBehaviourMappingWarning(GTSSpecification gts, IssueAcceptor validator,
		String message) {
		if (validator !== null) {
			validator.warning(message, gts, GtsMorpherPackage.Literals.GTS_SPECIFICATION__GTS,
				GTSMorpherValidator.INCOMPLETE_BEHAVIOUR_MAPPING)
		}
	}

	private static def dispatch incompleteBehaviourMappingWarning(GTSReference gts, IssueAcceptor validator,
		String message) {
		if (validator !== null) {
			validator.warning(message, gts, GtsMorpherPackage.Literals.GTS_REFERENCE__REF,
				GTSMorpherValidator.INCOMPLETE_BEHAVIOUR_MAPPING)
		}
	}

	/**
	 * Check that the given rule mapping is complete
	 */
	private static def checkIsCompleteRuleMapping(RuleMapping mapping, IssueAcceptor validator) {
		if (mapping.source !== null) {
			if (!mapping.target_virtual) { // Mappings to the virtual rules are implicitly complete by definition.
				val srcIsInterface = (mapping.eContainer.eContainer as GTSMapping).source.interface_mapping
				val elementIndex = new HashMap<String, List<GraphElement>>()
				mapping.source.lhs.addAllUnique(elementIndex, srcIsInterface)
				mapping.source.rhs.addAllUnique(elementIndex, srcIsInterface)

				val inComplete = elementIndex.entrySet.exists [ e |
					!mapping.element_mappings.exists [ em |
						((em instanceof ObjectMapping) && (e.value.contains((em as ObjectMapping).source))) ||
							((em instanceof LinkMapping) && (e.value.contains((em as LinkMapping).source))) ||
							((em instanceof SlotMapping) && (e.value.contains((em as SlotMapping).source)))
					]
				]

				if (inComplete) {
					if (validator !== null) {
						validator.warning("Incomplete mapping. Ensure all elements of the source rule are mapped.",
							mapping, GtsMorpherPackage.Literals.RULE_MAPPING__SOURCE,
							GTSMorpherValidator.INCOMPLETE_RULE_MAPPING)
					}

					return false
				}
			}
		}
		true
	}

	// FIXME: Also need to add slots, which will require a retyping of the index.
	private static def void addAllUnique(Graph graph, HashMap<String, List<GraphElement>> map, boolean srcIsInterface) {
		graph.eContents.filter [ ge |
			!srcIsInterface || (if (ge instanceof Node) {
				isInterfaceElement(ge.type)
			} else if (ge instanceof Edge) {
				isInterfaceElement(ge.type)
			} else {
				false
			})
		].forEach [ eo |
			val ge = eo as GraphElement
			var list = map.get(ge.name.toString)
			if (list === null) {
				list = new ArrayList<GraphElement>()
				map.put(ge.name.toString, list)
			}
			list.add(ge)
		]
	}
}
