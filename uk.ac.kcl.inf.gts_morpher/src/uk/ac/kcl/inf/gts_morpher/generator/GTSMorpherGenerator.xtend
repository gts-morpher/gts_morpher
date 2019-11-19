/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.gts_morpher.generator

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import uk.ac.kcl.inf.gts_morpher.util.IProgressMonitor
import uk.ac.kcl.inf.gts_morpher.util.Triple
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilyChoice
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSWeave

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import uk.ac.kcl.inf.gts_morpher.composer.GTSComposer
import org.eclipse.xtext.diagnostics.Severity

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class GTSMorpherGenerator extends AbstractGenerator {

	@Inject
	extension GTSComposer composer

	@Inject
	extension IResourceValidator resourceValidator

	/**
	 * Generate all composed GTSs
	 */
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		if (resource.contents.empty) {
			return
		}
		
		val monitor = IProgressMonitor.wrapCancelIndicator(context.cancelIndicator)
		val _monitor = monitor.convert(2)
		try {
			val issues = resource.validate(CheckMode.ALL, _monitor.split("Validating resource.", 1))

			// Ignore warnings etc to ensure we still save generation results in those cases
			if (issues.filter [severity === Severity.ERROR].empty) {
				val gtsModule = resource.contents.head as GTSSpecificationModule

				gtsModule.gtss.filter[gts|gts.export].map[it.gts].filter [
					it instanceof GTSWeave || it instanceof GTSFamilyChoice
				].map [ sel |
					val name = (sel.eContainer as GTSSpecification).name

					new Pair(name, if (sel instanceof GTSWeave) {
						sel.doCompose(_monitor.split("Composing", 1))
					} else if (sel instanceof GTSFamilyChoice) {
						new Triple(sel.issues, sel.metamodel, sel.behaviour)
					})
				].forEach [ p |
					val weaveResult = p.value
					val name = p.key

					if (weaveResult.a.empty) {
						if (weaveResult.b !== null) {
							weaveResult.b.saveModel(fsa, resource, name, "tg.ecore")
						}
						if (weaveResult.c !== null) {
							weaveResult.c.saveModel(fsa, resource, name, "rules.henshin")
						}
					}
				]
			}
		} catch (Exception e) {
			e.printStackTrace
		}
	}

	private def void saveModel(EObject model, IFileSystemAccess2 fsa, Resource baseResource, String gtsName,
		String fileName) {
		val composedTGResource = baseResource.resourceSet.createResource(fsa.getURI(gtsName + "/" + fileName))
		composedTGResource.contents.clear
		composedTGResource.contents.add(model)
		composedTGResource.save(emptyMap)
	}
}
