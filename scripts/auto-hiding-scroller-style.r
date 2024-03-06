REBOL [
	title: "Auto-hiding scroller style example"
	file: %auto-hiding-scroller-style.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 03-11-2020
	version: 0.8.0
	Purpose: {Add an auto-hiding scroller to VID GUIs}
	History: [
		0.0.1 [19-10-2020 "Started"]
		0.8.0 [03-11-2020 "Main aspects completed"]
	]
	Category: [util vid view]
	library: [
		level: 'intermediate
		platform: 'all
		type: 'how-to
		domain: [gui vid]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: none
		see-also: none
	]
	help: {
		This script defines an auto hiding scroller style.
		It is meant to be placed next to the style where scrolling is needed
		A few new VID words are introduced:
		
			'for to define the style where scrolling is needed
			'scrolling to define the facet, given as a word! or a path!, that has the value that controls the amount of scrolling
			'scroll to define the initial amount of scrolling
			'total to define a function that gives the total amount of displayable data
			'visible to define a function that gives the amount of visible data
			'direction to define if scrolling goes in negative or positive direction when incrementing it 
		
		The scroller face has three main functions used to scroll the linked face and control the scroller appearance:
			scroll-to position [integer!]
				will scroll to given position. WARNING: this is 0-based because is meant also for images
			drag value [number! word!] "'step, 'page or a number in [0 1] range" dir [integer!] "-1 or 1"
				will scroll one step or page at a time or by the given value in [0 1] range
			update visible [integer!] total [integer!]
				to change the <visiblw> and <total> values

		See the example at the end of the script.
	}
	comment: {
		A few code is ripped from Rebol 2706031 SDK
	}
	todo: {
		key and scroll-wheel control ? But they are done in the linked face ?
	}
]

