REBOL [
        File: %quote-node-attributes.r
        Date: 23-11-2020
        Title: "Dialect Object Model"
        Author: daniel murrill
        Emai: inetw3.dm@gmail.com
        Purpose: {
This script is used on data Sequence key value pairs with various different syntax styles such as
DOM Vars, html,xml,css, objects, arrays, json, rebol series, etc. It attempts to reformat malformed
key/value data found in a ^DSL that's usually delimited as objects, arrays, or json statement.

It requotes *" "*, and can creates tagged node-elements for look up in Dialect Object Models. Witch
then can be set as Vars to be used with rebol-DOM functions. 

You can allso fine tune your own delimiter rules as characters or words patterens to use with the 
strip-obj-chars-from() function. ^(DSL: domain specific language)
}
        ]

library: [
        level: 'intermediate
        platform: 'all
        type: function
        domain: [html vid css json js array]
        tested-under: 'windows
        Author: daniel murrill
        support: none
        license: none
        see-also: %HTML-view.r
    ]

;You can use quote-node-attributes with parameters for more flexibility if needed. 
;Replace *does* with *quote-node-attributes: func [(parameters: in-node-element)]*
;Make sure you include *create-tag-element with-these-attributes*

;replace sequence obj. chars.

obj-chars: none

strip-obj-chars-from: func [node-name obj-chars][
        trim node-name remove-head-char? form node-name {"}
        foreach [-char +char] obj-chars: any [reduce obj-chars [
	#"^/" " " "  " " " {" , "} {" } {", "} {" } "," " " {" "} {" } {" : "} {: "}
	{":"} {: "} {":} {:} { " } "" {"[["} {"[[" "} "{" "[" "}" "]" {""}
	{"} {  "} "" " : " ": " ":" " " { =} {=} {=} " " "'" "" "#" " " "'" {"}]
	][
        replace/all node-name -char +char
        ]
]

;replace  html in-line style-obj chars.

tag-tokens: to-hash [
             style-obj-chars [
             "<" "" {style="} " " {style=} " " " : " { "} ": " { "} ":" {*"} 
             " " {__} {=""}  " "  "=" {*"} ";" {"*} {""} {"} { "} {"} 
             {*"} { "} {"*} {" } " >" "" ">" "" "rgb" "" {__"} {"} {" "} {"}
             ]
] 


remove-tail-char?: func [in-node element][
	  foreach char element [
          all [char = back tail to string! in-node
          remove back tail in-node]
	  ]
]

remove-head-char?: func [in-node element][
          type: type? in-node 
          foreach char element [
          all [char = any [first to-string in-node form first in-node]
	  to type trim to-string any [attempt [remove in-node] remove form in-node]]
	  ]	  
]

quote-node-attributes: does [with-these-attributes: copy ""

remove-tail-char? in-node-element "/"

this-node: find/match in-node-element replace node-name: first parse/all in-node-element { =">} "<" ""

strip-obj-chars-from in-node-element [
    #"^/" " " {:"} {"} ": {" "=true {"  
    { ="" } {="" } { ="} " " {"=""} " " 
    {="" } {" } "://" "&&"
]

if find/any this-node "style=" [	
        parse/all this-node [ 
        [to {style="} | to "style="] copy style-obj [thru {;" } | thru {;">} 
        | thru {;>} | thru {;"} | thru {" }  | thru {>} | thru "}," | to end] (
        *style.node: copy style-obj 
        foreach [style-chars found-with-in] tag-tokens/style-obj-chars [
        replace/all *style.node style-chars found-with-in
        ] replace this-node style-obj *style.node
     )
   ]
]

foreach part replace/all this-node: parse/all this-node {<{} __,=":;[]>} [""] [] [
	part: any [if find/match part "'" [
	replace/all part "'" ""] part ]
	strip-obj-chars-from part ["  " " " {,} " " "&&" "://" ". " "." {=null} {=""} "'" "" {""} "" "none" ""]
	append with-these-attributes mold form part  
	] 
] 

create-tag-element: func [these-attr][
         in-attribute-blk: to-block these-attr 
         foreach [attr-name attr-value] in-attribute-blk [
         replace in-attribute-blk attr-name to-word attr-name
         attempt [trim attr-value]
         ]
         attempt [insert in-attribute-blk to-word trim/all node-name]
         data-node: build-tag in-attribute-blk  
]

with-these-attributes: copy ""

;In the DOM everything grouped is a node. individual key value pairs are elements of a group.
;so we are *in a *node to requote *elements 

;How to use:     "this is a node full of messed up elements from a bad robot."

in-node-element: {p "color":= "#0000ff" bgcolor="yellow",, "width" : "399" "height":"100", "font-styles" : "big" 
                              style={"color: green; bgcolor: purple;"}
                             } 

quote-node-attributes create-tag-element with-these-attributes

;or 

;quote-node-attributes  

;You can also try using the Dialect Object Model *Var on your key/value data without having
;to know or care if it's malformed. It will select proper key values for multiple syntax styles
;written in string and block formats.

;with rebol set-word: & series

contacts: [{Bestfriend: "[{"first": "Besty", "last": "Bestest", "number": 777-9211}]"}]
;Var 'contacts

;with rebol-dom's string! sequence

;markup-DOM [contacts: [
;						{Bestfriend: "[{"first": "Besty", "last": "Bestest", "number": 777-9211}]"}
;						]
;] Var dom/.contacts/.Bestfriend  Bestfriend[first].[last].[number]

;or just...

;Var contacts: = {Bestfriend: "[{"first": "Besty", "last": "Bestest", "number": 777-9211}]"}

;Bestfriend[first] or..  contacts: :array-obj!, *![contacts]

;Bestfriend = {
print {"Her first name is " ${first} |n}
print {"Her last name is " ${last} |n.}
print {"Her number is " ${number} |n.}
}