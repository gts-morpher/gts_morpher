package uk.ac.kcl.inf.gts_morpher.composer

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.HenshinFactory
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Rule
import uk.ac.kcl.inf.gts_morpher.composer.helpers.DefaultNamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import uk.ac.kcl.inf.gts_morpher.composer.weavers.PatternWeaver
import uk.ac.kcl.inf.gts_morpher.composer.weavers.TGWeaver
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRef
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSWeave
import uk.ac.kcl.inf.gts_morpher.util.IProgressMonitor
import uk.ac.kcl.inf.gts_morpher.util.Triple

import static uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MorphismCompleter.*
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRefOrInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.composer.GTSComposer.Issue

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
class GTSComposer {

	interface Issue {
		def String getMessage()
	}

	private static class ExceptionIssue implements uk.ac.kcl.inf.gts_morpher.composer.GTSComposer.Issue {
		val Exception exception

		new(Exception e) {
			exception = e
		}

		override getMessage() '''Exception occurred during language composition: «exception.message».'''
	}

	private static class IssueIssue implements uk.ac.kcl.inf.gts_morpher.composer.GTSComposer.Issue {
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

	private static class MessageIssue implements uk.ac.kcl.inf.gts_morpher.composer.GTSComposer.Issue {
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
	def Triple<List<Issue>, EPackage, Module> doCompose(GTSWeave weaving,
		IProgressMonitor monitor) {
		val result = new ArrayList<Issue>
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
						val namingStrategy = weaving.options.fold(new DefaultNamingStrategy as NamingStrategy, [ acc, opt |
							opt.generateNamingStrategy(acc)
						])
		
						// Weave
						// TODO: produce mergesets here or feed the two mappings into the weavers below to create the mergesets in there when needed
						
						_monitor.split("Composing type graph.", 1)
						val tgWeaver = new TGWeaver
						composedTG = tgWeaver.weaveTG(tgMapping, mapping.source.metamodel, mapping.target.metamodel,
							namingStrategy)
	
						_monitor.split("Composing rules.", 1)
						composedModule = composeBehaviour(mapping.source.behaviour, mapping.target.behaviour,
							behaviourMapping, mapping.source.metamodel, tgWeaver, namingStrategy)
					}
				}
			}
		} catch (Exception e) {
			result.add(new ExceptionIssue(e))
			e.printStackTrace
		}

		new Triple(result, composedTG, composedModule)
	}
	
	private def dispatch extractMapping(GTSMappingRefOrInterfaceSpec spec, ArrayList<Issue> issues, IProgressMonitor monitor) { throw new IllegalArgumentException }
	private def dispatch extractMapping(GTSMappingRef spec, ArrayList<Issue> issues, IProgressMonitor monitor) {
		val mapping = spec.ref
		
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
			monitor.split("", 1)
		}
		
		return new Pair(tgMapping, behaviourMapping)
	}
	private def dispatch extractMapping(GTSMappingInterfaceSpec spec, ArrayList<Issue> issues, IProgressMonitor monitor) { throw new IllegalArgumentException }

	private def Module composeBehaviour(Module srcBehaviour, Module tgtBehaviour,
		Map<EObject, EObject> behaviourMapping, EPackage srcPackage, Map<Pair<Origin, EObject>, EObject> tgMapping,
		extension NamingStrategy naming) {
		if (behaviourMapping.empty) {
			return null
		}

		// Temporary index for purposes of weaving rule names
		val ruleWeavingMap = new HashMap<Rule, List<Pair<Origin, Rule>>>

		val result = HenshinFactory.eINSTANCE.createModule => [
			description = weaveDescriptions(srcBehaviour, tgtBehaviour)
			imports += tgMapping.get(srcPackage.sourceKey) as EPackage

			units += behaviourMapping.keySet.filter(Rule).map [ r |
				val composed = r.createComposed(behaviourMapping, tgMapping, naming)

				ruleWeavingMap.put(composed, #[(behaviourMapping.get(r) as Rule).sourceKey, r.targetKey])

				composed
			]
		]

		result.name = weaveNames(#{result -> #[srcBehaviour?.sourceKey, tgtBehaviour?.targetKey].filterNull}, result,
			emptyContext)
		result.units.forEach [ r |
			r.name = weaveNames(ruleWeavingMap, r, [result.units])
		]

		result
	}

	def Rule createComposed(Rule tgtRule, Map<EObject, EObject> behaviourMapping,
		Map<Pair<Origin, EObject>, EObject> tgMapping, extension NamingStrategy naming) {
		val srcRule = behaviourMapping.get(tgtRule) as Rule

		val result = HenshinFactory.eINSTANCE.createRule => [
			description = weaveDescriptions(tgtRule.description, srcRule.description)
			injectiveMatching = srcRule.injectiveMatching
			// TODO Should probably copy parameters, too
			lhs = new PatternWeaver(srcRule.lhs, tgtRule.lhs, behaviourMapping, tgMapping, "Lhs", naming).weavePattern
			rhs = new PatternWeaver(srcRule.rhs, tgtRule.rhs, behaviourMapping, tgMapping, "Rhs", naming).weavePattern
		]

		// Weave kernel
		result.lhs.nodes.map [ n |
			val n2 = result.rhs.nodes.findFirst[n2|n.name.equals(n2.name)]
			if (n2 !== null) {
				new Pair(n, n2)
			} else {
				null
			}
		].reject[n|n === null].forEach [ p |
			result.mappings.add(HenshinFactory.eINSTANCE.createMapping(p.key, p.value))
		]

		result
	}

	private static def String weaveDescriptions(Module sourceModule, Module targetModule) {
		weaveDescriptions(if(sourceModule !== null) sourceModule.description else null,
			if(targetModule !== null) targetModule.description else null)
	}

	private static def String weaveDescriptions(CharSequence sourceDescription, CharSequence targetDescription) {
		if (sourceDescription === null) {
			if (targetDescription !== null) {
				targetDescription.toString
			} else {
				null
			}
		} else if ((targetDescription === null) || (sourceDescription.equals(targetDescription))) {
			sourceDescription.toString
		} else
			'''Merged from «sourceDescription» and «targetDescription».'''
	}
}
