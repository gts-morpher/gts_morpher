package uk.ac.kcl.inf.gts_morpher.tests.shifter

import com.google.inject.Inject
import java.util.function.Predicate
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.shifter.ApplicationCondition
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider

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

		val gtsSpecification = result.members.head as GTSSpecification
		val rule = gtsSpecification.behaviour.units.head as Rule
		val lhs = rule.lhs
		val nac = lhs.formula
		assertNotNull("Did not find NAC", nac)

		val ac = new ApplicationCondition(nac)
		assertNotNull("Did not extract NAC", ac)
		assertTrue("Expected AC to be negative", ac.negative)
		assertTrue("Expected all lhs elements to be contained in application condition", (lhs.nodes + lhs.edges +
			lhs.nodes.flatMap [
				attributes
			]).exists[ac.morphism.containsKey(it)])
		assertTrue("Expected NAC to contain two additional elements", ac.unmappedElements.size === 2)

		val mapping = result.members.get(1) as GTSMapping

		val tgMapping = mapping.typeMapping.extractMapping(null)
		val behaviourMapping = mapping.behaviourMapping.extractMapping(tgMapping, null)
		behaviourMapping.put(lhs, lhs)

		val shiftedNAC = ac.shift(tgMapping, behaviourMapping, mapping.source.interface_mapping)
		assertNotNull("Expected to produce a shifted NAC", shiftedNAC)
		assertTrue("Expected shifted AC to be negative", shiftedNAC.negative)

		val equalityChecker1 = ac.createEqualityHelper("Expected EObject equality", shiftedNAC, gtsSpecification.metamodel)
		val equalityChecker2 = ac.createEqualityHelper("Expected EObject equality", shiftedNAC, gtsSpecification.metamodel)
		val equalityChecker3 = ac.createEqualityHelper("Expected EObject equality", shiftedNAC, gtsSpecification.metamodel)
		
		val acHostGraph = ac.morphism.keySet.head.graph
		val shiftedHostGraph = shiftedNAC.morphism.keySet.head.graph 
		val graphEqualityChecker = new EqualityHelper("Expected host graph equality", true)[eo |
			eo === acHostGraph || eo === shiftedHostGraph ||
			acHostGraph.eAllContents.exists[eo1 | eo === eo1] ||
			shiftedHostGraph.eAllContents.exists[eo1 | eo === eo1] ||
			gtsSpecification.metamodel.eAllContents.exists[eo1 | eo === eo1]
		]

		val acTargetGraph = ac.unmappedElements.head.graph
		val shiftedTargetGraph = shiftedNAC.unmappedElements.head.graph 
		val targetGraphEqualityChecker = new EqualityHelper("Expected target graph equality", true)[eo |
			eo === acTargetGraph || eo === shiftedTargetGraph ||
			acTargetGraph.eAllContents.exists[eo1 | eo === eo1] ||
			shiftedTargetGraph.eAllContents.exists[eo1 | eo === eo1] ||
			gtsSpecification.metamodel.eAllContents.exists[eo1 | eo === eo1]
		]

		assertTrue("Expected shifted AC to have same negativity as original AC", (ac.negative === shiftedNAC.negative))
		assertTrue("Expected shifted AC to have same size morphism as original AC",
			(ac.morphism.keySet.size === shiftedNAC.morphism.size))
		assertTrue("Expected shifted AC to have same size unmapped elements as original AC",
			(ac.unmappedElements.size === shiftedNAC.unmappedElements.size))
		assertTrue("Expected host graphs to be equal", graphEqualityChecker.equals(acHostGraph, shiftedHostGraph))
		assertTrue("Expected target graphs to be equal", targetGraphEqualityChecker.equals(acTargetGraph, shiftedTargetGraph))
		
		assertTrue(
			"Expected shifted AC to have equal morphism to original AC",
			(ac.morphism.entrySet.forall [ e |
				val res = shiftedNAC.morphism.entrySet.exists [ shiftedE |
					equalityChecker1.equals(e.key, shiftedE.key) && equalityChecker2.equals(e.value, shiftedE.value)

				]
				if (!res) {
					throw new AssertionError("Couldn't find correspondence for (" + e.key + " <" + e.key.hashCode + ">, " + e.value + " <" + e.key.hashCode + ">)")
				}

				res
			])
		)
		assertTrue(
			"Expected shifted AC to have equal unmapped elements to original AC",
			(ac.unmappedElements.forall [ eo |
				shiftedNAC.unmappedElements.exists [ shiftedEO |
					equalityChecker3.equals(eo, shiftedEO)
				]
			])
		)
	}
	
	private def createEqualityHelper(ApplicationCondition acExpected, String message, ApplicationCondition acShifted, EPackage metamodel) {
		new EqualityHelper(message, false, [eo | 
			acExpected.morphism.containsKey(eo) || acExpected.morphism.containsValue(eo) || acExpected.unmappedElements.contains(eo) ||
			acShifted.morphism.containsKey(eo) || acShifted.morphism.containsValue(eo) || acShifted.unmappedElements.contains(eo) ||
			metamodel.eAllContents.exists[eo1 | eo === eo1]
		])
	}

	private static class EqualityHelper extends uk.ac.kcl.inf.gts_morpher.tests.EqualityHelper {
		val Predicate<EObject> isContained

		new(String message, boolean throwExceptions, Predicate<EObject> isContained) {
			super(message)

			this.isContained = isContained
			throwExceptionOnError = throwExceptions
		}

		override equals(EObject eo1, EObject eo2) {
			(!isContained.test(eo1)) || super.equals(eo1, eo2)
		}
	}
}
