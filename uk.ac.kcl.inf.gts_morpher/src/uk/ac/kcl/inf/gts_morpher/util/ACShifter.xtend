package uk.ac.kcl.inf.gts_morpher.util

import org.eclipse.emf.henshin.model.Formula
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Not
import org.eclipse.emf.henshin.model.NestedCondition

/**
 * Helper class for shifting an application condition along a mapping
 */
class ACShifter {
	
	static extension val HenshinFactory factory = HenshinFactory.eINSTANCE
	
	/**
	 * Shift the formula given along the provided mappings
	 * 
	 * @return Not yet sure that returning a fully packaged formula is really the right thing here...
	 */
	static dispatch def Formula shift(Formula formula, Map<EObject, EObject> tgMapping, Map<EObject, EObject> behaviourMapping) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	static dispatch def Formula shift(Not formula, Map<EObject, EObject> tgMapping, Map<EObject, EObject> behaviourMapping) {
		createNot => [
			child = formula.child.shift(tgMapping, behaviourMapping)
		]
	}
	
	static dispatch def Formula shift(NestedCondition formula, Map<EObject, EObject> tgMapping, Map<EObject, EObject> behaviourMapping) {
		null
	}
}