/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import java.util.Collection;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.util.InternalEList;
import org.eclipse.emf.henshin.model.Edge;
import org.eclipse.emf.henshin.model.Node;
import org.eclipse.emf.henshin.model.impl.NodeImpl;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.DelegatingTranslatingEcoreEList;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.EObjectTranslator;

/**
 * <!-- begin-user-doc --> An implementation of the model object
 * '<em><b>Object</b></em>'. <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.ObjectImpl#getType
 * <em>Type</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.ObjectImpl#getOutgoing
 * <em>Outgoing</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.ObjectImpl#getIncoming
 * <em>Incoming</em>}</li>
 * </ul>
 *
 * @not-generated
 */
public class ObjectImpl extends NamedElementImpl implements uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object {

	/**
	 * The cached value of the '{@link #getOutgoing() <em>Outgoing</em>}' reference
	 * list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getOutgoing()
	 * @generated
	 * @ordered
	 */
	protected EList<Link> outgoing;

	/**
	 * The cached value of the '{@link #getIncoming() <em>Incoming</em>}' reference
	 * list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getIncoming()
	 * @generated
	 * @ordered
	 */
	protected EList<Link> incoming;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	protected ObjectImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.OBJECT;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EClass getType() {
		return ((Node) wrappedElement).getType();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EClass basicGetType() {
		return ((NodeImpl) wrappedElement).basicGetType();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public void setType(EClass newType) {
		EClass oldType = getType();
		((Node) wrappedElement).setType(newType);
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.OBJECT__TYPE, oldType,
					newType));
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EList<Link> getOutgoing() {
		if (outgoing == null) {
			// TODO: Need a slightly different list implementation that knows how to resolve
			// to the correct Link instance such that forward and backward references are
			// via the same objects
			outgoing = new DelegatingTranslatingEcoreEList<Link, Edge>(this,
					Behaviour_adaptationPackage.OBJECT__OUTGOING, ((Node) wrappedElement).getOutgoing(), (edge) -> {
						return EObjectTranslator.INSTANCE.createLinkFor(edge);
					});
		}
		return outgoing;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EList<Link> getIncoming() {
		if (incoming == null) {
			// TODO: Need a slightly different list implementation that knows how to resolve
			// to the correct Link instance such that forward and backward references are
			// via the same objects
			incoming = new DelegatingTranslatingEcoreEList<Link, Edge>(this,
					Behaviour_adaptationPackage.OBJECT__INCOMING, ((Node) wrappedElement).getIncoming(), (edge) -> {
						return EObjectTranslator.INSTANCE.createLinkFor(edge);
					});
		}
		return incoming;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public NotificationChain eInverseAdd(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
		case Behaviour_adaptationPackage.OBJECT__OUTGOING:
			return ((InternalEList<InternalEObject>) (InternalEList<?>) getOutgoing()).basicAdd(otherEnd, msgs);
		case Behaviour_adaptationPackage.OBJECT__INCOMING:
			return ((InternalEList<InternalEObject>) (InternalEList<?>) getIncoming()).basicAdd(otherEnd, msgs);
		}
		return super.eInverseAdd(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
		case Behaviour_adaptationPackage.OBJECT__OUTGOING:
			return ((InternalEList<?>) getOutgoing()).basicRemove(otherEnd, msgs);
		case Behaviour_adaptationPackage.OBJECT__INCOMING:
			return ((InternalEList<?>) getIncoming()).basicRemove(otherEnd, msgs);
		}
		return super.eInverseRemove(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
		case Behaviour_adaptationPackage.OBJECT__TYPE:
			if (resolve)
				return getType();
			return basicGetType();
		case Behaviour_adaptationPackage.OBJECT__OUTGOING:
			return getOutgoing();
		case Behaviour_adaptationPackage.OBJECT__INCOMING:
			return getIncoming();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
		case Behaviour_adaptationPackage.OBJECT__TYPE:
			setType((EClass) newValue);
			return;
		case Behaviour_adaptationPackage.OBJECT__OUTGOING:
			getOutgoing().clear();
			getOutgoing().addAll((Collection<? extends Link>) newValue);
			return;
		case Behaviour_adaptationPackage.OBJECT__INCOMING:
			getIncoming().clear();
			getIncoming().addAll((Collection<? extends Link>) newValue);
			return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
		case Behaviour_adaptationPackage.OBJECT__TYPE:
			setType((EClass) null);
			return;
		case Behaviour_adaptationPackage.OBJECT__OUTGOING:
			getOutgoing().clear();
			return;
		case Behaviour_adaptationPackage.OBJECT__INCOMING:
			getIncoming().clear();
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
		case Behaviour_adaptationPackage.OBJECT__TYPE:
			return getType() != null;
		case Behaviour_adaptationPackage.OBJECT__OUTGOING:
			return outgoing != null && !outgoing.isEmpty();
		case Behaviour_adaptationPackage.OBJECT__INCOMING:
			return incoming != null && !incoming.isEmpty();
		}
		return super.eIsSet(featureID);
	}

	@Override
	public String getName() {
		return ((Node) wrappedElement).getName();
	}

	@Override
	protected void internalSetName(String newname) {
		((Node) wrappedElement).setName(newname);
	}

} // ObjectImpl