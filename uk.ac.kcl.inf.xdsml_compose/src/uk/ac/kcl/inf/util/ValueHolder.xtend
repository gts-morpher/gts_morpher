package uk.ac.kcl.inf.util

import org.eclipse.xtend.lib.annotations.Accessors

class ValueHolder<T> {
	@Accessors
	var T value
	
	new (T value) {
		setValue(value)
	}
}
