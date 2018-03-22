package uk.ac.kcl.inf.util

import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.ListIterator
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static org.eclipse.core.runtime.Assert.*
import static uk.ac.kcl.inf.util.MorphismChecker.*

import static extension uk.ac.kcl.inf.util.EMFHelper.*
import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.util.MappingConverter.*

/**
 * Helper for completing type mappings into clan morphisms 
 */
class MorphismCompleter {

	/**
	 * Create and return a morphism completer for the given GTSMapping. Completions will not be run yet.
	 */
	static def createMorphismCompleter(GTSMapping mapping) {
		val _typeMapping = mapping.typeMapping.extractMapping(null)
		val _behaviourMapping = mapping.behaviourMapping.extractMapping(null)

		new MorphismCompleter(_typeMapping, mapping.source.metamodel, mapping.target.metamodel, _behaviourMapping,
			mapping.source.behaviour, mapping.target.behaviour, mapping.source.interface_mapping,
			mapping.target.interface_mapping)
		}

		/**
		 * This will contain the results, if any
		 */
		@Accessors(PUBLIC_GETTER)
		private var List<Map<? extends EObject, ? extends EObject>> completedMappings = new ArrayList

		/**
		 * If true, then we were able to at least complete a type mapping.
		 */
		@Accessors(PUBLIC_GETTER)
		private var boolean completedTypeMapping = false

		private var Map<EObject, EObject> typeMapping
		private var EPackage srcPackage
		private var EPackage tgtPackage
		private var List<EObject> allSrcModelElements
		private var List<EObject> allTgtModelElements
		private var List<EClass> allTgtClasses
		private var List<EReference> allTgtReferences
		private var List<EAttribute> allTgtAttributes

		private var Map<EObject, EObject> behaviourMapping
		private var Module srcModule
		private var Module tgtModule
		private List<EObject> allSrcBehaviorElements
		private List<EObject> allTgtBehaviorElements

		private var boolean srcIsInterface = false
		private var boolean tgtIsInterface = false

		new(Map<EObject, EObject> typeMapping, EPackage srcPackage, EPackage tgtPackage,
			Map<EObject, EObject> behaviourMapping, Module srcModule, Module tgtModule, boolean srcIsInterface,
			boolean tgtIsInterface) {
				this.typeMapping = new HashMap<EObject, EObject>(typeMapping)
				this.srcPackage = srcPackage
				this.tgtPackage = tgtPackage
				this.srcIsInterface = srcIsInterface
				this.tgtIsInterface = tgtIsInterface

				allSrcModelElements = srcPackage.allContents
				if (srcIsInterface) {
					allSrcModelElements = allSrcModelElements.filter [ eo |
						(eo as EModelElement).isInterfaceElement
					].toList
				}
				allTgtModelElements = tgtPackage.allContents
				if (tgtIsInterface) {
					allTgtModelElements = allTgtModelElements.filter [ eo |
						(eo as EModelElement).isInterfaceElement
					].toList
				}

				// Cache target classes and references for future lookups
				allTgtClasses = allTgtModelElements.filter(EClass).toList
				allTgtReferences = allTgtModelElements.filter(EReference).toList
				allTgtAttributes = allTgtModelElements.filter(EAttribute).toList
				allTgtClasses = Collections.unmodifiableList(allTgtClasses)
				allTgtReferences = Collections.unmodifiableList(allTgtReferences)
				allTgtAttributes = Collections.unmodifiableList(allTgtAttributes)

				this.behaviourMapping = behaviourMapping
				this.srcModule = srcModule
				this.tgtModule = tgtModule
				allSrcBehaviorElements = srcModule.allContents
				if (srcIsInterface) {
					allSrcBehaviorElements = allSrcBehaviorElements.filter [ eo |
						if (eo instanceof Node) {
							eo.type.isInterfaceElement
						} else if (eo instanceof Edge) {
							eo.type.isInterfaceElement
						} else {
							true
						}
					].toList
				}
				allTgtBehaviorElements = tgtModule.allContents
				if (tgtIsInterface) {
					allTgtBehaviorElements = allTgtBehaviorElements.filter [ eo |
						if (eo instanceof Node) {
							eo.type.isInterfaceElement
						} else if (eo instanceof Edge) {
							eo.type.isInterfaceElement
						} else {
							true
						}
					].toList
				}
			}

