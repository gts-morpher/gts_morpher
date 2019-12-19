package uk.ac.kcl.inf.gts_morpher.tests

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.henshin.model.HenshinPackage
import org.eclipse.emf.henshin.model.resource.HenshinResourceFactory
import org.eclipse.xtext.resource.XtextResourceSet

abstract class AbstractTest {
	@Inject
	Provider<XtextResourceSet> resourceSetProvider;
	
	protected def createResourceSet(String[] fileNames) {
		val resourceSet = resourceSetProvider.get
		resourceSet.packageRegistry.put (HenshinPackage.eINSTANCE.nsURI, HenshinPackage.eINSTANCE)
		resourceSet.resourceFactoryRegistry.extensionToFactoryMap.put("henshin", new HenshinResourceFactory())
		
		fileNames.forEach[ file | 
			resourceSet.getResource(createFileURI(file), true)
		]

		resourceSet
	}
	
	protected def createFileURI(String file) {
		URI.createFileURI(class.getResource(file).path)
	}
}