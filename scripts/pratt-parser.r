Rebol [
	title: "Pratt's parser implementation"
	file: %pratt-parser.r
	author: "Marco Antoniazzi"
	Copyright: "(C) 2018 Marco Antoniazzi. All Rights reserved."
	email: [luce80 AT libero DOT it]
	date: 08-08-2018
	version: 0.1.1
	Purpose: "A set of functions to ease construction of expressions parsing with precedences."
	History: [
		0.0.1 [05-08-2018 "Started"]
		0.1.1 [08-08-2018 "Completed main aspects"]
	]
	library: [
		level: 'advanced
		platform: 'all
		type: 'function
		domain: [parse grammar]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
	]
	Use: {See examples at end of script}
	help: {
		Most of the code is directly derived from that of Frederik Lundh's article 
			http://effbot.org/zone/simple-top-down-parsing.htm
		Some parts are derived also from Robert Nystrom's article
			http://journal.stuffwithstuff.com/2011/03/19/pratt-parsers-expression-parsing-made-easy/
		
		The code does not provide a "complete" language scanner.
		The core of the evaluation happens inside 'expression' function and that shouldn't be changed.
		The next most important function is 'tokenize'. This function scans the source string and
		outputs a list of name,object-token pairs. If yuu want to add support for e.g. hexadecimal
		numbers you must modify it and also some parsing rules and functions.
		Some common helper functions are provided but if you want to add support for some particular
		construct you will have to make it "manually" by calling the 'symbol' function and providing
		the necessary 'nud' and/or 'led' functions (see Lundh's article to understand what I mean)
		
		DISCLAIMER: USE THIS SCRIPT AT YOUR OWN RISK.
	}
]


if not value? 'pratt-ctx [; avoid redefinition

pratt-ctx: context [
	debug: false
	
	log: :comment
	if debug [log: :do]

	; rules
		digit: charset [#"0" - #"9"]
		alpha: charset [#"A" - #"Z" #"a" - #"z"]
		space: charset "^(09)^(0A)^(0D)^(20)"
		ops-chars: charset "/*-+!?:()"
		var-chars: complement union space ops-chars
		ops: ["**" | ops-chars]

		digits: [some digit]
		positive-decimal: [opt digits "." digits | digits "." ]
		exponent: [ [ "e" | "E" ] opt ["+" | "-"] digits]
		positive-float: [[positive-decimal | digits] opt exponent]
		number: [opt "-" positive-float]
		
		number_?: func [source [string!]] [parse/all source number]
	;
	; skips
		skip_spaces: func [str [string!]] [while [any [str/1 = #" " str/1 = #"^(09)" str/1 = #"^(0A)" str/1 = #"^(0D)"]][str: next str] str]
		skip_until_char: func [str [string!] char [char!]] [while [str/1 <> char][str: next str]]
		skip_comment: func [str [string!]][
			if str/1 <> #";" [return str]
			str: skip_until_char str #"^/"
		]
		skip_white: func [string [string!] /local start end] [
			start: end: string
			until [
				end: skip_spaces start
				start: skip_comment end
				start = end
			]
			start
		]

		skip_to_space: func [source [string!]] [parse/all source [[number | ops | some var-chars] source:] source]
	;
	token-list: copy []
	symbol_table: copy []
	
	yield: func [obj [object!]] [append token-list obj]
	advance: func [id [string! none!]] [
		if all [id token/id <> id] [to error! reform ["Expected:" id]]
		token: first+ token-list
	]

	tokenize: func [
		"Scan the input string! and create a list of <token>s"
		code [string!]
		/local
		pos
		word
		elem
		] [
		pos: code
		while [not tail? pos] [
			log [probe pos]
			pos: skip_white pos
			word: copy/part pos pos: skip_to_space pos
			log [prin "word: " probe word]
			case [
				number_? word [
					elem: make symbol_table/("literal") [value: word]
					yield elem
				]
				find alpha word/1 [
					elem: make symbol_table/("name") [value: word]
					yield elem
				]
				'else [
					if none? elem: select symbol_table word [to error! reform ["Unknown operator:" word ]]
					yield make elem []
				]
			]
		]
		yield symbol_table/("(end)")
	]

	token: none ; current token

	to_str: func [value [block!]][make string! attempt value] ; convert also none
	
	symbol_base: make object! [
		id: none ; node/token type name
		value: none ; used by literals
		first: second: third: none ; first, second and third param of outputted function or operator or statement"
		leftprec: 0
		nud: func [][
			to error! reform ["Syntax error (" id ")"]
		]
		led: func [left [object!]][
			to error! reform ["Unkknown or misplaced operator:" id ]
		]
		repr: func [][
			either any [id = "name" id = "literal"] [
				rejoin ["(" id " " value ")"]
			][
				rejoin ["(" id " " to_str [first/repr] to_str [second/repr] to_str [third/repr] ")"]
			]
		]
		eval: func [][
			either id = "literal" [
				load value
			][
				ops: [
					"+" add
					"-" subtract
					"*" multiply
					"/" divide
				]
				do reduce [select ops id first/eval second/eval]
			]
		]
		comp: func [][
			either id = "literal" [
				reform ["movi sp" value]
			][
				ops: [
					"+" "add sp sp(0) sp(1)"
					"-" "sub sp sp(0) sp(1)"
					"*" "mul sp sp(0) sp(1)"
					"/" "div sp sp(0) sp(1)"
				]
				reform [ second/comp lf first/comp lf select ops id ]
			]
		]
	]
	symbol: func [
		"Create a new symbol and append it to the global table or just updtate it."
		name [string! none!]
		prec [integer! none!]
		nud [block! none!]
		led [block! none!]
		/local
		sym
		][
		if none? sym: select symbol_table name [
			sym: make symbol_base []
			append symbol_table name
			append symbol_table sym
		]
		if name [sym/id: name]
		if prec [sym/leftprec: max prec sym/leftprec]
		if nud [sym/nud: func [] bind nud sym]
		if led [sym/led: func [left] bind led sym]
		sym
	]

	infix: func [name prec][
		symbol name prec none compose [
			first: left
			second: expression (prec)
			self
			]
	]

	prefix: func [name prec][
		symbol name none compose [
			first: expression (prec)
			self
			]
			none ; led
	]

	; infix binary operator but right-associative
	infix-right: func [name prec][
		symbol name prec none compose [
			first: left
			second: expression (prec - 1)
			self
			]
	]
	
	postfix: func [name prec][
		symbol name prec none [
			first: left
			self
			]		
	]

	; pseudo-infix ternary operator
	mixfix: func [name1 name2 prec][
		symbol name2 none none none
		symbol name1 prec none compose [
			first: left
			second: expression 0
			advance (name2)
			third: expression 0
			self
			]
	]

	constant: func [name][
		symbol name 0 compose [
			id: "literal"
			value: (name)
			self
			]
			none ; led
	]

	; the core of the evaluator
	expression: func [
		"Recursively travel a tokenized list according to precedences"
		rightprec [integer!]
		/local
		prevtoken
		left
		] [
		prevtoken: token
		token: first+ token-list
		left: prevtoken/nud
		while [rightprec < token/leftprec] [
			prevtoken: token
			token: first+ token-list
			left: prevtoken/led left
		]
		left
	]

	parse-expression: func [program [string!]] [
		tokenize program
		;probe token-list
		token: first+ token-list
		token: expression -1 ; -1 is initial "fake" precedence
	]

	
] ; context pratt-2

] ; value?

; examples
do ; just comment this line to avoid executing examples
[
	if system/script/title = "Pratt's parser implementation" [;do examples only if script started by us
	do bind [ ; bind to simplify code
		; make a SIMPLIFIED grammar with precedences

		; generic literal
		symbol
			"literal" 	; name
			none		; precedence
			[self]		; body of nud function
			none		; body of led function
		symbol "name" none [self] none
		; mark end of input
		set in symbol "(end)" none none none 'leftprec -1 ; (end) has a special precedence of -1 to intercept "lonely" ops
		
		infix "+" 30 infix "-" 30
		infix "*" 40 infix "/" 40
		; update operators to support also prefix precedence
		prefix "+" 60 prefix "-" 60
		; right-associative infix binary operator
		infix-right "**" 50
		; factorial as a postfix unary operator
		postfix "!" 70
		; conditionaal expression as pseudo-infix ternary operator
		mixfix "?" ":" 20

		; associativity made with parens as prefix unary pseudo-operator with delimiter
		symbol "(" none [
				first: expression 0
				advance ")"
				first ; return directly result of expression instead of 'self that would return the operator "("
			]
			none
		; add symbol to avoid reporting it as unknown
		symbol ")" none none none

		; constants are lierals
		constant "true" constant "false"

		;...
		; add as many as you want
		;...

		parse-expression probe "e ** (i / h * (p * x - E * t))"
		print ""
		print "Parsing tree:"
		print token/repr
		
		print ""
		parse-expression probe "b ** 2 - 4 * a * c"
		print ""
		print "Parsing tree:"
		print token/repr

		print ""
		parse-expression probe "1 / k !"
		print ""
		print "Parsing tree:"
		print token/repr

		print ""
		parse-expression probe "a * - b"
		print ""
		print "Parsing tree:"
		print token/repr

		print ""
		parse-expression probe "1 + 2 * (3 - 4)"
		print ""
		print "Parsing tree:"
		print token/repr

		print ""
		prin "Result of evaluation: "
		; note: only arithmetic operators supported (see symbol_base/eval)
		print token/eval

		print ""
		print "compiled pseudo ;) assembly: "
		; note: only arithmetic operators supported (see symbol_base/comp)
		print token/comp

		halt 
	] pratt-ctx
	] ; if title


]

