/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.tests

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.henshin.model.HenshinPackage
import org.eclipse.emf.henshin.model.resource.HenshinResourceFactory
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.validation.XDsmlComposeValidator
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.util.henshinsupport.NamingHelper.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class XDsmlComposeParsingAndValidationTests {
	@Inject
	ParseHelper<GTSMapping> parseHelper

	@Inject 
	extension ValidationTestHelper
	
	@Inject
	private Provider<XtextResourceSet> resourceSetProvider;
	
	private def createResourceSet() {
		val resourceSet = resourceSetProvider.get
		resourceSet.packageRegistry.put (HenshinPackage.eINSTANCE.nsURI, HenshinPackage.eINSTANCE)
		resourceSet.resourceFactoryRegistry.extensionToFactoryMap.put("henshin", new HenshinResourceFactory())
		
		#["server.ecore", "DEVSMM.ecore", "server.henshin", "devsmm.henshin"].forEach[ file | 
			val fileURI = URI.createFileURI(XDsmlComposeParsingAndValidationTests.getResource(file).path)
			resourceSet.getResource(fileURI, true)
		]

		resourceSet
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
			createResourceSet)
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
			createResourceSet)
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
			createResourceSet)
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
			createResourceSet)
		assertNotNull("Did not produce parse result", result)		
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)
		
		assertTrue("Not set to auto-complete", result.autoComplete)
		assertTrue("Not set to unique auto-complete", result.uniqueCompletion)
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
			createResourceSet)

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
			createResourceSet)

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
			createResourceSet)

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
			createResourceSet)

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
			createResourceSet)

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
			createResourceSet)

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
			createResourceSet)
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
			createResourceSet)
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
			createResourceSet)
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
			createResourceSet)

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
			createResourceSet)
		assertNotNull("Did not produce parse result", result)		
		
		result.assertNoWarnings(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)		
	}
}