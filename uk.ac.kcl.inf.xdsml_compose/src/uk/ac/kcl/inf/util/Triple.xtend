package uk.ac.kcl.inf.util

import org.eclipse.xtend.lib.annotations.Data

@Data
public class Triple<S1, S2, S3> {
	private val S1 first
	private val S2 second
	private val S3 third
}
