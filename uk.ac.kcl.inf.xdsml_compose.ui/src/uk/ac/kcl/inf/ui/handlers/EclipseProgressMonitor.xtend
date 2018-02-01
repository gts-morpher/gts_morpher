package uk.ac.kcl.inf.ui.handlers

import uk.ac.kcl.inf.util.IProgressMonitor
import org.eclipse.core.runtime.SubMonitor

class EclipseProgressMonitor implements IProgressMonitor {
	val org.eclipse.core.runtime.IProgressMonitor delegate
	
	new (org.eclipse.core.runtime.IProgressMonitor delegate) {
		this.delegate = delegate
	}
	
	override isCanceled() {
		delegate.canceled
	}
	
	override convert(int units) {
		return new EclipseProgressMonitor(SubMonitor.convert(delegate, units))
	}
	
	override split(String taskName, int units) {
		if (delegate instanceof SubMonitor) {
			delegate.taskName = taskName
			new EclipseProgressMonitor(delegate.split(units))			
		} else {
			this
		}
	}
}