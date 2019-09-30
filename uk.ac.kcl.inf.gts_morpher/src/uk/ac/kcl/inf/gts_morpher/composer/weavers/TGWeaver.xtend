package uk.ac.kcl.inf.gts_morpher.composer.weavers

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.function.Function
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.ENamedElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.InternalEObject
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*

/**
 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
 * will act as a Map from source EObjects to the corresponding woven EObjects. 
 */
class TGWeaver extends HashMap<Pair<Origin, EObject>, EObject> {
	/**
	 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
	 */
	def EPackage weaveTG(Map<EObject, EObject> tgMapping, EPackage srcPackage, EPackage tgtPackage,
		extension NamingStrategy naming) {
		// TODO Handle sub-packages?
		val EPackage result = EcoreFactory.eINSTANCE.createEPackage => [
			nsPrefix = weaveNameSpaces(#[srcPackage.sourceKey, tgtPackage.targetKey])
			nsURI = weaveURIs(srcPackage, tgtPackage)
		]
		result.name = weaveNames(#{(result -> #[srcPackage.sourceKey, tgtPackage.targetKey])}, result, emptyContext)

		put(srcPackage.sourceKey, result)
		put(tgtPackage.targetKey, result)

		val invertedIndex = tgMapping.invertedIndex
		val unmappedSrcElements = srcPackage.eAllContents.reject[eo|tgMapping.containsKey(eo)].toList
		val unmappedTgtElements = tgtPackage.eAllContents.reject[eo|tgMapping.values.contains(eo)].toList
		weaveClasses(invertedIndex, unmappedSrcElements, unmappedTgtElements, result)
		weaveInheritance
		weaveReferences(invertedIndex, unmappedSrcElements, unmappedTgtElements)
		weaveAttributes(invertedIndex, unmappedSrcElements, unmappedTgtElements)

		naming.weaveAllNames

		return result
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

	private def invertedIndex(Map<EObject, EObject> tgMapping) {
		// Build inverted index so that we can merge objects as required
		val invertedIndex = new HashMap<EObject, List<EObject>>()
		tgMapping.forEach [ k, v |
			invertedIndex.putIfAbsent(v, new ArrayList<EObject>)
			invertedIndex.get(v).add(k)
		]
		invertedIndex
	}

	private def weaveClasses(Map<EObject, List<EObject>> invertedIndex, List<EObject> unmappedSrcElements,
		List<EObject> unmappedTgtElements, EPackage composedPackage) {
		// Weave from inverted index for mapped classes 
		invertedIndex.entrySet.filter[e|e.key instanceof EClass].forEach [ e |
			val EClass composed = composedPackage.createEClass

			put(e.key.targetKey, composed)
			e.value.forEach[eo|put(eo.sourceKey, composed)]
		]

		// Create copies for all unmapped classes
		composedPackage.createForEachEClass(unmappedSrcElements, Origin.SOURCE)
		composedPackage.createForEachEClass(unmappedTgtElements, Origin.TARGET)
	}

	private def weaveReferences(Map<EObject, List<EObject>> invertedIndex, List<EObject> unmappedSrcElements,
		List<EObject> unmappedTgtElements) {
		// Weave mapped references
		// Because the mapping is a morphism, this must work :-)
		invertedIndex.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
			val EReference composed = createEReference(e.key as EReference)

			put(e.key.targetKey, composed)
			e.value.forEach[eo|put(eo.sourceKey, composed)]
		]

		// Create copied for unmapped references
		unmappedSrcElements.createForEachEReference(Origin.SOURCE)
		unmappedTgtElements.createForEachEReference(Origin.TARGET)
	}

	private def weaveAttributes(Map<EObject, List<EObject>> invertedIndex, List<EObject> unmappedSrcElements,
		List<EObject> unmappedTgtElements) {
		// Weave mapped attributes
		// Because the mapping is a morphism, this must work :-)
		invertedIndex.entrySet.filter[e|e.key instanceof EAttribute].forEach [ e |
			val EAttribute composed = createEAttribute(e.key as EAttribute)

			put(e.key.targetKey, composed)
			e.value.forEach[eo|put(eo.sourceKey, composed)]
		]

		// Create copies for unmapped attributes
		unmappedSrcElements.createForEachEAttribute(Origin.SOURCE)
		unmappedTgtElements.createForEachEAttribute(Origin.TARGET)
	}

	private def createForEachEClass(EPackage composedPackage, List<EObject> elements, Origin origin) {
		elements.createForEach(EClass, origin, [eo|composedPackage.createEClass])
	}

	private def createForEachEReference(List<EObject> elements, Origin origin) {
		elements.createForEach(EReference, origin, [er|er.createEReference(origin)])
	}

	private def createForEachEAttribute(List<EObject> elements, Origin origin) {
		elements.createForEach(EAttribute, origin, [ea|ea.createEAttribute(origin)])
	}

	private def <T extends ENamedElement> createForEach(List<EObject> elements, Class<T> clazz, Origin origin,
		Function<T, T> creator) {
		elements.filter(clazz).forEach [ eo |
			put(eo.origKey(origin), creator.apply(eo))
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

	private def createEClass(EPackage container) {
		val EClass result = EcoreFactory.eINSTANCE.createEClass
		container.EClassifiers.add(result)
		result
	}

	private def createEReference(EReference source) {
		// Origin doesn't matter in this case, but must be TARGET because we've previously decided to copy from target references
		createEReference(source, Origin.TARGET)
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
		// Origin doesn't matter in this case, but must be TARGET because we've previously decided to copy from target references
		createEAttribute(source, Origin.TARGET)
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
