package uk.ac.kcl.inf.util

import org.eclipse.xtend.lib.annotations.Data

@Data
class Triple<A, B, C> {
	val A a;
	val B b;
	val C c;
}