package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

/**
 * A chained naming strategy. 
 * 
 * Chained naming strategies may make a decision about a particular aspect of naming. If they do not make a decision,
 * they hand over the decision to a fallback naming strategy. If they do make a decision, but it turns out to lead to 
 * a non-unique name, they pass on the naming decision to the default naming strategy. 
 */
abstract class AbstractChainedNamingStrategy extends DefaultNamingStrategy {
	protected val NamingStrategy fallback

	new(NamingStrategy fallback) {
		this.fallback = fallback
	}

	protected def boolean isUniqueInContext(String proposedName, EObject objectToName, UniquenessContext context,
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup) {
		!context.contextElements.exists [ eo |
			(eo !== objectToName) && (proposedName == preferredNameFor(eo, nameSourcesLookup))
		]
	}

	protected def String preferredNameFor(EObject eo,
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup)

	override String weaveNames(
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
		EObject objectToName, UniquenessContext context) {
		val tentativeName = preferredNameFor(objectToName, nameSourcesLookup)

		if (tentativeName !== null) {
			if (tentativeName.isUniqueInContext(objectToName, context, nameSourcesLookup)) {
				// Go with the name decided
				tentativeName
			} else {
				// Our decision was non-unique
				super.weaveNames(nameSourcesLookup, objectToName, context)
			}
		} else {
			// We haven't made a decision
			fallback.weaveNames(nameSourcesLookup, objectToName, context)
		}
	}

	override String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		fallback.weaveNameSpaces(nameSources)
	}

	override String weaveURIs(EPackage srcPackage, EPackage tgtPackage) {
		fallback.weaveURIs(srcPackage, tgtPackage)
	}
}
