package uk.ac.kcl.inf.util

import java.util.HashMap
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import uk.ac.kcl.inf.xDsmlCompose.BehaviourMapping
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

/**
 * Basic util methods for handling mappings
 */
class BasicMappingChecker {
	public static val DUPLICATE_CLASS_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_CLASS_MAPPING'
	public static val DUPLICATE_REFERENCE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_REFERENCE_MAPPING'
	public static val DUPLICATE_RULE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_RULE_MAPPING'
	public static val DUPLICATE_OBJECT_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_OBJECT_MAPPING'
	public static val DUPLICATE_LINK_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_LINK_MAPPING'

	public static interface IssueAcceptor {
		def void error(String message, EObject source, EStructuralFeature feature, String code, String... issueData)
	}

	/**
	 * Extract the type mapping specified as a map object. Report duplicate entries as errors via the IssueAcceptor provided, if any.
	 */
	public static def Map<EObject, EObject> extractMapping(TypeGraphMapping mapping, IssueAcceptor issues) {
		val Map<EObject, EObject> _mapping = new HashMap

		mapping.mappings.filter(ClassMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				if (issues !== null) {
					issues.error('''Duplicate mapping for EClassifier �cm.source.name�.''', cm,
						XDsmlComposePackage.Literals.CLASS_MAPPING__SOURCE, DUPLICATE_CLASS_MAPPING)
				}
			} else {
				_mapping.put(cm.source, cm.target)
			}
		]

		mapping.mappings.filter(ReferenceMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				if (issues !== null) {
					issues.error('''Duplicate mapping for EReference �cm.source.name�.''', cm,
						XDsmlComposePackage.Literals.REFERENCE_MAPPING__SOURCE, DUPLICATE_REFERENCE_MAPPING)
				}
			} else {
				_mapping.put(cm.source, cm.target)
			}
		]

		_mapping
	}

	/**
	 * Extract the rule mapping specified as a map object. Report duplicate entries as errors via the IssueAcceptor provided, if any.
	 */
	public static def Map<EObject, EObject> extractMapping(BehaviourMapping mapping, IssueAcceptor issues) {
		val _mapping = new HashMap<EObject, EObject>

		mapping.mappings.forEach [ rm |
			if (_mapping.containsKey(rm.target)) {
				if (issues !== null) {
					issues.error("Duplicate mapping for Rule " + rm.target.name + ".", rm,
						XDsmlComposePackage.Literals.RULE_MAPPING__TARGET, DUPLICATE_RULE_MAPPING)
				}
			} else {
				_mapping.put(rm.target, rm.source)

				rm.element_mappings.filter(ObjectMapping).forEach [ em |
					if (_mapping.containsKey(em.source)) {
						if (issues !== null) {
							issues.error("Duplicate mapping for Object " + em.source.name + ".", em,
								XDsmlComposePackage.Literals.OBJECT_MAPPING__SOURCE, DUPLICATE_OBJECT_MAPPING)
						}
					} else {
						_mapping.put(em.source, em.target)
					}
				]
				rm.element_mappings.filter(LinkMapping).forEach [ em |
					if (_mapping.containsKey(em.source)) {
						if (issues !== null) {
							issues.error("Duplicate mapping for Link " + em.source.name + ".", em,
								XDsmlComposePackage.Literals.LINK_MAPPING__SOURCE, DUPLICATE_LINK_MAPPING)
						}
					} else {
						_mapping.put(em.source, em.target)
					}
				]
			}
		]

		_mapping
	}
}
