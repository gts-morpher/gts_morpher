package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util

import java.util.Map
import java.util.WeakHashMap
import org.eclipse.emf.ecore.resource.Resource

class ResourceCache {
	private static Map<Resource, Resource> cache = new WeakHashMap()

	static def Resource get(Resource srcResource) {
		if (!cache.containsKey(srcResource)) {
			println("Providing translating resource. ResourceSet is a " + srcResource.resourceSet.class.name);
			cache.put(srcResource, new TranslatingResource(srcResource));
		}

		cache.get(srcResource)
	}
}