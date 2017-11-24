package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.xtextsupport;

import org.eclipse.xtext.naming.IQualifiedNameProvider;
import org.eclipse.xtext.resource.IDefaultResourceDescriptionStrategy;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceRuntimeModule;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.HenshinWrapperFactory;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.IWrapperFactory;

public class BehaviourAdaptationRuntimeModule extends AbstractGenericResourceRuntimeModule {

	@Override
	protected String getLanguageName() {
		return "uk.ac.kcl.inf.xdmsl_compose.behaviour.presentation.Behaviour_adaptationEditorID";//"org.eclipse.emf.henshin.presentation.HenshinEditorID";
	}

	@Override
	protected String getFileExtensions() {
		return "henshin"; // TODO Needs flexing by extensions
	}

	public Class<? extends IDefaultResourceDescriptionStrategy> bindIDefaultResourceDescriptionStrategy() {
		return BehaviourAdaptationResourceDescriptionStrategy.class;
	}
	
	public Class<? extends IWrapperFactory> bindIWrapperFactory() {
		return HenshinWrapperFactory.class;
	}
	
	@Override
	public Class<? extends IQualifiedNameProvider> bindIQualifiedNameProvider() {
		return BehaviourAdaptationQualifiedNameProvider.class;
	}
}