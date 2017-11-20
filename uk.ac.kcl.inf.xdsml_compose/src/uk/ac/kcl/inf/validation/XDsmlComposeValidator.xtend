/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.validation

import java.util.ArrayList
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.validation.Check
import uk.ac.kcl.inf.util.BasicMappingChecker
import uk.ac.kcl.inf.util.BasicMappingChecker.IssueAcceptor
import uk.ac.kcl.inf.util.TypeMorphismChecker.Issue
import uk.ac.kcl.inf.util.TypeMorphismCompleter
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static uk.ac.kcl.inf.util.TypeMorphismChecker.*
import static uk.ac.kcl.inf.util.BasicMappingChecker.*
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.validation.CheckType

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
	public static val NO_UNIQUE_COMPLETION = 'uk.ac.kcl.inf.xdsml_compose.NO_UNIQUE_COMPLETION'
	public static val UNIQUE_COMPLETION_NOT_CHECKED = 'uk.ac.kcl.inf.xdsml_compose.UNIQUE_COMPLETION_NOT_CHECKED'

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
					error(i.message, mapping.mappings.filter(ReferenceMapping).findFirst [ m |
						m.source == i.sourceModelElement
					], XDsmlComposePackage.Literals.REFERENCE_MAPPING__TARGET, NOT_A_CLAN_MORPHISM)
				}
			]
		}
	}

	/**
	 * Check that the given mapping is complete
	 */
	@Check
	def checkIsCompleteMapping(TypeGraphMapping mapping) {
		if (mapping.isInCompleteMapping && !(mapping.eContainer as GTSMapping).autoComplete) {
			warning("Incomplete mapping. Ensure all elements of the source metamodel are mapped.", mapping,
				XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING__SOURCE, INCOMPLETE_TYPE_GRAPH_MAPPING)
		}
	}

	/**
	 * Check that we can auto-complete, if requested to do so
	 */
	@Check
	def checkCanAutoCompleteMapping(GTSMapping mapping) {
		if (mapping.autoComplete) {
			// Check we can auto-complete type mapping
			val typeMapping = mapping.typeMapping
			val _mapping = typeMapping.extractMapping
			if (typeMapping.isInCompleteMapping) {
				if (checkValidMaybeIncompleteClanMorphism(_mapping, null)) {
					val morphismCompleter = new TypeMorphismCompleter(_mapping, mapping.typeMapping.source,
						mapping.typeMapping.target)
					if (morphismCompleter.findMorphismCompletions(mapping.uniqueCompletion && (checkMode.shouldCheck(CheckType.EXPENSIVE))) != 0) {
						error("Cannot complete type mapping to a valid morphism", mapping,
							XDsmlComposePackage.Literals.GTS_MAPPING__TYPE_MAPPING, UNCOMPLETABLE_TYPE_GRAPH_MAPPING)
					} else if (morphismCompleter.completedMappings.size > 1) {
						// Found more than one mapping (this can only happen if we were looking for all mappings), so need to report this as an error
						error("Cannot uniquely complete type mapping to a valid morphism", mapping,
							XDsmlComposePackage.Literals.GTS_MAPPING__UNIQUE_COMPLETION, NO_UNIQUE_COMPLETION)
					} else if (mapping.uniqueCompletion && (!checkMode.shouldCheck(CheckType.EXPENSIVE))) {
						warning("Uniqueness of mapping has not been checked. Please run explicit validation from editor context menu to check this.", mapping,
							XDsmlComposePackage.Literals.GTS_MAPPING__UNIQUE_COMPLETION, UNIQUE_COMPLETION_NOT_CHECKED)
					}
				}
			} else {
				warning("Type morphism is already complete", mapping,
					XDsmlComposePackage.Literals.GTS_MAPPING__AUTO_COMPLETE)
			}
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
	 * Return true if the given mapping is incomplete
	 */
	private def isInCompleteMapping(TypeGraphMapping mapping) {
		val _mapping = mapping.extractMapping
		mapping.source.eAllContents.filter[me|me instanceof EClassifier || me instanceof EReference].exists [ me |
			!_mapping.containsKey(me)
		]
	}
}
