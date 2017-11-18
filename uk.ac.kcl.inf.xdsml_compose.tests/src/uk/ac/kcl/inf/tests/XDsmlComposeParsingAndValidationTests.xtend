/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.tests

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
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
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static org.junit.Assert.*

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
		val serverURI = URI.createFileURI(XDsmlComposeParsingAndValidationTests.getResource("server.ecore").path)
		resourceSet.getResource(serverURI, true)
		val devsmmURI = URI.createFileURI(XDsmlComposeParsingAndValidationTests.getResource("DEVSMM.ecore").path)
		resourceSet.getResource(devsmmURI, true)
		resourceSet
	}
	
	/**
	 * Tests basic parsing and linking for a sunshine case
	 */
	@Test
	def void loadModel() {	
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
				map {
					type_mapping from "server" to "devsmm" {
						class server.Server => devsmm.Machine
						reference server.Server.Out => devsmm.Machine.out
					}
				}
			''',
			createResourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		assertNotNull("No type mapping", result.typeMapping)

		assertNotNull("Did not load source package", result.typeMapping.source.name)
		assertNotNull("Did not load target package", result.typeMapping.target.name)

		assertNotNull("Did not load source class", (result.typeMapping.mappings.head as ClassMapping).source.name)
		assertNotNull("Did not load target class", (result.typeMapping.mappings.head as ClassMapping).target.name)

		assertNotNull("Did not load source reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).source.name)
		assertNotNull("Did not load target reference", (result.typeMapping.mappings.get(1) as ReferenceMapping).target.name)
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
					type_mapping from "server" to "devsmm" {
						class devsmm.Machine => server.Server 
						reference devsmm.Machine.out => server.Server.Out
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
		result.typeMapping.assertWarning(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		assertTrue(issues.length == 5)	
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
					type_mapping from "server" to "devsmm" {
						class server.Server => devsmm.Machine 
						class server.Server => devsmm.Assemble 
						reference server.Server.Out => devsmm.Machine.out 
						reference server.Server.Out => devsmm.Machine.in
					}
				}
			''',
			createResourceSet)

		assertNotNull("Did not produce parse result", result)
		// Expecting validation errors as there are duplicate mappings
		val issues = result.validate()
		result.typeMapping.mappings.get(1).assertError(XDsmlComposePackage.Literals.CLASS_MAPPING, XDsmlComposeValidator.DUPLICATE_CLASS_MAPPING, "Duplicate mapping for EClassifier Server.")
		result.typeMapping.mappings.get(3).assertError(XDsmlComposePackage.Literals.REFERENCE_MAPPING, XDsmlComposeValidator.DUPLICATE_REFERENCE_MAPPING, "Duplicate mapping for EReference Out.")
		result.typeMapping.assertWarning(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		assertTrue(issues.length == 3)
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
					type_mapping from "server" to "devsmm" {
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
		result.typeMapping.assertWarning(XDsmlComposePackage.Literals.TYPE_GRAPH_MAPPING, XDsmlComposeValidator.INCOMPLETE_TYPE_GRAPH_MAPPING)
		assertTrue(issues.length == 3)
	}
}