package uk.ac.kcl.inf.gts_morpher.composer.weavers

import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.ENamedElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.EcorePackage
import org.eclipse.emf.ecore.InternalEObject
import uk.ac.kcl.inf.gts_morpher.composer.helpers.MergeSet
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*

/**
 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
 * will act as a Map from source EObjects to the corresponding woven EObjects. 
 */
class TGWeaver extends HashMap<Pair<Origin, EObject>, EObject> {

	val EcorePackage ecore = EcorePackage.eINSTANCE
	val extension EcoreFactory ecoreFactory = EcoreFactory.eINSTANCE

	/**
	 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
	 */
	def EPackage weaveTG(Map<EObject, EObject> leftTGMapping, Map<EObject, EObject> rightTGMapping,
		EPackage kernelMetamodel, EPackage leftMetamodel, EPackage rightMetamodel, NamingStrategy naming) {
		val mergeSet = new ModelSpan(leftTGMapping, rightTGMapping, kernelMetamodel, leftMetamodel, rightMetamodel).
			calculateMergeSet

		val unmappedLeftElements = leftMetamodel.eAllContents.reject[eo|leftTGMapping.containsValue(eo)].toList
		val unmappedRightElements = rightMetamodel.eAllContents.reject[eo|rightTGMapping.containsValue(eo)].toList

		mergeSet.weavePackages(unmappedLeftElements, unmappedRightElements, naming)

		mergeSet.weaveClasses(unmappedLeftElements, unmappedRightElements)
		weaveInheritance
		mergeSet.weaveReferences(unmappedLeftElements, unmappedRightElements)
		mergeSet.weaveAttributes(unmappedLeftElements, unmappedRightElements)

		naming.weaveAllNames

		return get(kernelMetamodel.kernelKey) as EPackage
	}

