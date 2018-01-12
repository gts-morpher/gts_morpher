/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.henshin.model.Edge;
import org.eclipse.emf.henshin.model.Node;
import org.eclipse.emf.henshin.model.impl.EdgeImpl;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.EObjectTranslator;

import static uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.HenshinNameAdapter.*;

/**
 * <!-- begin-user-doc --> An implementation of the model object
 * '<em><b>Link</b></em>'. <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.LinkImpl#getType
 * <em>Type</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.LinkImpl#getSource
 * <em>Source</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.LinkImpl#getTarget
 * <em>Target</em>}</li>
 * </ul>
 *
 * @not-generated
 */
public class LinkImpl extends NamedElementImpl implements Link {

	protected uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object source;
	protected uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object target;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	protected LinkImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.LINK;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EObject getType() {
		return safeWrappeeAccess((wrappedElement) -> { return ((Edge) wrappedElement).getType(); });
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EObject basicGetType() {
		return safeWrappeeAccess((wrappedElement) -> { return ((EdgeImpl) wrappedElement).basicGetType(); });
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public void setType(EObject newType) {
		EObject oldType = getType();
		safeWrappeeAccess((wrappedElement) -> { ((Edge) wrappedElement).setType((EReference) newType); });
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.LINK__TYPE, oldType,
					newType));
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object getSource() {
		if (source == null) {
			source = safeWrappeeAccess((wrappedElement) -> { return EObjectTranslator.INSTANCE.createObjectFor(((Edge) wrappedElement).getSource()); });
		}
		return source;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object basicGetSource() {
		Node n = safeWrappeeAccess((wrappedElement) -> { return ((EdgeImpl) wrappedElement).basicGetSource(); });
		if (n != null) {
			return EObjectTranslator.INSTANCE.createObjectFor(n);
		} else {
			return null;
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public NotificationChain basicSetSource(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object newSource,
			NotificationChain msgs) {
		uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object oldSource = source;

		source = newSource;
		final NotificationChain msgs2 = msgs;
		msgs = safeWrappeeAccess((wrappedElement) -> { return ((EdgeImpl) wrappedElement).basicSetSource((Node) ((ObjectImpl) newSource).safeWrappeeAccess((wrappedElement2) -> { return wrappedElement2; }), msgs2); });

		if (eNotificationRequired()) {
			ENotificationImpl notification = new ENotificationImpl(this, Notification.SET,
					Behaviour_adaptationPackage.LINK__SOURCE, oldSource, newSource);
			if (msgs == null)
				msgs = notification;
			else
				msgs.add(notification);
		}
		return msgs;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public void setSource(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object newSource) {
		if (newSource != source) {
			NotificationChain msgs = null;
			if (source != null)
				msgs = ((InternalEObject)source).eInverseRemove(this, Behaviour_adaptationPackage.OBJECT__OUTGOING, uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object.class, msgs);
			if (newSource != null)
				msgs = ((InternalEObject)newSource).eInverseAdd(this, Behaviour_adaptationPackage.OBJECT__OUTGOING, uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object.class, msgs);
			msgs = basicSetSource(newSource, msgs);
			if (msgs != null) msgs.dispatch();
		}
		else if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.LINK__SOURCE, newSource, newSource));
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object getTarget() {
		if (target == null) {
			target = safeWrappeeAccess((wrappedElement) -> { return EObjectTranslator.INSTANCE.createObjectFor(((Edge) wrappedElement).getTarget()); });
		}
		return target;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object basicGetTarget() {
		Node n = safeWrappeeAccess((wrappedElement) -> { return ((EdgeImpl) wrappedElement).basicGetTarget(); });
		if (n != null) {
			return EObjectTranslator.INSTANCE.createObjectFor(n);
		} else {
			return null;
		}
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public NotificationChain basicSetTarget(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object newTarget,
			NotificationChain msgs) {
		uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object oldTarget = target;

		target = newTarget;
		final NotificationChain msgs2 = msgs;
		msgs = safeWrappeeAccess((wrappedElement) -> { return ((EdgeImpl) wrappedElement).basicSetTarget((Node) ((ObjectImpl) newTarget).safeWrappeeAccess((wrappedElement2) -> { return wrappedElement2; }), msgs2); });

		if (eNotificationRequired()) {
			ENotificationImpl notification = new ENotificationImpl(this, Notification.SET,
					Behaviour_adaptationPackage.LINK__TARGET, oldTarget, newTarget);
			if (msgs == null)
				msgs = notification;
			else
				msgs.add(notification);
		}
		return msgs;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	public void setTarget(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object newTarget) {
		if (newTarget != target) {
			NotificationChain msgs = null;
			if (target != null)
				msgs = ((InternalEObject)target).eInverseRemove(this, Behaviour_adaptationPackage.OBJECT__INCOMING, uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object.class, msgs);
			if (newTarget != null)
				msgs = ((InternalEObject)newTarget).eInverseAdd(this, Behaviour_adaptationPackage.OBJECT__INCOMING, uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object.class, msgs);
			msgs = basicSetTarget(newTarget, msgs);
			if (msgs != null) msgs.dispatch();
		}
		else if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.LINK__TARGET, newTarget, newTarget));
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public NotificationChain eInverseAdd(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
			case Behaviour_adaptationPackage.LINK__SOURCE:
				if (source != null)
					msgs = ((InternalEObject)source).eInverseRemove(this, Behaviour_adaptationPackage.OBJECT__OUTGOING, uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object.class, msgs);
				return basicSetSource((uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)otherEnd, msgs);
			case Behaviour_adaptationPackage.LINK__TARGET:
				if (target != null)
					msgs = ((InternalEObject)target).eInverseRemove(this, Behaviour_adaptationPackage.OBJECT__INCOMING, uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object.class, msgs);
				return basicSetTarget((uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)otherEnd, msgs);
		}
		return super.eInverseAdd(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
			case Behaviour_adaptationPackage.LINK__SOURCE:
				return basicSetSource(null, msgs);
			case Behaviour_adaptationPackage.LINK__TARGET:
				return basicSetTarget(null, msgs);
		}
		return super.eInverseRemove(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case Behaviour_adaptationPackage.LINK__TYPE:
				if (resolve) return getType();
				return basicGetType();
			case Behaviour_adaptationPackage.LINK__SOURCE:
				if (resolve) return getSource();
				return basicGetSource();
			case Behaviour_adaptationPackage.LINK__TARGET:
				if (resolve) return getTarget();
				return basicGetTarget();
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
			case Behaviour_adaptationPackage.LINK__TYPE:
				setType((EObject)newValue);
				return;
			case Behaviour_adaptationPackage.LINK__SOURCE:
				setSource((uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)newValue);
				return;
			case Behaviour_adaptationPackage.LINK__TARGET:
				setTarget((uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)newValue);
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
			case Behaviour_adaptationPackage.LINK__TYPE:
				setType((EObject)null);
				return;
			case Behaviour_adaptationPackage.LINK__SOURCE:
				setSource((uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)null);
				return;
			case Behaviour_adaptationPackage.LINK__TARGET:
				setTarget((uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)null);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
		case Behaviour_adaptationPackage.LINK__TYPE:
			return getType() != null;
		case Behaviour_adaptationPackage.LINK__SOURCE:
			return getSource() != null;
		case Behaviour_adaptationPackage.LINK__TARGET:
			return getTarget() != null;
		}
		return super.eIsSet(featureID);
	}

	@Override
	public String getName() {
		return safeWrappeeAccess((wrappedElement) -> { 
			return name((Edge) wrappedElement);
		});
	}

	@Override
	protected void internalSetName(String newname) {
		throw new UnsupportedOperationException("Cannot set link name via adaptation layer");
	}

} // LinkImpl