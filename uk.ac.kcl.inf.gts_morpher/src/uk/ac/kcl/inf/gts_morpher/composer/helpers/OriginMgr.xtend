package uk.ac.kcl.inf.gts_morpher.composer.helpers

import org.eclipse.emf.ecore.EObject

final class OriginMgr {
	static enum Origin {
		SOURCE,
		TARGET		
	}

	static def getLabel(Origin origin) {
		switch (origin) {
			case SOURCE: return "source"
			case TARGET: return "target"
			default: return ""
		}
	}

	static def <T extends EObject> Pair<Origin, T> sourceKey(T object) { object.origKey(Origin.SOURCE) }

	static def <T extends EObject> Pair<Origin, T> targetKey(T object) { object.origKey(Origin.TARGET) }

	static def <T extends EObject> Pair<Origin, T> origKey(T object, Origin origin) { new Pair(origin, object) }
}
