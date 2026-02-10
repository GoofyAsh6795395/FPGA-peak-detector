transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xpm
vlib activehdl/xil_defaultlib

vmap xpm activehdl/xpm
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xpm  -sv2k12 "+incdir+../../../../../../../../../../../../Xilinx/2025.1/Vivado/data/rsb/busdef" "+incdir+../../../Peak_Detector.gen/sources_1/ip/clk_wiz_0" "+incdir+../../../Peak_Detector.gen/sources_1/ip/clk_wiz_1" "+incdir+../../../Peak_Detector.gen/sources_1/ip/clk_wiz_2" -l xpm -l xil_defaultlib \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  \
"C:/Xilinx/2025.1/Vivado/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -93  \
"../../../Peak_Detector.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_sim_netlist.vhdl" \
"../../../Supporting File/peak_detector/UART_RX_CTRL.vhd" \
"../../../Supporting File/uart_demo/UART_RX_CTRL.vhd" \
"../../../Supporting File/peak_detector/UART_TX_CTRL.vhd" \
"../../../Supporting File/uart_demo/control_unit_tst.vhd" \
"../../../Supporting File/uart_demo/test_top.vhd" \

vlog -work xil_defaultlib \
"glbl.v"

