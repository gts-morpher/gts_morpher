package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Data

/**
 * TODO: Make a top-level class
 */
@Data
class MergeSet {
	val Set<EObject> kernel
	val Set<EObject> left
	val Set<EObject> right

	def addLeft(EObject l) {
		left.add(l)
	}

	def addKernel(EObject k) {
		kernel.add(k)
	}

	def addRight(EObject r) {
		right.add(r)
	}

	static def fromMerge(MergeSet ms1, MergeSet ms2) {
		new MergeSet((ms1.kernel + ms2.kernel).toSet, (ms1.left + ms2.left).toSet, (ms1.right + ms2.right).toSet)
	}
}