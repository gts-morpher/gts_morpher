package uk.ac.kcl.inf.tests.gtsfamilies

import com.google.inject.Inject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.generator.XDsmlComposeGenerator
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.TestFileSystemAccess
import uk.ac.kcl.inf.tests.TestURIHandlerImpl
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.validation.XDsmlComposeValidator
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecificationModule
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposePackage

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.tests.TestResourceHandling.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class GTSFamiliesTests extends AbstractTest {
	@Inject
	XDsmlComposeGenerator generator

	@Inject
	ParseHelper<GTSSpecificationModule> parseHelper

	@Inject
	extension ValidationTestHelper

	override protected createResourceSet(String[] fileNames) {
		val rs = super.createResourceSet(fileNames)

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)

		rs
	}

	private def createNormalResourceSet() {
		#["server1.ecore", "server2.ecore", "server1.henshin", "server2.henshin", "transformers.henshin"].
			createResourceSet
	}

	/**
	 * Test GTS family choices are correctly evaluated.
	 */
	@Test
	def void testGTSFamilyChoices() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use �serverURI.toString� etc. below
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			export gts ServerChoice {
				family: {
					{
						metamodel: "server1"
					}
					
					transformers: "transformerRules"
				}
				
				using [
					addSubClass(server1.Queue, "InQueue"),
					addSubClass(server1.Queue, "OutQueue")
				]
			}
			
			auto-complete map {
				from ServerChoice
				
				to {
					metamodel: "server2"
				}
				
				type_mapping {
					class server1.Server => server2.Server
					class server1.InQueue => server2.InQueue
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		result.assertNoIssues

		result.checkGeneration(resourceSet, false)
	}

	/**
	 * Test GTS family choices are correctly evaluated.
	 */
	@Test
	def void testGTSFamilyChoicesWithRules() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use �serverURI.toString� etc. below
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			export gts ServerChoice {
				family: {
					{
						metamodel: "server1"
						behaviour: "server1Rules"
					}
					
					transformers: "transformerRules"
				}
				
				using [
					addSubClass(server1.Queue, "InQueue"),
					addSubClass(server1.Queue, "OutQueue"),
					reTypeToSubClass(server1Rules.produce, server1.Queue, server1.OutQueue)
				]
			}
			
			auto-complete map {
				from ServerChoice
				
				to {
					metamodel: "server2"
					behaviour: "server2Rules"
				}
				
				type_mapping {
					class server1.Server => server2.Server
					class server1.OutQueue => server2.OutQueue
				}
				
				behaviour_mapping {
					rule produce to produce {
						object q => oq
					}
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		result.assertNoIssues

		result.checkGeneration(resourceSet, true)
	}

	/**
	 * Test GTS family issues are correctly reported
	 */
	@Test
	def void testGTSFamilyChoicesIssues() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use �serverURI.toString� etc. below
		val result = parseHelper.parse('''
			export gts ServerChoice {
				family: {
					{
						metamodel: "server1"
					}
					
					transformers: "transformerRules"
				}
				
				using [
					addSubClass(server1.Queuer, "InQueue"),
					addSubClass(server1.Queue, "OutQueue")
				]
			}
			
			auto-complete map {
				from ServerChoice
				
				to {
					metamodel: "server2"
				}
				
				type_mapping {
					class server1.Server => server2.Server
					class server1.InQueue => server2.InQueue
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		assertTrue("Found parse errors: " + result.eResource.errors, result.eResource.errors.isEmpty)

		result.assertError(XDsmlComposePackage.Literals.UNIT_CALL, XDsmlComposeValidator.GTS_FAMILY_ISSUE)
	}

	private def checkGeneration(GTSSpecificationModule module, ResourceSet resourceSet, boolean includeRules) {
		// Run generator and test outputs -- need to set up appropriate FSA and mock resource saving
		generator.doGenerate(module.eResource, new TestFileSystemAccess, [IProgressMonitor.NULL_IMPL])

		// Check contents of generated resources and compare against oracle
		val ecoreResource = resourceSet.findComposedEcore("ServerChoice")
		assertNotNull("Could not find metamodel from GTS family.", ecoreResource)

		if (includeRules) {
			val henshinResource = resourceSet.findComposedHenshin("ServerChoice")
			assertNotNull("Could not find henshin from GTS family.", henshinResource)
		}
	}
}
