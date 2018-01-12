/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Link</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getType <em>Type</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getSource <em>Source</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getTarget <em>Target</em>}</li>
 * </ul>
 *
 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getLink()
 * @model
 * @generated
 */
public interface Link extends NamedElement {
	/**
	 * Returns the value of the '<em><b>Type</b></em>' reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Type</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Type</em>' reference.
	 * @see #setType(EObject)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getLink_Type()
	 * @model
	 * @generated
	 */
	EObject getType();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getType <em>Type</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Type</em>' reference.
	 * @see #getType()
	 * @generated
	 */
	void setType(EObject value);

	/**
	 * Returns the value of the '<em><b>Source</b></em>' reference.
	 * It is bidirectional and its opposite is '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getOutgoing <em>Outgoing</em>}'.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Source</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Source</em>' reference.
	 * @see #setSource(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getLink_Source()
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getOutgoing
	 * @model opposite="outgoing"
	 * @generated
	 */
	uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object getSource();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getSource <em>Source</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Source</em>' reference.
	 * @see #getSource()
	 * @generated
	 */
	void setSource(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object value);

	/**
	 * Returns the value of the '<em><b>Target</b></em>' reference.
	 * It is bidirectional and its opposite is '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getIncoming <em>Incoming</em>}'.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Target</em>' reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Target</em>' reference.
	 * @see #setTarget(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getLink_Target()
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object#getIncoming
	 * @model opposite="incoming"
	 * @generated
	 */
	uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object getTarget();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link#getTarget <em>Target</em>}' reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Target</em>' reference.
	 * @see #getTarget()
	 * @generated
	 */
	void setTarget(uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object value);

} // Link
