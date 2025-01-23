transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/floating_point_adder.sv}

vlog -sv -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/tb_floating_point_adder.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb_floating_point_adder

add wave *
view structure
view signals
run -all
