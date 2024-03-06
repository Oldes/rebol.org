Rebol [
	title: "Mini virtual and x86 machine dll to speed-up calculations a bit"
	file: %mini-reb-vm.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 11-01-2019
	version: 0.1.1
	Purpose: {speed-up calculations a bit.}
	History: [
		0.1.0 [28-09-2018 "Started"]
		0.1.1 [11-01-2019 "First version"]
	]
	Category: [tools math]
	library: [
		level: 'advanced
		platform: 'Windows
		type: 'function
		domain: [tools math]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
	]
	Notes:  {
		
		IMPORTANT:
		- No syntax checking is done
		- Only recognized language keywords are: if, either, while, break, return . Avoid ALL others.
		- All symbols except for operators and keywords are treated as variables,
		  so NO math or other functions allowed.
		- Avoid "lonely" variables, so Not: if var [...]  but: if var <> 0 [...]
		- All variables are "volatile", that means that they are local to single compiled block so you can not
		  access a variable declared in another compiled block
		  Also initialize variables at beginning of block
		- No checks on overflow/underflow
		- All numbers are translated to decimal!s and all math and comparison operations are done with decimal!s but
		  bit-logic operations are done with integer!s because nums are translated to integer!s
		  before doing the operation and back to decimal!s after, but this also means they are very slow.
		  
		The mandelbrot example is derived from https://github.com/red/code/blob/master/Scripts/mandelbrot.red
	}
	
	lib-code: {
		; compile with: do/args %red.r -dlib -o %mini-reb-vm.dll
		Red/System []

		; the order of this enumeration MUST match that of the compiler
		#enum mnems [
			NOPK: 1
			COPYK MOVIK
			ADDK SUBK MULK DIVK REMK NEGK
			SHIFTLK SHIFTRK ANDK ORK XORK NOTK
			SETEQK SETNEK SETGEK SETGTK SETLEK SETLTK
			LABELK IFFALSEK JUMPK RETURNK QUITK
		]
		
		; 1,11,52 1023
		f64-to-i32: func [
			"Convert from float! to integer!" ; while there is not an inline version
			numf [float!]
			return: [integer!]
			/local
				num [pointer! [float!]]
				p32 [pointer! [integer!]]
				hi32 [integer!]
				sign [integer!]
				exp [integer!]
				frac [integer!]
			] [
			num: [0.0]
			num/1: numf
			p32: as pointer! [integer!] num
			hi32: p32/2
			
			sign: hi32 >> 31 or 1 ; -1 or 1

			exp:  hi32 and 7FF00000h >> 20
			if exp = 1023 [return sign] ; -1 or 1
			if exp < 1023 [return 0]

			frac: hi32 and 000FFFFFh
			frac: either exp <= 1043 [
				frac >> (1043 - exp) ; only higher part needed
			][
				frac << (exp - 1043) or (p32/1 >>> (1075 - exp)) ; join higher and lower parts
			]
			2 << (exp - 1024) + frac * sign
		]

		mini_vm_run: func [
			code [pointer! [integer!]]
			vars [pointer! [float!]]
			return: [float!]
			/local
				p1 [integer!]
				p2 [integer!]
				i1 [integer!]
				i2 [integer!]
				start [integer!]
				mnem [integer!]
				codef [pointer! [float!]]
			][
			p1: 0 p2: 0
			codef: as pointer! [float!] code
			start: as integer! code
			; FIXME: end: find code QUITK
			mnem: code/1
			while [mnem <> QUITK][
				; FIXME: if code < start [return 0]
				mnem: code/1
				p1: code/2
				p2: code/3
				code: code + 4 ;(1 + 1 + 2)
				
				either mnem < SETEQK [
				either mnem < SHIFTLK [
				switch mnem [
					COPYK [vars/p1: vars/p2]
					MOVIK [vars/p1: codef/2]
					ADDK [vars/p1: vars/p1 + vars/p2 ]
					SUBK [vars/p1: vars/p1 - vars/p2 ]
					MULK [vars/p1: vars/p1 * vars/p2 ]
					DIVK [
						;if 0 = vars/p2 [
							;FIXME: set-error "Divide by 0"
						;	return 0
						;]
						vars/p1: vars/p1 / vars/p2  
					]
					REMK [vars/p1: vars/p1 // vars/p2 ]
					NEGK [vars/p1: 0.0 - vars/p1]
				]
				][
				; convert to int32
				i1: f64-to-i32 vars/p1
				i2: f64-to-i32 vars/p2
				switch mnem [
					NOTK [vars/p1: as float! not i1]
					ANDK [vars/p1: as float! i1 and i2]
					ORK [vars/p1: as float! i1 or i2]
					XORK [vars/p1: as float! i1 xor i2]
					SHIFTLK [vars/p1: as float! i1 << i2]
					SHIFTRK [vars/p1: as float! i1 >> i2]
				]
				]
				][
				either mnem < LABELK [
				switch mnem [
					SETEQK [vars/p1: either vars/p1 = vars/p2 [-1.0][0.0]]
					SETNEK [vars/p1: either vars/p1 <> vars/p2 [-1.0][0.0]]
					SETGEK [vars/p1: either vars/p1 >= vars/p2 [-1.0][0.0]]
					SETGTK [vars/p1: either vars/p1 > vars/p2 [-1.0][0.0]]
					SETLEK [vars/p1: either vars/p1 <= vars/p2 [-1.0][0.0]]
					SETLTK [vars/p1: either vars/p1 < vars/p2 [-1.0][0.0]]
				]
				][
				switch mnem [
					LABELK [] ; NOP
					IFFALSEK [if vars/p1 = 0.0 [code: as pointer! [integer!] start + p2]] ; param is expressed in bytes
					JUMPK [code: as pointer! [integer!] start + p2] ; param is expressed in bytes
					RETURNK [return vars/p1]
				]
				]
				]
				codef: as pointer! [float!] code ; restore after possible jump
			]
			
			vars/p1
		]
		
		mini_exe: func [
			code [pointer! [integer!]]
			vars [pointer! [float!]]
			return: [float!]
			/local
				exefunc
			][
			cfunc: alias function! [[stdcall] vars [pointer! [float!]] return: [float!]]
			exefunc: as cfunc code
			exefunc vars
		]
		
		#export [mini_vm_run]
		#export [mini_exe]
		
		comment { ; slower !
				mnemfunc: alias function! [vars [pointer! [float!]]]
				mnemf: as mnemfunc funcs/mnem
				mnemf vars
		funcs: [0 0 0  0 0 0 0 0 0 0]
		addf: func [vars [pointer! [float!]]] [vars/3: vars/3 + vars/1] funcs/ADDK: as integer! :addf
		subf: func [vars [pointer! [float!]]] [vars/3: vars/3 - vars/1] funcs/SUBK: as integer! :subf
		mulf: func [vars [pointer! [float!]]] [vars/3: vars/3 * vars/1] funcs/MULK: as integer! :mulf
		divf: func [vars [pointer! [float!]]] [vars/3: vars/3 / vars/1] funcs/DIVK: as integer! :divf
		negf: func [vars [pointer! [float!]]] [vars/3: 0.0 - vars/1] funcs/NEGK: as integer! :negf
		}

	}
]

