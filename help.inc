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
include 'Network\socket\socket_consts.asm'
include 'Screenshot\Screenshot.asm'
include 'Graphics\Graph.asm'
include 'Network\socket\socket_main.asm'
include 'Network\socket\socket_funcs.asm'

include 'Network\socket\socket_data.inc'
include 'Network\Client.asm'
