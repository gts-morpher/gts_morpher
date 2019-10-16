package uk.ac.kcl.inf.gts_morpher.composer.helpers

import org.eclipse.emf.ecore.EObject

final class OriginMgr {
	static enum Origin {
		KERNEL,
		LEFT,
		RIGHT
	}

	static def getLabel(Origin origin) {
		switch (origin) {
			case KERNEL: return "kernel"
			case LEFT: return "left"
			case RIGHT: return "right"
			default: return ""
		}
	}

	static def <T extends EObject> Pair<Origin, T> kernelKey(T object) { object.origKey(Origin.KERNEL) }

	static def <T extends EObject> Pair<Origin, T> leftKey(T object) { object.origKey(Origin.LEFT) }

	static def <T extends EObject> Pair<Origin, T> rightKey(T object) { object.origKey(Origin.RIGHT) }

	static def <T extends EObject> Pair<Origin, T> origKey(T object, Origin origin) { new Pair(origin, object) }
}
