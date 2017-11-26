/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.henshin.model.Graph;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.EObjectTranslator;

/**
 * <!-- begin-user-doc --> An implementation of the model object
 * '<em><b>Rule</b></em>'. <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.RuleImpl#getLhs
 * <em>Lhs</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.RuleImpl#getRhs
 * <em>Rhs</em>}</li>
 * </ul>
 *
 * @not-generated
 */
public class RuleImpl extends NamedElementImpl implements Rule {
	/**
	 * The cached value of the '{@link #getLhs() <em>Lhs</em>}' containment
	 * reference. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getLhs()
	 * @generated
	 * @ordered
	 */
	protected Pattern lhs;

	/**
	 * The cached value of the '{@link #getRhs() <em>Rhs</em>}' containment
	 * reference. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getRhs()
	 * @generated
	 * @ordered
	 */
	protected Pattern rhs;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	protected RuleImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.RULE;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public Pattern getLhs() {
		if (lhs == null) {
			lhs = EObjectTranslator.INSTANCE
					.createPatternFor(((org.eclipse.emf.henshin.model.Rule) wrappedElement).getLhs());
		}
		return lhs;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public NotificationChain basicSetLhs(Pattern newLhs, NotificationChain msgs) {
		Pattern oldLhs = lhs;

		((org.eclipse.emf.henshin.model.Rule) wrappedElement)
				.setLhs((newLhs != null) ? (Graph) ((PatternImpl) newLhs).wrappedElement : null);
		lhs = newLhs;

		if (eNotificationRequired()) {
			ENotificationImpl notification = new ENotificationImpl(this, Notification.SET,
					Behaviour_adaptationPackage.RULE__LHS, oldLhs, newLhs);
			if (msgs == null)
				msgs = notification;
			else
				msgs.add(notification);
		}
		return msgs;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	public void setLhs(Pattern newLhs) {
		if (newLhs != lhs) {
			NotificationChain msgs = null;
			if (lhs != null)
				msgs = ((InternalEObject) lhs).eInverseRemove(this,
						EOPPOSITE_FEATURE_BASE - Behaviour_adaptationPackage.RULE__LHS, null, msgs);
			if (newLhs != null)
				msgs = ((InternalEObject) newLhs).eInverseAdd(this,
						EOPPOSITE_FEATURE_BASE - Behaviour_adaptationPackage.RULE__LHS, null, msgs);
			msgs = basicSetLhs(newLhs, msgs);
			if (msgs != null)
				msgs.dispatch();
		} else if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.RULE__LHS, newLhs,
					newLhs));
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public Pattern getRhs() {
		if (rhs == null) {
			rhs = EObjectTranslator.INSTANCE
					.createPatternFor(((org.eclipse.emf.henshin.model.Rule) wrappedElement).getRhs());
		}
		return rhs;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public NotificationChain basicSetRhs(Pattern newRhs, NotificationChain msgs) {
		Pattern oldRhs = rhs;

		((org.eclipse.emf.henshin.model.Rule) wrappedElement)
				.setRhs((newRhs != null) ? (Graph) ((PatternImpl) newRhs).wrappedElement : null);
		rhs = newRhs;

		if (eNotificationRequired()) {
			ENotificationImpl notification = new ENotificationImpl(this, Notification.SET,
					Behaviour_adaptationPackage.RULE__RHS, oldRhs, newRhs);
			if (msgs == null)
				msgs = notification;
			else
				msgs.add(notification);
		}
		return msgs;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	public void setRhs(Pattern newRhs) {
		if (newRhs != rhs) {
			NotificationChain msgs = null;
			if (rhs != null)
				msgs = ((InternalEObject) rhs).eInverseRemove(this,
						EOPPOSITE_FEATURE_BASE - Behaviour_adaptationPackage.RULE__RHS, null, msgs);
			if (newRhs != null)
				msgs = ((InternalEObject) newRhs).eInverseAdd(this,
						EOPPOSITE_FEATURE_BASE - Behaviour_adaptationPackage.RULE__RHS, null, msgs);
			msgs = basicSetRhs(newRhs, msgs);
			if (msgs != null)
				msgs.dispatch();
		} else if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, Behaviour_adaptationPackage.RULE__RHS, newRhs,
					newRhs));
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
		case Behaviour_adaptationPackage.RULE__LHS:
			return basicSetLhs(null, msgs);
		case Behaviour_adaptationPackage.RULE__RHS:
			return basicSetRhs(null, msgs);
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
		case Behaviour_adaptationPackage.RULE__LHS:
			return getLhs();
		case Behaviour_adaptationPackage.RULE__RHS:
			return getRhs();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
		case Behaviour_adaptationPackage.RULE__LHS:
			setLhs((Pattern) newValue);
			return;
		case Behaviour_adaptationPackage.RULE__RHS:
			setRhs((Pattern) newValue);
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
		case Behaviour_adaptationPackage.RULE__LHS:
			setLhs((Pattern) null);
			return;
		case Behaviour_adaptationPackage.RULE__RHS:
			setRhs((Pattern) null);
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
		case Behaviour_adaptationPackage.RULE__LHS:
			return getLhs() != null;
		case Behaviour_adaptationPackage.RULE__RHS:
			return getRhs() != null;
		}
		return super.eIsSet(featureID);
	}

	@Override
	public String getName() {
		return ((org.eclipse.emf.henshin.model.Rule) wrappedElement).getName();
	}

	@Override
	protected void internalSetName(String newname) {
		((org.eclipse.emf.henshin.model.Rule) wrappedElement).setName(newname);
	}

} // RuleImpl
