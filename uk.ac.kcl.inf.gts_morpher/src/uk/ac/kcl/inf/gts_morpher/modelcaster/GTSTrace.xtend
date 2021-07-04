package uk.ac.kcl.inf.gts_morpher.modelcaster

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.util.OnChangeEvictingCache
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilyChoice
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilyReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilySpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSFamilySpecificationOrReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSLiteral
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMapping
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRef
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSMappingRefOrInterfaceSpec
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationOrReference
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSTraceMember
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSWeave

/**
 * A GTS trace is a path that connects a source and a target GTS through a number of transformations in a GTSMorpher specification. 
 * For example, the source GTS might be the root of a family specification, from which a member gets picked, that is then mapped 
 * and woven to construct the target GTS.
 * 
 * The source GTS is always the first member of the GTSTrace and the target GTS is always the last member of the GTSTrace. 
 */
class GTSTrace extends ArrayList<GTSTraceMember> {
	
	static val traceCache = new OnChangeEvictingCache
	
	/** 
	 * Constructs the set of traces through which source can be transformed into target.
	 */
	static def Set<GTSTrace> findTracesTo(GTSSpecification source, GTSSpecification target) {
		val key = source -> target
		
		traceCache.get(key, source.eResource) [
			traceCache.get(key, target.eResource) [
				new GTSTraceHelper().findTraces(source, target)			
			]
		]		
	}

	private new(GTSTraceMember... trace) {
		super()
		this += trace
	}

	def getSource() { head as GTSSpecification }

	def getTarget() { last as GTSSpecification }
	
	def EObject getTransformedModel() {
		null
	}

	private static class GTSTraceHelper extends HashMap<GTSTraceMember, Set<GTSTrace>> {
		def Set<GTSTrace> findTraces(GTSSpecification source, GTSSpecification target) {
			val Set<GTSTraceMember> visited = new HashSet

			collectTraces(source, target, visited)
		}

		private def Set<GTSTrace> collectTraces(GTSSpecification source, GTSTraceMember target,
			Set<GTSTraceMember> visited) {
			if (visited.contains(target)) {
				if (get(target) !== null) {
					return get(target)
				} else {
					return emptySet
				}
			}

			visited += target

			val traces = if (source === target) {
					#{new GTSTrace(source)}  
				} else {
					expandAll(target.stepDown.flatMap[source.collectTraces(it, visited)].toSet, target)
				}

			put(target, traces)

			traces
		}

		private def expandAll(Set<GTSTrace> traces, GTSTraceMember newTarget) {
			traces.map[new GTSTrace(it + #{newTarget})].toSet
		}

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSTraceMember node) { #[] }

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSSpecification node) { #[node.gts] }

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSMapping node) {
			#[node.source.resolve, node.target.resolve]
		}

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSLiteral node) { #[] }

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSFamilyChoice node) { #[node.family.resolve] }

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSReference node) { #[node.ref] }

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSWeave node) {
			#[node.mapping1.resolve, node.mapping2.resolve]
		}

		private dispatch def Iterable<GTSTraceMember> stepDown(GTSMappingInterfaceSpec node) { #[node.gts_ref] }

		private dispatch def GTSTraceMember resolve(GTSSpecificationOrReference ref) { null }

		private dispatch def GTSTraceMember resolve(GTSSpecification ref) { ref }

		private dispatch def GTSTraceMember resolve(GTSReference ref) { ref.ref }

		private dispatch def GTSTraceMember resolve(GTSFamilySpecificationOrReference ref) { null }

		private dispatch def GTSTraceMember resolve(GTSFamilySpecification ref) { ref.root_gts.resolve }

		private dispatch def GTSTraceMember resolve(GTSFamilyReference ref) { ref.ref.resolve }

		private dispatch def GTSTraceMember resolve(GTSMappingRefOrInterfaceSpec ref) { null }

		private dispatch def GTSTraceMember resolve(GTSMappingRef ref) { ref.ref }

		private dispatch def GTSTraceMember resolve(GTSMappingInterfaceSpec ref) { ref.gts_ref }
	}
}
