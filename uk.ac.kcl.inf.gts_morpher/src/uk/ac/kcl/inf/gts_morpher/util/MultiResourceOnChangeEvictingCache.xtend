package uk.ac.kcl.inf.gts_morpher.util

import com.google.inject.Provider
import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Map
import java.util.Set
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.common.notify.Notification
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.Resource.Diagnostic
import org.eclipse.emf.ecore.util.EContentAdapter
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Cache that depends on the state of multiple resources. Cache will get cleared whenever any one of the resources changes.
 */
class MultiResourceOnChangeEvictingCache {
	/**
	 * Try to obtain a value for the given key using a cache dependent on the resources named. 
	 * If no value is available for key, use the given provider to generate one.
	 */
	def <T> T get(Object key, Set<Resource> resources, Provider<T> provider) {
		if (resources === null) {
			return provider.get
		}
		
		val _resources = resources.reject[r | r === null]
		if (_resources.empty) {
			return provider.get
		}
		
		val cache = resources.getOrCreateCache
		
		var T result = cache.get(key) as T
		if (result === null) {
			result = provider.get
			cache.set(key, result)
		}
		if (result === Cache.NULL) {
			null
		} else {
			result			
		}
	}
	
	def Cache getOrCreateCache(Set<Resource> resources) {
		val adapters = resources.map[r |
			var adapter = EcoreUtil.getAdapter(r.eAdapters, CacheAdapter) as CacheAdapter
			
			if (adapter === null) {
				adapter = new CacheAdapter
				r.eAdapters.add(adapter)
			}
			
			adapter
		].toList
		val caches = adapters.map[a | a.caches]
		var cacheList = caches.reduce[l1, l2| l1.filter[c | l2.contains(c)].toList]
		
		if (cacheList.empty) {
			val cache = new Cache
			cacheList = new ArrayList<Cache>
			cacheList.add(cache)
			
			caches.forEach[c | c.add(cache)]
		}
		if (cacheList.size > 1) {
			throw new IllegalStateException("Multiple caches for same combination of resources!")
		}
		
		cacheList.head
	}
	
	/**
	 * A cached item that needs special attention when clearing the cache.
	 */
	interface IClearableItem {
		/**
		 * Notify the item that it is being cleared from the cache. Any required cleanup should be undertaken here.
		 */
		def void onClearedFromCache()
	}
	
	private static class Cache {
		static val NULL = new Object
		val Map<Object, Object> values = new ConcurrentHashMap<Object, Object>()
		
		def Object get(Object key) {
			values.get(key)
		}
		
		def void set(Object key, Object value) {
			values.put(key, if (value === null) NULL else value)
		}
		
		def void clear() {
			values.values.filter(IClearableItem).forEach[c | c.onClearedFromCache]
			values.clear				
		}
	}
	
	private static class CacheAdapter extends EContentAdapter {
		@Accessors(PUBLIC_GETTER)
		List<Cache> caches = Collections.synchronizedList(new ArrayList<Cache>)
		
		override isAdapterForType(Object type) { type === class }
		
		override notifyChanged(Notification notification) {
			super.notifyChanged(notification)
			
			if (isSemanticStateChange(notification)) {
				caches.forEach[c | c.clear]
			}
		}
		
		override protected resolve() { false }
		
		private def isSemanticStateChange(Notification notification) {
			!notification.isTouch() && 
			!(notification.getNewValue() instanceof Diagnostic) && 
			!(notification.getOldValue() instanceof Diagnostic)
		}
	}
}
