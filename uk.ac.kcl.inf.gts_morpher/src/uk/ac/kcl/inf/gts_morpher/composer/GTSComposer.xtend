package uk.ac.kcl.inf.gts_morpher.composer

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtend.lib.annotations.Data
import uk.ac.kcl.inf.gts_morpher.composer.helpers.DefaultNamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import uk.ac.kcl.inf.gts_morpher.composer.weavers.PatternWeaver
import uk.ac.kcl.inf.gts_morpher.composer.weavers.TGWeaver
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRef
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRefOrInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSWeave
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GtsMorpherFactory
import uk.ac.kcl.inf.gts_morpher.util.IProgressMonitor
import uk.ac.kcl.inf.gts_morpher.util.Triple
import uk.ac.kcl.inf.gts_morpher.util.ValueHolder

import static uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*
import static uk.ac.kcl.inf.gts_morpher.util.MorphismChecker.*

import static extension uk.ac.kcl.inf.gts_morpher.composer.weavers.PatternWeaver.weaveAllNames
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MorphismCompleter.*
import static extension uk.ac.kcl.inf.gts_morpher.validation.GTSMorpherValidatorHelper.*

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
class GTSComposer {

	interface Issue {
		def String getMessage()
	}

	private static class ExceptionIssue implements GTSComposer.Issue {
		val Exception exception

		new(Exception e) {
			exception = e
		}

		override getMessage() '''Exception occurred during language composition: «exception.message».'''
	}

	private static class IssueIssue implements GTSComposer.Issue {
		val org.eclipse.xtext.validation.Issue issue

		new(org.eclipse.xtext.validation.Issue issue) {
			this.issue = issue
		}

		override getMessage() '''«issue.severityLabel»: «issue.message» at «issue.lineNumber»:«issue.column».'''

		private def severityLabel(org.eclipse.xtext.validation.Issue issue) {
			switch (issue.severity) {
				case ERROR: return "Error"
				case WARNING: return "Warning"
				case INFO: return "Information"
				case IGNORE: return "Ignore"
				default: return ""
			}
		}
	}

	private static class MessageIssue implements GTSComposer.Issue {
		val String message

		new(String message) {
			this.message = message
		}

		override getMessage() { message }
	}

	/**
	 * Perform the composition.
	 * 
	 * @param resource a resource with the morphism specification. If source is <code>interface_of</code> performs a 
	 * full pushout, otherwise assumes that interface and full language are identical for the source. Currently does 
	 * not support use of <code>interface_of</code> in the target GTS.
	 * 
	 * @param fsa used for file-system access
	 * 
	 * @return a list of issues that occurred when trying to do the composition. Empty rather than null if no issues have occurred.
	 */
	def Triple<List<GTSComposer.Issue>, EPackage, Module> doCompose(GTSWeave weaving, IProgressMonitor monitor) {
		val result = new ArrayList<GTSComposer.Issue>
		var Module composedModule = null
		var EPackage composedTG = null

		try {
			val _monitor = monitor.convert(4)

			// TODO: Should probably validate weaving before going on...
			if ((weaving.mapping1 === null) || (weaving.mapping2 === null)) {
				result.add(new MessageIssue("Both mappings need to be defined"))
			} else {
				val leftMapping = weaving.mapping1.extractMapping(result, _monitor)
				if (result.empty) {
					val rightMapping = weaving.mapping2.extractMapping(result, _monitor)

					if (result.empty) {
						// Actually do the weaving
						val namingStrategy = weaving.options.fold(
							new DefaultNamingStrategy as NamingStrategy, [ acc, opt |
								opt.generateNamingStrategy(acc)
							])

						// Weave
						_monitor.split("Composing type graph.", 1)
						val tgWeaver = new TGWeaver(leftMapping.tgMapping, rightMapping.tgMapping,
							weaving.mapping1.source.metamodel, weaving.mapping1.target.metamodel,
							weaving.mapping2.target.metamodel, namingStrategy)
						composedTG = tgWeaver.weaveTG

						_monitor.split("Composing rules.", 1)
						composedModule = composeBehaviour(leftMapping.behaviourMapping, rightMapping.behaviourMapping,
							weaving.mapping1.source.behaviour, weaving.mapping1.target.behaviour,
							weaving.mapping2.target.behaviour, weaving.mapping1.source.metamodel,
							weaving.mapping1.target.metamodel, weaving.mapping2.target.metamodel, tgWeaver,
							namingStrategy)
					}
				}
			}
		} catch (Exception e) {
			result.add(new ExceptionIssue(e))
			e.printStackTrace
		}

		new Triple(result, composedTG, composedModule)
	}

	@Data
	private static class MappingsPair {
		val Map<EObject, EObject> tgMapping
		val Map<EObject, EObject> behaviourMapping
	}

