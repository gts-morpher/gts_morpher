package uk.ac.kcl.inf.composer

import java.util.HashMap
import java.util.Iterator
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static extension uk.ac.kcl.inf.util.BasicMappingChecker.*
import static extension uk.ac.kcl.inf.util.EMFHelper.*

/**
 * Compose two xDSMLs based on the description in a resource of our language and store the result in suitable output resources.
 */
class XDsmlComposer {

	/**
	 * Perform the composition.
	 * 
	 * @param resource a resource with the morphism specification. If source is <code>interface_of</code> performs a 
	 * full pushout, otherwise assumes that interface and full language are identical for the source. Currently does 
	 * not support use of <code>interface_of</code> in the target GTS.
	 * 
	 * @param fsa used for file-system access
	 */
	def doCompose(Resource resource, IFileSystemAccess2 fsa) {
		val mapping = resource.contents.head as GTSMapping

		if (mapping.target.interface_mapping) {
			throw new UnsupportedOperationException(
				"Target GTS for a weave cannot currently be an interface_of mapping.")
		}

		// TODO Handle auto-complete and non-unique auto-completes

		val tgWeaver = new TGWeaver
		val composedTG = tgWeaver.weaveTG(mapping)
		val composedTGResource = resource.resourceSet.createResource(fsa.getURI(resource.URI.trimFileExtension.lastSegment + "_composed_tg.ecore"))
		composedTGResource.contents.clear
		composedTGResource.contents.add(composedTG)
		composedTGResource.save(emptyMap)
	}

	/**
	 * Helper class composing two TGs based on a morphism specification. Similar to EcoreUtil.Copier, the instance of this class used 
	 * will act as a Map from source EObjects to the corresponding woven EObjects. 
	 */
	static class TGWeaver extends HashMap<EObject, EObject> {
		/**
		 * Compose the two TGs, returning a mapping from old EObjects (EClass/EReference) to newly created corresponding element (if any). 
		 */
		def EPackage weaveTG(GTSMapping mapping) {
			// TODO Handle sub-packages?
			val EPackage result = EcoreFactory.eINSTANCE.createEPackage
			result.name = '''«mapping.source.metamodel.name»_«mapping.target.metamodel.name»'''
			put(mapping.source.metamodel, result)
			put(mapping.target.metamodel, result)

			val tgMapping = mapping.typeMapping.extractMapping(null)

			weaveMappedElements(tgMapping, result)
			weaveUnmappedElements(mapping, tgMapping, result)

			weaveInheritance

			return result
		}

		private def weaveMappedElements(Map<EObject, EObject> tgMapping, EPackage composedPackage) {
			tgMapping.entrySet.filter[e|e.key instanceof EClass].forEach [ e |
				val EClass composed = composedPackage.createEClass('''«e.key.name»_«e.value.name»''')

				put(e.key, composed)
				put(e.value, composed)
			]
			// Because the mapping is a morphism, this must work :-)
			tgMapping.entrySet.filter[e|e.key instanceof EReference].forEach [ e |
				val EReference composed = createEReference(e.key as EReference, '''«e.key.name»_«e.value.name»''')

				put(e.key, composed)
				put(e.value, composed)
			]

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveUnmappedElements(GTSMapping mapping, Map<EObject, EObject> tgMapping,
			EPackage composedPackage) {
			// Deal with unmapped source elements
			mapping.source.metamodel.eAllContents.reject[eo|tgMapping.containsKey(eo)].
				doWeaveUnmappedElements(composedPackage)

			// Deal with unmapped target elements
			mapping.target.metamodel.eAllContents.reject[eo|tgMapping.values.contains(eo)].
				doWeaveUnmappedElements(composedPackage)

		// TODO Also copy attributes, I guess :-)
		}

		private def weaveInheritance() {
			keySet.filter(EClass).forEach[ec |
				val composed = get(ec) as EClass
				composed.ESuperTypes.addAll(ec.ESuperTypes.map[ec2 | get(ec2) as EClass].reject[ec2 | composed.ESuperTypes.contains(ec2)])
			]
		}

		private def doWeaveUnmappedElements(Iterator<EObject> unmappedElements, EPackage composedPackage) {
			unmappedElements.filter(EClass).forEach[ec|put(ec, composedPackage.createEClass(ec.name))]
			unmappedElements.filter(EReference).forEach[er|put(er, er.createEReference(er.name))]
		}

		private def createEClass(EPackage container, String name) {
			val EClass result = EcoreFactory.eINSTANCE.createEClass
			container.EClassifiers.add(result)
			result.name = name
			result
		}

		private def createEReference(EReference source, String name) {
			val EReference result = EcoreFactory.eINSTANCE.createEReference
			result.name = name;

			(get(source.EContainingClass) as EClass).EStructuralFeatures.add(result)
			result.EType = get(source.EType) as EClass

			result
		}
	}
}
