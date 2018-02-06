/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.ui.quickfix

import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.ui.editor.quickfix.DefaultQuickfixProvider
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue
import uk.ac.kcl.inf.validation.XDsmlComposeValidator
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.XDsmlComposeFactory

import static extension uk.ac.kcl.inf.util.EMFHelper.*
import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*


/**
 * Custom quickfixes.
 * 
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#quick-fixes
 */
class XDsmlComposeQuickfixProvider extends DefaultQuickfixProvider {

	@Fix(XDsmlComposeValidator.NO_UNIQUE_COMPLETION)
	def tryImproveCompletionUniqueness(Issue issue, IssueResolutionAcceptor acceptor) {
		// Each element in issue data represents an option for how to improve the mapping. These are given in the form "(class|reference)|srcName=>tgtName".
		issue.data.forEach [ id |
			val _first_split = id.split(':')
			val classOrReference = _first_split.get(0)
			val _second_split = _first_split.get(1).split('=>')
			val source = _second_split.get(0)
			val target = _second_split.get(1)

			val quickFixText = '''Add a mapping from «classOrReference» «source» to «target».'''

			acceptor.accept(issue,
				quickFixText, quickFixText, null, [element, context |
				val gtsMapping = element as GTSMapping
				val typeMapping = gtsMapping.typeMapping
				
				if (classOrReference.equals("class")) {
					val classMapping = XDsmlComposeFactory.eINSTANCE.createClassMapping
					classMapping.source = gtsMapping.source.metamodel.findWithQualifiedName (source) as EClass
					classMapping.target = gtsMapping.target.metamodel.findWithQualifiedName (target) as EClass
					typeMapping.mappings.add(classMapping)
				} else {
					val referenceMapping = XDsmlComposeFactory.eINSTANCE.createReferenceMapping
					referenceMapping.source = gtsMapping.source.metamodel.findWithQualifiedName (source) as EReference
					referenceMapping.target = gtsMapping.target.metamodel.findWithQualifiedName (target) as EReference
					typeMapping.mappings.add(referenceMapping)					
				}
			])
		]
	}
}
