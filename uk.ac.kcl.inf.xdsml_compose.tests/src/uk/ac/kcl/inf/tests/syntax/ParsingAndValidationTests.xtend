/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.tests.syntax

import com.google.inject.Inject
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.validation.XDsmlComposeValidator
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.util.henshinsupport.NamingHelper.*
import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*
import uk.ac.kcl.inf.xDsmlCompose.GTSFamilyChoice
import com.google.common.collect.Iterables

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class ParsingAndValidationTests extends AbstractTest {
	@Inject
	ParseHelper<GTSMapping> parseHelper

	@Inject 
	extension ValidationTestHelper

	protected override createResourceSet(String[] files) {
		super.createResourceSet(Iterables.concat(files, #["transformers.henshin"]))
	}

	private def createNormalResourceSet() {
		#["server.ecore", "DEVSMM.ecore", "server.henshin", "devsmm.henshin"].createResourceSet
	}
	
	private def createInterfaceResourceSet() {
		#["storing_server.ecore", "DEVSMM.ecore", "storing_server.henshin", "devsmm.henshin"].createResourceSet
	}

	/**
	 * Tests basic parsing and linking for a sunshine case
	 */
	@Test
	def void parsingBasic() {	
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		assertTrue("Set to auto-complete", !result.autoComplete)

		assertNotNull("No type mapping", result.typeMapping)

		assertNotNull("Did not load source package", result.source.metamodel.name)
		assertNotNull("Did not load target package", result.target.metamodel.name)

		assertNotNull("Did not load source class", (result.typeMapping.mappings.head as ClassMapping).source.name)
		assertNotNull("Did not load target class", (result.typeMapping.mappings.head as ClassMapping).target.name)

		assertNotNull("Did not load source reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).source.name)
		assertNotNull("Did not load target reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).target.name)
	}
	
	/**
	 * Test basic parsing with auto-complete annotation.
	 */
	@Test
	def void parsingAutoComplete() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)
		
		assertTrue("Not set to auto-complete", result.autoComplete)
		assertFalse("Set to unique auto-completion", result.uniqueCompletion)
	}
	
	/**
	 * Tests basic parsing and linking with behaviour mapping
	 */
	@Test
	def void parsingBasicWithBehaviour() {	
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
					
					behaviour_mapping {
						rule devsmmRules.process to serverRules.process {
							object input => in_part
							link [in_queue->input:elts] => [tray->in_part:parts]
						}
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		assertTrue("Set to auto-complete", !result.autoComplete)

		assertNotNull("No type mapping", result.typeMapping)

		assertNotNull("Did not load source package", result.source.metamodel.name)
		assertNotNull("Did not load target package", result.target.metamodel.name)

		assertNotNull("Did not load source class", (result.typeMapping.mappings.head as ClassMapping).source.name)
		assertNotNull("Did not load target class", (result.typeMapping.mappings.head as ClassMapping).target.name)

		assertNotNull("Did not load source reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).source.name)
		assertNotNull("Did not load target reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).target.name)

		assertNotNull("Did not load source behaviour", result.source.behaviour.name)
		assertNotNull("Did not load target behaviour", result.target.behaviour.name)
		
		assertNotNull("Did not find source rule", result.behaviourMapping.mappings.get(0).source.name)
		assertNotNull("Did not find target rule", result.behaviourMapping.mappings.get(0).target.name)
		
		val ruleMap = result.behaviourMapping.mappings.get(0)
		assertNotNull ("Did not find source object", (ruleMap.element_mappings.get(0) as ObjectMapping).source.name)
		assertNotNull ("Did not find target object", (ruleMap.element_mappings.get(0) as ObjectMapping).target.name)

		assertNotNull ("Did not find source link", (ruleMap.element_mappings.get(1) as LinkMapping).source.name)
		assertNotNull ("Did not find target link", (ruleMap.element_mappings.get(1) as LinkMapping).target.name)
	}
	
	/**
	 * Tests basic parsing and linking with behaviour mapping for an interface-mapping
	 */
	@Test
	def void parsingBasicWithBehaviourAndInterface() {	
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from interface_of {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
					
					behaviour_mapping {
						rule devsmmRules.process to serverRules.process {
							object input => in_part
							link [in_queue->input:elts] => [tray->in_part:parts]
						}
					}
				}
			''',
			createInterfaceResourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		assertTrue("Set to auto-complete", !result.autoComplete)

		assertNotNull("No type mapping", result.typeMapping)

		assertNotNull("Did not load source package", result.source.metamodel.name)
		assertNotNull("Did not load target package", result.target.metamodel.name)

		assertNotNull("Did not load source class", (result.typeMapping.mappings.head as ClassMapping).source.name)
		assertNotNull("Did not load target class", (result.typeMapping.mappings.head as ClassMapping).target.name)

		assertNotNull("Did not load source reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).source.name)
		assertNotNull("Did not load target reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).target.name)

		assertNotNull("Did not load source behaviour", result.source.behaviour.name)
		assertNotNull("Did not load target behaviour", result.target.behaviour.name)
		
		assertNotNull("Did not find source rule", result.behaviourMapping.mappings.get(0).source.name)
		assertNotNull("Did not find target rule", result.behaviourMapping.mappings.get(0).target.name)
		
		val ruleMap = result.behaviourMapping.mappings.get(0)
		assertNotNull ("Did not find source object", (ruleMap.element_mappings.get(0) as ObjectMapping).source.name)
		assertNotNull ("Did not find target object", (ruleMap.element_mappings.get(0) as ObjectMapping).target.name)

		assertNotNull ("Did not find source link", (ruleMap.element_mappings.get(1) as LinkMapping).source.name)
		assertNotNull ("Did not find target link", (ruleMap.element_mappings.get(1) as LinkMapping).target.name)
	}

	/**
	 * Test basic parsing with unique auto-complete annotation.
	 */
	@Test
	def void parsingUniqueAutoComplete() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)
		
		assertTrue("Not set to auto-complete", result.autoComplete)
		assertTrue("Not set to unique auto-complete", result.uniqueCompletion)
	}

	/**
	 * Test basic parsing with a GTS family specification
	 */
	@Test
	def void parsingBasicGTSFamily() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						family: {
							metamodel: "server"
							transformers: "transformerRules"
						}
						
						using [
							addSubClass(server.Server, "Server1"),
							addSubClass(server.Server, "Server2")
						]
					}
					
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server1 => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)
		
		assertNotNull("Didn't manage to load transformers.", (result.source.gts as GTSFamilyChoice).transformers.name)
		
		assertNotNull("Didn't find transformer being invoked", (result.source.gts as GTSFamilyChoice).transformationSteps.steps.head.unit.name)
	}

	/**
	 * Tests that we get the correct error messages when a type mapping is the wrong way around
	 */
	@Test
	def void crossedMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class devsmm.Machine => server.Server 
						reference devsmm.Machine.out => server.Server.Out
					}
					
					behaviour_mapping {
						rule devsmmRules.process to serverRules.process {
							object in_part => input
							link [tray->in_part:parts] => [in_queue->input:elts]
						}
						rule serverRules.process to devsmmRules.process {
							object in_part => input
						}
					}
				}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		// Expecting validation errors as source and target are switched in the class mapping
		val issues = result.validate()

		result.assertError(XDsmlComposePackage.Literals.CLASS_MAPPING, Diagnostic.LINKING_DIAGNOSTIC)
		result.assertError(XDsmlComposePackage.Literals.REFERENCE_MAPPING, Diagnostic.LINKING_DIAGNOSTIC)

//		(result.typeMapping.mappings.get(0) as ClassMapping).assertError(XDsmlComposePackage.Literals.CLASS_MAPPING, Diagnostic.LINKING_DIAGNOSTIC)

		result.assertWarning(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)

		result.assertError(XDsmlComposePackage.Literals.OBJECT_MAPPING, Diagnostic.LINKING_DIAGNOSTIC)
		result.assertError(XDsmlComposePackage.Literals.LINK_MAPPING, Diagnostic.LINKING_DIAGNOSTIC)
		
		result.assertError(XDsmlComposePackage.Literals.RULE_MAPPING, Diagnostic.LINKING_DIAGNOSTIC)

		assertTrue(issues.length == 16)
	}
	
	/**
	 * Tests validation of GTS specifications
	 */
	@Test
	def void invalidGTSSpecification() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
						behaviour: "devsmmRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine 
					}
				}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		// Expecting validation errors as there is an invalid GTS specification
		val issues = result.validate()
		
		result.source.assertError(XDsmlComposePackage.Literals.GTS_SPECIFICATION, XDsmlComposeValidator.INVALID_BEHAVIOUR_SPEC)
		
		assertTrue("Also failed check on target GTS", issues.length == 3) // There's also an incomplete mapping warning
	}
	
	/**
	 * Tests validation against duplicate mappings
	 */
	@Test
	def void duplicateMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine 
						class server.Server => devsmm.Assemble 
						reference server.Server.In => devsmm.Machine.in 
						reference server.Server.In => devsmm.Machine.out
						reference server.Queue.elts => devsmm.Container.parts
					}
					
					behaviour_mapping {
						rule devsmmRules.process to serverRules.process {
							object server => machine
							object server => machine
							link [in_queue->input:elts] => [tray->in_part:parts]
							link [in_queue->input:elts] => [tray->in_part:parts]
						}
						rule devsmmRules.process to serverRules.process {
							object input => in_part
						}
					}
				}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		// Expecting validation errors as there are duplicate mappings
		val issues = result.validate()
		
		result.typeMapping.mappings.get(1).assertError(XDsmlComposePackage.Literals.CLASS_MAPPING, XDsmlComposeValidator.DUPLICATE_CLASS_MAPPING, "Duplicate mapping for EClassifier Server.")
		result.typeMapping.mappings.get(3).assertError(XDsmlComposePackage.Literals.REFERENCE_MAPPING, XDsmlComposeValidator.DUPLICATE_REFERENCE_MAPPING, "Duplicate mapping for EReference In.")
				
		result.behaviourMapping.mappings.get(1).assertError(XDsmlComposePackage.Literals.RULE_MAPPING, XDsmlComposeValidator.DUPLICATE_RULE_MAPPING, "Duplicate mapping for Rule process.")
		
		val ruleMapping = result.behaviourMapping.mappings.get(0)
		ruleMapping.element_mappings.get(1).assertError(XDsmlComposePackage.Literals.OBJECT_MAPPING, XDsmlComposeValidator.DUPLICATE_OBJECT_MAPPING, "Duplicate mapping for Object server.")
		ruleMapping.element_mappings.get(3).assertError(XDsmlComposePackage.Literals.LINK_MAPPING, XDsmlComposeValidator.DUPLICATE_LINK_MAPPING, "Duplicate mapping for Link [in_queue->input:elts].")

		result.assertWarning(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		
		assertTrue(issues.length == 10)
	} 
	
	/**
	 * Tests validation against mappings that aren't morphisms
	 */
	@Test
	def void nonMorphismMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						class server.Queue => devsmm.Container
						reference server.Server.Out => devsmm.Machine.out
						reference server.Server.In => devsmm.Machine.in
					}
				}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		// Expecting validation errors as there are duplicate mappings
		val issues = result.validate()
		result.typeMapping.mappings.get(2).assertError(XDsmlComposePackage.Literals.REFERENCE_MAPPING, XDsmlComposeValidator.NOT_A_CLAN_MORPHISM)
		result.typeMapping.mappings.get(3).assertError(XDsmlComposePackage.Literals.REFERENCE_MAPPING, XDsmlComposeValidator.NOT_A_CLAN_MORPHISM)
		result.assertWarning(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		assertTrue(issues.length == 3)
	}

	/**
	 * Tests validation against mappings that are behaviour morphisms
	 */
	@Test
	def void morphismBehaviourMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.Server => devsmm.GenHandle
						class server.Queue => devsmm.Conveyor
						reference server.Server.Out => devsmm.Machine.out
					}
					
					behaviour_mapping {
						rule devsmmRules.generateHandle to serverRules.produce {
							object s => g
						}
					}
				}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		val issues = result.validate()
		// Incomplete mapping errors 
		assertTrue(issues.length == 4)
	}

	/**
	 * Tests validation against mappings that are not behaviour morphisms
	 */
	@Test
	def void nonMorphismBehaviourMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.Server => devsmm.GenHandle
						class server.Queue => devsmm.Conveyor
						reference server.Server.Out => devsmm.Machine.out
					}
					
					behaviour_mapping {
						rule devsmmRules.generateHandle to serverRules.produce {
							object s => g
							object q => c
							link [s->q:Out] => [c->h:parts]
						}
					}
				}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		val issues = result.validate()
		
		result.assertError(XDsmlComposePackage.Literals.LINK_MAPPING, XDsmlComposeValidator.NOT_A_RULE_MORPHISM)
		
		// Various incomplete mapping errors 
		assertTrue(issues.length == 5)
	}

	/**
	 * Tests that auto-completion validation works in positive case
	 */
	@Test
	def void validateAutoCompletePositive() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertNoErrors(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.UNCOMPLETABLE_TYPE_GRAPH_MAPPING)
		result.assertNoWarnings(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
	}

	/**
	 * Tests that unique auto-completion validation works in negative case
	 */
	@Test
	def void validateUniqueAutoCompleteNegative() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete unique map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						class server.Queue => devsmm.Tray
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertNoErrors(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.UNCOMPLETABLE_TYPE_GRAPH_MAPPING)
		result.assertNoWarnings(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		
		result.assertError(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.NO_UNIQUE_COMPLETION)
	}

	/**
	 * Tests that auto-completion validation works in the negative case
	 */
	@Test
	def void validateAutoCompleteNegative() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				auto-complete map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
						class server.Queue => devsmm.Container
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertError(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.UNCOMPLETABLE_TYPE_GRAPH_MAPPING)
		result.assertNoWarnings(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
	}
	
	/**
	 * Tests auto-completion of behaviour morphisms
	 */
	@Test
	def void validateAutoCompleteBehaviourMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			auto-complete map {
				from {
					metamodel: "server"
					behaviour: "serverRules"
				}
				to {
					metamodel: "server"
					behaviour: "serverRules"
				}
				
				type_mapping {
					class server.Server => server.Server
					class server.Queue => server.Queue
					class server.Element => server.Element
					class server.Input => server.Input
					class server.Output => server.Output
					reference server.Server.Out => server.Server.Out
					reference server.Server.In => server.Server.In
					reference server.Queue.elts => server.Queue.elts
				}
				
				behaviour_mapping {
					rule serverRules.process to serverRules.process {
						object server => server
					}
				}
			}
			''',
			createNormalResourceSet)

		assertNotNull("Did not produce parse result", result)
		val issues = result.validate()

		// For now 
		// TODO: update with proper size
		assertTrue(issues.empty)		
		// TODO Add more meaningful tests
	}
	
	/**
	 * Tests that completeness check works correctly for complete mappings
	 */
	@Test
	def void validateCompletenessPositive() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						metamodel: "server"
					}
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Element => devsmm.Part
						class server.Queue => devsmm.Tray
						class server.Server => devsmm.Machine
						class server.Input => devsmm.Part
						class server.Output => devsmm.Part
						reference server.Server.In => devsmm.Machine.in
						reference server.Server.Out => devsmm.Machine.in
						reference server.Queue.elts => devsmm.Container.parts
					} 
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertNoWarnings(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
	}

	/**
	 * Tests that completeness check works correctly for complete mappings with behaviour mappings
	 */
	@Test
	def void validateBehaviourCompletenessPositive() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "server"
					behaviour: "serverRules"
				}
				to {
					metamodel: "server"
					behaviour: "serverRules"
				}
				
				type_mapping {
					reference server.Queue.elts => server.Queue.elts
					class server.Element => server.Element
					class server.Input => server.Input
					reference server.Server.Out => server.Server.Out
					class server.Output => server.Output
					class server.Server => server.Server
					class server.Queue => server.Queue
					reference server.Server.In => server.Server.In
				}
				behaviour_mapping {
					rule serverRules.process to serverRules.process {
						object output => output
						object server => server
						object input => input
						object out_queue => in_queue
						object in_queue => in_queue
						link [out_queue->output:elts] => [out_queue->output:elts]
						link [server->in_queue:In] => [server->in_queue:In]
						link [server->out_queue:Out] => [server->out_queue:Out]
						link [in_queue->input:elts] => [in_queue->input:elts]
					}
					
					rule serverRules.produce to serverRules.produce {
						link [q->o:elts] => [q->o:elts]
						object q => q
						object s => s
						link [s->q:Out] => [s->q:Out]
						object o => o
					}
				}
			}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertNoWarnings(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		result.assertNoIssue(XDsmlComposePackage.Literals.RULE_MAPPING, XDsmlComposeValidator.INCOMPLETE_RULE_MAPPING)		
	}

	/**
	 * Tests that completeness check works correctly for complete mappings with behaviour mappings in the presence of interface annotations
	 */
	@Test
	def void validateBehaviourWithInterfaceCompletenessPositive() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from interface_of {
					metamodel: "server"
					behaviour: "serverRules"
				}
				to {
					metamodel: "server"
					behaviour: "serverRules"
				}
				
				type_mapping {
					reference server.Queue.elts => server.Queue.elts
					class server.Element => server.Element
					class server.Input => server.Input
					reference server.Server.Out => server.Server.Out
					class server.Output => server.Output
					class server.Server => server.Server
					class server.Queue => server.Queue
					reference server.Server.In => server.Server.In
				}
				behaviour_mapping {
					rule serverRules.process to serverRules.process {
						object output => output
						object server => server
						object input => input
						object out_queue => in_queue
						object in_queue => in_queue
						link [out_queue->output:elts] => [out_queue->output:elts]
						link [server->in_queue:In] => [server->in_queue:In]
						link [server->out_queue:Out] => [server->out_queue:Out]
						link [in_queue->input:elts] => [in_queue->input:elts]
					}
				}
			}
			''',
			createInterfaceResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertNoWarnings(XDsmlComposePackage.Literals.GTS_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		result.assertNoIssue(XDsmlComposePackage.Literals.RULE_MAPPING, XDsmlComposeValidator.INCOMPLETE_RULE_MAPPING)		
	}

	/**
	 * Tests that in interface-mappings we cannot map non-interface elements
	 */
	@Test
	def void validateNonInterfaceElementMappingAttempts() {	
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from interface_of {
						metamodel: "server"
						behaviour: "serverRules"
					}
					to {
						metamodel: "devsmm"
						behaviour: "devsmmRules"
					}
					
					type_mapping {
						class server.ServerObserver => devsmm.Machine
						reference server.ServerObserver.server => devsmm.Machine.out
					}
					
					behaviour_mapping {
						rule devsmmRules.process to serverRules.process {
							object so => machine
							link [so->server:server] => [machine->conveyor:out]
						}
					}
				}
			''',
			createInterfaceResourceSet)
		assertNotNull("Did not produce parse result", result)
		
		result.assertError(XDsmlComposePackage.Literals.CLASS_MAPPING, XDsmlComposeValidator.NON_INTERFACE_CLASS_MAPPING_ATTEMPT)
		result.assertError(XDsmlComposePackage.Literals.REFERENCE_MAPPING, XDsmlComposeValidator.NON_INTERFACE_REFERENCE_MAPPING_ATTEMPT)

		result.assertError(XDsmlComposePackage.Literals.OBJECT_MAPPING, XDsmlComposeValidator.NON_INTERFACE_OBJECT_MAPPING_ATTEMPT)
		result.assertError(XDsmlComposePackage.Literals.LINK_MAPPING, XDsmlComposeValidator.NON_INTERFACE_LINK_MAPPING_ATTEMPT)
		result.assertNoError(XDsmlComposeValidator.NOT_A_RULE_MORPHISM)
	}
	
	/**
	 * Test validation of transformer rules with a GTS family specification
	 */
	@Test
	def void validateBasicGTSFamilyNegative() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						family: {
							metamodel: "server"
							transformers: "serverRules"
						}
						
						using [
							addSubClass(server.Server, "Server1"),
							addSubClass(server.Server, "Server2")
						]
					}
					
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		result.assertError(XDsmlComposePackage.Literals.GTS_FAMILY_CHOICE, XDsmlComposeValidator.INVALID_TRANSFORMER_SPECIFICATION)
	}

	/**
	 * Test validation of transformer rules with a GTS family specification
	 */
	@Test
	def void validateBasicGTSFamilyPositive() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						family: {
							metamodel: "server"
							transformers: "transformerRules"
						}
						
						using [
							addSubClass(server.Server, "Server1"),
							addSubClass(server.Server, "Server2")
						]
					}
					
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		result.assertNoError(XDsmlComposeValidator.INVALID_TRANSFORMER_SPECIFICATION)
	}

	/**
	 * Test validation of transformer unit calls with a GTS family specification
	 */
	@Test
	def void validateBasicGTSFamilyUnitCalls() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					from {
						family: {
							metamodel: "server"
							transformers: "transformerRules"
						}
						
						using [
							addSubClass("Server1"),
							addSubClass("Server2", server.Server)
						]
					}
					
					to {
						metamodel: "devsmm"
					}
					
					type_mapping {
						class server.Server => devsmm.Machine
					}
				}
			''',
			createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		result.assertNoError(XDsmlComposeValidator.INVALID_TRANSFORMER_SPECIFICATION)
		
		result.assertError(XDsmlComposePackage.Literals.UNIT_CALL, XDsmlComposeValidator.WRONG_PARAMETER_NUMBER_IN_UNIT_CALL)
		result.assertError(XDsmlComposePackage.Literals.EOBJECT_REFERENCE_PARAMETER, XDsmlComposeValidator.INVALID_UNIT_CALL_PARAMETER_TYPE)
		result.assertError(XDsmlComposePackage.Literals.STRING_PARAMETER, XDsmlComposeValidator.INVALID_UNIT_CALL_PARAMETER_TYPE)
	}
}