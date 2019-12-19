package uk.ac.kcl.inf.gts_morpher.composer.weavers

import java.util.HashMap
import java.util.Map
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.ENamedElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.EcorePackage
import org.eclipse.emf.ecore.InternalEObject
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import uk.ac.kcl.inf.gts_morpher.composer.helpers.NamingStrategy
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin

import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.*
import static extension uk.ac.kcl.inf.gts_morpher.composer.helpers.UniquenessContext.*
import static uk.ac.kcl.inf.gts_morpher.composer.helpers.ContentsEnumerators.*

/**
 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
 * will act as a Map from source EObjects to the corresponding woven EObjects. 
 */
class TGWeaver extends AbstractWeaver {

	val EcorePackage ecore = EcorePackage.eINSTANCE

	val NamingStrategy naming
	val EPackage kernelMetamodel

	new(Map<EObject, EObject> leftTGMapping, Map<EObject, EObject> rightTGMapping, EPackage kernelMetamodel,
		EPackage leftMetamodel, EPackage rightMetamodel, NamingStrategy naming, boolean kernelIsInterface) {
		super(new ModelSpan(leftTGMapping, rightTGMapping, kernelMetamodel, leftMetamodel, rightMetamodel,
							packageEnumerator(kernelIsInterface)).
			calculateMergeSet, leftMetamodel.eAllContents.reject[eo|leftTGMapping.containsValue(eo)].toList,
			rightMetamodel.eAllContents.reject[eo|rightTGMapping.containsValue(eo)].toList)
		this.naming = naming
		this.kernelMetamodel = kernelMetamodel
	}

	/**
	 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
	 */
	def EPackage weaveTG() {
		naming.weavePackages

		weaveClasses
		weaveInheritance
		weaveReferences
		weaveAttributes

		naming.weaveAllNames

		return get(kernelMetamodel.kernelKey) as EPackage
	}

	private def weavePackages(extension NamingStrategy naming) {

		doWeave(EPackage, ecore.EPackage, [ ep, keyedMergeList |
			// A bit annoying, but the only efficient way of getting around Java typing issues, short of spending ages on getting the generics right for ModelSpans.
			val keyedMergeEPackageList = keyedMergeList.map [ kep |
				new Pair(kep.key, kep.value as EPackage)
			].toList
			val mergedPackage = EcoreFactory.eINSTANCE.createEPackage => [
				nsPrefix = keyedMergeEPackageList.weaveNameSpaces
				nsURI = keyedMergeEPackageList.weaveURIs
			]
			// FIXME: For nested packages will need to derive better uniqueness context
			// TODO: This may not actually be needed, as we are weaving names separately anyway
			mergedPackage.name = weaveNames(#{(mergedPackage -> keyedMergeList)}, mergedPackage, mergedPackage.uniquenessContext)

			mergedPackage
		], [ ep, o |
			EcoreFactory.eINSTANCE.createEPackage => [
				// FIXME: This should really call on the relevant weave methods
				nsPrefix = ep.nsPrefix
				nsURI = ep.nsURI
				name = ep.name
			]
		])
	}

	private def weaveClasses() {
		doWeave(EClass, ecore.EClass, [ ec, keyedMergeList |
			(get(ec.EPackage.kernelKey) as EPackage).createEClass
		], [ ec, o |
			(get(ec.EPackage.origKey(o)) as EPackage).createEClass
		])
	}

	private def weaveInheritance() {
		keySet.filter[p|p.value instanceof EClass].forEach [ p |
			val composed = get(p) as EClass
			composed.ESuperTypes.addAll((p.value as EClass).ESuperTypes.map[ec2|get(ec2.origKey(p.key)) as EClass].
				filterNull. // Need to filter because some of those classes might have been unmapped as they weren't annotated with @Interface
				reject [ ec2 |
					composed === ec2 || composed.ESuperTypes.contains(ec2)
				])
		]
	}

	private def weaveReferences() {
		// Because the mapping is a morphism, this must work :-)
		doWeave(EReference, ecore.EReference, [ er, keyedMergeList |
			// FIXME: currently we're basing the reference properties apart from the name only on the first left EReference. Should probably define some proper weaving rules here 
			er.createEReference
		], [ er, o |
			er.createEReference(o)
		])
	}

	private def weaveAttributes() {
		// Because the mapping is a morphism, this must work :-)
		doWeave(EAttribute, ecore.EAttribute, [ ea, keyedMergeList |
			// FIXME: currently we're basing the reference properties apart from the name only on the first left EReference. Should probably define some proper weaving rules here 
			ea.createEAttribute
		], [ ea, o |
			ea.createEAttribute(o)
		])
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
	var proxyMapper = new HashMap<Pair<Origin, EObject>, InternalEObject>

	override EObject get(Object key) {
		val result = super.get(key)
		val kkey = key as Pair<Origin, EObject> // guaranteed by super.get
		if ((result === null) && (!((kkey.value === null) || (kkey.value instanceof EReference)))) {
			val object = kkey.value as EObject

			if (object.eIsProxy()) {
				// Proxies wouldn't have been found when navigating the containment hierarchy, so we add them lazily as we come across them
				var proxyCopy = proxyMapper.get(key)

				if (proxyCopy === null) {
					proxyCopy = (EcoreFactory.eINSTANCE.create(object.eClass) as InternalEObject)
					proxyCopy.eSetProxyURI((object as InternalEObject).eProxyURI)
					proxyMapper.put(kkey, proxyCopy)
				}

				return proxyCopy
			}

			System.err.println('''Couldn't find «object» in «kkey.key».''')
		}

		return result
	}
}