; debug
	???: func ['name][prin name prin ": " probe either path? :name [do :name][get name]] ; watch: inspect: examine:
; gui
	update-face: func [
		face [object!]
		value
		] [
		set-face face value
		do-face face get-face face
	]
	hide-face: func [
		face [object!]
		] [
		face/offset: 0x0 - face/size
		show face
	]
	old-hide: :hide
	hide: func spec-of :hide
		[
		face/hidden?: true ; will give error if word not found
		do pick [old-hide old-hide/show] not show face
	]
	unhide: func [
		"Unhide a face"
		face [object!]
		/no-show "Do not show change yet"
		][
		face/hidden?: false ; will give error if word not found
		unless no-show [show face]
	]
	inner-size?: func [
		"Give face's size less its edge"
		face [object!]
		] [
		face/size - edge-size? face
	]
	set-facet: func [
		"Attempt to change a face's facet value"
		face [object!]
		member [word! path!]
		value 
		/no-show "Do not show change yet"
		][
		any [
			attempt [do reduce [append to-set-path 'face member value]]
			attempt [do reduce [append to-set-path 'face member round value]]
		]
		unless no-show [show face]
	]
	get-facet: func [
		"Get a face's facet"
		face [object!]
		member [word! path!]
		][
		do append to-path 'face member
	]
;
stylize/master [
	arrow-btn: btn ; should be a button that acts only on mouse down
		feel [
			redraw: func [face action position][
				if action = 'draw [ ; FIXME: of is it better if action = 'show [... ?
					face/effect/draw/fill-pen: face/font/color
					; resize the drawing
					face/effect/draw/translate: face/size / 2
					face/effect/draw/scale: face/size / 4
					face/effect/draw/rotate: select [right -90 down 0 left 90 up 180] face/head
				]
			]
			engage-super: :engage
			engage: func [face action event][
				engage-super face action event
				case [
					action = 'down [face/start: now/time/precise face/rate: 0:0:0.5 face/act face face/data]
					action = 'up [face/rate: none]
					event/type = 'time [face/rate: either (now/time/precise - face/start) < 0:0:1.5 [0:0:0.1][0:0:0.02] face/act face face/data]
				]
				show face ; update timer
			]
		]
		with [
			start: none
			head: 'down
			act: none
			words: [up right down left [new/head: first args args]]
			append init [
				act: :action
				action: none ; use none (and "act" instead) to avoid doing action on mouse up
				append effect compose/deep [draw [
					pen none fill-pen (font/color)
					translate (size / 2)
					scale (size / 4)
					rotate (select [right -90 down 0 left 90 up 180] head)
					triangle -1x-1 1x-1 0x1 
				]]
			]
		]
		
	auto-hiding-scroller: btn
		edge [size: 0x0]
		feel [
			redraw-super: :redraw
			redraw: func [face action position /local axis visible total][
				redraw-super face action position
				if action = 'show [
					axis: face/axis
					position: face/clip - face/dragger/size
					face/dragger/offset/(axis): face/data * position/(axis) + face/off/(axis)

					; keep size same as that of linked face's
					face/size/(axis): face/linked/size/(axis)
					; if size changed reposition arrow and recalc dragger and linked face size
					if (face/size) <> (face/arrow-2/offset + face/arrow-2/size) [
						
						do-face face face/data ; update main face's values

						face/arrow-2/offset: face/size - face/arrow-2/size
						
						; "auto-hide" scroller if possible
						visible: face/visible ; these are functions
						total: face/total
						; 3 - axis is opposite of main axis (1 <-> 2)
						either visible < total [
							face/linked/size/(3 - axis): face/offset/(3 - axis) - face/linked/offset/(3 - axis)

							face/update visible total

							unhide/no-show face ; use no-show to avoid recursion !
						][
							face/linked/size/(3 - axis): face/offset/(3 - axis) - face/linked/offset/(3 - axis) + face/size/(3 - axis) 

							hide face
						]
						; if we're using %simple-vid-resizing.r update also stored dimensions
						if attempt [face/linked/feel/decis] [ 
							face/linked/feel/decis/3: face/linked/size/x
							face/linked/feel/decis/4: face/linked/size/y
						]
					]
									
					face/show?: not face/hidden? ; keep it hidden if necessary

				]
			]
			over: none ; avoid changing background when over
			engage: func [face action event /local dir][
				case [
					action = 'down [
						face/start: now/time/precise
						face/rate: 0:0:0.5
						dir: either outside? (event/offset + win-offset? face) win-offset? face/dragger [face/arrow-1][face/arrow-2]
						face/move-drag dir face/page
					]
					action = 'up [face/rate: none]
					event/type = 'time [
						face/rate: either (now/time/precise - face/start) < 0:0:1.5 [0:0:0.1][0:0:0.02]
						if within? event/offset win-offset? face/dragger face/dragger/size [
							face/rate: none
							exit
						]
						dir: either inside? event/offset win-offset? face/dragger [face/arrow-2][face/arrow-1]
						face/move-drag dir face/page
					]
				]
				show face ; update timer
			]
		]
		with [
			state: true ; use inverted image for background
			data:  ; main value in [0 1] range
			start: ; time when mouse down
			ratio: ; visible size / total size (proportional draggers)
			step:  ; scrolling granularity
			page:  ; paging size
			0.0
			axis: none	; integer used to indicate X or Y major axis
			off: clip: 0x0	; account for arrow boxes in scrollers

			arrow-1: arrow-2:
			dragger: none

			hidden?: false  ; to be able to permanently hide the scroller
			visible:    ; amount of visible data (a function or will be converted to a function)
			total:      ; amount of displayable data (a function or will be converted to a function)
			scroll: 0   ; scrolling value in [0 or 1  +/-(total - visible)] range
			direction: 1 ; direction of scrolling: 1 to increment, -1 to decrement
			linked:     ; the face to be controlled
			facet: none ; the facet that makes the scrolling [word! or path!]
			
			action: func [face value] [
				value: to-integer value * (face/total - face/visible)
				value: min max 0 value face/total
				if value <> face/scroll [
					face/scroll: value 
					set-facet face/linked face/facet value * face/direction
				]
			] 

			access: ctx-access/data-number
			words: [
				for [new/linked: second args next args]
				scrolling [new/facet: second args next args]
				visible [
					new/visible: second args
					if block? new/visible [new/visible: does new/visible]
					if not function? get in new 'visible [new/visible: does reduce [new/visible]]
					next args
				]
				total [
					new/total: second args
					if block? new/total [new/total: does new/total]
					if not function? get in new 'total [new/total: does reduce [new/total]]
					next args
				]
				scroll [new/scroll: second args next args]
				direction [new/direction: either positive? second args [1][-1] next args]
			]

			redrag: func [val /local tmp][; this function is ripped from REBOL SDK, only a little modified
				; clip the ratio to proper range (save for possible resize)
				ratio: min max 0 val 1
				; compute page step size
				page: any [all [ratio = 1 0] ratio / (1 - ratio)]
				; compute space behind dragger
				clip: size - (2 * edge/size) - (arrow-1/size * pick [0x2 2x0] axis = 2)
				; compute size of dragger
				tmp: clip/:axis * ratio
				; don't let dragger get smaller than 10 pixels
				if tmp < 10 [page: either clip/:axis = tmp: 10 [1][tmp / (clip/:axis - tmp)]]
				dragger/size/(axis): tmp
			]
			update: func [visible [integer!] total [integer!]][
				step: 1 / max 1 (total - visible) 
				; arrows will scroll by a step
				arrow-1/data: arrow-2/data: step
				redrag min (max 1 visible) / (max 1 total) 1

				self
			]
			move-drag: func [face val][
				update-face face/parent-face min max 0 face/parent-face/data + (face/dir * val) 1
			]
			scroll-to: func [pos [integer!] /local visible total] [
				visible: self/visible total: self/total
				; scale to [0 1] range
				pos: (min pos (total - visible)) / max 1 (total - visible)
				update-face self min max 0 pos 1
			]
			drag: func [
				value [number! word!] "'step, 'page or a number in [0 1] range"
				dir [integer!] "-1 or 1"
				][
				value: switch/default value [
					step [step]
					page [page]
				] value
				dir: either dir = 1 [arrow-2][arrow-1]
				move-drag dir value
			]

			append init [
				; I must make the pane in init to avoid duplicated faces
				pane: reduce [
					arrow-1: make-face/spec 'arrow-btn [
						dir: -1
						action: :move-drag
					]
					dragger: make-face/spec 'btn [
						; FIXME: use %feel-loose.r ?
						feel: make feel [
							redraw: func [face action position][
								face/effect/draw/translate: (size / 2)
							]
							engage: func [face action event /local value axis clip][
								if find [over away] action [
									axis: face/parent-face/axis
									clip: face/parent-face/clip/(axis) - face/size/(axis)
									value: face/offset + event/offset - face/data - face/parent-face/off
									value: min max 0 value/(axis) clip
									value: either clip = 0 [0][value / clip]

									update-face face/parent-face value
								]
								if find [down alt-down] action [face/data: event/offset] ; store mouse pos
							]
						]
						append init [
							append effect compose/deep [draw [
								pen (black) ; FIXME: (main-font/color)
								fill-pen none
								; it's a pity I cannot give decimal! numbers here
								translate (size / 2)
								;scale (size / 4)
								circle 0x0 2.5
							]]
						]
					]
					arrow-2: make-face/spec 'arrow-btn [
						dir: 1
						action: :move-drag
					]
				]


				axis: pick [2 1] size/y >= size/x

				arrow-1/size/(3 - axis): dragger/size/(3 - axis): arrow-2/size/(3 - axis): size/(3 - axis)
				arrow-1/size/(axis): arrow-2/size/(axis): size/(3 - axis) ; keep these square
				
				dragger/offset: arrow-1/size * pick [1x0 0x1] axis
				arrow-1/head: pick [left up] axis
				arrow-2/head: pick [right down] axis
				
				off: arrow-1/size
				clip: size - (2 * edge/size) - (off * pick [2x0 0x2] axis)

				update visible total
				
			]
		]
]

