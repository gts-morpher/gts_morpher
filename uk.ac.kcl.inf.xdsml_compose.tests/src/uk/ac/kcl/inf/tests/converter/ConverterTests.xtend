package uk.ac.kcl.inf.tests.converter

import com.google.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.henshin.model.Module
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.resource.SaveOptions
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.TestURIHandlerImpl
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecificationModule
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposeFactory

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.util.MappingConverter.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
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
			"K.henshin",
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

	/**
	 * The same as {@link #testBasicMappingWithToVirtualRuleAndGTSReferences} minus the parsing and extraction steps
	 */
	@Test
	def void testFromFullyManuallyConstructed2() {
		val rs = createNormalResourceSet
		val resourceForKEcore = rs.getResource(createFileURI("K.ecore"), true)
		val metamodelForK = resourceForKEcore.contents.head as EPackage
		val resourceForKHenshin = rs.getResource(createFileURI("K.henshin"), true)
		val moduleforK = resourceForKHenshin.contents.head as Module
		val resourceForLEcore = rs.getResource(createFileURI("L.ecore"), true)
		val metamodelForL = resourceForLEcore.contents.head as EPackage

		val k1 = metamodelForK.EClassifiers.filter[name == "K1"].head
		val l1 = metamodelForL.EClassifiers.filter[name == "L1"].head
		
		val initRule = moduleforK.units.filter[name == "init"].head as Rule

		extension val factory = XDsmlComposeFactory.eINSTANCE

		val module = createGTSSpecificationModule => [
			val gtsK = createGTSSpecification => [
				name = "K"

				gts = createGTSLiteral => [
					metamodel = metamodelForK
					behaviour = moduleforK
				]
			]
			members += gtsK
			
			val gtsL = createGTSSpecification => [
				name = "LGTS"

				gts = createGTSLiteral => [
					metamodel = metamodelForL
				]
			]
			members += gtsL
		
			members += createGTSMapping => [
				source = createGTSSpecification => [
					interface_mapping = true
					gts = createGTSReference => [
						ref = gtsK
					]
				]
				
				target = createGTSReference => [
					ref = gtsL
				]

				typeMapping = createTypeGraphMapping => [
					mappings += createClassMapping => [
						source = k1
						target = l1
					]
				]
				
				behaviourMapping = createBehaviourMapping => [
					mappings += createRuleMapping => [
						source = initRule
						target_virtual = true
//						target_identity = true
					]
				]
			]
		]

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)
		val resource = rs.createResource(URI.createURI("test:/synthetic.lang_compose"))

		resource.contents += module

		assertNotNull("Didn't serialise", module.serialize(SaveOptions.newBuilder.format.options))
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

	/**
	 * The same as {@link #testMappingWithDuplicatedGTSReference} minus the parsing and extraction steps
	 */
	@Test
	def void testFromFullyManuallyConstructed1() {
		val rs = createNormalResourceSet
		val resourceForA = rs.getResource(createFileURI("A.ecore"), true)
		val metamodelForA = resourceForA.contents.head as EPackage
		val a1 = metamodelForA.EClassifiers.filter[name == "A1"].head
		val a2 = metamodelForA.EClassifiers.filter[name == "A2"].head

		extension val factory = XDsmlComposeFactory.eINSTANCE

		val module = createGTSSpecificationModule => [
			val theGTS = createGTSSpecification => [
				name = "AGTS"

				gts = createGTSLiteral => [
					metamodel = metamodelForA
				]
			]
			members += theGTS

			members += createGTSMapping => [
				source = createGTSReference => [
					ref = theGTS
				]

				target = createGTSReference => [
					ref = theGTS
				]

				typeMapping = createTypeGraphMapping => [
					mappings += createClassMapping => [
						source = a1
						target = a2
					]
				]
			]
		]

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)
		val resource = rs.createResource(URI.createURI("test:/synthetic.lang_compose"))

		resource.contents += module

		assertNotNull("Didn't serialise", module.serialize(SaveOptions.newBuilder.format.options))
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

	/**
	 * The same as {@link #testMappingWithDuplicatedGTSReferenceAndReferencingGTS} minus the parsing and extraction steps
	 */
	@Test
	def void testFromFullyManuallyConstructed() {		
		val rs = createNormalResourceSet
		val resourceForA = rs.getResource(createFileURI("A.ecore"), true)
		val metamodelForA = resourceForA.contents.head as EPackage
		val a1 = metamodelForA.EClassifiers.filter[name == "A1"].head
		val a2 = metamodelForA.EClassifiers.filter[name == "A2"].head

		extension val factory = XDsmlComposeFactory.eINSTANCE

		val module = createGTSSpecificationModule => [
			val theGTS = createGTSSpecification => [
				name = "A"

				gts = createGTSLiteral => [
					metamodel = metamodelForA
				]
			]
			members += theGTS

			members += createGTSMapping => [
				source = createGTSSpecification => [
					interface_mapping = false

					gts = createGTSReference => [
						ref = theGTS
					]
				]

				target = createGTSReference => [
					ref = theGTS
				]

				typeMapping = createTypeGraphMapping => [
					mappings += createClassMapping => [
						source = a1
						target = a2
					]
				]
			]
		]

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)
		val resource = rs.createResource(URI.createURI("test:/synthetic.lang_compose"))

		resource.contents += module

		assertNotNull("Didn't serialise", module.serialize(SaveOptions.newBuilder.format.options))
	}

	private def void doTest(CharSequence text) {
		val result = text.parse(createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		EcoreUtil.resolveAll(result)

		val mapping = result.mappings.head.typeMapping.extractMapping(null)
		if (result.mappings.head.behaviourMapping !== null) {
			mapping.putAll(result.mappings.head.behaviourMapping.extractMapping(mapping, null))
		}

		val rs = result.eResource.resourceSet

		rs.URIConverter.URIHandlers.add(0, new TestURIHandlerImpl)
		val resource = rs.createResource(URI.createURI("test:/synthetic.lang_compose"))

		val extractedMapping = mapping.extractGTSMapping(result.mappings.head.source, result.mappings.head.target,
			resource)

		assertEquals(
			"Extraction failed",
			result.mappings.head.serialize(SaveOptions.newBuilder.format.options).trim,
			extractedMapping.serialize(SaveOptions.newBuilder.format.options).trim
		)
	}
}
