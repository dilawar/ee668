ghdl -i *.vhd
ghdl -m memtest
ghdl -r memtest --stop-time=40ms --vcd=dilawar.vcd
