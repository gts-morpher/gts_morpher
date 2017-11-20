package uk.ac.kcl.inf.validation.checkers

import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.List
import java.util.ListIterator
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference

import static uk.ac.kcl.inf.validation.checkers.TypeMorphismChecker.*

/**
 * Helper for completing type mappings into clan morphisms 
 */
// TODO This probably will live better in a different package outside the validation tree
class TypeMorphismCompleter {
	private var Map<EObject, EObject> typeMapping
	private var EPackage srcPackage
	private var EPackage tgtPackage
	private var List<EObject> allSrcModelElements
	private var List<EObject> allTgtModelElements
	private var List<EClass> allTgtClasses
	private var List<EReference> allTgtReferences

	new(Map<EObject, EObject> typeMapping, EPackage srcPackage, EPackage tgtPackage) {
		this.typeMapping = new HashMap<EObject, EObject>(typeMapping)
		this.srcPackage = srcPackage
		this.tgtPackage = tgtPackage
		allSrcModelElements = srcPackage.allContents
		allTgtModelElements = tgtPackage.allContents

		// Cache target classes and references for future lookups
		allTgtClasses = allTgtModelElements.filter(EClass).toList
		allTgtReferences = allTgtModelElements.filter(EReference).toList
		allTgtClasses = Collections.unmodifiableList(allTgtClasses)
		allTgtReferences = Collections.unmodifiableList(allTgtReferences)
	}

	/**
	 * Attempts to complete the model mapping between the source and target packages
	 * by incrementally adding elements until clan-morphism rules are broken.
	 * 
	 * Reports back the number of unmatched elements for the biggest mapping found.
	 * If a full morphism has been found, {@link #typeMapping} shows this mapping.
	 * Otherwise, {@link #typeMapping} is unchanged when this method returns (but it
	 * will change during the execution of the method).
	 * 
	 * @return the number of unmatched elements in the biggest morphism-like mapping
	 *         found
	 */
	def int tryCompleteTypeMorphism() {
		var List<EObject> unmatchedList = unmatched

		// check if the map contains the package, if not add
		if (unmatchedList.contains(srcPackage)) {
			typeMapping.put(srcPackage, tgtPackage)
			unmatchedList.remove(srcPackage)
		}

		// If the mapping is already not a morphism, return the maximum size of
		// unmatched elements
		if (!checkValidMaybeIncompleteClanMorphism(typeMapping, null)) {
			return allSrcModelElements.size()
		} else {
			// Otherwise, check if we're already done and have mapped everything
			if (unmatchedList.empty) {
				// TODO We can probably do better than this
				System.out.println('''Found TG morphism {«typeMapping.entrySet.map[ e | '''«e.key.name» => «e.value.name»'''].join(',\n\t')»}.''')
				return 0
			}
		}

		// get first priority list and search all objects
		doTryCompleteTypeMorphism(unmatchedList, unmatchedList.firstPriorityList)
	}