			/**
			 * Attempts to complete the mapping between the source and target GTSs
			 * by incrementally adding elements until morphism rules are broken.
			 * 
			 * Reports back the number of unmatched elements for the biggest mapping found.
			 * If a full morphism has been found, {@link #typeMapping} and {@link behaviourMapping} show
			 * this mapping, which can also be found in {@link #completedMappings}. Otherwise, 
			 * {@link #typeMapping} and {@link behaviourMapping} are unchanged when this method returns 
			 * (but will change during the execution of the method).
			 * 
			 * @return the number of unmatched elements in the biggest morphism-like mapping found, 0 if morphism(s) can be found
			 */
			def int tryCompleteMorphism() {
				findMorphismCompletions(false)
			}

			/**
			 * Attempts to complete the mapping between the source and target GTSs
			 * by incrementally adding elements until morphism rules are broken.
			 * 
			 * Reports back the number of unmatched elements for the biggest mapping found.
			 * If a full morphism has been found, {@link #typeMapping} and {@link behaviourMapping} show
			 * this mapping, which can also be found in {@link #completedMappings}. Otherwise, 
			 * {@link #typeMapping} and {@link behaviourMapping} are unchanged when this method returns 
			 * (but will change during the execution of the method). If findAll is true, all morphism 
			 * completions will be found and will be stored in {@link #completedMappings}. In this case, 
			 * {@link #typeMapping} will be left unchanged at the end.
			 * 
			 * @param findAll if true, and a completion can be found, all completions will be found
			 *  
			 * @return the number of unmatched elements in the biggest morphism-like mapping found, 0 if morphism(s) can be found
			 */
			def int findMorphismCompletions(boolean findAll) {
				completedMappings = new ArrayList
				completedTypeMapping = false

				var List<EObject> unmatchedTGElements = unmatchedTGElements
				var List<EObject> unmatchedBehaviourElements = unmatchedBehaviourElements

				// check if the map contains the package, if not add
				if (unmatchedTGElements.contains(srcPackage)) {
					typeMapping.put(srcPackage, tgtPackage)
					unmatchedTGElements.remove(srcPackage)
				}

				// If the mapping is already not a morphism, return the maximum size of
				// unmatched elements
				if (!checkValidMaybeIncompleteClanMorphism(typeMapping, null)) {
					return allSrcModelElements.size()
				} else {
					// Otherwise, check if we're already done and have mapped everything
					if (unmatchedTGElements.empty) {
						return handleFoundTGMorphism(unmatchedBehaviourElements, findAll)
					}
				}

				// get first priority list and search all objects
				doTryCompleteTypeMorphism(unmatchedTGElements, unmatchedTGElements.firstPrioritySet,
					unmatchedBehaviourElements, findAll)
			}

			/**
			 * Recursively seek to extend the mapping to create a full morphism. Report back
			 * the smallest number of unmatched elements before breaking morphism rules
			 * found so far.
			 * 
			 * @param unmatchedTGElements
			 *            - a list of unmatched TG elements
			 * @param unmatchedBehaviourElements
			 *            - a list of unmatched behaviour elements
			 * @param priorityList
			 *            - a list of priority unmatched elements
			 * @param findAll
			 *            - if true, find all morphism completions, if any
			 * @return the number of unmatched elements in the model morphism
			 */
			private def int doTryCompleteTypeMorphism(List<EObject> unmatchedTGElements, Set<EObject> _prioritySet,
				List<EObject> unmatchedBehaviourElements, boolean findAll) {
				// If the mapping is already not a morphism, return the number of unmatched elements
				if (!checkValidMaybeIncompleteClanMorphism(typeMapping, null)) {
					// There's already at least one element too many in the map
					return unmatchedTGElements.size + unmatchedBehaviourElements.size + 1
				} else {
					// Otherwise, check if we're already done and have mapped everything
					if (unmatchedTGElements.empty) {
						return handleFoundTGMorphism(unmatchedBehaviourElements, findAll)
					}
				}

				// Pick an unmatched object either from priority list or general list
				var EObject pick = null
				if (_prioritySet.empty) {
					pick = unmatchedTGElements.remove(0)
				} else {
					pick = _prioritySet.head
					_prioritySet.remove(pick)
					unmatchedTGElements.remove(pick)
				}

				var prioritySet = pick.getPriorityModelObjects(unmatchedTGElements, _prioritySet)
				// Need to add one because we don't actually know yet if this will be able to
				// make a morphism
				var int numUnmatched = unmatchedTGElements.size + unmatchedBehaviourElements.size + 1

				var List<? extends EObject> possible = pick.getPossibleMatches()
				// go through all possible objects and recursively find matches for further objects
				for (EObject o : possible) {
					typeMapping.put(pick, o)
					val int numUnmatchedInDescend = doTryCompleteTypeMorphism(unmatchedTGElements, prioritySet,
						unmatchedBehaviourElements, findAll)
					// make sure count reflects the minimum found count
					if (!findAll && (numUnmatchedInDescend == 0)) {
						return 0
					} else {
						if (numUnmatchedInDescend < numUnmatched) {
							numUnmatched = numUnmatchedInDescend
						}
					}
				}

				typeMapping.remove(pick)
				unmatchedTGElements.add(pick)
				return numUnmatched
			}

