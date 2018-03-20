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
			map {
				from {
					metamodel: "a"
				}
			
				to {
					metamodel: "b"
				}
			
				type_mapping {
					class a.A => b.B
					reference a.A.a => b.B.b
					attribute a.A.b => b.B.c
				}
			}'''
		val testInput = '''map{from{metamodel:"a"}to{metamodel:"b"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}}'''
		
		doTest(testInput, expectedResult)
	}
	
	@Test
	def testSimpleMorphism() {
		val expectedResult = '''
			map {
				from {
					metamodel: "a"
				}
			
				to {
					metamodel: "b"
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
		val testInput = '''map{from{metamodel:"a"}to{metamodel:"b"}type_mapping{class  a.A=>b.B reference  a.A.a=>b.B.b attribute   a.A.b=>b.B.c}behaviour_mapping{rule   a    to   b{object  a=>b link[A->B:C]=>[D->E:F]slot   a.c=>b.d}}}'''
		
		doTest(testInput, expectedResult)
	}

	private def doTest(CharSequence testInput, CharSequence expectedResult) {  
		assertEquals(expectedResult,testInput.parse ().serialize(SaveOptions.newBuilder.format.options))
	}
}
