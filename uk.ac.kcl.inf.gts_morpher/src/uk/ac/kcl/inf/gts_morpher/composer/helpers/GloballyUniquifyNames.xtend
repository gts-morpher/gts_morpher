package uk.ac.kcl.inf.gts_morpher.composer.helpers

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EPackage
import uk.ac.kcl.inf.gts_morpher.composer.helpers.OriginMgr.Origin
import org.eclipse.xtend.lib.annotations.Accessors

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
		val Map<String, List<EObject>> duplicateNames

		private static class DuplicateObjectCount {
			@Accessors
			var int count = 0
			@Accessors
			var List<EObject> elementsSeen = new ArrayList<EObject>
		}

		new(Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
			UniquenessContext context, NamingStrategy naming) {
			names = context.contextElements.map[eo | 
				new Pair(eo, naming.weaveNames(nameSourcesLookup, eo, context))
			].toMap([key], [value])
			
			duplicateNames = names.keySet.groupBy[names.get(it)]
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
			var tentativeName = names.get(object)
			
			if (tentativeName !== null) {
				val allEquallyNamedObjects = duplicateNames.get(tentativeName)
				
				if (allEquallyNamedObjects !== null) {
					tentativeName += '''_«allEquallyNamedObjects.indexOf(object) + 1»'''
				}
			}
			
			tentativeName
		}
	}

	val nameResolvers = new HashMap<Pair<Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>>, UniquenessContext>, UniqueNameResolver>

	override weaveNames(
		Map<? extends EObject, ? extends Iterable<? extends Pair<Origin, ? extends EObject>>> nameSourcesLookup,
		EObject objectToName, UniquenessContext context) {
		//FIXME: Pairs don't have a good equals / hashmap method so don't work properly for map lookup
		val nameKey = new Pair(nameSourcesLookup, context)
		var nameResolver = nameResolvers.get(nameKey)
		if (nameResolver === null) {
			nameResolver = new UniqueNameResolver(nameSourcesLookup, context, baseNS)
			nameResolvers.put(nameKey, nameResolver)
		}

		nameResolver.uniqueNameFor(objectToName)
	}
}
