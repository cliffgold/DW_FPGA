#Rules to use the Makefile:
#  1) directory structure:
#        Verilog files: chipname/chipname.srcs/HDL/*.v .sv .vh .svh  (and subdirs below)
#        IP files:      chipname/chipname.srcs/IP/*/*.xci
#        tcl files:     chipname/chipname.srcs/tcl/*.tcl
#        sim files:     chipname/chipname.srcs/SIM/*.v .sv .vh .svh
#        test files     chipname/chipname.srcs/SIM/tests/*.v .sv .vh .svh
#        wave cfg files chipname/chipname.srcs/WAVE/*.wcfg (helpful waveform display templates)
# 	 constraints    chipname/chipname.srcs/constr_1/*.xdc
#
#  2) All files within this structure will be acted upon.
#        Change extensions for temporary files (testcode.sv.temp)
#
#  3) Only the HDL top level must start with letters "top". (top.sv top_chip.sv etc.)
#         And must be located just below HDL (NO subdir)
#
rootDir   := $(CURDIR)
srcDir    := $(CURDIR)/$(wildcard *.srcs)
HDLDir    := $(srcDir)/HDL
IPDir     := $(srcDir)/IP
tclDir    := $(srcDir)/tcl
xdcDir    := $(srcDir)/constrs_1
runDir    := $(patsubst %.srcs,%.runs,$(srcDir))

HDLFiles  := $(shell find $(HDLDir) -iname '*.sv')
topFiles  := $(notdir $(wildcard $(HDLDir)/top*.sv $(HDLDir)/top*.v))
ipFiles   := $(wildcard $(IPDir)/*/*.xci)
xdcFiles  := $(wildcard $(xdcDir)/*.xdc)
xprFile   := $(wildcard *.xpr)

ipTargets   := $(patsubst %.xci,%.dcp,$(ipFiles))
topBase     := $(strip $(subst .v,,$(subst .sv,,$(topFiles))))
synTargets  := $(runDir)/synth_1/$(topBase).dcp
implTargets := $(runDir)/impl_1/$(topBase)_routed.dcp

vivado     := vivado -mode batch -source $(tclDir)/dojob.tcl $(xprFile) -tclargs

all: $(implTargets)

$(implTargets): $(synTargets) $(tclDir)/impl_top.tcl $(xdcFiles)
	$(vivado) impl_top.tcl nofile 

$(synTargets): $(HDLFiles) $(ipTargets) $(tclDir)/synth_top.tcl
	$(vivado) synth_top.tcl

$(ipTargets): %.dcp : %.xci $(tclDir)/ip.tcl
	$(vivado) ip.tcl $(basename $(notdir $<)) 

.PHONY: clean

clean:
	rm -f $(ipTargets) $(synTargets) $(implTargets)        ;\
	rm -f vivado* .init_design*.rst .opt_design*.rst hs_err*

