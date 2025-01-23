transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/fpu_sp_top.v}
vlog -vlog01compat -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/fpu_sp_sub.v}
vlog -vlog01compat -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/fpu_sp_mul.v}
vlog -vlog01compat -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/fpu_sp_div.v}
vlog -vlog01compat -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/fpu_sp_add.v}

vlog -vlog01compat -work work +incdir+C:/SJ/Sem\ 7/EN3021_Digital\ System\ Design/fp {C:/SJ/Sem 7/EN3021_Digital System Design/fp/fpu_sp_add_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  fpu_sp_add_tb

add wave *
view structure
view signals
run -all
