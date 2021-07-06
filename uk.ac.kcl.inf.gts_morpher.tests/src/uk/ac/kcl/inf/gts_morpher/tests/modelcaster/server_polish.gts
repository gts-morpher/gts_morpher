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

	to {
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

