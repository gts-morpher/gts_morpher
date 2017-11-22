package uk.ac.kcl.inf.util

import java.util.HashMap
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

/**
 * Basic util methods for handling mappings
 */
class BasicMappingChecker {
	public static val DUPLICATE_CLASS_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_CLASS_MAPPING'
	public static val DUPLICATE_REFERENCE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_REFERENCE_MAPPING'

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
					issues.error('''Duplicate mapping for EClassifier «cm.source.name».''', cm,
						XDsmlComposePackage.Literals.CLASS_MAPPING__SOURCE, DUPLICATE_CLASS_MAPPING)
				}
			} else {
				_mapping.put(cm.source, cm.target)
			}
		]
		mapping.mappings.filter(ReferenceMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				if (issues !== null) {
					issues.error('''Duplicate mapping for EReference «cm.source.name».''', cm,
						XDsmlComposePackage.Literals.REFERENCE_MAPPING__SOURCE, DUPLICATE_REFERENCE_MAPPING)
				}
			} else {
				_mapping.put(cm.source, cm.target)
			}
		]
		_mapping
	}
}
