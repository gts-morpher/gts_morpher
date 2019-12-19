package uk.ac.kcl.inf.gts_morpher.tests

import java.util.List
import java.util.function.Supplier
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtend.lib.annotations.Accessors

import static org.junit.Assert.*

/**
 * An equality helper that provides better jUnit diagnostics for when things aren't equal. 
 */
class EqualityHelper extends EcoreUtil.EqualityHelper {
	val String message
	@Accessors(PROTECTED_SETTER, PROTECTED_GETTER)
	var boolean throwExceptionOnError = true

	new(String message) {
		this.message = message
	}

	override boolean equals(EObject expected, EObject actual) {
		val areEqual = super.equals(expected, actual)

		if (throwExceptionOnError) {
			if (!areEqual) {
				fail(format(expected, actual))
			}
		}

		areEqual
	}

	override protected haveEqualFeature(EObject expected, EObject actual, EStructuralFeature feature) {
		val areEqual = super.haveEqualFeature(expected, actual, feature)

		if (throwExceptionOnError) {
			if (!areEqual) {
				fail(feature.format(expected, actual))
			}
		}

		areEqual
	}

	override protected haveEqualReference(EObject expected, EObject actual, EReference reference) {
//			if (reference.ordered) {
//				super.haveEqualReference(eObject1, eObject2, reference)
//			} else {
		val Object value1 = expected.eGet(reference);
		val Object value2 = actual.eGet(reference);

		if (reference.many) {
			val expectedList = value1 as List<EObject>
			val actualList = value2 as List<EObject>
			val result = equalsUnordered(expectedList, actualList)

			if (!result && throwExceptionOnError) {
				// Try to get us a better error message
				val unmatchedElements = runProtected[
					new Pair<List<EObject>, List<EObject>>(expectedList.reject [ eo |
						actualList.exists[eo2|equals(eo, eo2)]
					].toList, actualList.reject[eo|expectedList.exists[eo2|equals(eo, eo2)]].toList)
				]

				if (unmatchedElements.key.size == unmatchedElements.value.size) {
					// Attempt to find matches where all attributes match, but there may be a difference further down the graph
					val deeplyUnmatchedElements = runProtected[
						new Pair<List<Pair<EObject, EObject>>, List<Pair<EObject, EObject>>>(
							unmatchedElements.key.map [ eo |
								new Pair<EObject, EObject>(eo, unmatchedElements.value.filter [ eo2 |
									(eo.eClass === eo2.eClass) && (eo.eClass.EAllAttributes.forall [ attr |
										haveEqualAttribute(eo, eo2, attr)
									])
								].head)
							].toList,
							unmatchedElements.value.map [ eo |
								new Pair<EObject, EObject>(eo, unmatchedElements.key.filter [ eo2 |
									(eo.eClass === eo2.eClass) && (eo.eClass.EAllAttributes.forall [ attr |
										haveEqualAttribute(eo2, eo, attr)
									])
								].head)
							].toList
						)
					]

					// Now execute the comparisons again in unprotected mode, throwing exceptions at the deepest level that's meaningful
					deeplyUnmatchedElements.key.filter[value !== null].forEach[p|equals(p.key, p.value)]
					deeplyUnmatchedElements.value.filter[value !== null].forEach[p|equals(p.key, p.value)]
				}

				// If all unmatching elements are shallowly unmatched, report that
				fail(format(expected, unmatchedElements.key, actual, unmatchedElements.value, reference))
			}

			result
		} else {
			equals(value1 as EObject, value2 as EObject)
		}
//			}
	}

	/**
	 * Run the given function without throwing any exceptions if inequalities are encountered.
	 */
	protected final def <T> T runProtected(Supplier<T> function) {
		val oldThrowExceptionOnError = throwExceptionOnError
		throwExceptionOnError = false

		val result = function.get

		throwExceptionOnError = oldThrowExceptionOnError

		result
	}

	private def String format(EStructuralFeature feature, EObject expected, EObject actual) {
		var String formatted = getMessage

		formatted +=
			"Object " + actual.formatClassAndValue + " differed from expected object " + expected.formatClassAndValue +
				" in feature " + feature.name + ".\n"

		var String expectedString
		var String actualString

		if (feature.many) {
			expectedString = "[" + (expected.eGet(feature) as List).map[formatClassAndValue].join(", ") + "]"
			actualString = "[" + (actual.eGet(feature) as List).map[formatClassAndValue].join(", ") + "]"
		} else {
			expectedString = expected.eGet(feature).formatClassAndValue
			actualString = actual.eGet(feature).formatClassAndValue
		}

		formatted + "Expected " + expectedString + " but was " + actualString
	}

	private def String format(EObject expected, EObject actual) {
		var String formatted = getMessage

		formatted + "expected: " + expected.formatClassAndValue + " but was: " + actual.formatClassAndValue
	}

	protected def getMessage() {
		if (message !== null && message != "") {
			message + " "
		} else {
			""
		}
	}

	protected dispatch def String formatClassAndValue(Void value) { "NULL" }

	protected dispatch def String formatClassAndValue(Object value) {
		val className = value === null ? "null" : value.class.name
		val valueString = value === null ? "null" : String.valueOf(value)

		className + "<" + valueString + ">"
	}

	protected dispatch def String formatClassAndValue(EObject value) {
		val className = value === null ? "null" : value.eClass.name
		val valueString = value === null ? "null" : value.eClass.EAllAttributes.map[attr|value.eGet(attr)?.toString].
				join(", ")

		className + "<" + valueString + ">"
	}

	protected def equalsUnordered(List<EObject> expected, List<EObject> actual) {
		runProtected[
			(expected.size == actual.size) && expected.forall[eo|actual.exists[eo2|equals(eo, eo2)]] && actual.forall [ eo |
				expected.exists[eo2|equals(eo, eo2)]
			]
		]
	}

	private def String format(EObject expected, List<? extends EObject> expectedList, EObject actual,
		List<? extends EObject> actualList, EReference reference) {
		val formatted = getMessage

		formatted + "Couldn't match elements referenced by EReference " + reference.name + ".\n" + "Expected object " +
			expected.formatClassAndValue + " had the following unmatched elements: [" + expectedList.map [
				formatClassAndValue
			].join(", ") + "].\n" + "Actual object " + actual.formatClassAndValue +
			" had the following unmatched elements: [" + actualList.map [
				formatClassAndValue
			].join(", ") + "]."
	}
}
