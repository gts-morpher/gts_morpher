package uk.ac.kcl.inf.tests.converter

import com.google.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.resource.SaveOptions
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.tests.composer.TestURIHandlerImpl
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.util.MappingConverter.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class ConverterTests extends AbstractTest {
	@Inject extension ParseHelper<GTSMapping>

	@Inject extension ISerializer

	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"B.ecore",
			"A.henshin",
			"B.henshin",
			"transformers.henshin"
		].createResourceSet
	}

	private def normalSource() '''
		from {
			metamodel: "A"
			behaviour: "ARules"
		}'''

	private def familySource() '''
		from {
			family: {
				metamodel: "A"
				behaviour: "ARules"
				transformers: "transformerRules"
			}
		
			using [
				addSubClass (A.A1, "TT")
			]
		}'''

	@Test
	def void testBasicConversionClassMapping() {
		testConversionClassMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionClassMapping() {
		testConversionClassMapping(familySource)
	}
	
	private def testConversionClassMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
				}
			
				type_mapping {
					class A.A1 => B.B1
				}
			}'''.doTest
	}

	@Test
	def void testBasicConversionReferenceMapping() {
		testConversionReferenceMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionReferenceMapping() {
		testConversionReferenceMapping(familySource)
	}

	private def testConversionReferenceMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
				}
			
				type_mapping {
					reference A.A2.a => B.B2.a
				}
			}'''.doTest
	}

	@Test
	def void testBasicConversionAttributeMapping() {
		testConversionAttributeMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionAttributeMapping() {
		testConversionAttributeMapping(familySource)
	}
	
	private def testConversionAttributeMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
				}
			
				type_mapping {
					attribute A.A1.att => B.B2.att
				}
			}'''.doTest
	}

	@Test
	def void testBasicConversionObjectMapping() {
		testConversionObjectMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionObjectMapping() {
		testConversionObjectMapping(familySource)
	}
	
	private def testConversionObjectMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
			
				type_mapping {
					class A.A1 => B.B1
				}
			
				behaviour_mapping {
					rule do to do {
						object a1 => b1
					}
				}
			}'''.doTest
	}

	@Test
	def void testBasicConversionEmptyRuleMapping() {
		testConversionEmptyRuleMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionEmptyRuleMapping() {
		testConversionEmptyRuleMapping(familySource)
	}
	
	private def testConversionEmptyRuleMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
			
				type_mapping {
					class A.A1 => B.B1
				}
			
				behaviour_mapping {
					rule do to do {
					}
				}
			}'''.doTest
	}

	@Test
	def void testBasicConversionLinkMapping() {
		testConversionLinkMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionLinkMapping() {
		testConversionLinkMapping(familySource)
	}
	
	private def testConversionLinkMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
			
				type_mapping {
					class A.A1 => B.B1
				}
			
				behaviour_mapping {
					rule do to do {
						link [a1->a2:bs] => [b1->b2:_2s]
					}
				}
			}'''.doTest
	}

	@Test
	def void testBasicConversionSlotMapping() {
		testConversionSlotMapping(normalSource)
	}
	
	@Test
	def void testFamilyConversionSlotMapping() {
		testConversionSlotMapping(familySource)
	}
	
	private def testConversionSlotMapping(CharSequence srcText) {
		'''
			map {
				«srcText»
			
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
			
				type_mapping {
					class A.A1 => B.B2
				}
			
				behaviour_mapping {
					rule do to do {
						slot a1.att => b2.att
					}
				}
			}'''.doTest
	}

	// TODO: Add tests for GTS family choice case

	private def void doTest(CharSequence text) {
		val result = text.parse(createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		EcoreUtil.resolveAll(result)

		val mapping = result.typeMapping.extractMapping(null)
		if (result.behaviourMapping !== null) {
			mapping.putAll(result.behaviourMapping.extractMapping(null))
		}

		val rs = result.eResource.resourceSet

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)
		val resource = rs.createResource(URI.createURI("test:/synthetic.lang_compose"))

		assertEquals(
			"Extraction failed",
			result.serialize(
				SaveOptions.newBuilder.format.options),
			mapping.extractGTSMapping(result.source, result.target, resource).serialize(
				SaveOptions.newBuilder.format.options)
		)
	}
}
