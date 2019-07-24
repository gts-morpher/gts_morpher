package uk.ac.kcl.inf.tests

import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.util.RuntimeIOException
import java.io.InputStream
import org.eclipse.emf.common.util.URI

class TestFileSystemAccess implements IFileSystemAccess2 {
	
	override isFile(String path) throws RuntimeIOException { true }
	
	override isFile(String path, String outputConfigurationName) throws RuntimeIOException { true }
	
	override deleteFile(String fileName) { }
	
	override generateFile(String fileName, CharSequence contents) { }
	
	override generateFile(String fileName, String outputConfigurationName, CharSequence contents) { }
	
	override deleteFile(String fileName, String outputConfigurationName) { }
	
	override getURI(String path) {
		getURI(path, null)
	}
	
	override getURI(String path, String outputConfiguration) {
		URI.createURI('''«TestURIHandlerImpl.TEST_URI_SCHEME»:/tests/«path»''')
	}
	
	override generateFile(String fileName, InputStream content) throws RuntimeIOException { }
	
	override generateFile(String fileName, String outputCfgName, InputStream content) throws RuntimeIOException { }
	
	override readBinaryFile(String fileName) throws RuntimeIOException { 
		throw new UnsupportedOperationException("Cannot read binary files in test")
	}
	
	override readBinaryFile(String fileName, String outputCfgName) throws RuntimeIOException {
		throw new UnsupportedOperationException("Cannot read binary files in test")
	}
	
	override readTextFile(String fileName) throws RuntimeIOException ''''''
	
	override readTextFile(String fileName, String outputCfgName) throws RuntimeIOException ''''''
	
}
