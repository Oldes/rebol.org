rebol[
	title: "Format Decimal"
    date: 24-Feb-2017
    file: %to-decimal-notation.r
    author:  Christian Le Corre
    purpose: "Build a string that represents the decimal notation of a given number"
]

to-decimal-notation: func ["Build a string that represents the decimal notation of a given number" amount [decimal! integer!] /local var output pos nb]
[
	var: to-string amount
	either none? find var {E-}
	[var] ; No scientific notation or E-0
	[
		pos: index? find var "E"
		; nb is the number of zeros
		nb: to-integer to-string skip var (pos + 1)
		
		output: copy ""
		loop nb [
			if equal? (length? output) 1 [append output "."]
			append output "0"
		]
		append output (replace copy/part var (pos - 1) "." "")
		output
	]
]

; to-decimal-notation 3 / 5757
;
; The output is:
; "0.000521104742053153"