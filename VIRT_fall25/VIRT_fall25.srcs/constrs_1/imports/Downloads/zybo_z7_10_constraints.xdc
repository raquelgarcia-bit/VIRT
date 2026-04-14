##------------------------------------------------------------------------------
## Zybo Z7-10 Constraints File Template
## OV7670 Camera to HDMI Project
## Fill in PIN_XX with actual pin locations from Zybo Z7-10 schematic/master XDC
##------------------------------------------------------------------------------

## System Clock (125 MHz)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_125mhz_in]
create_clock -period 8.000 -name sys_clk [get_ports clk_125mhz_in]
## test
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk125mhz_in_IBUF]

## Reset Button
## FIXME: come back to this
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst]

## Center Button (mode select)
## FIXME
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports btnc]

##------------------------------------------------------------------------------
## HDMI Output (via TMDS)
##------------------------------------------------------------------------------
## HDMI TX Clock
set_property -dict {PACKAGE_PIN H16 IOSTANDARD TMDS_33} [get_ports TMDS_Clk_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD TMDS_33} [get_ports TMDS_Clk_n]

## HDMI TX Data Channels
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {TMDS_Data_p[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {TMDS_Data_n[0]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {TMDS_Data_p[1]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {TMDS_Data_n[1]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {TMDS_Data_p[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {TMDS_Data_n[2]}]

##------------------------------------------------------------------------------
## LEDs
##------------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
#set_property -dict {PACKAGE_PIN PIN_XX IOSTANDARD LVCMOS33} [get_ports {led[4]}]
#set_property -dict {PACKAGE_PIN PIN_XX IOSTANDARD LVCMOS33} [get_ports {led[5]}]
#set_property -dict {PACKAGE_PIN PIN_XX IOSTANDARD LVCMOS33} [get_ports {led[6]}]
#set_property -dict {PACKAGE_PIN PIN_XX IOSTANDARD LVCMOS33} [get_ports {led[7]}]

##------------------------------------------------------------------------------
## Configuration
##------------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
