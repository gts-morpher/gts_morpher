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

		nameSources.sortBy[it.value.name.toString].sortBy[key].map[ns|ns.value.name].fold(null, [ acc, n |
			weaveNameStrings(acc, n)
		]).toString
	}

	override String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		val sourceName = nameSources.findFirst[p|p.key === Origin.SOURCE]?.value?.nsPrefix
		val targetName = nameSources.findFirst[p|p.key === Origin.TARGET]?.value?.nsPrefix

		weaveNameStrings(sourceName, targetName).toString
	}

	// TODO We can probably do better here :-)
	override String weaveURIs(EPackage srcPackage,
		EPackage tgtPackage) '''https://metamodel.woven/«srcPackage.nsPrefix»/«tgtPackage.nsPrefix»'''

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
