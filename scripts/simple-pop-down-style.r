REBOL [
	title: "Pop-down style example"
	file: %simple-pop-down-style.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 23-09-2020
	version: 0.3.1
	Purpose: {A quick way to add a simple pop-down to VID GUIs}
	comment: {You are strongly encouraged to post an enhanced version of this script}
	History: [
		0.0.1 [21-09-2014 "First version"]
		0.0.2 [23-05-2020 "Changed show/hide mechanism, similar to html modal popups"]
		0.0.3 [13-06-2020 "Added if title..."]
		0.0.4 [18-06-2020 "Fixed size. Added data"]
		0.0.5 [13-09-2020 "Fixed offset/y"]
		0.3.0 [20-09-2020 "Added arrow keys support, scroller"]
		0.3.1 [23-09-2020 "Added mouse wheel support. Added default choice. Refactored"]
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
]

simple-pop-down-style-ctx: context [
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

stylize/master [
	choice-btn: btn
		para [origin: origin + 2x0] 
		feel [
			redraw-super: :redraw
			redraw: func [face act pos][
				redraw-super face act pos
				if face/update [face/text: get-face face]
			]
			engage: func [face action event /local win pop-list pop-row pop-list-height offset maxy scroller][
				if action = 'down [
					if empty? face/data [exit]
					pop-list: face/list/pane/1

					focus/no-show pop-list  ; allows key control

					pop-row: pop-list/subface/pane/1
					pop-list/offset: (win-offset? face) + (face/size * 0x1)
					pop-list/offset/x: pop-list/offset/x - pop-list/size/x + face/size/x ; right aligned
					win: find-window face
					; cover entire window ; FIXME: or parent panel ?
					face/list/size: win/size
					face/list/offset: 0x0

					maxy: win/size/y - face/offset/y - face/size/y ; FIXME: - edge
					maxy: round/floor/to maxy pop-row/size/y
					offset: pop-list/offset
					; keep inside window 
					offset/x: min max 0 offset/x win/size/x - pop-list/size/x
					if all [
						offset/y > (win/size/y - pop-list/size/y) 
						offset/y > (win/size/y / 2)
						]
						[
						maxy: round/floor/to face/offset/y pop-row/size/y
						offset/y: face/offset/y - min pop-list/size/y maxy
					]
					pop-list/offset: offset
					; if too much tall then add scroller
					scroller: face/list/pane/2
					pop-list-height: pop-row/size/y * length? face/data ; FIXME: + edge
					either pop-list-height > maxy [
						pop-list/size/y: maxy
						; show scroller
						scroller/offset: pop-list/offset + (pop-list/size/x * 1x0 - 12x0)
					][
						; hide scroller
						hide-face scroller
					]
					scroller/resize as-pair 12 pop-list/size/y
					scroller/update (to-integer pop-list/size/y / pop-row/size/y) (length? face/data)
					; show chosen item
					scroller/scroll-to face/chosen - 1
					; put list on top
					remove find win/pane face/list
					append win/pane face/list
					show win
				]
			]
		]
		with [
			pad: 6
			font: make font [align: 'left] ; must assign this here and not with the vid word
			font-btn: font ; give font another name to copy its size to list text
			update: true ; update face when an item is chosen
			chosen: none ; to store chosen item
			list: none
			list-size: none
			texts: any [texts copy []]
			data: make block! length? texts
			colors-back: none
			colors-fore: none
			scroll-count: 0
			access: context [
				set-face*: func [face value][face/chosen: index? find face/data value] ; will give error if not found
				get-face*: func [face][pick face/data face/chosen]
			]
			words: [
				update [new/update: second args next args]
				data [new/data: copy second args next args]
			]
			insert init [
				unless find data texts [insert data texts]
				if empty? data [insert data copy ""]
				text: any [text first data]
				if text = "" [update: false]
				if not update [remove data] ; remove first text
				chosen: index? any [find data text ""]
				
				if size/x <> -1 [pad: 0]
			]
			append init [
				; draw arrow
				append effect compose/deep [draw [
					pen none fill-pen (font/color)
					translate (size / 2)
					scale 4x3
					triangle -1x-1 1x-1 0x1 
				]]
				size/x: size/x + pad ; add space for arrow (unless width is already defined)
				; set arrow position
				effect/draw/translate: as-pair (size/x - 10 ) (size/y / 2)
				list: layout/tight [
					list as-pair -1 (4 + second size-text self) * (length? data) + 2 edge [size: 1x1 color: black] [
						txt 10000 "" no-wrap with [ ; use txt if text is modified
							colors-back: reduce [white black]
							colors-fore: reduce [black white]
							font: make font [color: first colors-fore size: font-btn/size]
							color: first colors-back
							active: false
							feel: make feel [
								redraw: func [face act pos][
									face/font/color: pick face/colors-fore not face/active
									face/color: pick face/colors-back not face/active
								]
								over: func [face action event][
									face/active: action
									show face
								]
								engage: func [face action event /local button][
									if event/type = 'down [
										button: list/pane/1/data
										update-face button face/text
										button/feel/over button false none ; remove orange border
										hide-face list
									]
								]
							]
							
						]
					] supply [
						face/text: data/(count + scroll-count)
						if count > length? data [return none]
					]
					feel [
						engage: func [face action event /local scroller][
							scroller: list/pane/2
							case [
								find [up down] event/key [
									; face/data is main button
									face/data/chosen: min max 1 (face/data/chosen + either event/key = 'up [-1][1]) scroller/total 
									show face/data
									do-face face/data get-face face/data
									scroller/scroll-to face/data/chosen - 1
								]
								event/type = 'scroll-line [
									do pick [scroll-drag scroll-drag/back] event/offset/y > 0 scroller
								]
								event/type = 'scroll-page [
									do pick [scroll-drag/page scroll-drag/page/back] event/offset/y > 0 scroller
								]
								'else [
									;hide covering face
									hide-face list
								]
							]
						]
					]
					with [
						append init [ ; must append this, cannot simply set it (!?)
							style: 'choice-list ; unique name to better distinguish this especially when focused
						]
					]
					at 0x0
					scroller 12
						[
							list/pane/1/subface/pane/1/active: false
							value: to-integer value * (face/total - face/visible)
							if value <> scroll-count [
								scroll-count: value 
								show list
							]
						] 
						with [
							visible: total: 0
							update: func [visible [integer!] total [integer!]][
								self/visible: visible self/total: total
								step: 1 / max 1 (total - visible) 
								redrag min (max 1 visible) / (max 1 total) 1

								self
							]
							scroll-to: func [pos [integer!]] [
								pos: (min pos (total - visible)) / max 1 (total - visible)
								update-face self pos
							]
							append init [
								update 0 0
							]
						] 
				]
				list/style: 'choice-list

				list/color: none ; place a color here to see what is happening

				list/pane/1/data: self ; store btn face
				use [t tmp maxx pop-row] [
					maxx: 0
					pop-row: list/pane/1/subface/pane/1
					pop-row/colors-back: any [reduce colors-back reduce [white black]]
					pop-row/colors-fore: any [reduce colors-fore reduce [black white]]

					foreach t data [
						pop-row/text: t
						pop-row/size/x: 10000
						tmp: size-text pop-row
						pop-row/size/x: either tmp [tmp/x + font/offset/x + 5][50]
						maxx: max maxx pop-row/size/x
					]
					list/pane/1/size/x:
					pop-row/size/x: any [list-size max size/x maxx]
				]
				list/feel: make face/feel [
					engage: func [face action event][
						; remove orange border
						list/pane/1/data/feel/over list/pane/1/data false none
						; hide covering face
						hide-face face
					]
				]
			]
		]

] ; stylize
] ; context
do ; comment this line to comment example code
[
	if system/script/title = "Pop-down style example" [;do examples only if script started by us

	txts: copy []
	repeat n 20 [append txts join "text" form n]

	view center-face layout [
		across
			text1: text as-is "text4   "
			cb1: choice-btn "text4" data (txts) [set-face text1 value]
			text "simple case"
		return
			text2: text "not chosen"
			choice-btn "Choose a text" "1st text" "2nd text" red update false font [color: yellow] with [colors-back: [white blue] colors-fore: [black green]] [set-face text2 value]
			text "This has a fixed text"
		return
			field1: field
			; NOTE the empty first text
			choice-btn "" "1st choice" "2nd choice" "3rd" "4th" [set-face field1 value]
		return
			text "This is an example of various pop-downs"
	]

	] ; if title
]