	/**
	 * Recursively seek to extend the mapping to create a full morphism. Report back
	 * the smallest number of unmatched elements before breaking morphism rules
	 * found so far.
	 * 
	 * @param unmatchedList
	 *            - a list of unmatched elements
	 * @param priorityList
	 *            - a list of priority unmatched elements
	 * @return the number of unmatched elements in the model morphism
	 */
	private def int doTryCompleteTypeMorphism(List<EObject> unmatchedList, List<EObject> _priorityList) {
		// If the mapping is already not a morphism, return the number of unmatched elements
		if (!checkValidMaybeIncompleteClanMorphism(typeMapping, null)) {
			// There's already at least one element too many in the map
			return unmatchedList.size() + 1
		} else {
			// Otherwise, check if we're already done and have mapped everything
			if (unmatchedList.empty) {
				// TODO Better logging
				System.out.println('''Found TG morphism {«typeMapping.entrySet.map[ e | '''«e.key.name» => «e.value.name»'''].join(',\n\t')»}.''')
				return 0
			}
		}

		// Pick an unmatched object either from priority list or general list
		var EObject pick = null
		if (_priorityList.empty) {
			pick = unmatchedList.remove(0)
		} else {
			pick = _priorityList.remove(0)
			unmatchedList.remove(pick)
		}

		var priorityList = pick.getPriorityModelObjects(unmatchedList, _priorityList)
		// Need to add one because we don't actually know yet if this will be able to
		// make a morphism
		var int numUnmatched = unmatchedList.size() + 1

		var List<? extends EObject> possible = pick.getPossibleMatches()
		// go through all possible objects and recursively find matches for further objects
		for (EObject o : possible) {
			typeMapping.put(pick, o)
			val int numUnmatchedInDescend = doTryCompleteTypeMorphism(unmatchedList, priorityList)
			// make sure count reflects the minimum found count
			if (numUnmatchedInDescend == 0) {
				return 0
			} else {
				if (numUnmatchedInDescend < numUnmatched) {
					numUnmatched = numUnmatchedInDescend
				}
			}
		}

		typeMapping.remove(pick)
		unmatchedList.add(pick)
		return numUnmatched
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

	/**
	 * Returns a first priority list in the model. This is determined by going
	 * through the elements currently mapped already and finding new elements
	 * connected to them and not yet mapped.
	 * 
	 * @param unmatchedList
	 * @return a first priority list in the model
	 */
	private def List<EObject> getFirstPriorityList(List<EObject> unmatchedList) {
		typeMapping.keySet.fold(new ArrayList<EObject>() as List<EObject>, [ l, eo |
			eo.getPriorityModelObjects(unmatchedList, l)
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
	private def List<EObject> getPriorityModelObjects(EObject pick, List<EObject> unmatchedList,
		List<EObject> previousPriorityList) {
		val priorityList = new ArrayList(previousPriorityList)

		// if picked object is an EReference, add its target and source to the priority
		// list if they are in unmatched list
		if (pick instanceof EReference) {
			val EClass eclass1 = (pick as EReference).EReferenceType
			val EClass eclass2 = (pick as EReference).EContainingClass

			if (unmatchedList.contains(eclass1))
				priorityList.add(eclass1)
			if (unmatchedList.contains(eclass2))
				priorityList.add(eclass2)

		// if picked object is an EClass
		} else if (pick instanceof EClass) {
			// add its EReferences to the priority list if they are unmatched
			// TODO: Original code wasn't filtering for references
			pick.eContents.filter(EReference).filter[er|unmatchedList.contains(er)].forEach[er|priorityList.add(er)]

			// add its Subclasses to the priority list if they are unmatched
			allSrcModelElements.filter(EClass).filter[ec|ec.ESuperTypes.contains(pick)].filter [ ec |
				unmatchedList.contains(ec)
			].forEach[ec|priorityList.add(ec)]
		}

		priorityList
	}

	/**
	 * Return a list of elements that are not yet matched in the {@code typeMapping}.
	 * 
	 * @return a list of elements that are not yet matched in the {@code typeMapping}
	 */
	private def List<EObject> getUnmatched() {
		allSrcModelElements.filter [ eo |
			!typeMapping.containsKey(eo)
		].toList
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

	/**
	 * Find the clan of {@code clazz} in the set of model elements in
	 * {@code allModelElements}
	 * 
	 * @param clazz
	 * @param allModelElements
	 * @return a list of a clan members of {@code clazz}
	 */
	private static def List<EClass> getClan(EClass clazz, List<? extends EObject> allModelElements) {
		var clan = new ArrayList<EClass>()
		clan.add(clazz)

		clan.addAll(allModelElements.filter(EClass).filter[ec|ec.ESuperTypes.contains(clazz)].map [ ec |
			ec.getClan(allModelElements)
		].flatten)

		clan
	}
	
	private static dispatch def getName(EObject eo) ''''''
	
	private static dispatch def getName(EClass ec) { ec.name }
	
	private static dispatch def getName(EReference er) { er.name }
}
