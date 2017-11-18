/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.validation

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.validation.Check
import uk.ac.kcl.inf.validation.checkers.TypeMorphismChecker.Issue
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static uk.ac.kcl.inf.validation.checkers.TypeMorphismChecker.*

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class XDsmlComposeValidator extends AbstractXDsmlComposeValidator {
	public static val DUPLICATE_CLASS_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_CLASS_MAPPING'
	public static val DUPLICATE_REFERENCE_MAPPING = 'uk.ac.kcl.inf.xdsml_compose.DUPLICATE_REFERENCE_MAPPING'
	public static val NOT_A_CLAN_MORPHISM = 'uk.ac.kcl.inf.xdsml_compose.NOT_A_CLAN_MORPHISM'

	/**
	 * Check that no source EClass or EReference is mapped more than once in the given mapping.
	 */
	@Check
	def checkMapsUniqueSources(TypeGraphMapping mapping) {
		mapping.extractMapping
	}

	/**
	 * Check that the given mappings do not violate the rules for clan morphisms
	 */
	@Check
	def checkIsMorphismMaybeIncomplete(TypeGraphMapping mapping) {
		val List<Issue> issues = new ArrayList
		if (!checkValidMaybeIncompleteClanMorphism(extractMapping(mapping), issues)) {
			issues.forEach [ i |
				if (i.sourceModelElement instanceof EClassifier) {
					error(i.message, mapping.mappings.filter(ClassMapping).
						findFirst[m|m.source == i.sourceModelElement],
						XDsmlComposePackage.Literals.CLASS_MAPPING__TARGET, NOT_A_CLAN_MORPHISM)
				} else if (i.sourceModelElement instanceof EReference) {
					error(i.message, mapping.mappings.filter(ReferenceMapping).
						findFirst[m|m.source == i.sourceModelElement],
						XDsmlComposePackage.Literals.REFERENCE_MAPPING__TARGET, NOT_A_CLAN_MORPHISM)
				}
			]
		}
	}

	private static val TYPE_MAPPINGS = XDsmlComposeValidator.canonicalName + ".typeMappings"

	/**
	 * Extract the type mapping information as a Map. Also ensure no element is mapped more than once; report errors 
	 * otherwise. Expects to be called in a validation context.
	 */
	private def extractMapping(TypeGraphMapping mapping) {
		if (context.containsKey(TYPE_MAPPINGS)) {
			return context.get(TYPE_MAPPINGS) as Map<EObject, EObject>
		}

		val Map<EObject, EObject> _mapping = new HashMap
		mapping.mappings.filter(ClassMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				error('''Duplicate mapping for EClassifier �cm.source.name�.''', cm,
					XDsmlComposePackage.Literals.CLASS_MAPPING__SOURCE, DUPLICATE_CLASS_MAPPING)
			} else {
				_mapping.put(cm.source, cm.target)
			}
		]
		mapping.mappings.filter(ReferenceMapping).forEach [ cm |
			if (_mapping.containsKey(cm.source)) {
				error('''Duplicate mapping for EReference �cm.source.name�.''', cm,
					XDsmlComposePackage.Literals.REFERENCE_MAPPING__SOURCE, DUPLICATE_REFERENCE_MAPPING)
			} else {
				_mapping.put(cm.source, cm.target)
			}
		]

		context.put(TYPE_MAPPINGS, _mapping)

		_mapping
	}
}
