package uk.ac.kcl.inf.tests.formatter

import com.google.inject.Inject
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

	private def createNormalResourceSet() {
		#[
			"server.ecore",
			"DEVSMM.ecore"
		].createResourceSet
	}

	@Test
	def testSimpleTGMorphism() {
		val expectedResult = '''
			map {
				from {
					metamodel: "server"
				}
				to {
					metamodel: "devsmm"
				}
				
				type_mapping {
					class server.Server => devsmm.Machine
					reference server.Server.Out => devsmm.Machine.out
				}
			}
		'''
		val testInput = '''map{from{metamodel:"server"}to{metamodel:"devsmm"}type_mapping{class server.Server=>devsmm.Machine reference server.Server.Out=>devsmm.Machine.out}}'''
		
		doTest(testInput, expectedResult)
	}
	
	private def doTest(CharSequence testInput, CharSequence expectedResult) {  
		assertEquals(expectedResult,testInput.parse (createNormalResourceSet).serialize)
	}
}
