/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Module</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module#getSubModules <em>Sub Modules</em>}</li>
 *   <li>{@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module#getRules <em>Rules</em>}</li>
 * </ul>
 *
 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getModule()
 * @model
 * @generated
 */
public interface Module extends NamedElement {
	/**
	 * Returns the value of the '<em><b>Sub Modules</b></em>' containment reference list.
	 * The list contents are of type {@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Sub Modules</em>' containment reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Sub Modules</em>' containment reference list.
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getModule_SubModules()
	 * @model containment="true"
	 * @generated
	 */
	EList<Module> getSubModules();

	/**
	 * Returns the value of the '<em><b>Rules</b></em>' containment reference list.
	 * The list contents are of type {@link uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule}.
	 * <!-- begin-user-doc -->
	 * <p>
	 * If the meaning of the '<em>Rules</em>' containment reference list isn't clear,
	 * there really should be more of a description here...
	 * </p>
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Rules</em>' containment reference list.
	 * @see uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage#getModule_Rules()
	 * @model containment="true"
	 * @generated
	 */
	EList<Rule> getRules();

} // Module
