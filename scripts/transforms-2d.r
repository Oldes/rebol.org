REBOL [
	title: "2D transformations"
	Purpose: "Visualize and experiment with 2D transformation matrices"
	comment: "If you find a nice preset please let me know!"
	needs: "%simple-spin-number-style.r, %simple-pop-down-style.r"
	Date: 12-10-2020
	Version: 0.5.1
	File: %transforms-2d.r
	Author: "Marco Antoniazzi"
	eMail: [luce80 AT libero DOT it]
	History: [
		0.0.1 [29-07-2020 "Started"]
		0.5.1 [12-10-2020 "Mature enough"]
	]
	Category: [vid gfx]
	library: [
		level: 'intermediate
		platform: 'all
		type: 'tool
		domain: [math]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: none
		see-also: none
	]
	thumbnail: https://i.postimg.cc/1XkKbL1r/transforms-2d-mini.png
	todo: {
		- grid size
		- combine transformations
	}
]

; modules
; script-version , undirize , choose_file , download , load-script-thru
	do decompress
	64#{
	eJx1VUuT3DQQvvtX9CqV4lHxiCo4uUi2gMApVEIoTmZCaeyesVlZMpK8zkDx3+nWw7OzWcoHW+rX191ftyvfuXEO9T06P1rTwHExHbSVt4vrEFof3GhON3uopLad0pAV
	wc+qQw/doJyv9mSxefhqRw9UUdJAZ6dZ44QmZJMm2WAAAR/qD1JANfNZKq2hhK3C4BYQ73/8/u0bAcqcSzzRCkiyEk+Q0YRFXnV2Pl9AsqRArIKtw0JgipjvFtOPbvwb
	S+LiPYbFGQ8Koid7pHAIswoDsAB7GE2wJD6OGncRPIlaPt3A4vQNlJLFqrC0Sa6iYrUOpMn6pgchfxeQNA6qu4OgRh3PZOlwsveYT9WAqo/fjLkbrPX4B4cssOk7oHvQ
	rtwt1qmNmpCxLCaQ/7baLhtw+NeCPtR8Je8QZ2mNPsvsLr+q8QjGGry9uGN8XI54T5Dw4+iDf6CQ6+3wYHX0fi3q7Wq0Vf3GN6octFy+C9O0pao46A539dFAr4JKPBtx
	lQZXklNhiVfo6iP1HrQ62yWQhj5oEK9zBCoHNSngxwCfH62buEdfQEWeG5idPTn0kRwpTMETbCAEh3NAzzGJrSkGA4q3ICHqxGQIGpdS9bXBIItXjgRNhk/Fj8C5vJxZ
	lfOpGGOdh5CJvRHxDQmIZkkER2cnWNd1Fyu6s+6UxoDJ2aluQEoyNebCRC7lUSs/gPgpvhRMhEudkLBHy8VTexMj+6t6yVVRc8V3Gl1IWsSBDMVYgmNpcFgv4no8AnsQ
	b+dAE6YSnSkEuhjUo3LdQOYuxk8e2U+Z2HtmcZxS9vLzaMZpmbZ5ZrqODmPkRJKYe6LkZPuFLgbs7nidRbJsp1LWqJltowFpUWoc9hVc78IkT42FVNt8k0ifzdN0BLhX
	eqER+YzbXDtLN+322QCOlK8Df/YBp5Kt/AZewtfQPpc/yN+oyF6+Ww567ORr2y28Mpl8z2WY5j0zdEu1gc2zbCKyKqbIe7LlVOIKJpOMN95XKlBo6l+7FYVS+9OOhgYv
	b8HULUE7Oe4M8vCE0QXH0/LHksqvY6Cm513DqyNFjeMY4f9zIRUQNVZnzak0/QUwLWEMLzaO0uGpgSBLoke4/ZeYw9MjLluAPn8hkaB6PmtT+1rW3cOzNriFjw8SvOxX
	EF/unGCto9I+btGNFSmJIYS5kfIKiSxAa5VHe+duM7k435elRqU/vk6Lu9AkTW275VuYGqn4iHfxT5K4n/6XtDuIqeoOAZ2z7gbEr48HN1n/P+mfti8qwdIgT/S7Zj+r
	GwN+OoYptWqfnhiO/+8tY0gavGEoJRVXTKlmCfVtYiCIV9fM+ATCTuz3W7D/AGL3BZ7NCAAA
	}

	do load load-script-thru/flash/warn/from/version %simple-pop-down-style.r %../../gui/simple 0.0.4 ; 0.3.1
	do load load-script-thru/flash/warn/from/version %simple-spin-number-style.r %../../gui/simple 0.8.0 ; 0.9.0

