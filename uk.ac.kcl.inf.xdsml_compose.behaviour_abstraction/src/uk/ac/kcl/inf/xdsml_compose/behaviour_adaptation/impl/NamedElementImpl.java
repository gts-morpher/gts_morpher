/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EClass;

import org.eclipse.emf.ecore.impl.ENotificationImpl;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.NamedElement;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Named Element</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.NamedElementImpl#getName <em>Name</em>}</li>
 * </ul>
 *
 * @not-generated
 */
public abstract class NamedElementImpl extends WrappingElementImpl implements NamedElement {

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected NamedElementImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.NAMED_ELEMENT;
	}

	/**
	 * To be overridden in child classes by forwarding suitably to the wrapped object.
	 * 
	 * @not-generated
	 */
	public abstract String getName();

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @not-generated
	 */
	public void setName(String newName) {
		String oldName = getName();
		internalSetName(newName);
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.NAMED_ELEMENT__NAME, oldName, newName));
	}
	
	/**
	 * To be overridden in child classes to set the name of the wrapped object.
	 *  
	 * @param newname
	 * @generatedNot
	 */
	protected abstract void internalSetName (String newname);

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case Behaviour_adaptationPackage.NAMED_ELEMENT__NAME:
				return getName();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case Behaviour_adaptationPackage.NAMED_ELEMENT__NAME:
				setName((String)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @not-generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case Behaviour_adaptationPackage.NAMED_ELEMENT__NAME:
				setName(null);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @not-generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case Behaviour_adaptationPackage.NAMED_ELEMENT__NAME:
				return getName() != null ;
		}
		return super.eIsSet(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @not-generated
	 */
	@Override
	public String toString() {
		if (eIsProxy()) return super.toString();

		StringBuffer result = new StringBuffer(super.toString());
		result.append(" (name: ");
		result.append(getName());
		result.append(')');
		return result.toString();
	}

} //NamedElementImpl
