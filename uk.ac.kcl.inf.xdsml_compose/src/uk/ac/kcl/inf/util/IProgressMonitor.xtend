package uk.ac.kcl.inf.util

import org.eclipse.xtext.util.CancelIndicator

interface IProgressMonitor extends CancelIndicator {
	
	def IProgressMonitor convert (int units)
	def IProgressMonitor split (String taskName, int units)

	public static val NULL_IMPL = new IProgressMonitor() {

		override isCanceled() { false }
		
		override convert(int units) { this }
		
		override split(String taskName, int units) { this }
	}
}
