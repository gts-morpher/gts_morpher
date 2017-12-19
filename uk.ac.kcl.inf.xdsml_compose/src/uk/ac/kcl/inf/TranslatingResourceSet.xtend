package uk.ac.kcl.inf

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.resource.SynchronizedXtextResourceSet
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.ResourceCache
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.TranslatingResource

class TranslatingResourceSet extends SynchronizedXtextResourceSet {
	override createResource(URI uri) {
		synchronized (lock) {
			var result = super.createResource(uri)

			// Potentially wrap resource if needed
			if (result.needsTranslating) {
				result = ResourceCache.get(result)
				if (!resources.contains(result)) {
					resources.add(result)
				}
			}

			result
		}
	}

	override getResource(URI uri, boolean loadOnDemand) {
		synchronized (lock) {
			var result = super.getResource(uri, loadOnDemand)

			// Potentially wrap resource if needed
			if (result.needsTranslating) {
				result = ResourceCache.get(result)
//				if (!resources.contains(result)) {
//					resources.add(result)
//				}
			}

			result
		}
	}
	
	private def needsTranslating(Resource r) {
		if ((r === null) || (r instanceof TranslatingResource)) {
			return false;
		}
		
		val uri = r.URI
		val fileExt = uri.fileExtension;
		
		// FIXME: Need to make this configurable
		((fileExt !== null) && (fileExt.equals("henshin")))
	}
}
