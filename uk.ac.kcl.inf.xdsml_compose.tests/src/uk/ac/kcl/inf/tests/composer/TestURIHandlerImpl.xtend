package uk.ac.kcl.inf.tests.composer

import java.io.IOException
import java.io.OutputStream
import java.util.Map
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ContentHandler
import org.eclipse.emf.ecore.resource.impl.URIHandlerImpl

/**
 * Mockup URI handler treating the URIs created by the Test FSA. 
 */
class TestURIHandlerImpl extends URIHandlerImpl {
	public static val TEST_URI_SCHEME = "test"
	
	override canHandle(URI uri) {
		TEST_URI_SCHEME.equals(uri.scheme)
	}
	
	override createOutputStream(URI uri, Map<?, ?> options) throws IOException {
		new OutputStream() {
			
			override write(int b) throws IOException {
				// Ignore anything written to this stream, we're just testing :-)
			}
			
		}
	}
	
	override createInputStream(URI uri, Map<?, ?> options) throws IOException {
		throw new UnsupportedOperationException("Cannot create input streams for test URIs.")
	}
	
	override delete(URI uri, Map<?, ?> options) throws IOException {
		throw new UnsupportedOperationException("Cannot delete test URIs.")
	}
	
	override contentDescription(URI uri, Map<?, ?> options) throws IOException {
		ContentHandler.INVALID_CONTENT_DESCRIPTION
	}
	
	override exists(URI uri, Map<?, ?> options) { true }
	
	override getAttributes(URI uri, Map<?, ?> options) {
		throw new UnsupportedOperationException("No attributes for test URIs.")
	}
	
	override setAttributes(URI uri, Map<String, ?> attributes, Map<?, ?> options) throws IOException { }
}
