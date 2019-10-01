package uk.ac.kcl.inf.gts_morpher.tests.mergesets

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.composer.helpers.ModelSpan
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider
import static org.junit.Assert.assertEquals

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class MergeSetTests {
	extension val EcoreFactory ecoreFactory = EcoreFactory.eINSTANCE

	@Test
	def void testBasicSpan() {
		val k0 = createEClass => [
			name = "K0"
		]
		val kernel = createEPackage => [
			name = "KernelPackage"
			EClassifiers += #[k0]
		]

		val l0 = createEClass => [
			name = "L0"
		]
		val l1 = createEClass => [
			name = "L1"
		]
		val left = createEPackage => [
			name = "LeftPackage"
			EClassifiers += #[l0, l1]
		]

		val r0 = createEClass => [
			name = "R0"
		]
		val r1 = createEClass => [
			name = "R1"
		]
		val right = createEPackage => [
			name = "RightPackage"
			EClassifiers += #[r0, r1]
		]
		
		val Map<EObject, EObject> leftMapping = #{k0 -> l0}
		val Map<EObject, EObject> rightMapping = #{k0 -> r0}
		
		val mergeSets = new ModelSpan(leftMapping, rightMapping, kernel, left, right).calculateMergeSet
		
		assertEquals("Expected only two merge sets to be produced", 2, mergeSets.size)
		
		
		
	}
}
