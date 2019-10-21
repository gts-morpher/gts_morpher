package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*
import java.util.ArrayList

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

		/*
		 * Need to sortBy[key] twice: the first time to make sure equal names are sorted in the same order 
		 * when we see them in the fold bit, the second time to actually sort by key again
		 */
		nameSources.sortBy[key].sortBy[value.name.toString].fold(
			new ArrayList<Pair<Origin, ? extends EObject>>, [ acc, elt |
				// Skip if the same name occurs twice
				if (elt.value.name != acc.last?.value.name) {
					acc.add(elt)
				}
				acc
			]).sortBy[key].map[value?.name].filterNull.fold(null, [ acc, n |
			weaveNameStrings(acc, n)
		]).toString
	}

	override String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		nameSources.sortBy[key].map[value.nsPrefix].fold(null, [ acc, n |
			weaveNameStrings(acc, n)
		]).toString
	}

	// TODO We can probably do better here :-)
	override String weaveURIs(
		Iterable<Pair<Origin, EPackage>> nameSources) '''https://metamodel.woven/«nameSources.sortBy[key].map[value.nsPrefix].join('/')»'''

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