			/**
			 * Called whenever we've found a TG morphism. Try to complete it by a behaviour morphism.
			 * 
			 * @return the minimal number of elements that could not be mapped
			 */
			private def int handleFoundTGMorphism(List<EObject> unmatchedBehaviourElements, boolean findAll) {
				// TODO Better logging
				println('''Found TG morphism {«typeMapping.entrySet.map[ e | '''«e.key.name» => «e.value.name»'''].join(',\n\t')»}.''')
				completedTypeMapping = true

				// Check if we need to do any behaviour mapping
				if ((srcModule === null) && (tgtModule === null)) {
					completedMappings.add(new HashMap(typeMapping))
					return 0
				}

				// Check if we stand a chance of completing the behaviour mapping at all
				if (!checkValidMaybeIncompleteBehaviourMorphism(typeMapping, behaviourMapping, null)) {
					println("Behaviour mapping is already not a morphism under this TG morphism.")
					return unmatchedBehaviourElements.size + 1
				}

				// Try to complete behaviour mapping
				if (behaviourMapping.containsKey(srcModule)) {
					if (behaviourMapping.get(srcModule) != tgtModule) {
						println("Weird behaviour mapping.")
						return unmatchedBehaviourElements.size + 1
					}
				}
				behaviourMapping.put(srcModule, tgtModule)
				unmatchedBehaviourElements.remove(srcModule)

				return tryMapRules(unmatchedBehaviourElements, findAll)
			}

			/**
			 * Return possible matches for a source model element. All possible matches will be taken from the target model.
			 * 
			 * @param srcObject
			 *            - source model element
			 * @return a list of the possible matches in the target model
			 */
			private dispatch def List<? extends EObject> getPossibleMatches(EObject srcObject) {
				// Really nothing to match in this case
				Collections.EMPTY_LIST
			}

			/**
			 * Return possible matches for a source model class. All possible matches will be taken from the target model.
			 * 
			 * @param srcClass
			 *            - source model element
			 * @return a list of the possible matching classes in the target model
			 */
			private dispatch def List<EClass> getPossibleMatches(EClass srcClass) {
				// Potentially all target classes might be a match
				val List<EClass> possibleMatches = new ArrayList(allTgtClasses)

				// Check super class, if any, and use any mapping information to narrow down the
				// set of potential matches
				var List<EClass> superTypes = srcClass.ESuperTypes
				while (!superTypes.empty) {
					var List<EClass> newCandidateSuperTypes = new ArrayList()

					for (EClass currentSuperType : superTypes) {
						if (typeMapping.containsKey(currentSuperType)) {
							// Use the image to restrict the search
							val EClass superTypeImage = typeMapping.get(currentSuperType) as EClass
							possibleMatches.retainAll(superTypeImage.getClan(allTgtClasses))
							if (possibleMatches.empty) {
								// No matches for this class, then!
								return possibleMatches
							}
						} else {
							// Check whether any super types of this super type are mapped
							newCandidateSuperTypes.addAll(currentSuperType.ESuperTypes)
						}
					}

					superTypes = newCandidateSuperTypes
				}

				// Check contained references to see if they've been mapped
				// Only need to check directly contained references, those declared in super
				// types should be covered by the checks above if at all
				for (EReference ref : srcClass.EReferences) {
					val EClass refSrcClass = ref.EContainingClass

					if (typeMapping.containsKey(refSrcClass)) {
						val EClass refSrcClassImage = typeMapping.get(refSrcClass) as EClass

						possibleMatches.retainAll(refSrcClassImage.getClan(allTgtClasses))

						if (possibleMatches.empty) {
							// No matches for this class, then!
							return possibleMatches
						}
					}
				}

				// TODO Check references targeting srcClass.
				// I've not implemented this here, because it's actually computationally quite
				// heavy (it requires a complete traversal of the srcReferences list) and I'm
				// not convinced that the benefit outweighs the cost.
				// Return whatever remains
				possibleMatches
			}