	private def dispatch MappingsPair extractMapping(GTSMappingRefOrInterfaceSpec spec, ArrayList<GTSComposer.Issue> issues,
		IProgressMonitor monitor) { throw new IllegalArgumentException }

	private def dispatch MappingsPair extractMapping(GTSMappingRef spec, ArrayList<GTSComposer.Issue> issues,
		IProgressMonitor monitor) {
		spec.ref?.extractMapping(issues, monitor)
	}

	private def dispatch MappingsPair extractMapping(GTSMapping mapping, ArrayList<GTSComposer.Issue> issues,
		IProgressMonitor monitor) {
		var tgMapping = mapping.typeMapping.extractMapping(null)
		var behaviourMapping = mapping.behaviourMapping.extractMapping(tgMapping, null)

		if (mapping.autoComplete) {
			monitor.split("Autocompleting.", 1)

			if (!mapping.uniqueCompletion) {
				issues.add(new MessageIssue("Can only weave based on unique auto-completions."))
				return null
			}

			// Auto-complete
			val completions = mapping.getMorphismCompletions(false)
			val completer = completions.key
			if (completions.value == 0) {
				if (completer.completedMappings.size == 1) {
					tgMapping = new HashMap(completer.completedMappings.head.filter [ k, v |
						(k instanceof EClass) || (k instanceof EReference) || (k instanceof EAttribute)
					] as Map<EObject, EObject>)
					behaviourMapping = new HashMap(completer.completedMappings.head.filter [ k, v |
						!((k instanceof EClass) || (k instanceof EReference || (k instanceof EAttribute)))
					] as Map<EObject, EObject>)
				} else {
					issues.add(new MessageIssue("There is no unique auto-completion for this morphism."))
					return null
				}
			} else {
				issues.add(new MessageIssue("Was unable to auto-complete the morphism."))
				return null
			}
		} else {
			// FIXME: Need to validate morphism completeness here, as this is assumed by the weavers and will otherwise potentially crash them
			monitor.split("Validating mapping", 1)

			if (!(!mapping.typeMapping.isInCompleteMapping(tgMapping) && mapping.doCheckIsCompleteBehaviourMapping(null) &&
				mapping.checkIsMorphismMaybeIncomplete(tgMapping, behaviourMapping))) {
				issues.add(new MessageIssue("Not a complete mapping -- cannot weave"))
				return null
			}
		}

		return new MappingsPair(tgMapping, behaviourMapping)
	}

	private def dispatch MappingsPair extractMapping(GTSMappingInterfaceSpec spec, ArrayList<GTSComposer.Issue> issues,
		IProgressMonitor monitor) {
		extension val factory = GtsMorpherFactory.eINSTANCE
		val mockedMapping = createGTSMapping => [
			autoComplete = true
			uniqueCompletion = true
			inclusion = true // To ensure completion can actually be done uniquely
			source = createGTSSpecification => [
				interface_mapping = true
				gts = createGTSReference => [
					ref = spec.gts_ref
				]
			]
			target = createGTSReference => [
				ref = spec.gts_ref
			]
			typeMapping = createTypeGraphMapping // because this is mandatory even when it's empty
		]

		mockedMapping.extractMapping(issues, monitor)
	}

	private def boolean checkIsMorphismMaybeIncomplete(GTSMapping mapping, Map<EObject, EObject> tgMapping, Map<EObject, EObject> behaviourMapping) {
		val isValidTypeMorphism = checkValidMaybeIncompleteClanMorphism(tgMapping, null)

		if (isValidTypeMorphism) {
			checkValidMaybeIncompleteBehaviourMorphism(tgMapping, behaviourMapping, null)
		} else {
			false
		}
	}

	private def Module composeBehaviour(Map<EObject, EObject> leftBehaviourMapping,
		Map<EObject, EObject> rightBehaviourMapping, Module kernelBehaviour, Module leftBehaviour,
		Module rightBehaviour, EPackage kernelMetamodel, EPackage leftMetamodel, EPackage rightMetamodel,
		Map<Pair<Origin, EObject>, EObject> tgMapping, extension NamingStrategy naming) {
		if (leftBehaviourMapping.empty && rightBehaviourMapping.empty) {
			return null
		}

		val kernelRulesIncludingVirtualRules = (leftBehaviourMapping.allKernelRules +
			rightBehaviourMapping.allKernelRules).toSet

		// Temporary index for purposes of weaving rule names
		val ruleWeavingMap = new HashMap<Rule, List<Pair<Origin, Rule>>>

		val result = HenshinFactory.eINSTANCE.createModule => [
			description = weaveDescriptions(kernelBehaviour, leftBehaviour, rightBehaviour)
			imports += tgMapping.get(kernelMetamodel.kernelKey) as EPackage

			units += kernelRulesIncludingVirtualRules.map [ r |
				val composed = r.createComposed(leftBehaviourMapping, rightBehaviourMapping, tgMapping, naming)

				ruleWeavingMap.put(composed,
					#[r.kernelKey, leftBehaviourMapping.getMappedTargetRule(r).leftKey,
						rightBehaviourMapping.getMappedTargetRule(r).rightKey])

				composed
			]
		]

