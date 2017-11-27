/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.scoping

import com.google.inject.Inject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.naming.SimpleNameProvider
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider
import org.eclipse.xtext.scoping.impl.FilteringScope
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.RuleMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xdsml_compose.behaviour_adaptation.Behaviour_adaptationPackage

import static org.eclipse.xtext.scoping.Scopes.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class XDsmlComposeScopeProvider extends AbstractDeclarativeScopeProvider {

	def IScope scope_ClassMapping_source(ClassMapping context, EReference ref) {
		new FilteringScope(
			sourceScope(context.eContainer as TypeGraphMapping), 
			[ eod | EcorePackage.Literals.ECLASSIFIER.isSuperTypeOf(eod.EClass)])
	}

	def IScope scope_ClassMapping_target(ClassMapping context, EReference ref) {
		new FilteringScope(
			targetScope(context.eContainer as TypeGraphMapping), 
			[ eod | EcorePackage.Literals.ECLASSIFIER.isSuperTypeOf(eod.EClass)])
	}
	
	def IScope scope_ReferenceMapping_source(ReferenceMapping context, EReference ref) {
		new FilteringScope(
			sourceScope(context.eContainer as TypeGraphMapping), 
			[ eod | eod.EClass == EcorePackage.Literals.EREFERENCE])
	}

	def IScope scope_ReferenceMapping_target(ReferenceMapping context, EReference ref) {
		new FilteringScope(
			targetScope(context.eContainer as TypeGraphMapping), 
			[ eod | eod.EClass == EcorePackage.Literals.EREFERENCE])
	}

	private def IScope sourceScope (TypeGraphMapping tgm) {
		scopeFor([(tgm.eContainer as GTSMapping).source.metamodel.eAllContents], new DefaultDeclarativeQualifiedNameProvider, IScope.NULLSCOPE)
	}

	private def IScope targetScope (TypeGraphMapping tgm) {
		scopeFor([(tgm.eContainer as GTSMapping).target.metamodel.eAllContents], new DefaultDeclarativeQualifiedNameProvider, IScope.NULLSCOPE)
	}
	
	def IScope scope_ObjectMapping_source (ObjectMapping context, EReference ref) {
		new FilteringScope(
			sourceScope(context.eContainer as RuleMapping),
			[eod | eod.EClass == Behaviour_adaptationPackage.Literals.OBJECT]
		)
	}
	
	def IScope scope_ObjectMapping_target (ObjectMapping context, EReference ref) {
		new FilteringScope(
			targetScope(context.eContainer as RuleMapping),
			[eod | eod.EClass == Behaviour_adaptationPackage.Literals.OBJECT]
		)
	}
	
	def IScope scope_LinkMapping_source (LinkMapping context, EReference ref) {
		new FilteringScope(
			sourceScope(context.eContainer as RuleMapping),
			[eod | eod.EClass == Behaviour_adaptationPackage.Literals.LINK]
		)
	}
	
	def IScope scope_LinkMapping_target (LinkMapping context, EReference ref) {
		new FilteringScope(
			targetScope(context.eContainer as RuleMapping),
			[eod | eod.EClass == Behaviour_adaptationPackage.Literals.LINK]
		)
	}

	@Inject
	var SimpleNameProvider nameProvider;
	
	private def sourceScope(RuleMapping rm) {
		// FIXME: This causes an exception down the line. I think the problem is that the scope contains Link objects, which don't have a name.
		// Thus, the solution is to ensure Links are NamedElements and to move the naming rule from QualifiedNameProvider/the resource description strategy into the actual Link.
		// Hmm, just did a quick check and it appears that Links are named and produce some sort of name (if not what we need yet). So maybe that isn't the problem after all.
		// Need to debug into what rm.source.eAllContents produces. May need to pre-filter this...
		scopeFor([
			rm.source.eAllContents
		], nameProvider, IScope.NULLSCOPE)
	}

	private def targetScope(RuleMapping rm) {
		scopeFor([rm.target.eAllContents], nameProvider, IScope.NULLSCOPE)
	}
}
