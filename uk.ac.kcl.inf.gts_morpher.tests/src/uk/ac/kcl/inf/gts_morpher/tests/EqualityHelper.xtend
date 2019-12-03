package uk.ac.kcl.inf.gts_morpher.tests

import java.util.List
import java.util.function.Supplier
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.util.EcoreUtil

import static org.junit.Assert.*
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * An equality helper that provides better jUnit diagnostics for when things aren't equal. 
 */
class EqualityHelper extends EcoreUtil.EqualityHelper {
	static def void assertEObjectsEquals(String message, EObject expected, EObject actual) {
		new EqualityHelper(message).equals(expected, actual)
	}

	val String message
	@Accessors(PROTECTED_GETTER)
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
}
