Rebol [
	Author: "Ladislav Mecir"
	File: %clean-func.r
	Title: "Clean-func"
	Date: 2-Oct-2020
	Purpose: {
		Func defines a function with given spec and body
		that remembers its arguments and locals after return.
		
		Clean-func defines a function with given spec and body
		that does not remember its arguments and locals after return.
	}
]

make object! [
	; helper function
	do-body: func [body [block!]] [do body]
	
	; result store
	result: none
	
	part1: [
		; get the result
		set/any 'result do-body
	]
	
	set 'body-of-clean func [
		[catch]
		{Return the body of a clean-func}
		f [function!]
	] [
		unless all [
			equal? length? second :f 8
			block? fourth second :f
			find/match second :f part1
			same? 'do-body third second :f
		] [
			throw make error! "cannot use body-of-clean on the function"
		]
		fourth second :f
	]
	
	set 'clean-func func [
		{
			Define a function with given spec and body that does not remember
			argument values on return.
		}
		[catch]
		spec [block!] {Help string (opt) followed by arg words (and opt type and string)}
		body [block!] "The body block of the function"
		/local context-var f part2
	] [
		unless find spec /local [append spec /local]
		
		; every function defined will have its own context-var
		context-var: use [context] ['context]
		
		; create modified function body
		part2: compose [
			; clear the context
			unset (context-var)
			; return the result
			get/any 'result
		]
		body: compose [
			(part1) (reduce [body])
			(part2)
		]
		
		; we need a local word
		change body 'local
		
		; make the function
		throw-on-error [f: make function! spec body]
		
		spec: first :f
		body: second :f
		
		; get the function context
		set context-var clear copy spec
		foreach value spec [
			if any-word? :value [
				append get context-var to word! :value
			]
		]
		bind get context-var first body
		
		; revert changes to the parts of the function body
		change body part1
		change skip body 1 + length? part1 part2
		
		:f
	]
]

comment [
	; Examples
	
	; normal func
	f: func [x [series!]] [length? :x]
	body-of :f
	; == [length? :x]

	; f remembers its argument value(s) and locals
	f head insert/dup copy "" "0" 1000
	get second body-of :f
	; == {0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000...
	
	; this should not work
	body-of-clean :f
	; ** User Error: cannot use body-of-clean on the function
	; ** Near: body-of-clean :f
	
	; clean-func
	g: clean-func [x [series!]] [length? :x]
	; this works
	body-of :g
	; == [
	; 	set/any 'result do-body [length? :x]
	; 	unset context
	; 	get/any 'result
	; ]
	
	; this works too
	body-of-clean :g
	; == [length? :x]
	

	; g does not remember its argument value(s) and locals
	g head insert/dup copy "" "0" 1000
	get second body-of-clean :g
	; ** Script Error: x has no value
	; ** Near: get second body-of-clean :g
]
