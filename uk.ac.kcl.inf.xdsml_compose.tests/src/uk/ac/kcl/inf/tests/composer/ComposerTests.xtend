package uk.ac.kcl.inf.tests.composer

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.emf.ecore.xml.type.XMLTypePackage
import org.eclipse.emf.henshin.model.Module
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.composer.XDsmlComposer
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.util.IProgressMonitor
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class ComposerTests extends AbstractTest {
	@Inject
	XDsmlComposer composer

	@Inject
	ParseHelper<GTSMapping> parseHelper

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
			"F.ecore"			
		].createResourceSet
	}

	@Test
	def testSimpleTGMorphism() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			map {
				from interface_of {
					metamodel: "A"
				}
				to {
					metamodel: "B"
				}
				
				type_mapping {
					class A.A1 => B.B1
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
		val composedOracle = resourceSet.getResource(createFileURI("AB.ecore"), true).contents.head as EPackage
		
		assertTrue("Woven TG was not as expected", new EqualityHelper().equals(composedLanguage, composedOracle))
	}

	@Test
	def testSimpleGTSMorphism() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			map {
				from interface_of {
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
				
				behaviour_mapping {
					rule BRules.process to ARules.process {
						object a1 => b1
					}
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)

		// Check contents of generated resources and compare against oracle
		val henshin = resourceSet.findComposedHenshin
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
			map {
				from interface_of {
					metamodel: "C"
				}
				to {
					metamodel: "D"
				}
				
				type_mapping {
					class C.C1 => D.D1
					class C.C2 => D.D1
					reference C.C2.c1 => D.D1.d1
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
			map {
				from interface_of {
					metamodel: "C"
					behaviour: "CRules"
				}
				
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
					rule DRules.resolveSelfReference to CRules.change {
						object c2 => d1
						object c1 => d1
						object c1b => d1b
						link [c2->c1:c1] => [d1->d1:d1]
						link [c2->c1b:c1] => [d1->d1b:d1]
					}
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
	def testClanBasedReferences() {
		val resourceSet = createNormalResourceSet
		val result = parseHelper.parse('''
			map {
				from interface_of {
					metamodel: "E"
				}
				
				to {
					metamodel: "F"
				}
				
				type_mapping {
					class E.E1 => F.F1
					class E.E2 => F.F2
					reference E.E1.e2 => F.F0.f2
				}
			}
		''', resourceSet)
		assertNotNull("Did not produce parse result", result)

		// Run composer and test outputs -- need to set up appropriate FSA and mock resource saving
		val issues = composer.doCompose(result.eResource, new TestFileSystemAccess, IProgressMonitor.NULL_IMPL)

		assertTrue("Expected to see no issues.", issues.empty)
	}

	private def findComposedEcore(ResourceSet resourceSet) {
		resourceSet.findComposed("ecore")
	}

	private def findComposedHenshin(ResourceSet resourceSet) {
		resourceSet.findComposed("henshin")
	}
		
	private def findComposed(ResourceSet resourceSet, String ext) {
		resourceSet.resources.filter[r|TestURIHandlerImpl.TEST_URI_SCHEME.equals(r.URI.scheme)].filter [r |
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
			(l1.size == l2.size) &&
			l1.forall[eo | l2.exists[eo2 | equals(eo, eo2)]] &&
			l2.forall[eo | l1.exists[eo2 | equals(eo, eo2)]]
		}
	}
}
