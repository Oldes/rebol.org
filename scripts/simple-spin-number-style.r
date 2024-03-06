REBOL [
	title: "Spin-number style example"
	file: %simple-spin-number-style.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 28-09-2020
	version: 0.9.0
	Purpose: {A quick way to add a simple spin-number to VID GUIs}
	comment: {You are strongly encouraged to post an enhanced version of this script}
	History: [
		0.0.1 [10-05-2020 "Started"]
		0.0.2 [14-05-2020 "Some fixes"]
		0.0.3 [30-07-2020 "ADD: re-form-dec"]
		0.0.4 [30-07-2020 "ADD: shift and ctrl multipliers"]
		0.0.5 [11-08-2020 "FIX: removed do-face from set-face"]
		0.0.6 [20-08-2020 "FIX: returned args position for 'integer"]
		0.0.7 [22-08-2020 "FIX: text input, FIX: face edge, ADD: scroll-wheel support"]
		0.8.0 [23-08-2020 "ADD: resizing"]
		0.9.0 [28-09-2020 "ADD: change value by moving mouse, ADD: flag to cycle between min and max"]
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
	todo: {copy Anton's decimal-edit-style behaviour: change mantissa when moving left/right ?}
]

stylize/master [
	arrow-btn: btn ; should be a button that acts only on mouse down
		feel [
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
			act: none
			words: [up right down left [new/data: first args args]]
			resize: func [new-size [pair!]][
				size: new-size
				effect/draw/translate: size / 2
				effect/draw/scale: size / 4
			]
			append init [
				act: :action
				action: none ; use none (and "act" instead) to avoid doing action on mouse up
				append effect compose/deep [draw [
					pen none fill-pen (font/color)
					translate (size / 2)
					scale (size / 4)
					rotate (select [right -90 down 0 left 90 up 180] data)
					triangle -1x-1 1x-1 0x1 
				]]
			]
		]
		
	spin-number: box
		feel [
			engage: func [face action event /local factor][
				if find [key scroll-line scroll-page] event/type [
					factor: case [
						event/shift [10]
						event/control [face/step]
						'else [1]
					]
					switch event/key [
						up right [set-face face face/data + factor do-face face none]
						down left [set-face face face/data - factor do-face face none]
					]
					switch event/type [
						scroll-line scroll-page [set-face face face/data - (factor * sign? event/offset/y) do-face face none]
					]
				]
			]
		]
		with [
			style: 'spin-number
			size: 60x20
			low: 0 high: 100 step: 1 ; FIXME: I wish to use "min" and "max" instead of "low" and "high" that are ugly but they would clash with the functions
			this: none ; self
			field: arrow-up: arrow-down: none
			faces-moves: faces-dims: frac-y: none
			words: [
				low high step [
					if not number? second args [make error! reduce ['script 'expect-set "number!" type? second args]]
					set in new first args second args next args
				]
				integer [flag-face new 'integer args]
				cycle [flag-face new 'cycle args]
			]
			access: make ctx-access/data-number [
				re-form-dec: func ["Convert scientific to decimal notation. (modifies)"
					number [string!] /local digit pos end sign exp
					][
					sign: 0
					digit: charset "0123456789"
					parse/all number [
						opt ["-" (sign: 1)] any digit pos: opt "." any digit 
						[
							end: "E-" (if pos <> end [remove pos end: back end] pos: remove/part end 2)
							:pos copy exp some digit end: (exp: do exp remove/part pos end)
						]
						| (return number) ; if exponent not found abort
					]
					insert/dup insert skip number sign "0." "0" exp - 1
					number
				]
				set-face*: func [face value [number!]][
					if face/data = value [exit] ; check _before_ the constraints
					; FIXME: if (abs face/data - value) <= face/precision [exit] ; this way I could use do-face at end?
					value: to decimal! round/to value face/step
					if flag-face? face 'cycle [
						value: face/low + mod (value - face/low) (face/high - face/low)
					]
					value: min max face/low value face/high
					if flag-face? face 'integer [value: round value]
					face/data: value
					face/field/text: re-form-dec form value
					face/field/old-text: copy face/field/text ; store old value to be able to restore it if an error occurs
					;do-face face value ; in some situations (e.g. caused by rounding errors) this can cause an infinite loop
				]
				resize-face*: func [face [object!] size [pair!] x [logic!] y [logic!]][
					face/resize size
				]
			]
			resize: func [new-size [pair!] /local siz][
				siz: new-size - size
				foreach [face pair] faces-moves [face/offset: face/offset + (siz * pair)]
				foreach [face pair] faces-dims [face/size: face/size + (siz * pair)]
				; adjust arrows (frac-y is used to compensate for rounding errors when converting to pair!)
				frac-y/1: frac-y/1 + (siz/y * .5)
				arrow-down/offset/y: frac-y/1
				frac-y/2: frac-y/2 + (siz/y * .5)
				arrow-up/resize as-pair arrow-up/size/x frac-y/2
				frac-y/3: frac-y/3 + (siz/y * .5)
				arrow-down/resize as-pair arrow-down/size/x frac-y/3
			]

			append init [
				this: self
				if size/x < 0 [size/x: 60]
				if size/y < 0 [size/y: 20]
				size: size - edge-size? this
				data: any [data low]
				pane: layout/tight [
					space 0x0 below
					field: field "0" (as-pair size/x - 20 size/y)  white white edge [size: 1x1]
						with [
							old-text: none
							mouse-pos: 0x0
							moving?: false
							value: 0
							do-math: func [; let's be more "tolerant" with the input strings
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
								do text
							]
							feel: make ctx-text/edit [
								engage-super: :engage
								engage: func [face action event /local factor delta][
									engage-super face action event
									if 	any [
											action = 'away
											find [up down] event/key
											find [scroll-line scroll-page] event/type
											all [face/moving? action = 'over]
										][
											do-face face face/text ; update this/data
											factor: case [
												event/shift [10]
												event/control [this/step]
												'else [1]
											]
									]
									case [
										any [
											find [up down] event/key
											find [scroll-line scroll-page] event/type
										][
											switch event/key [
												up [set-face this this/data + factor do-face this this/data]
												down [set-face this this/data - factor do-face this this/data]
											]
											switch event/type [
												scroll-line scroll-page [set-face this this/data - (factor * sign? event/offset/y) do-face this this/data]
											]
										]
										action = 'down [
											face/mouse-pos: event/offset
											face/value: this/data
										]
										action = 'up [
											face/moving?: false
										]
										any [action = 'away all [face/moving? action = 'over]] [
											face/moving?: true
											delta: round face/mouse-pos/y - event/offset/y / 3
											set-face this face/value + (factor * delta)
											do-face this this/data
										]
									]
									if factor [ ; used as a flag
										; update caret
										focus/no-show face
										unlight-text
										show face
									]
								]
							]
						]
						[; action
							if none? attempt [value: face/do-math face/text] [face/text: copy face/old-text focus face exit]
							face/para/scroll/x: 0 ; restore position for long text
							set-face this value
							do-face this value
						]
					return
					style arrow-btn arrow-btn (as-pair 20 size/y / 2) [
						focus this
						if not number? value [exit]
						value: step * value + get-face this
						set-face this value
						do-face this value
					]
					arrow-up: arrow-btn 'up with [append init [data: 1]]
					arrow-down: arrow-btn 'down with [append init [data: -1]]
				]
				size: pane/size + edge-size? this
				faces-moves: reduce [
					arrow-up 1x0
					arrow-down 1x0
				]
				faces-dims: reduce [
					field 1x1
					this/pane 1x1
					this 1x1
				]
				frac-y: reduce [arrow-down/offset/y arrow-up/size/y arrow-down/size/y]
				user-data: data
				data: none ; force refresh in set-face
				set-face this user-data
			]
		]

]
do ; just comment this line to avoid executing examples
[
	if system/script/title = "Spin-number style example" [;do examples only if script started by us
	
	insert-event-func func [face event /local siz][
		if event/type = 'active [
			face: event/face
			face/data: face/size          ; store old size
		]
		if event/type = 'resize [
			face: event/face
			siz: face/size - face/data    ; compute size difference
			face/data: face/size          ; store new size

			resize-faces face siz
			show face
		]
		event
	]
	resize-faces: func [window siz [pair!]] [
		foreach [face x y w h] [
			sp-1  0 0    1 0.25
			sp-2  0 0.25 1 0.25
			sp-3  0 0.50 1 0.25
			sp-4  0 0.75 1 0.25
			t-1   1 0    0 0
			t-2   1 0.25 0 0
			t-3   1 0.50 0 0
			t-4   1 0.75 0 0
			h-1   0 1    0 0
			h-2   0 1    0 0
			h-3   0 1    0 0
			][
			frac-dims/(face)/x: frac-dims/(face)/x + (siz/x * x)
			frac-dims/(face)/y: frac-dims/(face)/y + (siz/y * y)
			set in get face 'offset as-pair frac-dims/(face)/x frac-dims/(face)/y
			frac-dims/(face)/w: frac-dims/(face)/w + (siz/x * w)
			frac-dims/(face)/h: frac-dims/(face)/h + (siz/y * h)
			either in get face 'resize [
				do in get face 'resize as-pair frac-dims/(face)/w frac-dims/(face)/h
			][
				set in get face 'size as-pair frac-dims/(face)/w frac-dims/(face)/h
				resize-face get face as-pair frac-dims/(face)/w frac-dims/(face)/h
			]
		]
	]

	win: layout [
		across
		sp-1: spin-number 50.0 low 0 high 100 step 0.5
		t-1: text "min 0.0 max 100.0 step 0.5" 
		return
		sp-2: spin-number 50.0 low 0 high 100 cycle
		t-2: text "min 0.0 max 100.0 cycle" 
		return
		; note that even if this spinner displays only integers it must be initialized with a decimal!
		sp-3: spin-number 80 2.0 low 0 high 1000 step 1 integer
		t-3: text "min 0 max 1000 step 1 integer" 
		return
		sp-4: spin-number 80 20.0 low -1000 high 1000 step .01
		t-4: text "min -1000 max 1000 step .01" 
		return
		h-1: h3 "Use also (qualified) arrows"
		return
		pad 0x-10
		h-2: h3 "Use also (qualified) scroll-wheel"
		return
		pad 0x-10
		h-3: h3 "Try also (qualified) drag up and down inside field"
		return
	]

	; store single faces dimensions in a block
	; see: http://www.rebol.org/view-script.r?script=simple-vid-resizing.r
	; for a better, general implementation
	frac-dims: copy []
	foreach face win/pane [
		insert/only insert frac-dims face/var compose [x (face/offset/x) y (face/offset/y) w (face/size/x) h (face/size/y)]
	]

	view/options win 'resize

	] ; if title
]
