package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.HashMap
import java.util.HashSet
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtend.lib.annotations.Data

/**
 * A collection of individual EObject spans. 
 */
class ModelSpan {
	val Set<EObjectSpan> modelElementSpans = new HashSet

	new(Map<EObject, EObject> leftMapping, Map<EObject, EObject> rightMapping, EPackage kernelPackage,
		EPackage leftPackage, EPackage rightPackage) {
		initialise(leftMapping, rightMapping, kernelPackage, leftPackage, rightPackage)
	}

	new(Map<EObject, EObject> leftMapping, Map<EObject, EObject> rightMapping, Graph kernelGraph, Graph leftGraph,
		Graph rightGraph) {
		initialise(leftMapping, rightMapping, kernelGraph, leftGraph, rightGraph)
	}

	new(Map<EObject, EObject> leftMapping, Map<EObject, EObject> rightMapping, Module kernelModule, Module leftModule,
		Module rightModule) {
		initialise(leftMapping, rightMapping, kernelModule, leftModule, rightModule)
	}

	private final def initialise(Map<EObject, EObject> leftMapping, Map<EObject, EObject> rightMapping, EObject kernel,
		EObject left, EObject right) {
		modelElementSpans.add(new EObjectSpan(kernel, left, right))

		modelElementSpans.addAll(kernel.eAllContents.map [ eo |
			val l = leftMapping.get(eo)
			val r = rightMapping.get(eo)
			if ((l !== null) && (r !== null)) {
				new EObjectSpan(eo, l, r)
			} else {
				null
			}
		].filterNull.toList)
	}

	/**
	 * A span-mapping between a single kernel EObject and EObjects on the left and the right. Part of a GTS span.
	 */
	@Data
	private static class EObjectSpan {
		val EObject kernel
		val EObject left
		val EObject right
	}
	
	private static def makeMergeSet(EObjectSpan eos) {
		new MergeSet(#{eos.kernel}, #{eos.left}, #{eos.right})
	}

	@Data
	private static class MergeSetAccumulator extends HashMap<EObject, MergeSet> {
		val Set<MergeSet> mergeSets = new HashSet

		new() {
		}

		/**
		 * This method incrementally accumulates all objects that need to be merged because they are referenced by overlapping EObjectSpans. This is where the magic is. 
		 * 
		 * The method works by keeping track of what objects from the left or the right have already been included in some merge set (kernel elements will, by definition, 
		 * only occur at most once in any given set of spans). When a new span is added, we first check if we have seen the left or right object before and, if so, simply 
		 * update the existing mergeset. Special attention needs to be paid when the left and right element have only been included in different mergesets so far. In this 
		 * case, we need to merge the two mergesets and update all the references to replace the two old mergesets with the new one. 
		 */
		def addSpan(EObjectSpan eos) {
			val leftSet = get(eos.left)
			val rightSet = get(eos.right)

			if ((leftSet === null) && (rightSet === null)) {
				val ms = eos.makeMergeSet()
				mergeSets.add(ms)
				put(eos.left, ms)
				put(eos.right, ms)
			} else if ((leftSet === null) && (rightSet !== null)) {
				rightSet.addLeft(eos.left)
				rightSet.addKernel(eos.kernel)

				put(eos.left, rightSet)
			} else if ((leftSet !== null) && (rightSet === null)) {
				leftSet.addRight(eos.right)
				leftSet.addKernel(eos.kernel)

				put(eos.right, leftSet)
			} else if (leftSet === rightSet) {
				leftSet.addKernel(eos.kernel)
			} else {
				// Two different merge sets, need to merge them together and replace the original ones with the new ones
				val mergedSet = MergeSet.fromMerge(leftSet, rightSet)

				put(eos.kernel, mergedSet)

				// Replace all references to one of the original sets with a reference to the merged set -- need toList to make a copy of the set of keys
				keySet.filter [ k |
					val ms = get(k)
					((ms === leftSet) || (ms === rightSet))
				].toList.forEach [ k |
					put(k, mergedSet)
				]
			}

			this
		}
	}

	/**
	 * Calculate the set of objects to be merged in an amalgamation.
	 */
	def calculateMergeSet() {
		modelElementSpans.fold(new MergeSetAccumulator, [ acc, s |
			acc.addSpan(s)
		]).mergeSets
	}
}
