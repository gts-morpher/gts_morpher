/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Wrapping Element</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.WrappingElement#getWrappedElement <em>Wrapped Element</em>}</li>
 * </ul>
 *
 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getWrappingElement()
 * @model abstract="true"
 * @generated
 */
public interface WrappingElement extends EObject {
	/**
	 * Returns the value of the '<em><b>Wrapped Element</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Wrapped Element</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Wrapped Element</em>' reference.
	 * @see #setWrappedElement(EObject)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getWrappingElement_WrappedElement()
	 * @model transient="true"
	 * @generated
	 */
	EObject getWrappedElement();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.WrappingElement#getWrappedElement <em>Wrapped Element</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Wrapped Element</em>' reference.
	 * @see #getWrappedElement()
	 * @generated
	 */
	void setWrappedElement(EObject value);

} // WrappingElement
