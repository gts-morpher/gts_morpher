/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Rule</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule#getLhs <em>Lhs</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule#getRhs <em>Rhs</em>}</li>
 * </ul>
 *
 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getRule()
 * @model
 * @generated
 */
public interface Rule extends NamedElement {
	/**
	 * Returns the value of the '<em><b>Lhs</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Lhs</em>' containment reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Lhs</em>' containment reference.
	 * @see #setLhs(Pattern)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getRule_Lhs()
	 * @model containment="true"
	 * @generated
	 */
	Pattern getLhs();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule#getLhs <em>Lhs</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Lhs</em>' containment reference.
	 * @see #getLhs()
	 * @generated
	 */
	void setLhs(Pattern value);

	/**
	 * Returns the value of the '<em><b>Rhs</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Rhs</em>' containment reference isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Rhs</em>' containment reference.
	 * @see #setRhs(Pattern)
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getRule_Rhs()
	 * @model containment="true"
	 * @generated
	 */
	Pattern getRhs();

	/**
	 * Sets the value of the '{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule#getRhs <em>Rhs</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Rhs</em>' containment reference.
	 * @see #getRhs()
	 * @generated
	 */
	void setRhs(Pattern value);

} // Rule
