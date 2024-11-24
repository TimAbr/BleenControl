struct BUTTON

	x	dd ?
	y	dd ?
	right	dd ?
	bottom	dd ?
	text	dd ?
	color	dd ?
	textColor dd ?

ends

num_cells = 4
cells_gap = 25
add_template_width = 400
add_template_half_width = 200
add_template_border = 15

start_screen = 0
main_screen = 1
client_screen = 2 
server_screen = 3 
control_mode = 4

include 'Network\Client.inc'
include 'Network\Server.inc'
include 'Network\socket\socket_consts.asm'
include 'Screenshot\Screenshot.asm'
include 'Graphics\Graph.asm'
include 'Network\socket\socket_main.asm'
include 'Network\socket\socket_funcs.asm'

include 'Network\socket\socket_data.inc'
include 'Network\Client.asm'
include 'Network\Server.asm'

main_color = 0x2e2e2e
sec_color = 0x343536
menu_color = 0x1f1f1f

Request.getId   dd  0
Request.closeConnection dd  -1
Request.sendID.server  dd  1
Request.sendID.client  dd  2
Request.closeID  dd  3
Request.serverCondition dd 4

isReady   dd 0
close_flag dd 0
close_flag_buf  dd 0

mode    dd -1
server_mode = 0
client_mode = 1

dev_mode dd 0

output_buf TCHAR 33 dup '0',0

text_ticks_compress TCHAR "Compression ticks: "
buf_compress TCHAR 33 dup '0',0
ticks_compress dd 0

text_ticks_total TCHAR "Total ticks: "
buf_total TCHAR 33 dup '0',0
ticks_total dd 0

text_ticks_output TCHAR "Output ticks: "
buf_output TCHAR 33 dup '0',0
ticks_output dd 0

text_ticks_send TCHAR "Network ticks: "
buf_send TCHAR 33 dup '0',0
ticks_send dd 0 



thread_rect_1  dd 0, 0, 0, 0
end_flag_1   dd 1


thread_rect_2  dd 0, 0, 0, 0
end_flag_2   dd 1


thread_rect_3  dd 0, 0, 0, 0
end_flag_3   dd 1


thread_rect_4  dd 0, 0, 0, 0
end_flag_4   dd 1

thread_output dd 0
thread_send dd 0
thread_recieve dd 0
thread_compress dd 0

temp_recieve dd 0



buf_format TCHAR "%lu",0

hBuf  dd 0
lpBuf dd 0

minimized dd 0