			private dispatch def List<EReference> getPossibleMatches(EReference srcReference) {
				// Potentially, all references in the target could be matches
				val List<EReference> possibleMatches = new ArrayList(allTgtReferences)

				/*
				 * Use source class to narrow selection: If the source class has a mapping, the
				 * image must be in the clan of any eligible reference. Note if the direct
				 * source class isn't mapped, we cannot restrict the set of potential matches
				 * based on one of the super types as we might later map the direct source
				 * class, too.
				 */
				val EClass srcSrcClass = srcReference.EContainingClass
				if (typeMapping.containsKey(srcSrcClass)) {
					val EClass tgtSrcClass = typeMapping.get(srcSrcClass) as EClass

					val ListIterator<EReference> it = possibleMatches.listIterator()
					while (it.hasNext()) {
						val EReference currentTgtRef = it.next()
						val EClass currentTgtSrcClass = currentTgtRef.EContainingClass

						if (!currentTgtSrcClass.getClan(allTgtClasses).contains(tgtSrcClass)) {
							// This reference isn't a match
							it.remove()
						}
					}
				}

				if (!possibleMatches.empty) {
					/*
					 * Use target class to narrow selection: If the target class has a mapping, the
					 * image must be in the clan of any eligible reference. Note if the direct
					 * target class isn't mapped, we cannot restrict the set of potential matches
					 * based on one of the super types as we might later map the direct target
					 * class, too.
					 */
					if (srcReference.EType instanceof EClass) {
						val EClass srcTgtClass = srcReference.EType as EClass
						if (typeMapping.containsKey(srcTgtClass)) {
							val EClass tgtTgtClass = typeMapping.get(srcTgtClass) as EClass
							val ListIterator<EReference> it = possibleMatches.listIterator()
							while (it.hasNext()) {
								val EReference currentTgtRef = it.next()
								if (currentTgtRef.EType instanceof EClass) {
									val EClass currentTgtTgtClass = currentTgtRef.getEType() as EClass

									if (!currentTgtTgtClass.getClan(allTgtClasses).contains(tgtTgtClass)) {
										// This reference isn't a match
										it.remove()
									}
								}
							}
						}
					}
				}

				possibleMatches
			}

			private dispatch def List<EAttribute> getPossibleMatches(EAttribute srcAttribute) {
				// Potentially, all attributes in the target could be matches, if they have the same type as the source attribute
				// TODO: If we switch to allow type widening/narrowing, this needs to change
				val List<EAttribute> possibleMatches = allTgtAttributes.reject[ea|ea.EType !== srcAttribute.EType].
					toList

				/*
				 * Use source class to narrow selection: If the source class has a mapping, the
				 * image must be in the clan of any eligible attributes. Note if the direct
				 * source class isn't mapped, we cannot restrict the set of potential matches
				 * based on one of the super types as we might later map the direct source
				 * class, too.
				 */
				val EClass srcSrcClass = srcAttribute.EContainingClass
				if (typeMapping.containsKey(srcSrcClass)) {
					val EClass tgtSrcClass = typeMapping.get(srcSrcClass) as EClass

					val ListIterator<EAttribute> it = possibleMatches.listIterator()
					while (it.hasNext()) {
						val EAttribute currentTgtAttr = it.next()
						val EClass currentTgtSrcClass = currentTgtAttr.EContainingClass

						if (!currentTgtSrcClass.getClan(allTgtClasses).contains(tgtSrcClass)) {
							// This reference isn't a match
							it.remove()
						}
					}
				}

				possibleMatches
			}

			/**
			 * Returns a first priority list in the model. This is determined by going
			 * through the elements currently mapped already and finding new elements
			 * connected to them and not yet mapped.
			 * 
			 * @param unmatchedList
			 * @return a first priority list in the model
			 */
			private def Set<EObject> getFirstPrioritySet(List<EObject> unmatchedList) {
				typeMapping.keySet.fold(new HashSet<EObject>() as Set<EObject>, [ s, eo |
					eo.getPriorityModelObjects(unmatchedList, s)
				])
			}

