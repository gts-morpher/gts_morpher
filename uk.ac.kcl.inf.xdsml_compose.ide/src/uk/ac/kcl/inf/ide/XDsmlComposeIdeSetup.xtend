/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.ide

import com.google.inject.Guice
import org.eclipse.xtext.util.Modules2
import uk.ac.kcl.inf.XDsmlComposeRuntimeModule
import uk.ac.kcl.inf.XDsmlComposeStandaloneSetup

/**
 * Initialization support for running Xtext languages as language servers.
 */
class XDsmlComposeIdeSetup extends XDsmlComposeStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new XDsmlComposeRuntimeModule, new XDsmlComposeIdeModule))
	}
	
}