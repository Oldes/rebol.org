Rebol [
	title: "Tweener"
	file: %tweener.r
	author: "Marco Antoniazzi"
	Copyright: "(C) 2018 Marco Antoniazzi. All Rights reserved."
	email: [luce80 AT libero DOT it]
	date: 29-07-2018
	version: 0.7.5
	Purpose: "Make transitions between two values. Many easing functions to animate faces."
	History: [
		0.0.1 [01-05-2018 "Started"]
		0.5.1 [09-05-2018 "Completed sync and async modes"]
		0.6.1 [20-05-2018 "Implemented cubic-bezier, steps and frames functions"]
		0.6.2 [22-05-2018 "Implemented jitter function"]
		0.7.0 [26-05-2018 "Implemented async stoppable fade"]
		0.7.1 [27-05-2018 "Implemented defaults"]
		0.7.2 [01-06-2018 "Implemented CSS bezier defaults"]
		0.7.3 [03-06-2018 "Added nice example"]
		0.7.4 [10-06-2018 "Fix: set not only integers. Changed bind rejoin with reduce to-set-path"]
		0.7.5 [29-07-2018 "Fix: Frames button and frames default parameter should be 2 (thx @greggirwin)"]
	]
	library: [
		level: 'intermediate
		platform: 'all
		type: 'tool
		domain: [gfx animation]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
	]
	help: {
		This script provides 3 functions to create and stop trabsitions:
			<transit> 
				"Animate smoothly from one facet value to a new one over time."
				face [object!] "The face to which apply transition"
				'facet [word! path!] "The facet that will change"
				value [number! pair! tuple!] "New value"
				duration [number! time!] "Duration in seconds"
				easefunc [word!] "Function used to tween"
				/delay timed [number! time!] "Optional initial delay (default is 0)"
				/params a [number! block! none!] p [number!] "Parameters for functions that need them"
				/async tick-face [object!] "Make this transition asyncronous using tick-face 's timer"
			<transitions>
				"Animate smoothly from one or more facet(s) value(s) to new one(s) over time."
				specs [block!]
					{list of lists with faces, facets and values in the format:
						[
							face [object!] [
								[
									facet [word! path!]
									new-value [number! pair! tuple!]
									duration [number! time!]
									ease-function [word! function!]
									delay [number! time!]
									param1 [number! block!]
									param2 [number!]
								]
								...
							] 
							...
						]
					}
				/async tick-face [object!] "Make this transition asyncronous using tick-face 's timer"
			<stop_transition/async>
				"Stop a transition (only async for now)"
				face [object!] "The face which has the transition to be stopped"
				facet [word! path!] "The facet that is transitioning"
				/async tick-face [object!] "The <ticker> face which whose timer is used to give the pace"
			there are also <set-defaults> and <restore-defaults> to set and restore default duration, ease-function, delay and rate. 

				
		To use async mode you need a face to be used as a "ticker". See example face <ticker> at end of this file to see how it can be done.
		A synchronous transition is executed at maximum frame-rate and will start only after the previous synchronous transition has completed,
		an asynchronous transition is executed at a (almost) fixed frame-rate and will start indipendently of other transitions.
		
		Most easing functions are derived from Robert Penner's Easing Equations (see below).
		There are other functions inside the comments below.
		You can add your own easing function. See example "custom-ease" in axample part at the end of the script.
		An easing (interpolating) function is a function that:
			- passes through the points (0,0) and (1,1) , and almost any math function can be scaled, rotated and translated to pass through those points...
			- if it is adjustable with 1 or 2 parameters it MUST ALWAYS pass through (0,0) and (1,1) indipendently of the parameters.
		
		Please note that:
		- Transitions "specs" blocks are first compose/deep and then reduced.
		- In the example script there are not the "CSS" transition functions but they are implmented and with the same names: 
			ease, ease-in, ease-out, ease-in-out

	}
]
if not value? 'tweener-ctx [; avoid redefinition

