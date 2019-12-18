package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.function.Function
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.henshin.model.Graph
import org.eclipse.emf.henshin.model.Rule

import static extension uk.ac.kcl.inf.gts_morpher.util.EMFHelper.*

/**
 * Helper class for producing standard contents enumerators
 */
abstract class ContentsEnumerators {
	static def Function<EPackage, Iterable<EObject>> packageEnumerator(boolean interfaceOnly) {
		interfaceFilteredContentsEnumerator([eAllContents.toIterable], interfaceOnly)
	}

	static def Function<Graph, Iterable<EObject>> graphEnumerator(boolean interfaceOnly) {
		interfaceFilteredContentsEnumerator([graphContents], interfaceOnly)
	}

	static def Function<Rule, Iterable<EObject>> ruleEnumerator(boolean interfaceOnly) {
		interfaceFilteredContentsEnumerator([
			#[lhs, rhs] + parameters + lhs.graphContents + rhs.graphContents
		], interfaceOnly)
	}

	private static def Iterable<EObject> graphContents(extension Graph g) {
		(nodes + edges + nodes.flatMap[attributes]).map[it as EObject]
	}

	private static def <T extends EObject> Function<T, Iterable<EObject>> interfaceFilteredContentsEnumerator(
		Function<T, Iterable<EObject>> contents, boolean interfaceOnly) {
		if (interfaceOnly) {
			contents.andThen[filter[interfaceElement]]
		} else {
			contents
		}
	}
}
