package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util

import org.eclipse.emf.ecore.EObject
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.WrappingElement

interface IWrapperFactory {
	
	def WrappingElement createWrapperFor(EObject object)
	
}