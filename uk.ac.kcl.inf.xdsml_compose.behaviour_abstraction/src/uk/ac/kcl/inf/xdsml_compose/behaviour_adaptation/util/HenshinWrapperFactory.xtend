package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.henshin.model.HenshinPackage

class HenshinWrapperFactory implements IWrapperFactory {
	
	override createWrapperFor(EObject object) {
		switch(object.eClass) {
			case HenshinPackage.Literals.MODULE:
				return EObjectTranslator.INSTANCE.createModuleFor(object)
			case HenshinPackage.Literals.RULE:
				return EObjectTranslator.INSTANCE.createRuleFor(object)
			case HenshinPackage.Literals.GRAPH:
				return EObjectTranslator.INSTANCE.createPatternFor(object)
			case HenshinPackage.Literals.NODE:
				return EObjectTranslator.INSTANCE.createObjectFor(object)
			case HenshinPackage.Literals.EDGE:
				return EObjectTranslator.INSTANCE.createLinkFor(object)
			default:
				return null
		}
	}
}