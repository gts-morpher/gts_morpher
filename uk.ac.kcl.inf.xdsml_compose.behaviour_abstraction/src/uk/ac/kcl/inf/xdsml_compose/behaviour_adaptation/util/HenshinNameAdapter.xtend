package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util

import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.NamedElement

class HenshinNameAdapter {
	static dispatch def name(EObject eo) { null }
	static dispatch def name(NamedElement ne) { ne.name }
	static dispatch def name(Edge e) { '''[«e.source.name»->«e.target.name»:«e.type.name»]'''.toString }
}