package uk.ac.kcl.inf.gts_morpher.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.composer.GTSComposer.Issue
import uk.ac.kcl.inf.gts_morpher.generator.GTSMorpherGenerator
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider
import uk.ac.kcl.inf.gts_morpher.tests.TestFileSystemAccess
import uk.ac.kcl.inf.gts_morpher.tests.TestURIHandlerImpl
import uk.ac.kcl.inf.gts_morpher.util.IProgressMonitor
import uk.ac.kcl.inf.gts_morpher.util.Triple

import static extension uk.ac.kcl.inf.gts_morpher.tests.TestResourceHandling.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class ComposerGeneratorTests extends GeneralTestCaseDefinitions {
	@Inject
	GTSMorpherGenerator generator

	override protected createResourceSet(String[] fileNames) {
		val rs = super.createResourceSet(fileNames)

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)

		rs
	}

	protected override Triple<List<Issue>, EPackage, Module> doTest(GTSSpecificationModule module, String nameOfExport,
		ResourceSet resourceSet) {
		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		generator.doGenerate(module.eResource, new TestFileSystemAccess, [IProgressMonitor.NULL_IMPL])

		// Extract contents 
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

		new Triple(emptyList, ecore, henshin)
	}
}
