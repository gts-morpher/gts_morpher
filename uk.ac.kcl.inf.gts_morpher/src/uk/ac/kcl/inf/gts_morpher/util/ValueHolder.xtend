package uk.ac.kcl.inf.gts_morpher.util

import org.eclipse.xtend.lib.annotations.Accessors

class ValueHolder<T> {
	@Accessors
	var T value
	
	new (T value) {
		setValue(value)
	}
}
