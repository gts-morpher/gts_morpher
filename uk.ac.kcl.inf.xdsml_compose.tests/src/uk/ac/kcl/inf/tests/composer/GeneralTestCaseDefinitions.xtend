package uk.ac.kcl.inf.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.Test
import uk.ac.kcl.inf.composer.XDsmlComposer.Issue
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.util.Triple
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecificationModule

import static org.junit.Assert.*

/**
 * Define the general test cases. These will then be specialised by the two sub-classes to test the composition in general and the code-generation from the composition.
 */
@InjectWith(XDsmlComposeInjectorProvider)
abstract class GeneralTestCaseDefinitions extends AbstractTest {

	@Inject
	ParseHelper<GTSSpecificationModule> parseHelper

	@Inject
	extension ValidationTestHelper

	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"B.ecore",
			"A.henshin",
			"B.henshin",
			"C.ecore",
			"D.ecore",
			"C.henshin",
			"D.henshin",
			"E.ecore",
			"F.ecore",
			"G.ecore",
			"H.ecore",
			"I.ecore",
			"J.ecore",
			"I.henshin",
			"J.henshin",
			"K.ecore",
			"L.ecore",
			"K.henshin",
			"K2.henshin",
			"M.ecore",
			"M.henshin",
			"N.ecore"
		].createResourceSet
	}

	private def Triple<List<Issue>, EPackage, Module> doTest(GTSSpecificationModule module, ResourceSet rs) {
		module.doTest("woven", rs)
	}

	protected abstract def Triple<List<Issue>, EPackage, Module> doTest(GTSSpecificationModule module,
		String nameOfExport, ResourceSet rs)

	@Test
	def testSimpleTGMorphism() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts A {
				metamodel: "A"
			}
			
			map A2B {
				from interface_of { A }
				to {
					metamodel: "B"
				}
				
				type_mapping {
					class A.A1 => B.B1
				}
			}
			
			export gts woven_with_different_name {
				weave: {
					map1: interface_of (A)
					map2: A2B
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest("woven_with_different_name", resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("AB.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)
	}

	@Test
	def testSimpleGTSMorphism() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts A {
				metamodel: "A"
				behaviour: "ARules"
			}
			
			map A2B{
				from interface_of { A }
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
				
				type_mapping {
					class A.A1 => B.B1
				}
				
				behaviour_mapping {
					rule process to process {
						object a1 => b1
					}
				}
			}
			
			export gts woven_with_different_name {
				weave: {
					map1: interface_of (A)
					map2: A2B
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest("woven_with_different_name", resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		assertNotNull("Couldn't find composed Henshin rules", runResult.c)

		EcoreUtil2.resolveAll(runResult.c)
		val composedOracle = resourceSet.getResource(createFileURI("AB.henshin"), true).contents.head as Module
		EcoreUtil2.resolveAll(composedOracle)

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	def testNonInjectiveTGMorphism() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts C {
				metamodel: "C"
			}
			
			map C2D {
				from interface_of { C }
				to {
					metamodel: "D"
				}
				
				type_mapping {
					class C.C1 => D.D1
					class C.C2 => D.D1
					reference C.C2.c1 => D.D1.d1
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of(C)
					map2: C2D
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("CD.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)
	}

	@Test
	def testNonInjectiveGTSMorphism() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts C {
				metamodel: "C"
				behaviour: "CRules"
			}
			
			map C2D {
				from interface_of { C }
				
				to {
					metamodel: "D"
					behaviour: "DRules"
				}
				
				type_mapping {
					class C.C1 => D.D1
					class C.C2 => D.D1
					reference C.C2.c1 => D.D1.d1
				}
				
				behaviour_mapping {
					rule change to resolveSelfReference {
						object c2 => d1
						object c1 => d1
						object c1b => d1b
						link [c2->c1:c1] => [d1->d1:d1]
						link [c2->c1b:c1] => [d1->d1b:d1]
					}
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (C)
					map2: C2D
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedOracle = resourceSet.getResource(createFileURI("CD.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	def testNonInjectiveGTSMorphismToVirtualRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts C {
				metamodel: "C"
				behaviour: "CRules"
			}
			
			map C2D {
				from interface_of { C }
				
				to {
					metamodel: "D"
				}
				
				type_mapping {
					class C.C1 => D.D1
					class C.C2 => D.D1
					reference C.C2.c1 => D.D1.d1
				}
				
				behaviour_mapping {
					rule change to virtual
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (C)
					map2: C2D
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedOracle = resourceSet.getResource(createFileURI("CD2.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	// TODO: Also need to test case where there are already some target rules
	def testGTSMorphismToVirtualRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts K {
				metamodel: "K"
				behaviour: "KRules"
			}
			
			map K2L {
				from interface_of { K }
				
				to {
					metamodel: "L"
				}
				 
				type_mapping {
					class K.K1 => L.L1
					attribute K.K1.k1 => L.L1.l1
				}
				
				behaviour_mapping {
					rule init to virtual
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (K)
					map2: K2L
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedOracle = resourceSet.getResource(createFileURI("KL.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	def testGTSMorphismToVirtualRuleWithAutoComplete() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts K {
				metamodel: "K"
				behaviour: "K2Rules"
			}
			
			auto-complete unique map K2L {
				from interface_of { K }
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				//behaviour_mapping {
				//	rule init to virtual
				//}
			}
			
			export gts woven {
				weave: {
					map1: interface_of(K)
					map2: K2L
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedOracle = resourceSet.getResource(createFileURI("KL2.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	// TODO: Also need to test case where there are already some target rules
	def testGTSMorphismToIdentityRule() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts K {
				metamodel: "K"
				behaviour: "KRules"
			}
			
			map K2L {
				from interface_of { K }
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					class K.K1 => L.L1
					attribute K.K1.k1 => L.L1.l1
				}
				
				behaviour_mapping {
					rule init to virtual identity
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (K)
					map2: K2L
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedOracle = resourceSet.getResource(createFileURI("KL.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	def testGTSMorphismToIdentityRuleWithAutoComplete() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts K {
				metamodel: "K"
				behaviour: "KRules"
			}
			
			auto-complete unique map K2L {
				from interface_of { K }
				
				to {
					metamodel: "L"
				}
				
				type_mapping {
					class K.K1 => L.L1
					//attribute K.K1.k1 => L.L1.l1
				}
				
				//behaviour_mapping {
				//	rule init to identity
				//}
			}
			
			export gts woven {
				weave: {
					map1: interface_of(K)
					map2: K2L
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedOracle = resourceSet.getResource(createFileURI("KL.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedOracle, runResult.c)
	}

	@Test
	def testFromEmptyRuleMapping() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts I {
				metamodel: "I"
			}
			
			map I2J {
				from interface_of { I }
				to {
					metamodel: "J"
					behaviour: "JRules"
				}
				
				type_mapping {
					attribute I.I1.a1 => J.J1.a1
					class I.I1 => J.J1
				}
				behaviour_mapping {
					rule empty to do
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (I)
					map2: I2J
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ2.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedHenshinOracle, runResult.c)
	}

	@Test
	def testFromEmptyRuleMappingWithAutoComplete() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts I {
				metamodel: "I"
			}
			
			auto-complete unique allow-from-empty map I2J {
				from interface_of { I }
				to {
					metamodel: "J"
					behaviour: "JRules"
				}
				
				type_mapping {
					attribute I.I1.a1 => J.J1.a1
					class I.I1 => J.J1
				}
				//behaviour_mapping {
				//	rule empty to do
				//}
			}
			
			export gts woven {
				weave: {
					map1: interface_of(I)
					map2: I2J
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ2.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedHenshinOracle, runResult.c)
	}

	@Test
	def testClanBasedReferences() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts E {
				metamodel: "E"
			}
			
			map E2F {
				from interface_of { E }
				
				to {
					metamodel: "F"
				}
				
				type_mapping {
					class E.E1 => F.F1
					class E.E2 => F.F2
					reference E.E1.e2 => F.F0.f2
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (E)
					map2: E2F
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)
	}

	@Test
	def testInheritanceFolding() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts G {
				metamodel: "G"
			}
			
			map G2H {
				from interface_of { G }
				
				to {
					metamodel: "H"
				}
				
				type_mapping {
					class G.G1 => H.H1
					class G.G2 => H.H1
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (G)
					map2: G2H
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("GH.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)
	}

	@Test
	def testAttributeComposition() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts I {
				metamodel: "I"
				behaviour: "IRules"
			}
			
			map I2J {
				from interface_of { I }
				to {
					metamodel: "J"
					behaviour: "JRules"
				}
				
				type_mapping {
					attribute I.I1.a1 => J.J1.a1
					class I.I1 => J.J1
				}
				behaviour_mapping {
					rule do to do {
						object i1 => j1
						slot i1.a1 => j1.a1
					}
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (I)
					map2: I2J
				}
			}
			
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedHenshinOracle, runResult.c)
	}

	@Test
	def testAttributeCompositionWithAutoComplete() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts I {
				metamodel: "I"
				behaviour: "IRules"
			}
			
			auto-complete unique map I2J {
				from interface_of { I }
				
				to {
					metamodel: "J"
					behaviour: "JRules"
				}
				
				type_mapping {
					class I.I1 => J.J1
					attribute I.I1.a1 => J.J1.a1
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of (I)
					map2: I2J
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedHenshinOracle, runResult.c)
	}

	@Test
	def testAttributeCompositionWithAutoCompleteWithEmptyRuleMap() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts I {
				metamodel: "I"
				behaviour: "IRules"
			}
			
			auto-complete unique map I2J {
				from interface_of { I }
				
				to {
					metamodel: "J"
					behaviour: "JRules"
				}
				
				type_mapping {
					class I.I1 => J.J1
					attribute I.I1.a1 => J.J1.a1
				}
				
				behaviour_mapping {
					rule do to do {
					}
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of(I)
					map2: I2J
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedHenshinOracle, runResult.c)
	}

	@Test
	def testSimpleGTSMorphismReferencing() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts A {
				metamodel: "A"
				behaviour: "ARules"
			}
			
			map A2B{
				from interface_of { A }
				to {
					metamodel: "B"
					behaviour: "BRules"
				}
				
				type_mapping {
					class A.A1 => B.B1
				}
				
				behaviour_mapping {
					rule process to process {
						object a1 => b1
					}
				}
			}
			
			gts woven {
				weave: {
					map1: interface_of (A)
					map2: A2B
				}
			}
			
			map woven2C {
				from woven
				
				to {
					metamodel: "C"
					behaviour: "CRules"
				}
				
				type_mapping {
					class A_B.A1_B1 => C.C1
				}
				
				behaviour_mapping {
					rule process to change {
						object a1_b1 => c1
					}
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		result.assertNoError(Diagnostic.LINKING_DIAGNOSTIC)
	}

	@Test
	def testWeavingWithInterfaceAndNonInterfaceSuperClass() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			gts M {
				metamodel: "M"
				behaviour: "MRules"
			}
			
			gts N {
				metamodel: "N"
			}
			
			auto-complete unique map M2N {
				from interface_of { M }
				
				to N
				
				type_mapping {
					class M.M1 => N.N1
					class M.M2 => N.N2
					reference M.M1.m2s => N.N1.n2s
					reference M.M2.m1 => N.N2.n1
				}
			}
			
			export gts woven {
				weave: {
					map1: interface_of(M)
					map2: M2N
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)
		result.assertNoIssues

		val runResult = result.doTest(resourceSet)

		assertTrue("Expected to see no issues.", runResult.a.empty)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed ecore", runResult.b)

		val composedOracle = resourceSet.getResource(createFileURI("MN.ecore"), true).contents.head as EPackage

		assertEObjectsEquals("Woven TG was not as expected", composedOracle, runResult.b)

		// Check contents of generated resources and compare against oracle
		assertNotNull("Couldn't find composed henshin rules", runResult.c)

		val composedHenshinOracle = resourceSet.getResource(createFileURI("MN.henshin"), true).contents.head as Module

		assertEObjectsEquals("Woven GTS was not as expected", composedHenshinOracle, runResult.c)
	}

	static def void assertEObjectsEquals(String message, EObject expected, EObject actual) {
		new EqualityHelper(message).equals(expected, actual)
	}

	private static class EqualityHelper extends uk.ac.kcl.inf.tests.EqualityHelper {

		new(String message) {
			super(message)
		}

		override protected haveEqualReference(EObject expected, EObject actual, EReference reference) {
//			if (reference.ordered) {
//				super.haveEqualReference(eObject1, eObject2, reference)
//			} else {
			val Object value1 = expected.eGet(reference);
			val Object value2 = actual.eGet(reference);

			if (reference.many) {
				val expectedList = value1 as List<EObject>
				val actualList = value2 as List<EObject>
				val result = equalsUnordered(expectedList, actualList)

				if (!result && throwExceptionOnError) {
					// Try to get us a better error message
					val unmatchedElements = runProtected[
						new Pair<List<EObject>, List<EObject>>(expectedList.reject [ eo |
							actualList.exists[eo2|equals(eo, eo2)]
						].toList, actualList.reject[eo|expectedList.exists[eo2|equals(eo, eo2)]].toList)
					]

					if (unmatchedElements.key.size == unmatchedElements.value.size) {
						// Attempt to find matches where all attributes match, but there may be a difference further down the graph
						val deeplyUnmatchedElements = runProtected[
							new Pair<List<Pair<EObject, EObject>>, List<Pair<EObject, EObject>>>(
								unmatchedElements.key.map [ eo |
									new Pair<EObject, EObject>(eo, unmatchedElements.value.filter [ eo2 |
										(eo.eClass === eo2.eClass) && (eo.eClass.EAllAttributes.forall [ attr |
											haveEqualAttribute(eo, eo2, attr)
										])
									].head)
								].toList,
								unmatchedElements.value.map [ eo |
									new Pair<EObject, EObject>(eo, unmatchedElements.key.filter [ eo2 |
										(eo.eClass === eo2.eClass) && (eo.eClass.EAllAttributes.forall [ attr |
											haveEqualAttribute(eo2, eo, attr)
										])
									].head)
								].toList
							)
						]

						// Now execute the comparisons again in unprotected mode, throwing exceptions at the deepest level that's meaningful
						deeplyUnmatchedElements.key.filter[value !== null].forEach[p|equals(p.key, p.value)]
						deeplyUnmatchedElements.value.filter[value !== null].forEach[p|equals(p.key, p.value)]
					}

					// If all unmatching elements are shallowly unmatched, report that
					fail(format(expected, unmatchedElements.key, actual, unmatchedElements.value, reference))
				}

				result
			} else {
				equals(value1 as EObject, value2 as EObject)
			}
//			}
		}

		protected def equalsUnordered(List<EObject> expected, List<EObject> actual) {
			runProtected[
				(expected.size == actual.size) && expected.forall[eo|actual.exists[eo2|equals(eo, eo2)]] &&
					actual.forall [ eo |
						expected.exists[eo2|equals(eo, eo2)]
					]
			]
		}

		private def String format(EObject expected, List<? extends EObject> expectedList, EObject actual,
			List<? extends EObject> actualList, EReference reference) {
			val formatted = getMessage

			formatted + "Couldn't match elements referenced by EReference " + reference.name + ".\n" +
				"Expected object " + expected.formatClassAndValue + " had the following unmatched elements: [" +
				expectedList.map[formatClassAndValue].join(", ") + "].\n" + "Actual object " +
				actual.formatClassAndValue + " had the following unmatched elements: [" + actualList.map [
					formatClassAndValue
				].join(", ") + "]."
		}
	}
}
