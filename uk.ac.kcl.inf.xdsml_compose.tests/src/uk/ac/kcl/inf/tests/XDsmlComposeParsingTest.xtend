/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class XDsmlComposeParsingTest {
	@Inject
	ParseHelper<GTSMapping> parseHelper
	
	@Test
	def void loadModel() {
		val result = parseHelper.parse('''
			map {
				type_mapping from "server.ecore" to "DEVSMM.ecore" {
					class server.Server => devsmm.Machine
					reference server.Server.Out => devsmm.Machine.out
				}
			}
		''')
		Assert.assertNotNull(result)
		Assert.assertTrue(result.eResource.errors.isEmpty)
	}
}
