GHDL       = /opt/ghdl/bin/ghdl
GHDLEFLAGS = -Wl,vhpi.o
SRC        = $(sort $(wildcard src/*.vhd))
SRC_O      = $(SRC:.vhd=.o)
SIM        = $(sort $(wildcard sim/*.vhd)) $(wildcard sim/mocks/*.vhd)
SIM_O      = $(SIM:.vhd=.o)
SIM_NMS    = $(basename $(notdir $(filter %_tb.vhd,$(SIM))))

FILES	   = src/com_components.o src/com_controller.o src/hash_components.o src/main.o src/extender.o src/padder_512.o src/compressor.o src/nonce_generator_and_padder.o src/comparator.o src/mining_core.o src/nonce_master.o src/bus_comp.o sim/sim_tb_top.o sim/vhpi_access.o sim/mocks/clk_core.o sim/mocks/uart_transceiver.o sim/mocks/uart_receiver.o src/compressor_second_stage.o

PRIO_SRC_O = src/com_components.o src/hash_components.o

all: trace.ghw

%.o: %.vhd
	cd build;${GHDL} -a --ieee=synopsys ../$<

testbench: init ${FILES} vhpi
	cd build;${GHDL} -e --ieee=synopsys ${GHDLEFLAGS} sim_tb_top

syntax: init ${FILES}
	rm -rf build

init:
	mkdir -p build

vhpi:
	gcc -c sim/vhpi.c -o build/vhpi.o

trace.ghw: testbench pipe
	cd build;${GHDL} -r -v --ieee=synopsys sim_tb_top --wave=trace.ghw

pipe:
	rm -f build/pipe.in
	rm -f build/pipe.out
	mkfifo build/pipe.in
	mkfifo build/pipe.out
	# Necessary on some machines
	chmod 777 build/pipe.in
	chmod 777 build/pipe.out

view: trace.ghw
	gtkwave build/trace.ghw

clean:
	rm -f -r build
	mkdir build

%_tb:
	@echo ""
	@echo "\033[94m ##### Executing Testbench: $@ ##### \033[0m"
	cd build;${GHDL} -e --ieee=synopsys ${GHDLEFLAGS} $@
	cd build;${GHDL} -r -v --ieee=synopsys $@  --wave=trace_$@.ghw

test: init ${PRIO_SRC_O} ${SRC_O} ${SIM_O} vhpi ${SIM_NMS}
