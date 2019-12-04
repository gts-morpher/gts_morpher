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
import org.eclipse.emf.henshin.model.Attribute

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
		val invertedMapping = keySet.groupBy[p|get(p)]

		wovenParameters.forEach [ p |
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

	/**
	 * Rewrite attribute expressions based on changes to parameter names. To be called after rule has been woven 
	 * and all names have been determined.
	 */
	def weaveAttributeExpressions(List<PatternWeaver> weavers) {
		// TODO: All these inverted mappings have been calculated before. Can we reuse those?
		val allMappings = weavers.fold(new HashMap<Pair<Origin, EObject>, EObject>) [ acc, pw |
			acc.putAll(pw)
			acc
		]

		val invertedSlotMapping = allMappings.keySet.filter[value instanceof Attribute].groupBy[p|allMappings.get(p)]

		val invertedParameterMapping = keySet.groupBy[p|get(p)]

		// TODO: Find a way to reuse the regexp construction below
		invertedSlotMapping.keySet.forEach [ slot |
			/*
			 * There are two cases here for every slot: either the slot has already got a representative in the kernel or it doesn't. 
			 * In the former case, the expression will have been copied in from the kernel, so we just need to rename based on kernel parameter names and mappings from kernel parameters to woven parameters. 
			 * We can choose any of the source slots in the kernel, because they will all be identical (because we're currently checking for syntactic identity in the morphism checks). 
			 * In the latter case, there will be only one source from either the left or right mapping and we use this for rewriting names together with the corresponding parameter mappings. 
			 */
			val slotSources = invertedSlotMapping.get(slot)
			val parameterOrigin = if (slotSources.exists[key === Origin.KERNEL]) {
					// This slot comes from the kernel, so rewrite based on the kernel parameters
					Origin.KERNEL
				} else {
					// slotSources should only contain one element, whose origin tells us which parameters to use for rewriting.
					if (slotSources.size > 1) {
						throw new IllegalStateException("Was expecting at most one source slot")
					} else {
						slotSources.head.key
					}
				}
			val slotToRework = slotSources.filter[key === parameterOrigin].head.value as Attribute

			invertedParameterMapping.keySet.forEach [ p |
				val replacementText = '''$1«(p as Parameter).name»$2'''

				invertedParameterMapping.get(p).filter[key === parameterOrigin].forEach [ srcP |
					val regexp = '''(^|[^_a-zA-Z])«(srcP.value as Parameter).name»([^_a-zA-Z0-9]|$)'''

					slotToRework.value = slotToRework.value.replaceAll(regexp, replacementText)
				]
			]
		]
	}

}
