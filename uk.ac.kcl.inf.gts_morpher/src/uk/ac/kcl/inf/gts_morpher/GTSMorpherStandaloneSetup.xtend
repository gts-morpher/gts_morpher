/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.gts_morpher

import com.google.inject.Injector
import org.eclipse.emf.henshin.adapters.xtext.HenshinSupport
import org.eclipse.xtext.ecore.EcoreSupport

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class GTSMorpherStandaloneSetup extends GTSMorpherStandaloneSetupGenerated {

	def static void doSetup() {
		new GTSMorpherStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
	
	override register(Injector injector) {
        super.register(injector);
        new EcoreSupport().registerServices(true);
        new HenshinSupport().registerServices(true);
    }
}
