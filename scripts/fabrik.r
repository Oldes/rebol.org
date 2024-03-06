REBOL [
	title: "FABRIK IK solver"
	file: %fabrik.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 15-12-2019
	version: 0.1.0
	Purpose: "Implement Forward And Backward Reaching Inverse Kinematics algorithm."
	History: [
		0.0.1 [29-10-2019 "Started"]
		0.1.0 [02-12-2019 "Main aspects completed"]
		0.1.1 [15-12-2019 "FIX: made main function global"]
	]
	Needs: [%feel-loose.r]
	library: [
		level: 'intermediate
		platform: 'all
		type: [function tool]
		domain: [graphics visualization]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'public-domain
	]
	Notes: {
		http://andreasaristidou.com/publications/papers/FABRIK.pdf
		Andreas Aristidou , Joan Lasenby : Forward And Backward Reaching Inverse Kinematics (FABRIK), for solving the IK problem in different scenarios.
		
		comments starting with ";%" are those found in the original paper
	}
]
if not value? 'FABRIK-ctx [; avoid redefinition

FABRIK-ctx: context [
	; misc functions
		undirize: func ["Returns a copy of the path turned into a file."
			path [file! string! url!]
			][
			path: copy path
			while [find "/\" pick path: back tail path 1] [remove path]
			head path
		]
		download: func [
			url [url!]
			/local lo bar cbk-fn data
			][
			view/new lo: center-face layout [
				lbl "Downloading"
				text (form url)
				bar: progress
			]
			cbk-fn: func [total bytes][
				set-face bar bytes / total
			]
			data: read-net/progress url :cbk-fn
			unview/only lo
			data
		]
		load-script-thru: func ["Load a script from www.rebol.org thru the cache"
			name [file!]
			/flash "Flash a message to the user"
			/warn "Alert user if script not found"
			/from path [file!] "Optional path where to search for the script"
			/local cache-name modul
			][
			if not value? 'view-root [view-root: either system/version/4 = 3 [%/C/Users/Public/Documents] [%/tmp]]
			cache-name: view-root/:name
			modul: any [
				attempt [read cache-name] ; try the cache
				attempt [read name] ; try current dir
				attempt [read rejoin [undirize path "/" name]] ; try optional dir 
				attempt [ ; try downloading it from www.rebol.org
					if not request [rejoin [form name " not found, download it from www.rebol.org or quit?"] "Download" "Quit"][quit]
					modul: rejoin [http://www.rebol.org/download-a-script.r?script-name= name]
					modul: as-string either flash [download modul][read modul]
					if not find modul "REBOL [" [make error! "Script not found"]
					write cache-name modul
					modul
				]
			]
			if all [not modul warn] [alert rejoin ["Script <" name "> not found."]]
			modul
		]
		fill: func [
			"Duplicates an append a specified number of times. (modifies)"
			series [series!]
			value
			count [integer!]
			][
			head insert/dup tail series value count
		]
		atan2: func [; author: Steeve Antoine 2009
			"Angle of the vector (0,0)-(x,y) with arctangent y / x. The resulting angle is extended to -pi,+pi"
			x [number!] y [number!]
			][
			if x = 0 [x: 0.0000000001]
			add arctangent y / x pick [0 180] x > 0
		]
		point-point-distance: func [p1 [block!] p2 [block!]][
			0.0000000001 + ; avoid division by 0
			square-root (((p2/x - p1/x) ** 2) + ((p2/y - p1/y) ** 2))
		]
		three-points-angle: func [A [block!] V [block!] B [block!]][
			(atan2 A/x - V/x A/y - V/y) - (atan2 B/x - V/x B/y - V/y)
		]
		rotate-point-around-point: func [p [block!] sina [decimal!] cosa [decimal!] center [block!] /local px py cx cy][
			px: p/x
			py: p/y
			cx: center/x
			cy: center/y
			p/x: (px * cosa) - (py * sina) - (cx * cosa) + (cy * sina) + cx
			p/y: (px * sina) + (py * cosa) - (cx * sina) - (cy * cosa) + cy
			p
		]
	;

	; FABRIK
	set 'FABRIK func [
		;% Algorithm 1. A full iteration of the FABRIK algorithm

		;% Input: The joint positions pi for i = 1,. . . ,n, the target position t
		p [block!] "joint positions as block of blocks with coordinates and angles constraints (modified)"
		t [block!] "target position"
		/tolerance tol [decimal!]
		/drag bool [logic!] "if target is unreachable then snap to target"
		/local
			angle dx dy
			n d i r_i k_i b difA
		;% Output: The new joint positions pi for i = 1,. . . ,n.
		][
		
		n: length? p
		if n = 0 [return p] ; FIXME: or return none or error?
		if n = 1 [p/1/x: t/x p/1/y: t/y return p]

		tol: min max 1E-12 any [tol 0.5] 1
		tolerance: tol

		d: fill copy [] 0 n - 1
		;% the distances between each joint
		for i 1 n - 1 1 [
			d/(i): point-point-distance p/(i + 1) p/(i)
		]

		r_i: k_i: 0
	
		; The target is reachable ? set as b the initial position of the joint p1
		b: copy p/1
		;% Check whether the distance between the end effector pn and the target t is greater than a tolerance.
		difA: point-point-distance p/(n) t
		while [difA > tol] [
			;% STAGE 1: FORWARD REACHING
			;% Set the end effector pn as target t
			p/(n)/x: t/x
			p/(n)/y: t/y
			for i n - 1 1 -1 [
				;% Find the distance ri between the new joint position pi+1 and the joint pi
				r_i: point-point-distance p/(i + 1) p/(i)
				k_i: d/(i) / r_i
				;% Find the new joint positions pi. using lineaar interpolation
				p/(i)/x: (p/(i)/x - p/(i + 1)/x) * k_i + p/(i + 1)/x
				p/(i)/y: (p/(i)/y - p/(i + 1)/y) * k_i + p/(i + 1)/y

				;% Algorithm 2. The orientational constraints
				; apply angle contraints
				if all [n >= 3 2 <= i i <= (n - 1)] [
					angle: three-points-angle p/(i + 1) p/(i) p/(i - 1)
					if angle < 0 [angle: 360 + angle] ; normalize to 0..360
					;% Check whether the rotor R is within the motion range bounds
					case [
						angle < p/(i)/as [
							;% reorient the joint pi in such a way that the rotor will be within the limits
							angle: negate angle - p/(i)/as
							rotate-point-around-point p/(i) sine angle cosine angle p/(i + 1)
						]
						angle > (p/(i)/as + p/(i)/al) [
							;% reorient the joint pi in such a way that the rotor will be within the limits
							angle: (p/(i)/as + p/(i)/al) - angle
							rotate-point-around-point p/(i) sine angle cosine angle p/(i + 1)
						]
					]
				]

			]

			;% STAGE 2: BACKWARD REACHING
			;% Set the root p1 its initial position.
			p/1/x: b/x
			p/1/y: b/y
			for i 1 n - 1 1 [
				;% Find the distance ri between the new joint position pi and the joint pi+1
				r_i: point-point-distance p/(i + 1) p/(i)
				k_i: d/(i) / r_i
				;% Find the new joint positions pi. using lineaar interpolation
				p/(i + 1)/x: (p/(i + 1)/x - p/(i)/x) * k_i + p/(i)/x
				p/(i + 1)/y: (p/(i + 1)/y - p/(i)/y) * k_i + p/(i)/y

				;% Algorithm 2. The orientational constraints
				; apply angle contraints
				if all [n >= 3 2 <= i i <= (n - 1)] [
					angle: three-points-angle p/(i + 1) p/(i) p/(i - 1)
					if angle < 0 [angle: 360 + angle] ; normalize to 0..360
					;% Check whether the rotor R is within the motion range bounds
					case [
						angle < p/(i)/as [
							;% reorient the joint pi in such a way that the rotor will be within the limits
							angle: negate angle - p/(i)/as
							rotate-point-around-point p/(i + 1) sine angle cosine angle p/(i)
						]
						angle > (p/(i)/as + p/(i)/al) [
							;% reorient the joint pi in such a way that the rotor will be within the limits
							angle: (p/(i)/as + p/(i)/al) - angle
							rotate-point-around-point p/(i + 1) sine angle cosine angle p/(i)
						]
					]
				]

			]

			difA: point-point-distance p/(n) t
			tol: tol * 2 ; avoid infinite loop
		]
		
		if all [bool difA > tolerance][
			;The target is unreachable, but we want to reach it
			dx: t/x - p/(n)/x
			dy: t/y - p/(n)/y
			; translate all points so end-effector reaches target
			for i 1 n 1 [
				p/(i)/x: p/(i)/x + dx
				p/(i)/y: p/(i)/y + dy
			]
		]

		p
	]

] ; context

] ; value?

