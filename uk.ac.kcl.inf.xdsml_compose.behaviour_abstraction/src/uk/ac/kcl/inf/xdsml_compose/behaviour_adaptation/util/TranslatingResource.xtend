package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util

import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.Collection
import java.util.ListIterator
import java.util.Map
import java.util.function.Consumer
import java.util.function.Function
import java.util.function.Supplier
import org.eclipse.emf.common.notify.Notification
import org.eclipse.emf.common.notify.NotificationChain
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.common.util.TreeIterator
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.WrappingElement
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.WrappingElementImpl

/**
 * A resource wrapping another resource and translating elements into wrapped elements.
 */
class TranslatingResource implements Resource.Internal {

	private Resource wrappedResource;
	// FIXME: Should really inject this
	private IWrapperFactory wrapperFactory = new HenshinWrapperFactory();

	new(Resource wrappedResource) {
		this.wrappedResource = wrappedResource
	}

	override getAllContents() {
		new TreeIterator<EObject>() {
			private TreeIterator<EObject> wrappedIterator = wrappedResource.allContents

			override prune() {
				wrappedIterator.prune
			}

			override hasNext() {
				wrappedIterator.hasNext
			}

			override next() {
				wrapperFactory.createWrapperFor(wrappedIterator.next)
			}
		}
	}

	private static class LI implements ListIterator<EObject> {
		// FIXME: Should really inject this
		private IWrapperFactory wrapperFactory = new HenshinWrapperFactory();
		private ListIterator<EObject> wrappedIterator

		new(ListIterator<EObject> wrappedIterator) {
			this.wrappedIterator = wrappedIterator
		}

		override add(EObject e) {
			delegate(e, [weo|wrappedIterator.add(weo)])
		}

		override hasNext() {
			wrappedIterator.hasNext
		}

		override hasPrevious() {
			wrappedIterator.hasPrevious
		}

		override next() {
			wrapperFactory.createWrapperFor(wrappedIterator.next)
		}

		override nextIndex() {
			wrappedIterator.nextIndex
		}

		override previous() {
			wrapperFactory.createWrapperFor(wrappedIterator.previous)
		}

		override previousIndex() {
			wrappedIterator.previousIndex
		}

		override remove() {
			wrappedIterator.remove
		}

		override set(EObject e) {
			delegate(e, [weo|wrappedIterator.set(weo)])
		}
	}

	override getContents() {

		new EList<EObject> {
			private EList<EObject> wrappedList = wrappedResource.contents

			override move(int newPosition, EObject object) {
				delegate(object, [weo|wrappedList.move(newPosition, weo)])
			}

			override move(int newPosition, int oldPosition) {
				wrappedList.move(newPosition, oldPosition)
			}

			override add(EObject e) {
				delegate(e, [we|wrappedList.add(we)], [false])
			}

			override add(int index, EObject element) {
				delegate(element, [we|wrappedList.add(index, we)])
			}

			override addAll(Collection<? extends EObject> c) {
				wrappedList.addAll(c.map[eo|delegate(eo, [weo|weo], [null])])
			}

			override addAll(int index, Collection<? extends EObject> c) {
				wrappedList.addAll(index, c.map[eo|delegate(eo, [weo|weo], [null])].toList)
			}

			override clear() {
				wrappedList.clear
			}

			override contains(Object o) {
				if (o instanceof EObject) {
					delegate(o as EObject, [weo|wrappedList.contains(weo)], [false])
				} else {
					false
				}
			}

			override containsAll(Collection<?> c) {
				c.forall[o|contains(o)]
			}

			override get(int index) {
				wrapperFactory.createWrapperFor(wrappedList.get(index))
			}

			override indexOf(Object o) {
				if (o instanceof EObject) {
					delegate(o as EObject, [weo|wrappedList.indexOf(weo)], [-1])
				} else {
					-1
				}
			}

			override isEmpty() {
				wrappedList.empty
			}

			override iterator() {
				wrappedList.iterator.map[eo|wrapperFactory.createWrapperFor(eo)]
			}

			override lastIndexOf(Object o) {
				if (o instanceof EObject) {
					delegate(o as EObject, [weo|wrappedList.lastIndexOf(weo)], [-1])
				} else {
					-1
				}
			}

			override listIterator() {
				new LI(wrappedList.listIterator)
			}

			override listIterator(int index) {
				new LI(wrappedList.listIterator(index))
			}

			override remove(Object o) {
				if (o instanceof EObject) {
					delegate(o as EObject, [weo|wrappedList.remove(weo)], [false])
				} else {
					false
				}
			}

			override remove(int index) {
				wrappedList.remove(index)
			}

			override removeAll(Collection<?> c) {
				wrappedList.removeAll(c.map [o |
					if (o instanceof EObject) {
						delegate(o as EObject, [weo | weo], [null])
					} else {
						null
					}
				])
			}

			override retainAll(Collection<?> c) {
				wrappedList.retainAll(c.map [o |
					if (o instanceof EObject) {
						delegate(o as EObject, [weo | weo], [null])
					} else {
						null
					}
				].toList)
			}

			override set(int index, EObject element) {
				delegate(element, [weo | wrappedList.set(index, element)], [null])
			}

			override size() {
				wrappedList.size
			}

			override subList(int fromIndex, int toIndex) {
				wrappedList.subList(fromIndex, toIndex).map[weo | wrapperFactory.createWrapperFor(weo)]
			}

			override toArray() {
				wrappedList.toArray.map[o | wrapperFactory.createWrapperFor(o as EObject)]
			}

			override <T> toArray(T[] a) {
				// TODO Not much to be done here, but hopefully won't need it anyway
				throw new UnsupportedOperationException("TODO: auto-generated method stub")
			}

		}
	}

