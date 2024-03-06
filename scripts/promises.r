REBOL [
	title: "JS Promises"
	Purpose: "A Rebol-style implementation of JS Promises"
	file: %promises.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 02-04-2020
	version: 0.9.1
	History: [
		0.0.1 [09-02-2020 "Started"]
		0.9.1 [02-04-2020 "Completed. More advanced then original ;) "]
	]
	Category: [tools]
	library: [
		level: 'advanced
		platform: 'win
		type: [tool dialect]
		domain: [dialects]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: {
			Copyright (c) 2020, Marco Antoniazzi

			Redistribution and use in source and binary forms, with or without
			modification, are permitted provided that the following conditions are met:

			1. Redistributions of source code must retain the above copyright notice, this
			   list of conditions and the following disclaimer.
			2. Redistributions in binary form must reproduce the above copyright notice,
			   this list of conditions and the following disclaimer in the documentation
			   and/or other materials provided with the distribution.

			THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
			ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
			WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
			DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
			ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
			(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
			LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
			ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
			(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
			SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
		}
		see-also: none
	]
	Help: {
		Implemented promise's "public" methods (object's functions): then, catch, done, finally
		Implemented promise's "shortcuts": resolve, reject , race , all , all-settled; and also: any , then-all
		
		The function 'async takes a block that is a dialect and returns a promise.
		The dialect syntax is:
		<one of: await , after-all , after-all-settled , race , after-any , then-forall>
		followed by 0 or more of <then> or <catch>
		and end with <done> and/or <finally>
		strings between items are ignored

		<await> is followed by a block of code that must return a promise or can be empty and an empty promise will be created.
		<after-all , after-all-settled , race , after-any , then-forall> are followed by a block or a word identifing a block.
		<then-forall> is also followed by 2 blocks of code: one to execute for those promises that fulfill and one for those that reject.
		<then> is followed by a block of code to execute if "preceding" promise fulfills.
		<catch> is followed by a block of code to execute if "preceding" promise rejects.
		<done> is followed by 2 blocks of code: one to execute for those promises that fulfill and one for those that reject.
		<finally> is followed by a block of code to execute always.
		
		To have local variables inside blocks of code precede them with <use> or <has> followed by a block of words.
		
		Examples:
		async [
			await [a-promise]
			then [...]
			catch [...]
			done [...] [...]
		]

		async [
			race a-block-of-promises
			then [...]
			then use [var1 var2 ...] [...]
			catch [...]
			finally [...]
		]

		async [
			then-forall a-block-of-promises [...] [...]
			then [...]
		]
	}
	Notes: {
		"The Promise object represents the eventual completion (or failure) of an asynchronous operation, and its resulting value."

		An asynchronous operation is an operation that:
		 - is done in a non-GUI-blocking way
		 - is done in the background
		 - you do not know when it will end
		 - when it ends it MUST call a callback function
		  or
		 - when it fails to complete it MUST call a callback function
		 
		Unfortunately AFAIK in R2 there aren't asynchronous funtions ! So this script is propably useless but who cares !
		 
		Asynchronous operations are done using timers, AFAIK Rebol2 timers exist only for GUI faces. When at least one
		face has a "running" timer, Rebol creates a global "pace-maker" timer that ticks many times a second.
		This also implies that, since callbacks are called using timers, you should _ALWAYS_ give them some time to complete.
		For this reason in the examples below I do a lot of "wait-for-pending-timeouts" but, obviously, in a "real" program
		you should do something more useful than simply waiting ... ;)
		
		You can have many "then-catch" handlers for the same promise and each one will return a different promise
		or you can "chain" an handler to a previously returned promise so that it will get its value.
		And remember to ALWAYS return something.
		
		"then" and "catch" functions book an action that is/can-be executed after a while.
		And remember to ALWAYS return something.
		
		Since for almost all situations error!s are silenced , remember to NEVER return unset! (e.g. print ...) from your callbacks,
		or, which is the same, to ALWAYS return something.
		To avoid silencing error!s altogether use: disarm: func [a][:a]
		That is: if a promise is rejected and you don't know why try: disarm: func [a][:a]
		In fact: if you make an error inside a catch it will be difficult to discover it and in that case try: disarm: func [a][:a]
		And also remember to ALWAYS return something.
		
		A "catched" rejected promise will return a _FULFILLED_  promise with the rejection reason.
		
		The method "finally" ALWAYS _FULFILLS_. In case of a previous rejected promise it will _FULFILL_ with the rejection reason;
		so it is better to place it at the end as its name suggests.

		The method "done" is similar to "finally" but it will not silence error!s, so it is useful to throw uncaught error!s.
		
		I don't really know how to properly handle unset!s and error!s. Any idea ?
		
		Since promises take callback functions as arguments, You will often have to "compose" them dynamically to avoid re-using
		the previously used static block.
		
		In this script there are: low-level functions, mid-level functions and high-level dialect
		
		Since promises are not easy there are a lot of tests.
		
		BUG: sometimes "wait-for-pending-timeouts" seems not to wait enough and an error of "p12 has no value" appears during tests :(
		or is it that it is not enough to know that all callbacks are called since there still could be one not completed ?

		And remember to ALWAYS return something.

		This script is mostly a translation from
			https://exploringjs.com/es6/ch_promises.html#ch_promises
			https://github.com/rauschma/demo_promise
			https://stackoverflow.com/a/49125327
			https://developers.google.com/web/fundamentals/primers/promises
	}
]
;
; set-timeout , stop-timeouts
	context [
		; not precise, not complete but tested and it works

		system/error: make system/error [
			set-timeout: make object! [
				code: 1000
				type: "set-timeout Error"
				loop: [{Probable infinite loop or "then or done"-function returned unset! instead of a value}]
			]
		]

		; to use timers we must have a window
		win-face: layout [size 0x0] ; hidden 0-sized window
		old-face: none

		timings: copy []
		first-time: 0 
		level: 0
		set 'set-timeout func [
			"Calls a function with an argument after a specified period of time"
			time [number! time!]
			callback [any-function!]
			arg
			/local
			now-time
			][
			level: level + 1
			; FIXME: adjust times better to be more precise
			now-time: now/time/precise
			if not find system/view/screen-face/pane win-face [view/new win-face]
			insert/only insert insert tail timings
				now-time + to time! time
				:callback
				:arg
			; FIXME: possible optimization: either time = previous-time-inserted [insert after previous-time-inserted][previous-time-inserted: append-sorted]
			sort/skip head timings 3
			time: first timings
			if time < first-time [
				first-time: time
				win-face/rate: time - now-time
				show win-face
			]
			; FIXME: return the id of newly inserted timeout to be able to remove it with "clear-timeout"
		]
		set 'stop-timeouts does [
			clear timings
			first-time: now/time/precise + to time! 1000000; choose a big value
			win-face/rate: none
			show win-face
			if win-face = old-face [unview/only win-face]
		]
		set 'pending-timeouts? does [
			not empty? timings
		]
		set 'wait-for-pending-timeouts does [
			while [pending-timeouts?][wait 0.02]
			wait 0.02
			stop-timeouts
		]

		set 'set-timeouts-win-face func [face [object!]] [
			old-face: win-face
			stop-timeouts
			win-face: face
			win-face/feel: make win-face/feel [engage: func [face action event][if action = 'time [face/action face face/data]]] ; FIXME: avoid overwriting feel/engage ?
			win-face/action: func [face value /local time callback arg][
				level: level - 1
				if level < 0 [
					to-error [set-timeout loop]
					exit ; FIXME: unreached ?
				]
				set [time callback arg] timings
				remove/part timings 3
				if empty? timings [first-time: now/time/precise + to time! 1000000]
				; FIXME: if (or while) ((first timings) - time) = 0 [call another callback]
				win-face/rate: attempt [max 0:0:0 (first timings) - now/time/precise] ; will also stop timer after last timeout
				show win-face
				callback :arg
			]
			old-face
		]

		set-timeouts-win-face win-face

	]
	;do
	[
		prin "start setting " print now/time/precise
		set-timeout 1.5 func [arg] [prin now/time/precise print " act2"] none
		set-timeout 0.5 func [arg] [prin now/time/precise print " act1"] none
		set-timeout 3.0 func [arg] [prin now/time/precise print " act3"] none
		prin "end setting " print now/time/precise
	]
