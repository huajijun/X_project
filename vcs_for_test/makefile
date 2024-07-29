#!/bin/make
all: comp sim
 
comp:
	vcs -full64 -timescale=1ns/1ps -V -R -sverilog -debug_access+all +vc +v2k -kdb -l vcs.log -f dut.f +define+DUMP_FSDB=1 -top test
 
sim:
	./simv -l simv.log
 
show:
	verdi -ssf tb.fsdb &
 
clean:
	rm -rf *~  core  csrc  simv*  vc_hdrs.h  ucli.key  urg* *.log  novas.* *.fsdb* verdiLog  64* DVEfiles *.vpd verdi_config_file
