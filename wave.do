onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/TOP_DRIVER/clock
add wave -noupdate /tb/TOP_DRIVER/reset
add wave -noupdate /tb/TOP_DRIVER/ignition
add wave -noupdate /tb/TOP_DRIVER/d_door
add wave -noupdate /tb/TOP_DRIVER/p_door
add wave -noupdate /tb/TOP_DRIVER/switch
add wave -noupdate /tb/TOP_DRIVER/pedal
add wave -noupdate /tb/TOP_DRIVER/set
add wave -noupdate /tb/TOP_DRIVER/siren
add wave -noupdate /tb/TOP_DRIVER/fp_status
add wave -noupdate -radix decimal /tb/TOP_DRIVER/EA
add wave -noupdate -radix decimal /tb/TOP_DRIVER/t
add wave -noupdate -divider ARM_DRIVER
add wave -noupdate /tb/TOP_DRIVER/en_arm
add wave -noupdate -radix decimal /tb/TOP_DRIVER/ARM_DRIVER/EA
add wave -noupdate /tb/TOP_DRIVER/ARM_DRIVER/start_count
add wave -noupdate -divider timer
add wave -noupdate /tb/TOP_DRIVER/en_timer
add wave -noupdate /tb/TOP_DRIVER/load
add wave -noupdate -radix decimal /tb/TOP_DRIVER/COUNTER/t
add wave -noupdate /tb/TOP_DRIVER/waited
add wave -noupdate -divider DISARM_DRIVER
add wave -noupdate /tb/TOP_DRIVER/en_disarm
add wave -noupdate -radix decimal /tb/TOP_DRIVER/DISARM_DRIVER/EA
add wave -noupdate /tb/TOP_DRIVER/DISARM_DRIVER/start_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {365 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {379 ns} {1033 ns}