;

; error funcs
	to-error: func [[catch] ; gives a better error message
		value
		][
		throw 
		to error! :value
	]
	disarmed-error?: func [
		"Returns true if given object is a disarmed error"
		error [object!]
		][
		[self code type id arg1 arg2 arg3 near where] = first error
	]
	form-error: func [[catch]
		"Forms a disarmed error"
		err [object!]
		/local
		arg1 arg2 arg3 message
		][;derived from 11-Feb-2007 Guest2
		either disarmed-error? err [
			arg1: any [attempt [get in err 'arg1] 'unset]
			arg2: any [attempt [get in err 'arg2] 'unset]
			arg3: any [attempt [get in err 'arg3] 'unset]
			message: get err/id
			if block? message [bind message 'arg1]
			message: rejoin ["** " get in get in system/error err/type 'type ": " form reduce message newline
			                 "** Near: " either block? err/near [mold/only err/near][err/near] newline]
		][
			throw make error! [script expect-arg form-error err "disarmed error"]
		]
	]
	form-on-error: func [
		"Evaluates a block, which if it results in an error, forms that error."
		blk [block!]
		][
		if error? set/any 'blk try blk [form-error disarm blk] 
	]
	rearm: func [
		"Re-fires a disarmed error!"
		error [object!]
		][
		either disarmed-error? error [
			make error! reduce [error/type error/id get in error 'arg1 get in error 'arg2 get in error 'arg3 error/near get in error 'where]
		][
			error ; pass thru
		]
	]
	try-catch: func [
		try-body [block!] word [word!] catch-body [block!]
		][
		if error? set/any word try try-body catch-body
	]
	;disarm: func [a][:a] ; let errors appear !       ; FIXME: should this be activated with a flag ?
; debug
	probedo: func [code [block!] /local result][print [result: do code mold code] :result]
	do-many: func ["Do a block over each value of another block" ; apply
		executor [block!] ; FIXME: add any-function!
		block [block!]
		] [
		foreach item block head insert insert tail clear [] executor 'item
	]
;
system/error: make system/error [
	promise: make object! [
		code: 1000
		type: "promise Error"
		then: {"then"-function returned unset! instead of a value}
	]
]


make-promise: func [
	resolver [function!]
	/local
	promise err
	addToTaskQueue
	][
	addToTaskQueue: func [task [function!]][set-timeout 0 :task none]

	promise: make object! [
		type: 'promise
		state: 'pending
		value: none
		alreadyResolved: false
		fulfillReactions: copy []
		rejectReactions: copy []

		then: func [
			onFulfilled [function! block! none!]
			onRejected [function! block! none!] ; FIXME: transform to a refinement! ?
			/local
			returned-promise
			fulfilledTask
			rejectedTask
			][
			returned-promise: make-promise does []
			
			if block? :onFulfilled [onFulfilled: func [value] onFulfilled ]

			either function? :onFulfilled [
				fulfilledTask: func [/local res err] compose/deep [ ; <<<== to make onFulfilled function dynamically to avoid static version
					if error? set/any 'err try [
						set/any 'res (:onFulfilled) :value  ; <<<== dynamic onFulfilled
						if unset? get/any 'res [to-error ""] ; force an error
						do in (returned-promise) 'fulfill res
					][
						if unset? get/any 'res [wait-for-pending-timeouts to-error [promise then]]
						do in (returned-promise) 'reject disarm err
					]
				]
			][
				fulfilledTask: func [] compose [ ; <<<== to make onFulfilled function dynamically to avoid static version
					do in (returned-promise) 'fulfill :value
				]
			]

			if block? :onRejected [onRejected: func [value] onRejected]

			either function? :onRejected [
				rejectedTask: func [/local res err] compose/deep [ ; <<<== to make onRejected function dynamically to avoid static version
					if error? set/any 'err try [
						set/any 'res (:onRejected) :value  ; <<<== dynamic onRejected
						if unset? get/any 'res [to-error ""] ; force an error
						do in (returned-promise) 'fulfill res
					][
						if unset? get/any 'res [wait-for-pending-timeouts to-error [promise then]]
						do in (returned-promise) 'reject disarm err
					]
				]
			][
				rejectedTask: func [] compose [ ; <<<== to make onFulfilled function dynamically to avoid static version
					;// `onRejected` has not been provided
					;// => we must pass on the rejection
					do in (returned-promise) 'reject :value
				]
			]

			switch state [
				pending [
					append fulfillReactions :fulfilledTask
					append rejectReactions :rejectedTask
				]
				fulfilled [
					addToTaskQueue :fulfilledTask
				]
				rejected [
					addToTaskQueue :rejectedTask
				]
			]

			returned-promise
		]
		catch: func [
			onRejected [function! block! none!]
			][
			then none :onRejected
		]
		fulfill: func [result][
			if not alreadyResolved [
				alreadyResolved: true
				_doResolve result
			]
			self
		]
		_doResolve: func [result /local this fulfilledTask][
				either is-promise? result [
					;// Forward fulfillments and rejections from `result` to `this`.
					this: self
					fulfilledTask: func [] compose/deep [ ; <<<== to avoid static version
						do in (result) 'then
							func [result] [
								do in (this) '_doResolve result
							]
							func [reason] [
								do in (this) '_doReject reason
							]
					]
					addToTaskQueue :fulfilledTask
				][
					if state = 'pending [
						state: 'fulfilled
						value: result
						; call then(s)
						while [not empty? fulfillReactions] [
							addToTaskQueue first fulfillReactions
							remove fulfillReactions
						]
					]
				]
		]
		reject: func [reason][
			if not alreadyResolved [
				alreadyResolved: true
				_doReject reason
			]
			self
		]
		_doReject: func [reason][
				if state = 'pending [
					state: 'rejected
					value: reason
					; call catch(s)
					while [not empty? rejectReactions] [
						addToTaskQueue first rejectReactions
						remove rejectReactions
					]
				]
		]
		done: func [onFulfilled [function! block! none!] onRejected [function! block! none!]] [
			do in then :onFulfilled :onRejected
				'catch 
					func [reason][
						set-timeout 0 does [rearm reason] none
						none ; must return something
					]
		]
		finally: func [callback [function! block!]] [
			if block? :callback [callback: does callback ]
			;// We don’t invoke the callback in here,
			;// because we want then() to handle its exceptions
			then
				;// Callback fulfills: pass on predecessor settlement
				;// Callback rejects: pass on rejection (=omit 2nd arg.)
				func [result] [do in make-promise-resolve callback 'then [result] none]
				func [reason] [do in make-promise-resolve callback 'then [reason] none]
		]

	]

	;if 2 <> length? first :resolver [to-error "Promise's resolver must accept 2 parameters"] ; NOT necessary !
	if error? set/any 'err try [
		resolver get in promise 'fulfill get in promise 'reject
	][
		promise/reject disarm err
	]
	
	promise
]

make-promise-resolve: func [result][ ; [any-type! unset!]] [
	;make-promise func [resolve reject][if not unset? get/any 'result [resolve result]]
	make-promise func [resolve reject][resolve result]
]
make-promise-reject: func [reason] [
	make-promise func [resolve reject][reject reason]
]
make-promise-race: func [
	block [block!]
	][
	if empty? block [return make-promise-resolve copy [] ]
	make-promise func [resolve reject] [
		foreach item block [
			do in make-promise-resolve item
			'then
				func [value][resolve value]
				func [value][reject value] ; FIXME: if rejection break the loop ?
		]
	]
]
make-promise-all: func [
	block [block!]
	/local
	len i counter result
	][
	if empty? block [return make-promise-resolve copy [] ]
	result: copy block
	len: length? block
	i: 1
	counter: 0
	make-promise func [resolve reject] [
		foreach item block [
			do in make-promise-resolve item
			'then
				func [value] compose [
					change at result (i) value ; <<<--- i must be placed dynamically
					counter: counter + 1
					if counter = len [resolve result]
				]
				func [value][reject value]
			i: i + 1
		]
	]
]
make-promise-all-settled: func [
	block [block!]
	/local
	len i counter result
	] [
	if empty? block [return make-promise-resolve copy [] ]
	result: copy block
	len: length? block
	i: 1
	counter: 0
	make-promise func [resolve reject] [
		foreach item block [
			do in make-promise-resolve item
			'then
				func [value] compose [
					change at result (i) value ; <<<--- i must be placed dynamically
					counter: counter + 1
					if counter = len [resolve result]
				]
				func [value] compose [
					change at result (i) value ; <<<--- i must be placed dynamically
					counter: counter + 1
					if counter = len [resolve result] ; _ALWAYS_ resolve
				]
			i: i + 1
		]
	]
]
make-promise-any: func [
	block [block!]
	/local
	len i counter result
	] [
	if empty? block [return make-promise-resolve copy [] ]
	result: copy block
	len: length? block
	i: 1
	counter: 0
	make-promise func [resolve reject] [
		foreach item block [
			do in make-promise-resolve item
			'then
				func [value][resolve value]
				func [value] compose [
					change at result (i) value ; <<<--- i must be placed dynamically
					counter: counter + 1
					if counter = len [reject result]
				]
			i: i + 1
		]
	]
]
make-promise-then-all: func [
	"For each value in a block calls fulfillment or rejection handler on it in sequence. Returns a fulfilled promise."
	block [block!]
	onFulfilled [function! block! none!]
	onRejected [function! block! none!]
	/local
	p0 result
	] [
	if empty? block [return make-promise-resolve copy [] ]
	result: copy []

	if none?  :onFulfilled [onFulfilled: [:value] ] ; FIXME: wrong ? should we pass it on ? better no !
	if block? :onFulfilled [onFulfilled: func [value] onFulfilled ]
	if none?  :onRejected [onRejected: [:value] ]   ; FIXME: wrong ? should we pass it on ? better no !
	if block? :onRejected [onRejected: func [value] onRejected]
	p0: make-promise-resolve []
	do in
	forall block [
		p0: do in
		p0/then
			compose [make-promise-resolve (block/1)] ; transform to promise
			none
		'then
			[append result onFulfilled value]
			[append result onRejected value]
	]
	'then [result] none
]
;
[;make-promise-race , -all , -all-settled , any
	; much more compact but much more "obscure"
	body: body-of :make-promise-all-settled
	body/18/4/13: [reject value]
	make-promise-all: func spec-of :make-promise-all-settled body

	body: body-of :make-promise-all-settled
	body/18/4/9: [resolve value]
	body/18/4/13/14: [reject result]
	make-promise-any: func spec-of :make-promise-all-settled body

	body: body-of :make-promise-all
	body/18/4/9: [resolve value]
	make-promise-race: func spec-of :make-promise-all body
]

wait-for-pending-promise: func [
	promise [object!]
	][
	if is-promise? promise [
		while [promise/state = 'pending][wait 0.2]
	]
]
is-promise?: func [obj][
	all [
		object? obj
		'promise = attempt [obj/type]
		function? attempt [get in obj 'then]
	]
]
dump-promise: func [name [word! object!] /local promise] [
	either word? name [promise: get name][promise: name name: 'promise]
	print [join name "/state:" promise/state newline join name "/value:" mold promise/value]
	promise
]
bare-promise: func [
	promise [object!]
	/local value
	][
	either is-promise? promise [
		value: get in promise 'value
		reduce [get in promise 'state either all [object? value disarmed-error? value] ['!ERROR!][value]]
		][
		copy []
	]
]

; promise dialect
system/error: make system/error [
	async: make object! [
		code: 1000
		type: "async rule Error"
		syntax: ["in async block Near: " :arg1]
		block: ["not a block: " :arg1]
	]
]
async: func [
	[catch]
	body [block!]
	/local
	rule-use
	rule-block-none
	rule-block-word
	rule
	code code1 code2 block
	use-block
	pos

	prom
	][
	; FIXME: place <any string!> in more places
	rule-use: [(use-block: []) opt [['use | 'has] set use-block block!] set code block! (if empty? code [code: [make-promise-resolve []]] code: reduce ['use use-block code] ) ]
	rule-block-none: [[set code [block! | none!]] | 'none (code: none) ]
	rule-block-word: [set block block! | set block word! (
		if not block? get/any block [
			disarm: func [a][:a] ; let errors appear !
			throw make error! reduce ['async 'block block]
		]
		block: get block
		)
	]
	rule: [
		[
		  'await rule-use (set/any 'prom do code)
		| 'after-all rule-block-word (set/any 'prom make-promise-all block)
		| 'after-all-settled rule-block-word (set/any 'prom make-promise-all-settled block)
		| 'race rule-block-word (set/any 'prom make-promise-race block)
		| 'after-any rule-block-word (set/any 'prom make-promise-any block)
		| 'then-forall rule-block-word rule-use (code1: code) rule-use (code2: code) (set/any 'prom make-promise-then-all block code1 code2)
		| pos: (if not tail? pos [
					disarm: func [a][:a] ; let errors appear !
					throw make error! reduce ['async 'syntax mold pos]
				]) thru end
		]
		any [
			  ['then rule-use (set/any 'prom do in prom 'then code none) ]
			| ['catch rule-use (set/any 'prom do in prom 'then none code) ]
			| string! ; comments
		]
		opt [
				[
					['done rule-block-none (code1: code) rule-block-none (code2: code) (set/any 'prom do in prom 'done code1 code2) ]
					any string! ; comments
					opt ['finally rule-use (set/any 'prom do in prom 'finally code) ]
				]
			|	[
					['finally rule-use (set/any 'prom do in prom 'finally code) ]
					any string! ; comments
					opt ['done rule-block-none (code1: code) rule-block-none (code2: code) (set/any 'prom do in prom 'done code1 code2) ]
			]

		]
		any string! ; comments
		pos: (if not tail? pos [
					disarm: func [a][:a] ; let errors appear !
					throw make error! reduce ['async 'syntax mold pos]
				]) thru end
	]
	parse body rule
	prom
]
{************************************************************
** tests and examples
************************************************************}
do ; just comment this line to avoid executing example
[
	if system/script/title = "JS Promises" [;do examples only if script started by us

	;
	; set tests
		; assign values to names
		set [
			immediate-simple
			non-immediate-simple
			immediate-multi
			non-immediate-multi
			promise-dialect
			] false
		; choose which one to test
		set [
			;immediate-simple
			;non-immediate-simple
			;immediate-multi
			;non-immediate-multi
			promise-dialect
			] true
	;

	; fake-download
		fake-download: func [
			file [word! string!]
			ok-cbk [function!]
			ok-arg
			fail-cbk [function!]
			fail-arg
			/state st [integer!] "0=ok , 1=ko or 2=random"
			/delay secs
			][
			secs: any [secs 0.5]
			st: min max 0 any [st 0] 2
			if 3 = st: 1 + random st [st: 1]

			print [now/time/precise "start fake-downloading" file]
			do pick
			[
				[set-timeout secs   :ok-cbk ok-arg]
				[set-timeout secs   :fail-cbk fail-arg]
			] st
		]
	;

	; test "immediate" mode
		if immediate-simple [

		p0: make-promise func [resolve reject] [10] ; not resolved or rejected. Will remain "pending"
		p1: make-promise func [resolve reject] [resolve 100] ; resolves with 100
		p2: make-promise func [resolve reject] [resolve 100 resolve 300] ; resolves with 100 and ignores any other fulfillments or rejections
		p3: make-promise func [resolve reject] [resolve 100 reject -3] ; resolves with 100 and ignores any other fulfillments or rejections
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[pending #[none]] = bare-promise p0]
			[[fulfilled 100] = bare-promise p1]
			[[fulfilled 100] = bare-promise p2]
			[[fulfilled 100] = bare-promise p3]
		]

		p1: make-promise func [resolve reject] [reject -3] ; rejects with -3
		p2: make-promise func [resolve reject] [reject -3 reject 300] ; rejects with -3 and ignores any other fulfillments or rejections
		p3: make-promise func [resolve reject] [reject -3 resolve 100 ] ; rejects with -3 and ignores any other fulfillments or rejections
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected -3] = bare-promise p1]
			[[rejected -3] = bare-promise p2]
			[[rejected -3] = bare-promise p3]
		]
		
		p1: make-promise-resolve 50 ; immediate resolve "shortcut"
		p2: make-promise-reject "Renegaded" ; immediate reject "shortcut"
		p3: p2/catch func [reason] [prin "cought with: " print reason reason] ; catch is "shortcut" for /then none func [...
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 50] = bare-promise p1]
			[[rejected "Renegaded"] = bare-promise p2]
			[[fulfilled "Renegaded"] = bare-promise p3]
		]

		; test many then(s)
		p1: make-promise func [resolve reject] [resolve 100] ; resolves with 100
		p2: p1/then ; a then
			func [result][result + 200]
			func [reason][reason]
		p3: p1/then ; an other then for the same promise
			func [result][result + 300]
			func [reason][reason]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 100] = bare-promise p1]
			[[fulfilled 300] = bare-promise p2]
			[[fulfilled 400] = bare-promise p3]
		]

		; test chaining
		p1: make-promise func [resolve reject] [resolve 100] ; resolves with 100
		; following code is commented because it will generate an error! and since it is executed in an asyncronous way you will NOT be able
		; to catch it unless you patch set-timeout or disarm !
		;p2: p1/then
		;	func [result][print result] ; <<<=== do NOT do this. _ALWAYS_ return something or an error! will be generated
		;	none ; catch function can be none

		p1: make-promise func [ok ko] [ok 100] ; resolves with 100 . 1st parametere is name of function used to resolve AKA fulfill, 2nd is that used to reject
		p2: p1/then
			func [result][result + 5] ; function's parameter is value returned from "fulfilling" function
			none ; catch function can be none
		p3: p2/then
			[value + 15] ; you can use a block instead of a function but parameter name _MUST_ be "value" . OTHERWISE A SILENCED ERROR! WILL BE THROWN AND PROMISE WILL BE REJECTED.
			none
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 100] = bare-promise p1]
			[[fulfilled 105] = bare-promise p2]
			[[fulfilled 120] = bare-promise p3]
		]

		p1: make-promise func [resolve reject] [1 / 0] ; error!s will make promise to be rejected with the disarmed error! object
		p2: p1/then
			func [result][print "No error" none] ; not called since p1 is rejected. N.W.: _ALWAYS_ return something
			func [reason][reason]
		p3: p2/then
			none ; then "fulfill" function can be none, in which case, the promise value is passed thru.
			func [reason][print "An ERROR occured" reason] ; not called since p2 is _FULFILLED_ with a rejection reason
		p4: p3/then
			func [result][prin "My catched error: " print form-error result none] ; show what happens in a controlled way
			none
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected !ERROR!] = bare-promise p1]
			[[fulfilled !ERROR!] = bare-promise p2]
			[[fulfilled !ERROR!] = bare-promise p3]
			[[fulfilled #[none]] = bare-promise p4]
		]
		
		p1: make-promise-resolve 100
		p2: p1/then
			func [result][2 / 0 none] ; error!s in fulfill or reject functions will make "then's" promise to be rejected with the disarmed error! object
			none
		p3: p2/catch func [reason][prin "My catched error: " print form-error reason reason]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 100] = bare-promise p1]
			[[rejected !ERROR!] = bare-promise p2]
			[[fulfilled !ERROR!] = bare-promise p3]
		]
		
		] ; immediate-simple
	;

	; test "non-immediate" mode
		if non-immediate-simple [

		p1: make-promise func [resolve reject] [
			fake-download "file1" :resolve "text1" :reject "rejected1"
		]
		p2: p1/then
			func [result][print result join result "+t2"]
			func [reason][prin "Error p2: " print reason reason]
		wait-for-pending-timeouts ; wait for fake-download to finish...
		do-many [probedo] [
			[[fulfilled "text1"] = bare-promise p1]
			[[fulfilled "text1+t2"] = bare-promise p2]
		]

		p1: make-promise func [resolve reject] [
			fake-download "file1" :resolve "foo" :reject "rejected1"
		]
		p2: p1/then
			func [result-foo][
				prin ">>p1-resolved " print result-foo 
				p12: make-promise func [resolve reject] [
					fake-download "file2" :resolve "bar" :reject "rejected2"
				]
				; return a promise
				p212: p12/then
					func [result][prin ">>>p12-resolved " print result probe join result-foo result]
					func [reason][prin "Error p212: " print reason reason]
			] 
			func [reason][prin "Error p1. Failed to fake-download foo. Reason: " print reason reason]
		p3: p2/then
			func [result][prin ">>p2-resolved " print result result]
			func [reason][prin "Error p2: " print reason reason]
		wait-for-pending-timeouts ; wait for fake-download to finish...
		do-many [probedo] [
			[[fulfilled "foo"] = bare-promise p1]
			[[fulfilled "bar"] = bare-promise p12]
			[[fulfilled "foobar"] = bare-promise p2]
			[[fulfilled "foobar"] = bare-promise p212]
			[[fulfilled "foobar"] = bare-promise p3]
		]

		p1: make-promise func [resolve reject] [
			fake-download "file1" :resolve "foo" :reject "rejected1"
		]
		p2: p1/then
			func [result-foo][
				prin ">>p1-resolved " print result-foo 
				p12: make-promise func [resolve reject] [
					fake-download/state "file2" :resolve "bar" :reject "rejected2" 1 ; force rejection
				]
				; return a promise
				p212: p12/then
					func [result][prin ">>>p12-resolved " print result probe join result-foo result]
					func [reason][prin "Error p212: " print reason reason]
			] 
			func [reason][prin "Error p1. Failed to fake-download foo. Reason: " print reason reason]
		p3: p2/then
			func [result][prin ">>p2-resolved " print result result]
			func [reason][prin "Error p2: " print reason reason]
		wait-for-pending-timeouts ; wait for fake-download to finish...
		do-many [probedo] [
			[[fulfilled "foo"] = bare-promise p1]
			[[rejected "rejected2"] = bare-promise p12] ; 1st rejection will "cascade-transmit" rejection reason to next handlers
			[[fulfilled "rejected2"] = bare-promise p2]
			[[fulfilled "rejected2"] = bare-promise p212]
			[[fulfilled "rejected2"] = bare-promise p3]
		]

		p1: make-promise func [resolve reject] [
			fake-download "file1" :resolve "foo" :reject "rejected1"
		]
		p2: p1/then
			func [result-foo][
				prin ">>p1-resolved " print result-foo 
				p12: make-promise func [resolve reject] [
					fake-download "file2" :resolve "bar" :reject "rejected2"
				]
				p212: p12/then
					func [result][prin ">>>p12-resolved " print result probe join result-foo result]
					none
			] 
			none
		p3: p2/catch
			func [reason][prin "Error p2: " print reason "One of the files failed to fake-download"]
		p4: p3/then
			func [result][prin "Final result: " print result result]
			none
		wait-for-pending-timeouts ; wait for fake-download to finish...
		do-many [probedo] [
			[[fulfilled "foo"] = bare-promise p1]
			[[fulfilled "bar"] = bare-promise p12]
			[[fulfilled "foobar"] = bare-promise p2]
			[[fulfilled "foobar"] = bare-promise p212]
			[[fulfilled "foobar"] = bare-promise p3]
			[[fulfilled "foobar"] = bare-promise p4]
		]

		] ; non-immediate-simple
	;

	; test "finally" , "done" , "race" , "all" , "all-settled" , "any" , "then-all"
		if immediate-multi [

		p1: make-promise-resolve "foo"
		p2: p1/then
			func [result] [?? result]
			none
		p3: p2/then
			func [result] [?? result]
			none
		p4: p3/finally
			does [print "finallyzed" true] ; called independently of fulfillment or rejection
		p5: p4/done
			func [result] [prin "Final result: " probe result] ; if an error occured we could have done: if probe disarmed-error? reason [rearm reason] to stop execution
			none
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled "foo"] = bare-promise p1]
			[[fulfilled "foo"] = bare-promise p2]
			[[fulfilled "foo"] = bare-promise p3]
			[[fulfilled "foo"] = bare-promise p4]
			[[fulfilled "foo"] = bare-promise p5]
		]

		p1: make-promise-reject "BAD"
		p2: p1/then
			func [result] [print "OK" ?? result]
			;func [result] [print "not-OK" ?? result] ; this would fulfill with rejection reason
			none                                        ; but this passes thru rejection
		p3: p2/catch
			func [result] [print "catched" ?? result] ; this fulfills with rejection reason, not called if previous handler catches rejection
		p4: p3/finally
			does [print "finallyzed" true] ; called independently of fulfillment or rejection
		p5: p4/done
			func [result] [prin "Final result: " probe result] ; if an error occured we could have done: if disarmed-error? reason [rearm reason] to stop execution
			none
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected "BAD"] = bare-promise p1]
			[[rejected "BAD"] = bare-promise p2]
			[[fulfilled "BAD"] = bare-promise p3]
			[[fulfilled "BAD"] = bare-promise p4]
			[[fulfilled "BAD"] = bare-promise p5]
		]

		p1: make-promise func [resolve reject] [
			set-timeout 0.5 :resolve "one"
		]
		p2: make-promise func [resolve reject] [
			set-timeout 0.1 :resolve "two"
		]
		pa: make-promise-race reduce [p1 p2]
		pa1: pa/then
			func [value][print ["the winner is:" value] value]
			none ; not called
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled "one"] = bare-promise p1]
			[[fulfilled "two"] = bare-promise p2]
			[[fulfilled "two"] = bare-promise pa]
			[[fulfilled "two"] = bare-promise pa1]
		]

		p1: make-promise func [resolve reject] [
			set-timeout 0.5 :resolve "one"
		]
		p2: make-promise func [resolve reject] [
			set-timeout 0.1 :reject "two"
		]
		pa: make-promise-race reduce [p1 p2]
		pa1: pa/then
			func [value][print ["the winner is:" value] value] ; not called
			func [value][print ["the rejected winner is:" value] value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled "one"] = bare-promise p1]
			[[rejected "two"] = bare-promise p2]
			[[rejected "two"] = bare-promise pa]
			[[fulfilled "two"] = bare-promise pa1]
		]

		p1: make-promise-resolve 3
		p2: make-promise-all reduce [true p1 4]
		p3: p2/then
			func [values] [prin "FINAL: " probe values]
			func [values] [prin "FINAL rejected: " probe values]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 3] = bare-promise p1]
			[[fulfilled [#[true] 3 4]] = bare-promise p2]
			[[fulfilled [#[true] 3 4]] = bare-promise p3]
		]
		
		p1: make-promise-reject "NO!"
		p2: make-promise-all reduce [true p1 4]
		p3: p2/then
			func [values] [prin "FINAL: " probe values]
			func [values] [prin "FINAL rejected: " probe values] ; this fulfills with rejection reason
			;none                                                ; but this would pass thru the rejection
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected "NO!"] = bare-promise p1]
			[[rejected "NO!"] = bare-promise p2]
			[[fulfilled "NO!"] = bare-promise p3]
		]
		
		p1: make-promise-resolve 3
		p2: make-promise-all-settled reduce [true p1 4] ; is always resolved, is never rejected
		p3: p2/then
			func [values] [prin "FINAL: " probe values]
			func [values] [prin "FINAL rejected: " probe values] ; never called because all-settled never rejects
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 3] = bare-promise p1]
			[[fulfilled [#[true] 3 4]] = bare-promise p2]
			[[fulfilled [#[true] 3 4]] = bare-promise p3]
		]

		p1: make-promise-reject "NO!"
		p2: make-promise-all-settled reduce [true p1 4] ; is always resolved, is never rejected
		p3: p2/then
			func [values] [prin "FINAL: " probe values]
			func [values] [prin "FINAL rejected: " probe values] ; never called because all-settled never rejects
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected "NO!"] = bare-promise p1]
			[[fulfilled [#[true] "NO!" 4]] = bare-promise p2]
			[[fulfilled [#[true] "NO!" 4]] = bare-promise p3]
		]

		; same as all-settled but the order in which results arrive is important and is kept in sequence.
		; same as all-settled but with "then" functions that are called in the "right" order (see "non-immediate" version below)
		p1: make-promise-resolve 3
		p2: make-promise-then-all ; is always resolved, is never rejected
			reduce [true p1 4]
			func [value] [?? value]
			func [value] [?? value]
		p3: p2/then
			func [values] [prin "FINAL: " probe values]
			func [values] [prin "FINAL rejected: " probe values] ; never called because then-all never rejects
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled 3] = bare-promise p1]
			[[fulfilled [#[true] 3 4]] = bare-promise p2]
			[[fulfilled [#[true] 3 4]] = bare-promise p3]
		]
		
		p1: make-promise func [resolve reject] [
			set-timeout 0.5 :resolve "one"
		]
		p2: make-promise func [resolve reject] [
			set-timeout 0.1 :reject "two"
		]
		pa: make-promise-any reduce [p1 p2]
		pa1: pa/then
			func [value][print ["the winner is:" value] value] ;
			func [value][print ["the rejected winner is:" value] value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[fulfilled "one"] = bare-promise p1]
			[[rejected "two"] = bare-promise p2]
			[[fulfilled "one"] = bare-promise pa]
			[[fulfilled "one"] = bare-promise pa1]
		]

		p1: make-promise func [resolve reject] [
			set-timeout 0.5 :reject "one"
		]
		p2: make-promise func [resolve reject] [
			set-timeout 0.1 :reject "two"
		]
		pa: make-promise-any reduce [p1 p2]
		pa1: pa/then
			func [value][print ["the winner is:" value] value] ;
			func [value][print ["the rejected winner is:" value] value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected "one"] = bare-promise p1]
			[[rejected "two"] = bare-promise p2]
			[[rejected ["one" "two"]] = bare-promise pa]
			[[fulfilled ["one" "two"]] = bare-promise pa1]
		]
		p1: make-promise-reject "NO!"
		p2: make-promise-then-all ; is always resolved, is never rejected
			reduce [true p1 4]
			[?? value]
			[?? value]
		p3: p2/then
			func [values] [prin "FINAL: " probe values]
			func [values] [prin "FINAL rejected: " probe values] ; never called because then-all never rejects
		wait-for-pending-timeouts ; wait for promises to be resolved...
		do-many [probedo] [
			[[rejected "NO!"] = bare-promise p1]
			[[fulfilled [#[true] "NO!" 4]] = bare-promise p2]
			[[fulfilled [#[true] "NO!" 4]] = bare-promise p3]
		]
		print ""
		
		] ; immediate-multi
	;

	; test "non-immediate" -all etc.
		if non-immediate-multi [

		times: [0.8 .4 .6 1.2]
		outcomes: [0 0 0 0]
		fake-download-4-promised-files: func [/allok /local idx pf] [
			promised-files: copy ["file1" "file2" "file3" "file4"]
			if not allok [outcomes/3: 1]

			idx: 1
			pf: promised-files
			forall pf [
				do in
				pf/1: make-promise func [resolve reject] [
					fake-download/state/delay pf/1 :resolve join "ok-text" last  pf/1 :reject join "rejected-" pf/1 outcomes/:idx  times/:idx
				]
				'then
					[print [now/time/precise "fake-downloaded" value] value]
					[prin now/time/precise prin " Rejected: " ?? value]
				idx: idx + 1
			]
		]
		
		print "testing -all"
		fake-download-4-promised-files/allok
		
		do in
		pa: make-promise-all promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[fulfilled ["ok-text1" "ok-text2" "ok-text3" "ok-text4"]] = bare-promise pa]
		print ""

		print "testing -all"
		fake-download-4-promised-files
		
		do in
		pa: make-promise-all promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[rejected "rejected-file3"] = bare-promise pa]
		print ""
		
		print "testing -all-settled"
		fake-download-4-promised-files
		
		do in
		pa: make-promise-all-settled promised-files
		'then
			[print "ok" ?? value]   ; _ALWAYS_ fulfilled
			[print "niet" ?? value]   ; never called
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[fulfilled ["ok-text1" "ok-text2" "rejected-file3" "ok-text4"]] = bare-promise pa] ; _ALWAYS_ fulfilled
		print ""
		
		print "testing -race"
		fake-download-4-promised-files

		do in
		pa: make-promise-race promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[fulfilled "ok-text2"] = bare-promise pa] ;
		print ""

		print "testing -race"
		outcomes: [0 1 1 1]
		fake-download-4-promised-files/allok

		do in
		pa: make-promise-race promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[rejected "rejected-file2"] = bare-promise pa] ;
		print ""

		print "testing -any"
		outcomes: [0 0 0 0]
		fake-download-4-promised-files

		do in
		pa: make-promise-any promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[fulfilled "ok-text2"] = bare-promise pa] ;
		print ""

		print "testing -any"
		outcomes: [0 1 1 1]
		fake-download-4-promised-files/allok

		do in
		pa: make-promise-any promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[fulfilled "ok-text1"] = bare-promise pa] ;
		print ""

		print "testing -any"
		outcomes: [1 1 1 1]
		fake-download-4-promised-files/allok

		do in
		pa: make-promise-any promised-files
		'then
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[rejected ["rejected-file1" "rejected-file2" "rejected-file3" "rejected-file4"]] = bare-promise pa] ;
		print ""

		print "testing -then-all"
		outcomes: [0 0 0 0]
		fake-download-4-promised-files
		
		pa: make-promise-then-all promised-files
			[print "ok" ?? value]
			[print "niet" ?? value]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		print ""
		probedo [[fulfilled ["ok-text1" "ok-text2" "rejected-file3" "ok-text4"]] = bare-promise pa] ; _ALWAYS_ fulfilled
		print ""

		] ; non-immediate-multi
	;

	; test promise dialect
		if promise-dialect [
		story: [
			heading "A story of something"
			chapters [
				Chap1 0 0.8 "text1" ; format is: chapter state delay text
				Chap2 0 0.4 "text2"
				Chap3 1 0.6 "text3"
				Chap4 0 1.2 "text4"
			]
		]

		promisified-fake-download: func [
			name [word!]
			delay [number!]
			state [integer!]
			/local
			prom
			][
					;do in
					prom: make-promise func [resolve reject] [
						fake-download/state/delay form name :resolve get name :reject join "rejected-" form get name state delay
					]
					{
					'then
						[print [now/time/precise "fake-downloaded" value] value]
						[prin now/time/precise prin " Rejected: " ?? value]
					}
					
					prom
		]

		print "^/Testing loop"
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then [
				print value/heading
				
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					async [
						await [promisified-fake-download 'chapter delay state]
						; print the value as soon as it arrives
						then [print value value]
						catch [print ["Broken!" value] value]
					]
				]
			]
			then [print "All done!" 0]
			catch [print "Something broken!" 1]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing after-all with a rejection"
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if one of the promises is rejected
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					after-all chapters
					then
						[
							foreach chapter value [ ; use value (block!) returned by "after-all"
								print chapter
							]
							value ; return something
						]
					catch [probe "Something broken!" value]
					
				]
			]
			done [print ["All done but:" value] 0] [probe "All broken!" 1]
			finally []
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		; idem as before but with all promises fulfilled
		print "^/Testing after-all without rejections"
		story/chapters/Chap3: 0
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if one of the promises is rejected
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					after-all chapters
					then
						[
							foreach chapter value [ ; use value (block!) returned by "after-all"
								print chapter
							]
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing race"
		story/chapters/Chap3: 0
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; if using 'then or 'catch we would "interfere" with the output
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					race chapters
					then
						[
							print ["The fastest is:" value] ; we will receive only one value
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing race with first promise settled rejected"
		story/chapters/Chap2: 1
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; if using 'then or 'catch we would "interfere" with the output
							then [print value value]
							catch [print ["Broken!" value] value]
						]
				]
				async [
					race chapters
					then
						[
							print ["The fastest is:" value] ; we will receive only one value
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing after-any"
		story/chapters/Chap2: 0
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if all of the promises are rejected
							; or we would "interfere" with the output
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					after-any chapters
					then
						[
							print ["The fastest fulfilled is:" value] ; we will receive only one value
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing after-any with first promise settled rejected"
		story/chapters/Chap2: 1
		story/chapters/Chap3: 0
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if all of the promises are rejected
							; or we would "interfere" with the output
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					after-any chapters
					then
						[
							print ["The fastest fulfilled is:" value] ; we will receive only one value
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing after-any with all promises rejected"
		story/chapters/Chap1: 1
		story/chapters/Chap2: 1
		story/chapters/Chap3: 1
		story/chapters/Chap4: 1
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if all of the promises are rejected
							; or we would "interfere" with the output
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					after-any chapters
					then
						[
							print ["The fastest fulfilled is:" value] ; we will receive only one value
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing after-all-settled"
		story/chapters/Chap1: 0
		story/chapters/Chap2: 0
		story/chapters/Chap3: 1
		story/chapters/Chap4: 0
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if one of the promises is rejected

							; but -all-settled always fulfills so we could print the value as soon as it arrives
							then [print value value]
							catch [print ["Broken!" value] value]
						]
				]
				async [
					after-all-settled chapters
					then
						[
							print ""
							foreach chapter value [ ; use value (block!) returned by "after-all-settled"
								print chapter
							]
							value ; return something
						]
					catch [probe "Something broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...

		print "^/Testing then-forall"
		async 
		[
			await [promisified-fake-download 'story 0.5 0]
			then has [chapters] [
				print value/heading
				
				chapters: copy [] ; promises
				foreach [chapter state delay text] value/chapters [
					chapter: text ; since we're "faking" pre-assign result(s)
					append chapters
						async [
							await [promisified-fake-download 'chapter delay state]
							; AVOID using 'then or 'catch since they would fulfill the "parent" promise
							; and prevent it to be rejected and we won't be able to get a rejected promise
							; if one of the promises is rejected

							; but then-forall always fulfills so we could print the value as soon as it arrives
							;then [print value value]
							;catch [print ["Broken!" value] value]
						]
				]
				async [
					then-forall chapters
						; this is then
						[
							print value
							value ; return something
						]
						; this is catch
						[probe "This is broken!" 1]
					
				]
			]
			then [probe "All done!" 0]
			catch [probe "All broken!" 0]
			finally [print "THE END" 0]
		]
		wait-for-pending-timeouts ; wait for promises to be resolved...
		]
	;

	wait-for-pending-timeouts

	halt
	] ; if title
]
