## About this repository

<p>
This repository is used for the purpose of group collaboration, namely, VCS.<br>
What's contained here is not only source code itself, also the project plan and related exercises on RTL.<br>
Temporary it's private and will be public soon after the code is submitted and reviewed by university.
</p>

## About this coursework

<p>
Work done here is a part of assessments involved in the unit of EEME200002 at University of Bristol.<br>
In general, the desired function on FPGA is to find the peak value from the generated sequence, 
then gives out the corresponding information based on the input from PuTTY.
</p>

A bottom-up approach is utilised in this program:
<ol type="1">
	<li>Start from breaking the target into small tasks.</li>
	<li>Then draft their corresponding FSM, ASM chart on paper.</li>
	<li>Implement them in VHDL firstly, then put them together.</li>
  	<li>After carefully tested in simulation, synthesis it on FPGA.</li>
</ol><br>

The tool-chain required ranges from Altera Quaratus Prime to Xilinx Vivado, of course, community free version, 
so you can carry out some trials easily.

The description above is so brief that it's worthwhile referring to the official website of this unit for more details:
Online guidance: https://seis.bristol.ac.uk/~sy13201/digital_design/ECAD/A2_index.htm <br>
Unit info: https://www.bris.ac.uk/unit-programme-catalogue/UnitDetails.jsa?ayrCode=25%2F26&unitCode=EEME20002 <br>
Beyond these, there is another separated Assessment Detail.pdf also attached. <br>

Nevertheless, these discussions only applies to the minimum requirements of this task.<br>
For anyone who pursues at least a little serious experience in digital design, like us, it is recommended that:
<ol type = "A">
	<li>Fully utilise most of functions in Xilinx Vivado Design Suite, including:
		<ol type = "1">
			<li>Debugging process, like breakpoints and step simulation.</li>
			<li>Identify potential problems from "Report Methodology".</li>
			<li>Use timing tool to accomoplish STA.</li>
			<li>Observe the schematics to ensure the degisn consistent with expected one.</li>
		</ol>
	</li>
	<li>Optimise the latency:
		<ol type = '1'>
			<li>Pipelining is not required since it will introduce some extra clock cycles and for this task, maybe not ideal.</li>
			<li>Other techniques like breaking down cascaded MUX, decreasing fan in/out would be more suitable.</li>
		</ol>
	</li>
	<li>Understand what's happening behind and be proficient at VHDL syntax.
	</li>
</ol>

Also, some bad habits like HLS(high level synthesis) from C code, is not prohibited.<br>
Therefore, I have written some C files with a similar function to:
<ol type = "A">
	<li>demonstrate the task requirement to my group members </li>
	<li>prepare to make a comparison in our VHDL code and the generated one, if leisure.</li>
</ol>

## About us
<ul>
  <li>The dictator, me, Xinrui Zhu,</li>
  <li>Player A: Yuan Ren,</li>
  <li>Player B: Julia Young,</li>
  <li>Player C: Yuhao Jiang,</li>
  <li>Player D: Xi Zhao.</li>
</ul>

## Statement

Please feel free to clone this repo for any purpose, it's Github here instead of Google Scholar, so you don't need to pay for anything.<br>
In the end, thanks to my group members, I cannot have such a archivevement without them.
<br>
Not at all.
