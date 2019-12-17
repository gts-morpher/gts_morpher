package uk.ac.kcl.inf.gts_morpher.tests.shifter

import com.google.inject.Inject
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider
import uk.ac.kcl.inf.gts_morpher.util.ACShifter

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class ApplicationConditionShifterTests extends AbstractTest {
	@Inject
	ParseHelper<GTSSpecificationModule> parseHelper

	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"A.henshin"
		].createResourceSet
	}

	/**
	 * Test the basic shifting of a NAC along a GTS mapping.
	 */
	@Test
	def void shiftACAlongGTSMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			gts A {
				metamodel: "A"
				behaviour: "ARules"
			}

			map {
				from interface_of { A }
				
				to A
				
				type_mapping {
					class A.A1 => A.A1
					class A.A2 => A.A2
					class A.A3 => A.A3
					class A.A4 => A.A4
					reference A.A1.a2 => A.A1.a2
					reference A.A1.a3 => A.A1.a3
					reference A.A2.a4s => A.A2.a4s
					reference A.A3.a4s => A.A3.a4s
				}
				
				behaviour_mapping {
					rule test to test {
						object a1 => a1
						object a2 => a2
						object a3 => a3
						object a4 => a4
						
						link [a1->a2:a2] => [a1->a2:a2]
						link [a1->a3:a3] => [a1->a3:a3]
						link [a2->a4:a4s] => [a2->a4:a4s]
						link [a3->a4:a4s] => [a3->a4:a4s]
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)
		
		val nac = ((result.members.head as GTSSpecification).behaviour.units.head as Rule).lhs.formula
		assertNotNull("Did not find NAC", nac)
		
		val mapping = result.members.get(1) as GTSMapping
		
		val tgMapping = mapping.typeMapping.extractMapping(null)
		val behaviourMapping = mapping.behaviourMapping.extractMapping(tgMapping, null)
		
		val shiftedNAC = ACShifter.shift(nac, tgMapping, behaviourMapping)
		assertNotNull("Expected to produce a shifted NAC", shiftedNAC)
		
		assertEObjectsEquals("Expected the right kind of NAC to be produced", nac, shiftedNAC)
	}
}
