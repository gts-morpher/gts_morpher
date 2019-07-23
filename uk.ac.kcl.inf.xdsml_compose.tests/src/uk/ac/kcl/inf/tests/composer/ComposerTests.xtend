package uk.ac.kcl.inf.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.composer.XDsmlComposer
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecificationModule

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class ComposerTests extends AbstractTest {
	@Inject
	XDsmlComposer composer

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
			"K2.henshin"
		].createResourceSet
	}

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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore("woven_with_different_name")
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("AB.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin("woven_with_different_name")
		assertNotNull("Couldn't find composed Henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		EcoreUtil2.resolveAll(composedLanguage)
		val composedOracle = resourceSet.getResource(createFileURI("AB.henshin"), true).contents.head as Module
		EcoreUtil2.resolveAll(composedOracle)

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("CD.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("CD.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("CD2.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("KL.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("KL2.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("KL.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedLanguage = henshin.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("KL.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedHenshin = henshin.contents.head
		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ2.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedHenshin, composedHenshinOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedHenshin = henshin.contents.head
		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ2.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedHenshin, composedHenshinOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("GH.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedHenshin = henshin.contents.head
		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedHenshin, composedHenshinOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedHenshin = henshin.contents.head
		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedHenshin, composedHenshinOracle))
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

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val ecore = resourceSet.findComposedEcore
		assertNotNull("Couldn't find composed ecore", ecore)

		val composedLanguage = ecore.contents.head
		val composedOracle = resourceSet.getResource(createFileURI("IJ.ecore"), true).contents.head as EPackage

		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
		assertNotNull("Couldn't find composed henshin rules", henshin)

		val composedHenshin = henshin.contents.head
		val composedHenshinOracle = resourceSet.getResource(createFileURI("IJ.henshin"), true).contents.head as Module

		assertTrue("Woven GTS was not as expected", new EqualityHelper().equals(composedHenshin, composedHenshinOracle))
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

	private def findComposedEcore(ResourceSet resourceSet) {
		resourceSet.findComposedEcore("woven")
	}
	
	private def findComposedEcore(ResourceSet resourceSet, String gtsName) {
		resourceSet.findComposed("ecore", gtsName)
	}

	private def findComposedHenshin(ResourceSet resourceSet) {
		resourceSet.findComposedHenshin("woven")
	}
	
	private def findComposedHenshin(ResourceSet resourceSet, String gtsName) {
		resourceSet.findComposed("henshin", gtsName)
	}
	
	private def findComposed(ResourceSet resourceSet, String ext, String gtsName) {
		resourceSet.resources.filter[r|TestURIHandlerImpl.TEST_URI_SCHEME.equals(r.URI.scheme)].filter [ r |
			gtsName.equals(r.URI.segments.get(r.URI.segmentCount - 2))
		].filter [ r |
			ext.equals(r.URI.fileExtension)
		].head
	}

	private static class EqualityHelper extends EcoreUtil.EqualityHelper {

		override protected haveEqualReference(EObject eObject1, EObject eObject2, EReference reference) {
//			if (reference.ordered) {
//				super.haveEqualReference(eObject1, eObject2, reference)
//			} else {
			val Object value1 = eObject1.eGet(reference);
			val Object value2 = eObject2.eGet(reference);

			if (reference.many) {
				equalsUnordered(value1 as List<EObject>, value2 as List<EObject>)
			} else {
				equals(value1 as EObject, value2 as EObject)
			}
//			}
		}

		protected def equalsUnordered(List<EObject> l1, List<EObject> l2) {
			(l1.size == l2.size) && l1.forall[eo|l2.exists[eo2|equals(eo, eo2)]] && l2.forall [ eo |
				l1.exists[eo2|equals(eo, eo2)]
			]
		}
	}
}
