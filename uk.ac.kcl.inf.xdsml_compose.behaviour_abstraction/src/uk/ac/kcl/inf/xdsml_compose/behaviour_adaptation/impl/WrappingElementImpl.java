/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import java.util.function.Consumer;
import java.util.function.Function;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.MinimalEObjectImpl;
import org.eclipse.emf.ecore.resource.Resource;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.WrappingElement;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.HenshinWrapperFactory;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.IWrapperFactory;

/**
 * <!-- begin-user-doc --> An implementation of the model object
 * '<em><b>Wrapping Element</b></em>'. <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.WrappingElementImpl#getWrappedElement <em>Wrapped Element</em>}</li>
 * </ul>
 *
 * @generated
 */
public abstract class WrappingElementImpl extends MinimalEObjectImpl.Container implements WrappingElement {
	/**
	 * The cached value of the '{@link #getWrappedElement() <em>Wrapped
	 * Element</em>}' reference. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getWrappedElement()
	 * @not-generated
	 * @ordered
	 */
	private EObject wrappedElement;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	protected WrappingElementImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.WRAPPING_ELEMENT;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public EObject getWrappedElement() {
		if (wrappedElement != null && wrappedElement.eIsProxy()) {
			InternalEObject oldWrappedElement = (InternalEObject)wrappedElement;
			wrappedElement = eResolveProxy(oldWrappedElement);
			if (wrappedElement != oldWrappedElement) {
				if (eNotificationRequired())
					eNotify(new ENotificationImpl(this, Notification.RESOLVE, Behaviour_adaptationPackage.WRAPPING_ELEMENT__WRAPPED_ELEMENT, oldWrappedElement, wrappedElement));
			}
		}
		return wrappedElement;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public EObject basicGetWrappedElement() {
		return wrappedElement;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public void setWrappedElement(EObject newWrappedElement) {
		EObject oldWrappedElement = wrappedElement;
		wrappedElement = newWrappedElement;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.WRAPPING_ELEMENT__WRAPPED_ELEMENT, oldWrappedElement, wrappedElement));
	}

	/**
	 * Allow safe access to features of the wrapped element. If there is a wrapped
	 * element (we are not a proxy), then calls func with it and returns the result.
	 * Otherwise, returns defaultValue.
	 * 
	 * @generatedNot
	 */
	protected <T> T safeWrappeeAccess(T defaultValue, Function<EObject, T> func) {
		if (!eIsProxy()) {
			if (wrappedElement == null) {
				System.err.println("No wrapped element, but not a proxy!");
				return defaultValue;
			} else {
				return func.apply(wrappedElement);
			}
		} else {
			return defaultValue;
		}
	}

	/**
	 * Allow safe access to features of the wrapped element. If there is a wrapped
	 * element (we are not a proxy), then calls func with it and returns the result.
	 * Otherwise, returns <code>null</code>.
	 * 
	 * @generatedNot
	 */
	protected <T> T safeWrappeeAccess(Function<EObject, T> func) {
		return safeWrappeeAccess(null, func);
	}

	/**
	 * Allow safe access to features of the wrapped element. If there is a wrapped
	 * element (we are not a proxy), then calls func with it.
	 * 
	 * @generatedNot
	 */
	protected void safeWrappeeAccess(Consumer<EObject> func) {
		if (!eIsProxy()) {
			if (wrappedElement == null) {
				System.err.println("No wrapped element, but not a proxy!");
			} else {
				func.accept(wrappedElement);
			}
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case Behaviour_adaptationPackage.WRAPPING_ELEMENT__WRAPPED_ELEMENT:
				if (resolve) return getWrappedElement();
				return basicGetWrappedElement();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case Behaviour_adaptationPackage.WRAPPING_ELEMENT__WRAPPED_ELEMENT:
				setWrappedElement((EObject)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case Behaviour_adaptationPackage.WRAPPING_ELEMENT__WRAPPED_ELEMENT:
				setWrappedElement((EObject)null);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case Behaviour_adaptationPackage.WRAPPING_ELEMENT__WRAPPED_ELEMENT:
				return wrappedElement != null;
		}
		return super.eIsSet(featureID);
	}

	/**
	 * Take the resource from the wrapped object. This is a bit of a hack, but
	 * should hopefully be enough to convince Xtext that this is a legit object.
	 * 
	 * @generatedNot
	 */
	@Override
	public Resource eResource() {
		return (wrappedElement != null) ? wrappedElement.eResource() : super.eResource();
	}

	// FIXME: Should really inject this
	private IWrapperFactory wrapperFactory = new HenshinWrapperFactory();

	/**
	 * Use the container from the wrapped element, if any
	 * 
	 * @generatedNot
	 */
	@Override
	public EObject eContainer() {
		return safeWrappeeAccess((wrappedElement) -> {
			EObject container = wrappedElement.eContainer();
			if (container != null) {
				return wrapperFactory.createWrapperFor(container);
			} else {
				return null;
			}
		});
	}
} // WrappingElementImpl
