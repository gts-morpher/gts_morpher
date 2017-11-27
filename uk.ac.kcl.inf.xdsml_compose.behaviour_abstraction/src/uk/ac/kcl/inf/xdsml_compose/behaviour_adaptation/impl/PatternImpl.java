/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import java.util.Collection;

import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.util.InternalEList;
import org.eclipse.emf.henshin.model.Graph;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.DelegatingTranslatingEcoreEList;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.EObjectTranslator;

/**
 * <!-- begin-user-doc --> An implementation of the model object
 * '<em><b>Pattern</b></em>'. <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.PatternImpl#getObjects
 * <em>Objects</em>}</li>
 * <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl.PatternImpl#getLinks
 * <em>Links</em>}</li>
 * </ul>
 *
 * @generated
 */
public class PatternImpl extends NamedElementImpl implements Pattern {
	/**
	 * The cached value of the '{@link #getObjects() <em>Objects</em>}' containment
	 * reference list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getObjects()
	 * @generated
	 * @ordered
	 */
	protected EList<uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object> objects;

	/**
	 * The cached value of the '{@link #getLinks() <em>Links</em>}' containment
	 * reference list. <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @see #getLinks()
	 * @generated
	 * @ordered
	 */
	protected EList<Link> links;

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	protected PatternImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return Behaviour_adaptationPackage.Literals.PATTERN;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EList<uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object> getObjects() {
		if (objects == null) {
			objects = new DelegatingTranslatingEcoreEList<uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object, org.eclipse.emf.henshin.model.Node>(
					this, Behaviour_adaptationPackage.PATTERN__OBJECTS,
					safeWrappeeAccess((wrappedElement) -> { return ((org.eclipse.emf.henshin.model.Graph) wrappedElement).getNodes(); }),
					(node) -> {
						return EObjectTranslator.INSTANCE.createObjectFor(node);
					});
		}
		return objects;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	public EList<Link> getLinks() {
		if (links == null) {
			links = new DelegatingTranslatingEcoreEList<Link, org.eclipse.emf.henshin.model.Edge>(this,
					Behaviour_adaptationPackage.PATTERN__LINKS,
					safeWrappeeAccess((wrappedElement) -> { return ((org.eclipse.emf.henshin.model.Graph) wrappedElement).getEdges(); }),
					(edge) -> {
						return EObjectTranslator.INSTANCE.createLinkFor(edge);
					});
		}
		return links;
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	@Override
	public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs) {
		switch (featureID) {
		case Behaviour_adaptationPackage.PATTERN__OBJECTS:
			return ((InternalEList<?>) getObjects()).basicRemove(otherEnd, msgs);
		case Behaviour_adaptationPackage.PATTERN__LINKS:
			return ((InternalEList<?>) getLinks()).basicRemove(otherEnd, msgs);
		}
		return super.eInverseRemove(otherEnd, featureID, msgs);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
		case Behaviour_adaptationPackage.PATTERN__OBJECTS:
			return getObjects();
		case Behaviour_adaptationPackage.PATTERN__LINKS:
			return getLinks();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
		case Behaviour_adaptationPackage.PATTERN__OBJECTS:
			getObjects().clear();
			getObjects()
					.addAll((Collection<? extends uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object>) newValue);
			return;
		case Behaviour_adaptationPackage.PATTERN__LINKS:
			getLinks().clear();
			getLinks().addAll((Collection<? extends Link>) newValue);
			return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc --> <!-- end-user-doc -->
	 * 
	 * @not-generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
		case Behaviour_adaptationPackage.PATTERN__OBJECTS:
			getObjects().clear();
			return;
		case Behaviour_adaptationPackage.PATTERN__LINKS:
			getLinks().clear();
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
		case Behaviour_adaptationPackage.PATTERN__OBJECTS:
			return getObjects() != null && !getObjects().isEmpty();
		case Behaviour_adaptationPackage.PATTERN__LINKS:
			return getLinks() != null && !getLinks().isEmpty();
		}
		return super.eIsSet(featureID);
	}

	@Override
	public String getName() {
		return safeWrappeeAccess((wrappedElement) -> { return ((Graph) wrappedElement).getName(); });
	}

	@Override
	protected void internalSetName(String newname) {
		safeWrappeeAccess((wrappedElement) -> { ((Graph) wrappedElement).setName(newname); });
	}

} // PatternImpl
