// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
// Date        : Mon Feb  9 19:03:47 2026
// Host        : DESKTOP-U9E3C55 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {c:/Users/Xinrui
//               Zhu/iCloudDrive/Documents/Projects/Courseworks/Engineering Practice/Group Project/VHDL
//               code/Peak_Detector.gen/sources_1/ip/clk_wiz_2/clk_wiz_2_stub.v}
// Design      : clk_wiz_2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* CORE_GENERATION_INFO = "clk_wiz_2,clk_wiz_v6_0_16_0_0,{component_name=clk_wiz_2,use_phase_alignment=true,use_min_o_jitter=false,use_max_i_jitter=false,use_dyn_phase_shift=false,use_inclk_switchover=false,use_dyn_reconfig=false,enable_axi=0,feedback_source=FDBK_AUTO,PRIMITIVE=MMCM,num_out_clk=1,clkin1_period=83.333,clkin2_period=10.0,use_power_down=false,use_reset=false,use_locked=false,use_inclk_stopped=false,feedback_type=SINGLE,CLOCK_MGR_TYPE=NA,manual_override=false}" *) 
module clk_wiz_2(clk_out, clk_in)
/* synthesis syn_black_box black_box_pad_pin="clk_in" */
/* synthesis syn_force_seq_prim="clk_out" */;
  output clk_out /* synthesis syn_isclock = 1 */;
  input clk_in;
endmodule
