package uk.ac.kcl.inf.gts_morpher.util

import org.eclipse.xtext.conversion.ValueConverterException
import org.eclipse.xtext.conversion.impl.INTValueConverter

/**
 * Allow negative integers.
 */
class MyINTValueConverter extends INTValueConverter {
	override assertValidValue(Integer value) {
		if (value === null) {
			throw new ValueConverterException(getRuleName() + " may not be null.", null, null)
		}
	}
}