			/**
			 * Returns a list of priority objects for an element {@code pick}. Priority
			 * elements are those elements that are connected to the given object through
			 * references or by being sub-classes thereof.
			 * 
			 * @param pick
			 * @param unmatchedList
			 * @param previousPriorityList
			 * @param allSrcBehaviorElements
			 * @return a list of priority objects for an element {@code pick}
			 */
			private def Set<EObject> getPriorityModelObjects(EObject pick, List<EObject> unmatchedList,
				Collection<EObject> previousPriorityObjects) {
				val prioritySet = new HashSet<EObject>(previousPriorityObjects)

				if (pick instanceof EReference) {
					// if picked object is an EReference, add its target and source to the priority
					// list if they are in unmatched list
					val EClass eclass1 = (pick as EReference).EReferenceType
					val EClass eclass2 = (pick as EReference).EContainingClass

					if (unmatchedList.contains(eclass1))
						prioritySet.add(eclass1)
					if (unmatchedList.contains(eclass2))
						prioritySet.add(eclass2)
				} else if (pick instanceof EAttribute) {
					// If picked object is an EAttribute, add its source to the priority list if it's not yet mapped
					val srcClass = (pick as EAttribute).EContainingClass

					if (unmatchedList.contains(srcClass))
						prioritySet.add(srcClass)
				} else if (pick instanceof EClass) {
					// if picked object is an EClass
					// add its EReferences to the priority list if they are unmatched
					// TODO: Original code wasn't filtering for references
					pick.eContents.filter(EReference).filter[er|unmatchedList.contains(er)].forEach [ er |
						prioritySet.add(er)
					]

					// Also add in all unmatched  attributes
					pick.eContents.filter(EAttribute).filter[ea|unmatchedList.contains(ea)].forEach [ ea |
						prioritySet.add(ea)
					]

					// add its Subclasses to the priority list if they are unmatched
					allSrcModelElements.filter(EClass).filter[ec|ec.ESuperTypes.contains(pick)].filter [ ec |
						unmatchedList.contains(ec)
					].forEach[ec|prioritySet.add(ec)]
				}

				prioritySet
			}

			/**
			 * Return a list of elements that are not yet matched in the {@code typeMapping}.
			 * 
			 * @return a list of elements that are not yet matched in the {@code typeMapping}
			 */
			private def List<EObject> getUnmatchedTGElements() {
				allSrcModelElements.filter [ eo |
					!typeMapping.containsKey(eo)
				].toList
			}

			/**
			 * Returns a list of elements not yet matched in the {@link behaviourMapping}.
			 */
			private def List<EObject> getUnmatchedBehaviourElements() {
				var result = allSrcBehaviorElements.reject[eo|eo instanceof Rule].toList
				result.removeAll(behaviourMapping.keySet)
				if (tgtModule !== null) {
					result.addAll(tgtModule.units.filter(Rule).reject[r|behaviourMapping.containsKey(r)])
				}

				result
			}

			@Data
			private static abstract class MorphismOrNonmatchedCount {
			}

			@Data
			private static class Morphism extends MorphismOrNonmatchedCount {
				private val List<Pair<Rule, List<Pair<EObject, EObject>>>> mappingVariants
			}

			@Data
			private static class NonmatchedCount extends MorphismOrNonmatchedCount {
				private val int numUnmatched
			}

			/**
			 * Try to map all rules with complete rule morphisms. Return the minimum number of unmatched elements if no morphism completion can be found. Alternatively, store the complete 
			 * mapping (including the type mapping) in {@link #completedMappings}. If findAll is true, find all possible completions. Otherwise, stop when the first completion has been found.
			 */
			private def tryMapRules(List<EObject> unmappedBehaviourElements, boolean findAll) {
				/*
				 * Plan: 
				 * 
				 * 1. Check whether rule morphisms can be established. There may be many ways in which to complete a particular rule morphism, but at this level we're only interested in 
				 *    whether a rule morphism can be established at all. We do this in two steps:
				 * 
				 *    1. Check the rules that have already been mapped. Here we just check whether these rule mappings can be meaningfully completed to rule morphisms.
				 *    2. Check the rules that have not been mapped yet. Here we have more freedom to choose which rule to map to which, so we need to do a full recursive descend. For sanity, 
				 *       we assume that there are no Object or Link mappings without a corresponding Rule mapping. Note that this will always be satisfied for mappings that come from the DSML.
				 * 
				 *    In each case, we call out to a function that tries to complete the rule morphism. If there are multiple options for completing the morphism, and findAll is true, this will 
				 *    return all options. We use the resulting list to create all combinations once we have mapped all rules.
				 * 
				 * 2. Once all target rules are mapped, we need to check that we have mapped to all source rules. If not, we need to add in mappings from virtual nop rules --> TODO figure out what exactly we need to do here.
				 * 
				 * 3. Once all mappings have been established, create all recombinations to produce the full set of valid morphisms, if so required. Alternatively, just pick one and go with it :-)
				 */
				// This will store all possible rule mappings found for each target rule or the minimum number of unmatched elements for that rule
				val resultData = new ValueHolder<Map<Rule, MorphismOrNonmatchedCount>>(
					new HashMap<Rule, MorphismOrNonmatchedCount>(allTgtBehaviorElements.filter(Rule).size))

				// 1. Check rules that are already mapped and try to complete their morphisms
				behaviourMapping.keySet.filter(Rule).toList.forEach [ r |
					// Check rule morphism can be completed and find all possible completions and the minimum number of unmapped elements *within the rule*
					resultData.value.put(r,
						tryCompleteRuleMorphism(r, behaviourMapping.get(r) as Rule, unmappedBehaviourElements, findAll))
				]

				// 2. Check the rules that have not been mapped yet
				var unmappedRules = unmappedBehaviourElements.filter(Rule).toList
				doTryMapRules(unmappedRules, unmappedBehaviourElements, findAll, resultData.value)

				// TODO: 3. Check all source rules have been mapped to, too
				// 4. Figure out mappings to return
				if (resultData.value.values.exists[v|v instanceof NonmatchedCount]) {
					// Didn't manage to produce a match for all rules
					return resultData.value.values.filter(NonmatchedCount).fold(0, [acc, nmc|acc + nmc.numUnmatched])
				} else {
					// Matched all rules, now need to merge results
					// No need to consider findAll; that's already been taken into account in the search
					recombineFoundMappings(resultData.value)

					return 0
				}
			}

