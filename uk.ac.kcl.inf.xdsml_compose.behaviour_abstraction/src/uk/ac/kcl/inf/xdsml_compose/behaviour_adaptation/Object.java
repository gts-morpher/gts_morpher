/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EClass;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Object</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getType <em>Type</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getOutgoing <em>Outgoing</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getIncoming <em>Incoming</em>}</li>
 * </ul>
 *
 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getObject()
 * @model
 * @generated
 */
public interface Object extends NamedElement {
	/**
	 * Returns the value of the '<em><b>Type</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Type</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Type</em>' reference.
	 * @see #setType(EClass)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getObject_Type()
	 * @model
	 * @generated
	 */
	EClass getType();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getType <em>Type</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Type</em>' reference.
	 * @see #getType()
	 * @generated
	 */
	void setType(EClass value);

	/**
	 * Returns the value of the '<em><b>Outgoing</b></em>' reference list.
	 * The list contents are of type {@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link}.
	 * It is bidirectional and its opposite is '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getSource <em>Source</em>}'.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Outgoing</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Outgoing</em>' reference list.
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getObject_Outgoing()
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getSource
	 * @model opposite="source"
	 * @generated
	 */
	EList<Link> getOutgoing();

	/**
	 * Returns the value of the '<em><b>Incoming</b></em>' reference list.
	 * The list contents are of type {@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link}.
	 * It is bidirectional and its opposite is '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getTarget <em>Target</em>}'.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Incoming</em>' reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Incoming</em>' reference list.
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getObject_Incoming()
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getTarget
	 * @model opposite="target"
	 * @generated
	 */
	EList<Link> getIncoming();

} // Object
