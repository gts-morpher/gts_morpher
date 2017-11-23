/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf

import com.google.inject.Injector
import org.eclipse.xtext.ecore.EcoreSupport
import uk.ac.kcl.inf.henshin.HenshinSupport

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class XDsmlComposeStandaloneSetup extends XDsmlComposeStandaloneSetupGenerated {

	def static void doSetup() {
		new XDsmlComposeStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
	
	override register(Injector injector) {
        super.register(injector);
        new EcoreSupport().registerServices(true);
        new HenshinSupport().registerServices(true);
    }
}
