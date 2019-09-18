package uk.ac.kcl.inf.gts_morpher.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.resource.SaveOptions
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.util.IProgressMonitor

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.extractGTSMapping
import static extension uk.ac.kcl.inf.gts_morpher.util.MorphismCompleter.*

/**
 * Generator producing auto-completions for marked morphisms.
 */
class AutoCompletionGenerator {
	
	/**
	 * Generate all completions for all mappings marked as auto-complete in the given resource.
	 */
	def void doGenerate(Resource resource, IFileSystemAccess2 fsa, IProgressMonitor monitor) {
		val mappings = (resource.contents.head as GTSSpecificationModule).mappings.filter[autoComplete].toList
		
		val _monitor = monitor.split("Generating auto-completions", 1).convert(mappings.size)
		
		mappings.forEach[mapping | 
			val __monitor = _monitor.split('''Generating for mapping «mapping.name».''', 2)
			
			__monitor.split("Generating completions", 1)
			val completedMappings = mapping.completedMappings

			val ___monitor = __monitor.split("Saving completions", 1).convert(completedMappings.size)
			completedMappings.forEach[ mp, idx |
				___monitor.split("Saving completions", 1)
				
				val uri = fsa.getURI('''«resource.URI.trimFileExtension.lastSegment»_«mapping.name»_«idx».complete.gts''')
				
				var saveRes = resource.resourceSet.getResource(uri, false)
				if (saveRes === null) {
					saveRes = resource.resourceSet.createResource(uri)
				} else {
					saveRes.contents.clear
				}
				
				mp.extractGTSMapping(mapping.source, mapping.target, saveRes)
				
				saveRes.save(SaveOptions.newBuilder.format.options.toOptionsMap)
			]
		]
	}

	private static def getCompletedMappings(GTSMapping mapping) {
		val completions = mapping.getMorphismCompletions(true)
		val completer = completions.key

		if (completions.value == 0) {
			// Found morphism(s)
			completer.completedMappings
		} else {
			// We have a problem
			#[]
		}
	}}