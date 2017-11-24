package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util;

import org.eclipse.emf.ecore.EObject;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationFactory;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule;

public class EObjectTranslator {
	public static final EObjectTranslator INSTANCE = new EObjectTranslator();

	public Module createModuleFor(EObject object) {
		Module module = Behaviour_adaptationFactory.eINSTANCE.createModule();
		module.setWrappedElement(object);
		return module;
	}

	public Rule createRuleFor(EObject object) {
		Rule rule = Behaviour_adaptationFactory.eINSTANCE.createRule();
		rule.setWrappedElement(object);
		return rule;
	}

	public Pattern createPatternFor(EObject object) {
		Pattern pattern = Behaviour_adaptationFactory.eINSTANCE.createPattern();
		pattern.setWrappedElement(object);
		return pattern;
	}

	public Object createObjectFor(EObject object) {
		Object result = Behaviour_adaptationFactory.eINSTANCE.createObject();
		result.setWrappedElement(object);
		return result;
	}

	public Link createLinkFor(EObject object) {
		Link result = Behaviour_adaptationFactory.eINSTANCE.createLink();
		result.setWrappedElement(object);
		return result;
	}
}