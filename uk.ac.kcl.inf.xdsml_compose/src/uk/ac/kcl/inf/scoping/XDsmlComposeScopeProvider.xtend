/*
 * generated by Xtext 2.12.0
 */
package uk.ac.kcl.inf.scoping

import com.google.common.base.Function
import com.google.inject.Inject
import com.google.inject.Provider
import java.util.Iterator
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage
import org.eclipse.emf.henshin.model.HenshinPackage
import org.eclipse.emf.henshin.model.Rule
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.naming.SimpleNameProvider
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider
import org.eclipse.xtext.scoping.impl.FilteringScope
import uk.ac.kcl.inf.util.henshinsupport.HenshinQualifiedNameProvider
import uk.ac.kcl.inf.xDsmlCompose.AttributeMapping
import uk.ac.kcl.inf.xDsmlCompose.ClassMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSFamilyChoice
import uk.ac.kcl.inf.xDsmlCompose.GTSMapping
import uk.ac.kcl.inf.xDsmlCompose.GTSSpecification
import uk.ac.kcl.inf.xDsmlCompose.LinkMapping
import uk.ac.kcl.inf.xDsmlCompose.ObjectMapping
import uk.ac.kcl.inf.xDsmlCompose.ReferenceMapping
import uk.ac.kcl.inf.xDsmlCompose.RuleMapping
import uk.ac.kcl.inf.xDsmlCompose.TypeGraphMapping
import uk.ac.kcl.inf.xDsmlCompose.UnitCall

import static org.eclipse.xtext.scoping.Scopes.*

import static extension uk.ac.kcl.inf.util.GTSSpecificationHelper.*

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class XDsmlComposeScopeProvider extends AbstractDeclarativeScopeProvider {

	@Inject
	val SimpleNameProvider simpleNameProvider = null

	def IScope scope_UnitCall_unit(UnitCall context, EReference ref) {
		safeScopeFor([(context.eContainer.eContainer as GTSFamilyChoice).transformers.units], simpleNameProvider,
			IScope.NULLSCOPE)
	}

	def IScope scope_ClassMapping_source(ClassMapping context, EReference ref) {
		new FilteringScope(sourceScope(context.eContainer as TypeGraphMapping), [ eod |
			EcorePackage.Literals.ECLASSIFIER.isSuperTypeOf(eod.EClass)
		])
	}

	def IScope scope_ClassMapping_target(ClassMapping context, EReference ref) {
		new FilteringScope(targetScope(context.eContainer as TypeGraphMapping), [ eod |
			EcorePackage.Literals.ECLASSIFIER.isSuperTypeOf(eod.EClass)
		])
	}

	def IScope scope_ReferenceMapping_source(ReferenceMapping context, EReference ref) {
		new FilteringScope(sourceScope(context.eContainer as TypeGraphMapping), [ eod |
			eod.EClass === EcorePackage.Literals.EREFERENCE
		])
	}

	def IScope scope_ReferenceMapping_target(ReferenceMapping context, EReference ref) {
		new FilteringScope(targetScope(context.eContainer as TypeGraphMapping), [ eod |
			eod.EClass === EcorePackage.Literals.EREFERENCE
		])
	}

	def IScope scope_AttributeMapping_source(AttributeMapping context, EReference ref) {
		new FilteringScope(sourceScope(context.eContainer as TypeGraphMapping), [ eod |
			eod.EClass === EcorePackage.Literals.EATTRIBUTE
		])
	}

	def IScope scope_AttributeMapping_target(AttributeMapping context, EReference ref) {
		new FilteringScope(targetScope(context.eContainer as TypeGraphMapping), [ eod |
			eod.EClass === EcorePackage.Literals.EATTRIBUTE
		])
	}

	private def IScope sourceScope(TypeGraphMapping tgm) {
		safeScopeFor_([(tgm.eContainer as GTSMapping).source.metamodel.eAllContents],
			new DefaultDeclarativeQualifiedNameProvider, IScope.NULLSCOPE)
	}

	private def IScope targetScope(TypeGraphMapping tgm) {
		safeScopeFor_([(tgm.eContainer as GTSMapping).target.metamodel.eAllContents],
			new DefaultDeclarativeQualifiedNameProvider, IScope.NULLSCOPE)
	}

	def IScope scope_RuleMapping_source(RuleMapping context, EReference ref) {
		rm_scope((context.eContainer.eContainer as GTSMapping).source)
	}

	def IScope scope_RuleMapping_target(RuleMapping context, EReference ref) {
		rm_scope((context.eContainer.eContainer as GTSMapping).target)
	}

	def IScope scope_ObjectMapping_source(ObjectMapping context, EReference ref) {
		new FilteringScope(
			sourceScope(context.eContainer as RuleMapping),
			[eod|eod.EClass == HenshinPackage.Literals.NODE]
		)
	}

	def IScope scope_ObjectMapping_target(ObjectMapping context, EReference ref) {
		new FilteringScope(
			targetScope(context.eContainer as RuleMapping),
			[eod|eod.EClass == HenshinPackage.Literals.NODE]
		)
	}

	def IScope scope_LinkMapping_source(LinkMapping context, EReference ref) {
		new FilteringScope(
			sourceScope(context.eContainer as RuleMapping),
			[eod|eod.EClass == HenshinPackage.Literals.EDGE]
		)
	}

	def IScope scope_LinkMapping_target(LinkMapping context, EReference ref) {
		new FilteringScope(
			targetScope(context.eContainer as RuleMapping),
			[eod|eod.EClass == HenshinPackage.Literals.EDGE]
		)
	}

	// An adapted variant of SimpleNameProvider that handles Henshin naming graciously
	val nameProvider = new IQualifiedNameProvider.AbstractImpl {

		private val delegate = new HenshinQualifiedNameProvider

		override getFullyQualifiedName(EObject obj) {
			val name = delegate.getFullyQualifiedName(obj)
			if (name === null) {
				null
			} else {
				QualifiedName.create(name.lastSegment)
			}
		}

	}

	private def rm_scope(GTSSpecification gts) {
		safeScopeFor_([
			gts.behaviour.eAllContents.filter [ eo |
				eo instanceof Rule
			]
		], nameProvider, IScope.NULLSCOPE)
	}

	private def sourceScope(RuleMapping rm) {
		safeScopeFor_([rm.source.eAllContents], nameProvider, IScope.NULLSCOPE)
	}

	private def targetScope(RuleMapping rm) {
		safeScopeFor_([rm.target.eAllContents], nameProvider, IScope.NULLSCOPE)
	}

	private def safeScopeFor(Provider<Iterable<? extends EObject>> scopeElements,
		Function<EObject, QualifiedName> nameProvider, IScope outer) {
		try {
			return scopeFor(scopeElements.get, nameProvider, outer)
		} catch (NullPointerException npe) {
			return outer
		}
	}

	private def safeScopeFor_(Provider<Iterator<EObject>> scopeElements,
		Function<EObject, QualifiedName> nameProvider, IScope outer) {
		try {
			val iterator = scopeElements.get
			return scopeFor([iterator], nameProvider, outer)
		} catch (NullPointerException npe) {
			return outer
		}
	}
}
