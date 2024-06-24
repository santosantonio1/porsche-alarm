if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

vlog -work work hdl/top.v
vlog -work work hdl/arm.v
vlog -work work hdl/disarm.v
vlog -work work hdl/timer.v
vlog -work work hdl/fuelpump.v
vlog -work work hdl/tb.v

vsim -voptargs=+acc=lprn -t ns work.tb

set StdArithNoWarnings 1
set StdVitalGlitchNoWarnings 1

do wave.do 

run 1 us