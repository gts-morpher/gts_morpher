package uk.ac.kcl.inf.gts_morpher.tests.completion

import com.google.inject.Inject
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MorphismCompleter.*
import org.eclipse.emf.henshin.model.Parameter

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class MorphismCompleterTests extends AbstractTest {
	@Inject
	ParseHelper<GTSSpecificationModule> parseHelper

	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"B.ecore",
			"A4.ecore",
			"A5.ecore",
			"B4.ecore",
			"A.henshin",
			"B.henshin",
			"A2.henshin",
			"B2.henshin",
			"A3.henshin",
			"B3.henshin",
			"A4.henshin",
			"B4.henshin",
			"A5.henshin",
			"B5.henshin",
			"BUniqueComplete.henshin",
			"B2UniqueComplete.henshin",
			"B3UniqueComplete.henshin",
			"C.ecore",
			"D.ecore",
			"E.ecore",
			"F.ecore",
			"I.ecore",
			"J.ecore",
			"E.henshin",
			"F.henshin",
			"I.henshin",
			"J.henshin",
			"K.henshin",
			"K2.henshin",
			"K.ecore",
			"L.ecore",
			"L.henshin",
			"pls.ecore",
			"server.ecore",
			"server2.ecore",
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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		
		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find two completions", completer.completedMappings.size == 2)

		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Tests that auto-completion with behaviour works where there are multiple possible completions for the create nodes in the behaviour and a GTS reference.
	 */
	@Test
	def void completeMultipleWithCreateAndGTSReference() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			gts A {
				metamodel: "A"
				behaviour: "ARules"
			}

			auto-complete unique map {
				from A
				
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
				
				type_mapping {
					class A.A1 => B.B1
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find two completions", completer.completedMappings.size == 2)

		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Ensure parameter mappings are consistent with attribute mappings
	 */
	@Test
	def void completeMultipleParameterMorphism() {
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "A4"
					behaviour: "A4Rules"
				}
				
				to {
					metamodel: "B4"
					behaviour: "B4Rules"
				}
				
				type_mapping {
					class A4.A1 => B4.B1
					attribute A4.A1.numA => B4.B1.numB
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find exactly two completions", completer.completedMappings.size == 2)

		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		
		assertTrue("Expected to see completions include parameter mappings", completer.completedMappings.forall[keySet.exists[it instanceof Parameter]])
	}

	/**
	 * Auto-complete parameter mappings where there's an interface_of statement
	 */
	@Test
	def void completeMultipleParameterMorphismWithInterfaceOf() {
		val result = parseHelper.parse('''
			map {
				from interface_of {
					metamodel: "A5"
					behaviour: "A5Rules"
				}
				
				to {
					metamodel: "B4"
					behaviour: "B5Rules"
				}
				
				type_mapping {
					class A5.A1 => B4.B1
					attribute A5.A1.numA => B4.B1.numB
				}
				
				behaviour_mapping {
					rule test to test {
«««						param a2 => b1
«««						param numberA2 => numberB
«««						object a1 => b1
«««						slot a1.numA => b1.numB
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)

//		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		
		assertTrue("Expected to see completions include parameter mappings", completer.completedMappings.forall[keySet.exists[it instanceof Parameter]])
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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests that auto-completion with behaviour works where there are multiple possible completions for the create nodes in the behaviour and a GTS reference.
	 */
	@Test
	def void completeUniqueInclusion() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			gts B {
				metamodel: "B"
				behaviour: "BRules"
			}

			auto-complete unique inclusion map {
				from B
				
				to B
				
				type_mapping { }
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected to find 1 completion", completer.completedMappings.size == 1)
		
		assertTrue("Didn't complete type mapping", completer.completedTypeMapping)
		
		completer.completedMappings.head.forEach[k, v |
			assertSame("Completed mapping was not an inclusion", k, v)
		]
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
						{
							metamodel: "server"
							behaviour: "serverRules"
						}
						
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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests a strange case where completion used to produce weird results.
	 */
	@Test
	def void testWeirdCaseTGOnly() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique 
			map {
				from interface_of {
					family: {
						{
							metamodel: "server"
						}
						
						transformers: "transformerRules"
					}
					
					using [
						addSubClass(server.Queue, "InputQueue"),
						addSubClass(server.Queue, "OutputQueue"),
						mvAssocDown(server.Server.in, server.InputQueue),
						mvAssocDown(server.Server.out, server.OutputQueue)
					] 
				}
				
				to {
					metamodel: "pls"
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
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Tests a strange case where completion used to produce weird results.
	 */
	@Test
	def void testWeirdCaseTGOnlyNoFamily() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique 
			map {
				from interface_of {
					metamodel: "server2"
				}
				
				to {
					metamodel: "pls"
				}
				
				type_mapping {
			//		class server2.Server => pls.Polisher
					class server2.Queue => pls.Container
					class server2.InputQueue => pls.Tray
					class server2.OutputQueue => pls.Conveyor
					reference server2.Server.in => pls.Machine.in
					reference server2.Server.out => pls.Machine.out
					reference server2.Queue.elts => pls.Container.parts
			//		class server2.Input => pls.Part
			//		class server2.Output => pls.Part
			//		class server2.Element => pls.Part
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
	}

	/**
	 * Tests a strange case where completion used to produce weird results.
	 */
	@Test
	def void testWeirdCaseMinimised() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique 
			map {
				from {
					metamodel: "c"
				}
				
				to {
					metamodel: "d"
				}
				
				type_mapping {
			//		class c.C1 => d.D1
			//		class c.C2 => d.D2
			//		class c.C3 => d.D3
					reference c.C1.c2 => d.D1.d2
					reference c.C1.c3 => d.D1.d3
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests completion including attribute mappings.
	 */
	@Test
	def void testCompletionOfAttributeMappings() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique map {
				from {
					metamodel: "E"
				}
				
				to {
					metamodel: "F"
				}
				
				type_mapping {
					class E.E1 => F.F1
			//      attribute E.E1.a1 => F.F1.a1
			//      attribute E.E1.a2 => F.F1.a2
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests completion including attribute mappings.
	 */
	@Test
	def void testCompletionOfAttributeMappingsNonUnique() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique map {
				from {
					metamodel: "E"
				}
				
				to {
					metamodel: "F"
				}
				
				type_mapping {
					class E.E1 => F.F2
			//      attribute E.E1.a1 => F.F1.a1 (or F.F2.a3)
			//      attribute E.E1.a2 => F.F1.a2
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 2)
	}

	/**
	 * Tests completion including attribute and slot mappings. This is the same test as {@link #testCompletionOfAttributeMappingsNonUnique}, but the slot mappings actually make it unique.
	 */
	@Test
	def void testCompletionOfAttributeMappingsNonUniqueWithUniqueSlots() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique map {
				from {
					metamodel: "E"
					behaviour: "ERules"
				}
				
				to {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				type_mapping {
					class E.E1 => F.F2
			//      attribute E.E1.a1 => F.F1.a1 ( but no longer F.F2.a3 because that's prevented by the rule morphism)
			//      attribute E.E1.a2 => F.F1.a2
				}
				
				//behaviour_mapping {
				//	rule do to do {
				//		object e1 => f2
				//	}
				//}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests completion including attribute and slot mappings. This is the same test as {@link #testCompletionOfAttributeMappingsNonUnique}, but the slot mappings actually make it unique.
	 */
	@Test
	def void testCompletionOfAttributeMappingsNonUniqueWithUniqueSlotsAndEmptyRuleMap() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique map {
				from {
					metamodel: "E"
					behaviour: "ERules"
				}
				
				to {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				type_mapping {
					class E.E1 => F.F2
			//      attribute E.E1.a1 => F.F1.a1 ( but no longer F.F2.a3 because that's prevented by the rule morphism)
			//      attribute E.E1.a2 => F.F1.a2
				}
				
				behaviour_mapping {
					rule do to do {
				//		object e1 => f2
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests completion including attribute and slot mappings. This is the same test as {@link #testCompletionOfAttributeMappingsNonUnique}, but the slot mappings actually make it unique.
	 */
	@Test
	def void testCompletionOfAttributeMappingsNonUniqueWithUniqueSlotsRuleAlreadyMapped() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete unique map {
				from {
					metamodel: "E"
					behaviour: "ERules"
				}
				
				to {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				type_mapping {
					class E.E1 => F.F2
			//      attribute E.E1.a1 => F.F1.a1 ( but no longer F.F2.a3 because that's prevented by the rule morphism)
			//      attribute E.E1.a2 => F.F1.a2
				}
				
				behaviour_mapping {
					rule do to do {
						object e1 => f2
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	/**
	 * Tests completion including attribute and slot mappings. This is the same test as {@link #testCompletionOfAttributeMappingsNonUnique}, but the slot mappings actually make it unique.
	 */
	@Test
	def void testCompletionOfAttributeMappingsUniqueWithSlotsFromInterface() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete map {
				from interface_of {
					metamodel: "I"
					behaviour: "IRules"
				}
				
				to {
					metamodel: "J"
					behaviour: "JRules"
				}
				
				type_mapping {
					class I.I1 => J.J1
					attribute I.I1.a1 => J.J1.a1
			//		attribute I.I1.a2 => J.J1.a2
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)

		assertTrue("Expected to find slots mapped in the completion",
			completer.completedMappings.head.keySet.filter(Attribute).size > 0)
	}

	@Test
	def testGTSMorphismFromEmptyRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			auto-complete map {
				from interface_of {
					metamodel: "K"
				}
				
				to {
					metamodel: "L"
					behaviour: "LRules"
				}
				
				type_mapping {
					//class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				behaviour_mapping {
					rule empty to fiddleSticks
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	@Test
	def testGTSMorphismToVirtualRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			auto-complete map {
				from interface_of {
					metamodel: "K"
					behaviour: "KRules"
				}
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					//class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				behaviour_mapping {
					rule init to virtual
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	@Test
	def testGTSMorphismToIdentityRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			auto-complete map {
				from interface_of {
					metamodel: "K"
					behaviour: "KRules"
				}
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					//class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				behaviour_mapping {
					rule init to virtual identity
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	@Test
	def testGTSMorphismNeedsFromEmptyRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			auto-complete allow-from-empty map {
				from interface_of {
					metamodel: "K"
				}
				
				to {
					metamodel: "L"
					behaviour: "LRules"
				}
				
				type_mapping {
					//class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				//behaviour_mapping {
				//	rule empty to fiddleSticks
				//}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)
	}

	@Test
	def testGTSMorphismNeedsToVirtualRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			auto-complete map {
				from interface_of {
					metamodel: "K"
					behaviour: "K2Rules"
				}
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					//class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				//behaviour_mapping {
					//rule init to virtual
				//}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)

		val initRule = result.mappings.head.source.behaviour.units.head
		assertTrue("Expected to find mapping for init rule", completer.completedMappings.head.values.contains(initRule))
		val virtualInitRule = completer.completedMappings.head.keySet.findFirst [ eo |
			completer.completedMappings.head.get(eo) === initRule
		] as Rule
		assertTrue("Expected init rule to be mapped to virtual rule", (virtualInitRule).isVirtualRule)
		assertFalse("Expected init rule not to be mapped to virtual identity rule",
			(virtualInitRule).isVirtualIdentityRule)
	}

	@Test
	def testGTSMorphismNeedsToIdentityRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			auto-complete map {
				from interface_of {
					metamodel: "K"
					behaviour: "KRules"
				}
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					//class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				//behaviour_mapping {
					//rule init to virtual identity
				//}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val completions = result.mappings.head.getMorphismCompletions(true)
		val completer = completions.key
		val numUncompleted = completions.value

		assertTrue("Couldn't autocomplete", numUncompleted == 0)
		assertTrue("Expected mappings to be unique", completer.completedMappings.isUniqueSetOfMappings)
		assertTrue("Expected to find exactly one completion", completer.completedMappings.size == 1)

		val initRule = result.mappings.head.source.behaviour.units.head
		assertTrue("Expected to find mapping for init rule", completer.completedMappings.head.values.contains(initRule))
		assertTrue("Expected init rule to be mapped to virtual identity",
			(completer.completedMappings.head.keySet.
				findFirst[eo|completer.completedMappings.head.get(eo) === initRule] as Rule).isVirtualIdentityRule)
	}

	private def isUniqueSetOfMappings(List<Map<EObject, EObject>> mappings) {
		mappings.forall [ m |
			mappings.forall [ m2 |
				(m === m2) || (m.keySet.exists[eo|m.get(eo) != m2.get(eo)])
			]
		]
	}
}
