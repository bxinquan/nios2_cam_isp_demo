# TCL File Generated by Component Editor 12.1
# Fri May 07 21:06:51 CST 2021
# DO NOT MODIFY


# 
# avalon_isp_lite "avalon_isp_lite" v1.0
# bxq 2021.05.07.21:06:51
# avalon_isp_lite
# 

# 
# request TCL package from ACDS 12.1
# 
package require -exact qsys 12.1


# 
# module avalon_isp_lite
# 
set_module_property DESCRIPTION avalon_isp_lite
set_module_property NAME avalon_isp_lite
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP bxq
set_module_property AUTHOR bxq
set_module_property DISPLAY_NAME avalon_isp_lite
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL avalon_isp_lite
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file avalon_isp_lite.v VERILOG PATH rtl/avalon_isp_lite.v
add_fileset_file isp_top.v VERILOG PATH isp_lite/isp_top.v
add_fileset_file isp_blc.v VERILOG PATH isp_lite/isp_blc.v
add_fileset_file isp_bnr.v VERILOG PATH isp_lite/isp_bnr.v
add_fileset_file isp_ccm.v VERILOG PATH isp_lite/isp_ccm.v
add_fileset_file isp_csc.v VERILOG PATH isp_lite/isp_csc.v
add_fileset_file isp_demosaic.v VERILOG PATH isp_lite/isp_demosaic.v
add_fileset_file isp_dgain.v VERILOG PATH isp_lite/isp_dgain.v
add_fileset_file isp_ee.v VERILOG PATH isp_lite/isp_ee.v
add_fileset_file isp_gamma.v VERILOG PATH isp_lite/isp_gamma.v
add_fileset_file isp_stat_ae.v VERILOG PATH isp_lite/isp_stat_ae.v
add_fileset_file isp_stat_awb.v VERILOG PATH isp_lite/isp_stat_awb.v
add_fileset_file isp_utils.v VERILOG PATH isp_lite/isp_utils.v
add_fileset_file isp_wb.v VERILOG PATH isp_lite/isp_wb.v


# 
# parameters
# 
add_parameter BITS INTEGER 8
set_parameter_property BITS DEFAULT_VALUE 8
set_parameter_property BITS DISPLAY_NAME BITS
set_parameter_property BITS TYPE INTEGER
set_parameter_property BITS UNITS None
set_parameter_property BITS ALLOWED_RANGES -2147483648:2147483647
set_parameter_property BITS HDL_PARAMETER true
add_parameter WIDTH INTEGER 1280
set_parameter_property WIDTH DEFAULT_VALUE 1280
set_parameter_property WIDTH DISPLAY_NAME WIDTH
set_parameter_property WIDTH TYPE INTEGER
set_parameter_property WIDTH UNITS None
set_parameter_property WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property WIDTH HDL_PARAMETER true
add_parameter HEIGHT INTEGER 960
set_parameter_property HEIGHT DEFAULT_VALUE 960
set_parameter_property HEIGHT DISPLAY_NAME HEIGHT
set_parameter_property HEIGHT TYPE INTEGER
set_parameter_property HEIGHT UNITS None
set_parameter_property HEIGHT ALLOWED_RANGES -2147483648:2147483647
set_parameter_property HEIGHT HDL_PARAMETER true
add_parameter BAYER INTEGER 0
set_parameter_property BAYER DEFAULT_VALUE 0
set_parameter_property BAYER DISPLAY_NAME BAYER
set_parameter_property BAYER TYPE INTEGER
set_parameter_property BAYER UNITS None
set_parameter_property BAYER ALLOWED_RANGES -2147483648:2147483647
set_parameter_property BAYER HDL_PARAMETER true
add_parameter STAT_BITS INTEGER 28
set_parameter_property STAT_BITS DEFAULT_VALUE 28
set_parameter_property STAT_BITS DISPLAY_NAME STAT_BITS
set_parameter_property STAT_BITS TYPE INTEGER
set_parameter_property STAT_BITS UNITS None
set_parameter_property STAT_BITS HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true

add_interface_port reset reset reset Input 1


# 
# connection point as
# 
add_interface as avalon end
set_interface_property as addressAlignment NATIVE
set_interface_property as addressUnits WORDS
set_interface_property as associatedClock clock
set_interface_property as associatedReset reset
set_interface_property as bitsPerSymbol 8
set_interface_property as burstOnBurstBoundariesOnly false
set_interface_property as burstcountUnits WORDS
set_interface_property as explicitAddressSpan 0
set_interface_property as holdTime 0
set_interface_property as linewrapBursts false
set_interface_property as maximumPendingReadTransactions 0
set_interface_property as readLatency 0
set_interface_property as readWaitTime 1
set_interface_property as setupTime 0
set_interface_property as timingUnits Cycles
set_interface_property as writeWaitTime 0
set_interface_property as ENABLED true

add_interface_port as as_address address Input "(BITS+3) - (0) + 1"
add_interface_port as as_read read Input 1
add_interface_port as as_readdata readdata Output 32
add_interface_port as as_write write Input 1
add_interface_port as as_writedata writedata Input 32
set_interface_assignment as embeddedsw.configuration.isFlash 0
set_interface_assignment as embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment as embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment as embeddedsw.configuration.isPrintableDevice 0


# 
# connection point conduit_end
# 
add_interface conduit_end conduit end
set_interface_property conduit_end associatedClock clock
set_interface_property conduit_end associatedReset ""
set_interface_property conduit_end ENABLED true

add_interface_port conduit_end pclk export Input 1
add_interface_port conduit_end rst_n export Input 1
add_interface_port conduit_end in_href export Input 1
add_interface_port conduit_end in_vsync export Input 1
add_interface_port conduit_end in_raw export Input BITS
add_interface_port conduit_end out_href export Output 1
add_interface_port conduit_end out_vsync export Output 1
add_interface_port conduit_end out_y export Output BITS
add_interface_port conduit_end out_u export Output BITS
add_interface_port conduit_end out_v export Output BITS


# 
# connection point interrupt_sender
# 
add_interface interrupt_sender interrupt end
set_interface_property interrupt_sender associatedAddressablePoint as
set_interface_property interrupt_sender associatedClock clock
set_interface_property interrupt_sender associatedReset reset
set_interface_property interrupt_sender ENABLED true

add_interface_port interrupt_sender irq irq Output 1

