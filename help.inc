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
