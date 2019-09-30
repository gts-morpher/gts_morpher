package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Map
import org.eclipse.emf.ecore.EObject
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*

class DontLabelNonKernelNames extends AbstractChainedNamingStrategy {
	new(NamingStrategy fallback) {
		super(fallback)
	}

	protected override String preferredNameFor(EObject objectToName,
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup) {
		val nonNullSources = nameSourcesLookup.get(objectToName)?.filterNull

		if (nonNullSources.size == 1) {
			// This element is a non-kernel element
			return nonNullSources.head.value.name.toString
		}

		null
	}
}
