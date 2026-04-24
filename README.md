## About this repository:

This repository is used for the purpose of group collaboration, namely, VCS.
What's contained here is not only source code itself, also the project plan and related exercises on RTL.
Temporary it's private and will be public soon after the code is submitted and reviewed by university.

## About this coursework:

Work done here is a part of assessments involved in the unit of EEME200002 at University of Bristol.
In general, the desired function on FPGA is to find the peak value from the generated sequence, 
then gives out the corresponding information based on the input from PuTTY.

A bottom-up approach is utilised in this programme:
	Start from breaking the target into small tasks.
	Then draft their corresponding FSM, ASM chart on paper.
	Implement them in VHDL firstly, then put them together.
  After carefully tested in simulation, synthesis it on FPGA.

The tool-chain required ranges from Altera Quaratus Prime to Xilinx Vivado, of course, community free version, 
so you can carry out some trials easily.

The description above is so brief that it's worthwhile referring to the official website of this unit for more details:

Online guidance: https://seis.bristol.ac.uk/~sy13201/digital_design/ECAD/A2_index.htm 
Unit info: https://www.bris.ac.uk/unit-programme-catalogue/UnitDetails.jsa?ayrCode=25%2F26&unitCode=EEME20002
Beyond these, there is another separated Assessment Detail.pdf also attached.

Nevertheless, these discussions only applies to the minimum requirements of this task.
For anyone who pursues at least a little serious experience in digital design, like us, 
what's recommended is mentioned below:
	A. Fully utilise most of functions in Xilinx Vivado Design Suite, including:
		1. Debugging process, like breakpoints and step simulation.
		2. Identify potential problems from "Report Methodology".
		3. Use timing tool to accomoplish STA.
		4. Observe the schematics to ensure the degisn consistent with expected one.
	B. Optimise the latency:
		Pipelining is not required since it will introduce some extra clock cycles and for this task, maybe not ideal.
		Other techniques like breaking down cascaded MUX, decreasing fan in/out would be more suitable.
	C. Understand what's happening behind and be proficient at VHDL syntax.

Also, some bad habits like HLS(high level synthesis) from C code, is not prohibited.
Therefore, I have written some C files with a similar function to 
  A, demonstrate the task requirement to my group members; 
  B, prepare to make a comparison in our VHDL code and the generated one, at leisure.

## About us:

  The dictator, me, Xinrui Zhu,  Player A: Yuan Ren,
  Player B: Julia Young,
  Player C: Yuhao Jiang,
  Player D: Xi Zhao.

## Statement:

Please feel free to clone this repo for any purpose, it's Github here instead of Google Scholar, so you don't need to pay for anything.
In the end, thanks to my group members, I cannot have such a archivevement without them.<br>
Not at all.