	private def weavePackages(Set<MergeSet> mergeSets, List<EObject> unmappedLeftElements,
		List<EObject> unmappedRightElements, extension NamingStrategy naming) {
		mergeSets.filter[hasType(ecore.EPackage)].forEach [ ms |
			val keyedMergeList = ms.keyedMergeList
			// A bit annoying, but the only efficient way of getting around Java typing issues, short of spending ages on getting the generics right for ModelSpans.
			val keyedMergeEPackageList = keyedMergeList.map[kep | 
				new Pair(kep.key, kep.value as EPackage)
			].toList
			val mergedPackage = createEPackage => [
				nsPrefix = keyedMergeEPackageList.weaveNameSpaces
				nsURI = keyedMergeEPackageList.weaveURIs
			]
			// FIXME: For nested packages will need to derive better uniqueness context
			// TODO: This may not actually be needed, as we are weaving names separately anyway
			mergedPackage.name = weaveNames(#{(mergedPackage -> keyedMergeList)}, mergedPackage, emptyContext)

			keyedMergeList.forEach [ kep |
				put(kep, mergedPackage)
			]
		]

		unmappedLeftElements.filter[eClass === ecore.EPackage].forEach [ eo |
			val ep = eo as EPackage
			put(ep.leftKey, createEPackage => [
				// FIXME: This should really call on the relevant weave methods
				nsPrefix = ep.nsPrefix
				nsURI = ep.nsURI
				name = ep.name
			])
		]
	}

	private def weaveClasses(Set<MergeSet> mergeSets, List<EObject> unmappedLeftElements, List<EObject> unmappedRightElements) {
		// Weave mapped classes
		mergeSets.filter[hasType(ecore.EClass)].forEach[ms | 
			val keyedMergeList = ms.keyedMergeList
			val containingMergedPackage = get((ms.kernel.head as EClass).EPackage.kernelKey) as EPackage
			
			val mergedClass = containingMergedPackage.createEClass
			
			keyedMergeList.forEach [ kep |
				put(kep, mergedClass)
			]			
		] 

		// Create copies for all unmapped classes
		unmappedLeftElements.filter(EClass).forEach [ ec |
			put(ec.leftKey, (get(ec.EPackage.leftKey) as EPackage).createEClass)
		]
		unmappedRightElements.filter(EClass).forEach [ ec |
			put(ec.rightKey, (get(ec.EPackage.rightKey) as EPackage).createEClass)
		]
	}

	private def weaveInheritance() {
		keySet.filter[p|p.value instanceof EClass].forEach [ p |
			val composed = get(p) as EClass
			composed.ESuperTypes.addAll((p.value as EClass).ESuperTypes.map[ec2|get(ec2.origKey(p.key)) as EClass].
				reject [ ec2 |
					composed === ec2 || composed.ESuperTypes.contains(ec2)
				])
		]
	}

	private def weaveReferences(Set<MergeSet> mergeSets, List<EObject> unmappedLeftElements, List<EObject> unmappedRightElements) {
		// Weave mapped references
		// Because the mapping is a morphism, this must work :-)
		mergeSets.filter[hasType(ecore.EReference)].forEach[ms |
			val keyedMergeList = ms.keyedMergeList
			
			// FIXME: currently we're basing the reference properties apart from the name only on the first left EReference. Should probably define some proper weaving rules here 
			val mergedRef = (ms.left.head as EReference).createEReference
			
			keyedMergeList.forEach [ kep |
				put(kep, mergedRef)
			]			
		] 
	
		// Create copied for unmapped references
		unmappedLeftElements.filter(EReference).forEach [ er |
			put(er.leftKey, (er.createEReference))
		]
		unmappedRightElements.filter(EReference).forEach [ er |
			put(er.rightKey, (er.createEReference))
		]
	}

	private def weaveAttributes(Set<MergeSet> mergeSets, List<EObject> unmappedLeftElements, List<EObject> unmappedRightElements) {
		// Weave mapped attributes
		// Because the mapping is a morphism, this must work :-) 
		mergeSets.filter[hasType(ecore.EAttribute)].forEach[ms |
			val keyedMergeList = ms.keyedMergeList
			
			// FIXME: currently we're basing the attribute properties apart from the name only on the first left EAttribute. Should probably define some proper weaving rules here 
			val mergedAttr = (ms.left.head as EAttribute).createEAttribute
			
			keyedMergeList.forEach [ kep |
				put(kep, mergedAttr)
			]		
		]
		
		// Create copies for unmapped attributes
		unmappedLeftElements.filter(EAttribute).forEach [ ea |
			put(ea.leftKey, (ea.createEAttribute))
		]
		unmappedRightElements.filter(EAttribute).forEach [ ea |
			put(ea.rightKey, (ea.createEAttribute))
		]
	}

	/**
	 * Fix names of all elements produced...
	 */
	private def weaveAllNames(NamingStrategy naming) {
		// 1. Invert the weaving
		val invertedMapping = keySet.groupBy[p|get(p)]

		// 2. For every key in keyset of inversion, define the name based on names of all the sources that were merged into this
		invertedMapping.keySet.forEach [ eo |
			(eo as ENamedElement).name = naming.weaveNames(invertedMapping, eo, eo.uniquenessContext)
		]
	}

	private def createEClass(EPackage container) {
		val EClass result = EcoreFactory.eINSTANCE.createEClass
		container.EClassifiers.add(result)
		result
	}

	private def createEReference(EReference source) {
		// Origin doesn't matter in this case, but must be TARGET because we've previously decided to copy from target references
		createEReference(source, Origin.LEFT)
	}

	private def createEReference(EReference source, Origin origin) {
		val EReference result = EcoreFactory.eINSTANCE.createEReference => [
			EType = get(source.EType.origKey(origin)) as EClass
			changeable = source.changeable
			containment = source.containment
			derived = source.derived
			lowerBound = source.lowerBound
			ordered = source.ordered
			transient = source.transient
			unique = source.unique
			unsettable = source.unsettable
			upperBound = source.upperBound
			volatile = source.volatile
		]

		val opposite = get(source.EOpposite.origKey(origin)) as EReference
		if (opposite !== null) {
			result.EOpposite = opposite
			opposite.EOpposite = result
		}

		(get(source.EContainingClass.origKey(origin)) as EClass).EStructuralFeatures.add(result)

		result
	}

	private def createEAttribute(EAttribute source) {
		// Origin doesn't matter in this case, but must be LEFT because we've previously decided to copy from target references
		createEAttribute(source, Origin.LEFT)
	}

	private def createEAttribute(EAttribute source, Origin origin) {
		val EAttribute result = EcoreFactory.eINSTANCE.createEAttribute => [
			/*
			 * TODO This will work well with datatypes that are centrally shared, but not with datatypes defined in a model. However,
			 * at the moment such datatypes wouldn't pass the morphism checker code either, so this is probably safe for now.
			 */
			EType = source.EType

			changeable = source.changeable
			derived = source.derived
			lowerBound = source.lowerBound
			ordered = source.ordered
			transient = source.transient
			unique = source.unique
			unsettable = source.unsettable
			upperBound = source.upperBound
			volatile = source.volatile
		]

		(get(source.EContainingClass.origKey(origin)) as EClass).EStructuralFeatures.add(result)

		result
	}

	/**
	 * Separate map for keeping mappings established for proxies. Needs to be kept separately to avoid concurrent modifications when get transparently creates copies of proxies on demand.
	 */
	var proxyMapper = new HashMap<Pair<EObject, Origin>, InternalEObject>

	override EObject get(Object key) {
		if (key instanceof Pair) {
			if ((key.key instanceof Origin) && (key.value instanceof EObject)) {
				val result = super.get(key)

				if ((result === null) && (!(key.value instanceof EReference))) {
					val object = key.value as EObject

					if (object.eIsProxy()) {
						// Proxies wouldn't have been found when navigating the containment hierarchy, so we add them lazily as we come across them
						var proxyCopy = proxyMapper.get(key)

						if (proxyCopy === null) {
							proxyCopy = (EcoreFactory.eINSTANCE.create(object.eClass) as InternalEObject)
							proxyCopy.eSetProxyURI((object as InternalEObject).eProxyURI)
							proxyMapper.put(key, proxyCopy)
						}

						return proxyCopy
					}

					System.err.println('''Couldn't find «object» in «key.key».''')
				}

				return result
			}
		} else {
			throw new IllegalArgumentException("Requiring a pair in call to get!")
		}
	}
}
