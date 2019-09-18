package uk.ac.kcl.inf.gts_morpher.ui.handlers

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.core.commands.AbstractHandler
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.IProject
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.MultiStatus
import org.eclipse.core.runtime.Status
import org.eclipse.core.runtime.SubMonitor
import org.eclipse.core.runtime.jobs.Job
import org.eclipse.emf.common.util.URI
import org.eclipse.jface.viewers.TreeSelection
import org.eclipse.swt.widgets.Shell
import org.eclipse.xtext.builder.EclipseOutputConfigurationProvider
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.xtext.ui.resource.IResourceSetProvider
import uk.ac.kcl.inf.gts_morpher.generator.AutoCompletionGenerator

import static com.google.common.collect.Maps.uniqueIndex

import static extension org.eclipse.ui.handlers.HandlerUtil.*
import uk.ac.kcl.inf.gts_morpher.ui.internal.Gts_morpherActivator

class ComposeXDsmlsHandler extends AbstractHandler {

	@Inject
	IResourceSetProvider resourceSetProvider

	@Inject
	Provider<EclipseResourceFileSystemAccess2> fileSystemAccessProvider

	@Inject
	EclipseOutputConfigurationProvider outputConfigurationProvider

	@Inject
	AutoCompletionGenerator generator

	override execute(ExecutionEvent event) throws ExecutionException {
		val selection = event.currentSelection
		if (selection instanceof TreeSelection) {

			val job = new Job("Auto-completing") {
				override protected run(IProgressMonitor monitor) {
					val subMonitor = SubMonitor.convert(monitor, selection.size())

					val status = selection.iterator.map [ f |
						subMonitor.taskName = '''Auto-completing mappings in «(f as IFile).name».'''
						handleFile(f as IFile, event.activeShell, subMonitor.split(1))
					].reject[s|s.OK].toList

					if (status.empty) {
						Status.OK_STATUS
					} else {
						new MultiStatus(Gts_morpherActivator.UK_AC_KCL_INF_GTS_MORPHER_GTSMORPHER, IStatus.ERROR, status,
							"There have been issues auto-completing some of the mappings.", null)
					}
				}
			}
			job.schedule
		}

		null
	}

	private def handleFile(IFile f, Shell shell, IProgressMonitor monitor) {
		val subMonitor = SubMonitor.convert(monitor, 2)

		subMonitor.taskName = "Preparing..."
		subMonitor.split(1)
		val resourceSet = resourceSetProvider.get(f.project)
		val resource = resourceSet.getResource(URI.createPlatformResourceURI(f.fullPath.toString, false), true)

		val EclipseResourceFileSystemAccess2 fileSystemAccess = fileSystemAccessProvider.get()
		val IProject project = f.project
		fileSystemAccess.context = project
		val outputConfigIndex = uniqueIndex(
			outputConfigurationProvider.getOutputConfigurations(project), [cfg|cfg.name])
		// Probably don't need to do this
//		refreshOutputFolders(context, outputConfigurations, subMonitor.newChild(1));
		fileSystemAccess.outputConfigurations = outputConfigIndex

		subMonitor.taskName = "Auto-completing..."
		generator.doGenerate(resource, fileSystemAccess, new EclipseProgressMonitor(subMonitor.split(1)))
		
		Status.OK_STATUS
	}
}
