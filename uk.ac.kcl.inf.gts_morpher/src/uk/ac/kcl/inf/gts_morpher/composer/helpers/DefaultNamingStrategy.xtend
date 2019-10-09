package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*

/**
 * This strategy currently doesn't undertake any uniqueness checks for names produced.
 */
class DefaultNamingStrategy implements NamingStrategy {
	override String weaveNames(
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
		EObject objectToName, UniquenessContext context) {
		val nameSources = nameSourcesLookup.get(objectToName)
		val nonNullSources = nameSources?.filterNull

		if (nonNullSources.size == 1) {
			// This element is a non-kernel element
			val element = nonNullSources.head
			return '''«element.key.label»__«element.value.name»'''
		}

		nameSources.sortBy[value.name.toString].sortBy[key].map[value.name].fold(null, [ acc, n |
			weaveNameStrings(acc, n)
		]).toString
	}

	override String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		nameSources.sortBy[key].map[value.name].fold(null, [acc, n | 
			weaveNameStrings(acc, n)
		]).toString
	}

	// TODO We can probably do better here :-)
	override String weaveURIs(Iterable<Pair<Origin, EPackage>> nameSources)
	 '''https://metamodel.woven/«nameSources.sortBy[key].map[value.nsPrefix].join('/')»'''

	private def weaveNameStrings(CharSequence sourceName, CharSequence targetName) {
		if (sourceName === null) {
			if (targetName !== null) {
				targetName.toString
			} else {
				null
			}
		} else if ((targetName === null) || (sourceName.equals(targetName))) {
			sourceName.toString
		} else
			'''«sourceName»_«targetName»'''
	}
}
