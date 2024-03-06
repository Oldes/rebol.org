REBOL [
	title: "loose feel for dragging faces"
	file: %feel-loose.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 19-07-2020
	version: 0.2.1
	Purpose: "Add dragging capability to any face. Inspired by Red."
	History: [
		0.1.0 [25-08-2019 "First version"]
		0.1.1 [02-11-2019 "FIX: start dragging also with alt-down"]
		0.2.0 [05-05-2020 "ADD: key support"]
		0.2.1 [19-07-2020 "FIX: 'no-focus"]
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
	]
]

; loose definition
	feel-loose: make object! [
		step: 1x1
		key-steps: [1 10 100]
		range-x: -1000000000x1000000000
		range-y: -1000000000x1000000000
		inside: none
		action: none ; will be done. ; FIXME: better rename "on-drag" ?
		mouse-pos: 0x0
		flags: []
		we: none
		engage-super: [ ; will be swapped with 'engage
			attempt [engage-super face action event]
			case [
				find [over away] action [
					; FIXME: also use "wait-fast" (AKA "eat-events") ?
					face/offset/x: min max range-x/1 face/offset/x + either step/x = 0 [0][round/floor/to event/offset/x - mouse-pos/x step/x] range-x/2 
					face/offset/y: min max range-y/1 face/offset/y + either step/y = 0 [0][round/floor/to event/offset/y - mouse-pos/y step/y] range-y/2
					if block? self/action [do bind self/action 'face]
					show face
				]
				find [down alt-down] action [
					mouse-pos: event/offset
					if all [attempt [not flag-face? we 'no-focus] system/view/focal-face <> face] [
						focus/no-show face  ; allows scrollwheel and key control
						system/view/caret: none ; avoid caret appearing. But we must add the patch below.
					]
				]
				; FIXME: add "sticky" behaviour
				; FIXME: add on-up or on-drop to implement drag&drop
				all [action = 'key any [word? event/key #"^-" = event/key #"^[" = event/key]] [
					use [amount][
						amount: case [event/control [key-steps/1 * key-steps/3] event/shift [key-steps/1 * key-steps/2] true [key-steps/1]]
						switch event/key [
							left  [face/offset/x: face/offset/x + (step/x * - amount)]
							right [face/offset/x: face/offset/x + (step/x * amount)]
							up    [face/offset/y: face/offset/y + (step/y * - amount)]
							down  [face/offset/y: face/offset/y + (step/y * amount)]
							home  [face/offset/x: either step/x > 0 [0][face/offset/x] face/offset/y: either step/y > 0 [0][face/offset/y]]
							end   [face/offset: 1000000000x1000000000] ; FIXME: clip to window ?
							;page-up   []
							;page-down []
							#"^-" [focus either event/shift [ctx-text/back-field face][ctx-text/next-field face]]
						]
					]
					face/offset/x: min max range-x/1 face/offset/x range-x/2 
					face/offset/y: min max range-y/1 face/offset/y range-y/2
					if block? self/action [do bind self/action 'face]
					show face
				]
			]
		]
	]
	; VID new facet
	insert tail svv/facet-words reduce [
		'loose func [new args /local temp edge][
			new/feel: make new/feel feel-loose
			new/feel/we: new ; let loose feel know who we are

			; swap 'engage-super and 'engage
			temp: get in new/feel 'engage
			new/feel/engage: func [face action event] bind feel-loose/engage-super in new/feel 'engage
			new/feel/engage-super: :temp
			
			either attempt [block? second args] [
				new/feel: make new/feel second args
				temp: new/feel/inside
				if attempt [all [object? temp pair? temp/offset pair? temp/size]] [
					edge: (edge-size? temp) / 2
					new/offset: max new/offset temp/offset + edge
					new/feel/range-x: as-pair temp/offset/x + edge/x temp/offset/x + temp/size/x - edge/x - new/size/x
					new/feel/range-y: as-pair temp/offset/y + edge/y temp/offset/y + temp/size/y - edge/y - new/size/y
				]
				next args
			][
				args
			]
		]
	]
	insert-event-func no-caret-key-handler: func [face event][;author: Anton Rolls 17-Jan-2008
		if all [
			event/type = 'key 
			system/view/focal-face  ; there is a focal-face
			none? system/view/caret ; but there is no caret
			; the View system (DO EVENT) won't send the key events if there's no caret so we do it 
			;flag-face? system/view/focal-face no-caret ; only for faces flagged with NO-CARET. (Anton's specific)
			system/view/focal-face/feel ; and which have a FEEL/ENGAGE function
			get in system/view/focal-face/feel 'engage 
		][
			; <- send to detect first (and check the return value) ?  (like mimic-do-event...?)
			;  because the face might be expecting all events to go through detect first.
			system/view/focal-face/feel/engage system/view/focal-face event/type event
			return none ; swallow this event
		]
		event ; allow other events to continue
	]
;
do ; just comment this line to avoid executing examples
[
	if system/script/title = "loose feel for dragging faces" [;do examples only if script started by us
	context [ ; avoid inserting names in global context

	print "Output will be printed here"
	view layout [
		h1 "Drag faces around or click them"
		h1 "and use (qualified) arrow keys"
		style button button 150
		button "free" [print "hi"] loose
		btn "free with an action" loose [action: [print face/offset]]
		button "horizontal" loose [step: 1x0]
		box 200x30 magenta "horizontal stepped" loose [step: 30x0]
		limit1: box 300x60 edge [size: 1x1]
		pad 0x-60
		button "in a rectangle" loose [
			range-x: as-pair 20 20 + 300 - 150
			range-y: as-pair limit1/offset/y limit1/offset/y + 60 - 24
		]
		pad 0x+30
		limit2: box 300x60 edge [size: 3x6] ; use a thick edge for test purposes
		pad 0x-68
		button "inside a face grid" loose [
			step: 30x10
			inside: limit2
		]
	]

	] ; context
	] ; if title

]
