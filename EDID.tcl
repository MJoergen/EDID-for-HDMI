if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vlib states

vmap work rtl_work
vmap states rtl_work

vcom -work states [pwd]/states.vhd
vcom -work work [pwd]/toplevel.vhd
vcom -work work [pwd]/conv.vhd
vcom -work work [pwd]/EDID.vhd
vcom -work work [pwd]/I2C.vhd
vcom -work work [pwd]/UART.vhd

vsim toplevel

add wave -recursive *

force clk 0, 1 13.5 -r 27
force RST 1 0, 0 50
force btn1 1 50, 0 77

view structure
view signals

run 500 us

view -undock wave
wave zoomfull