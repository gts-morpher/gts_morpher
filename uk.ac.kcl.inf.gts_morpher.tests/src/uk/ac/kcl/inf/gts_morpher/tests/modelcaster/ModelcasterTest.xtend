package uk.ac.kcl.inf.gts_morpher.tests.modelcaster

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.Test
import org.junit.runner.RunWith
import uk.ac.kcl.inf.gts_morpher.gtsMorpher.GTSSpecificationModule
import uk.ac.kcl.inf.gts_morpher.tests.AbstractTest
import uk.ac.kcl.inf.gts_morpher.tests.GTSMorpherInjectorProvider

import static org.hamcrest.CoreMatchers.*
import static org.hamcrest.MatcherAssert.*
import static uk.ac.kcl.inf.gts_morpher.tests.HasSize.*
import static uk.ac.kcl.inf.gts_morpher.tests.IsEmpty.*
import static uk.ac.kcl.inf.gts_morpher.tests.IsTraceWith.*

import static extension uk.ac.kcl.inf.gts_morpher.modelcaster.GTSTrace.*
import static extension uk.ac.kcl.inf.gts_morpher.util.GTSSpecificationHelper.*

@RunWith(XtextRunner)
@InjectWith(GTSMorpherInjectorProvider)
class ModelcasterTest extends AbstractTest {
	@Inject
	ParseHelper<GTSSpecificationModule> parseHelper

	private def createModelResourceSet() {
		#["storing_server.ecore", 
		  "DEVSMM.ecore", 
		  "DEVSModel.xmi", 
		  "storing_server.henshin", 
		  "devsmm.henshin",
		  "pls.ecore",
		  "pls.henshin",
		  "server.ecore",
		  "server.henshin",
		  "transformers.henshin"].createResourceSet
	}

	/**
	 * Test trace generation
	 */
	@Test
	def void validationBasicTrace() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val rs = createModelResourceSet
		val result = parseHelper.parse('''
			gts ServerSystem {
				metamodel: "storing_server"
				behaviour: "storing_serverRules"
			}
			
			gts ServerInterface interface_of { ServerSystem }
			
			gts DEVSMMSystem {
				metamodel: "devsmm"
				behaviour: "devsmmRules"
			}
			
			map ServerToDEVSMM {
				from ServerInterface
				to DEVSMMSystem
				
				type_mapping {
					class server.Server => devsmm.Machine
					reference server.Server.Out => devsmm.Machine.out
				}
				
				behaviour_mapping {
					rule process to process {
						object input => in_part
						link [in_queue->input:elts] => [tray->in_part:parts]
					}
				}
			}
			
			gts DEVSMMWithServer {
				weave: {
					map1: interface_of (ServerSystem)
					map2: ServerToDEVSMM
				}
			}
			
			model derivedModel = "«class.getResource("DEVSModel.xmi").path»" (instance of DEVSMMSystem) as DEVSMMWithServer
		''', rs)
		assertThat ("Did not produce parse result", result, is(notNullValue))
		assertThat("Found parse errors: " + result.eResource.errors, result.eResource.errors, is(empty))
		
		val derivedModel = result.modelCasts.head
		val traces = derivedModel.srcGTS.findTracesTo(derivedModel.tgtGTS)
		assertThat("Too many traces found", traces, hasSize(1))
		
		assertThat("Trace too long", traces.head, hasSize(4))
		assertThat("Incorrect trace", traces.head, isTraceWith(
			result.gtss.get(2),
			result.mappings.head,
			result.gtss.get(3).gts,
			result.gtss.get(3)
		))
		
		val wovenGTS = result.gtss.last
		val wovenMetamodel = wovenGTS.metamodel
		
		val transformedModel = traces.head.transformModel(rs.getResource("DEVSModel.xmi".createFileURI, true).contents.head)
		assertThat("No transformed model", transformedModel, is(notNullValue))
		assertThat("Incorrect metamodel of transformed model", transformedModel.eClass.EPackage, is(sameInstance(wovenMetamodel)))
	}

	/**
	 * Test trace generation
	 */
	@Test
	def void validationBasicModelTransform() {
		// TODO At some point may want to change this so it works with actual URLs rather than relying on Xtext/Ecore to pick up and search all the available ecore files
		// Then would use «serverURI.toString» etc. below
		val rs = createModelResourceSet
		val result = parseHelper.parse('''
			gts_family ServerFamily {
				{
					metamodel: "server"
					behaviour: "serverRules"
				}
			
				transformers: "transformerRules"
			}
			
			export gts AdaptedServer {
				family: ServerFamily
			
				using [
					addSubClass (server.Queue, "InputQueue"),
					addSubClass (server.Queue, "OutputQueue"),
					reTypeToSubClass (serverRules.process, server.Queue, server.InputQueue, "iq"),
					reTypeToSubClass (serverRules.process, server.Queue, server.OutputQueue, "oq"),
					mvAssocDown (server.Server.in, server.InputQueue),
					mvAssocDown (server.Server.out, server.OutputQueue)
				]
			}
			
			auto-complete unique map Server2PLS {
				from interface_of {
					AdaptedServer
				}
			
				to gts pls {
					metamodel: "pls"
					behaviour: "plsRules"
				}
			
				type_mapping {
					class server.Server => pls.Polisher
					class server.InputQueue => pls.Tray
					class server.OutputQueue => pls.Conveyor
				}
			}
			
			export gts ServerPLS {
				weave(dontLabelNonKernelElements,preferMap2TargetNames): {
					map1: interface_of(AdaptedServer)
					map2: Server2PLS
				}
			}
						
			model derivedModel = "«class.getResource("DEVSModel.xmi").path»" (instance of pls) as ServerPLS
		''', rs)
		assertThat ("Did not produce parse result", result, is(notNullValue))
		assertThat("Found parse errors: " + result.eResource.errors, result.eResource.errors, is(empty))
		
		val derivedModel = result.modelCasts.head
		val traces = derivedModel.srcGTS.findTracesTo(derivedModel.tgtGTS)
		assertThat("Too many traces found", traces, hasSize(1))
		
		assertThat("Trace too long", traces.head, hasSize(4))
		assertThat("Incorrect trace", traces.head, isTraceWith(
			result.gtss.get(2),
			result.mappings.head,
			result.gtss.get(3).gts,
			result.gtss.get(3)
		))
		
		val wovenGTS = result.gtss.last
		val wovenMetamodel = wovenGTS.metamodel
		
		val transformedModel = traces.head.transformModel(rs.getResource("DEVSModel.xmi".createFileURI, true).contents.head)
		assertThat("No transformed model", transformedModel, is(notNullValue))
		assertThat("Incorrect metamodel of transformed model", transformedModel.eClass.EPackage, is(sameInstance(wovenMetamodel)))
	}
}
