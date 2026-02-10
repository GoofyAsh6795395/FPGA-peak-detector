transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+TEST_TOP  -L xil_defaultlib -L xpm -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.TEST_TOP xil_defaultlib.glbl

do {TEST_TOP.udo}

run 1000ns

endsim

quit -force
