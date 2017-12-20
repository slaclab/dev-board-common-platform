open_run synth_1

CreateDebugCore ila1
SetDebugCoreClk ila1 [get_nets -of [get_clocks sysClk156MHz]]

ConfigProbe ila1 [get_nets {muxedSignals[rxMasters][0][tValid]}]
ConfigProbe ila1 [get_nets {muxedSignals[rxMasters][0][tData]*}]
ConfigProbe ila1 [get_nets {muxedSignals[rxSlaves][0][tReady]}]
ConfigProbe ila1 [get_nets {muxedSignals[txMasters][0][tValid]}]
ConfigProbe ila1 [get_nets {muxedSignals[txMasters][0][tData]*}]
ConfigProbe ila1 [get_nets {muxedSignals[txSlaves][0][tReady]}]

# clip unused ports
WriteDebugProbes ila1 debugProbes.ltx
