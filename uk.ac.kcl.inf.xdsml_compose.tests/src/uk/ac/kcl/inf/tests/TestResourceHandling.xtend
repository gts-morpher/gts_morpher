package uk.ac.kcl.inf.tests

import org.eclipse.emf.ecore.resource.ResourceSet

class TestResourceHandling {
	static def findComposedEcore(ResourceSet resourceSet, String gtsName) {
		resourceSet.findComposed("ecore", gtsName)
	}

	static def findComposedHenshin(ResourceSet resourceSet, String gtsName) {
		resourceSet.findComposed("henshin", gtsName)
	}
	
	static def findComposed(ResourceSet resourceSet, String ext, String gtsName) {
		resourceSet.resources.filter[r|TestURIHandlerImpl.TEST_URI_SCHEME.equals(r.URI.scheme)].filter [ r |
			gtsName.equals(r.URI.segments.get(r.URI.segmentCount - 2))
		].filter [ r |
			ext.equals(r.URI.fileExtension)
		].head
	}
}