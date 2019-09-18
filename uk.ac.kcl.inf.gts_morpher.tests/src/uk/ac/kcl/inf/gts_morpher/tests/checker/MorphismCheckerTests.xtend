package uk.ac.kcl.inf.gts_morpher.tests.checker

import com.google.inject.Inject
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MappingConverter.*
import static extension uk.ac.kcl.inf.gts_morpher.util.MorphismChecker.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class MorphismCheckerTests extends AbstractTest {
	@Inject
	ParseHelper<GTSSpecificationModule> parseHelper

	private def createNormalResourceSet() {
		#[
			"A.ecore",
			"B.ecore",
			"C.ecore",
			"C2.ecore",
			"D.ecore",
			"E.ecore",
			"A2.henshin",
			"B2.henshin",
			"F.ecore",
			"G.ecore",
			"G2.ecore",
			"F.henshin",
			"G.henshin"
		].createResourceSet
	}

	/**
	 * Tests that morphism checks work for rules with preserve nodes and create edges.
	 */
	@Test
	def void checkTGMappingOK() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "A"
					behaviour: "A2Rules"
				}
				
				to {
					metamodel: "B"
					behaviour: "B2Rules"
				}
				
				type_mapping {
					class A.A1 => B.B1
					class A.A2 => B.B2
					reference A.A1.bs => B.B1._2s
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		assertTrue("Should confirm as clan morphism",
			result.mappings.head.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
		val tgMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue(
			"Empty rule map should be a morphism",
			checkRuleMorphism(
				result.mappings.head.target.behaviour.units.head as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				tgMapping,
				result.mappings.head.behaviourMapping.extractMapping(tgMapping, null),
				null
			)
		)
	}

	/**
	 * Tests morphism checker correctly rejects mappings where references with differing upper-bound multiplicities are mapped.
	 */
	@Test
	def void checkTGMapDifferentUpperMultiplicities() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "A"
				}
				
				to {
					metamodel: "C"
				}
				
				type_mapping {
					class A.A1 => C.C1
					class A.A2 => C.C2
					reference A.A1.bs => C.C1._2s
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		assertTrue("Should not be a clan morphism",
			!result.mappings.head.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
	}

	/**
	 * Tests morphism checker correctly rejects mappings where references with differing lower-bound multiplicities are mapped.
	 */
	@Test
	def void checkTGMapDifferentLowerMultiplicities() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "A"
				}
				
				to {
					metamodel: "C2"
				}
				
				type_mapping {
					class A.A1 => C2.C1
					class A.A2 => C2.C2
					reference A.A1.bs => C2.C1._2s
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		assertTrue("Should not be a clan morphism",
			!result.mappings.head.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
	}

	/**
	 * Tests morphism checker accepts valid attribute mappings.
	 */
	@Test
	def void checkTGMapAttributeMappings() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "D"
				}
				
				to {
					metamodel: "E"
				}
				
				type_mapping {
					class D.D1 => E.E1
					attribute D.D1.a1 => E.E1.a1
					attribute D.D1.a2 => E.E1.a2
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		assertTrue("Should be a clan morphism",
			result.mappings.head.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
	}

	/**
	 * Tests morphism checker rejects invalid attribute mappings.
	 */
	@Test
	def void checkTGMapAttributeMappingsNegative() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "D"
				}
				
				to {
					metamodel: "E"
				}
				
				type_mapping {
					class D.D1 => E.E1
					attribute D.D1.a1 => E.E1.a2
					attribute D.D1.a2 => E.E1.a1
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		assertTrue("Should not be a clan morphism",
			!result.mappings.head.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
	}
	
	/**
	 * Tests morphism checker accepts valid attribute mappings across the inheritance hierarchy.
	 */
	@Test
	def void checkTGMapAttributeMappingsWithInheritance() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "D"
				}
				
				to {
					metamodel: "E"
				}
				
				type_mapping {
					class D.D1 => E.E2
					attribute D.D1.a1 => E.E1.a1
					attribute D.D1.a2 => E.E1.a2
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		assertTrue("Should be a clan morphism",
			result.mappings.head.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
	}
	
	/**
	 * Tests morphism checker accepts empty rule mappings. 
	 */
	@Test
	def void checkEmptyRuleMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				to {
					metamodel: "G"
					behaviour: "GRules"
				}
				
				type_mapping {
					class F.F1 => G.G1
					attribute F.F1.a1 => G.G1.a1
					attribute F.F1.a2 => G.G1.a2
				}
				
				behaviour_mapping {
					rule do to do {
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val typeMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should be a rule morphism",
			checkRuleMorphism(
				result.mappings.head.target.behaviour.units.head as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				typeMapping,
				result.mappings.head.behaviourMapping.extractMapping(typeMapping, null),
				null
			)
		)
	}

	/**
	 * Tests morphism checker accepts virtual rule mappings. 
	 */
	@Test
	def void checkVirtualRuleMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				to {
					metamodel: "G"
					//behaviour: "GRules"
				}
				
				type_mapping {
					class F.F1 => G.G1
					attribute F.F1.a1 => G.G1.a1
					attribute F.F1.a2 => G.G1.a2
				}
				
				behaviour_mapping {
					rule do to virtual
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val typeMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		val behaviourMapping = result.mappings.head.behaviourMapping.extractMapping(typeMapping, null)
		assertTrue(
			"Should be a rule morphism",
			checkRuleMorphism(
				behaviourMapping.keySet.findFirst[eo | behaviourMapping.get(eo) === result.mappings.head.source.behaviour.units.head]as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				typeMapping,
				behaviourMapping,
				null
			)
		)
	}

	/**
	 * Tests morphism checker accepts virtual rule mappings. 
	 */
	@Test
	def void checkVirtualIdentityRuleMapping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from interface_of {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				to {
					metamodel: "G2"
				}
				
				type_mapping {
					class F.F1 => G2.G1
					attribute F.F1.a2 => G2.G1.a2
				}
				
				behaviour_mapping {
					rule do to virtual identity
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val typeMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		val behaviourMapping = result.mappings.head.behaviourMapping.extractMapping(typeMapping, null)
		assertTrue(
			"Should be a rule morphism",
			checkRuleMorphism(
				behaviourMapping.keySet.findFirst[eo | behaviourMapping.get(eo) === result.mappings.head.source.behaviour.units.head]as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				typeMapping,
				behaviourMapping,
				null
			)
		)
	}

	/**
	 * Tests morphism checker accepts valid slot mappings. 
	 */
	@Test
	def void checkSlotMappingsPositive() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				to {
					metamodel: "G"
					behaviour: "GRules"
				}
				
				type_mapping {
					class F.F1 => G.G1
					attribute F.F1.a1 => G.G1.a1
					attribute F.F1.a2 => G.G1.a2
				}
				
				behaviour_mapping {
					rule do to do {
						object f1 => g1
						slot f1.a1 => g1.a1
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val typeMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should be a rule morphism",
			checkRuleMorphism(
				result.mappings.head.target.behaviour.units.head as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				typeMapping,
				result.mappings.head.behaviourMapping.extractMapping(typeMapping, null),
				null
			)
		)
	}

	/**
	 * Tests morphism checker rejects invalid slot mappings because of attribute type.
	 */
	@Test
	def void checkSlotMappingsNegativeTyping() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				to {
					metamodel: "G"
					behaviour: "GRules"
				}
				
				type_mapping {
					class F.F1 => G.G1
					attribute F.F1.a1 => G.G1.a1
					attribute F.F1.a2 => G.G1.a2
				}
				
				behaviour_mapping {
					rule do to do {
						object f1 => g1
						slot f1.a1 => g1.a2
						slot f1.a2 => g1.a1
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val typeMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should not be a rule morphism",
			!checkRuleMorphism(
				result.mappings.head.target.behaviour.units.head as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				typeMapping,
				result.mappings.head.behaviourMapping.extractMapping(typeMapping, null),
				null
			)
		)
	}

	/**
	 * Tests morphism checker rejects invalid slot mappings because of attribute values.
	 */
	@Test
	def void checkSlotMappingsNegativeValues() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val result = parseHelper.parse('''
			map {
				from {
					metamodel: "F"
					behaviour: "FRules"
				}
				
				to {
					metamodel: "G"
					behaviour: "GRules"
				}
				
				type_mapping {
					class F.F1 => G.G1
					attribute F.F1.a1 => G.G1.a1
					attribute F.F1.a2 => G.G1.a2
				}
				
				behaviour_mapping {
					rule do to do {
						object f1 => g1
						slot f1.a2 => g1.a2
					}
				}
			}
		''', createNormalResourceSet)
		assertNotNull("Did not produce parse result", result)

		val typeMapping = result.mappings.head.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should not be a rule morphism",
			!checkRuleMorphism(
				result.mappings.head.target.behaviour.units.head as Rule,
				result.mappings.head.source.behaviour.units.head as Rule,
				typeMapping,
				result.mappings.head.behaviourMapping.extractMapping(typeMapping, null),
				null
			)
		)
	}
}