tweener-ctx: context [
	pi_2: pi * 0.5
	round-fast: func [n] [n: 0.5 + n n - mod n 1]
	set-facet: func [face [object!] member [word! path! ] value /local][
		any [
			;attempt [do bind load rejoin ["face/" member ": " value] 'local]
			;attempt [do bind load rejoin ["face/" member ": to-integer tweener-ctx/round-fast " value] 'local]
			attempt [do reduce [append to-set-path 'face member value]]
			attempt [do reduce [append to-set-path 'face member to-integer round-fast value]]
		]
	]
	default-duration: 0.2
	default-ease: 'linear
	default-delay: 0
	default-rate: 50 ; FPS , or use e.g. 00:00:00.02 to set as seconds
	set-defaults: func [
		"Set default values"
		values [block!] "block of 0<->4 values"
		/duration value1 [number! time!]
		/ease value2 [word!]
		/delay value3 [number! time!]
		/rate value4 [number! time!]
		][
		default-duration: any [values/1 value1 default-duration]
		default-ease: any [values/2 value2 default-ease]
		default-delay: any [values/3 value3 default-delay]
		default-rate: any [values/4 value4 default-rate]
	]
	restore-defaults: func ["Restore values to their factory defaults"][
		default-duration: 0.2
		default-ease: 'linear
		default-delay: 0
		default-rate: 50
	]

	aface: none
	paused?: false
	sync-play: off

	
	easeInQuad: easeOutQuad: easeInOutQuad: easeOutInQuad:
	easeInCubic: easeOutCubic: easeInOutCubic: easeOutInCubic:
	easeInQuart: easeOutQuart: easeInOutQuart: easeOutInQuart:
	easeInQuint: easeOutQuint: easeInOutQuint: easeOutInQuint:
	easeInSine: easeOutSine: easeInOutSine: easeOutInSine:
	easeInExpo: easeOutExpo: easeInOutExpo: easeOutInExpo:
	easeInCirc: easeOutCirc: easeInOutCirc: easeOutInCirc:
	easeInElastic: easeOutElastic: easeInOutElastic: easeOutInElastic:
	easeInBack: easeOutBack: easeInOutBack: easeOutInBack:
	easeInBounce: easeOutBounce: easeInOutBounce: easeOutInBounce:
	easeInBounceInt: easeOutBounceInt: easeInOutBounceInt: easeOutInBounceInt:
	linear: bezier: steps: frames: jitter: none

	easefunctions: [ ; functions that we will not reverse
		linear "Easing equation function for a simple linear tweening, with no easing."
		[
		;t: t / d  ; this is placed at the beginning of every function so t is in range 0..1
		;c * t + b ; this is placed at the end of every function so t is scaled and translated to final value
		]
		
		bezier "Easing function using cubic bézier curve. Parameter <a> is a block! of 4 values for the coordinates of the 2 control points (default: [0.0 0.0 1.0 1.0])"
		[
		t: yforx/yfort yforx/tforx t any [a [0 0 1 1]]
		]

		steps "Easing equation function for a tweening with steps. Parameter <a> is number of steps (default: 1). Parameter <p> is initial condition (default: 1)"
		[
		a: max 1 to integer! any [a 1] 
		p: min max 0  to integer! p 1
		t: min max 0 1 / a * (p + to integer! t * a) 1
		]

		frames "Easing equation function for a tweening with specified frames. Parameter <a> is number of frames (default: 2)"
		[
		a: max 2 to integer! any [a 2] 
		t: min max 0 (t: (to integer! t * a) t / (a - 1)) 1
		]

		jitter "Easing function for a random jittering. Parameter <a> is percentage of jittering (default: 5%)"
		[
		a: min max 0 any [a 5] 100
		t: t + ((0 - 1 + random 1000 - (0 - 1)) / 1000 * (1 / 100.0 * a))

		;if 0 = temp: (0 - 1 + random 1000 - (0 - 1)) / 1000 * 0.05 [temp: 0.001]
		;t: t + temp
		;a: random 100; max 0 to integer! a 
		;p: 1 ;min max 0  to integer! p 1
		;t: min max 0 1 / a * (p + round/to t * a 0.01) 1
		;t: min max 0 (t: (to integer! t * a) t / (a )) 1
		;t: min max 0 1 / a * (p + to integer! t * a) 1
		]
		;====ATTENTION: if you add a function here you MUST also add its "set-word" above========
	]
	spec: ["Easing equation function"
		t	"Current time (in frames or seconds)."
		b	"Starting value."
		c	"Change needed in value."
		d	"Expected easing duration (in frames or seconds)."
		a	"First optional parameter for function"
		p	"Second optional parameter for function"
		/local temp
	]
	foreach [name description body] easefunctions [
		spec/1: description
		do compose [(to-set-word name) func copy spec head insert tail insert body [if t >= d [return c + b] t: t / d] [c * t + b]]
		;FIXME: if d = 0 [return b + c]
	]
	{Most of these functions are derived from Robert Penner's Easing Equations:
		Disclaimer for Robert Penner's Easing Equations license:

		TERMS OF USE - EASING EQUATIONS

		Open source under the BSD License.

		Copyright © 2001 Robert Penner
		All rights reserved.

		Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

		    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
		    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
		    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	}
	easefunctions: [ ; functions that we will also reverse
		easeInQuad "Easing equation function for a quadratic (t^^2) easing in: accelerating from zero velocity."
		[
		t: t * t
		]
		;easeOutQuad "Easing equation function for a quadratic (t^^2) easing out: decelerating to zero velocity."
		;[0 - c * ((t: t / d) * (t - 2)) + b]
		;[0 - c * ((t: t / d - 1) * t) + c + b]
		;[c - (c * ((t: 1 - (t / d)) * t)) + b]
		;[easeInQuad d - t b + c 0 - c d a p]
		;easeInOutQuad "Easing equation function for a quadratic (t^^2) easing in/out: acceleration until halfway, then deceleration."
		;[either t < (d * 0.5)[easeInQuad t * 2 b c * 0.5 d a p][easeOutQuad t * 2 - d b + (c * 0.5) c * 0.5 d a p]]
		;easeOutInQuad "Easing equation function for a quadratic (t^^2) easing out/in: deceleration until halfway, then acceleration."
		;[either t < (d * 0.5)[easeOutQuad t * 2 b c * 0.5 d a p][easeInQuad t * 2 - d b + (c * 0.5) c * 0.5 d a p]]
		
		easeInCubic "Easing equation function for a cubic (t^^3) easing in: accelerating from zero velocity."
		[
		t: t * t * t
		]
		easeInQuart "Easing equation function for a quartic (t^^4) easing in: accelerating from zero velocity."
		[
		t: t * t * t * t
		]
		easeInQuint "Easing equation function for a quintic (t^^5) easing in: accelerating from zero velocity."
		[
		t: t * t * t * t * t
		]
		easeInSine "Easing equation function for a sinusoidal (sin(t)) easing in: accelerating from zero velocity."
		[
		t: 1 + sine/radians t + 3 * pi_2
		]
		easeInExpo "Easing equation function for an exponential (2^^t) easing in: accelerating from zero velocity."
		[
		t: power 2 10 * (t - 1)
		]
		easeInCirc "Easing equation function for a circular (sqrt(1-t^^2)) easing in: accelerating from zero velocity."
		[
		t: -1 * (square-root 1 - (t * t)) + 1
		]
		easeInElastic "Easing equation function for an elastic (exponentially decaying sine wave) easing in: accelerating from zero velocity.<a> is amplitude, <p> is period."
		[
		t: t - 1
		a: max 1 any [a 1]
		p: min max 0.1 p 2
		t: -1 * (  a * (2 ** (10 * t)) * sine/radians (( (t * 1 - ( p / (2 * pi) * arcsine/radians (1 / a))) * (2 * pi) / p))  )
		]
		easeInBack "Easing equation function for a back (overshooting cubic easing) easing in: accelerating from zero velocity.Parameter <a> is amplitude"
		[
		a: any [a 1.70158] ; this value gives 10% of overshooting
		t: t * t * ((a + 1) * t - a)
		;t: t - 1 * a + t * t * t
		
		]
		;==== THIS IS NOT a Penner's function
		easeInBounce "Easing equation function for a decaying bounce easing in: accelerating from zero velocity. <a> is number of bounces."
		[
		a: any [a 4]
		p: t - 1 * pi * a
		t: t * abs (sine/radians p) / p
		]
		;==== THIS IS NOT a Penner's function
		easeInBounceInt "Easing equation function for a bounce (integer number of times) easing in: accelerating from zero velocity. <a> is steps number."
		[
		a: round-fast any [a 4]
		p: t - 1 * pi * a
		t: abs (sine/radians p) / p
		]
		; in the functions below x is t (that is t / d )
		; 1 / sech(a) * sech(a / x)
		; 1 / sech(a) * sech(a / x) / x
		; mim max 0 (log-10 x) / 2 + 1 1
		; mim max 0 1 / (1.62 - x) - 0.62 1
		; a * x * x * ((2 + (1 / a)) - (2 * x)) ; similar to "back" but y-mirrored (AKA "smoothstep")
		; t: t - 1 * a + 1 * t; similar to "back" but quadratic (if a = 0 is linear, if a = 1 is quadratic)
		; <a> integer! >= 1 p: pi * t * a t: 1 - (sin(2 * p) - sin(p)) / p  ; Meyer wavelet
		; 1 - (e ** (-3 * x * x) cos (a * 6 * x)) ; Morlet wavelet
		; t: 1 - abs ((e ** (-6 * t)) * cosine/radians (a * 6 * t)) ; modified Morlet wavelet as a very nice bounce effect
		;====ATTENTION: if you add a function here you MUST also add its "set-word" above========
	]
	new-name: "" new-body: []
	foreach [name description body] easefunctions [
		spec/1: description
		do compose [(to-set-word name) func copy spec head insert tail insert body [if t >= d [return c + b] t: t / d] [c * t + b]]

		spec/1: replace copy description "in: accelerating from" "out: decelerating to"
		new-name: replace form name "In" "Out"
		new-body: compose [(name) d - t b + c 0 - c d a p]
		do bind compose [(to-set-word new-name) func copy spec head new-body] self

		spec/1: replace copy description "in: accelerating from zero velocity." "in/out: acceleration until halfway, then deceleration."
		new-body: [either t < (d * 0.5)[_ t * 2 b c * 0.5 d a p][_ t * 2 - d b + (c * 0.5) c * 0.5 d a p]]
		new-body/5/1: to-word name new-body/6/1: to-word new-name
		new-name: replace form name "In" "InOut"
		do bind compose [(to-set-word new-name) func copy spec bind head new-body self] self

		spec/1: replace copy description "in: accelerating from zero velocity." "out/in: deceleration until halfway, then acceleration."
		new-name: replace form name "In" "Out"
		new-body/5/1: to-word new-name new-body/6/1: to-word name
		new-name: replace form name "In" "OutIn"
		do bind compose [(to-set-word new-name) func copy spec bind head new-body self] self
	]

	yforx: context [ ; functions translated from those of Don Lancaster www.tinaja.com (optimized for 0..1 interval)
		x1: 0
		y1: 0
		x2: 1
		y2: 1
		A: B: C: D: E: F: _3A: _2B: 0

		xfort: func [t][
			A * t + B * t + C * t
		]
		yfort: func [t][
			D * t + E * t + F * t 
		]
		slopedtdx: func [t] [
			if 0 = t: (_3A * t + _2B * t + C) [t: 1]
			t
		]
		tforx: func [x p /local tguess tryx][
			x1: min max 0 p/1 1
			y1: p/2 ; min max -2 p/2 2
			x2: min max 0 p/3 1
			y2: p/4 ;min max -2 p/4 2

			A: x1 - x2 * 3 + 1
			B: x2 - x1 - x1 * 3
			C: x1 * 3
			D: y1 - y2 * 3 + 1
			E: y2 - y1 - y1 * 3
			F: y1 * 3
			_3A: 3 * A
			_2B: 2 * B

			tguess: x
			loop 6 [ ; avoid infinite loop
				tryx: xfort tguess
				if tryx = x [break]
				;if 0.005 > abs tryx - x [break]
				tguess: min max 0 tguess - ((tryx - x) / slopedtdx tguess) 1
			]
			tguess
		] 
	]

	;transitions-pause: does [paused?: true]
	;transitions-unpause: transitions-play: does [paused?: false]
	;transitions-stop: transitions-clear-all: does [clear properties]
	stop_atransition: func ["Stop a transition (only async for now)"
		face [object!] "The face which has the transition to be stopped"
		facet [word! path!] "The facet that is transitioning"
		/async tick-face [object!] "The <ticker> face which whose timer is used to give the pace"
		/local props
		][
		either none? async [
			; TBD
		][
			if props: find tick-face/anim-specs face [remove-each item second props [item/1 = facet]]
		]
	]
	atransit: func ["Animate smoothly from one facet value to a new one over time."
		face [object!] "The face to which apply transition"
		'facet [word! path!] "The facet that will change"
		value [number! pair! tuple!] "New value"
		duration [number! time!] "Duration in seconds"
		easefunc [word!] "Function used to tween"
		/delay timed [number! time!] "Optional initial delay (default is 0)"
		/params a [number! block! none!] p [number!] "Parameters for functions that need them"
		/async tick-face [object!] "Make this transition asyncronous using tick-face 's timer"
		/local props
		][
		timed: any [timed 0]
		a: any [a 1] p: any [p 1]
		props: head insert/only copy [] reduce [facet value duration easefunc timed a p]
		do pick [transitions transitions/async] none? async reduce [face compose [(props)] ] tick-face
	]
	atransitions: func ["Animate smoothly from one or more facet(s) value(s) to new one(s) over time."
		specs [block!] "list of lists with faces, facets and values in the format [face [facet [word! path!] new-value [number! pair! tuple!] duration [number! time!] ease-function [word! block!] delay [number! time!] param1 [number! block!] param2 [number!] ...] ...]"
		/async tick-face [object!] "Make this transition asyncronous using tick-face 's timer"
		/local prop properties begin ease-function
		][
		if 0 = length? specs [exit]
		if none? async [
			if sync-play [exit] ; avoid sync transitions interruption
		]
		specs: reduce compose/deep specs
		forskip specs 2 [
			aface: first specs
			properties: second specs
			if not object? aface [to-error "transitions MUST be applied to a face!"]
			if not block? properties [to-error "transition properties MUST be block!"]
			foreach prop properties [
				if not block? prop [to-error "transition properties MUST be block!"]
				insert tail prop switch/default length? prop [
					0 1 [to-error "transition properties MUST have at least 2 elements"]
					2 3 4 5 6 7 [skip compose [_ _ (default-duration) (default-ease) (default-delay) (none) 1] length? prop]
				] [to-error "transition properties MUST have at max 7 elements"]
				if not any [word? prop/1 path? prop/1] [to-error "transition MUST be applied to a facet given as a word! or path!"]
				if not any [number? prop/2 pair? prop/2 tuple? prop/2] [to-error join "transition changing value MUST be number!, pair! or tuple! not: " mold type? prop/2]
				if not any [number? prop/3 time? prop/3] [to-error "transition duration MUST be number! or time!"]
				if not any [word? prop/4 function? get prop/4] [to-error "transition ease function MUST be word! or function!"] ;FIXME: or get-word!
				if not any [number? prop/5 time? prop/5] [to-error "transition delay MUST be number! or time!"]
				;...
				if all [prop/4 = 'bezier not any [none? prop/6 block? prop/6]] [to-error "bezier transition parameter MUST be a block!"]

				prop/3: max 0 to-decimal prop/3 ; duration ; FIXME: beware division by 0
				prop/5: max 0 to-decimal prop/5 ; delay
				either word? prop/4 [
					ease-function: switch/default prop/4 [
						ease ease-in ease-out ease-in-out [:bezier]
						custom-ease [:custom-ease]
					] [get in self to-get-word prop/4]
					if none? :ease-function [to-error rejoin ["function " prop/4 " does not exist"]]
					if :ease-function = :bezier [
						prop/6: switch/default prop/4 [
							ease [[.25 .1 .25 1]]
							ease-in [[.42 0 1 1]]
							ease-out [[0 0 .58 1]]
							ease-in-out [[.42 0 .58 1]]
							; quadIn: [0.21,0,0.56,0.126]
							; cubIn: [0.335,0,0.666,0.3]
							; quartIn: [0.5,0,0.73,-0.022]
							; quintIn: [0.59,-0.007,0.777,-0.038]
							; sinIn: [0.23,0,0.5,0.17]
							; circIn: [0.552,0,1,0.448]
						][prop/6]
					]
					prop/4: :ease-function
				][
					prop/4: get prop/4
				]
				;probe 
				;begin: do bind load rejoin ["do aface/" prop/1] tweener-ctx
				begin: do append to-path 'aface prop/1
				prop/1: to-path prop/1

				insert tail prop begin ; FIXME: or add it as an other (optional?) parameter
				insert tail prop to decimal! now/time/precise ; start
				insert tail prop 0.0 ; time
			]
		]

		either async [
			insert tail tick-face/anim-specs specs
			tick-face/rate: default-rate ; start ALL (not already started) async transitions
			show tick-face
		][
			;======== MAIN LOOP ==========
			sync-play: on
			while [not empty? specs][;time <= max-duration] [
				forskip specs 2 [
					aface: first specs

					transition-step aface second specs

					if empty? head second specs [remove/part find specs aface 2]
					wait 0 ; let process user input events (R3, World, Topaz and Red probably need a different value)
				]
			]
			sync-play: off
		]
		specs
	]

	transition-step: func [tface [object!] properties [block!] /local prop i n start time][
		if paused? [; FIXME: TBD
			wait 0
			;start: to decimal! now/time/precise
			;time: time + start
			exit
		]
		forall properties [
			prop: first properties
			start: prop/9
			time: prop/10

			; if delay is passed and total duration is not passed then do next step of transition(s)

			; if delay is passed go on
			if time > prop/5 [
					 
				;do command
				either any [pair? prop/8 tuple? prop/8] [
					n: switch type?/word prop/8 [pair! [2] tuple! [length? prop/8]]
					repeat i n [
						set-facet tface rejoin [prop/1 i] prop/4 (time - prop/5) prop/8/:i prop/2/:i - prop/8/:i prop/3 prop/6 prop/7
					]
				][
						set-facet tface prop/1 prop/4 (time - prop/5) prop/8 prop/2 - prop/8 prop/3 prop/6 prop/7
				]

			]
			prop/10: (to decimal! now/time/precise) - start ; time
			; if total duration is passed stop current transition (Note: do check at end to avoid early interruption)
			if time >= (prop/3 + prop/5) [ ; FIXME: use this? if prop/2 = prop/8  NO, does not work correctly
				remove properties ; FIXME: and append to completed?
			]
		]
		;wait 0 ; let process user input events
		show tface ; if red : unless sync? [show face]

	]
	
	; make main functions global
	set [transit transitions stop_transition] reduce [:atransit :atransitions :stop_atransition]

] ; context

] ; value?


;==== example ====


do ; just comment this line to avoid executing examples
[
	if system/script/title = "Tweener" [;do examples only if script started by us
	context [ ; avoid inserting names in global context

	; custom-ease
		e: 2.718281828459045
		sech: func [x [number!]] [x: min max 0.0001 x 10 2 / ( (e ** x) + (e ** - x) )]
		set 'custom-ease func ["Easing equation function"
			t	"Current time (in frames or seconds)."
			b	"Starting value."
			c	"Change needed in value."
			d	"Expected easing duration (in frames or seconds)."
			a	"First optional parameter for function"
			p	"Second optional parameter for function"
			][
			if t >= d [return c + b]
			t: t / d
			t: (sech a / 2 / t) / (sech a / 2) / t
			c * t + b
		]
	;
	stylize/master [
		;====
		;==== ticker ====
		;====
		anim-ticker: sensor 0x0 rate none
			feel [
				engage: func [face action event /local anim-specs][
					;======== MAIN LOOP ==========
					if action = 'time [
						anim-specs: face/anim-specs
						forskip anim-specs 2 [

							tweener-ctx/transition-step first anim-specs second anim-specs

							if empty? second anim-specs [remove/part anim-specs 2]
						]

						if empty? anim-specs [
							face/rate: none show face ; stop ALL async animations
						]
					]
				]
			] with [
				anim-specs: copy [] ; set this to the block of specs for the various animations
			]
	]

	win-dim: 630x600
	woff: 20x20
	wspace: 10x10
	wwidth: win-dim/x wheight: win-dim/y
	pwidth: wwidth - (woff/x * 2)
	center-x: func [faces [object! block!] face2][
		faces: reduce compose [(faces)]
		foreach face faces [
			face/offset/x: max 0 face2/size/x - face/size/x / 2 + face2/offset/x
		]
	]
	set-time: func [face][
		set-face face copy/part to-itime now/time 5
	]

	direction: 1
	a: p: 1
	lay: [
		backdrop sky - 30.30.0
		ticker: anim-ticker
		pad 0x-10 ; erase space created by ticker

		origin 0x0
		across
		page-1: panel (wwidth) [
			box-rotate: box (1x0 * wwidth + 0x400) effect compose/deep [draw [
				;pen white
				fill-pen yellow
				translate (1x0 * wwidth / 2 + 0x210)
				rotate 0 ; used to tween only from 0 to 6 to avoid glich of tweening from 354 to 0
				rotate -90 ; start at 12 o'clock
				box 70x-6 180x6 3
				]]
				rate 1 feel [
					engage: func [face action event][
						if action = 'time [
							if 0 = third now/time [set-time text-clock] ; a minute is passed, update shown time
							face/effect/draw/rotate: 0
							face/effect/draw/8: 6 * third now/time - 15
							; this is async because otherwise we will have to wait for it to finish before being able to do the next transition (that is changing to next page)
							transit/params/async face effect/draw/rotate 6 .5 'easeOutBounceInt 3 1 ticker
						]
					]
				]
			pad 0x-228
			text-clock: text "00:00" sky - 30.30.0 font [size: 50]
			pad (0x1 * wheight - 0x200)
			h1-title: h1 "Here is a REBOL script" white
			h1-title-2: h1 "to make nice transitions" white
			btn-see: btn "Let's see!" (pwidth) [
				transitions [
					page-1 [[offset/x (page-1/size/x * -1 - 2) .5 easeOutInExpo]]
					page-2 [[offset/x 0 .5 easeOutInExpo]]
				]
				box-rotate/rate: none show box-rotate ; stop clock
			]
		]
		page-2: panel (wwidth) [
			do [sp: 4x4] origin 10x10 space sp 
			Across 
			btn-go: btn "Go!" 40x40 green [
					a: load get-face field-a2
					if any [not number? a a < -2 a > 2] [set-face field-a2 a: 0.0]
					a: load get-face field-a3
					if any [not number? a a < 0 a > 1] [set-face field-a3 a: 1.0]
					a: load get-face field-a4
					if any [not number? a a < -2 a > 2] [set-face field-a4 a: 1.0]
					a: load get-face field-a1
					if not any [number? a none? a] [set-face field-a1 a: 1]
					p: load get-face field-p
					if not number? p [set-face field-p p: 1]
					if h1-func/text = "frames" [set-face field-a1 max 2 load get-face field-a1]
					if h1-func/text = "bezier" [a: reduce [load get-face field-a1 load get-face field-a2 load get-face field-a3 load get-face field-a4]]

					transit/params
						box-sample
						offset/x
						(box-sample/offset/x + (200 * direction))
						get-face text-secs
						to-word get-face h1-func
						a
						p

					direction: negate direction
				]
			pad 0x5 
			h1-func: h1 "linear" 200
			return 
			h3-descr: h3 600x40 "Easing equation function for a simple linear tweening, with no easing."
			return 
			text "Duration:" 
			slider-secs: slider 100x16 0.5 white [
					secs: get-face face
					either secs < 0.5 [secs: max 0.1 round/to secs * 2 0.05][secs: max 1 round/to secs - 0.5 * 20 0.5]
					set-face text-secs secs
				]
			text-secs: text bold "1.0" 30 text "second(s)" 
			;pad 0x-4 
			return 
			pad 0x10 
			box-sample: box 20x20 blue 
			pad 0x10 
			return 
			style field field 40 white
			text "<a> parameter:" 100 field-a1: field "none" field-a2: field "0.0" field-a3: field "1.0" field-a4: field "1.0"
			return 
			text "<p> parameter:" 100 field-p: field "1"  
			return 
			guide 
			style box box "easeInOutBounceInt" 150x20 font [size: 12]
				effect [draw [pen none fill-pen 0.0.128 box 0x0 150x20 10]] 
				feel [
					over-super: :over
					over: func [face over? offset][
						over-super face over? offset ; pass up to super-class (not necessary in this case)
						either over? [
							; stop previous transition
							stop_transition/async face 'effect/draw/fill-pen ticker
							; rapidly change to new color
							;face/effect/draw/fill-pen: blue + 0.100.0
							;show face
							transit face effect/draw/fill-pen blue + 0.100.0 0.01 'linear
						][
							; slowly change to old color
							transit/async face effect/draw/fill-pen navy .5 'linear ticker
						]
					]
				]
				[
					set-face h1-func face/text
					set-face h3-descr first third get in tweener-ctx to-word face/text
				]
			box "custom-ease" [set-face h1-func face/text]

		]
		box-black: box (win-dim) black
		box-white: box (win-dim) effect compose/deep [draw [
				pen (none)
				fill-pen 255.255.255.255
				box 0x0 (win-dim) 20
			]]
		
		do [
			center-x [box-rotate h1-title h1-title-2 text-clock btn-see] page-1
			set-time text-clock
			set-face text-secs 1.0
		]
	]
	; add ease functions buttons
		page-2-buttons: copy []
		n: 1
		foreach item next first tweener-ctx [
			if function? elem: get in tweener-ctx item [
				if all [string? title: first third :elem find/match title "Easing"][; none? find form item "ease"] [
					append page-2-buttons reduce ['box form item]
					if 0 = modulo n 4 [append page-2-buttons 'return]
					n: n + 1
				]
			]
		]
		insert skip tail first find find/last lay 'panel block! -3 page-2-buttons
	;
	view/new main-window: center-face layout/size lay win-dim

		insert-event-func func [face event] [
			if event/face = main-window [
				switch event/type [
					close [
						;ask_close
						transit box-white offset 0x0 0.01 'linear
						transit box-white effect/draw/4 255.255.255.0 0.4 'linear
						transit box-black offset 0x0 0.01 'linear
						transitions [
							box-white [
								[effect/draw/6 (wheight / 2 - 10 * 0x1) 0.3 easeOutCubic]
								[effect/draw/7 (wheight / 2 + 10 * 0x1 + (1x0 * wwidth)) 0.3 easeOutCubic]
							]
						]
						transitions [
							box-white [
								[effect/draw/6 (win-dim / 2 - 15x10) 0.3 easeOutCubic]
								[effect/draw/7 (win-dim / 2 + 15x10) 0.3 easeOutCubic]
							]
						]
						transit box-white effect/draw/4 255.255.255.255 0.5 'linear

						return event

						;if all [value? 'help-win event/face = help-win] [unset 'help-win]
						;event
					]
				]
			]
			event
		]

	;
	;comment
	transitions
	[
		text-clock [[font/color (white) 1 linear .2]]
		h1-title [[offset/y (h1-title/offset/y - 240) .3 easeOutBack 2]]
		h1-title-2 [[offset/y (h1-title-2/offset/y - 240) .3 easeOutBack 2.2]]
		btn-see [[offset/y (btn-see/offset/y - 240) .5 easeOutElastic 2.3 1.3 .5]]
	]

	do-events

	] ; context
	] ; if title
]
