package uk.ac.kcl.inf.ui.handlers

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
import org.eclipse.xtext.resource.XtextResourceSet
import uk.ac.kcl.inf.composer.XDsmlComposer
import uk.ac.kcl.inf.xdsml_compose.ui.internal.Xdsml_composeActivator

import static com.google.common.collect.Maps.uniqueIndex

import static extension org.eclipse.ui.handlers.HandlerUtil.*

class ComposeXDsmlsHandler extends AbstractHandler {

	@Inject
	private Provider<XtextResourceSet> resourceSetProvider

	@Inject
	private Provider<EclipseResourceFileSystemAccess2> fileSystemAccessProvider

	@Inject
	private EclipseOutputConfigurationProvider outputConfigurationProvider

	@Inject
	private XDsmlComposer composer

	override execute(ExecutionEvent event) throws ExecutionException {
		val selection = event.currentSelection
		if (selection instanceof TreeSelection) {

			val job = new Job("Composing xDSMLs") {
				override protected run(IProgressMonitor monitor) {
					val subMonitor = SubMonitor.convert(monitor, selection.size())

					val status = selection.iterator.map [ f |
						subMonitor.taskName = '''Composing xDSMLs mapped in «(f as IFile).name».'''
						handleFile(f as IFile, event.activeShell, subMonitor.split(1))
					].reject[s|s.OK].toList

					if (status.empty) {
						Status.OK_STATUS
					} else {
						new MultiStatus(Xdsml_composeActivator.UK_AC_KCL_INF_XDSMLCOMPOSE, IStatus.ERROR, status,
							"There have been issues composing some of the xDSMLs.", null)
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
		val resourceSet = resourceSetProvider.get
		val resource = resourceSet.getResource(URI.createPlatformResourceURI(f.fullPath.toString, false), true)

		val EclipseResourceFileSystemAccess2 fileSystemAccess = fileSystemAccessProvider.get()
		val IProject project = f.project
		fileSystemAccess.context = project
		val outputConfigIndex = uniqueIndex(
			outputConfigurationProvider.getOutputConfigurations(project), [cfg|cfg.name])
		// Probably don't need to do this
//		refreshOutputFolders(context, outputConfigurations, subMonitor.newChild(1));
		fileSystemAccess.outputConfigurations = outputConfigIndex

		subMonitor.taskName = "Composing..."
		val issues = composer.doCompose(resource, fileSystemAccess, new EclipseProgressMonitor(subMonitor.split(1)))

		if (!issues.empty) {
			new MultiStatus(Xdsml_composeActivator.UK_AC_KCL_INF_XDSMLCOMPOSE, IStatus.ERROR, issues.map [ i |
					new Status(IStatus.ERROR, Xdsml_composeActivator.UK_AC_KCL_INF_XDSMLCOMPOSE, i.message)
				], '''Please fix any issues with the morphism specification in «f.name» before attempting to weave xDSMLs from it.''',
				null)
		} else {
			Status.OK_STATUS
		}
	}
}
