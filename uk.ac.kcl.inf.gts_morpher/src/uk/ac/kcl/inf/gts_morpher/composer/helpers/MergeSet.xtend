package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.HashSet
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Data

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*

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

	def boolean hasType(EClass ec) {
		ec.isSuperTypeOf(kernel.head.eClass)
	}
	
	def getKeyedMergeList() {
		(left.map[ep|ep.leftKey] + kernel.map[ep|ep.kernelKey] + right.map [ ep |
				ep.rightKey
			]).toList
	}

	static def fromMerge(MergeSet ms1, MergeSet ms2) {
		new MergeSet(new HashSet((ms1.kernel + ms2.kernel).toSet), new HashSet((ms1.left + ms2.left).toSet), new HashSet((ms1.right + ms2.right).toSet))
	}
}
