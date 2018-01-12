package uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.xtextsupport

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.resource.impl.DefaultResourceDescriptionStrategy
import org.eclipse.xtext.util.IAcceptor
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.util.IWrapperFactory

class BehaviourAdaptationResourceDescriptionStrategy extends DefaultResourceDescriptionStrategy {

	@Inject
	private var IWrapperFactory wrapperFactory;

	override createEObjectDescriptions(EObject eObject, IAcceptor<IEObjectDescription> acceptor) {
		try {
			val QualifiedName qualifiedName = qualifiedNameProvider.getFullyQualifiedName(eObject)
			if (qualifiedName !== null) {
				val wrappedObject = wrapperFactory.createWrapperFor(eObject)
				if (wrappedObject !== null) {
					acceptor.accept(EObjectDescription.create(qualifiedName, wrappedObject))					
				}
				return true
			}
		} catch (Exception exc) {
			println(exc.getMessage() + exc)
		}
		return false

	}

}