; misc
	pad: func ["Pad a FORMed value on right side with spaces" 
		str "Value to pad, FORMed" 
		n [integer!] "Total size (in characters) of the new string" 
		/left "Pad the string on left side" 
		/with "Pad with char" 
		c [char!] 
		;return: [string!] "Modified input string at head"
		][
		str: form str
		head insert/dup 
		any [all [left str] tail str] 
		any [c #" "] 
		(n - length? str)
	]
	form_bin16: func [
		"Insert spaces and newlines in formed binary!"
		chars [integer!] cols [integer!] bin [binary!]
		] [
		bin: replace/all form bin newline ""
		bin: skip bin 2 ; skip "#"
		bin: insert bin newline
		while [(length? bin) > chars] [
			loop cols [
				bin: skip bin chars
				bin: insert bin " "
			]
			bin: insert bin newline
		]
		bin: head bin
	]
	probe-vm: func [
		"Prints formatted binary! virtual machine code"
		code [binary!]
		/local
			as lined lin this-line p2
		][
		lined: make struct! [
			mnem [integer!]
			p1 [integer!]
			p2 [decimal!]
		] none
		as: func [struct bytes][change third struct bytes struct]

		this-line: as lined code
		lin: 0
		while [this-line/mnem <> QUITK][ ; BEWARE of endianess
			p2: this-line/p2
			if p2 < 1E-100 [p2: from-int32 skip code 2 * 4]
			print [
				pad/left lin 4
				pad reform [
				mnemsk/(this-line/mnem)
				this-line/p1
				p2
				] 20
				copy/part skip code 0 * 4 4
				copy/part skip code 1 * 4 4
				copy/part skip code 2 * 4 8
			]
			code: skip code 4 + 4 + 8
			this-line: as lined code
			lin: lin + 16
		]
		code: head code
	]

;
; compile to high-vm
	; global vars
		output: copy []
		output-pos: 0
		
		ops: [+ - * / // < > <> = <= >= and or xor not << >>]
		tokens: [if either while break return]
		unimplemented: [repeat until loop any all case do reduce compose load make] ; etc. !

	;
	; misc
		++: func ['arg [word!]] [set arg 1 + get arg]
		--: func ['arg [word!]] [set arg -1 + get arg]
	;
	; emit, error, to-high-vm
		level: 0
		error: func [a b][
			prin a prin " " print b
			prin "near: " probe back pos
			prin "last lexed type: " probe ret
			halt
		]

		debug?: false
		debug: either debug? [
			func [string] [print string string]
		][
			func [block] [block]
		]

		emit: func [a [block!] /local out] [
			out: debug rejoin a
			output-pos: insert tail output load out
		]
		
		to-high-vm: func [code][
			output: clear head output
			pos: code
			eval_main
			head new-line/all/skip output on 3
		]
	;
	; lex
		pos: prevpos: ret: prevlex: ret2: prevret2: none

		lex: func [][
			prevlex: ret
			prevret2: ret2
			prevpos: pos

			ret: type?/word ret2: pos/1
			if find ops ret2 [ret: 'op!]
			if find tokens ret2 [ret: 'token!]
			if find unimplemented ret2 [ret: 'unimplemented!]
			pos: next pos
			ret
		]
		go_BACK: func [] [
			pos: prevpos ret: prevlex ret2: prevret2
		]
	;
	; eval
		dreg: -1

		eval_main: func [] [
			until [
				eval_stats
				tail? pos
			]
		]
		eval_stats: func [/local post] [++ level
			debug "stats-beg"
			post: either debug? ["STAT"][""]
			lex
			switch/default ret [
				word! [
					++ dreg
					emit [" COPY" post " _d" dreg " " ret2]
				]
				set-word! [eval_set-word]
				;call! [eval_call]
				token! [eval_token]
				op! [go_BACK eval_expr_next]
				integer! decimal! [
					++ dreg
					emit [" MOVI" post " _d" dreg " " ret2]
				]
				paren! [go_BACK eval_paren]
				;#"^"" [eval_string]
			] [
				error "Unknown statement: " ret2
			]
			debug "stats-end"
			-- level
		]
		eval_set-word: func [/local ident post][++ level
			ident: ret2
			post: either debug? ["SET"][""]
			eval_expr_first
			eval_expr_next
			emit ["COPY" post " " ident " _d" dreg: max 0 dreg]
			-- dreg
			
			-- level
		]
		as-expr: false
		eval_expr_first: func [/local prefix post] [++ level
			lex ; start lexing
			post: either debug? ["EXPR"][""]
			switch/default ret [
				word! [debug ["copyexpr-dreg " dreg]
					++ dreg
					emit [" COPY" post " _d" dreg " " ret2]
				]
				set-word! [eval_set-word]
				;path! [eval_path]
				;call! [eval_call]
				token! [as-expr: true eval_token as-expr: false]
				integer! decimal! [
					++ dreg
					emit ["MOVI" post " _d" dreg " " ret2]
				]
				paren! [go_BACK eval_paren]
				op! [
					prefix: ret2
					eval_expr_first
					eval_expr_next
					switch/default form prefix [
						"-" [emit [" NEG _d" dreg " _d" dreg]]
						"not" [emit [" NOT _d" dreg " _d" dreg]]
					] [error "Wrong or unknown prefix operator:" prefix]
				]
			] [
				error "unknown symbol in expression:" ret2
			]
				
			-- level
		]
		eval_expr_next: func [ /local infix-list] [++ level
			infix-list: copy []

			while [lex = 'op!][
				eval_infix infix-list
				;print "infixing"
				eval_expr_first
				if not empty? infix-list [
					emit take infix-list
					-- dreg
				]
			]
			go_BACK 

			-- level
		]
		eval_infix: func [list [block!]] [++ level
			insert/only list copy switch form ret2 [
				"+" [[" ADD"]]
				"-" [[" SUB"]]
				"*" [[" MUL"]]
				"/" [[" DIV"]]
				"//" [[" REM"]]
				; TBD: ** power

				"<<" [[" SHIFTL"]]
				">>" [[" SHIFTR"]]

				"and" [[" AND"]]
				"or"  [[" OR"]]
				"xor" [[" xOR"]]

				"=" [[" SETEQ"]]
				">" [[" SETGT"]]
				"<" [[" SETLT"]]
				">=" [[" SETGE"]]
				"<=" [[" SETLE"]]
				"<>" [[" SETNE"]]
				"!=" [[" SETNE"]]
			]
			insert tail list/1 reduce [" _d" dreg " _d" dreg + 1]
			
			-- level
		]
		eval_paren: func [/local pre-block] [++ level
			pre-block: pos
			pos: pos/1
			while [not tail? pos] [
				eval_expr_first
				eval_expr_next
			]
			pos: next pre-block

			-- level
		]
		eval_block: func [/local pre-block] [++ level
			debug "eval_block-beg"
			either as-expr [-- dreg][dreg: -1]
			pre-block: pos
			pos: pos/1
			if not block? pos [error "block" "expected"]
			while [not tail? pos] [
				eval_stats
			]
			pos: next pre-block
			debug "eval_block-end"
			-- level
		]

		eval_token: func [] [++ level
			switch/default form ret2 [
				"if" [eval_if]
				"either" [eval_either]
				"while" [eval_while]
				"break" [emit [" JUMP endloop endloop"]]
				"return" [eval_return]
			] [
				error "unknown token" ret2
			]
			-- level
		]
		eval_if: func [] [++ level

			eval_expr_first
			eval_expr_next
			emit ["IFFALSE _d" dreg " else"]
			eval_block
			emit ["JUMP endif endif"] ; used to mantain "simmetry" in jumps list ?
			emit ["LABEL else else"]
			emit ["LABEL endif endif"]

			-- level
		]
		eval_either: func [] [++ level

			eval_expr_first
			eval_expr_next
			emit ["IFFALSE _d" dreg " else"]
			eval_block
			emit ["JUMP endif endif"]
			emit ["LABEL else else"]
			eval_block
			emit ["LABEL endif endif"]

			-- level
		]
		eval_while: func [] [++ level

			emit ["LABEL loop loop"]
			eval_block
			emit ["IFFALSE _d" dreg " endloop"]
			eval_block
			; FIXME: check for Ctrl-C to let stop the loop
			emit ["JUMP loop loop"]
			emit ["LABEL endloop endloop"]

			-- level
		]
		eval_return: func [] [++ level
			eval_expr_first
			eval_expr_next
			;?? dreg
			emit ["RETURN _d" dreg " _d" dreg]

			-- level
		]
	;
;
; compile and update to binary virtual machine or binary x86

	; 'little = get-modes system:// 'endian
	int32: make struct! [num [integer!]] none
	to-int32: func [value][int32/num: value copy third int32] ; endianess aware
	from-int32: func [value [binary!]][change third int32 copy/part value 4 int32/num]
	int64: make struct! [num [integer!] pad [integer!] ] none ; BEWARE of where is padding !
	to-int64: func [value][int64/num: value copy third int64] ; endianess aware
	float32: make struct! [num [float]] none
	to-float32: func [value][float32/num: value copy third float32] ; endianess aware
	from-float32: func [value][change third float32 to-int32 value float32/num]
	float64: make struct! [num [decimal!]] none
	to-float64: func [value][float64/num: value copy third float64] ; endianess aware
	from-float64: func [value][change third float64 to-int32 value float64/num]

	block-to-struct: func [
		"Construct a struct! based on given block"
		block [block!] /local spec n
		] [
		block: copy block
		replace/all block 'none 0
		spec: copy []
		n: 1
		forall block [
			append spec compose/deep/only [(to-word join '_ n) [decimal!]]
			n: n + 1
		]
		make struct! spec none ;block
	]

	combine: func [series [series! port!] value] [if not find series value [insert tail series value] head series]

	enum: func [block [block!] /local n][n: 1 repeat word block [set word n n: n + 1]]

	; once decided the order of this block it SHOULDN'T change !
	enum mnemsk: [
		NOPK
		COPYK MOVIK
		ADDK SUBK MULK DIVK REMK NEGK
		SHIFTLK SHIFTRK ANDK ORK XORK NOTK
		SETEQK SETNEK SETGEK SETGTK SETLEK SETLTK
		LABELK IFFALSEK JUMPK RETURNK QUITK
	]

	;== COMPILE ===============================
	stack: copy []
	push: func [new] [insert stack new]
	pop: func [] [take stack]
	appen: func [new] [stack: head insert tail stack new]
	breaks: copy []

	vars: none
	compile-ctx: context [
	
	vars-space: copy #{}
	
	set 'compile-to-vm func [
		params [block!]
		code [block!]
		/local
			out vars-words emit
			mnem param1 param2 pos j
		][
		;probe
		code: optimize_for_vm code

		out: copy #{}
		breaks: clear head breaks
		emit: func [m p1 p2][
			append out to-int32 get to-word join m "K" ;index? find mnems m
			append out either word? p1 [to-int32 index? find vars-words p1][to-int32 p1]
			append out either word? p2 [to-int64 index? find vars-words p2][to-float64 to decimal! p2]
		]
		emit-jmp: func [m p1 p2][
			append out to-int32 get to-word join m "K"
			append out either word? p1 [to-int32 index? find vars-words p1][to-int32 p1]
			append out to-int64 p2
		]

		pos: 1

		; collect variables
		vars-words: copy []
		combine vars-words params
		forskip code 3 [
			mnem: code/1
			param1: code/2
			param2: code/3
			if all [
				mnem <> 'IFFALSE
				mnem <> 'JUMP
				mnem <> 'LABEL
				] [
				if not number? param1 [combine vars-words param1]
				if not number? param2 [combine vars-words param2]
			]
		]
		;probe vars-words
		vars-space: head insert/dup clear head vars-space #{00000000 00000000} length? vars-words

		forskip code 3 [
			mnem: code/1
			param1: code/2
			param2: code/3
			;print [mnem param1 param2]
			switch/default mnem [
				IFFALSE [
					case [
						param2 = 'endloop [
							appen length? out
						]
						'else [
							push length? out ; store our position
						]
					]
					emit 'IFFALSE param1 0 ; position is changed later
				]
				JUMP [
					case [
						param2 = 'loop [
							pos: pop
							emit-jmp 'JUMP 0 pos ; position is changed now
						]
						param2 = 'endloop [
							append breaks length? out ; store our position
							emit 'JUMP 0 0 ; position is changed later
						]
						param2 = 'endif [
							push length? out ; store our position
							emit 'JUMP 0 0 ; position is changed later
						]
					]
				]
				LABEL [
					case [
						param2 = 'loop [
							appen length? out ; store our position
						]
						param2 = 'endloop [
							forall breaks [
								pos: breaks/1
								change/part at head out pos + 4 + 4 + 1 to-int32 (length? out) 4
							]
							pos: pop
							change/part at head out pos + 4 + 4 + 1 to-int32 (length? out) 4
						]
						param2 = 'else [
							j: pop ; take position of jump
							pos: pop ; take position of iffalse
							change/part at head out pos + 4 + 4 + 1 to-int32 (length? out) 4
							push j ; re-store position of jump
						]
						param2 = 'endif [
							pos: pop ; take position of jump
							change/part at head out pos + 4 + 4 + 1 to-int32 (length? out)  4
						]
					]
					emit 'LABEL 0 0
				]
			] [emit mnem param1 param2] ; all others are already correct
		]
		emit 'QUIT 0 0 ; the most important instruction ;) !
		out
	]
	set 'setup-vars func [
		params [block!]
		/local param
		][
		; translate ALL params values to float64
		repeat param reduce params [
			change/part vars-space to-float64 param 8
			vars-space: skip vars-space 8
		]
		vars-space: head vars-space
	]

	; x86 instructions
		
		AND_DW_MR: #"^(21)"
		OR_DW_MR: #"^(09)"
		xOR_DW_MR: #"^(31)"
		NOT_DW_MR: #"^(F7)"
		SHL_: #"^(D3)"
		SHR_: #"^(D3)"
		
		FADDP: "^(DE)^(C1)"
		FSUBP: "^(DE)^(E9)"
		FMULP: "^(DE)^(C9)"
		FDIVP: "^(DE)^(F9)"
		FPREM: "^(D9)^(C9)^(D9)^(F8)^(D9)^(C9)^(DD)^(D8)" ; fxch fprem fxch fpop
		FNEG: "^(D9)^(EE)^(DE)^(E1)" ; fldz  fsubrp
		FSUBR: "^(DC)^(E1)"
		
		maths: reduce ['ADD FADDP 'SUB FSUBP 'MUL FMULP 'DIV FDIVP 'REM FPREM 'NEG FNEG]
		
		fcmoves: [SETEQ "^(DA)^(C9)" SETNE "^(DB)^(C9)" SETGE "^(DB)^(D1)" SETGT "^(DB)^(C1)" SETLE "^(DA)^(D1)" SETLT "^(DA)^(C1)"]
		
		FCOMIP: "^(DF)^(F1)"
		
		MOV_DW: #"^(81)"
		
		FLD: "^(8B)^(5D)^(08)^(DD)^(83)" ; mov ebx,[ebp+8]  fld qword [ebx+ i32 ] (+8 is offset of second parameter to main routine and is address of vars-space
		; mov [ebp-8],dword 1st half  mov [ebp-4],dword 2nd half  fld qword [ebp-8]
		FLD_I: func [num][num: to-float64 num rejoin [#{} "^(C7)^(45)^(F8)" copy/part num 4 "^(C7)^(45)^(FC)" skip num 4 "^(DD)^(45)^(F8)"]]
		FILD: "^(DB)^(45)" ; ,[ebp+ i8]
		FSTP: "^(8B)^(5D)^(08)^(DD)^(9B)" ; mov ebx,[ebp+8] fstp qword [ebx+ i32 ]
		FISTP: "^(DB)^(5D)" ; ,[ebp+ i8]
		
		FLDZ: "^(D9)^(EE)"
		FLD1: "^(D9)^(E8)"
		
		FPOP: "^(DD)^(D8)" ; used to pop the stack, fdecstp does NOT work in this case !

		PUSH_BXDISI: "^(53)^(57)^(56)"
		POP_SIDIBX: "^(5E)^(5F)^(5B)"
		
		;JMP_B:  #"^(EB)"
		JMP_DW:  #"^(E9)"
		;JF_B: #"^(74)"
		JF_DW: "^(0F)^(84)"

		ENTER_: #"^(C8)"
		LEAVE_: #"^(C9)"
		RET_: #"^(C2)"
		
		NOP_: #"^(90)"
		
		RI: #"^(46)"
		RM: #"^(0A)"
		MR: #"^(08)"
		RR: #"^(08)"
		
		ind: #"^(00)" 	; indirect (e.g. [EAX])
		d8: #"^(40)"	; 8 bit displacement (e.g. [EBP+8])
		d32: #"^(80)"	; 32 bit displacement
		dir: #"^(C0)"	; direct register (e.g. ECX)
		
		EAX: #"^(C0)"
		d8_EBP: #"^(45)"
		ECX.d8_EBP: #"^(4D)"
		d8_EBP.ECX: #"^(4D)"
	;
	set 'assemble-to-exe func [
		params [block!]
		code [block!]
		/local
			out vars-words
			mnem param1 param2 pos j
			locals
			to-chars emit FLOAD
		][
		;probe
		code: optimize_for_vm code
		;probe
		code: optimize_for_exe code

		breaks: clear head breaks
		clear stack
		locals: 0
		to-chars: func [block [block!]
			][
			forall block [
				if number? block/1 [change block to-char either block/1 >= 0 [block/1][256 + block/1]]
			]
			head block
		]
		out: copy #{}
		emit: func [m block][
			append out m
			append out to-chars reduce block
		]

		; collect variables
		vars-words: copy []
		combine vars-words params
		forskip code 3 [
			mnem: code/1
			param1: code/2
			param2: code/3
			if all [
				mnem <> 'IFFALSE
				mnem <> 'JUMP
				mnem <> 'LABEL
				] [
				if not number? param1 [combine vars-words param1]
				if not number? param2 [combine vars-words param2]
			]
		]
		;probe vars-words
		vars-space: head insert/dup clear head vars-space #{00000000 00000000} length? vars-words
		;probe 
		vars: block-to-struct vars-words

		FLOAD: func [param][join copy #{} to-chars reduce either number? param [[FLD_I param]][[FLD to-int32 vars-words/(param)] ]]

		; prologue
		emit ENTER_ [8 + 4 + 4 0 0] ; make space for a float64 and two int32
		emit PUSH_BXDISI []

		tot: 0 
		while [not tail? vars-words] [
			vars-words: insert next vars-words tot
			tot: tot + 8
		]
		;probe 
		vars-words: head vars-words

		forskip code 3 [
			mnem: code/1
			param1: code/2
			param2: code/3
			;print [mnem param1 param2]
			switch/default mnem [
				COPY [
					emit "" [ 
						FLD to-int32 vars-words/(param2)
						FSTP to-int32 vars-words/(param1)
					]
				]
				MOVI [
					emit "" [
						FLD_I param2
						FSTP to-int32 vars-words/(param1)
					]
				]
				; math
					ADD SUB MUL DIV REM NEG [
						emit FLOAD param1 []
						emit FLOAD param2 []
						
						emit maths/(mnem) []
						
						emit FSTP [to-int32 vars-words/(param1)]
					]
				;
				; bit-logic
					AND OR XOR NOT SHIFTL SHIFTR [
						; -12 and -16 refers to offset of memory location in local stack
						; convert to int32
						emit "" [
							FLOAD param1
							FISTP -16
							FLOAD param2
							FISTP -12
							MOV_DW + RM ECX.d8_EBP -12
						]
						switch mnem [
							AND [emit AND_DW_MR [d8_EBP.ECX -16]]
							OR [emit OR_DW_MR [d8_EBP.ECX -16]]
							XOR [emit XOR_DW_MR [d8_EBP.ECX -16]]
							NOT [emit NOT_DW_MR [d8_EBP + 16 -16]]
							SHIFTL [emit SHL_ [d8_EBP + 32 -16]] ; FIXME: if param2 > 32 [print error !] 
							SHIFTR [emit SHR_ [d8_EBP + 40 -16]]
						]
						; convert back to float64
						emit FILD [-16]
						emit FSTP [to-int32 vars-words/(param1)] ; result in param1
					]
				;
				SETEQ SETNE SETGE SETGT SETLE SETLT [
					emit "" [
						; st0: 0 st1: -1
						FLD1
						FLDZ
						FSUBR
						
						FLOAD param2
						FLOAD param1

						; st0: either cc [-1][0]
						; I64 IA-32 Vol 1 p.8-7 "new mechanism" (only P6+ processors)
						FCOMIP
						FPOP
						fcmoves/(mnem)  ; (only P6+ processors)
						
						FSTP to-int32 vars-words/(param1)
						FPOP
					]
				]
				IFFALSE [
					emit "" [
						FLDZ
						FLD to-int32 vars-words/(param1)
						; I64 IA-32 Vol 1 p.8-7 "new mechanism" (only P6+ processors)
						FCOMIP
						FPOP
					]
					case [
						param2 = 'endloop [
							appen length? out
						]
						'else [
							push length? out ; store our position
						]
					]
					emit JF_DW [NOP_ NOP_ NOP_ NOP_] ; position is changed later
					;emit JF_B [NOP_] ; short jump ; position is changed later
				]
				JUMP [
					case [
						param2 = 'loop [
							pos: pop
							emit JMP_DW [to-int32 pos - (length? out) - 1 - 3] ; position is changed now
						]
						param2 = 'endloop [
							append breaks length? out ; store our position
							emit JMP_DW [0 NOP_ NOP_ 0] ; position is changed later
						]
						param2 = 'endif [
							push length? out ; store our position
							emit JMP_DW [NOP_ 0 NOP_ 0] ; position is changed later
							;emit JMP_B [NOP_] ; short jump ; position is changed later
						]
					]
				]
				LABEL [
					case [
						param2 = 'loop [
							appen length? out ; store our position
						]
						param2 = 'endloop [
							forall breaks [
								pos: breaks/1 ; take position of jump
								change/part at head out pos + 2 to-int32 ((length? out) - pos - 5) 4
							]
							pos: pop ; take position of iffalse
							change/part at head out pos + 3 to-int32 ((length? out) - pos - 6) 4
						]
						param2 = 'else [
							j: pop ; take position of jump
							pos: pop ; take position of iffalse
							change/part at head out pos + 3 to-int32 ((length? out) - pos - 6) 4
							;change/part at head out pos + 2 to-char first to-int32 ((length? out) - pos - 2) 1 ; for short jump
							push j ; re-store position of jump
						]
						param2 = 'endif [
							pos: pop ; take position of jump
							change/part at head out pos + 2 to-int32 ((length? out) - pos - 5) 4
							;change/part at head out pos + 2 to-char first to-int32 ((length? out) - pos - 2) 1 ; for short jump
						]
					]
				]
				RETURN [
					emit FLOAD param1 []
					; epilogue
					emit "" [
						POP_SIDIBX
						LEAVE_
						RET_ 4 * 1 0 ; always only one param
					]
				]
			] [prin "Unknown opcode " print mnem]
		]
		; epilogue
		emit "" [
			POP_SIDIBX
			LEAVE_
			RET_ 4 * 1 0 ; always only one param
		]
		;probe
		out
	]
	] ; compile-ctx
