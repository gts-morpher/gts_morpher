package uk.ac.kcl.inf.tests.completion

import com.google.inject.Inject
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.util.MorphismCompleter.createMorphismCompleter

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class MorphismCompleterTests extends AbstractTest{
	@Inject
	ParseHelper<GTSMapping> parseHelper
	
	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"B.ecore",
			"A.henshin",
			"B.henshin",
			"A2.henshin",
			"B2.henshin",
			"A3.henshin",
			"B3.henshin",
			"BUniqueComplete.henshin",
			"B2UniqueComplete.henshin",
			"B3UniqueComplete.henshin",
			"pls.ecore",
			"server.ecore",
			"pls.henshin",
			"server.henshin",
			"transformers.henshin"
		].createResourceSet
	}
	
	/**
	 * Tests that auto-completion with behaviour works where there are multiple possible completions for the create nodes in the behaviour.
	 */
	@Test
	def void completeMultipleWithCreate() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "A"
						behaviour: "ARules"
					}
					
					to {
						metamodel: "B"
						behaviour: "BRules"
					}
					
					type_mapping {
						class A.A1 => B.B1
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
	
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find two completions", completer.completedMappings.size == 2)
		
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Tests that auto-completion with behaviour works where there are multiple possible completions for the preserve nodes in the behaviour.
	 */
	@Test
	def void completeMultipleWithPreserve() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "A"
						behaviour: "A2Rules"
					}
					
					to {
						metamodel: "B"
						behaviour: "B2Rules"
					}
					
					type_mapping {
						class A.A1 => B.B1
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
	
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find two completions", completer.completedMappings.size == 2)
		
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Tests that auto-completion with behaviour works where there are multiple possible completions for the delete nodes in the behaviour.
	 */
	@Test
	def void completeMultipleWithDelete() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "A"
						behaviour: "A3Rules"
					}
					
					to {
						metamodel: "B"
						behaviour: "B3Rules"
					}
					
					type_mapping {
						class A.A1 => B.B1
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
	
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find two completions", completer.completedMappings.size == 2)
		
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Tests that unique auto-completion works with behaviour present and create nodes.
	 * 
	 * This is an interesting case because there are multiple type-graph mappings, but only one of them remains 
	 * a valid completion when considering the possible behaviour mappings.
	 */
	@Test
	def void completeUniqueWithCreate() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "A"
						behaviour: "ARules"
					}
					
					to {
						metamodel: "B"
						behaviour: "BRulesUniqueComplete"
					}
					
					type_mapping {
						class A.A1 => B.B1
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}
	
	/**
	 * Tests that unique auto-completion works with behaviour present and preserve nodes.
	 * 
	 * This is an interesting case because there are multiple type-graph mappings, but only one of them remains 
	 * a valid completion when considering the possible behaviour mappings.
	 */
	@Test
	def void completeUniqueWithPreserve() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "A"
						behaviour: "A2Rules"
					}
					
					to {
						metamodel: "B"
						behaviour: "B2RulesUniqueComplete"
					}
					
					type_mapping {
						class A.A1 => B.B1
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}
	
	/**
	 * Tests that unique auto-completion works with behaviour present and delete nodes.
	 * 
	 * This is an interesting case because there are multiple type-graph mappings, but only one of them remains 
	 * a valid completion when considering the possible behaviour mappings.
	 */
	@Test
	def void completeUniqueWithDelete() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "A"
						behaviour: "A3Rules"
					}
					
					to {
						metamodel: "B"
						behaviour: "B3RulesUniqueComplete"
					}
					
					type_mapping {
						class A.A1 => B.B1
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}
	
	/**
	 * Tests a strange case where completion used to produce weird results.
	 */
	@Test
	def void testWeirdCase() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique 
				map {
					from interface_of {
						family: {
							metamodel: "server"
							behaviour: "serverRules"
							transformers: "transformerRules"
						}
						
						using [
							addSubClass(server.Queue, "InputQueue"),
							addSubClass(server.Queue, "OutputQueue"),
							reTypeToSubClass(serverRules.process, server.Queue, server.InputQueue, "iq"),
							reTypeToSubClass(serverRules.process, server.Queue, server.OutputQueue, "oq"),
							mvAssocDown(server.Server.in, server.InputQueue),
							mvAssocDown(server.Server.out, server.OutputQueue)
						] 
					}
					
					to {
						metamodel: "pls"
						behaviour: "plsRules"
					}
					
					type_mapping {
				//		class server.Server => pls.Polisher
						class server.Queue => pls.Container
						class server.InputQueue => pls.Tray
						class server.OutputQueue => pls.Conveyor
						reference server.Server.in => pls.Machine.in
						reference server.Server.out => pls.Machine.out
						reference server.Queue.elts => pls.Container.parts
				//		class server.Input => pls.Part
				//		class server.Output => pls.Part
				//		class server.Element => pls.Part
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		val completer = result.createMorphismCompleter
		val numUncompleted = completer.findMorphismCompletions(true)	

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	private def isUniqueSetOfMappings(List<Map<? extends EObject, ? extends EObject>> mappings) {
		mappings.forall[m | 
			mappings.forall[m2 |
				(m === m2) ||
				(m.keySet.exists[eo | m.get(eo) != m2.get(eo)])
			]
		]
	}
}