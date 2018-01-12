/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Pattern</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern#getObjects <em>Objects</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern#getLinks <em>Links</em>}</li>
 * </ul>
 *
 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getPattern()
 * @model
 * @generated
 */
public interface Pattern extends NamedElement {
	/**
	 * Returns the value of the '<em><b>Objects</b></em>' containment reference list.
	 * The list contents are of type {@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Objects</em>' containment reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Objects</em>' containment reference list.
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getPattern_Objects()
	 * @model containment="true"
	 * @generated
	 */
	EList<uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object> getObjects();

	/**
	 * Returns the value of the '<em><b>Links</b></em>' containment reference list.
	 * The list contents are of type {@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Links</em>' containment reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Links</em>' containment reference list.
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getPattern_Links()
	 * @model containment="true"
	 * @generated
	 */
	EList<Link> getLinks();

} // Pattern
