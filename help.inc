struct BUTTON

	x	dd ?
	y	dd ?
	right	dd ?
	bottom	dd ?
	text	dd ?
	color	dd ?
	textColor dd ?
  textSize dd ?

ends


struct MouseListElement
  Left  dd ?
	Down	dd ?
	NextP dd ?
  NextH dd ?

ends

MouseHead MouseListElement 0,0,0
MouseCur dd MouseHead

MouseTotal dd 0
MouseControl dd 0
KeyboardControl dd 0

struct KeyboardListElement

  Char  dd ?
  Down	dd ?
	NextP dd ?
  NextH dd ?

ends

KeyboardHead KeyboardListElement 0,0,0,0
KeyboardCur dd KeyboardHead

KeyboardTotal dd 0

num_cells = 4
cells_gap = 25
add_template_width = 400
add_template_half_width = 200
add_template_border = 15

num_cells_ip = 12
cells_gap_ip = 5
add_template_width_ip = 700
add_template_half_width_ip = 350
add_template_border_ip = 15

start_screen = 0
main_screen = 1
client_screen = 2 
server_screen = 3 
control_mode = 4
change_ip_screen = 5

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

dev_mode dd 1

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

text_x_pos TCHAR "Mouse x-position: "
buf_x_pos TCHAR 10 dup '0',0

text_y_pos TCHAR "Mouse y-position: "
buf_y_pos TCHAR 10 dup '0',0

text_lbtn_down TCHAR "Down",0
text_lbtn_up TCHAR "Up",0

text_img_size TCHAR "Image size (compressed): "
buf_img_size TCHAR 10 dup '0',0

text_min_x TCHAR "Min X: "
buf_min_x TCHAR 10 dup '0',0
text_min_y TCHAR "Min Y: "
buf_min_y TCHAR 10 dup '0',0
text_max_x TCHAR "Max X: "
buf_max_x TCHAR 10 dup '0',0
text_max_y TCHAR "Max Y: "
buf_max_y TCHAR 10 dup '0',0
text_clicks TCHAR "Clicks: "
buf_clicks TCHAR 10 dup '0',0



thread_rect_1  dd 0, 0, 0, 0
end_flag_1   dd 1


thread_rect_2  dd 0, 0, 0, 0
end_flag_2   dd 1


thread_rect_3  dd 0, 0, 0, 0
end_flag_3   dd 1


thread_rect_4  dd 0, 0, 0, 0
end_flag_4   dd 1

thread_output dd 0
thread_recieve dd 0
thread_control dd 0
thread_movemouse dd 0
thread_compress_2 dd 0
thread_compress_3 dd 0
thread_compress_4 dd 0
thread_drawInterface dd 0
thread_send dd 0

mut_min dd 0
mut_name TCHAR "mut_min",0

temp_recieve dd 0
temp_recieve_1 dd 0

mouse_last dd 0


buf_format TCHAR "%lu",0

hBuf  dd 0
lpBuf dd 0

minimized dd 0

MousePos dd 0, 0
MousePos_last dd 0, 0
MousePos_temp dd 0, 0
MouseDown dd 0
InputSymbol dd 0
CountMoves dd 0

res1080 = 1
res720 = 2
res480 = 3
res360 = 4

cur_res dd 1
temp_res dd 1
change_flag dd 0
temp_flag dd 0

image_width dd 1920
image_height dd 1080

cursor_size dd 32
window_active dd 1

show_efficiency dd 0
control_mouse dd 0
control_keyboard dd 0
SmoothMouse dd 0

max_x dd 0
max_y dd 0
min_x dd 0
min_y dd 0


max_x_proc_2 dd 0
max_y_proc_2 dd 0
min_x_proc_2 dd 0
min_y_proc_2 dd 0


max_x_proc_3 dd 0
max_y_proc_3 dd 0
min_x_proc_3 dd 0
min_y_proc_3 dd 0

max_x_proc_4 dd 0
max_y_proc_4 dd 0
min_x_proc_4 dd 0
min_y_proc_4 dd 0

temp_compress_2 dd 0
temp_compress_3 dd 0
temp_compress_4 dd 0

CircleRadius = 10
Circle1 dd 0
Circle2 dd 0
Circle3 dd 0

mutex dd 0
send_running dd 0
