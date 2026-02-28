##------------------------------------------------------------------------------
## Zybo Z7-10 Constraints File Template
## OV7670 Camera to HDMI Project
## Fill in PIN_XX with actual pin locations from Zybo Z7-10 schematic/master XDC
##------------------------------------------------------------------------------

## System Clock (125 MHz)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk125mhz_in]
create_clock -period 8.000 -name sys_clk [get_ports clk125mhz_in]
## test
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk125mhz_in_IBUF] 

## Reset Button
## FIXME: come back to this
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst]

## Center Button (mode select)
## FIXME
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports btnc]

##------------------------------------------------------------------------------
## OV7670 Camera Interface
##------------------------------------------------------------------------------
## Camera I2C/SCCB
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports ov7670_sioc]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports ov7670_siod]

## Camera Control
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports ov7670_rst_n]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports ov7670_pwdn]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports ov7670_xclk]

## Camera Sync Signals
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports ov7670_vsync]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports ov7670_href]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports ov7670_pclk]

## Camera Data Bus [7:0]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[0]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[1]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[2]}]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[3]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[4]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[5]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[6]}]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports {ov7670_d[7]}]

## Camera PCLK is a clock input - constrain it
create_clock -period 40.000 -name ov7670_pclk [get_ports ov7670_pclk]
set_input_delay -clock ov7670_pclk -min 5.000 [get_ports {ov7670_d[*]}]
set_input_delay -clock ov7670_pclk -max 10.000 [get_ports {ov7670_d[*]}]
set_input_delay -clock ov7670_pclk -min 5.000 [get_ports ov7670_href]
set_input_delay -clock ov7670_pclk -max 10.000 [get_ports ov7670_href]
set_input_delay -clock ov7670_pclk -min 5.000 [get_ports ov7670_vsync]
set_input_delay -clock ov7670_pclk -max 10.000 [get_ports ov7670_vsync]

## Asynchronous clock groups
set_clock_groups -asynchronous -group [get_clocks ov7670_pclk] -group [get_clocks -include_generated_clocks sys_clk]

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
