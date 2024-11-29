create_clock -period 10.000 -name CLK -waveform {0.000 5.000} -add [get_ports clk]
set_property -dict {PACKAGE_PIN C8} [get_ports clk]