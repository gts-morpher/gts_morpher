package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.WeaveOption

/**
 * A strategy to use when deciding on the names of new model elements created by composition.
 */
interface NamingStrategy {
	def String weaveNames(
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
		EObject objectToName, UniquenessContext context)

	def String weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources)

	def String weaveURIs(Iterable<Pair<Origin, EPackage>> nameSources)

	static def generateNamingStrategy(List<WeaveOption> options) {
		new GloballyUniquifyNames(options.fold(new DefaultNamingStrategy as NamingStrategy, [ acc, opt |
			opt.generateNamingStrategy(acc)
		]))
	}

	static def NamingStrategy generateNamingStrategy(WeaveOption option, NamingStrategy existingStrategy) {
		switch (option) {
			case DONT_LABEL_NON_KERNEL_ELEMENTS:
				return new DontLabelNonKernelNames(existingStrategy)
			case PREFER_KERNEL_NAMES:
				return new PreferNames(existingStrategy, Origin.KERNEL)
			// FIXME: This isn't correct: need to take into account what map1 and map2 actually are and differentiate the naming accordingly.
			case PREFER_MAP1_TARGET_NAMES:
				return new PreferNames(existingStrategy, Origin.LEFT)
			case PREFER_MAP2_TARGET_NAMES:
				return new PreferNames(existingStrategy, Origin.RIGHT)
			default:
				return existingStrategy
		}
	}
}