	override getEObject(String uriFragment) {
		wrapperFactory.createWrapperFor(wrappedResource.getEObject(uriFragment))
	}

	override getURIFragment(EObject eObject) {
		delegate(eObject, [wrappedElement|wrappedResource.getURIFragment(wrappedElement)], [
			wrappedResource.getURIFragment(eObject)
		])
	}

	override attached(EObject eObject) {
		delegate(eObject, [wrappedElement|(wrappedResource as Resource.Internal).attached(wrappedElement)])
	}

	override basicSetResourceSet(ResourceSet resourceSet, NotificationChain notifications) {
		(wrappedResource as Resource.Internal).basicSetResourceSet(resourceSet, notifications)
	}

	override detached(EObject eObject) {
		delegate(eObject, [wrappedElement|(wrappedResource as Resource.Internal).detached(wrappedElement)])
	}

	override isLoading() {
		(wrappedResource as Resource.Internal).loading
	}

	override delete(Map<?, ?> options) throws IOException {
		wrappedResource.delete(options)
	}

	override getErrors() {
		wrappedResource.errors
	}

	override getResourceSet() {
		wrappedResource.resourceSet
	}

	override getTimeStamp() {
		wrappedResource.timeStamp
	}

	override getURI() {
		wrappedResource.URI
	}

	override getWarnings() {
		wrappedResource.warnings
	}

	override isLoaded() {
		wrappedResource.loaded
	}

	override isModified() {
		wrappedResource.modified
	}

	override isTrackingModification() {
		wrappedResource.trackingModification
	}

	override load(Map<?, ?> options) throws IOException {
		wrappedResource.load(options)
	}

	override load(InputStream inputStream, Map<?, ?> options) throws IOException {
		wrappedResource.load(inputStream, options)
	}

	override save(Map<?, ?> options) throws IOException {
		wrappedResource.save(options)
	}

	override save(OutputStream outputStream, Map<?, ?> options) throws IOException {
		wrappedResource.save(outputStream, options)
	}

	override setModified(boolean isModified) {
		wrappedResource.modified = isModified
	}

	override setTimeStamp(long timeStamp) {
		wrappedResource.timeStamp = timeStamp
	}

	override setTrackingModification(boolean isTrackingModification) {
		wrappedResource.trackingModification = isTrackingModification
	}

	override setURI(URI uri) {
		wrappedResource.URI = uri
	}

	override unload() {
		wrappedResource.unload
	}

	override eAdapters() {
		wrappedResource.eAdapters
	}

	override eDeliver() {
		wrappedResource.eDeliver
	}

	override eNotify(Notification notification) {
		wrappedResource.eNotify(notification)
	}

	override eSetDeliver(boolean deliver) {
		wrappedResource.eSetDeliver(deliver)
	}

	protected static def delegate(EObject object, Consumer<EObject> func) {
		if (object instanceof WrappingElement) {
			(object as WrappingElementImpl).safeWrappeeAccess(func)
		}
	}

	protected static def <T> T delegate(EObject object, Function<EObject, T> wrappedHandler,
		Supplier<T> unwrappedHandler) {
		if (object instanceof WrappingElement) {
			var tentativeResult = (object as WrappingElementImpl).safeWrappeeAccess(null, wrappedHandler)
			if (tentativeResult === null) {
				// This is a little bit of a hack, as it assumes that null is never a legal result
				tentativeResult = unwrappedHandler.get
			}
			tentativeResult
		} else {
			unwrappedHandler.get
		}
	}
}
