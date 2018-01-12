package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.xtextsupport

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.util.IResourceScopeCache
import org.eclipse.xtext.util.Tuples

import static extension uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.HenshinNameAdapter.*

class BehaviourAdaptationQualifiedNameProvider extends IQualifiedNameProvider.AbstractImpl {
	
	private static val BEHAVIOUR_ADAPTATION_CACHE_KEY ="BEHAVIOUR_ADAPTATION_CACHE_KEY"
	
	@Inject
	private val IResourceScopeCache cache = IResourceScopeCache.NullImpl.INSTANCE;
	
	override getFullyQualifiedName(EObject obj) {
		cache.get(Tuples.pair(obj, BEHAVIOUR_ADAPTATION_CACHE_KEY), obj.eResource(), [
			val name = obj.name
			
			if (name === null) {
				null
			} else {
				val qualifiedName = QualifiedName.create(name)
				if (obj.eContainer !== null) {
					val parentsQualifiedName = getFullyQualifiedName(obj.eContainer)
					if (parentsQualifiedName === null) {
						null
					} else {
						parentsQualifiedName.append(qualifiedName)	
					}
				} else {
					qualifiedName
				}
				
			}
		])
	}	
}
