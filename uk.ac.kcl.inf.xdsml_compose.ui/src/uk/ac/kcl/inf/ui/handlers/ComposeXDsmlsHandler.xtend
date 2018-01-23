package uk.ac.kcl.inf.ui.handlers

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.IProject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jface.viewers.TreeSelection
import org.eclipse.swt.SWT
import org.eclipse.swt.widgets.MessageBox
import org.eclipse.swt.widgets.Shell
import org.eclipse.xtext.builder.EclipseOutputConfigurationProvider
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import uk.ac.kcl.inf.composer.XDsmlComposer

import static com.google.common.collect.Maps.uniqueIndex

import static extension org.eclipse.ui.handlers.HandlerUtil.*

class ComposeXDsmlsHandler extends AbstractHandler {

	@Inject
	private Provider<XtextResourceSet> resourceSetProvider

	@Inject
	private IResourceValidator resourceValidator
	
	@Inject
	private Provider<EclipseResourceFileSystemAccess2> fileSystemAccessProvider
	
	@Inject
	private EclipseOutputConfigurationProvider outputConfigurationProvider
	
	@Inject
	private XDsmlComposer composer

	override execute(ExecutionEvent event) throws ExecutionException {
		val selection = event.currentSelection
		if (selection instanceof TreeSelection) {
			val resourceSet = resourceSetProvider.get
			
			selection.iterator.forEach [ f |
				handleFile(f as IFile, resourceSet, event.activeShell)
			]
		}

		null
	}

	private def handleFile(IFile f, ResourceSet resourceSet, Shell shell) {
		val resource = resourceSet.getResource(URI.createPlatformResourceURI(f.fullPath.toString, false), true)
		val issues = resourceValidator.validate(resource, CheckMode.ALL, CancelIndicator.NullImpl)
		if (!issues.empty) {
			val mb = new MessageBox(shell, SWT.OK + SWT.ICON_ERROR + SWT.APPLICATION_MODAL)
			mb.text = "Error"
			mb.message = "Please fix any issues with this morphism specification before attempting to weave xDSMLs from it."
			mb.open
			return
		}
		
		val EclipseResourceFileSystemAccess2 fileSystemAccess = fileSystemAccessProvider.get()
		val IProject project = f.project
		fileSystemAccess.context = project
		val outputConfigIndex = uniqueIndex(outputConfigurationProvider.getOutputConfigurations(project), [cfg | cfg.name])
		// Probably don't need to do this
//		refreshOutputFolders(context, outputConfigurations, subMonitor.newChild(1));
		fileSystemAccess.outputConfigurations = outputConfigIndex
		
		composer.doCompose(resource, fileSystemAccess)
	}
}
