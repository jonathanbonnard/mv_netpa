onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_cnn_process/u1/clk
add wave -noupdate /tb_cnn_process/u1/reset_n
add wave -noupdate /tb_cnn_process/u1/enable
add wave -noupdate /tb_cnn_process/u1/in_data
add wave -noupdate /tb_cnn_process/u1/in_dv
add wave -noupdate /tb_cnn_process/u1/in_fv
add wave -noupdate /tb_cnn_process/u1/out_data
add wave -noupdate /tb_cnn_process/u1/out_dv
add wave -noupdate /tb_cnn_process/u1/out_fv
add wave -noupdate /tb_cnn_process/u1/data_data
add wave -noupdate /tb_cnn_process/u1/data_dv
add wave -noupdate /tb_cnn_process/u1/data_fv
add wave -noupdate /tb_cnn_process/u1/conv1_data
add wave -noupdate /tb_cnn_process/u1/conv1_dv
add wave -noupdate /tb_cnn_process/u1/conv1_fv
add wave -noupdate /tb_cnn_process/u1/stride1_data
add wave -noupdate /tb_cnn_process/u1/stride1_data_valid
add wave -noupdate /tb_cnn_process/u1/stride1_dv
add wave -noupdate /tb_cnn_process/u1/stride1_fv
add wave -noupdate /tb_cnn_process/u1/pool1_data
add wave -noupdate /tb_cnn_process/u1/pool1_dv
add wave -noupdate /tb_cnn_process/u1/pool1_fv
add wave -noupdate -divider stride_gen
add wave -noupdate /tb_cnn_process/u1/stride1/clk
add wave -noupdate /tb_cnn_process/u1/stride1/reset_n
add wave -noupdate /tb_cnn_process/u1/stride1/enable
add wave -noupdate /tb_cnn_process/u1/stride1/in_data
add wave -noupdate /tb_cnn_process/u1/stride1/in_dv
add wave -noupdate /tb_cnn_process/u1/stride1/in_fv
add wave -noupdate /tb_cnn_process/u1/stride1/out_data
add wave -noupdate /tb_cnn_process/u1/stride1/out_dv
add wave -noupdate /tb_cnn_process/u1/stride1/out_fv
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2699 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 316
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {10708 ps}
