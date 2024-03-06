REBOL [
	title: "The two-phase simplex algorithm"
	file: %simplex.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 07-12-2019
	version: 0.1.0
	Purpose: {Implement the two-phase simplex algorithm.}
	History: [
		0.0.1 [15-06-2019 "Started"]
		0.1.0 [07-12-2019 "First version"]
	]
	Category: [tools math]
	library: [
		level: 'intermediate
		platform: 'all
		type: 'function
		domain: [tools math]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
	]
	comment: "Assumes all variables are > 0"
	Help: {
		USAGE (block! form)
			simplex <objective> <constraints>
			or
			simplex/minimize <objective> <constraints>
		
		<objective> is block! of coefficients
		<constraints> is block! of block!s of constrains
		e.g. 
		Maximize z = 3x + 2y
		subject to
		-x + 2y <= 4
		3x + 2y <= 14
		x - y <= 3
		
		must be given as: simplex [3 2] [[<= -1 2 4][<= 3 2 14][<= 1 -1 3]]
	}
	Notes: {
		Many aspects taken from www.phpsimplex.com

		Returns a block with 2 elements, 1st is:
			none if no solution exists or
			"Unbounded" if solution is +infinity or
			found value
		2nd element is;
			a block with the values of variables of objective function
		
		If strings are passed you can omit variables' names if their coefficient is 0.
		If strings are passed you MUST always keep the variables' names in the same order also when they are
		on different constraints !.
	}
]
;
if not value? 'simplex-ctx [; avoid redefinition

