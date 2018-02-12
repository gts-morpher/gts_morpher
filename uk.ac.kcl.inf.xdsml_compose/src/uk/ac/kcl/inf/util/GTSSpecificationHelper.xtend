package uk.ac.kcl.inf.util

import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.henshin.model.Module
import uk.ac.kcl.inf.xDsmlCompose.GTSFamilyChoice
import uk.ac.kcl.inf.xDsmlCompose.GTSLiteral
import uk.ac.kcl.inf.xDsmlCompose.GTSSelection
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecification

class GTSSpecificationHelper {
	static dispatch def EPackage getMetamodel(GTSSpecification spec) {
		spec.gts.metamodel
	}
	
	static dispatch def EPackage getMetamodel(GTSSelection gts) { null }
	static dispatch def EPackage getMetamodel(GTSLiteral gts) { gts.metamodel }
	static dispatch def EPackage getMetamodel(GTSFamilyChoice gts) { 
		// FIXME: Actually perform transformation, preferably using a cache of sorts :-)
		gts.root.metamodel
	}
	static dispatch def EPackage getMetamodel(Void spec) { null }

	static dispatch def Module getBehaviour(GTSSpecification spec) {
		spec.gts.behaviour			
	}	
	static dispatch def Module getBehaviour(GTSSelection gts) { null }
	static dispatch def Module getBehaviour(GTSLiteral gts) { gts.behaviour }
	static dispatch def Module getBehaviour(GTSFamilyChoice gts) { 
		// FIXME: Actually perform transformation, preferably using a cache of sorts :-)
		gts.root.behaviour
	}
	static dispatch def Module getBehaviour(Void spec) { null }
}