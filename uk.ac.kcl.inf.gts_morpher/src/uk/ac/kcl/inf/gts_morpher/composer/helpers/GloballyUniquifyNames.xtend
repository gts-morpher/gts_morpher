package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data

class GloballyUniquifyNames implements NamingStrategy {
	val NamingStrategy baseNS

	new(NamingStrategy baseNS) {
		this.baseNS = baseNS
	}

	override weaveNameSpaces(Iterable<Pair<Origin, EPackage>> nameSources) {
		baseNS.weaveNameSpaces(nameSources)
	}

	override weaveURIs(Iterable<Pair<Origin, EPackage>> nameSources) {
		baseNS.weaveURIs(nameSources)
	}

	private static class UniqueNameResolver {
		val Map<EObject, String> names
	
		private static class DuplicateObjectCount {
			@Accessors
			var int count = 0
			@Accessors
			var List<EObject> elementsSeen = new ArrayList<EObject>
		}

		new(Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
			UniquenessContext context, NamingStrategy naming) {
			names = context.contextElements.map[eo | 
				(eo -> naming.weaveNames(nameSourcesLookup, eo, context))
			].toMap([key], [value])
			
			// TODO: Does this always terminate? I think it does because we are always appending a locally unique appendix, so names get longer and prefixes remain unique and, as a consequence cannot clash with names in other groups
			var Map<String, List<EObject>> duplicateNames
			do {
				duplicateNames = context.calculateDuplicateNames

				duplicateNames.forEach[name, objects |
					objects.forEach[eo, idx |
						names.put(eo, '''«name»_«idx + 1»''')
					]
				]
			} while (!duplicateNames.empty)
		}
		
		private def calculateDuplicateNames(UniquenessContext context) {
			names.keySet.groupBy[names.get(it)]
				.filter[name, objects | name !== null] // we don't need to keep track of duplicate unnamed objects
				.filter[name, objects | 
					objects.fold(new DuplicateObjectCount)[acc, o |
						if (!acc.elementsSeen.exists[o2 | context.considerIdentical(o, o2)]) {
							acc.count ++
						}

						acc.elementsSeen += o

						acc
					].count > 1
				]
		}

		def String uniqueNameFor(EObject object) {
			names.get(object)
		}
	}

	@Data
	private static class NameResolverCacheKey {
		val Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup
		val UniquenessContext contex
	}

	val nameResolvers = new HashMap<NameResolverCacheKey, UniqueNameResolver>

	override weaveNames(
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
		EObject objectToName, UniquenessContext context) {
		// FIXME: The context object changes every time, so is no good for caching. As a result, name resolution doesn't work
		val nameKey = new NameResolverCacheKey (nameSourcesLookup, context)
		var nameResolver = nameResolvers.get(nameKey)
		if (nameResolver === null) {
			nameResolver = new UniqueNameResolver(nameSourcesLookup, context, baseNS)
			nameResolvers.put(nameKey, nameResolver)
		}

		nameResolver.uniqueNameFor(objectToName)
	}
}