;
; optimize
	optimize_for_vm: func [
		block [block!]
		/local
			fail ok?
			r1 r2 r3 r4 s d n p1 p2 op
			start mid end
			shl ops
			rule+3
			rule1 rule2 rule3 rule4 rule5
		][
		fail: [end skip]
		rule+3: [
			start:
			'COPY set r1 word! set p1 word!
			mid:
			'COPY set r2 word! set p2 word!
			set op ['ADD | 'SUB | 'MUL | 'DIV | 'AND | 'OR | 'XOR | 'SHIFTL | 'SHIFTR | 'SETEQ | 'SETNE | 'SETGE | 'SETGT | 'SETLE | 'SETLT ] 
			set r3 word! set r4 word!
			end:
			(if all [r1 = r3 r2 = r4] [mid: change/part start reduce [to-word join op "3" r1 p1 p2] end])
			:mid
		]
		rule1: [
			start:
			'COPY set r1 word! set s word!
			mid:
			'COPY set d word! set r2 word!
			end:
			(case [
				all [r1 = r2 d = s] [mid: change/part start reduce ['COPY r1 s] end]
				r1 = r2 [mid: change/part start reduce ['COPY d s] end]
			])
			:mid
		]
		rule2: [
			start:
			'MOVI set r1 word! set n number!
			mid:
			'COPY set d word! set r2 word!
			end:
			(if r1 = r2 [mid: change/part start reduce ['MOVI d n] end])
			:mid
		]
		rule3: [
			start:
			'COPY set r1 word! set s word!
			mid:
			set op ['ADD | 'SUB | 'MUL | 'DIV | 'REM | 'AND | 'OR | 'XOR | 'SHIFTL | 'SHIFTR | 'SETEQ | 'SETNE | 'SETGE | 'SETGT | 'SETLE | 'SETLT ] 
			set r2 word! set r3 word!
			end:
			(if all [r1 = r3] [mid: change/part start reduce [op r2 s] end])
			:mid
		]
		rule4: [
			start:
			'COPY word! word!
			mid:
			[
			  ['MOVI set r1 word! 1 1 0 ['ADD | 'SUB] set d word! set r2 word!]
			| ['MOVI set r1 word! 1 1 1 ['MUL | 'DIV] set d word! set r2 word!]
			]
			end:
			(if r1 = r2 [mid: change/part mid [] end])
			:start
		]
		shl: func [a b][shift/left a b]
		ops: reduce ['ADD :add 'SUB :subtract 'MUL :multiply 'DIV :divide 'REM :remainder
			'AND :and~ 'OR :or~ 'XOR :xor~ 'SHIFTL :shl 'SHIFTR :shift];
		rule5: [
			start:
			'MOVI set r1 word! set n1 number!
			'MOVI set r2 word! set n2 number!
			mid:
			set op ['ADD | 'SUB | 'MUL | 'DIV | 'REM | 'AND | 'OR | 'XOR | 'SHIFTL | 'SHIFTR] 
			set r3 word! set r4 word!
			end:
			(if all [r1 = r3 r2 = r4] [mid: change/part start reduce ['MOVI r3 ops/(op) n1 n2] end])
			:start
		]

		parse head block [some [rule1 | rule2 | rule3 | rule4 | rule5 | skip]]

		head new-line/all/skip block on 3
	]
	optimize_for_exe: func [
		block [block!]
		/local
			r1 r2 r3 s op
			start mid end
			rule3
		][
		rule3: [
			start:
			  ['COPY set r1 word! set s word!]
			| ['MOVI set r1 word! set s number!]
			mid:
			set op ['ADD | 'SUB | 'MUL | 'DIV | 'REM | 'AND | 'OR | 'XOR | 'SHIFTL | 'SHIFTR | 'SETEQ | 'SETNE | 'SETGE | 'SETGT | 'SETLE | 'SETLT ] 
			set r2 word! set r3 word!
			end:
			(if all [r1 = r3] [mid: change/part start reduce [op r2 s] end])
			:mid
		]

		parse head block [some [rule3 | skip]]

		head new-line/all/skip block on 3
	]
;

; compile interface
	compile_to_mini-vm: func [
		"Compiles a block! to a mini-virtual-machine binary!"
		vars [block!] "List of words to be passed to compiled block"
		body [block!] "The body block to compile"
		/no-binary "Avoid last compilation pass. Used to include a block into another."
		/show opts [block!] "List of things to show. Any of [source high-vm low-vm all] "
		/local
			out
		][
		opts: any [opts []]
		if not empty? opts [print "Compiling..."]
		if any [find opts 'all find opts 'source] [prin "Source>> " probe body]
		out: to-high-vm body
		if any [find opts 'all find opts 'high-vm] [prin "As high-vm>> " probe out]
		if no-binary [return out]
		out: compile-to-vm vars out
		if any [find opts 'all find opts 'low-vm] [print "As (optimized) low-vm>> " probe-vm out]
		out
	]
	assemble_to_mini-exe: func [
		"Assembles a block! to a x86 binary!"
		vars [block!] "List of words to be passed to compiled block"
		body [block!] "The body block to compile"
		/no-binary "Avoid last compilation pass. Used to include a block into another."
		/show opts [block!] "List of things to show. Any of [source high-vm binary all] "
		/local
			out
		][
		opts: any [opts []]
		if not empty? opts [print "Compiling..."]
		if any [find opts 'all find opts 'source] [prin "Source>> " probe body]
		out: to-high-vm body
		if any [find opts 'all find opts 'high-vm] [prin "As high-vm>> " probe out]
		if no-binary [return out]
		out: assemble-to-exe vars out
		if any [find opts 'all find opts 'binary] [print "As x86 binary>> " probe out]
		out
	]
;


; test the mini-vm library
	if system/version/4 <> 3 [alert "This script requires Windows OS" quit]

	write/binary %mini-reb-vm.dll decompress
	64#{
		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
		gMWrAGwAAA==
	}

	lib: load/library %mini-reb-vm.dll

	mini_vm_run: make routine! [
		a [binary!]
		b [binary!]
		;c [integer!] ; FIXME: future expansion
		return: [decimal!]
	] lib "mini_vm_run"
	mini_exe: make routine! [
		a [binary!]
		b [binary!]
		;c [integer!]
		return: [decimal!]
	] lib "mini_exe"

	palette: copy []
	make-palette: func [count [integer!] /local i c] [
		clear palette
		repeat i min count 255 [
			c: 3 * (log-e i) / log-e (count - 1.0)
			c: case [
				c < 1 [(to integer! 255 * (c - 0)) * 1.0.0 +   0.0.0]
				c < 2 [(to integer! 255 * (c - 1)) * 0.1.0 + 255.0.0]
				true  [(to integer! 254 * (c - 2)) * 0.0.1 + 255.255.0]
			]
			append palette c
		]
		change back tail palette 0.0.0 ; black inside, comment this to have white inside
	]

	mandel-code:
	[
		;/local
		;	i cr ci zr zi zr2 zi2 zrzi

		cr: x
		ci: y
		zr: 0
		zi: 0

		i: 0
		while [i < max-iter] [
			zr2: zr * zr
			zi2: zi * zi
			zrzi: zr * zi
			zr: zr2 - zi2 + cr
			zi: zrzi + zrzi + ci
			if zr2 + zi2 > 4.0 [break]

			i: i + 1
		]
		return i
	]

	; "pre-compile" code
	mandel-bin-code: compile_to_mini-vm/show [x y max-iter] mandel-code [all]

	mandelbrot-vm: func [
		x [decimal!] y [decimal!] max-iter [integer!]
		][
		; the static block below will (because it MUST) be reduced ! by setup-vars
		; and it MUST be equal to that used for compile_mini-reb-vm

		mini_vm_run mandel-bin-code setup-vars [x y max-iter]
	]

	; "pre-assemble" code
	mandel-exe-code: assemble_to_mini-exe/show [x y max-iter] mandel-code [binary]

	mandelbrot-exe: func [
		x [decimal!] y [decimal!] max-iter [integer!]
		][

		vars/_1: x
		vars/_2: y
		vars/_3: max-iter
		mini_exe mandel-exe-code third vars ; using this: setup-vars [x y max-iter] is slower
	]

	mandelbrot-iter: func [
		x [decimal!] y [decimal!] max-iter [integer!]
		/local
			i cr ci zr zi zr2 zi2 zrzi
		] mandel-code ; re-use already defined block
	;

	mandelbrot: func [img xmin xmax ymin ymax iterations /local width height pix bmp imgpix iy ix x y i c][
		width:  img/image/size/x - 1
		height: img/image/size/y - 1
		imgpix: img/image
		
		iy: 0
		while [iy <= height] [
			ix: 0
			while [ix <= width] [
				x: xmin + ((xmax - xmin) * ix / width)
				y: ymin + ((ymax - ymin) * iy / height)

				i: switch engine [
					rebol [mandelbrot-iter x y iterations]
					vm [mandelbrot-vm x y iterations]
					exe [mandelbrot-exe x y iterations]
				]
				
				if i > 255 [i: to integer! 255 * i / iterations]

				poke imgpix as-pair ix iy palette/(i)

				ix: ix + 1
			]
			if even? iy [wait 0.01]		;-- allow GUI msgs to be processed
			if stopped [exit] ; avoid "recursion"
			if empty? system/view/screen-face/pane [exit] ; stop calcs when window is closed
			iy: iy + 1
		]
	]

	ricalc-mandel: [
		stopped: false
		dt/text: "" show dt
		img/image/rgb: black 
		t0: now/time/precise
		make-palette load iterations/data
		mandelbrot img load xmin/data load xmax/data load ymin/data load ymax/data load iterations/data
		dt/text: form now/time/precise - t0
		show [dt img]
		stopped: true
	]

	engine: 'rebol

	view layout [
		title "Rebol Mandelbrot"
		style txt text 82 right ;font-size 10
		
		across
			style fld field 60 ricalc-mandel
			txt "x-min" xmin: fld "-2.0" here: at return
			txt "x-max" xmax: fld  "1.0" return
			txt "y-min" ymin: fld "-1.0" return
			txt "y-max" ymax: fld  "1.0" return
			txt "iterations" iterations: fld "100" return

		btn "Draw" 150x40 [engine: 'rebol do ricalc-mandel] return
		btn "Draw faster" 150x40 [engine: 'vm do ricalc-mandel] return
		btn "Draw fastest" 150x40 [engine: 'exe do ricalc-mandel] return
		txt "time (s):" 60 dt: txt 80 bold
		;return
		at here img: image 900x600 black rate 0:00:0.5
			feel [engage: func [face action event][if action = 'time [show img]]]
			with [append init [image: make image! size]]
	]
;
	free lib
	wait 0.5
	delete %mini-reb-vm.dll
if not empty? system/console/history [halt]

