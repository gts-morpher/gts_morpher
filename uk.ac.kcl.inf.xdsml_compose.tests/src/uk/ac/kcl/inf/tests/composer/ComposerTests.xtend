package uk.ac.kcl.inf.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.junit.runner.RunWith
import uk.ac.kcl.inf.composer.XDsmlComposer
import uk.ac.kcl.inf.composer.XDsmlComposer.Issue
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.util.Triple
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecificationModule
import uk.ac.kcl.inf.xDsmlCompose.GTSWeave

import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class ComposerTests extends GeneralTestCaseDefinitions {
	@Inject
	XDsmlComposer composer

	protected override Triple<List<Issue>, EPackage, Module> doTest(GTSSpecificationModule module, String nameOfExport, ResourceSet resourceSet) {
		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		composer.doCompose(module.gtss.filter[gts | (gts.name == nameOfExport) && (gts.gts instanceof GTSWeave)].map[gts | gts.gts as GTSWeave].head,
			IProgressMonitor.NULL_IMPL)
	} 
}
