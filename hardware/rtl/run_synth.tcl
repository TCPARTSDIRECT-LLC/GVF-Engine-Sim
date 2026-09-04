read_verilog -sv gvf_core_top.sv
read_verilog -sv gvf_bitline_comparator.sv

# Target Xilinx Artix-7
synth_design -top gvf_core_top -part xc7a35tcpg236-1

report_utilization -file utilization_report.txt
report_power -file power_report.txt
exit
