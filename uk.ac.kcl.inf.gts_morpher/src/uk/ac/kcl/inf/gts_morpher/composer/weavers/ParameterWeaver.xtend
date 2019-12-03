package uk.ac.kcl.inf.gts_morpher.composer.weavers

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.HenshinPackage
import org.eclipse.emf.henshin.model.Parameter
import org.eclipse.emf.henshin.model.Rule
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*

class ParameterWeaver extends AbstractWeaver {

	val Map<Pair<Origin, EObject>, EObject> tgMapping
	var List<Parameter> wovenParameters = new ArrayList
	
	extension val HenshinPackage henshin = HenshinPackage.eINSTANCE	

	new(Rule kernelTgtRule, Rule leftRule, Rule rightRule, Map<EObject, EObject> leftBehaviourMapping,
		Map<EObject, EObject> rightBehaviourMapping, Map<Pair<Origin, EObject>, EObject> tgMapping) {
		super(
			new ModelSpan(leftBehaviourMapping.filteredMapping(leftRule),
				rightBehaviourMapping.filteredMapping(rightRule), kernelTgtRule, leftRule, rightRule).calculateMergeSet,
			leftBehaviourMapping.unmappedElements(leftRule),
			rightBehaviourMapping.unmappedElements(rightRule)
		)

		this.tgMapping = tgMapping
	}

	private static def filteredMapping(Map<EObject, EObject> behaviourMapping, Rule tgtRule) {
		new HashMap(behaviourMapping.filter [ k, v |
			tgtRule?.parameters?.contains(v)
		])
	}

	private static def unmappedElements(Map<EObject, EObject> behaviourMapping, Rule tgtRule) {
		if (tgtRule !== null) {
			tgtRule.parameters.reject[p|behaviourMapping.containsValue(p)].map[it as EObject].toList
		} else {
			emptyList
		}
	}
	
	def weaveParameters() {
		doWeave(Parameter, parameter, [ p, ms |
			p.createParameter
		], [ p, o |
			p.createParameter(o)
		])
		
		wovenParameters
	}
	
	def weaveNames(extension NamingStrategy naming) {
		val invertedMapping = keySet.groupBy[p | get(p)]
		
		wovenParameters.forEach[p | 
			p.name = invertedMapping.weaveNames(p, p.uniquenessContext)
		]
	}
	
	private def createParameter(Parameter pSrc) {
		// Origin doesn't matter for mapped elements, must be target because we've decided to copy data from target TG
		pSrc.createParameter(Origin.KERNEL)
	}

	private def createParameter(Parameter pSrc, Origin origin) {
		val result = HenshinFactory.eINSTANCE.createParameter => [
			kind = pSrc.kind
			if (pSrc.type instanceof EClass) {
				type = tgMapping.get(pSrc.type.origKey(origin)) as EClass
			} else {
				type = pSrc.type
			}
		]

		wovenParameters += result

		result
	}
}
