package uk.ac.kcl.inf.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.junit.runner.RunWith
import uk.ac.kcl.inf.composer.XDsmlComposer.Issue
import uk.ac.kcl.inf.generator.XDsmlComposeGenerator
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.util.Triple
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecificationModule

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class ComposerGeneratorTests extends GeneralTestCaseDefinitions {
	@Inject
	XDsmlComposeGenerator generator

	protected override Triple<List<Issue>, EPackage, Module> doTest(GTSSpecificationModule module, String nameOfExport, ResourceSet resourceSet) {
		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		generator.doGenerate(module.eResource, new TestFileSystemAccess, [IProgressMonitor.NULL_IMPL])

		// Check contents of generated resources and compare against oracle
		val ecoreResource = resourceSet.findComposedEcore(nameOfExport)
		var EPackage ecore = null
		if (ecoreResource !== null) {
			ecore = ecoreResource.contents.head as EPackage
		}
		
		val henshinResource = resourceSet.findComposedHenshin(nameOfExport)
		var Module henshin = null
		if (henshinResource !== null) {
			henshin = henshinResource.contents.head as Module
		}
		
		new Triple (emptyList, ecore, henshin)
	} 

	private def findComposedEcore(ResourceSet resourceSet, String gtsName) {
		resourceSet.findComposed("ecore", gtsName)
	}

	private def findComposedHenshin(ResourceSet resourceSet, String gtsName) {
		resourceSet.findComposed("henshin", gtsName)
	}
	
	private def findComposed(ResourceSet resourceSet, String ext, String gtsName) {
		resourceSet.resources.filter[r|TestURIHandlerImpl.TEST_URI_SCHEME.equals(r.URI.scheme)].filter [ r |
			gtsName.equals(r.URI.segments.get(r.URI.segmentCount - 2))
		].filter [ r |
			ext.equals(r.URI.fileExtension)
		].head
	}
}
