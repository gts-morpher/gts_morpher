package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.xtextsupport;

import org.eclipse.xtext.ISetup;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceSupport;

import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;

/**
 * Class meant to be used from MWE workflows or standalone setups to register behaviour adaptation support services.
 * 
 * @author k1074611
 */
public class BehaviourAdaptationSupport extends AbstractGenericResourceSupport implements ISetup {

	@Override
	protected Module createGuiceModule() {
		return new BehaviourAdaptationRuntimeModule();
	}

	/**
	 * @since 2.5
	 */
	@Override
	public Injector createInjectorAndDoEMFRegistration() {
		Injector injector = Guice.createInjector(getGuiceModule());
		injector.injectMembers(this);
		registerInRegistry(false);
		return injector;
	}
}