simplex-ctx: context [
	; debug
		debug:
			:comment
			;:do

	; series, math
		change-each: func [;replace ;map
			[throw]
			"Change each value in the series by evaluating a block over it. (modifies)"
			'word [word!] "Word or block of words to set each time (will be local)"
			data [series!] "The series to traverse"
			body [block!] "Block to evaluate. Return value to change current item to."
			/local n
			][
			repeat n data [set word n data: change/only data do body]
			head data
		]
		count-each: func [
			"Count how many values in the series return true by evaluating a block over it"
			'word [word!] "Word or block of words to set each time (will be local)"
			data [series!] "The series to traverse"
			body [block!] "Block to evaluate. Return true to add to the count."
			/local count n
			][
			count: 0
			repeat n data [set word n if do body [count: count + 1]]
			count
		]
		rotate: func [
			"Rotates elements in a series by an offset. (modifies)"
			series [series!]
			offset [integer!]
			][
			head case [
				offset > 0 [move/part series offset (length? series ) - offset]
				offset < 0 [move/part series (length? series) negate offset]
				offset = 0 [series]
			]
		]
		fill: func [
			"Duplicates an append a specified number of times. (modifies)"
			series [series!]
			value
			count [integer!]
			][
			head insert/dup tail series value count
		]
		summation: func [[catch]
			'index [word!]
			start [integer!]
			end [integer!]
			body [block!]
			/local sum n
			][
			; FIXME: change algorithm to reduce rounding errors?
			if start > end [throw make error! "start is greater then end in summation"]
			sum: 0
			repeat n (end - start + 1) [
				set index n + start - 1
				sum: sum + do body
			]
			sum
		]
	;
	; parse objective and constraints
	obj-vars:
	constr-vars: none
	parse_problem: context [

		out: copy []
		vars: copy []
		res: copy []
		sign: num: cond: var: err: none

		digit: charset [#"0" - #"9"]
		upper: charset [#"A" - #"Z"]
		lower: charset [#"a" - #"z"]
		letter: union upper lower

		digits: [some digit]

		add_op: [(num: "1" sign: 1) "+" | ["-" (sign: -1)]]
		number: [copy num [opt digits "." digits | digits "." | digits] ]
		variable: [copy var [letter any [letter | digit]]]
		term: [
			opt add_op opt [number opt "*"] variable
			(num: sign * load num   append vars var: to-word trim var)
		]
		line: [
			any [" " | "^-"] newline ; empty line
			|
			some [term (repend out [num var])]
			copy cond [">=" | "<=" | "="] (append out to-word cond)
			opt add_op number (append out sign * load num)
			[newline | end]
			(append/only res copy out clear out) 
		]
		constrs: [opt [thru "sub" thru "to" | "s.t."] some [line | err: thru end]]

		constraints:  func [
			string [string!]
			/local
				pos row
			][
			clear out
			clear vars
			clear res
			if not parse string constrs [throw make error! join "Malformed constraints string near: " copy/part err any [find err newline tail err]]

			constr-vars: unique vars
			if obj-vars <> constr-vars [throw make error! "Malformed or unsorted constraints or objective variables"]
			vars: constr-vars
			; pad tableau with 0s and make rows in proper format
			repeat row res [
				; FIXME?: by sorting we could place variables wherever we want
				; but than coefficients of final result could be in a different position. Or we could give also associated names of variables
				; but than which names should we give if no names are given?
				;sort/all/skip/part/compare row 2 ((length? row) - 2) func [a b] [a/2 < b/2]

				pos: row
				repeat var vars [
					row: either not pos: find row var [insert row 0] [remove pos]
				]
				row: head row
				move/to/part back back tail row 1 2
			]
			;probe 
			new-line/all res true
			copy res
		]
		
		object: [opt [thru "min" (minimiz: true)] thru "=" some [term (append out num) | err: thru end]] ;(repend out [num var])]]
		objective: func [
			string [string!]
			][
			clear out
			clear vars
			replace/all string newline " "
			if not parse string object [throw make error! join "Malformed objective string near: " err]
			obj-vars: unique vars
			copy out
		]
	]

	tableau: none
	objective-orig:
	objective-null:
	objective-basic:
	constraints-orig:
	objective:
	base:
	names:
	minimiz: none
	
	tot-vars:
	tot-constraints: 0

	need_phase_1?: false
	
	init_tableau: func [
		/local
			add_column curr-column basic basic-neg
		][
		add_column: func [
			col
			/local
				n row
			][
			n: 1
			foreach row tableau [
				insert tail row col/:n
				n: n + 1
			]
		]
		
		if minimiz [change-each num objective-orig [negate num]]

		tot-vars: length? objective-orig
		tot-constraints: length? constraints-orig
		objective-null: fill copy [] 0 tot-vars
		objective-basic: copy []
		base: copy []
		curr-column: tot-vars + 1
		; build basic vectors
		basic: fill copy [1] 0 tot-constraints - 1
		basic-neg: fill copy [-1] 0 tot-constraints - 1
		need_phase_1?: false

		tableau: copy/deep constraints-orig
		foreach row tableau [
			row/1: select [>= 1 <= -1 = 0] row/1
			if negative? row/2 [
				change-each num row [negate num] ; if 1st coefficient is negative we must swap all signs
			]
			curr-column: curr-column + 1
			switch row/1 [
				-1 [ ; <=
					add_column basic
					append objective-basic 0
					append base curr-column
				]
				 1 [ ; >=
					add_column basic-neg
					append objective-basic 0
					curr-column: curr-column + 1

					add_column basic
					append objective-basic -1
					append base curr-column
					need_phase_1?: true
				]
				 0 [ ; =
					add_column basic
					append objective-basic -1
					append base curr-column
					need_phase_1?: true
				]
			]
			; prepare unit vectors for next variables
			rotate basic 1
			rotate basic-neg 1
			; remove condition
			remove row
		]
		debug [print "inited" ?? base ?? objective-basic new-line/all tableau true ?? tableau]

		tableau
	]
	calc_Z: func [
		objective
		/local
			Z col
			sum start end n i
		][
		;Calculate the Z line:
		Z: copy []
		repeat col length? first tableau [
			append Z (summation i 1 (length? tableau) [ tableau/(i)/(col) * any [objective/(base/(i)) 0] ]) - objective/(col)
		]
		Z
	]
	find_Pivot_Index: func [
		tableau
		/local
			column row ratios item z-line entering leaving
		][
		z-line: next last tableau
		; Bland's rule (first negative). Used to avoid cycling
		column: index? entering: forall z-line [if negative? z-line/1 [break/return z-line] [0]]
		; minimum's rule
		;column: index? entering: minimum-of z-line
		if (first entering) >= 0 [throw none] ; no solution

		ratios: copy []
		foreach row tableau [
			append ratios case [
				all [row/1 >= 0 row/(column) >  0] [row/1 / row/(column)]
				all [row/1 >= 0 row/(column) <= 0] [1E+63]
				all [row/1 <  0 row/(column) >= 0] [1E+63]
				all [row/1 <  0 row/(column) <  0] [row/1 / row/(column)]
			]
		]
		remove back tail ratios ; remove unnecessarily calculated ratio
		row: index? leaving: minimum-of ratios ; this is an arg min

		if (first leaving) = 1E+63 [throw "Unbounded"]

		reduce [row  column]
	]
	pivot_About: func [
		tableau
		pivot
		/local
			i j item pivotDenom pivotRowMultiple col
		][
		set [i j] pivot
		base/(i): j
		pivotDenom: tableau/(i)/(j)
		if pivotDenom <> 0 [change-each item tableau/(i) [item / pivotDenom]]

		repeat row length? tableau [
			if row <> i [
				pivotRowMultiple: tableau/(row)/(j) ; store old value
				col: 0 
				change-each item tableau/(row) [col: col + 1 item - (pivotRowMultiple * tableau/(i)/(col))]
			]
		]

		tableau
	]
	can_Improve: func [tableau /local num][
		;not empty? remove-each num copy next last tableau [num >= 0]
		0 <> count-each num next last tableau [num < 0]
	]
	improve: func [
		][
		while [can_Improve tableau][
			debug [print "improving" ?? objective ?? tableau]
			pivot_About tableau find_Pivot_Index tableau
		]
	]
	objective_values: func [
		; calc values of non-basic variables of objective function
		/local
			values
		][
		change-each num base [num - 1]
		values: fill copy [] 0 tot-vars
		
		forall base [
			if base/1 <= tot-vars [
				values/(base/1): tableau/(index? base)/1
			]
		]
		values
	]
	set 'simplex func [[catch]
		"Returns maximum (minimum) of objective function, subject to given constraints using two-phase simplex algorithm"
		objective [block! string!] "objective linear function's coefficients or string!"
		constraints [block! string!] "block! of block!s of constraints with: condition, coefficients, RHS values. Or string!"
		/minimize
		/local
			n row col num catched
		] [
		minimiz: false ; restore default
		names: none ; restore default
		; FIXME: if (type? objective) <> (type? constraints) [Error]
		if string? objective [
			objective: parse_problem/objective objective
			names: copy parse_problem/vars
		]
		if string? constraints [
			constraints: parse_problem/constraints constraints
		]

		objective-orig: copy objective
		constraints-orig: copy constraints ; FIXME: copy/deep ?
		; check number of coefficients
		n: 1
		repeat row constraints [
			if ((length? row) - 2) <> (length? objective) [throw make error! join "Malformed or unsorted constraints or objective in row: " mold row]
			n: n + 1
		]

		catched: catch [ ; use catch instead of creating errors

			minimiz: any [minimize minimiz]

			init_tableau
			
			if need_phase_1? [

				; phase I

				objective: compose [0  (objective-null)  (objective-basic)]
				
				; calculate and append Z line
				append/only tableau calc_Z objective
				
				improve

				if (first last tableau) < 0 [ throw none] ; no solution

				; prepare for phase II

				; Remove Z line
				remove back tail tableau

				;Remove the columns corresponding to artificial variables.
				for col (length? first tableau) 1 -1 [
					if objective/(col) = -1 [
						repeat row tableau [
							remove at head row col
						]
						; update basic part of objective
						remove at head objective-basic col - 1 - tot-vars
						; change also indexes in base to account for removed columns
						change-each num base [either all [num > (tot-vars + 1) num > col][num: num - 1][num]]
					]
				]
			]

			; Modify the row of the objective function for the original problem.
			objective: compose [0  (objective-orig)  (objective-basic)]

			; calculate and append Z line
			append/only tableau calc_Z objective

			improve

			;FIXME: check for other solutions
			debug [if minimiz [change-each num objective-orig [negate num]]]
			debug [print "improved" ?? objective-orig ?? objective ?? base new-line/all tableau true ?? tableau]

			absolute first last tableau
		] ; catch
		reduce [catched objective_values]
	]

] ; context

] ; value?

