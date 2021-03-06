package uk.ac.kcl.inf.gts_morpher.tests.converter

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
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider
import uk.ac.kcl.inf.gts_morpher.tests.TestURIHandlerImpl

import static org.junit.Assert.*
import static uk.ac.kcl.inf.gts_morpher.tests.EqualityHelper.*

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class ConverterTests extends AbstractTest {
	@Inject extension ParseHelper<GTSSpecificationModule>

	@Inject extension ISerializer

	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"B.ecore",
			"K.ecore",
			"L.ecore",
			"A.henshin",
			"A_unnamed.henshin",
			"K.henshin",
			"B.henshin",
			"B_unnamed.henshin",
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
			{
				metamodel: "A"
				behaviour: "ARules"
			}
			
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
	def void testBasicConversionParamMapping() {
		testConversionParamMapping(normalSource)
	}

	@Test
	def void testFamilyConversionParamMapping() {
		testConversionParamMapping(familySource)
	}

	private def testConversionParamMapping(CharSequence srcText) {
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
					param a2 => b2
				}
			}
		}'''.doTest
	}

	@Test
	def void testBasicMappingWithoutNodeNames() {
		testMappingWithoutNodeNames('''
			from {
				metamodel: "A"
				behaviour: "ARules_UN"
			}'''
		)
	}

	@Test
	def void testFamilyMappingWithoutNodeNames() {
		testMappingWithoutNodeNames('''
			from {
				family: {
					{
						metamodel: "A"
						behaviour: "ARules_UN"
					}
					
					transformers: "transformerRules"
				}
			
				using [
					addSubClass (A.A1, "TT")
				]
			}'''
		)
	}

	private def testMappingWithoutNodeNames(CharSequence srcText) {
		'''
		map {
			«srcText»
		
			to {
				metamodel: "B"
				behaviour: "BRules_UN"
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
	@Test
	def void testBasicMappingWithToVirtualRule() {
		'''
		map {
			from interface_of {
				metamodel: "K"
				behaviour: "KRules"
			}
		
			to {
				metamodel: "L"
			}
		
			type_mapping {
				class K.K1 => L.L1
			}
		
			behaviour_mapping {
				rule init to virtual
			}
		}'''.doTest
	}

	@Test
	def void testBasicMappingWithToVirtualRuleAndGTSReferences() {
		'''
		gts K {
			metamodel: "K"
			behaviour: "KRules"
		}
		
		gts LGTS {
			metamodel: "L"
		}
		
		map {
			from interface_of { K }
		
			to LGTS
		
			type_mapping {
				class K.K1 => L.L1
			}
		
			behaviour_mapping {
				rule init to virtual
			}
		}'''.doTest
	}

	@Test
	def void testBasicMappingWithToIdentityRule() {
		'''
		map {
			from interface_of {
				metamodel: "K"
				behaviour: "KRules"
			}
		
			to {
				metamodel: "L"
			}
		
			type_mapping {
				class K.K1 => L.L1
			}
		
			behaviour_mapping {
				rule init to virtual identity
			}
		}'''.doTest
	}

	@Test
	def testBasicMappingWithFromEmptyRule() {
		'''
		map {
			from {
				metamodel: "A"
			}
		
			to {
			metamodel: "B"
			behaviour: "BRules"
			}
		
			type_mapping {
				class A.A1 => B.B2
			}
		
			behaviour_mapping {
				rule empty to do
			}
		}'''.doTest
	}

	@Test
	def testMappingWithDuplicatedGTSReference() {
		'''
		gts AGTS {
			metamodel: "A"
		}
		
		map {
			from AGTS
		
			to AGTS
		
			type_mapping {
				class A.A1 => A.A2
			}
		}'''.doTest
	}

	@Test
	def testMappingWithDuplicatedGTSReferenceAndReferencingGTS() {
		'''
		gts A {
			metamodel: "A"
		}
		
		map {
			from { A }
		
			to A
		
			type_mapping {
				class A.A1 => A.A2
			}
		}'''.doTest
	}

	private def void doTest(CharSequence text) {
		val rs = createNormalResourceSet
		val result = text.parse(rs)
		assertNotNull("Did not produce parse result", result)
		EcoreUtil.resolveAll(result)

		val mapping = result.mappings.head.typeMapping.extractMapping(null)
		if (result.mappings.head.behaviourMapping !== null) {
			mapping.putAll(result.mappings.head.behaviourMapping.extractMapping(mapping, null))
		}

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)
		val resource = rs.createResource(URI.createURI("test:/synthetic.gts"))

		val extractedMapping = mapping.extractGTSMapping(result.mappings.head.source, result.mappings.head.target,
			resource)

		assertNotNull("Parsed mapping didn't serialise",
			result.mappings.head.serialize(SaveOptions.newBuilder.format.options))
		assertEObjectsEquals("Extracted mapping was different from parsed mapping", result.mappings.head,
			extractedMapping)

		assertEquals(
			"Extraction failed",
			result.mappings.head.serialize(SaveOptions.newBuilder.format.options).trim,
			extractedMapping.serialize(SaveOptions.newBuilder.format.options).trim
		)
	}
}
