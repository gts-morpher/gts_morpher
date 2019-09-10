package uk.ac.kcl.inf.util

import com.google.inject.Provider
import java.util.Map
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.emf.common.notify.Notification
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource.Diagnostic
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.util.NonRecursiveEContentAdapter
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.util.OnChangeEvictingCache
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.common.notify.Notifier

/**
 * A cache that attaches to a specific EObject and invalidates when this EObject or any of it's contained EObjects changes. Essentially, a more discerning form of OnChangeEvictingCache.
 * 
 * TODO: Should probably add an option so that the cache automatically invalidates whenever referenced objects change that live outside of the current EObject.
 */
class EObjectOnChangeEvictingCache {

	/**
	 * Try to obtain the value that is cached for the given key and the given EObject. 
	 * 
	 * If no value is cached, the provider is used to compute it and store it afterwards.
	 * 
	 * @param object the object against which to cache. If it is <code>null</code>, the provider will be used to compute the value.
	 * @param key the cache key. May not be <code>null</code>.
	 * @param provider the strategy to compute the value if necessary. May not be <code>null</code>.
	 */
	def <T> T get(Object key, EObject object, Provider<T> provider) {
		if (object === null) {
			provider.get()
		} else {
			val CacheAdapter adapter = object.getOrCreate

			var element = adapter.<T>internal_get(key)

			if (element === null) {
				System.err.println('''Cache miss for object <«object»>\n and key <«key»>.''')
				element = provider.get()
				adapter.set(key, element)
			} else {
				System.err.println('''Cache hit for object <«object»>\n and key <«key»>.''')
			}

			if (element === CacheAdapter.NULL) {
				null
			} else {
				element
			}
		}
	}

	/**
	 * Finds the cache adapter for the given EObject or creates it if none exists yet.
	 */
	private def getOrCreate(EObject object) {
		var adapter = EcoreUtil.getAdapter(object.eAdapters, CacheAdapter) as CacheAdapter

		if (adapter === null) {
			// Look in resource first. If an adapter has been registered for some object in the same resource, we may want to reuse it
			// FIXME: This may actually be wrong: we will want to have multiple adapter objects for the same resource, potentially, as they may be attached to completely different subtrees and we don't want to have cross-talk...
			val resource = object.eResource
			adapter = EcoreUtil.getAdapter(resource.eAdapters, CacheAdapter) as CacheAdapter

			if (adapter === null) {
				adapter = new CacheAdapter
				resource.eAdapters += adapter
			}

			object.eAdapters += adapter
		}

		adapter
	}

	/**
	 * The actual cache adapter. We're extending OnChangeEvictingCache.CacheAdapter so that we can benefit from Xtext's built-in support for stopping cache evictions on relinking. 
	 * 
	 * However, we're stopping the adapter from attaching to everything in the resource.
	 */
	static class CacheAdapter extends OnChangeEvictingCache.CacheAdapter {
		/**
		 * Marker for "real" <code>null</code> values. Need to redo this because the internal_get methods are private in OnChangeEvictingCache.CacheAdapter... 
		 */
		static val NULL = new Object

		override set(Object key, Object value) {
			if (value !== null) {
				super.set(key, value)
			} else {
				super.set(key, NULL)
			}
		}

		protected def <T> T internal_get(Object key) {
			super.<T>get(key)
		}

		override <T> T get(Object key) {
			val result = <T>internal_get(key)

			if (result !== NULL) {
				result
			} else {
				null
			}
		}

//		override void notifyChanged(Notification notification) {
//			super.notifyChanged(notification)
//
//			if (notification.isSemanticStateChange) {
//				System.err.println('''Evicting cache on change to object <«notification.notifier»> (Event was: «notification.eventType»).''')
//				if (notification.feature instanceof EStructuralFeature) {
//					System.err.println('''Feature was <«(notification.feature as EStructuralFeature).name»>.''')					
//				}
//				System.err.println('''Old value was <«notification.oldValue»>.''')
//				System.err.println('''New value is <«notification.newValue»>.''')
//				clearValues()
//			}
//		}
		override void clearValues() {
			System.err.println("Clearing cache!")
			super.clearValues
		}

		override isAdapterForType(Object type) { type === class }

//
//		// TODO: Not sure this is correct...
//		override resolve() { false }
		protected override void selfAdapt(Notification notification) {
			val notifier = notification.notifier

			// Only update attachments on changes to EObjects, not resources
			if (!((notifier instanceof Resource) || (notifier instanceof ResourceSet))) {
				super.selfAdapt(notification)
			}
		}

		override setTarget(Notifier target) {
			// Only recursively attach to EObjects, not the entire resource
			if (!((target instanceof Resource) || (target instanceof ResourceSet))) {
				super.target = target
			} else {
				basicSetTarget(target)
			}
		}
	}
}
