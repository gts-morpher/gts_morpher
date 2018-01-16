/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.generator

import java.util.HashMap
import java.util.Map
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import uk.ac.kcl.inf.util.MorphismCompleter
import uk.ac.kcl.inf.util.ValueHolder
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecification
import uk.ac.kcl.inf.xDsmlCompose.RuleMapping

import static uk.ac.kcl.inf.util.BasicMappingChecker.*

import static extension uk.ac.kcl.inf.util.EMFHelper.*

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
			from �mapping.source.generate�
			to �mapping.target.generate�
			
			type_mapping {
				�mp.entrySet.filter[e | (e.key instanceof EClass) || (e.key instanceof EReference)].map[e | '''�if (e.key instanceof EClass) '''class''' else '''reference'''� �e.key.qualifiedName� => �e.value.qualifiedName�'''].join('\n')�
			}
			�generateBehaviourMapping (mp)�
		}
	'''
	
	private def generate(GTSSpecification spec) '''
		{
			metamodel: "�spec.metamodel.name�"
			�if (spec.behaviour !== null) '''behaviour: "�spec.behaviour.name�"'''�
		}
	'''
	
	private def generateBehaviourMapping (Map<? extends EObject, ? extends EObject> mp) '''
		behaviour_mapping {
			�mp.keySet.filter(Rule).map[r | r.generate(mp)].join('\n')�
		}
	'''

	private def generate (Rule r, Map<? extends EObject, ? extends EObject> mp) '''
		rule �r.qualifiedName� to �(mp.get(r) as Rule).qualifiedName� {
			� r.generateRuleElementMappings(mp) �
		}
	'''
	
	private def generateRuleElementMappings(Rule r, Map<? extends EObject, ? extends EObject> mp) {
		val preprocessedElements = mp.entrySet.filter[e | (e.key instanceof GraphElement) && (e.key.eContainer.eContainer == mp.get(r))].map[e | new Pair(e.key.name, e)]
		val uniqueElements = new ValueHolder(new HashMap<String, Pair<GraphElement, GraphElement>>())
		preprocessedElements.forEach[p | 
			uniqueElements.value.put(p.key.toString, new Pair(p.value.key, p.value.value))
		]
		uniqueElements.value.values.map[p | generateRuleElementMapping(p.key, p.value)].join('\n')
	}

	private def generateRuleElementMapping(GraphElement source, GraphElement target) {
		if (source instanceof Node) '''object �source.name� => �target.name�''' 
		else if (source instanceof Edge) '''link �source.name� => �target.name�'''
		else ''''''
	}

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