			/**
			 * Try to map all remaining unmapped rules, placing the results into the result parameter.
			 */
			private def doTryMapRules(List<Rule> unmappedRules, List<EObject> unmappedBehaviourElements,
				boolean findAll, Map<Rule, MorphismOrNonmatchedCount> result) {
				unmappedRules.forEach [ pick |
					val ValueHolder<MorphismOrNonmatchedCount> resultForPick = new ValueHolder(null)

					allSrcBehaviorElements.filter(Rule).forEach [ r |
						behaviourMapping.put(pick, r)
						val possibleRuleMorphism = tryCompleteRuleMorphism(pick, r, unmappedBehaviourElements, findAll)

						if (resultForPick.value === null) {
							resultForPick.value = possibleRuleMorphism
						} else {
							if (possibleRuleMorphism instanceof Morphism) {
								// store
								if (resultForPick.value instanceof Morphism) {
									(resultForPick.value as Morphism).mappingVariants.addAll(
										possibleRuleMorphism.mappingVariants)
								} else {
									resultForPick.value = possibleRuleMorphism
								}
							} else {
								if (resultForPick.value instanceof NonmatchedCount) {
									if ((resultForPick.value as NonmatchedCount).numUnmatched >
										(possibleRuleMorphism as NonmatchedCount).numUnmatched) {
										resultForPick.value = possibleRuleMorphism
									}
								}
							}
						}

						behaviourMapping.remove(pick)
					]

					result.put(pick, resultForPick.value)
				]
			}

			/**
			 * Try to complete the rule morphism between srcRule and tgtRule considering all unmapped elements in these rules.
			 */
			private def MorphismOrNonmatchedCount tryCompleteRuleMorphism(Rule tgtRule, Rule srcRule,
				List<EObject> unmappedBehaviourElements, boolean findAll) {
				val unmappedPatterns = unmappedBehaviourElements.filter(Graph).filter[g|g.eContainer == srcRule].toList
				unmappedPatterns.forEach [ p |
					if (p == srcRule.lhs) {
						behaviourMapping.put(srcRule.lhs, tgtRule.lhs)
						unmappedBehaviourElements.remove(p)
					} else if (p == srcRule.rhs) {
						behaviourMapping.put(srcRule.rhs, tgtRule.rhs)
						unmappedBehaviourElements.remove(p)
					}
				]

				val elementsToMap = unmappedBehaviourElements.filter(GraphElement).filter [ pe |
					pe.eContainer.eContainer == srcRule
				].toList

				val slotMappingsToComplete = behaviourMapping.keySet.filter(Node).filter [ n |
					n.eContainer.eContainer === srcRule
				].map [ n |
					new Pair<Node, List<Attribute>>(behaviourMapping.get(n) as Node, n.unmappedAttributes)
				].toList

				val result = doTryCompleteRuleMorphism(slotMappingsToComplete, srcRule, tgtRule, elementsToMap, findAll)

				// Restore unmapped patterns
				unmappedPatterns.forEach [ p |
					behaviourMapping.remove(p)
					unmappedBehaviourElements.add(p)
				]

				result
			}