		result.name = weaveNames(
			#{result -> #[kernelBehaviour?.kernelKey, leftBehaviour?.leftKey, rightBehaviour?.rightKey].filterNull},
			result, emptyContext)
		result.units.forEach [ r |
			r.name = weaveNames(ruleWeavingMap, r, [result.units])
		]

		result
	}

	def getAllKernelRules(Map<EObject, EObject> behaviourMapping) {
		behaviourMapping.values.filter(Rule)
	}

	def Rule createComposed(Rule kernelTgtRule, Map<EObject, EObject> leftBehaviourMapping,
		Map<EObject, EObject> rightBehaviourMapping, Map<Pair<Origin, EObject>, EObject> tgMapping,
		extension NamingStrategy naming) {
		// leftRule or rightRule can be null if we have previously introduced a virtual rule in the kernel for one of the mappings.		
		val leftRule = leftBehaviourMapping.getMappedTargetRule(kernelTgtRule)
		val rightRule = rightBehaviourMapping.getMappedTargetRule(kernelTgtRule)

		val lhsWeaver = new PatternWeaver(kernelTgtRule.lhs, leftRule?.lhs, rightRule?.lhs, leftBehaviourMapping,
				rightBehaviourMapping, tgMapping, "Lhs")
		val rhsWeaver = new PatternWeaver(kernelTgtRule.rhs, leftRule?.rhs, rightRule?.rhs, leftBehaviourMapping,
				rightBehaviourMapping, tgMapping, "Rhs")

		val result = HenshinFactory.eINSTANCE.createRule => [
			description = weaveDescriptions(kernelTgtRule.description, leftRule?.description, rightRule?.description)
			injectiveMatching = kernelTgtRule.injectiveMatching
			// TODO Should probably copy parameters, too
			lhs = lhsWeaver.weavePattern
			rhs = rhsWeaver.weavePattern
		]

		// Weave kernel
		val mappingsCreatedFor = new ValueHolder(new HashSet<Node>)		
		result.createMappings(kernelTgtRule, Origin.KERNEL, lhsWeaver, rhsWeaver, mappingsCreatedFor)
		result.createMappings(leftRule, Origin.LEFT, lhsWeaver, rhsWeaver, mappingsCreatedFor)
		result.createMappings(rightRule, Origin.RIGHT, lhsWeaver, rhsWeaver, mappingsCreatedFor)

		// Finally, weave names
		naming.weaveAllNames(#[lhsWeaver, rhsWeaver])		
		
		result
	}

	private def createMappings(Rule result, Rule rule, Origin o, PatternWeaver lhsWeaver, PatternWeaver rhsWeaver, ValueHolder<HashSet<Node>> mappingsCreatedFor) {
		extension val henshinFactory = HenshinFactory.eINSTANCE
		rule?.mappings?.forEach[mp |
			val mappedOrigin = lhsWeaver.get(mp.origin.origKey(o)) as Node
			val mappedImage = rhsWeaver.get(mp.image.origKey(o)) as Node
			
			if ((mappedOrigin !== null) && (mappedImage !== null)) {
				// Avoid creating duplicate mappings
				if ((!mappingsCreatedFor.value.contains(mappedOrigin)) && (!mappingsCreatedFor.value.contains(mappedImage))) {
					result.mappings.add(createMapping(mappedOrigin, mappedImage))
					
					mappingsCreatedFor.value.add(mappedOrigin)
					mappingsCreatedFor.value.add(mappedImage)
				}
			}
		]
	}

	def Rule getMappedTargetRule(Map<EObject, EObject> behaviourMapping, Rule kernelRule) {
		// Remember, rule mappings are the other way around
		behaviourMapping.keySet.filter(Rule).findFirst[r|behaviourMapping.get(r) === kernelRule]
	}

	private static def String weaveDescriptions(Module kernelModule, Module leftModule, Module rightModule) {
		weaveDescriptions(kernelModule?.description, leftModule?.description, rightModule?.description)
	}

	private static def String weaveDescriptions(CharSequence kernelDescription, CharSequence leftDescription,
		CharSequence rightDescription) {
		if ((kernelDescription !== null) || (leftDescription !== null) || (rightDescription !== null)) {
			val kd = (kernelDescription === null) ? "" : kernelDescription
			val ld = (leftDescription === null) ? "" : leftDescription
			val rd = (rightDescription === null) ? "" : rightDescription

			'''«kd» «ld» «rd»'''
		} else {
			null
		}
	}
}
