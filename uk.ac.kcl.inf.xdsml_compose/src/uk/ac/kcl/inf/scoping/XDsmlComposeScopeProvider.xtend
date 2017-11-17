/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.scoping

import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider
import org.eclipse.xtext.scoping.impl.FilteringScope
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping

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

	def IScope sourceScope (TypeGraphMapping tgm) {
		scopeFor([tgm.source.eAllContents], new DefaultDeclarativeQualifiedNameProvider, IScope.NULLSCOPE)
	}

	def IScope targetScope (TypeGraphMapping tgm) {
		scopeFor([tgm.target.eAllContents], new DefaultDeclarativeQualifiedNameProvider, IScope.NULLSCOPE)
	}
}