; debug , math
	opened-console?: false

	old-print: :print
	print: func [value][opened-console?: true old-print value]
	
	get-err-id: func [
		value [error!]
		][
		value: get in disarm value 'id
		any [
			select [
				missing "missing parenthesis or bracket"
				no-value "a word has no value"
			] value
			value
		]
	]

	atan2: func [; author: Steeve Antoine 2009, modified by luce80
		"Angle of the vector (0,0)-(x,y) with arctangent y / x. The resulting angle is in range 0 360"
		x [number!] y [number!]
		][
		if x = 0 [x: 1e-10]
		;mod add arctangent y / x pick [0 180] x > 0 360 ; 0 at east
		add arctangent y / x pick [90 270] x > 0 ; 0 at north
	]
	load-math: func [; let's be more "tolerant" with the input strings
		text [string!]
		][
		text: copy text
		replace/all text "e+" "e£" ; avoid corner cases
		replace/all text "+" " + "
		replace/all text "e£" "e+"
		replace/all text "e-" "e£"
		replace/all text "-" " - "
		replace/all text "e£" "e-"
		replace/all text "*" " * "
		replace/all text "/" " / "
		load text
	]

; presets
	presets: copy/deep [
		"identity" ["1" "0" "0"  "0" "1" "0"  "0" "0" "1" 0 0 0]
		"move" ["1" "0" "a"  "0" "1" "b"  "0" "0" "1" 10 5 0]
		"rotate" ["cosine a" "- sine a" "0"  "sine a" "cosine a" "0"  "0" "0" "1" 45 0 0]
		"scale" ["a" "0" "0"  "0" "b" "0"  "0" "0" "1" 2 1.5 0]
		"mirror x" ["-1" "0" "0"  "0" "1" "0"  "0" "0" "1" 0 0 0]
		"mirror y" ["1" "0" "0"  "0" "-1" "0"  "0" "0" "1" 0 0 0]
		"skew" ["1" "- tangent a" "0"  "tangent b" "1" "0"  "0" "0" "1" 30 10 0]
		"roto-zoom" ["1" "- tangent a" "0"  "tangent a" "1" "0"  "0" "0" "1" 45 0 0]
		"perspective" ["1" "0" "0"  "0" "1" "0"  "a / 10000" "b / 10000" "1" 10 15 0]
		"taper x" ["d" "0" "0" "0" "1" "0" "0" "0" "1" 20 0 0 "y * a / 1000 + 1"]
		"skew x sine" ["1" "d" "0" "0" "1" "0" "0" "0" "1" 70 0 0 "(cosine y) * a / 100"]
		"cross cosine angles" ["d" "0" "0" "0" "e" "0" "0" "0" "1" 80 18 0 "(cosine (y * b / 10)) * a / 100 + 1" "(cosine (x * b / 10)) * a / 100 + 1"]
		"cross cosine squared"  ["d" "0" "0" "0" "e" "0" "0" "0" "1" -70 18 0 "(cosine (x * b / 10)) * a / 100 + 1" "(cosine (y * b / 10)) * a / 100 + 1"]
		"cross cosine sides"  ["d" "0" "0" "0" "e" "0" "0" "0" "1" 110 0 0 "cosine (y * a / 100)" "cosine (x * a / 100)"]
		"cross cosine -53"  ["d" "0" "0" "0" "e" "0" "0" "0" "1" 20 -53 0 "(cosine (y * b / 10)) * a / 100 + 1" "(cosine (x * b / 10)) * a / 100 + 1"]
		"bend x parabola" ["cosine d * y" "- sine d * x" "0"  "sine d * x" "cosine d * x" "0"  "0" "0" "1" 70 0 0 "a / 100"]
		"bend x cardio" ["cosine d" "- sine d" "0"  "sine d" "cosine d" "0"  "0" "0" "1" 60 0 0 "x * a / 100"]
		"bend roll" ["cosine d" "0" "0" "- sine d" "0" "0" "0" "0" "1" 120 0 0 "y * a / 100"]
		"bulge pinch" ["e" "0" "0" "0" "e" "0" "0" "0" "1" -70 0 0 "square-root (x * x) + (y * y)" "power d / 100 a / 100"]
		"bulge contract" ["d" "0" "0" "0" "d" "0" "x" "y" "d" 200 0 0 "1 / tangent (a / 10000)"]
		"wrap circle" ["cosine d" "0" "0" "0" "cosine d" "0" "0" "0" "1" 170 0 0 "((x * x) + (y * y)) * a / 10000"]
		"cone x" ["cosine d" "- sine d" "0" "0" "1" "0" "0" "0" "1" 80 0 0 "x * a / 100"]
		"fisheye" ["e" "0" "0" "0" "e" "0" "0" "0" "1" 20 0 0 "square-root (x * x) + (y * y)" "100 * tangent (arctangent d / a) / (d + .001)"]
		"pinwheel" ["cosine d * x" "- sine a" "0"  "sine a" "cosine d * y" "0"  "0" "0" "1" 120 0 0 "a / 100"]
		"curve y cyl" ["d" "0" "0"  "e" "1" "0"  "0" "0" "1" 224 156 0 "(cosine x) * b / 100" " x * a / 10000"]
		"curve y parabola" ["1" "0" "0" "d" "1" "0" "0" "0" "1" 160 0 0 "x * a / 10000"]
		"taper x sine" ["d" "0" "0" "0" "1" "0" "0" "0" "1" -45 30 90 "(sine (y * b / 10 + c)) * a / 100 + 1"]
		"taper x cosine" ["d" "0" "0" "0" "1" "0" "0" "0" "1" 40 30 0 "(cosine (y * b / 10)) * a / 100 + 1"]
		"taper x hyp" ["d" "0" "0" "0" "1" "0" "0" "0" "1" 10 30 0 "1 / (y * a / 1000 + 1)"]
		"twist x cosine" ["d" "0" "0" "0" "1" "0" "0" "0" "1" 30 30 0 "cosine (y * a / 10)"]
		"twist sine" ["cosine d" "- sine d" "0"  "sine d" "cosine d" "0"  "0" "0" "1" 10 0 0 "x * x * (a / 1000)"]
		"twirl" ["cosine e" "- sine e" "0"  "sine e" "cosine e" "0"  "0" "0" "1" 120 0 0 "square-root (x * x) + (y * y)" "d * a / 100"]
		"whirl" ["cosine e" "- sine e" "0"  "sine e" "cosine e" "0"  "0" "0" "1" 30 0 0 "square-root (x * x) + (y * y)" "1 / (d + 1e-10) * a * 100"]
		"whirl sine" ["1" "- sine e" "0"  "sine e" "1" "0"  "0" "0" "1" 80 0 0 "square-root (x * x) + (y * y)" "1 / (d + 1e-10) * a * 100"]
	]
	
