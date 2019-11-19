package uk.ac.kcl.inf.gts_morpher.tests.formatter

import com.google.inject.Inject
import org.eclipse.xtext.resource.SaveOptions
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class FormatterTests extends AbstractTest {
	@Inject
	extension ParseHelper<GTSMapping> parseHelper
	
	@Inject 
	extension ISerializer serialiser

	@Test
	def testSimpleTGMorphism() {
		val expectedResult = '''
			auto-complete unique map {
				from {
					metamodel: "a"
				}
			
				to interface_of {
					metamodel: "b"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			}
			
			'''
		val testInput = '''auto-complete    unique       map{from{metamodel:"a"}to   interface_of{metamodel:"b"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}}'''
		
		doTest(testInput, expectedResult)
	}
	
	@Test
	def testSimpleTGMorphismWithGTSRefs() {
		val expectedResult = '''
			gts A {
				metamodel: "a"
			}
			
			auto-complete unique map A2B {
				from {
					A
				}
			
				to interface_of {
					metamodel: "b"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			}
			
			'''
		val testInput = '''gts    A    {metamodel: "a"}    auto-complete    unique       map     A2B{from{A}to   interface_of{metamodel:"b"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testGTSWeave() {
		val expectedResult = '''
			gts A {
				metamodel: "a"
			}
			
			auto-complete unique map A2B {
				from interface_of {
					A
				}
			
				to interface_of {
					metamodel: "b"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			}
			
			gts woven {
				weave: {
					map1: interface_of(A)
					map2: A2B
				}
			}
			
			'''
		val testInput = '''gts    A    {metamodel: "a"}    auto-complete    unique       map     A2B{from  interface_of{A}to   interface_of{metamodel:"b"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}}gts    woven{weave   :   {map1   :    interface_of   (   A   )map2   :   A2B}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testSimpleMorphism() {
		val expectedResult = '''
			map {
				from {
					metamodel: "a"
					behaviour: "arules"
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule a to b {
						object a => b
						link [A->B:C] => [D->E:F]
						slot a.c => b.d
						param a1 => b1
					}
				}
			}
			
			'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{object  a=>b link[A->B:C]=>[D->E:F]slot   a.c=>b.d    param   a1=>b1   }}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testSimpleMorphismEmptyRuleMapping() {
		val expectedResult = '''
			map {
				from {
					metamodel: "a"
					behaviour: "arules"
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule a to b {
					}
				}
			}
			
			'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{   }}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testSimpleMorphismRuleMappingToVirtual() {
		val expectedResult = '''
			map {
				from {
					metamodel: "a"
					behaviour: "arules"
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule a to virtual
				}
			}
			
			'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   virtual    }}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testSimpleMorphismRuleMappingToIdentity() {
		val expectedResult = '''
			map {
				from {
					metamodel: "a"
					behaviour: "arules"
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule a to virtual identity
				}
			}
			
			'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   virtual    identity}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testSimpleMorphismRuleMappingFromEmpty() {
		val expectedResult = '''
			map {
				from {
					metamodel: "a"
					behaviour: "arules"
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule empty to b
				}
			}
			
			'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   empty    to   b   }}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testMorphismFromFamily() {
		val expectedResult = '''
			map {
				from interface_of {
					family: {
						{
							metamodel: "a"
							behaviour: "arules"
						}
			
						transformers: "transformers"
					}
			
					using [
						addSubclass (a.b, "foo"),
						callOther (c.d, d.f, "s")
					]
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule a to b {
						object a => b
						link [A->B:C] => [D->E:F]
						slot a.c => b.d
					}
				}
			}
			
			'''
		val testInput = '''map{from  interface_of{family :{{metamodel  :"a"behaviour :"arules"}transformers  :"transformers"}using[addSubclass(a.b,"foo"),callOther(c.d,d.f,"s")]}to{metamodel :"b"behaviour :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{object  a=>b link[A->B:C]=>[D->E:F]slot   a.c=>b.d}}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testMorphismFromFamilyWithFamilyReference() {
		val expectedResult = '''
			gts_family AFamily {
				{
					metamodel: "a"
					behaviour: "arules"
				}

				transformers: "transformers"
			}

			map {
				from interface_of {
					family: AFamily
			
					using [
						addSubclass (a.b, "foo"),
						callOther (c.d, d.f, "s")
					]
				}
			
				to {
					metamodel: "b"
					behaviour: "brules"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			
				behaviour_mapping {
					rule a to b {
						object a => b
						link [A->B:C] => [D->E:F]
						slot a.c => b.d
					}
				}
			}
			
			'''
		val testInput = '''gts_family    AFamily      {{metamodel  :"a"behaviour :"arules"}transformers  :"transformers"}map{from  interface_of{family :AFamily    using[addSubclass(a.b,"foo"),callOther(c.d,d.f,"s")]}to{metamodel :"b"behaviour :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{object  a=>b link[A->B:C]=>[D->E:F]slot   a.c=>b.d}}}'''
		
		doTest(testInput, expectedResult)
	}

	private def doTest(CharSequence testInput, CharSequence expectedResult) {  
		assertEquals(expectedResult,testInput.parse ().serialize(SaveOptions.newBuilder.format.options))
	}
}