;==== example ====

do ; just comment this line to avoid executing examples
[
	if system/script/title = "FABRIK IK solver" [;do examples only if script started by us
	do bind [ ; bind to simplify code

		if error? try [do load load-script-thru/flash/warn/from %feel-loose.r %../../gui/][quit]

		;print "" ; open console

		IK-points: copy []
		IK-set: does [
			clear IK-points
			repeat face next pts/pane [
				append/only IK-points reduce [
					'x face/offset/x 'y face/offset/y
					; FIXME: check values < 0 , < -360 and > 360 , start > end , start = end
					'as any [attempt [face/angle-start] 0]
					'al any [attempt [face/angle-length] 360]
					]
			]
			bkg/effect/2: draw-lines
			show pts
		]
		IK-get: has [
			i
			][
			i: 1
			repeat face next pts/pane [
				if error? err: try [face/offset: as-pair IK-points/(i)/x IK-points/(i)/y][?? i probe IK-points err]
				i: i + 1
			]
			; redraw
			bkg/effect/2: draw-lines
			show pts
			
		]
		points-list: copy []
		draw-lines: has [
			point prev_point ang
			][
			points-list: append clear points-list compose [pen (yellow) line]
			
			repeat point IK-points [
				append points-list 8x10 + as-pair point/x point/y
			]
			append points-list compose [pen (white)]
			prev_point: IK-points/1
			repeat point IK-points [
				ang: atan2 prev_point/x - point/x prev_point/y - point/y
				append points-list reduce [
					'transform ang as-pair point/x point/y 1 1 8x10
					'arc as-pair point/x point/y 20x20 point/as point/al 'closed
					'reset-matrix
				]
				prev_point: point
			]
			;??
			points-list
		]

		view layout [
			origin 0
			h3 "Move green points by dragging them"
			h3 "Right click green points to delete them"
			check-drag: check-line "Fixed root point" false
			style point box 20x19 
				effect [draw [pen 0.255.0 fill-pen 0.200.0 circle 7x9 4]]
				feel [
					click: 0
					engage: func [face action event][
						if action = 'alt-down [click: event/time]
						; when right-click delete point
						if all [action = 'alt-up (event/time - click) < 250] [remove find face/parent-face/pane face IK-set]
					]
				]
				loose [action: [IK-set]]
				with [angle-start: 0 angle-length: 360]
			pts: panel gray [
				bkg: box 600x600 with [effect: [draw []]]
				at 300x200 point
				at 250x290 point with [angle-start: 180 + 40 angle-length: 50]
				at 200x300 point
				at 150x250 point
				at 120x230 radio-line ""
					loose [
						action: [
							FABRIK/drag IK-points reduce ['x face/offset/x 'y face/offset/y] not get-face check-drag
							IK-get
						]
					]
			]
			do [IK-set]
		]

	;halt
	] FABRIK-ctx ; bind
	] ; if title
]