			/**
			 * Map one more graph element and descend recursively if possible
			 */
			def MorphismOrNonmatchedCount doTryCompleteRuleMorphism(Rule srcRule, Rule tgtRule,
				List<GraphElement> elementsToMap, boolean findAll) {
				// Check it's still a rule morphism
				if (!checkRuleMorphism(tgtRule, srcRule, typeMapping, behaviourMapping, null)) {
					// We've mapped at least one element too many in this rule, already
					return new NonmatchedCount(elementsToMap.size + 1)
				}

				// Check whether we're done and, if so, return appropriately
				if (elementsToMap.empty) {
					var mappingVariant = new ArrayList<Pair<Rule, List<Pair<EObject, EObject>>>>
					// Report a new morphism from tgtRule to srcRule with the specific mappings found
					mappingVariant.add(new Pair(srcRule, behaviourMapping.filter [ src, tgt |
						((src instanceof Graph) && (src.eContainer == srcRule)) ||
							((src instanceof GraphElement) && (src.eContainer.eContainer == srcRule)) ||
							((src instanceof Attribute) && (src.eContainer.eContainer.eContainer == srcRule))
					].entrySet.map[e|new Pair<EObject, EObject>(e.key, e.value)].toList))

					return new Morphism(mappingVariant)
				}

				// Pick an element to map and find a mapping, then recursively descend
				val pick = elementsToMap.remove(0)
				var unmatchedCount = elementsToMap.size + 1
				var Morphism morphism = null
				val possibleMatches = findPossibleMatches(pick, tgtRule)

				// TODO: Should make sure kernel mappings are preserved a priori, too, to avoid overly many checks
				for (currentMatch : possibleMatches) {
					behaviourMapping.put(pick, currentMatch)

					var MorphismOrNonmatchedCount descendResult = null

					if (pick instanceof Node) {
						// Go through any attribute slots and make sure they've got a complete mapping, too
						descendResult = doTryCompleteRuleMorphism(currentMatch as Node, pick.unmappedAttributes,
							emptyList, srcRule, tgtRule, elementsToMap, findAll)
					} else {
						descendResult = doTryCompleteRuleMorphism(srcRule, tgtRule, elementsToMap, findAll)
					}

					if (descendResult instanceof Morphism) {
						unmatchedCount = 0

						if (!findAll) {
							return descendResult
						} else {
							// Extend current morphism, if any
							if (morphism === null) {
								morphism = descendResult
							} else {
								morphism.mappingVariants.addAll(descendResult.mappingVariants)
							}
						}
					} else if (descendResult instanceof NonmatchedCount) {
						if (unmatchedCount > descendResult.numUnmatched) {
							unmatchedCount = descendResult.numUnmatched
						}
					}

					behaviourMapping.remove(pick)
				}

				elementsToMap.add(0, pick)

				if (morphism !== null) {
					return morphism
				} else {
					return new NonmatchedCount(unmatchedCount)
				}
			}

			/**
			 * Recursively descend, continuing by mapping the unmappedAttributes first, before going on to other bits.
			 */
			private def MorphismOrNonmatchedCount doTryCompleteRuleMorphism(
				List<Pair<Node, List<Attribute>>> remainingNodesToComplete, Rule srcRule, Rule tgtRule,
				List<GraphElement> elementsToMap, boolean findAll) {

				if (remainingNodesToComplete.empty) {
					return doTryCompleteRuleMorphism(srcRule, tgtRule, elementsToMap, findAll)
				} else {
					val pick = remainingNodesToComplete.remove(0)
					return doTryCompleteRuleMorphism(pick.key, pick.value, remainingNodesToComplete, srcRule, tgtRule,
						elementsToMap, findAll)
				}
			}

			/**
			 * Recursively descend, continuing by mapping the unmappedAttributes first, before going on to other bits.
			 */
			private def MorphismOrNonmatchedCount doTryCompleteRuleMorphism(Node tgtNode,
				List<Attribute> unmappedAttributes, List<Pair<Node, List<Attribute>>> remainingNodesToComplete,
				Rule srcRule, Rule tgtRule, List<GraphElement> elementsToMap, boolean findAll) {

				if (unmappedAttributes.empty) {
					return doTryCompleteRuleMorphism(remainingNodesToComplete, srcRule, tgtRule, elementsToMap, findAll)
				}

				val pick = unmappedAttributes.remove(0)
				// There should only be one
				val tgtAttribute = tgtNode.attributes.findFirst[a|typeMapping.get(pick.type) === a.type]

				if ((tgtAttribute === null) || (tgtIsInterface && !tgtAttribute.type.isInterfaceElement) ||
					(pick.value != tgtAttribute.value)) {
					// FIXME: Not ideal as we're not differentiating situations where slots are partially mapped
					// println("Couldn't map slot.")
					var unmatchedCount = elementsToMap.size + 1
					return new NonmatchedCount(unmatchedCount)
				}

				behaviourMapping.put(pick, tgtAttribute)
				// println("Slot mapped: " + pick.type.name)
				var descendResult = doTryCompleteRuleMorphism(tgtNode, unmappedAttributes, remainingNodesToComplete,
					srcRule, tgtRule, elementsToMap, findAll)

				behaviourMapping.remove(pick)

				descendResult
			}

