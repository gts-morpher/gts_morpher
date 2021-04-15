package uk.ac.kcl.inf.gts_morpher.util

import java.util.ArrayList
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EModelElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.Attribute
import org.eclipse.emf.henshin.model.Edge
import org.eclipse.emf.henshin.model.GraphElement
import org.eclipse.emf.henshin.model.ModelElement
import org.eclipse.emf.henshin.model.Node
import org.eclipse.emf.henshin.model.Parameter

import static extension uk.ac.kcl.inf.util.henshinsupport.NamingHelper.*
import static extension uk.ac.kcl.inf.gts_morpher.util.ExpressionRewriter.*

class EMFHelper {

	static dispatch def getName(Void eo) ''''''
	
	static dispatch def getName(EObject eo) ''''''

	static dispatch def getName(EClass ec) { ec.name }

	static dispatch def getName(EReference er) { er.name }

	static dispatch def getName(EAttribute ea) { ea.name }

	static dispatch def getName(EPackage ep) { ep.name }
	
	static dispatch def getName(ModelElement me) { me.name() }

	static def CharSequence getQualifiedName(EObject eo) {
		if (eo.eContainer !== null) {
			'''«eo.eContainer.qualifiedName».«eo.getName()»'''
		} else {
			eo.getName()
		}
	}

	static def EObject findWithQualifiedName(EPackage pck, String qualifiedName) {
		var nameSegments = new ArrayList<String> (qualifiedName.split('\\.'))
		if (!pck.name.equals(nameSegments.remove(0))) {
			return null
		}

		var EObject next = pck
		for (segment : nameSegments) {
			next = next.eContents.findFirst[eo|eo.getName().equals(segment)]

			if (next === null) {
				return null
			}
		}

		if ((next instanceof EClassifier) || (next instanceof EReference)) {
			return next
		} else {
			null
		}
	}
	
	static dispatch def boolean isInterfaceElement(Void v) {
		false
	}

	static dispatch def boolean isInterfaceElement(EObject eo) {
		true
	}
	
	static dispatch def boolean isInterfaceElement(EModelElement em) {
		em.EAnnotations.exists[a | a.source.equalsIgnoreCase("Interface")]
	}
	
	static dispatch def boolean isInterfaceElement(GraphElement ge) {
		ge.type.isInterfaceElement
	}
	
	static dispatch def boolean isInterfaceElement(Parameter p) {
		if (p.type instanceof EClass) {
			p.type.isInterfaceElement
		} else {
			p.unit.eAllContents.filter(Attribute).exists[a | 
				a.isInterfaceElement &&
				a.value.referencesParameter(p)
			]
		}
	}
	
	static dispatch def getType(GraphElement ge) { null }
	static dispatch def getType(Node n) { n.type }
	static dispatch def getType(Edge e) { e.type }	
	static dispatch def getType(Attribute a) { a.type }	
}
