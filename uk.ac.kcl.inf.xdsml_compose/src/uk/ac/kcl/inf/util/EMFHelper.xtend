package uk.ac.kcl.inf.util

import java.util.ArrayList
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.henshin.model.ModelElement

import static extension uk.ac.kcl.inf.util.henshinsupport.NamingHelper.*

class EMFHelper {

	static dispatch def getName(EObject eo) ''''''

	static dispatch def getName(EClass ec) { ec.name }

	static dispatch def getName(EReference er) { er.name }

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
		var currentPackage = pck

		if (!pck.name.equals(nameSegments.remove(0))) {
			return null
		}

		var EObject next = null

		for (segment : nameSegments) {
			if (currentPackage === null) {
				return null
			}
			next = currentPackage.eContents.findFirst[eo|eo.getName().equals(segment)]

			if (next === null) {
				return null
			} else if (next instanceof EPackage) {
				currentPackage = next as EPackage
			} else {
				currentPackage = null
			}
		}

		if ((next instanceof EClassifier) || (next instanceof EReference)) {
			return next
		} else {
			null
		}
	}
}
