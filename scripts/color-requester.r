REBOL [
	title: "Choose and convert colors"
	needs: "Recent versions of %feel-loose.r, %simple-spin-number-style.r, %simple-pop-down-style.r"
	Date: 31-12-2023
	Version: 0.8.10
	File: %color-requester.r
	Author: "Marco Antoniazzi"
	Rights: "Copyright (C) 2021 Marco Antoniazzi"
	Purpose: "Requests a color or modify or convert it"
	eMail: [luce80 AT libero DOT it]
	History: [
		0.0.1 [09-05-2020 "Started"]
		0.8.1 [21-06-2020 "Mature enough"]
		0.8.2 [05-07-2020 "UPD: Better tab and enter key handling"]
		0.8.3 [11-07-2020 "UPD: remove global event func when closing window"]
		0.8.4 [19-07-2020 "FIX: non-focus of grad-sliders knobs by fixing %feel-loose.r"]
		0.8.5 [24-07-2020 "FIX: unfocus when switching to palette's panel"]
		0.8.6 [11-08-2020 "FIX: speedup by better handling interacions UPD: minor cleanups"]
		0.8.7 [27-09-2020 "FIX: added -style to modules names, avoid tab on choice-btn, better key support"]
		0.8.8 [24-11-2020 "FIX: division by 0 in rgb-to-hsi. UPD: initial console message, keyboard input speedup"]
		0.8.9 [12-02-2021 "ADD: RGB-to-sRGB (lossy) conversion"]
		0.8.10 [31-12-2023 "UPD: improved load-script-thru"]
	]
	Category: [util vid gfx]
	library: [
		level: 'advanced
		platform: 'all
		type: 'function
		domain: [gui VID]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
		see-also: none
	]
	thumbnail: https://i.postimg.cc/xCks0n53/color-requester-mini.png
	todo: {
		Add possibility to choose a named color
		Show old color also in palette mixer panel
		Convert "info" widget to field to make converted colors editable (and searchable?)
	}
]
; misc
	script-version: func [
		source [string!]
		/local version spaces chars
		][
		version: 0.0.0
		chars: complement spaces: charset " ^-^/"
		parse/all source [
			thru "REBOL" any spaces "[" thru "version:" some spaces
			copy version some chars
		]
		to-tuple version
	]
	undirize: func ["Returns a copy of the path turned into a file."
		path [file! url! string!]
		][
		path: copy path
		while [find "/\" path: back tail path] [remove path]
		head path
	]
	choose_file: func [filter [string!] /local file-name] [
		until [
			file-name: request-file/keep/only/filter filter
			if none? file-name [return none]
			exists? file-name
		]
		to-rebol-file file-name
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
		name [file! url!]
		/flash "Flash a message to the user while downloading"
		/warn "Alert user if script not found"
		/from path [file! url!] "Optional path where to search for the script"
		/version ver [tuple!] "Minimum version required"
		/local cache-name modul check-ver
		][
		check-ver: func [name /local modul][if ver > script-version modul: read name [modul: none] modul]

		if not value? 'view-root [view-root: either system/version/4 = 3 [%/C/Users/Public/Documents] [%/tmp]]
		cache-name: view-root/:name
		ver: any [ver 0.0.0]
		modul: any [
			attempt [check-ver path/:name] ; try optional dir 
			attempt [check-ver cache-name] ; try the cache
			attempt [check-ver name] ; try current dir
			attempt [ ; try loading it or downloading it from www.rebol.org
				switch request [rejoin [form name " not found or wrong version, load it, download it from www.rebol.org or quit?"] "Load" "Download" "Quit"] [
					#[none] [quit]
					#[true] [check-ver choose_file "*.r"]
					#[false] [
						modul: rejoin [http://www.rebol.org/download-a-script.r?script-name= name]
						modul: mold/only load/all as-string either flash [download modul][read modul]
						if not find modul "REBOL [" [make error! "Script not found"]
						if ver > script-version modul [make error! "Script version too small"] ; FIXME: errors are silenced by attempt [...
						write cache-name modul ; FIXME: append it to a cache list of scripts instead
						modul
					]
				]
			]
		]
		if all [not modul warn] [alert rejoin ["Script <" name "> not found or version too small."]]
		modul
	]
;
if error? try [ ; use "do load" to avoid executing examples
	do load load-script-thru/flash/warn/from/version %feel-loose.r %../ 0.2.1
	do load load-script-thru/flash/warn/from/version %simple-spin-number-style.r %../simple 0.9.0 ; 0.9.3
	do load load-script-thru/flash/warn/from/version %simple-pop-down-style.r %../simple 0.3.1
	][
	quit
]

; color spaces conversions
color-conv-ctx: context [
	to-tuple-color: func [color [block!]][
		(1.0.0 * round color/1 * 255) + (0.1.0 * round color/2 * 255) + (0.0.1 * round color/3 * 255)
	]
	rgb-to-rgb: func [
		"Converts RGB to RGB. Values in range 0-1" 
		RGB [block!] "values in range 0-1"
		][
		copy RGB
	]

	rgb-to-hexadecimal: func [
		"Converts RGB value to hexadecimal number" 
		rgb [block!] "values in range 0-1"
		/local bin
		][
		remove remove to-hex to-integer to-binary to-tuple-color rgb
	]
	hexadecimal-to-rgb: func [
		"Converts hexadecimal number to RGB." 
		hex [issue! string!] "values in range 00-FF"
		][
		if "#" = first hex [remove hex]
		hex: debase/base form hex 16
		reduce [hex/1 / 255 hex/2 / 255 hex/3 / 255]
	]

	rgb-to-hsv: func [
		"Converts RGB value to HSV (hue, saturation, value). Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/local r g b chroma h v
		][
		set [r g b] rgb
		v: max max r g b
		chroma: v - min min r g b
		if chroma = 0 [return reduce [0 0 v]] ; achromatic gray
		h: case [
			v = r [g - b / chroma + 0]	; between yellow & magenta
			v = g [b - r / chroma + 2]	; between cyan & yellow
			v = b [r - g / chroma + 4]	; between magenta & cyan
		]
		if h < 0 [h: h + 6]
		reduce [h / 6 chroma / v v]
	]
	hsvf: func [h a b c /local k][
		k: abs (mod (6 * h + c) 6) - 3 
		k: min max 0 k - 1 1
		k: k * a + b 
	]
	hsv-to-rgb: func [
		"Converts HSV (hue, saturation, value) to RGB. Values in range 0-1" 
		hsv [block!] "values in range 0-1"
		/local h s v a b
		][
		set [h s v] hsv
		if s = 0 [return reduce [v v v]] ; achromatic grey
		a: v * s
		b: v - a

		reduce [hsvf h a b 0 hsvf h a b 4 hsvf h a b 2]
	]

	rgb-to-hsl: func [
		"Converts RGB value to HSL (hue, saturation, lightness). Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/local r g b chroma h v L
		][
		set [r g b] rgb
		v: max max r g b
		chroma: v - L: min min r g b
		if chroma = 0 [return reduce [0 0 v]] ; achromatic gray
		h: case [
			v = r [g - b / chroma + 0]	; between yellow & magenta
			v = g [b - r / chroma + 2]	; between cyan & yellow
			v = b [r - g / chroma + 4]	; between magenta & cyan
		]
		if h < 0 [h: h + 6]

		L: v + L
		reduce [h / 6 chroma / (1 - abs L - 1) L / 2]
	]
	hslf: func [h a b c /local k][
		k: mod (12 * h + c) 12
		k: min max -1 min (k - 3) (9 - k) 1
		k: k * a + b 
	]
	hsl-to-rgb: func [
		"Converts HSL (hue, saturation, lightness) to RGB. Values in range 0-1" 
		hsl [block!] "values in range 0-1"
		/local h s a L 
		][
		set [h s L] hsl
		if s = 0 [return reduce [L L L]] ; achromatic gray
		a: 0 - (s * min L 1 - L)

		reduce [hslf h a L 0 hslf h a L 8 hslf h a L 4]
	]

	rgb-to-hwb: func [
		"Converts RGB value to HWB (hue, whiteness, blackness). Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/local r g b chroma h v w
		][
		set [r g b] rgb
		v: max max r g b
		chroma: v - w: min min r g b
		if chroma = 0 [return reduce [0 0 v]] ; achromatic gray
		h: case [
			v = r [g - b / chroma + 0]	; between yellow & magenta
			v = g [b - r / chroma + 2]	; between cyan & yellow
			v = b [r - g / chroma + 4]	; between magenta & cyan
		]
		if h < 0 [h: h + 6]
		reduce [h / 6  w  1 - v]
	]
	hwbf: func [h a b c /local k][
		k: abs (mod (6 * h + c) 6) - 3 
		k: min max 0 k - 1 1
		k: k * a + b
	]
	hwb-to-rgb: func [
		"Converts HWB (hue, whiteness, blackness) to RGB. Values in range 0-1" 
		hwb [block!] "values in range 0-1"
		/local h w b scale
		][
		set [h w b] hwb
		scale: 1 - w - b

		reduce [hwbf h scale w 0 hwbf h scale w 4 hwbf h scale w 2]
	]
	
	rgb-to-hsi: func [
		"Converts RGB value to HSI (hue, saturation, intensity). Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/local r g b w h s i
		][
		set [r g b] rgb
		i: r + g + b / 3
		s: either i = 0 [0][1 - ((min min r g b) / i) ]
		if s = 0 [return reduce [0 0 i]]
		{
		w: 0.5 * (r - g + r + b) / square-root (((r - g) * (r - g)) + ((r - b) * (g - b)))
		w: min max -1 w 1
		h: arccosine/radians w
		if b > g [h: 2 * pi - h]
		}
		h: arctangent/radians 1.73205080756888 * (g - b) / (r - g + r - b + 1e-10) ; ... (sqrt 3) * ...
		if h < 0 [h: h + pi]
		if b > g [h: h + pi]

		reduce [h / (2 * pi) s i]
	]
	hsi-to-rgb: func [
		"Converts HSI (hue, saturation, intensity) to RGB. Values in range 0-1" 
		hsi [block!] "values in range 0-1"
		/local h s i r g b
		][
		set [h s i] hsi
		if s = 0 [return reduce [i i i]]
		h: h * 360 ; h in 0-360 range
		case [
			h < 120 [
				b: 1 - s * i
				r: (s * cosine h) / (cosine (60 - h)) + 1 * i
				g: 3 * i - b - r
			]
			h < 240 [
				h: h - 120
				r: 1 - s * i
				g: (s * cosine h) / (cosine (60 - h)) + 1 * i
				b: 3 * i - r - g
			]
			h <= 360 [
				h: h - 240
				g: 1 - s * i
				b: (s * cosine h) / (cosine (60 - h)) + 1 * i
				r: 3 * i - g - b
			]
		]
		reduce [r g b]
	]

	rgb-to-cmy: func [
		"Converts RGB value to CMY (cyan, magenta, yellow). Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/local r g b
		][
		set [r g b] rgb
		reduce [1 - r 1 - g 1 - b]
	]
	cmy-to-rgb: func [
		"Converts CMY (cyan, magenta, yellow) to RGB. Values in range 0-1" 
		cmy [block!] "values in range 0-1"
		/local c m y
		][
		set [c m y] cmy
		reduce [1 - c 1 - m 1 - y]
	]

	rgb-to-cmyk: func [
		"Converts RGB value to CMYK (cyan, magenta, yellow, black). Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/local r g b c m y k
		][
		set [r g b] rgb
		set [c m y] reduce [1 - r 1 - g 1 - b]
		k: min min c m y
		if k = 1 [return copy [0 0 0 1]]
		reduce [c - k / (1 - k)   m - k / (1 - k)   y - k / (1 - k)   k]
	]
	cmyk-to-rgb: func [
		"Converts CMYK (cyan, magenta, yellow, black) to RGB. Values in range 0-1" 
		cmyk [block!] "values in range 0-1"
		/local c m y k
		][
		set [c m y k] cmyk
		k: 1 - k
		reduce [1 - c * k  1 - m * k  1 - y * k]
	]

	; values from http://www.brucelindbloom.com/index.html?Eqn_RGB_to_XYZ.html
	rgb-to-XYZ-sRGB-D65: [
		[0.4124564  0.3575761  0.1804375]
		[0.2126729  0.7151522  0.0721750]
		[0.0193339  0.1191920  0.9503041]
	]
	XYZ-to-rgb-sRGB-D65: [
		[ 3.2404542 -1.5371385 -0.4985314]
		[-0.9692660  1.8760108  0.0415560]
		[ 0.0556434 -0.2040259  1.0572252]
	]
	dot: func [
		row [block!]
		col [block!]
		][
		(row/1 * col/1) + (row/2 * col/2) + (row/3 * col/3)
	]
	gamma-compress: func [rgb /local u][
		repeat u 3 [

			rgb/(u): either rgb/(u) <= 0.04045 [
				rgb/(u) / 12.92
			][
				power (rgb/(u) + 0.055) / 1.055 2.4
			]
		]
		rgb
	]
	gamma-expand: func [rgb /local u][
		repeat u 3 [

			rgb/(u): either rgb/(u) <= 0.0031308 [
				rgb/(u) * 12.92
			][
				(1.055 * power rgb/(u) (1 / 2.4)) - 0.055
			]
		]
		rgb
	]

	rgb-to-xyz: func [
		"Converts RGB value to XYZ. Values in range 0-1" 
		rgb [block!] "values in range 0-1"
		/space ws [word! string!]
		/white ref [word! string!]
		/local mat
		][
		ws: form any [ws "sRGB"]
		ref: form any [ref "D65"]
		mat: get bind to-word join "rgb-to-XYZ-" [ws "-" ref] self
		rgb: gamma-compress copy rgb
		reduce [dot mat/1 rgb dot mat/2 rgb dot mat/3 rgb]
	]
	xyz-to-rgb: func [
		"Converts XYZ to RGB. Values in range 0-1" 
		xyz [block!] "values in range 0-1"
		/space ws [word! string!]
		/white ref [word! string!]
		/local mat rgb
		][
		ws: form any [ws "sRGB"]
		ref: form any [ref "D65"]
		mat: get bind to-word join "XYZ-to-rgb-" [ws "-" ref] self
		rgb: reduce [dot mat/1 xyz dot mat/2 xyz dot mat/3 xyz]
		gamma-expand rgb
	]

	rgb-to-srgb: func [
		"Converts RGB to sRGB. Values in range 0-1" 
		RGB [block!] "values in range 0-1"
		][
		gamma-compress copy RGB
	]
	srgb-to-rgb: func [
		"Converts sRGB to RGB. Values in range 0-1" 
		sRGB [block!] "values in range 0-1"
		][
		gamma-expand copy sRGB
	]

	rgb-to-YPbPr-SDTV: [
		[ 0.299  0.587  0.114]
		[-0.169 -0.331  0.500]
		[ 0.500 -0.419 -0.081]
	]
	YPbPr-to-rgb-SDTV: [
		[ 1.000  0.000  1.402]
		[ 1.000 -0.344 -0.714]
		[ 1.000  1.722  0.000]
	]
	rgb-to-YPbPr: func [
		"Converts RGB value to YPbPr with values in range [0 1] and [-.5 +.5]" 
		rgb [block!] "values in range 0-1"
		/tv video [word! string!]
		/local mat
		][

		video: form any [video "SDTV"]
		mat: get bind to-word append copy "rgb-to-YPbPr-" video self
		reduce [dot mat/1 rgb dot mat/2 rgb dot mat/3 rgb]
	]
	YPbPr-to-rgb: func [
		"Converts YPbPr with values in range [0 1] and [-.5 +.5] tp RGB values in range [0 1]" 
		YPbPr [block!] "values in range [0 1] and [-.5 +.5]"
		/tv video [word! string!]
		/local mat
		][

		video: form any [video "SDTV"]
		mat: get bind to-word append copy "YPbPr-to-rgb-" video self
		reduce [dot mat/1 YPbPr dot mat/2 YPbPr dot mat/3 YPbPr]
	]
	rgb-to-YCbCr-full: [
		[ 0.299  0.587  0.114]
		[-0.169 -0.331  0.500]
		[ 0.500 -0.419 -0.081]
	]
	YCbCr-to-rgb-full: [
		[ 1.000  0.000  1.400]
		[ 1.000 -0.343 -0.711]
		[ 1.000  1.765  0.000]
	]
	rgb-to-YCbCr: func [
		"Converts RGB value to YCbCr with values in range [0 1]" 
		rgb [block!] "values in range 0-1"
		/tv video [word! string!]
		/local mat
		][

		video: form any [video "full"]
		mat: get bind to-word append copy "rgb-to-YCbCr-" video self
		reduce [dot mat/1 rgb 0.5 + dot mat/2 rgb 0.5 + dot mat/3 rgb]
	]
	YCbCr-to-rgb: func [
		"Converts YCbCr with values in range [0 1] tp RGB values in range [0 1]" 
		YCbCr [block!] "values in range [0 1]"
		/tv video [word! string!]
		/local mat
		][
		YCbCr/2: YCbCr/2 - .5
		YCbCr/3: YCbCr/3 - .5

		video: form any [video "full"]
		mat: get bind to-word append copy "YCbCr-to-rgb-" video self
		reduce [dot mat/1 YCbCr dot mat/2 YCbCr dot mat/3 YCbCr]
	]
	rgb-to-yuv-atv: [
		[ 0.299  0.587  0.114]
		[-0.147 -0.289  0.436]
		[ 0.615 -0.515 -0.100]
	]
	yuv-to-rgb-atv: [
		[ 1.000  0.000  1.140]
		[ 1.000 -0.395 -0.581]
		[ 1.000  2.032  0.000]
	]
	rgb-to-yuv: func [
		"Converts RGB value to YUV with values in range [0 1] [-0.436 +0.436] [-0.615 +0.615]" 
		rgb [block!] "values in range 0-1"
		/local mat
		][

		mat: rgb-to-yuv-atv
		reduce [dot mat/1 rgb dot mat/2 rgb dot mat/3 rgb]
	]
	yuv-to-rgb: func [
		"Converts YUV with values in range [0 1] [-0.436 +0.436] [-0.615 +0.615] to RGB values in range [0 1]" 
		yuv [block!] "values in range [0 1] [-0.436 +0.436] [-0.615 +0.615]"
		/local mat
		][

		mat: yuv-to-rgb-atv
		reduce [dot mat/1 yuv dot mat/2 yuv dot mat/3 yuv]
	]
	rgb-to-CIELAB: func [
		"Converts RGB value to CIE L*a*b* with values in range [0 100] and [-128 128]" 
		rgb [block!] "values in range [0 1]"
		/local xyz value
		][
		xyz: rgb-to-xyz rgb
		; observer = 2°, illuminant = D65
		xyz/1: xyz/1 * 100 / 95.047
		xyz/2: xyz/2 * 100 / 100.0
		xyz/3: xyz/3 * 100 / 108.883
		forall xyz [
			value: xyz/1
			xyz/1: either value > 0.008856 [
				power value (1 / 3)
			][
				7.787 * value + (16 / 116)
			]
		]
		reduce [116 * xyz/2 - 16  500 * (xyz/1 - xyz/2)  200 * (xyz/2 - xyz/3)]
	]
	CIELAB-to-rgb: func [
		"Converts CIE L*a*b* with values in range [0 100] and [-128 128] to RGB values in range [0 1]"
		Lab [block!] "values in range [0 100] and [-128 128]"
		/local x y z xyz value
		][
		y: Lab/1 + 16 / 116
		x: Lab/2 / 500 + y
		z: y - (Lab/3 / 200)

		xyz: reduce [x y z]
		forall xyz [
			value: power xyz/1 3
			xyz/1: either value > 0.008856 [
				value
			][
				xyz/1 - (16 / 116) / 7.787
			]
		]
		; observer = 2°, illuminant = D65
		xyz/1: xyz/1 * 95.047 / 100
		xyz/2: xyz/2 * 100.0 / 100
		xyz/3: xyz/3 * 108.883 / 100
		xyz-to-rgb xyz
	]

]

if not value? 'color-req-ctx [

color-req-ctx: context [
	tab-chain: none

	; series
		cycle: func [
			"Cycles through a series"
			series [series! port!]
			/back   ; redefined
			][
			either back [
				system/words/back either head? series [tail series] [series]
			][
				either tail? next series [head series] [next series]
			]
		]
		fry: func [
			series [series!]
			items [series!]
			/with
				marker [word!]
			][
			marker: any [marker '_]
			items: copy items
			replace/all copy series marker does [take items]
		] 
	;
	; control
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
	;
	; math
		atan2: func [; author: Steeve Antoine 2009, modified by luce80
			"Angle of the vector (0,0)-(x,y) with arctangent y / x. The resulting angle is in range 0 360"
			x [number!] y [number!]
			][
			if x = 0 [x: 1e-10]
			;mod add arctangent y / x pick [0 180] x > 0 360 ; 0 at east
			add arctangent y / x pick [90 270] x > 0 ; 0 at north, clock-wise
		]
		rotate-point: func [p [pair!] sina [decimal!] cosa [decimal!] /local px py][
			px: p/x
			py: p/y
			p/x: (px * cosa) - (py * sina)
			p/y: (px * sina) + (py * cosa)
			p
		]
		rotate-point-around-point: func [p [pair!] sina [decimal!] cosa [decimal!] center [pair!] /local px py cx cy][
			px: p/x
			py: p/y
			cx: center/x
			cy: center/y
			p/x: (px * cosa) - (py * sina) - (cx * cosa) + (cy * sina) + cx
			p/y: (px * sina) + (py * cosa) - (cx * sina) - (cy * cosa) + cy
			p
		]
		re-form-dec: func ["Convert scientific to decimal notation. (modifies)"
			number [string!] /local digit pos end sign exp
			][
			sign: 0
			digit: charset ["0123456789"]
			parse/all number [
				opt ["-" (sign: 1)] any digit opt [pos: "." ]
				any digit [
					end: "E-" (if pos <> end [remove pos end: back end] pos: remove/part end 2)
					:pos copy exp some digit end: (exp: do exp remove/part pos end)
				]
				| (return number) ; if exponent not found abort
			]
			insert/dup insert skip number sign "0." "0" exp - 1
			number
		]
		re-form-decs: func [num [string!] /local pos][ ; FIXME: could be a refinement of re-form-dec
			pos: num
			until [
				re-form-dec pos
				none? pos: find/tail pos " "
			]
			num
		]
	;
	; tuple<->block
		normalize-color: func [color [tuple!]] [
			reduce [(color/1 / 255) (color/2 / 255) (color/3 / 255)]
		]
		to-tuple-color: func [color [block!]][
			(1.0.0 * round color/1 * 255) + (0.1.0 * round color/2 * 255) + (0.0.1 * round color/3 * 255)
		]
		scale-block: func [color [block!] scale [block!]] [
			color: copy color
			foreach [mult rnd] scale [
				color/1: round/to color/1 * mult rnd
				color: next color
			]
			head color
		]
	;

	color-styles: stylize [
		grad-slider: box
			edge [size: 1x1 color: none]
			with [
				data: 0
				low: 0 high: 1 step: none
				words: [low high step [
					if not number? second args [make error! reduce ['script 'expect-set "number!" type? second args]]
					set in new first args second args next args
					]
				]
				knob-w_2: 7
				width-in: 255
				box-slide: none
				box-knob: none
				main: none
				main-colors: none
				this: self
				access: make ctx-access/data-number [
					set-face*: func [face value][
						if face/data = value [exit]
						face/data: value: min max face/low value face/high
						face/box-knob/offset/x: round width-in * (value - face/low) / (face/high - face/low + 1e-10)
					]
				]
				chg-grad: func [comp rgb][
					box-slide/effect/3: box-slide/effect/4: rgb
					box-slide/effect/3/(comp): 0
					box-slide/effect/4/(comp): 255
					show box-slide
				]

				init: [
					this: self
					if none? step [step: (high - low) / 100]
					main-colors: any [colors [0.0.0 255.0.0]]
					colors: none
					color: none
					main: layout [
						origin as-pair knob-w_2 0
						at as-pair knob-w_2 4
						box-slide: box width-in * 1x0 + 0x20 edge none
							;effect reduce ['gradient 1x0 main-colors/1 main-colors/2]
							feel [
								engage: func [face action event /local offs][
									offs: face/offset/x - knob-w_2
									box-knob/offset/x: min max offs offs + event/offset/x offs + width-in
									do box-knob/feel/action
									if action = 'down [box-knob/edge/size: 3x3]
									if action = 'up [box-knob/edge/size: 2x2]
									show box-knob
								]
							]
						at 0x0
						box-knob: box (knob-w_2 * 2x0 + 0x28)
							with [flags: [no-focus]] ; do not give focus to us because it will be given to a spin-number
							edge [size: 2x2 color: gray]
							feel [
								engage: func [face action event][
									if action = 'down [box-knob/edge/size: 3x3]
									if action = 'up [box-knob/edge/size: 2x2]
									show box-knob
								]
							]
							loose [
								step: 1x0
								range-x: as-pair box-slide/offset/x - knob-w_2 box-slide/offset/x - knob-w_2 + width-in
								action: [
									this/data: box-knob/offset/x / box-slide/size/x
									this/data: min max 0 this/data 1
									this/data: this/data * (this/high - this/low) + this/low
									this/action this this/data
								]
							]
					] ; layout
					size: main/size + (edge/size * 2)
					pane: get in main 'pane
					if all [effect not find effect 'gradient] [insert effect [gradient 1x0 230.230.230 230.230.230]]
					box-slide/effect: effect
					effect: none
					user-data: data
					data: none ; force refresh in set-face
				] ; init
			] ; with
		

		palette-mixer: box
			font [size: 14]
			effect [draw [translate 2x2]]
			feel [
				engage: func [face action event /local pos cell] [
					if action = 'up [
						pos: event/offset
						cell: min max 1x1 pos - 2x2 - face/edge/size / face/swatch-size + 1x1 7x6
						case [
							cell/y <= 3 [face/source: none face/dest: cell]
							cell/y  = 4 [face/source: none face/dest: none]
							cell/y <= 6 [
								either face/dest [
									face/source: cell face/mix face/dest: none
								][
									face/dest: cell
								]
							]
						]
						either face/dest [
							face/effect/draw/("evpen"): white
							face/effect/draw/("evpos"): face/swatch-size * face/dest
							do-face face face/effect/draw/(form face/dest)
						][
							face/effect/draw/("evpen"): none
						]
						show face
					]
				]
			]
			with [
				access: make ctx-access/data-number [
					set-face*: func [face value][
						face/dest: value/1
						face/data: value/2
					]
				]
				colors: [ ; my own "balanced" palette (inspired by McBeth colors)
					234.184.142 255.255.0  160.187.37 204.249.218 189.186.214 241.137.163  255.255.255
					255.0.0     255.102.0  0.156.19   0.171.128   0.164.227   175.44.116   128.128.128
					143.48.29   89.44.16   0.79.0     37.96.165   36.49.131   117.34.118   0.0.0
				]
				source: none
				dest: none
				swatch-size: 50x30
				orig: 0x0
				mix: func [/local draw lft mid rgt cell swatch][
					draw: effect/draw
					if none? source [exit]
					if none? dest [exit]
					draw/(form source): either dest = 0x0 [data] [draw/(form dest)]
					mid: source
					source/x: 1
					lft: draw/(form source)
					rgt: draw/(form mid)
					for cell mid/x - 1 2 -1 [
						swatch: form as-pair mid/x - cell + 1 source/y
						lft/1: round rgt/1 - lft/1 / cell + lft/1
						lft/2: round rgt/2 - lft/2 / cell + lft/2
						lft/3: round rgt/3 - lft/3 / cell + lft/3
						draw/(swatch): lft
					]

					lft: draw/(form mid)
					source/x: 7
					rgt: draw/(form source)
					for cell 7 - mid/x 2 -1 [
						swatch: form as-pair 7 - cell + 1 source/y
						lft/1: round rgt/1 - lft/1 / cell + lft/1
						lft/2: round rgt/2 - lft/2 / cell + lft/2
						lft/3: round rgt/3 - lft/3 / cell + lft/3
						draw/(swatch): lft
					]
				]
				append init [
					orig: 0x0
					repeat r 6 [
						repeat c 7 [
							append effect/draw compose [
								pen (either r = 4 [none][black])
								fill-pen (form as-pair c r) (pick colors (r - 1 * 7 + c))
								box (orig) (orig + swatch-size)
							]
							orig/x: orig/x + swatch-size/x
						]
						orig/x: 0
						orig/y: orig/y + swatch-size/y
					]
					append effect/draw compose [font (font) text (swatch-size * 3 + 10 * 0x1 + 4x0) "Pick a color and select a box below"]
					append effect/draw compose [
						pen "evpen" none line-width 2 fill-pen none
						translate "evpos" (swatch-size * 1x1)
						box (1x1) (0x0 - swatch-size - 1x1)
					]
					effect/draw/("1x5"): white
					effect/draw/("7x5"): black
					effect/draw/("1x6"): black
					effect/draw/("7x6"): white
					source: 1x5 dest: 1x5 mix
					source: 1x6 dest: 1x6 mix
					source: dest: none
					size: edge/size * 2 + as-pair swatch-size/x * 7 + 1 + 4 swatch-size/y * 6 + 1 + 4
				]
			]

	]

	ctx-rgb: context [
		gs-1:
		gs-2:
		gs-3:
		spin-1:
		spin-2:
		spin-3:
		none
		change_grads: func [rgb][
			gs-1/chg-grad 1 rgb
			gs-2/chg-grad 2 rgb
			gs-3/chg-grad 3 rgb
		]
		update: func [
			comp
			value
			/local rgb
			][
			if not value? 'box-sample [exit]
			set-face get in ctx-rgb to-word append copy "gs-" comp value
			set-face get in ctx-rgb to-word append copy "spin-" comp value
			rgb: get-face box-sample
			rgb/(comp): value / 255
			set-face box-sample rgb
			; always change ALL gradients because they depend on all 3 components
			change_grads box-sample/color
		]
		rgb: layout/tight [
			styles color-styles
			style grad-slide grad-slider 128 low 0 high 255 step 1 effect [gradient 1x0 0.0.0 255.0.0]
			style spin spin-number 70x22 128.0 integer low 0 high 255
			space 0x-4
			across
			gs-1: grad-slide [focus/no-show spin-1 update 1 value]
			pad 0x4
			spin-1: spin [update 1 value]
			h3 "R" feel none
			return
			gs-2: grad-slide [focus/no-show spin-2 update 2 value]
			pad 0x4
			spin-2: spin [update 2 value]
			h3 "G" feel none
			return
			gs-3: grad-slide [focus/no-show spin-3 update 3 value]
			pad 0x4
			spin-3: spin [update 3 value]
			h3 "B" feel none
			do [tab-chain: reduce [spin-1/field spin-2/field spin-3/field]]
		]
	]

	ctx-hsl-g: context [
		hsl-gizmo:
		spin-1:
		spin-2:
		spin-3:
		none
		update_sample: func [/local hsl][
			if not value? 'box-sample [exit]
			hsl: reduce [((get-face spin-1) / 360)  (min max 1e-10 (get-face spin-2) / 100 1 - 1e-10) (min max 1e-10 (get-face spin-3) / 100 1 - 1e-10)]
			set-face box-sample color-conv-ctx/hsl-to-rgb hsl
		]
		hsl-giz: layout/tight [
			hsl-gizmo: box 200x200
				effect compose/deep [draw [
					; HSL gizmo
					; H
					pen none
					fill-pen conic 100x100 0 360 90 1 1
					red yellow green cyan blue magenta red
					circle 100x100 100
					fill-pen "G" (white + 0.0.0.255) ; grayness (saturation)
					circle 100x100 100
					fill-pen "D" (black + 0.0.0.255) ; darkness (value)
					circle 100x100 100
					fill-pen white
					circle 100x100 75

					pen 220.220.220
					; S
					fill-pen 
					conic 100x100 10 360 170 1 1
					black "S0" gray "S1" red
					arc 100x100 70x70 190 160 closed
					; L
					fill-pen 
					conic 100x100 200 360 -10 1 1
					white "L.5" red black
					arc 100x100 70x70 10 160 closed

					fill-pen white
					circle 100x100 45
					pen none
					; old (optional)
					fill-pen "old" black
					arc 100x100 40x40 180 180 closed
					; new
					fill-pen "new" red
					arc 100x100 40x40 0 180 closed

					pen black fill-pen none
					circle 100x100 40

					; knobs
					translate "KH" 100x12
					pen white line-width 2.5 fill-pen none
					circle 0x0 11.5
					pen black line-width 2
					circle 0x0 10
					reset-matrix
					translate "KS" 100x42
					pen white line-width 2.5
					circle 0x0 11.5
					pen black line-width 2
					circle 0x0 10
					reset-matrix
					translate "KL" 100x157
					pen white line-width 2.5
					circle 0x0 11.5
					pen black line-width 2
					circle 0x0 10
					reset-matrix
				]]
				feel [
					engage: func [face action event /local k pos radius angle col][
						if find [down over away] action [
							pos: event/offset - 100x100
							radius: 1e-10 + square-root (pos/x * pos/x) + (pos/y * pos/y)
							angle: atan2 pos/x pos/y
						]
						case [
							action = 'down [
								face/k: case [
									radius <= 40 [
										exit
									]
									radius <= 70 [
										face/orbit: 58
										case [
											all [ 95 < angle angle < 265] [face/ang-min: 100 face/ang-max: 260 "KL"]
											any [275 < angle angle <  85] [face/ang-min: 100 face/ang-max: 260 angle: mod angle - 180 360 "KS"]
											'else [none]
										]
									]
									radius <= 101 [
										face/orbit: 88
										face/ang-min: 0 face/ang-max: 360
										"KH"
									]
									'else [
										none
									]
								]
								if face/k [
									if radius <> face/orbit [
										pos: pos * (face/orbit / radius) ; re-put on orbit
									]
								]
							]
							find [over away] action [
								if none? face/k [exit]
								if face/k = "KS" [angle: mod angle - 180 360]
								if radius <> face/orbit [
									pos: pos * (face/orbit / radius) ; re-put on orbit
								]
								if angle < face/ang-min [
									pos: either face/k = "KS" [-57x-11][56x11] ; "hardcoded" to avoid rounding errors
									angle: face/ang-min
								]
								if angle > face/ang-max [
									pos: either face/k = "KS" [56x-11][-57x11] ; "hardcoded" to make it more stable
									angle: face/ang-max
								]
								;?? angle
							]
							action = 'up [
								face/k: none
							]
						]
						if find [down up over away] action [
							if face/k [
								face/effect/draw/(face/k): pos + 100x100
								switch face/k [
									"KH" [face/data/1/1: angle / 360]
									"KS" [face/data/1/2: min max 1e-10  ((angle - 100) / (260 - 100))  1 - 1e-10]
									"KL" [face/data/1/3: min max 1e-10  1 - ((angle - 100) / (260 - 100))  1 - 1e-10]
								]
								face/update_grads
								do-face face face/data/1
							]
						]
					]
				]
				with [
					data: copy/deep [[0 0 0] [0 0 0]] ; new and optional default
					k: none
					orbit: 88
					ang-min: 0
					ang-max: 360
					modify?: false
					update_grads: func [/local col draw rgb][
						col: copy data/1
						draw: effect/draw
						rgb: color-conv-ctx/hsl-to-rgb col
						draw/("new"): to-tuple-color rgb
						if not modify? [draw/("old"): draw/("new")]
						draw/("G")/4: second to-tuple-color color-conv-ctx/rgb-to-hsv rgb ; note the use of HSV instead of HSL
						draw/("D")/4: third to-tuple-color color-conv-ctx/rgb-to-hsv rgb
						col/2: 0
						draw/("S0"): to-tuple-color color-conv-ctx/hsl-to-rgb col
						col/2: 1
						draw/("S1"): to-tuple-color color-conv-ctx/hsl-to-rgb col
						col/2: data/1/2
						col/3: 0.50
						draw/("L.5"): to-tuple-color color-conv-ctx/hsl-to-rgb col
						face
					]
					update_knobs: func [/local angle pos][
						angle: data/1/1 * 360
						pos: rotate-point 0x-88 sine angle cosine angle
						effect/draw/("KH"): pos + 100x100

						angle: data/1/2 * (170 - 10) + 10
						pos: rotate-point -58x0 sine angle cosine angle 
						effect/draw/("KS"): pos + 100x100

						angle: negate data/1/3 * (260 - 100) + 10
						pos: rotate-point -58x0 sine angle cosine angle 
						effect/draw/("KL"): pos + 100x100
					]
					access: make ctx-access/data-number [
						set-face*: func [face value][
							if all [2 = length? value face/data = value] [exit]
							if face/data/1 = value [exit]
							face/data: copy/deep value
							face/update_grads
							face/update_knobs
						]
					]
				]
				[ ; action
					focus/no-show switch face/k [
						"KH" [spin-1]
						"KS" [spin-2]
						"KL" [spin-3]
					]
					set-face box-sample color-conv-ctx/hsl-to-rgb face/data/1
				]
			return
			here: at
			across
			guide
			at here
			pad 37x0
			guide
			space 0x8
			style spin spin-number 70x22 50.0 low 0 high 100
			spin-1: spin 90.0 low 0 high 360 step 0.5 cycle [update_sample]
			h3 "H" feel none
			return
			spin-2: spin [update_sample]
			h3 "S" feel none
			return
			spin-3: spin [update_sample]
			h3 "L" feel none
			do [append tab-chain reduce [spin-1/field spin-2/field spin-3/field]]
		]
	]

	update_all: func [/local comp mult rgb hsl][
		rgb: box-sample/norm-color

		box-sample/set?: false ; avoid infinite loop and "bouncing"
		hsl: color-conv-ctx/rgb-to-hsl rgb
		foreach [face comp mult] reduce [
				ctx-hsl-g/spin-1 1 360 
				ctx-hsl-g/spin-2 2 100
				ctx-hsl-g/spin-3 3 100
				] [
			set-face face round/to hsl/(comp) * mult 0.01
		]
		set-face ctx-hsl-g/hsl-gizmo compose/deep [[(hsl)]]

		box-sample/set?: true
		foreach [face comp mult] reduce [
				ctx-rgb/gs-1 1 255
				ctx-rgb/gs-2 2 255
				ctx-rgb/gs-3 3 255
				ctx-rgb/spin-1 1 255
				ctx-rgb/spin-2 2 255
				ctx-rgb/spin-3 3 255
				] [
			set-face face rgb/(comp) * mult
		]
		ctx-rgb/change_grads box-sample/color
		
		set-face info-rgb box-sample/color
		do-face choice-conv none
	]

	svv/vid-face/color: snow ; background color of all windows ; FIXME: make this settable (light/dark)

	color-win: [
		styles color-styles
		origin 4x4
		panel-pal: panel svv/vid-face/color [
			pal-mix: palette-mixer [
				set-face box-sample normalize-color value
				box-sample/edge/color: none
				show box-sample
			]
			pad 2x0

			box-sample: box start-color
				edge [size: 1x1 color: none]
				feel [
					engage: func [face action event][
						if action = 'up [
							set-face pal-mix compose [0x0 (face/color)] 
							pal-mix/effect/draw/("evpen"): none
							face/edge/color: complement svv/vid-face/color
							show [face pal-mix]
						]
					]
				]
				with [
					norm-color: none
					set?: true
					access: make object! [
						set-face*: func [face value /local comp col chg][;print [ "box-samp-set" face/norm-color value set?]
							if not set? [exit]
							if value = face/norm-color [exit]
							face/norm-color: value
							face/color: to-tuple-color face/norm-color
							show face
							update_all
						]
						get-face*: func [face][
							copy face/norm-color
						]
					]
				] 
		]
		at 4x4
		panel-slides: panel svv/vid-face/color [
			sliders-rgb: box with [pane: ctx-rgb/rgb/pane append init [size: ctx-rgb/rgb/size + (edge/size * 2)]]
			pad 25x0
			sliders-hsl-giz: box with [pane: ctx-hsl-g/hsl-giz/pane append init [size: ctx-hsl-g/hsl-giz/size + (edge/size * 2)]]
		]
		do [panel-pal/size: panel-slides/size]
		return
		space 4x4
		across
		btn 100 "Palette & Mixer..." with [data: "Color sliders..."] [
			value: face/data
			face/data: face/text
			face/text: value
			
			unfocus
			move color-lay/pane 1 ; switch between sliders and palette panels
			show color-lay
		] 
		pad 50x0
		btn 100 "OK" [result: box-sample/color hide-popup]
		btn 100 "Cancel" escape [hide-popup]
		return
		below
		at 262x200
		text 100 "RGB" bold center
		info-rgb: info "0.0.0" 100
		pad -40x0
		choice-conv: choice-btn 140x24 "hexadecimal" data ["hexadecimal" "CIELab" "CMY" "CMYK" "HSI" "HSL" "HSV" "HWB" "sRGB" "XYZ" "YCbCr" "YPbPr" "YUV"] [
			use [rgb col-space col] [
				rgb: box-sample/norm-color
				col-space: get-face face
				col: color-conv-ctx/(to-word append copy "rgb-to-" col-space) rgb
				set-face info-conv re-form-decs switch col-space [
					"hexadecimal" [mold col]
					"CIELab" [fry "_  _  _" scale-block col [1 0.01 1 0.01 1 0.01]]
					"HSL" [fry "_° _% _%" scale-block col [360 0.01 100 0.01 100 0.01]]
					"HSV" [fry "_° _% _%" scale-block col [360 0.01 100 0.01 100 0.01]]
					"HSI" [fry "_° _% _%" scale-block col [360 0.01 100 0.01 100 0.01]]
					"HWB" [fry "_° _% _%" scale-block col [360 0.01 100 0.01 100 0.01]]
					"CMY" [fry "_ / _ / _" scale-block col [100 1 100 1 100 1]]
					"CMYK" [fry "_ / _ / _ / _" scale-block col [100 1 100 1 100 1 100 1]]
					;"RGB" [fry "_  _  _" scale-block col [1 0.01 1 0.01 1 0.01]]
					"sRGB" [fry "_  _  _" scale-block col [255 1 255 1 255 1]]
					"XYZ" [fry "_  _  _" scale-block col [1 0.01 1 0.01 1 0.01]]
					"YCbCr" [fry "_  _  _" scale-block col [1 0.001 1 0.001 1 0.001]]
					"YPbPr" [fry "_  _  _" scale-block col [1 0.01 1 0.01 1 0.01]]
					"YUV" [fry "_  _  _" scale-block col [1 0.01 1 0.01 1 0.01]]
				]
				show info-conv
			]
		]
		info-conv: info "" 140

	]
	color-req-event-func: func [face event][
		eat_events/skip [move key time] ; speedup movement and input by avoiding following all events
		if event/key = tab [
			if any [
				system/view/focal-face = none
				system/view/focal-face/style = 'spin
				system/view/focal-face/style = 'choice-list
				] [
				focus first tab-chain
				return none
			]
			if attempt [face: find tab-chain system/view/focal-face][
				do-face first face get-face first face
				face: first either event/shift [cycle/back face][cycle face]
				focus face
				return none
			]
		]
		if event/key = #"^M" [; enter
			if any [
				system/view/focal-face = none
				system/view/focal-face/style = 'spin
				system/view/focal-face/style = 'choice-list
				] [
				result: box-sample/color
				hide-popup
				return none
			]
		]
		event
	]

	; main
		start-color: 148.128.108

		result: none
		color-lay: none

		set 'request_color func [
			"Requests a color value." 
			/color clr [tuple!] "Start with this color" ; FIXME: better use /with as name ?
			/offset xy [pair!] "Offset of requester window"
			/modify "Modify the given color"
			][
			if none? :color-lay [
				color-lay: layout color-win
			]
			insert-event-func :color-req-event-func
			set-face box-sample normalize-color any [clr start-color]
			ctx-hsl-g/hsl-gizmo/modify?: modify
			result: none

			do pick [inform/title inform/title/offset] not offset color-lay "Choose a color" xy

			; restore defaults
			set-face box-sample normalize-color start-color
			ctx-hsl-g/hsl-gizmo/modify?: false
			remove-event-func :color-req-event-func
			result
		]

] ; color-req-ctx
] ; value?

do ; just comment this line to avoid executing examples
[
	if system/script/title = "Choose and convert colors" [;do examples only if script started by us

	print "Chosen color:"
	;probe request-color/color red
	probe request_color
	probe request_color/color crimson
	probe request_color/modify
	probe request_color/modify/color crimson

	halt
] ; if title
] ; do
