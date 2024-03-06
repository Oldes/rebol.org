Rebol [
	title: "Simple accordion style"
	file: %simple-accordion-style.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 22-08-2018
	version: 0.1.0
	Purpose: {Create accordions, using a simple but versatile function.}
	Comment: {Making a tree list with accordions is left as an exercize to the reader ;) }
	History: [
		0.1.0 [22-08-2018 "First version"]
	]
	Category: [util vid view]
	library: [
		level: 'beginner
		platform: 'all
		type: 'how-to
		domain: [gui vid]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
	]
]

fold-next-face: func [face /local next-face next-pos factor height][
	next-face: first next-pos: next find face/parent-face/pane face

	either next-face/extra [
		face/extra: next-face/size
		next-face/size: 0x0
		next-face/extra: false
		factor: -1
	][
		next-face/size: face/extra
		next-face/extra: true
		factor: 1
	]
	height: face/extra/y
	foreach fac next-pos [fac/offset/y: factor * height + fac/offset/y]
	face/parent-face/size/y: factor * height + face/parent-face/size/y

	while [all [face: face/parent-face attempt [face/parent-face/pane not none? face/extra]]] [
		next-pos: next find face/parent-face/pane face
		foreach fac next-pos [fac/offset/y: factor * height + fac/offset/y]
		face/parent-face/size/y: factor * height + face/parent-face/size/y
	]
	show any [face/parent-face find-window face]
]
toggle-fold-all: func [pane][
	foreach [face other] pane [
		set-face face not get-face face
		do-face face none
	]
]

gui: layout [
	do [sp: 4x4] origin sp space sp 
	style tog tog with [extra: false] [fold-next-face face]
	style text text with [extra: true]
	btn "Toggle fold all" [toggle-fold-all next face/parent-face/pane]
	tog " - " " + " 
	text "Place a face here. Only one, but it can be a panel." 
	tog " - " " + " 
	text "And also a panel that contains an accordion..." 
	tog " - " " + " 
	text "Remember to add an 'extra' facet to every face" 
	tog " - " " + " 
	text "Initialize 'extra' to false for toggles and to true for the others"
]

view center-face gui
	
	