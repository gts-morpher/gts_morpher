package uk.ac.kcl.inf.gts_morpher.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.composer.GTSComposer
import uk.ac.kcl.inf.gts_morpher.composer.GTSComposer.Issue
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSWeave
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider
import uk.ac.kcl.inf.gts_morpher.util.IProgressMonitor
import uk.ac.kcl.inf.gts_morpher.util.Triple

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class ComposerTests extends GeneralTestCaseDefinitions {
	@Inject
	GTSComposer composer

	protected override Triple<List<Issue>, EPackage, Module> doTest(GTSSpecificationModule module, String nameOfExport, ResourceSet resourceSet) {
		composer.doCompose(module.gtss.filter[gts | (gts.name == nameOfExport) && (gts.gts instanceof GTSWeave)].map[gts | gts.gts as GTSWeave].head,
			IProgressMonitor.NULL_IMPL)
	} 
}