; load_preset , make_preset , add_preset
	load_preset: func [data][
		foreach face win/pane [
			if face/style = 'field [set-face face any [first+ data ""]]
			if number? face/data [set-face face first+ data]
		]
		update
	]
	make_preset: func [name [string!] /local preset] [
		preset: reduce [name copy []]
		foreach face win/pane [
			if face/style = 'field [append preset/2 copy face/text]
			if number? face/data [append preset/2 face/data]
		]
		preset
	]
	add_preset: func [preset [block!]][
		either find pop-down-presets/data first preset [
			change find presets first preset preset ; overwrite
		][
			insert tail pop-down-presets/data first preset
			insert tail presets preset
		]
		set-face pop-down-presets first preset
	]
; make_points , load_matrix , transform
	squares: 10
	points: copy []

	make_points: func [][
		clear points
		repeat row squares + 1 [
			append/only points copy []
			for col 0 - (squares / 2) (squares / 2) 1 [
				append/only points/(row) reduce [col * 10 row - 1 - (squares / 2) * 10]
			]
		]
		;probe
		points
	]

	matrix: [
		[field-11 field-12 field-13]
		[field-21 field-22 field-23]
		[field-31 field-32 field-33]
	]
	M: [
		[0 0 0]
		[0 0 0]
		[0 0 0]
	]
	load_matrix: func [/local value][
		repeat row 3 [
			repeat col 3 [
				M/(row)/(col): either error? set/any 'value try [load-math get-face get matrix/(row)/(col)] [
					err: get-err-id value
					0
				][
					get/any 'value
				]
			]
		]
	]
	err: false
	get-M: func [row col /local value][
		if error? set/any 'value try [do M/(row)/(col)] [
			err: get-err-id value
			return 0
		]
		if not number? get/any 'value [
			err: "not a number"
			return 0
		]
		value
	]

	transform: func [][
		a: get-face spin-a
		b: get-face spin-b
		c: get-face spin-c

		h3-warn/color: green
		h3-warn/text: "OK"
		h3-err/text: ""
		show [h3-warn h3-err]

		repeat row squares + 1 [
			repeat col squares + 1 [
				x: points/(row)/(col)/1
				y: points/(row)/(col)/2
				
				d: case [
					error? set/any 'value try [do load-math get-face field-d] [err: get-err-id value  0]
					unset? get/any 'value [0]
					'else [value]
				]
				e: case [
					error? set/any 'value try [do load-math get-face field-e] [err: get-err-id value  0]
					unset? get/any 'value [0]
					'else [value]
				]
				; affine
				x': ((get-M 1 1) * x) + ((get-M 1 2) * y) + (get-M 1 3)
				y': ((get-M 2 1) * x) + ((get-M 2 2) * y) + (get-M 2 3)
				; non-affine
				w': ((get-M 3 1) * x) + ((get-M 3 2) * y) + (max .1 get-M 3 3) + 1e-10

				points/(row)/(col)/1: x' / w'
				points/(row)/(col)/2: y' / w'
			]
		]
		if err [
			h3-warn/color: red
			h3-warn/text: "Error"
			h3-err/text: form err
			show [h3-warn h3-err]
			err: false
		]
	]

