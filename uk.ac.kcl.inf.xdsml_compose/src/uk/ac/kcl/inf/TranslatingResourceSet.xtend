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

			result.translateIfNeeded
		}
	}

	override getResource(URI uri, boolean loadOnDemand) {
		synchronized (lock) {
			var result = super.getResource(uri, loadOnDemand)

			result.translateIfNeeded
		}
	}

	/**
	 * Wrap resource if needed
	 */
	private def Resource translateIfNeeded(Resource r) {
		if (r.needsTranslating) {
			println("Asking to be given translated resource")
			val translatedResource = ResourceCache.get(r)

			if (!resources.contains(translatedResource)) {
				resources.remove(r)
				resources.add(translatedResource)
			}

			return translatedResource
		} else {
			return r
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
