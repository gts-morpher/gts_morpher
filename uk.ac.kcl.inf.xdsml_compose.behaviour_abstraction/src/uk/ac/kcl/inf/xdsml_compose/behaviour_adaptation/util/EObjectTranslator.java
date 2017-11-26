package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.util.IResourceScopeCache;
import org.eclipse.xtext.util.OnChangeEvictingCache;

import com.google.inject.Provider;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationFactory;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.WrappingElement;

public class EObjectTranslator {
	public static final EObjectTranslator INSTANCE = new EObjectTranslator();

	// Normally would inject this, but EObjectTranslator is never run through injection
	private final IResourceScopeCache cache = new OnChangeEvictingCache();
		
	private <T extends WrappingElement> T createWrapperFor(EObject object, Provider<T> wrapperCreator) {
		return cache.get(object, object.eResource(), () -> {
			T elt = wrapperCreator.get();
			elt.setWrappedElement(object);
			return elt;
		});
	}
	
	public Module createModuleFor(EObject object) {
		return createWrapperFor(object, () -> {
			return Behaviour_adaptationFactory.eINSTANCE.createModule();
		});
	}

	public Rule createRuleFor(EObject object) {
		return createWrapperFor(object, () -> {
			return Behaviour_adaptationFactory.eINSTANCE.createRule();
		});
	}

	public Pattern createPatternFor(EObject object) {
		return createWrapperFor(object, () -> {
			return Behaviour_adaptationFactory.eINSTANCE.createPattern();
		});
	}

	public Object createObjectFor(EObject object) {
		return createWrapperFor(object, () -> {
			return Behaviour_adaptationFactory.eINSTANCE.createObject();
		});
	}

	public Link createLinkFor(EObject object) {
		return createWrapperFor(object, () -> {
			return Behaviour_adaptationFactory.eINSTANCE.createLink();
		});
	}
}