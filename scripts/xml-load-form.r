Rebol [
	title: "Parse and write XML code"
	file: %xml-load-form.r
	author: "Marco Antoniazzi"
	Copyright: "(C) 2018 Marco Antoniazzi. All Rights reserved."
	email: [luce80 AT libero DOT it]
	date: 07-08-2018
	version: 0.7.1
	Purpose: "Parse XML code and return a tree of block, and vice-versa."
	History: [
		0.0.1 [15-07-2018 "Started"]
		0.7.0 [30-07-2018 "Completed main aspects"]
		0.7.1 [07-08-2018 "Twicked a little"]
	]
	library: [
		level: 'intermediate
		platform: 'all
		type: 'function
		domain: [parse markup xml]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
	]
	Use: {See examples at end of script}
	help: {
		This script has two main functions:
			'xml-to-block' that parses XML code and returns a tree of blocks.
		This tree and all its sub-blocks lengths are and are kept even, this way you can use common path selection
		or the provided internal functions 'select-nth' 'select-tree' 'change-nth' 'change-tree' and also 
		'get_element_by_attr' 'get_element_by_id' to get or set one or more elements of the tree.
			'form-xml' that transforms a tree of blocks returned by xml-to-block to an xml string!
		
		As part of the parsing process, to keep the structure 'even', some special elements of type issue! are
		inserted in the output.
		
		 - Since Rebol2 does not support Unicode this script does not support it either.
		 - There is no "post-processing" of parsed input so you will have to decode or re-parse the parts that need it (eg. entities, DTD).
		 - This is a quite extensive implementation but NOT complete, especially the DTD part.
		 - There is no special support for namespaces or other particular aspect.
		 - A malformed document is not parsed correctly resulting in an error, but if parsing succeds it cannot be considerd as if
		   the document is "valid" and/or "well-formed".
		
		DISCLAIMER: USE THIS SCRIPT AT YOUR OWN RISK.
	}
]

if not value? 'xml-ctx [; avoid redefinition

