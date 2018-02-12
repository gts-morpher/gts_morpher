package uk.ac.kcl.inf.util

import java.util.HashSet
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.Resource
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
		gts.derivePickedGTS.key
	}
	static dispatch def EPackage getMetamodel(Void spec) { null }

	static dispatch def Module getBehaviour(GTSSpecification spec) {
		spec.gts.behaviour			
	}	
	static dispatch def Module getBehaviour(GTSSelection gts) { null }
	static dispatch def Module getBehaviour(GTSLiteral gts) { gts.behaviour }
	static dispatch def Module getBehaviour(GTSFamilyChoice gts) { 
		gts.derivePickedGTS.value
	}
	static dispatch def Module getBehaviour(Void spec) { null }
	
	private static val familyCache = new MultiResourceOnChangeEvictingCache
	private static val FAMILY_CONTENTS_KEY = "FAMILY_CONTENTS_KEY"
	
	static def Pair<EPackage, Module> derivePickedGTS(GTSFamilyChoice gts) {
		familyCache.get(new Pair(FAMILY_CONTENTS_KEY, gts), getSetOfResources(gts.root.metamodel, gts.root.behaviour, gts.transformers), [
			// FIXME: Actually perform transformation
			new Pair(gts.root.metamodel, gts.root.behaviour)
		])		
	}
	
	private static def getSetOfResources(EPackage metamodel, Module behaviour, Module transformers) {
		val resources = new HashSet<Resource>
		#[metamodel, behaviour, transformers].forEach[eo | 
			if (eo !== null) {
				resources.add(eo.eResource)
			}
		]
		
		resources		
	}
}