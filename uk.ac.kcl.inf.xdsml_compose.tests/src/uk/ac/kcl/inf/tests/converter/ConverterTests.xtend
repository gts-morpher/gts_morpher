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
			"B.henshin"
		].createResourceSet
	}

	@Test
	def void testBasicConversionClassMapping() {
		'''
			map {
				from {
					metamodel: "A"
				}
			
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
		'''
			map {
				from {
					metamodel: "A"
				}
			
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
		'''
			map {
				from {
					metamodel: "A"
				}
			
				to {
					metamodel: "B"
				}
			
				type_mapping {
					attribute A.A1.att => B.B1.att
				}
			}'''.doTest
	}

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
			text.toString,
			mapping.extractGTSMapping(result.source, result.target, resource).serialize(
				SaveOptions.newBuilder.format.options)
		)
	}
}