do ; just comment this line to avoid executing examples
[
	if system/script/title = "Auto-hiding scroller style example" [;do examples only if script started by us

	; script-version , choose_file , download , load-script-thru (all manually minified)
	do decompress
	64#{
	eJxVVNtu2zAMfc9XECqGbkMdDdiejLUFtu6twG7Yk6AWiiwn3nRxJSpu/n6UbAdtAgQkRZGHh0fZ9C20ffYaNqk5ttCLBNwGrSwcYQQtBQU/bOkLugXzrG3uDOjgRmuc
	8QhjC/qgYjLI4KF54Gz1JBuLwZW1kAQeYma/vn35fs+UP8HIBKuho4lpCL5lKThTGobxRJ2rpyWGBjN1gqPc6Me+wOtXeF6CyB4HC8K3EM1TNgmbfrCG/zNm5MHbEycX
	TYQehh588OYWvIgGc/TVleZ5SJgoWlpFswu2ViB/09nSLq/tLOxAQ0d8DGbi3kxA55oYMLHplTZg1SlkFHZn2V2YvA2qG/yeoXlGeNuH6CC/27UwxrCPJiWpS3mE3UkK
	omuusSMXOKDsykSqa7xBvt6ADK2G7CuAMh1h6uSmNGqSjsOITaG0lPXAe6vSAfikYnFicEQuX9gmgpepdOPB0e8RlBSKpKAQjRuxhKgQ6aLUmnOdFMTiEW6AlAJuRkh8
	klW5dHJTWUY4KpuJ6suCtImBIuJskogGPNBO0ilRqxUS/wTX8FG84V/5n0Qh/iPv7KD5XdC56CxJOkM3ShJCQ/s+1+MtjdMCiUocZ6FKN7tKlLlGSpCzSRcXi9arRJoG
	1IdVOSSLv2Hwom7KszpHH7LvIESYYvB7WKBeQaEcBryCblk0OVA5nqZpW2W0DXFfbj7lAW/pLdxTFjsLg7GfFGdSbC5E5U6UPHkhMGZDuq5oH3v2fhsZRXtlE+VUygtI
	EAfEseX8VTu+omnUoodtvF2E4ZUz12Xswk1qEkbS5rqJWSqiqyuuS3Vy2WQ/EAFufrggmKBXYmIMkTH5Ugvw8mCKA5pFWU7Sp8ii/AuIUpE4IknSjMqaiOeB2O8KFD4z
	z25ek7+KFkOA5KjQlklJlbOndwOX/eY/gnuiqMQEAAA=
	}

	do load load-script-thru/flash/warn/from %simple-win-resizer-style.r %simple/
	clear last mod: load load-script-thru/flash/warn/version %simple-vid-resizing.r 1.2.3
	do mod

	;prin "^(back)" ; open console for debug
	win: layout [
		here: at
		sizer: win-resizer move-xy
		space 0
		across
		at here
		area-test: area 150x100 resize-xy trim/auto {
			123456789_123456789_123456789_
			a
			b
			c
			dd
			e
			f
			g
			h}
			edge [size: 1x1]
			with [
				feel: make ctx-text/edit [
					engage-super: :engage
					engage: func [face action event][
						engage-super face action event
						; update visible and total values
						scrx/update  first inner-size? face  first size-text face
						scry/update second inner-size? face second size-text face
						; sync dragger position with text scrolling
						scrx/scroll-to 0 - face/para/scroll/x
						scry/scroll-to 0 - face/para/scroll/y
					]
				]
			]

		; dimension is given only to suggest orientation, the scroller will adapt to its linked face's size
		scry: auto-hiding-scroller 16x20 move-x resize-y
			for area-test
			scrolling 'para/scroll/y
			visible [second inner-size? area-test]
			total [second size-text area-test]
			direction -1
		
		return

		scrx: auto-hiding-scroller 20x16 move-y resize-x
			for area-test
			scrolling 'para/scroll/x
			visible [first inner-size? area-test]
			total [first size-text area-test]
			direction -1

	]	

	; put sizer on window's bottom-right corner and keep it there
	sizer/user-data: sizer/offset: win/size - sizer/size 

	view/options center-face win [resize]

	] ; if title
]
