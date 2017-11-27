/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import java.util.Collection;

import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.util.InternalEList;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.DelegatingTranslatingEcoreEList;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.EObjectTranslator;

/**
 * <!-- begin-user-doc --> An implementation of the model object
 * '<em><b>Module</b></em>'. <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.ModuleImpl#getSubModules
 * <em>Sub Modules</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.ModuleImpl#getRules
 * <em>Rules</em>}</li>
 * </ul>
 *
 * @not-generated
 */
public class ModuleImpl extends NamedElementImpl implements Module {
	/**
	 * The cached value of the '{@link #getSubModules() <em>Sub Modules</em>}'
	 * containment reference list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getSubModules()
	 * @generated
	 * @ordered
	 */
	protected EList<Module> subModules;

	/**
	 * The cached value of the '{@link #getRules() <em>Rules</em>}' containment
	 * reference list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getRules()
	 * @generated
	 * @ordered
	 */
	protected EList<Rule> rules;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	protected ModuleImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.MODULE;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EList<Module> getSubModules() {
		if (subModules == null) {
			subModules = new DelegatingTranslatingEcoreEList<Module, org.eclipse.emf.henshin.model.Module>(this,
					Behaviour_adaptationPackage.MODULE__SUB_MODULES,
					safeWrappeeAccess((wrappedElement) -> { return ((org.eclipse.emf.henshin.model.Module) wrappedElement).getSubModules(); }),
					(henshinModule) -> {
						return EObjectTranslator.INSTANCE.createModuleFor(henshinModule);
					});
		}
		return subModules;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	public EList<Rule> getRules() {
		if (rules == null) {
			rules = new DelegatingTranslatingEcoreEList<Rule, org.eclipse.emf.henshin.model.Unit>(this,
					Behaviour_adaptationPackage.MODULE__RULES,
					safeWrappeeAccess((wrappedElement) -> { return ((org.eclipse.emf.henshin.model.Module) wrappedElement).getUnits(); }),
					(unit) -> {
						if (unit instanceof org.eclipse.emf.henshin.model.Rule) {
							return EObjectTranslator.INSTANCE.createRuleFor(unit);
						} else {
							return null;
						}
					});
		}
		return rules;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
		case Behaviour_adaptationPackage.MODULE__SUB_MODULES:
			return ((InternalEList<?>) getSubModules()).basicRemove(otherEnd, msgs);
		case Behaviour_adaptationPackage.MODULE__RULES:
			return ((InternalEList<?>) getRules()).basicRemove(otherEnd, msgs);
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
		case Behaviour_adaptationPackage.MODULE__SUB_MODULES:
			return getSubModules();
		case Behaviour_adaptationPackage.MODULE__RULES:
			return getRules();
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
		case Behaviour_adaptationPackage.MODULE__SUB_MODULES:
			getSubModules().clear();
			getSubModules().addAll((Collection<? extends Module>) newValue);
			return;
		case Behaviour_adaptationPackage.MODULE__RULES:
			getRules().clear();
			getRules().addAll((Collection<? extends Rule>) newValue);
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
		case Behaviour_adaptationPackage.MODULE__SUB_MODULES:
			getSubModules().clear();
			return;
		case Behaviour_adaptationPackage.MODULE__RULES:
			getRules().clear();
			return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
		case Behaviour_adaptationPackage.MODULE__SUB_MODULES:
			return subModules != null && !subModules.isEmpty();
		case Behaviour_adaptationPackage.MODULE__RULES:
			return rules != null && !rules.isEmpty();
		}
		return super.eIsSet(featureID);
	}

	@Override
	public String getName() {
		return safeWrappeeAccess((wrappedElement) -> { return ((org.eclipse.emf.henshin.model.Module) wrappedElement).getName(); });
	}

	@Override
	protected void internalSetName(String newname) {
		safeWrappeeAccess((wrappedElement) -> { ((org.eclipse.emf.henshin.model.Module) wrappedElement).setName(newname); });
	}

} // ModuleImpl