package uk.ac.kcl.inf.gts_morpher.composer.weavers

import java.util.HashMap
import java.util.List
import java.util.Set
import java.util.function.BiFunction
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import uk.ac.kcl.inf.gts_morpher.composer.helpers.MergeSet
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*

/**
 * Abstract super class to enable code reuse for the template pattern for weaving stuff. 
 */
abstract class AbstractWeaver extends HashMap<Pair<Origin, EObject>, EObject> {
	protected val Set<MergeSet> mergeSets
	protected val List<EObject> unmappedLeftElements
	protected val List<EObject> unmappedRightElements
	
	protected new(Set<MergeSet> mergeSets, List<EObject> unmappedLeftElements, List<EObject> unmappedRightElements) {
		this.mergeSets = mergeSets
		this.unmappedLeftElements = unmappedLeftElements
		this.unmappedRightElements = unmappedRightElements
	}
	
	protected def <T1 extends EObject, T2 extends EClass> void doWeave(
		Class<T1> clazz, T2 eType, BiFunction<T1, List<Pair<Origin, EObject>>, T1> weaver, 
		BiFunction<T1, Origin, T1> unmappedElementCloner
	) {
		if (eType.instanceClass !== clazz) { // Cannot express this with generics, so need to check explicitly
			throw new IllegalArgumentException("Mismatch in eClass information")
		}
		
		// Weave mapped classes
		mergeSets.filter[hasType(eType)].forEach [ ms |
			val keyedMergeList = ms.keyedMergeList
			
			// FIXME: currently we're basing this only on the first kernel element. Should probably define some proper weaving rules here 			
			val merged = weaver.apply(ms.kernel.head as T1, keyedMergeList)

			keyedMergeList.forEach [ kep |
				put(kep, merged)
			]
		]

		// Create copies for all unmapped classes
		unmappedLeftElements.filter(clazz).forEach [ ec |
			put(ec.leftKey, unmappedElementCloner.apply(ec, Origin.LEFT))
		]
		unmappedRightElements.filter(clazz).forEach [ ec |
			put(ec.rightKey, unmappedElementCloner.apply(ec, Origin.RIGHT))
		]
	}
	
	override EObject get(Object key) {
		if (key instanceof Pair) {
			if ((key.key instanceof Origin) && ((key.value === null) || (key.value instanceof EObject))) {
				return super.get(key)
			}
		} 
		throw new IllegalArgumentException("Requiring a pair in call to get!")
	}
}