; draw_mesh , redraw_mesh , update
	mesh: copy []
	draw_mesh: func [/local sqmidsize][
		; sqmidsize: squares * 10 / 2
		clear mesh
		insert tail mesh compose [
			translate (box-mesh/size / 2)
			; origin
			pen green
			line -50x0 50x0 ;(sqmidsize * -1x0) (sqmidsize * 1x0) 
			line 0x-50 0x50
			box -50x-50 50x50
			pen black
		]
		repeat row squares + 1 [
			if row = 2 [insert tail mesh [line-width 3 pen crimson]]
			if row = squares [insert tail mesh [line-width 3 pen magenta]]
			insert tail mesh [
				line
			]
			repeat col squares + 1 [
				insert tail mesh reduce [(as-pair round points/(row)/(col)/1 round points/(row)/(col)/2)]
			]
			if row = 2 [insert tail mesh [line-width 1 pen black]]
			if row = squares [insert tail mesh [line-width 1 pen black]]
		]

		repeat col squares + 1 [
			insert tail mesh [
				line
			]
			repeat row squares + 1 [
				insert tail mesh reduce [(as-pair round points/(row)/(col)/1 round points/(row)/(col)/2)]
			]
		]
		insert tail mesh compose [
			fill-pen gray
			polygon
				(as-pair round points/1/1/1 round points/1/1/2)
				(as-pair round points/1/2/1 round points/1/2/2)
				(as-pair round points/2/1/1 round points/2/1/2)
			fill-pen none
		]
		show box-mesh
		;probe
		mesh
	]
	redraw_mesh: does [
		make_points
		transform
		attempt [draw_mesh]
	]
	update: does [
		load_matrix
		redraw_mesh
	]
; undo
	undo-list: copy []
	redo-list: copy []
	undo-temp: none
	undo-id: 0
	add_to_undo-list: has [new-preset] [
		new-preset: make_preset form undo-id: undo-id + 1
		unless none? undo-temp [
			if (second new-preset) =  second undo-temp [undo-id: undo-id - 1 exit]
			insert/only undo-list undo-temp
		]
		undo-temp: new-preset
	]
	undo: does [
		if empty? undo-list [exit]
		insert/only redo-list undo-temp
		undo-temp: first undo-list
		load_preset second take undo-list
	]
	redo: does [
		if empty? redo-list [exit]
		insert/only undo-list undo-temp
		undo-temp: first redo-list
		load_preset second take redo-list
	]

