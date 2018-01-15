/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.generator

import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import uk.ac.kcl.inf.util.ValueHolder
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static uk.ac.kcl.inf.util.BasicMappingChecker.*
import static extension uk.ac.kcl.inf.util.EMFHelper.*
import uk.ac.kcl.inf.util.MorphismCompleter

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class XDsmlComposeGenerator extends AbstractGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val mapping = resource.allContents.head as GTSMapping
		if (mapping.autoComplete) {
			val completedMappings = mapping.completedMappings
			val idx = new ValueHolder<Integer>(0)
						
			completedMappings.forEach [mp |
				fsa.generateFile(resource.URI.trimFileExtension.lastSegment + idx.value + '.complete.lang_compose',
					mapping.generateCompleteMorphism(mp))
				idx.value = idx.value + 1
			]
		}
	}

	/**
	 * Assume mapping has the autocomplete option set and generate a new representation of the mapping where all source elements have been mapped
	 */
	private def generateCompleteMorphism(GTSMapping mapping, Map<? extends EObject, ? extends EObject> mp) '''
		map {
			from {
				metamodel: "�mapping.source.metamodel.name�"
			}
			to {
				metamodel: "�mapping.target.metamodel.name�"
			}
			
			type_mapping {
				�mp.entrySet.map[e | '''�if (e.key instanceof EClass) '''class''' else '''reference'''� �e.key.qualifiedName� => �e.value.qualifiedName�'''].join('\n')�
			}
		}
	'''

	private static def getCompletedMappings(GTSMapping mapping) {
		val _typeMapping = extractMapping(mapping.typeMapping, null)
		val _behaviourMapping = extractMapping(mapping.behaviourMapping, null)
				
		val completer = new MorphismCompleter(_typeMapping, mapping.source.metamodel, mapping.target.metamodel, 
			                                  _behaviourMapping, mapping.source.behaviour, mapping.target.behaviour)
		if (completer.findMorphismCompletions(true) == 0) {
			// Found morphism(s)
			completer.completedMappings
		} else {
			// We have a problem
			#[]
		}
	}
}
