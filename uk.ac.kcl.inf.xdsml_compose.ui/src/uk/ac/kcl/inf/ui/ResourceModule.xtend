package uk.ac.kcl.inf.ui

import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.service.AbstractGenericModule
import uk.ac.kcl.inf.TranslatingResourceSet

/**
 * Unfortunately, this doesn't work as XtextResourceSet is already bound in a private module, so cannot be reliably rebound.
 */
class ResourceModule extends AbstractGenericModule {
	def Class<? extends XtextResourceSet> bindXtextResourceSet() {
		TranslatingResourceSet
	}
}