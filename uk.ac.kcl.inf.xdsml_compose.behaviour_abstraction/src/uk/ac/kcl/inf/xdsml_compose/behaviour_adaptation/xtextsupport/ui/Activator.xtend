package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.xtextsupport.ui

import com.google.inject.Guice
import com.google.inject.Injector
import com.google.inject.util.Modules
import org.eclipse.ui.plugin.AbstractUIPlugin
import org.eclipse.xtext.ui.shared.SharedStateModule
import org.osgi.framework.BundleContext
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.xtextsupport.BehaviourAdaptationRuntimeModule

class Activator extends AbstractUIPlugin {
	
	public static val PLUGIN_ID = "uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation"

	static Activator plugin

	Injector injector

	new() { }

	def Injector getInjector() {
		return injector
	}

	def private void initializeInjector() {
		injector = Guice.createInjector(
			Modules.^override(Modules.^override(new BehaviourAdaptationRuntimeModule()).with(new BehaviourAdaptationUiModule(plugin))).with(
				new SharedStateModule()))
	}

	override start(BundleContext context) throws Exception {
		super.start(context)
		plugin = this
		initializeInjector()
	}

	override void stop(BundleContext context) throws Exception {
		plugin = null
		injector = null
		super.stop(context)
	}

	def static Activator getDefault() {
		return plugin
	}
}
