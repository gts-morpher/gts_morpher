package uk.ac.kcl.inf.gts_morpher.modelcaster

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Set
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecification
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSTraceMember

/**
 * A GTS trace is a path that connects a source and a target GTS through a number of transformations in a GTSMorpher specification. 
 * For example, the source GTS might be the root of a family specification, from which a member gets picked, that is then mapped 
 * and woven to construct the target GTS.
 * 
 * The source GTS is always the first member of the GTSTrace and the target GTS is always the last member of the GTSTrace. 
 */
interface GTSTrace extends List<GTSTraceMember> {
	def getSource() { head }

	def getTarget() { last }

	static class GTSTraceImpl extends ArrayList<GTSTraceMember> implements GTSTrace {
		new(GTSTraceMember... trace) {
			super()
			this += trace
		}
	}

	static class GTSTraceHelper extends HashMap<GTSTraceMember, Set<GTSTrace>> {
		def Set<? extends GTSTrace> findTraces(GTSSpecification source, GTSSpecification target) {
			val Set<GTSTraceMember> visited = new HashSet

			collectTraces(source, target, visited)
		}

		// TODO: Refactor to separate DFS logic and actual selection of followers
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
				#{new GTSTraceImpl(source, target) as GTSTrace}
			} else {
				expandAll(target.stepDown.flatMap[source.collectTraces(it, visited)].toSet, target)
			}
			
			put(target, traces)
			
			traces
		}
		
		private def expandAll(Set<GTSTrace> traces, GTSTraceMember newTarget) {
			traces.map[new GTSTraceImpl(it + #{newTarget}) as GTSTrace].toSet
		}
		
		private dispatch def Iterable<GTSTraceMember> stepDown (GTSTraceMember node) { #[] }
		private dispatch def Iterable<GTSTraceMember> stepDown (GTSSpecification node) { #[node.gts] }

		/*	
	private dispatch def boolean canBeDerivedFrom(GTSSpecification target, GTSSpecification source) {
		(target === source) || target.gts.canBeDerivedFrom(source)
	}

	private dispatch def boolean canBeDerivedFrom(GTSSelection target, GTSSpecification source) {
		false
	}

	private dispatch def boolean canBeDerivedFrom(GTSWeave target, GTSSpecification source) {
		target.mapping1.canBeDerivedFrom(source) || target.mapping2.canBeDerivedFrom(source)
	}

	private dispatch def boolean canBeDerivedFrom(GTSMappingRef target, GTSSpecification source) {
		target.ref.canBeDerivedFrom(source)
	}

	private dispatch def boolean canBeDerivedFrom(GTSMappingInterfaceSpec target, GTSSpecification source) {
		target.gts_ref.canBeDerivedFrom(source)
	}

	private dispatch def boolean canBeDerivedFrom(GTSMapping target, GTSSpecification source) {
		target.source.canBeDerivedFrom(source) || target.target.canBeDerivedFrom(source)
	}

	private dispatch def boolean canBeDerivedFrom(GTSReference target, GTSSpecification source) {
		target.ref.canBeDerivedFrom(source)
	}
		*/
	}

	static def findTracesTo(GTSSpecification source, GTSSpecification target) {
		new GTSTraceHelper().findTraces(source, target)
	}
}
