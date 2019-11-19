package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*

class PreferNames extends AbstractChainedNamingStrategy {
	val Origin toPrefer
	
	new(NamingStrategy fallback, Origin toPrefer) {
		super(fallback)
		
		this.toPrefer = toPrefer
	}

	protected override String _preferredNameFor(EObject objectToName,
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup) {
		val nameSources = nameSourcesLookup.get(objectToName)

		if (nameSources?.findFirst[p|p.key !== toPrefer] !== null) {
			nameSources?.findFirst[p|p.key === toPrefer]?.value?.name?.toString
		} else {
			null
		}
	}

	override String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		nameSources.findFirst[p|p.key === toPrefer].value.nsPrefix
	}

	override String weaveURIs(Iterable<Pair<Origin, EPackage>> nameSources) {
		nameSources.findFirst[p|p.key === toPrefer].value.nsURI
	}
}
