/**
 */
package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.impl;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EFactoryImpl;

import org.eclipse.emf.ecore.plugin.EcorePlugin;

import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationFactory;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Link;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Module;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Pattern;
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Rule;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Factory</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class Behaviour_adaptationFactoryImpl extends EFactoryImpl implements Behaviour_adaptationFactory {
	/**
	 * Creates the default factory implementation.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public static Behaviour_adaptationFactory init() {
		try {
			Behaviour_adaptationFactory theBehaviour_adaptationFactory = (Behaviour_adaptationFactory)EPackage.Registry.INSTANCE.getEFactory(Behaviour_adaptationPackage.eNS_URI);
			if (theBehaviour_adaptationFactory != null) {
				return theBehaviour_adaptationFactory;
			}
		}
		catch (Exception exception) {
			EcorePlugin.INSTANCE.log(exception);
		}
		return new Behaviour_adaptationFactoryImpl();
	}

	/**
	 * Creates an instance of the factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Behaviour_adaptationFactoryImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EObject create(EClass eClass) {
		switch (eClass.getClassifierID()) {
			case Behaviour_adaptationPackage.MODULE: return createModule();
			case Behaviour_adaptationPackage.RULE: return createRule();
			case Behaviour_adaptationPackage.PATTERN: return createPattern();
			case Behaviour_adaptationPackage.OBJECT: return createObject();
			case Behaviour_adaptationPackage.LINK: return createLink();
			default:
				throw new IllegalArgumentException("The class '" + eClass.getName() + "' is not a valid classifier");
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Module createModule() {
		ModuleImpl module = new ModuleImpl();
		return module;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Rule createRule() {
		RuleImpl rule = new RuleImpl();
		return rule;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Pattern createPattern() {
		PatternImpl pattern = new PatternImpl();
		return pattern;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Object createObject() {
		ObjectImpl object = new ObjectImpl();
		return object;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Link createLink() {
		LinkImpl link = new LinkImpl();
		return link;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public Behaviour_adaptationPackage getBehaviour_adaptationPackage() {
		return (Behaviour_adaptationPackage)getEPackage();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @deprecated
	 * @generated
	 */
	@Deprecated
	public static Behaviour_adaptationPackage getPackage() {
		return Behaviour_adaptationPackage.eINSTANCE;
	}

} //Behaviour_adaptationFactoryImpl
