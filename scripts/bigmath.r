Rebol [
	title: "Functions for calculations with big integer numbers"
	file: %bigmath.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 01-04-2019
	version: 0.2.0
	Purpose: {Make calculations with big integer numbers.}
	History: [
		0.0.1 [28-09-2018 "Started"]
		0.1.0 [30-12-2018 "First version"]
		0.2.0 [01-04-2019 "Complete examples"]
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
	Note: {Some things inspired by %bignumbers.r of Alban Gabillon. It was a starting point and verification suite}
]

if not value? 'big-math-ctx [; avoid redefinition

big-math-ctx: context [
; misc
	round-fast: func [n] [n: 0.4 + n to integer! n - (n // 1)] ; <<<<---- 0.4 to be "prudent" !
	non-zero: complement charset "0"
	trim-zeros: func [n [string!]][head remove/part n any [find n non-zero 0]]
;
maxint64: 9223372036854775807

; sign check and change
	big-absolute: func [
		"Returns the absolute value of a big number."
		number [string!]
		][
		number: trim-zeros copy number
		if #"-" = number/1 [remove number]
		number
	]
	big-negate: func [
		"Changes the sign of a big number."
		number [string!]
		][
		number: trim-zeros copy number
		either #"-" = number/1 [remove number][head insert number #"-"]
	]
	big-negative?: func [
		"Returns TRUE if the big number is negative."
		number [string!]
		][
		parse number [any "0" number:] ; skip leading 0s
		#"-" = number/1
	]
	big-positive?: func [
		"Returns TRUE if the big number is non negative."
		number [string!]
		][
		parse number [any "0" number:] ; skip leading 0s
		#"-" <> number/1
	]
	big-sign?: func [
		"Returns sign of big number as 1, 0, or -1 (to use as multiplier).}"
		number [string!]
		][
		either big-positive? number [1] [either big-negative? number [-1] [0]]
	]
;
; comparisons
	big-equal?: func [
		"Returns TRUE if the values are equal."
		value1 [string!]
		value2 [string!]
		][
		parse value1 [any "0" value1:] ; skip leading 0s
		parse value2 [any "0" value2:] ; skip leading 0s
		equal? value1 value2
	]

	big-not-equal?: func [
		"Returns TRUE if the values are not equal."
		value1 [string!]
		value2 [string!]
		][
		parse value1 [any "0" value1:] ; skip leading 0s
		parse value2 [any "0" value2:] ; skip leading 0s
		not equal? value1 value2
	]

	big-greater?: func [
		"Returns TRUE if the first value is greater than the second value."
		value1 [string!]
		value2 [string!]
		][
		parse value1 [any "0" value1:] ; skip leading 0s
		parse value2 [any "0" value2:] ; skip leading 0s
		case [
			all [big-positive? value1 big-negative? value2] [true]
			all [big-negative? value1 big-positive? value2] [false]
			all [(length? value1) > (length? value2) big-positive? value1 big-positive? value2] [true]
			all [(length? value1) < (length? value2) big-positive? value1 big-positive? value2] [false]

			all [(length? value1) > (length? value2)] [false] ; all negative
			all [(length? value1) < (length? value2)] [true] ; all negative
			; same lengths and same signs
			equal? value1 value2 [false]
			big-negative? value1 [lesser? value1 value2]
			'else [greater? value1 value2]
		]

	]

	big-greater-or-equal?: func [
		"Returns TRUE if the first value is greater than or equal to the second value."
		value1 [string!]
		value2 [string!]
		][
		if any [big-greater? value1 value2  big-equal? value1 value2] [return true]
		false
	]

	big-lesser?: func [
		"Returns TRUE if the first value is less than the second value."
		value1 [string!]
		value2 [string!]
		][
		not big-greater-or-equal? value1 value2
	]

	big-lesser-or-equal?: func [
		"Returns TRUE if the first value is less than or equal to the second value."
		value1 [string!]
		value2 [string!]
		][
		if any [not big-greater? value1 value2  big-equal? value1 value2] [return true]
		false
	]
;
; simple arithmetic
	big-add: func [
		"Add two big numbers represented as strings in base 10"
		; simple algorithm
		; from right to left add 14 digits and previous carry
		; insert last carry if needed
		; all calcs are done using decimal!s to speed up things
		value1 [string!]
		value2 [string!]
		/local
		;zeros
		L1 L2 n res
		carry
		out
		][
		; 18 is (length? "9223372036854775807") - 1
		; 14 is max R2 decimal! non-scientific moldable representation
		value1: copy value1
		L1: length? value1
		L2: length? value2
		if L1 < L2 [return big-add value2 value1]
		; 

		case [
			all [big-positive? value1 value2 = "1"  (last value1) < #"9"] [
				value1/:L1: value1/:L1 + 1
				return value1
			]
			value1 = "0" [return value2]
			value2 = "0" [return value1]

			all [big-positive? value1 big-positive? value2][
				; go on
			]
			all [big-positive? value1 big-negative? value2][
				return big-subtract value1 big-negate value2
			]
			all [big-negative? value1 big-positive? value2][
				return big-subtract value2 big-negate value1
			]
			all [big-negative? value1 big-negative? value2][
				return big-negate big-add big-negate value1 big-negate value2
			]

			; 
		]

		if L1 // 14 <> 0 [value1: head insert/dup value1 "0" 14 - (L1 // 14)]
		L1: length? value1
		if L2 < L1 [value2: head insert/dup copy value2 "0" L1 - L2]

		out: make string! L1

		carry: 0
		value1: tail value1
		value2: tail value2
		repeat n L1 / 14 [
		
			value1: skip value1 -14
			value2: skip value2 -14
			; do decimal! addition
			res:  (make decimal! copy/part value1 14) +
			      (make decimal! copy/part value2 14) + carry * 1.0

			carry: 0
			if res >= 1E+14 [
				res: res - 1E+14
				carry: 1
			]

			; re-convert to string!
			res: form res
			insert/part res "00000000000000.0" (16 - length? res)
			insert head out copy/part head res 14
		]
		if carry = 1 [out: head insert out #"1"] 
		trim-zeros out
	]
	big-subtract: func [
		"Subtract two big numbers represented as strings in base 10"
		; simple algorithm
		; from right to left sub 14 digits and previous borrow
		; all calcs are done using decimal!s to speed up things
		value1 [string!]
		value2 [string!]
		/local
		L1 L2 n res
		borrow
		out
		][
		; 18 is (length? "9223372036854775807") - 1
		; 14 is max R2 decimal! non-scientific moldable representation
		value1: copy value1
		L1: length? value1
		L2: length? value2

		case [
			all [big-greater? value1 "1"  value2 = "1"  (last value1) > #"0"] [
				value1/:L1: value1/:L1 - 1
				return value1
			]
			big-equal? value1 value2 [return "0"]
			value2 = "0" [return value1]
			value1 = "0" [return big-negate value2]

			all [big-positive? value1 big-positive? value2 big-greater? value1 value2][
				; go on
			]
			all [big-positive? value1 big-positive? value2 big-lesser? value1 value2][
				return big-negate big-subtract value2 value1
			]
			all [big-positive? value1 big-negative? value2][
				return big-add value1 big-negate value2
			]
			all [big-negative? value1 big-positive? value2][
				return big-negate big-add big-negate value1 value2
			]
			all [big-negative? value1 big-negative? value2 big-greater? value1 value2][
				return big-subtract big-negate value2 big-negate value1
			]
			all [big-negative? value1 big-negative? value2 big-lesser? value1 value2][
				return big-negate big-subtract big-negate value1 big-negate value2
			]

			; 
		]

		L1: length? value1
		if L1 // 14 <> 0 [value1: head insert/dup value1 "0" 14 - (L1 // 14)]
		L1: length? value1
		if L2 < L1 [value2: head insert/dup copy value2 "0" L1 - L2]
		L2: length? value2

		out: make string! L1

		borrow: 0
		value1: tail value1
		value2: tail value2
		repeat n L2 / 14 [
		
			value1: skip value1 -14
			value2: skip value2 -14
			; do decimal! subtraction
			res:  (make decimal! copy/part value1 14) -
			      (make decimal! copy/part value2 14) - borrow + 1E+14

			borrow: 1
			if res >= 1E+14 [
				res: res - 1E+14
				borrow: 0
			]

			res: form res ;
			; must pad with 0s to keep number right aligned
			L1: length? res
			if L1 < (14 + 2) [res: head insert/dup res "0" 14 + 2 - L1]
			insert head out copy/part res (length? res) - 2
		]
		trim-zeros out
	]
	big-multiply: func [
		"Multiply two big numbers represented as strings in base 10"
		; simple long (grade school) multiplication algorithm
		; all calcs are done using decimal!s to speed up things
		value1 [string!]
		value2 [string!]
		/local
		L1 L2 n partres lenpartres res v2 carry high low prev_high valuein
		out
		][
		; 18 is (length? "9223372036854775807") - 1
		; 14 is max R2 decimal! non-scientific moldable representation
		; 7 is 14 / 2
		L1: length? value1
		L2: length? value2
		if L1 < L2 [return big-multiply value2 value1]

		case [
			value1 = "-1" [return big-negate value2]
			value1 = "0" [return "0"]
			value1 = "1" [return value2]
			value1 = "2" [return big-add value2 value2]
			value2 = "-1" [return big-negate value1]
			value2 = "0" [return "0"]
			value2 = "1" [return value1]
			value2 = "2" [return big-add value1 value1] ; faster then big-multiply_2
			big-equal? value1 value2 [return big-square value1]
			; 
			(big-sign? value1) <> big-sign? value2 [return big-negate big-multiply big-absolute value1 big-absolute value2]
		]

		value1: copy value1
		if L1 // 7 <> 0 [value1: head insert/dup value1 "0" 7 - (L1 // 7)]
		L1: length? value1
		value2: copy value2
		if L2 // 7 <> 0 [value2: head insert/dup value2 "0" 7 - (L2 // 7)]
		L2: length? value2

		partres: make block! L1 + L2 / 7
		partres: insert/dup partres 0 L1 + L2 / 7
		lenpartres: 1 + length? head partres
		
		value2: tail value2
		repeat n L2 / 7 [
			partres: at head partres lenpartres - n
			prev_high: 0
			value2: skip value2 -7
			v2: make decimal! copy/part value2 7

			value1: tail value1
			repeat n L1 / 7 [
				value1: skip value1 -7
				; do decimal! multiplication
				res: (make decimal! copy/part value1 7) * v2
				
				high: to integer! (res / 1E7)
				low: res - (high * 1E7)
				; sum "central" partial results such as:
				;        43058618700734
				; 56382150198613
				partres/1: partres/1 + low + 0.0 + prev_high
				partres: back partres
				prev_high: high
			]
			partres/1: high
		]

		;re-convert partial results to string! adding also carries
		out: make string! L1 + L2
		carry: 0
		repeat n lenpartres - 1 [
			res: partres/(lenpartres - n) + carry
			carry: to integer! (res / 1E7)
			res: to integer! res - (carry * 1E7)
			insert head out res: form res
			if 7 > length? res [insert/dup head out "0" 7 - length? res]
		]
		trim-zeros out
	]

	big-multiply_2: func [
		; this is faster then "normal" big multiplication BUT slower then value + value 
		value [string!]
		/local
		L1 out carry res
		][
		out: copy ""
		L1: length? value
		if L1 // 9 <> 0 [value1: insert/dup value "0" 9 - (L1 // 9)]
		carry: 0
		value: tail value
		repeat n round/ceiling (length? head value) / 9  [
			value: skip value -9
			res: 0.0 + carry + shift/left (make integer! copy/part value 9) 1
			carry: 0
			if res >= 1E9 [
				res: res - 1E9
				carry: 1
			]
			res: form res
			L1: length? res
			if L1 < (9 + 2) [res: head insert/dup res "0" 9 + 2 - L1] ; 2 is length? ".0"
			insert head out copy/part res (length? res) - 2
		]
		if carry = 1 [out: head insert out #"1"] 
		trim-zeros out
	]
	big-square: func [
		"Returns the big number multiplied by itself"
		number [string!]
		/local
		n u v uv c carry ai aj number-7 n7 L1
		out
		][
		number: big-absolute number
		n: length? number

		case [
			number = "0" [return "0"]
			number = "1" [return "1"]
			number = "2" [return "4"]
		]

		if n // 7 <> 0 [number: head insert/dup copy number "0" 7 - (n // 7)]
		n: length? number
		n7: n / 7
		c: make block! 2 * n7 + 1
		c: head insert/dup c 0.0 2 * n7 + 1
		number: tail number
		repeat i n7 [;probe i
			number: skip number -7
			ai: make decimal! copy/part number 7 
			uv: c/(2 * i) + (ai * ai)
			carry: to-integer (uv / 1E7)
			c/(2 * i): uv - (carry * 1E7)
			number-7: number
			;for j i + 1 n7 1 [
			repeat j n7 - i [
				number-7: skip number-7 -7
				aj: make decimal! copy/part number-7 7
				uv: c/(i + i + j) + (2 * aj * ai) + carry 
				carry: to-integer (uv / 1E7)
				c/(i + i + j): uv - (carry * 1E7)
			]
			c/(i + n7 + 1): carry
		]
		;re-convert partial results to string!
		out: make string! 2 * n + 1
		;probe
		remove c
		repeat n length? c [
			res: form c/:n + 0.0 ; also convert to decimal! since short nums are formed into integer!s
			L1: length? res
			if L1 < (7 + 2) [res: head insert/dup res "0" 7 + 2 - L1] ; 2 is length? ".0"
			insert head out copy/part res (length? res) - 2
		]
		trim-zeros out
	]

	big-divide: func [
		"Divide two big numbers represented as strings in base 10"
		; _grade school_ long division algorithm but
		; 1st approximation is done using decimal!s then calc of
		; reminder is done using "full" big multiplication and subtraction
		; things get complicated when 1st approximation is wrong and we have to adjust for it
		value1 [string!]
		value2 [string!]
		/modulo "Return modulo"
		/local
		L1 L2 n partres lenpartres res extrazeros
		highdenom10 prevrem remapprox quotapprox quotapproxint numerapprox
		out
		][
		; 18 is (length? "9223372036854775807") - 1
		; 14 is max R2 decimal! non-scientific moldable representation
		; 7 is 14 / 2
		value1: trim-zeros copy value1
		value2: trim-zeros copy value2
		;out: bdivide reverse copy value1 reverse copy value2
		;return either modulo [out/2][out/1]
		L1: length? value1
		L2: length? value2

		case [
			big-lesser? value1 value2 [return either modulo [value1]["0"]]
			value2 = "1" [return either modulo ["0"][value1]]
			value2 = "2" [
				return either modulo [either big-odd? value1 ["1"]["0"]][big-divide_2_8 value1]
			]
			big-equal? value1 value2 [return either modulo ["0"]["1"]]
			value2 = "0" [to-error "Big divide by 0"] ; "1.INF"
			L1 < 18 [
				L1: make decimal! value1
				L2: make decimal! value2
				return head clear find form either modulo [L1 // L2][L1 / L2] "."
			]
			; 
		]
		
		; if this algorithm gives wrong results use an other
		;out: bdiv_n value1 value2
		;return either modulo [big-subtract value1 big-multiply value2 out][out]
		
		extrazeros: 0
		; denom length must be >= 10
		if L2 < 10 [
			;if modulo [return big-mod-int value1 to-integer value2]
			extrazeros: 10 - L2
			value1: head insert/dup tail value1 "0" extrazeros
			value2: head insert/dup tail value2 "0" extrazeros
		]
		L1: length? value1
		L2: length? value2
		
		
		out: make string! L1 - L2

		highdenom10: make decimal! copy/part value2 10
		prevrem: value1
		loop round L1 - L2 + 1 / 2 [
			remapprox: copy/part prevrem 18

			quotapprox: (make decimal! remapprox) / highdenom10
			
			if quotapprox < 1.0 [break]
			quotapproxint: form to integer! quotapprox

			if all [#"0" = last quotapproxint (length? quotapproxint) > 4] [clear skip tail quotapproxint -4]
			if all [#"9" = last quotapproxint 9 = length? quotapproxint] [remove back tail quotapproxint]

			out: head insert tail out quotapproxint
			n: 1
			if big-greater? value2 copy/part value1 L2 [n: 0] ; take one less digit
			if (lo: length? out) > (L1 - L2 + n) [
				out: copy/part out L1 - L2 + n
				numerapprox: big-multiply value2 out
				i: 0
				while [big-greater? numerapprox value1] [
					if 11 = i: i + 1 [break] ; avoid infinte loop
					insert skip tail out 0 - ((length? quotapproxint) - (lo - length? out)) #"0"
					remove back tail out
					numerapprox: big-multiply value2 out
					numerapprox: head insert/dup tail numerapprox "0" L1 - length? numerapprox
				]
				remapprox: big-subtract value1 numerapprox ;copy/part numerapprox L1
				break
			]
			numerapprox: big-multiply value2 out
			numerapprox: head insert/dup tail numerapprox "0" L1 - length? numerapprox
			
			if all [big-greater? numerapprox value1 (last out) > #"0"] [
				out: big-subtract out "1"
				numerapprox: big-multiply value2 out
				numerapprox: head insert/dup tail numerapprox "0" L1 - length? numerapprox
			]
			if all [big-greater? numerapprox value1 (last out) > #"0"][
				out: big-subtract out "1"
				numerapprox: big-multiply value2 out
				numerapprox: head insert/dup tail numerapprox "0" L1 - length? numerapprox
			]

			n: 0
			while [big-greater? numerapprox value1] [
				; still wrong approximation ? :`((((
				; try inserting 0s at left (must also remove last char! :(( )
				if 11 = n: n + 1 [break] ; avoid infinte loop
				insert skip tail out 0 - length? form quotapproxint #"0"
				remove back tail out
				numerapprox: big-multiply value2 out
				numerapprox: head insert/dup tail numerapprox "0" L1 - length? numerapprox
				out: trim-zeros out
			]
			; optimize: skip value1 9 * n skip numerapprox 9 * n
			remapprox: big-subtract value1 copy/part numerapprox L1
			if remapprox = "0" [break]

			prevrem: remapprox
		]
		if all [extrazeros > 0 remapprox <> "0"] [remapprox: head clear skip tail remapprox negate extrazeros]
		out: head clear skip tail out (L1 - L2 + 1) - (length? out)
		if big-greater? remapprox value1 [to-error "wrong big division !!"]
		either modulo [remapprox][out]
	]
	bdiv_n: func [
		"Divide two big numbers represented as strings in base 10"
		; algorithm: calc 1/b with Newton's method (scaled up to avoid floating point), then do a * result
		; this is much slower then grade-school long division
		a [string!]
		b [string!]
		/local
		L1 L2 x n factor1 factor2 scaled2 prev_x 
		][
		L1: length? a
		L2: length? b
		factor1: L1 + 1
		factor2: L1 + L2 + 1
		; initial guess
		x: form 1.0 / (to-decimal copy/part b 18)
		; remove mantissa
		x: head any [remove find x "." x]
		x: head any [clear find x "E" x]
		; avoid mantissa by scaling all
		x: head insert/dup tail x "0" factor1 + 1 - length? x
		scaled2: head insert/dup tail copy "2" "0" factor2
		prev_x: "0"
		while [not big-equal? prev_x x][
			prev_x: x
			x: bigmath [scaled2 - (b * x) * x]
			; re-scale down
			x: head clear skip tail x 0 - factor2
		]
		n: 1
		if big-greater? b copy/part a L2 [n: 0] ; take one less digit
		; final multiplication
		x: copy/part prev_x: bigmath [a * x] L1 - L2 + n

		; adjust if necessary
		if n = 1 [
			;try round up
			if ( prev_x/(L1 - L2 + 1 + 1)) > #"5" [
				prev_x: big-add x "1"
				; not too much?
				if bigmath [ (b * prev_x) <= a] [x: prev_x]
			]
		]
		x
	]

	big-divide_2_8: func [
		"Divide big integer by 2. Optimized version using integer!s for calcs"
		value [string!]
		/local
		L1 out borrow val res
		][
		L1: length? value
		if L1 // 8 <> 0 [value: head insert/dup copy value "0" 8 - (L1 // 8)]
		L1: length? value
		out: make string! L1
		borrow: 0
		repeat n round/ceiling L1 / 8  [
			val: make integer! copy/part value 8
			res: shift (val + borrow) 1
			borrow: 0
			if odd? val [borrow: 100000000]
			value: skip value 8
			res: form res
			L1: length? res
			if L1 < 8 [res: head insert/dup res "0" 8 - L1]
			insert tail out res
		]
		trim-zeros
		out
	]
	big-divide_2_14: func [
		"Divide big integer by 2. Optimized version using decimal!s for calcs"
		value [string!]
		/local
		L1 out borrow val res
		][
		L1: length? value
		if L1 // 14 <> 0 [value: head insert/dup value "0" 14 - (L1 // 14)]
		L1: length? value
		out: make string! L1
		borrow: 0
		repeat n round/ceiling L1 / 14  [
			val: make decimal! copy/part value 14
			res: val + borrow / 2.0
			borrow: 0
			if 0 <> (val // 2.0) [borrow: 1E+14]
			value: skip value 14
			res: form res
			L1: length? res
			if L1 < (14 + 2) [res: head insert/dup res "0" 14 + 2 - L1] ; 2 is length? ".0"
			;insert tail out res
			insert tail out copy/part res (length? res) - 2
		]
		trim-zeros
		out
	]
	big-mod-int: func [
		num [string!]
		a [number!]
		/local
		res
		][
		; Initialize result 
		res: 0 

		; One by one process all digits of 'num' 
		repeat i length? num [
			res: res * 10 + (num/:i - #"0") // a 
		]
		form to-integer res
	]
;
; square-root, power, power-mod
	big-sqrt: big-square-root: func [
		"Returns the square root of a big number."
		; Babylonian / Newton method using integer ops
		; since result is approximated (if value is not a perfect square) the algorithm
		; can "oscillate", so choose the 1st repeated value to avoid infinite loop and
		; also to avoid checking by calculating eps: value - (result * result). (is 5 enough?)
		value [string!]
		/local
		prev_res prev_2_res prev_3_res prev_4_res prev_5_res L1 res
		][
		prev_res: "0"
		prev_2_res: "0"
		prev_3_res: "0"
		prev_4_res: "0"
		prev_5_res: "0"
		L1: length? value
		if odd? L1 [value: head insert copy value "0" L1: L1 + 1]
		; initial approximation
		res: form to-integer square-root to-decimal copy/part value 4
		res: head insert/dup tail res "0" L1 / 2 - 2
		while [not any [res = prev_res res = prev_2_res res = prev_3_res res = prev_4_res res = prev_5_res]] [
			prev_5_res: prev_4_res
			prev_4_res: prev_3_res
			prev_3_res: prev_2_res
			prev_2_res: prev_res
			prev_res: res
			res: bigmath [value / res + res / 2] 
		]
		res
	]
	big-power: func [
		"Returns the first number raised to the second number."
		; algorithm: iterative exponentiation by squaring
		number [string!]
		exponent [string!]
		/local
		result
		][
		
		case [
			;exponent < 0 [
			;	number: 1 / number
			;	exponent: - exponent
			;]
			exponent = "0" [return "1"]
			;exponent < 1 [return bnthroot number exponent]
			exponent = "1" [return number]
		]
		case [
			number = "1" [return "1"]
			number = "0" [return "0"]
		]
		result: "1"
		while [big-greater? exponent "1"] [
			if odd? last exponent [
				result: big-multiply result number
			]
			exponent: big-divide exponent "2"
			number: big-multiply number number
		]
		big-multiply result number
	]
	big-power-mod: func [
		; algorithm: iterative exponentiation by squaring
		number [string!]
		exponent [string!]
		modulo [string!]
		/local
		result
		][
		number: bigmath [number // modulo]
		result: "1"

		while [bigmath [exponent > 1]] [
			if big-odd? exponent [
				bigmath ['result := (result * number // modulo)] ; parens used because there is no precedence
			]
			bigmath [
			('exponent := (exponent / 2))
			('number := (number * number // modulo))
			]
		]
		bigmath [result * number // modulo]
	]
;
; GCD, lcm, mod-inverse
	big-gcd: func [
		a [string!]
		b [string!]
		/local
		temp
		][
		while [not big-equal? b "0"][
			temp: b
			b: big-divide/modulo a b
			a: temp
		]
		a
	]
	big-lcm: func [
		a [string!]
		b [string!]
		][
		bigmath [big-absolute (a * b) / big-gcd a b]
	]
	big-mod-inverse: func [
		"Returns a^-1 mod n"
		a [string!]
		n [string!]
		/local t newt r newr quotient temp
		][
		t: "0"
		newt: "1"    
		r: n
		newr: a    
		while [not big-equal? newr "0"][
			quotient: bigmath [r / newr] ; FIXME: set [quotient reminder] big-divide/as-block r newr
			set [r newr] reduce [newr bigmath [r - (quotient * newr)]]  ; this is the reminder of previous division
			set [t newt] reduce [newt bigmath [t - (quotient * newt)]] 
		]
		if big-greater? r "1" [return none] ;"a is not invertible"]
		if big-lesser? t "0" [t: bigmath [t + n]]
		t
	]
;
; odd?, even?, random
	big-odd?: func [
		"Returns TRUE if the number is odd."
		number [string!]
		][
		odd? last number
	]
	big-to-odd: func [
		"Makes a big number odd."
		number [string!]
		][
		number/(length? number): number/(length? number) or 1
		number
	]
	big-even?: func [
		"Returns TRUE if the number is even."
		number [string!]
		][
		even? last number
	]
	big-random: func [
		min [integer! string!] "Minimum number of digits"
		max [integer! string!] "Maximum number of digits"
		/local
			digits tot out rc
		][
		min: to-integer min
		max: to-integer max
		digits: "123456789001379"
		tot: min - 1 + random max - min + 1 
		out: make string! tot
		;insert/dup out digits to-integer tot / length? digits
		;insert out copy/part digits tot // length? digits
		;random out
		while [tot > length? out] [while [(rc: random #"9") < #"0"][] insert out rc]
		trim-zeros out
	]
	big-random-prime: func [
		bits [integer!]
		/local
			digits p
		][
		digits: to integer! log-10 2 ** bits
		random/seed now/time/precise
		until [
			p: big-random digits digits + 1
			p: bigmath [p * 6 + 1]
			big-is_probable_prime p 6;length? primes
		]
		p
	]
;
; miller-rabin
	primes: 
	;[3 5 7 11
		[13 17 19 23 29 31 37 41 43 47 53]
	{	59 61 67 71 73 79 83 89
		97 101 103 107 109 113 127 131
		137 139 149 151 157 163 167 173
		179 181 191 193 197 199 211 223
		227 229 233 239 241 251 257 263
		269 271 277 281 283 293 307 311
		313 317 331 337 347 349 353 359
		367 373 379 383 389 397 401 409
		419 421 431 433 439 443 449 457
		461 463 467 479 487 491 499 503
		509 521 523 541 547 557 563 569
		571 577 587 593 599 601 607 613
		617 619 631 641 643 647 653 659
		661 673 677 683 691 701 709 719
		727 733 739 743 751 757 761 769
		773 787 797 809 811 821 823 827
		829 839 853 857 859 863 877 881
		883 887 907 911 919 929 937 941
		947 953 967 971 977 983 991 997
		1009 1013 1019 1021]}
	forskip primes 1 [primes/1: form primes/1]

	big-is_probable_prime: func [
		"Returns true if number is probably prime k times using Miller-Rabin method."
		n [string!]
		k [integer!]
		/local
		rest sx dx d i a x composite n-1
		][
		if big-even? n [return false] ; divisible by 2
		rest: 0 if 0 = repeat i length? n [rest: rest + n/:i // 3] [return false] ; divisible by 3
		if #"5" = last n [return false] ; divisible by 5
		rest: n/1 - #"0" if 0 = forall n [ rest: rest * 3 + (any [n/2 #"0"]) - #"0" // 7] [return false] ; divisible by 7
		n: head n
		sx: 0
		forskip n 2 [sx: sx + n/1 - #"0" // 11]
		dx: 0
		n: next n
		forskip n 2 [dx: dx + n/1 - #"0" // 11]
		if sx = dx [return false] ; divisible by 11
		; FIXME: generalizzare il criterio di divisibilità, trovare il resto e provare a sfruttarlo per velocizzare il calcolo della divisione
		
		n: head n

		; Find d such that n = 2^r * d + 1 for some r >= 1
		d: n-1: bigmath [n - 1]
		while [bigmath [d // 2 = 0]][
			d: bigmath [d / 2]
		]
		composite: true ; assume composite
		repeat i k [
			;prin "is-p? " probe i
			a: primes/:i ; or choose a random number ?
			;a: big-random to-integer (length? n) / 2 to-integer (length? n) / 2 + 5
			x: big-power-mod a d n
			while [bigmath [d <> n-1]] [
				if any [big-equal? x "1" big-equal? x n-1] [composite: false break]
				bigmath [
				('x := (x * x // n))
				('d := (d * 2))
				]
			]
				
			if composite [return false]
		]
		true
	]
;

; bigmath
	form-nums: func [
		"Convert numbers to strings"
		block [block! paren!]
		/local
		out
		][
		out: copy []
		forall block [
			while [paren? block/1] [
				insert/only tail out to-paren form-nums block/1
				block: next block
				if tail? block [return out]
			]
			insert/only tail out either number? block/1 [
				form block/1
			][
				block/1
			]
		]
		out
	]
	infixes: [
		+ big-add * big-multiply - big-subtract / big-divide ** big-power // big-divide/modulo
		= big-equal? <> big-not-equal? > big-greater? >= big-greater-or-equal? < big-lesser? <= big-lesser-or-equal?
		:= setl
	]
	prefixes: [- big-negate + [] ]
	setl: func [word [word!] value] [do reduce [to-set-word word value]]
	infix-to-prefix: func [
		"Converts math expression with infix notation to prefix one. (No precedences)"
		block [block! paren!]
		/local new out
		][
		out: copy []
		forall block [
			while [paren? block/1] [
				insert tail out infix-to-prefix block/1
				block: next block
				if tail? block [return out]
			]
			either all [ new: select prefixes block/1 any [head? block  find infixes first back block] ][ ;note: /-1 is NOT compatible with R3
				insert tail out new
			][
				either new: select infixes block/1 [
					insert/only head out new
				][
					insert/only tail out block/1
				]
			]
		]
		out
	]

	set 'bigmath func [
		"Converts a math expression for use with big numbers (only integer!s) and evaluates it"
		; EVERYTHING that is not an "operator" is treated as a variable
		block [block!]
		][
		do infix-to-prefix form-nums block
	]
;
] ; context big-math-ctx

] ; value?

; examples
do ; just comment this line to avoid executing examples
[
	if system/script/title = "Functions for calculations with big integer numbers" [;do examples only if script started by us
	do bind [ ; bind to simplify code

	probedo: func [code [block!] /local result][print [result: do code mold code] :result]

	probedo ["10000000000000000000000000000" = big-add "9999999999999999999999999999" "1"] ; 28 9s
	probedo ["4750249066184057040" = big-multiply big-divide "4750249066184057040" "10263959280" "10263959280"]
	probedo ["4750249066184057040" = bigmath [ "4750249066184057040" / "10263959280" * "10263959280"]]
	probedo ["8875533354" = big-divide/modulo "4750249066184057040" "10263959283"]
	p: {102639592829741105772054196573991675900716567808038066800000000000790711307779}
	q: {106603488380168454820927220360012878679207958575989291520000000000193062808643}
	p+q: {209243081209909560592981416934004554579924526384027358320000000000983774116422}
	q-p: {3963895550427349048873023786021202778491390767951224719999999999402351500864}
	p*q: {10941738641570527421809707322040357612003732945449205990324526055281594740152589551544193851371914616935247444538828338494346926086632656945905593354333897}
	?? p
	?? q
	?? p+q
	?? p*q
	probedo [p+q = big-add p q]
	probedo [q-p = big-subtract q p]
	probedo [p*q = big-multiply p q]
	probedo [p = big-divide p*q q]
	probedo [q = big-divide p*q p]
	probedo [p*q = big-square-root big-square p*q] ; correct
	; correct "enough" ;)
	probedo [p*q_2: big-square big-square-root p*q (copy/part p*q round (length? p*q) / 2) = (copy/part p*q_2 round (length? p*q_2) / 2)] ; correct "enough" ;)
	probedo ["1" = big-gcd p*q p+q]
	probedo ["1" = big-gcd "209243081209909" "152415765279684" ]
	probedo ["69" = big-gcd "10488" "18147"]
	probedo [p+q = bigmath [p+q / "152415765279684" * "152415765279684" + (p+q // "152415765279684")]]
	probedo ["413" = big-mod-inverse "17" "780"]
	;print bigmath [5 ** (4 ** (3 ** 2))] ; this will take 20 minutes on a Athlon Dual Core 2.00 GHz
	;probe big-lcm p*q p+q
	
	keysize: 64
	e: "65537" ; fixed public exponent
	print ["^/Computing p and q for" keysize "bits..."]
	until
	;do
	[
		p: big-random-prime keysize
		?? p
		q: big-random-prime keysize
		?? q
		fi: bigmath [(p - 1) * (q - 1)]
		?? fi
		;lambda: bigmath [big-lcm (p - 1) (q - 1)]
		;?? lambda
		all ["1" = big-gcd e fi];lambda]; big-greater? (big-absolute big-subtract p q) form to-integer 2 ** (keysize / 2 - 100)]
	]
	n: bigmath [p * q]
	?? n
	?? e
	d: big-mod-inverse e fi ;lambda
	?? d
	msg: "53183770"
	;msg: "1026395928297411057720";541965739";91675900716567808038066800000000000790711307779"
	?? msg
	; RSA encrypt (result will be <= n, so message must be <= n or it must be subdivided)
	cyph: big-power-mod msg e n
	?? cyph
	; RSA decrypt
	msg: big-power-mod cyph d n
	?? msg
	;

	] big-math-ctx ; bind
	] ; if title

	halt

] ; do