xml-ctx: context [

	__first: __last: __temp: none
	
	prolog: doctype: comment: pi: cdata: false

	; rules

		document: [ S? (keep 'xml keep new: copy [] push new) prolog_ element any Misc (pop)]

		fail: [end skip]

		apx: notapx: none

		digit: charset [#"0" - #"9"]
		alpha: charset [#"A" - #"Z" #"a" - #"z"]
		hexchar: union digit charset [#"a" - #"f" #"A" - #"F"]
		space: charset "^(09)^(0A)^(0D)^(20)"
		newline: charset "^(0A)^(0D)"
		Char: union space charset [#"^(21)" - #"^(FF)"] 				; [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]]
		apex: charset {"'}
		notquote: complement charset {"}
		notapos: complement charset {'}
		notltamp: complement charset "<&"
		notltampbr: exclude notltamp charset "]"
		notlit: complement charset {%&"'}
		
		S: [some space]
		S?: [any space]
		
		indentation: [newline S?]

		NameStartChar: charset [":_" #"A" - #"Z" #"a" - #"z" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(FF)"]  				;| [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF] ]
		NameChar: union NameStartChar charset ["-." #"0" - #"9" #"^(B7)"] 				; | [#x0300-#x036F] | [#x203F-#x2040] ]
		Name: [ NameStartChar any NameChar ]

		Eq: [ S? "=" S?]

		; Literals

		AttValue: [copy apx [{"} | {'} | {}] (notapx: either apx [complement union charset "<&" charset apx] [char]) copy __temp any [notapx | Reference] apx (keep __temp)] ; ------()-------
		SystemLiteral: [ {"} copy __temp any notquote {"} | {'} copy __temp any notapos {'}]
		PubidLiteral: [ {"} copy __first any PubidChar {"} | {'} copy __first any PubidCharnotapos {'}]
		PubidChar: charset [ "^(0A)^(0D)^(20)" #"0" - #"9" #"A" - #"Z" #"a" - #"z" {-'[]+,./:=?;!*#@$_%}]
		PubidCharnotapos: exclude PubidChar charset {'}

		;CharData: [any notltamp] ; [ [^<&]* - [[^<&]* "]]>" [^<&]*]]
		CharData: [pos: [any notltampbr "]]>" any notltamp] fail :pos | any notltamp]

		prolog_: [ opt XMLDecl any Misc opt [doctypedecl any Misc] ]
		Misc: [ comment_ | PI_ | S]
		XMLDecl: [ "<?xml" (if prolog [keep '?xml keep new: copy [] push new]) VersionInfo opt EncodingDecl opt SDDecl S? "?>" (if prolog [pop])] ; ------()-------
		VersionInfo: [ S "version" Eq apex "1." copy __temp some digit apex (if prolog [keep 'version keep join "1." __temp])] ; ------()-------
		EncodingDecl: [ S "encoding" Eq apex copy __temp EncName apex (if prolog [keep 'encoding keep __temp])] ; ------()-------
		EncName: [ alpha any [alpha | digit | "-" | "." | "_"]]
		SDDecl: [ S "standalone" Eq apex copy __temp ["yes" | "no"] apex (if prolog [keep 'standalone keep __temp])] ; ------()-------

		element: [ STag ["/>" | ">" opt indentation content ETag ] (
			pop
			; replace simple block with its content (but then I can not correctly reconstruct the xml string)
			;if all [2 = length? __last: last __first: first stack issue? first __last] [change back tail __first __last/2]
		)] ; ------()-------
		STag: [ "<" copy __temp Name (keep load __temp keep new: copy [] push new) any [S Attribute] S?] ; ------()-------
		Attribute: [ copy __temp Name (keep load __temp) Eq AttValue ] ; ------()-------
		ETag: [ "</" Name S? ">"]
		content: [ copy __temp opt CharData (if __temp [keep #Text keep __temp]) any [[element | copy __temp Reference (append last first stack __temp) | CDSect | PI_ | comment_] opt CharData]]

		comment_: [ "<!--" copy __temp to "-->" "-->" (if comment [keep #Comment keep __temp])]  ; ------()-------
		PI_: [ "<?" copy __first PITarget copy __last to "?>" "?>" (if pi [keep #PI keep append __first __last])] ; ------()-------
		PITarget: [ "xml" [S | "?>"] fail | Name S?]
		CDSect: [ "<![CDATA[" copy __temp to "]]>" "]]>" (if cdata [keep #CDATA keep __temp])] ; ------()-------

		doctypedecl: [ ; ------()-------
			"<!DOCTYPE" S copy __temp Name (if doctype [keep '!DOCTYPE keep new: copy [] push new keep #Name keep __temp ])
			opt [S ExternalID] S? opt ["[" copy __temp intSubset "]" (if doctype [keep #InternalSubset keep __temp]) S?] ">" (if doctype [pop])
		]
		intSubset: [any [markupdecl | ["%" Name ";" | S ]] ]
		markupdecl: [elementdecl | AttlistDecl | EntityDecl | NotationDecl | conditionalSect | PI_ | comment_ ]

		elementdecl: [ "<!ELEMENT" S Name S thru ">"]
		AttlistDecl: [ "<!ATTLIST" S Name S thru ">"]
		EntityDecl: [ "<!ENTITY" S opt ["%" S] Name S thru ">"]
		NotationDecl: [ "<!NOTATION" S Name S thru ">"]
		conditionalSect: ["<![" thru "]]>"] ; this "eats" those up here

		Reference: ["&" [Name | "#" some digit | "#x" some hexchar] ";"]

		ExternalID: [ ; ------()-------
			  "SYSTEM" S SystemLiteral (if doctype [keep 'SYSTEM keep __temp])
			| "PUBLIC" S PubidLiteral S SystemLiteral (if doctype [keep 'PUBLIC keep new: copy [] push new keep __first keep __temp pop])
		]

	;

	out: copy []
	stack: copy []
	stack: head insert/only stack out

	push: func [new] [insert/only stack new]
	pop: func [] [remove stack]
	keep: func [data] [append/only first stack data]

	set 'xml-to-block func [
		"Parses XML code and returns a tree of blocks."
		code [string!] "XML code to parse"
		/with elements [block!] "block of words indicating which extra elements to keep. Accepts: prolog, doctype, comment, pi, cdata"
		][
		if elements [forall elements [set in self first elements true]]

		out: copy []
		stack: copy []
		stack: head insert/only stack out

		either parse/all code document [

			; reset flags
			elements: [prolog doctype comment pi cdata]
			forall elements [set in self first elements false]

			head new-line-deep out
		][
			clear out
		]
	]

	indent: "" ; intentionally use a static string
	form-xml: func [
		"Transforms a tree of blocks returned by xml-to-block to an xml string!"
		block [block!]
		/root id "optionally give root name"
		/local
		out name value endchar attrs tailtag subblocks emit emit-attrs text
		][
		out: copy ""
		if empty? block [return out]
		attrs: copy ""
		subblocks: false
		emit: func [block][append out rejoin block]
		emit-attrs: func [name value][append attrs rejoin [{ } name {="} value {"}]]

		endchar: "/"
		if all [id id <> 'xml] [
			endchar: either #"?" = first form id ["?"]["/"]
			emit [indent "<" id]
		]
		tailtag: tail out
		forskip block 2 [
			name: block/1 value: block/2
			text: false
			case [
				'SYSTEM = name [ emit [{ SYSTEM "} value {"}]]
				'PUBLIC = name [ emit [{ PUBLIC "} value/1 {" "} value/2 {"}]]
				block? value [
					subblocks: true
					insert indent tab
					either all [2 = length? value #Text = first value] [
						emit [indent "<" name ">" value/2 "</" name ">^/" ]
						][
						either 0 = length? value [
							emit [indent "<" name "/>^/"]
						][
							emit [form-xml/root value name]
						]
					]
					remove indent
				]
				issue? name [
					emit switch name [
						#Comment [subblocks: true [indent tab "<!--" value "-->^/"]]
						#Name [append attrs " " [value]]
						#InternalSubset [endchar: "]" [ " [" value ]]
						#PI [subblocks: true [indent tab "<?" value "?>^/"]]
						#CDATA [subblocks: true [indent tab "<[CDATA[" value "]]>^/"]]
						#Text [subblocks: true text: true [value]]
					]
				]
				'else [emit-attrs name value]
			]
		]
		if any [subblocks empty? attrs] [
			if all [id id <> 'xml] [append attrs ">"]
			if not text [append attrs "^/"]
		]
		insert tailtag attrs
		either subblocks [
			if all [id id <> 'xml] [if not text [emit [indent]] emit ["</" id ">^/"]]
		][
			emit [endchar ">^/"]
		]
		
		out
	]

	new-line-deep: func [block [block!]] [
		foreach item block [
			if all [block? item any [2 < length? item block? item/2]] [new-line/all/skip item on 2 new-line-deep item]
		]
		block
	]
	
	get_element_by_attr: func [block [block!] name [word! lit-word!] value [string!] /local result] [
		result: none
		foreach [aname avalue] block [
			if all [aname = name avalue = value] [return block]
			if block? avalue [result: get_element_by_attr avalue name value]
			if block? result [return result]
		]
		result
	]
	get_element_by_id: func [block [block!] id [string!] ] [
		get_element_by_attr block 'id id
	]
	; get_elements_by_tagname:

	;select and change nth and tree
		comment { define 4 useful functions. They are compressed only because they are generic and do not belong only to xml
		select-nth series value n "Finds nth value in the series and returns the value or series after it, or none."
		select-tree series path "Finds a value in the series using path given as a block and returns the value or series after it, or none."
		change-nth series name n value "Finds nth value in the series and changes the value or series after it."
		change-tree series path value "Finds a value in the series using path given as a block and changes the value or series after it."
		}
		do decompress 64#{
		eJytVMFu2zAMvesr6J5SYJnhHIMBufUnDB9Um4mF2JIh0Q2Kdf8+ipKTNCiGrMhJNkmR7z1SVAEHbGltqd/CfrYt1Or3i7FdADbBmx5mBGOBeoSA3mAAbTvwSLO3Qcwp
		xvmzf0/owdCPaLPO4s8/oOpWU9s3oHJQnc4CJuepYHvKoizUxhIe0BeNahjMZNojl3yHenBuArvcZLSMsiRthqWwpOA7TQMV31UxYE0e8ZaZ/pLXHIw9wKSZ9sG8oQUd
		I18HJwAunBfbyXDkjS4p7/cUkMq15I6/JX/ogRXRI0ovDOGYJNE+YAJaq+DYzQcSSOTJ+a4A5SaKFSjdzIqC+oDFxknQFrCSxncu2p6jPxmqZ660UmYvsb+ggpp6704w
		6iMCeu8429Ooh73zI3YJzF5mII5T2fbaHlDEf2IuEfoWLqO2SHbmFisJ853QvDQ5/jUqohF9trCKmBwBjhO977IK38cmmT12c4tL0VxTOiWAHz9Cj3s2dw9NasH5SSxV
		5b44y02knMX5z3WQbv2b1110BPenJZA3g3DQw3DHGog5mgzp02qAHnWXLc0V2cf192E63LQ1L8cvu8sQ2zs6nF5NlnUHgw6U9EiljOVwAtFRLNX5xYWjma4c6831lAiE
		shLXcmwgt+wv/5MqXV0GAAA=
		}
	;

] ; context

] ; value?

;==== example ====

do ; just comment this line to avoid executing examples
[
	if system/script/title = "Parse and write XML code" [;do examples only if script started by us
	context [ ; avoid inserting names in global context

	xml: {
		<?xml version="1.0" encoding="UTF-8"?>
		<?php abc def in prolog?>
		<!DOCTYPE greeting PUBLIC "abc" "def" [
		  <!ELEMENT greeting (#PCDATA)>
		]>
		<users>
			<![CDATA[ (<a>) ]]>
		    <user id="u1" age="20">
				<?php xyz in tag?>
		        <name>Ema</name>
		        <surname>Princi</surname>
		        <address>Torino</address>
		    </user>
			<!-- #@! -->
		    <user id="u2" age="&gt;44" sex="M">
				<names>
			        <name/>
			        <name></name>
			        <name class="high" len="short">
					<!-- 
						Mix
					-->
					</name>
			        <name class="low">Max</name>
				</names>
		        <surname>Rossi</surname>
		        <address>Roma&apos;</address>
		    </user>
		</users>
	}
	probe 
	xml-tree: xml-to-block/with xml [prolog doctype comment pi cdata]
	print ">>>> get_element_by_id"
	probe u: xml-ctx/get_element_by_id xml-tree "u2"
	print ">>>> path selection"
	ns: u/names ; use simple path selection to access element
	foreach [name attributes] ns [
		print attempt [attributes/class]
	]
	print ">>>> block-path selection"
	probe select-tree xml-tree [xml users user 2 names name 3 len] ; xml/users/user:2/names/name:3/len
	print ">>>> block-path change"
	change-tree xml-tree [xml users user 2 names name 3 len] "very-long"
	probe select-tree xml-tree [xml users user 2 names name 3 len]
	print ">>>> xml reconstruction"
	print
	xml-ctx/form-xml xml-tree
	
	halt
	] ; context
	] ; if title
]


