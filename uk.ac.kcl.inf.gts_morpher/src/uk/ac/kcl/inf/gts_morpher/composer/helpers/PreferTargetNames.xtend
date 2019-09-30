package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*

class PreferTargetNames extends AbstractChainedNamingStrategy {
	new(NamingStrategy fallback) {
		super(fallback)
	}

	protected override String preferredNameFor(EObject objectToName,
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup) {
		val nameSources = nameSourcesLookup.get(objectToName)

		if (nameSources?.findFirst[p|p.key === Origin.SOURCE] !== null) {
			nameSources?.findFirst[p|p.key === Origin.TARGET]?.value?.name?.toString
		} else {
			null
		}
	}

	override String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		nameSources.findFirst[p|p.key === Origin.TARGET].value.nsPrefix
	}

	override String weaveURIs(EPackage srcPackage, EPackage tgtPackage) {
		tgtPackage.nsURI
	}
}
