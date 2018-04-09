package uk.ac.kcl.inf.tests.formatter

import com.google.inject.Inject
import org.eclipse.xtext.resource.SaveOptions
import org.eclipse.xtext.serializer.ISerializer
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
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
			}'''
		val testInput = '''auto-complete    unique       map{from{metamodel:"a"}to   interface_of{metamodel:"b"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}}'''
		
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
					}
				}
			}'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{object  a=>b link[A->B:C]=>[D->E:F]slot   a.c=>b.d}}}'''
		
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
			}'''
		val testInput = '''map{from{metamodel  :"a"behaviour  :"arules"}to{metamodel  :"b"behaviour  :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{   }}}'''
		
		doTest(testInput, expectedResult)
	}

	@Test
	def testMorphismFromFamily() {
		val expectedResult = '''
			map {
				from interface_of {
					family: {
						metamodel: "a"
						behaviour: "arules"
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
			}'''
		val testInput = '''map{from  interface_of{family :{metamodel  :"a"behaviour :"arules"transformers  :"transformers"}using[addSubclass(a.b,"foo"),callOther(c.d,d.f,"s")]}to{metamodel :"b"behaviour :"brules"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{object  a=>b link[A->B:C]=>[D->E:F]slot   a.c=>b.d}}}'''
		
		doTest(testInput, expectedResult)
	}

	private def doTest(CharSequence testInput, CharSequence expectedResult) {  
		assertEquals(expectedResult,testInput.parse ().serialize(SaveOptions.newBuilder.format.options))
	}
}
