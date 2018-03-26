package uk.ac.kcl.inf.tests.checker

import com.google.inject.Inject
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.tests.AbstractTest
import uk.ac.kcl.inf.tests.XDsmlComposeInjectorProvider
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping

import static org.junit.Assert.*

import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*
import static extension uk.ac.kcl.inf.util.MorphismChecker.*
import static extension uk.ac.kcl.inf.util.MappingConverter.*

@RunWith(XtextRunner)
@InjectWith(XDsmlComposeInjectorProvider)
class MorphismCheckerTests extends AbstractTest {
	@Inject
	ParseHelper<GTSMapping> parseHelper

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
			result.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
		assertTrue(
			"Empty rule map should be a morphism",
			checkRuleMorphism(
				result.target.behaviour.units.head as Rule,
				result.source.behaviour.units.head as Rule,
				result.typeMapping.extractMapping(null),
				result.behaviourMapping.extractMapping(null),
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
			!result.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
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
			!result.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
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
			result.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
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
			!result.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
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
			result.typeMapping.extractMapping(null).checkValidMaybeIncompleteClanMorphism(null))
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

		val typeMapping = result.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should be a rule morphism",
			checkRuleMorphism(
				result.target.behaviour.units.head as Rule,
				result.source.behaviour.units.head as Rule,
				typeMapping,
				result.behaviourMapping.extractMapping(null),
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

		val typeMapping = result.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should not be a rule morphism",
			!checkRuleMorphism(
				result.target.behaviour.units.head as Rule,
				result.source.behaviour.units.head as Rule,
				typeMapping,
				result.behaviourMapping.extractMapping(null),
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

		val typeMapping = result.typeMapping.extractMapping(null)
		assertTrue("Should be a clan morphism",
			typeMapping.checkValidMaybeIncompleteClanMorphism(null))

		assertTrue(
			"Should not be a rule morphism",
			!checkRuleMorphism(
				result.target.behaviour.units.head as Rule,
				result.source.behaviour.units.head as Rule,
				typeMapping,
				result.behaviourMapping.extractMapping(null),
				null
			)
		)
	}
}