;==== example ====

do ; just comment this line to avoid executing examples
[
	if system/script/title = "The two-phase simplex algorithm" [;do examples only if script started by us
	context [ ; avoid inserting names in global context

	probedo: func [code [block!] /local result][print [result: do code mold code] :result]

	probedo [
	; phase 1 & 2 =5
	objective: [1 1]
	constraints: 
				[	[<= 8  1 2]
					[<= 12 3 2]
					[>= 3  1 3]]
	5 = first probe simplex objective constraints
	]
	
	probedo [
	; phase 2 =11
	objective: [8 9 5]
	constraints: 
				[	[<= 2 1 1 2]
					[<= 3 2 3 4]
					[<= 8 6 6 2]]
	11 = first probe simplex objective constraints
	]
	
	probedo [
	; no solution =none
	objective: [2 5]
	constraints: 
				[	[<= 6 2 3]
					[>= 4 1 1]]
	none = first probe simplex objective constraints
	]
	
	
	probedo [
	; unbounded ="Unbounded" ; FIXME: should be +infinity or 1.INF
	objective: [3 2]
	constraints: 
				[	[<= 1  1 -1]
					[<= 2 -1  1]
					[<= 2  2 -3]]
	"Unbounded" = first probe simplex objective constraints
	]
	
	probedo [
	; phase 1 & 2 =1
	objective: [5 -1 -1]
	constraints: 
				[	[<= -1 3 -1 -1]
					[<= -2 1  2 -1]
					[<=  2 2  1  0]
					[=   1 1  1  0]]
	1 = first probe simplex objective constraints
	]
	
	probedo [
	; phase 2 degeneracy =11.7142857142857 82/7
	objective: [5 3]
	constraints: 
				[	[<= 2  1 -1]
					[<= 4  2  1]
					[<= 6 -3  2]]
	(82 / 7) = first probe simplex objective constraints
	]
	
	probedo [
	; phase 2 cycling =1
	objective: [10 -57 -9 -24]
	constraints: 
					compose/deep [[<= 0 (1 / 2) (-11 / 2) (-5 / 2) 9]
								[<= 0 (1 / 2) (-3 / 2) (-1 / 2) 1]
								[<= 1 1 0 0 0]]
	1 = first probe simplex objective constraints
	]

	probedo [
	; phase 1 & 2 minimize =2.2
	objective: [4 1 1]
	constraints: 
				[	[=  4 2 1 2]
					[=  3 3 3 1]
					;[>= 0 1 0 0]
					;[>= 0 0 1 0]
					;[>= 0 0 0 1]
				]
	2.2 = first probe simplex/minimize objective constraints
	]
	
	probedo [
	14 = first probe simplex "Maximize z = 3x1 + 2x2" {
		subject to
		-x1 + 2x2 <= 4
		3x1 + 2x2 <= 14
		x1 - x2 <= 3
	}
	]
	probe simplex-ctx/names
	

	probedo [
	; phase 1 & 2 minimize =5
	objective: [6 3]
	constraints: 
				[	[>= 1 1 1]
					[<= 2 0 -3]
					;[>= 0 1 0]
					[>= 1 2 -1]
					;[>= 0 0 1]
				]
	5 = first probe simplex/minimize objective constraints
	]
	
	halt
	] ; context
	] ; if title
]

