package uk.ac.kcl.inf.util

import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference

class EMFHelper {
		
	static dispatch def getName(EObject eo) ''''''
	static dispatch def getName(EClass ec) { ec.name }
	static dispatch def getName(EReference er) { er.name }
	static dispatch def getName(EPackage ep) { ep.name }
	
	static def CharSequence getQualifiedName(EObject eo) {
		if (eo.eContainer !== null) {
			'''«eo.eContainer.qualifiedName».«eo.name»'''
		} else {
			eo.name
		}
	}
}