; file
	load_file: func [/local file-name file-names data] [
		file-names: request-file/keep
		if none? file-names [return none]

		foreach file-name file-names [
			attempt [ ; avoid the case when a file doesn't exist or cannot be loaded
				data: load file-name
				if any [not string? data/1 not block? data/2 (length? data) > 2] [make error! "Wrong file"]
				add_preset data
				load_preset second data
				add_to_undo-list
			]
		]
	]
	save_file_as: func [/local name file preset][
		if any [
			none? name: request-text/title "Choose a name for this new preset:"
			empty? name: trim name
			none? file: request-file/keep/only/save/file append copy name ".txt"
			all [exists? file  not confirm "File already exists, overwrite it?"]
			]
			[exit]

		preset: make_preset name
		;probe preset
		save file preset
		add_preset preset
	]
; gui
	eat_events: func [;{derived from flush_events 12-May-2007 Anton Rolls}
		"Allow GUI messages to be processed faster then wait."
		/skip events [block!] "types of events to skip. Default: [move]"
		/local evt
		] [
		events: any [events [move]]
		; Remove the event-port
		remove find system/ports/wait-list system/view/event-port
		
		; Clear the event port of queued events
		while [evt: pick system/view/event-port 1][if not find events evt/type [do evt]] ; fixed by luce80
		
		; Re-add the event-port to the wait-list
		insert system/ports/wait-list system/view/event-port
	]
	win: layout [
		do [sp: 4x4] origin sp space sp 
		style field field "0" 70 white white edge [size: 1x1] [add_to_undo-list update]
		style spin spin-number 80x24 0.0 low -5000 high 5000 [attempt [redraw_mesh]]
		style choice-btn choice-btn 95x24
		style label text -1x24 font [valign: 'middle]
		style lab text 16x24 bold 
		Across 
		btn "Open..." [load_file]
		btn "Save as..." [save_file_as]
		btn "Undo" #"^Z" [undo]
		btn "(R)edo" #"^R" [redo]
		return
		bar-top: bar
		return
		h3 "Result:" 
		h3-warn: h3 "OK" 70 black green
		h3-err: h3 "" 300
		return
		label "Presets:"
		pop-down-presets: choice-btn 180 data (extract presets 2) [
			load_preset select presets value
			add_to_undo-list
		]
		return 
		guide 20x0
		field-11: field "1"
		field-12: field 
		field-13: field 
		here: at 
		return 
		field-21: field 
		field-22: field "1"
		field-23: field 
		return 
		field-31: field 
		field-32: field 
		field-33: field "1" 70
		return
		guide 0x0
		lab "a:"
		spin-a: spin 0.0 low -1000 high 1000
		label "Input:"
		choice-a: choice-btn "nothing" "mouse X" "angle North CW"
		return
		lab "b:"
		spin-b: spin
		label "Input:"
		choice-b: choice-btn "nothing" "mouse Y"
		return
		lab "c:"
		spin-c: spin
		return
		lab "d:"
		field-d: field 218
		return
		lab "e:"
		field-e: field 218
		return
		txt bold as-is {Used formulas:
			; affine (when linear)
			x': (M11 * x) + (M12 * y) + M13
			y': (M21 * x) + (M22 * y) + M23
			; non-affine
			w': (M13 * x) + (M23 * y) + M33

			Px: x' / w'		Py: y' / w'
		} para [tabs: 10]

		at here 
		box-mesh: box 300x300 white
			effect [draw mesh]
			feel [
				engage: func [face action event /local mx my][
					if find [down over away] action [
						mx: event/offset/x - (box-mesh/size/x / 2)
						my: event/offset/y - (box-mesh/size/y / 2)
						if "mouse X"        = get-face choice-a [set-face spin-a mx          redraw_mesh]
						if "angle North CW" = get-face choice-a [set-face spin-a atan2 mx my redraw_mesh]
						if "mouse Y"        = get-face choice-b [set-face spin-b my          redraw_mesh]
					]
				]
			]
		
		do [bar-top/size/x: box-mesh/offset/x + box-mesh/size/x]
	]
	insert-event-func func [face event ] [
		if event/type = 'move [eat_events] ; speedup movement by avoiding following all events
		event
	]
; main
	;print "" ; open console for debug
	add_to_undo-list
	update

	view win

	if opened-console? [halt]