			/**
			 * Get all unmapped attributes of the given (source) node.
			 */
			private def getUnmappedAttributes(Node n) {
				n.attributes.reject [ a |
					(srcIsInterface && !a.type.isInterfaceElement) || behaviourMapping.containsKey(a)
				].toList
			}

			private def List<? extends GraphElement> findPossibleMatches(GraphElement pick, Rule tgtRule) {
				val Rule srcRule = pick.eContainer.eContainer as Rule
				val srcPattern = pick.eContainer as Graph

				if (srcPattern == srcRule.lhs) {
					findPossibleMatchesInPattern(pick, tgtRule.lhs)
				} else {
					findPossibleMatchesInPattern(pick, tgtRule.rhs)
				}
			}

			private dispatch def List<? extends GraphElement> findPossibleMatchesInPattern(GraphElement pick,
				Graph tgtPattern) {
				Collections.EMPTY_LIST
			}

			private dispatch def List<Node> findPossibleMatchesInPattern(Node pick, Graph tgtPattern) {
				// TODO Check we're using the right clan relation here 
				val pickTgtClan = (typeMapping.get((pick as Node).type) as EClass).getClan(allTgtClasses)
				tgtPattern.nodes.filter [ n |
					pickTgtClan.contains(n.type)
				].toList
			}

			private dispatch def List<Edge> findPossibleMatchesInPattern(Edge pick, Graph tgtPattern) {
				// TODO Check we're using the right clan relation here 
				val pickSrcTgtClan = (typeMapping.get((pick as Edge).source.type) as EClass).getClan(allTgtClasses)
				val pickTgtTgtClan = (typeMapping.get((pick as Edge).target.type) as EClass).getClan(allTgtClasses)

				tgtPattern.edges.filter [ e |
					pickSrcTgtClan.contains(e.source.type) && pickTgtTgtClan.contains(e.target.type)
				].toList
			}

			/**
			 * Recursively recombine all possible morphism mappings and add them to {@link completedMappings}.
			 */
			private def recombineFoundMappings(Map<Rule, MorphismOrNonmatchedCount> mappings) {
				doRecombineFoundMappings(mappings.entrySet.toList, new HashMap(typeMapping))
			}

			private def void doRecombineFoundMappings(
				List<Map.Entry<Rule, MorphismOrNonmatchedCount>> remainingMappings,
				Map<? extends EObject, ? extends EObject> recombinedMorphism) {
				if (remainingMappings.empty) {
					completedMappings.add(recombinedMorphism)
					return
				}

				val pick = remainingMappings.remove(0)

				(pick.value as Morphism).mappingVariants.forEach [ v |
					// TODO Move creation of new map to end of recursion
					val newMorphism = new HashMap(recombinedMorphism)
					newMorphism.put(pick.key, v.key)
					v.value.forEach[vv|newMorphism.put(vv.key, vv.value)]
					doRecombineFoundMappings(remainingMappings, newMorphism)
				]

				remainingMappings.add(0, pick)
			}

			/**
			 * Returns a list of all elements in the EPackage
			 * 
			 * @param ePackage
			 *            - EPackage
			 * @return a list of all elements in the EPackage
			 */
			private static def getAllContents(EPackage ePackage) {
				ePackage.eAllContents.filter [ eo |
					// dont add generictypes
					// TODO: Why not? 
					!eo.eClass().getName().equals("EGenericType")
				].toList
			}

			private static def getAllContents(Module module) {
				if (module !== null) {
					var result = module.units.filter(Rule).map [ r |
						var List<EObject> result = new ArrayList<EObject>()
						result.add(r)
						result.add(r.lhs)
						result.add(r.rhs)

						result.addAll(r.lhs.nodes)
						result.addAll(r.rhs.nodes)

						result.addAll(r.lhs.edges)
						result.addAll(r.rhs.edges)

						result
					].flatten.toList

					result.add(module)

					result
				} else {
					Collections.EMPTY_LIST
				}
			}

			/**
			 * Find the clan of {@code clazz} in the set of model elements in
			 * {@code allModelElements}
			 * 
			 * @param clazz
			 * @param allModelElements
			 * @return a list of a clan members of {@code clazz}
			 */
			private static def List<EClass> getClan(EClass clazz, List<? extends EObject> allModelElements) {
				isNotNull(clazz)

				var clan = new ArrayList<EClass>()
				clan.add(clazz)

				clan.addAll(allModelElements.filter(EClass).filter[ec|ec.ESuperTypes.contains(clazz)].map [ ec |
					ec.getClan(allModelElements)
				].flatten)

				clan
			}
		}
		