REBOL [
        File: %rebol-dom-mdlparser.r
        Date: 02-11-2020
        Title: "Dialect Object Model"
        Emai: inetw3.dm@gmail.com
        author: daniel murrill
        Purpose: {
                      ----a future Rebol browser API?---- 
             %Rebol-DOM.r mdlparser.r can view DOM's as VID.
              The Rebol-dom code in the mdlparser has 
              been updated. I'll improve the mdlparser
              and post updates as time permits or if anyone
              request specific changes that will improve it.
              This mdlparser is successfully used for 
              demonstrating the DOM and HTML DSL usage 
              with the VID although it was only meant for my 
              own personal R&D use. Maybe someone else
              might be inspired, and do something
              rebolishush .}
        ]

library: [
        author: daniel murrill
        level: 'intermediate
        platform: 'all
        type: Dialect
        domain: [DOM html vid css json js array]
        tested-under: "windows Rebol2"
        support: "discussions email me"
        license: shareware
        see-also: { Check * html-entities: and *incolor-series: []
                           block, the upload keeps replacing them. You 
                           may need to reset the &;gt and &;lt ones.
}
    ]


html-demo: {
<meta name="date" content="21-May-2013/19:52:10-7:00">
<body background-color="Darkgoldenrod" text="Darkviolet">
<div><div width="770" bgcolor="Midnightblue" style="color:Saddlebrown;border:1x1 'solid rgb(200, 80, 70);">qwerty
<b color="Chocolate" bgcolor='yellow'>cause<i color="green">i</i>Chocolate</b>like you</div>
<p><p><p color='Blanchedalmond', bgcolor="black">The <b color="green">%Rebol-DOM.r</b> uses the <b color="white">%Markup-Dialect-parser</b>
<i>(Mdlparser.r)</i> to parse xml, xhtml, css, and html Domain Specific Languages in order for them to be viewable/scriptable in a VID. 
The %Mdlparser.r is not intended to be or used as a Rebol browser, but to be more in the spirit 
of the Webkit engine that was first used for the chrome browser. Its ability to view some web 
pages are limited due to HTTPS, javascript calls, improper and non standard use of html tags in web 
pages that only the browsers' quirks-mode can render. There's also the Rebol out of memeory crash thing that needs
to be work out.

So what can you do with<b color="red">a Rebol-DOM and its' mdlparser</b> you ask?. With a little more time
and patience i'll hopefully, at least create an XML, XHTML or HTML browser front end with a Dialect Object Model
server back end. Why? So the programing language can be any DSL transcoded through a DOM and executed/viewed
in Rebol.</p><br />
<hr size=%100 color="gray" bgcolor="white" />
<ul color="red" bgcolor="Beige">
<li color="red"><b color="blue">My First Item</b></li>
<li color="orange"><b>Second Item</b></li>
</ul><br /><area color="red" bgcolor="red"></area>
<div class="boiler"width="700">By Carl<strong>Sassenrath</strong>Revised: 1-Feb-2010 Original: 23-Oct-2005</div>
<table cell="0" cell="0" style=width:386;>
<TR color="orange" BGCOLOR="Mediumorchid">
<TD><TD width="4%"><b>0</b></TD>
<TD width="33%"><b><FONT COLOR="white"><i>itselfproject</i></FONT></b></TD></TD><TD>
<TD width="22%"><b><FONT COLOR="white">skill level</FONT></b></TD>
<TD width="21%"><b><FONT COLOR="white">study time</FONT></b></TD>
<TD width="20%"><b><FONT COLOR="white">edit/test</FONT></b></TD>
</TR>
<TR COLOR="green" BGCOLOR="#CCFFFF">
<TD BGCOLOR="#666666" width="4%"><b><FONT COLOR="white">1</FONT></b></TD>
<TD BGCOLOR="#CCFFFF" width="33%">create a single-page reblet</TD>
<TD width="20%">novice</TD>
<TD width="22%">5 m</TD>
<TD width="21%">5 m</TD>
</TR><TR BGCOLOR="#CCFFFF">
<TD BGCOLOR="#666666" width="4%"><b><FONT COLOR="white">2</FONT></b></TD>
<TD width="33%">create a multi-paged reblet</TD>
<TD width="22%">novice</TD>
<TD width="21%">10 m</TD>
<TD width="20%"><button value="Hi" color="Orchid" bgcolor="Teal" size=" " onclick="goo" />Click on Hi</TD>
</TR></table><br />
<b color="yellow" bgcolor="orange">language<a href="http://www.rebol.com/what-rebol.html"><i color="green">itself</i></a></b>
<input type="submit" value="ClickMe!" onclick="gogo" /><br /><br /><input type="button" value="checkbox this" style="color:yellow;bgcolor:Teal;border:4x2 solid rgb(100, 10, 10);" /><br /><p color="Indianred">Good by</p><br>Mediumpurple
<input type="search" bgcolor="YellowGreen" value="peanut butter"/>
<br /><p width="240" height="40px" style="color:Saddlebrown;bgcolor:red;border:1x1 solid rgb(20, 80, 10);">Hello with<b color="yellow">one more time<i color="#00ff00">value</i></b>Saddle</p>
<br /><button value="hello" color="green" />
<input type="button" value="Good button" color="Mediumpurple"/>
<br /><p color="Indianred">Good by</p><br /><input type="field" value="hello" /><input type="checkbox">
<br /><p color="#ff0000">Hello<span color="Chocolate">middle with</span><i color="#00ff00">every</i>
<b color="#0000ff">one</b></p><br /><button value="hello" color="Sienna" />
<input type="button" value="&nbsp;" color="purple" />
<br /><p color="red">Good by</p><br /><input type="field" value="hello"/>
<br /><p color="#ff0000">Hello with<i color="#00ff00">every</i><b color="#0000ff">one</b></p><span color="red">should be red</span>
<br /><button value="hello" color="Peachpuff" /><input type="button" value="Good by" color="Mediumpurple" />
<br /><p color="orange">Good by</p><br /><input type="field" value="hello" />&nbsp;</body>}







macros:[
"&amp;" "&" 
"&lt;" "<" 
"&gt;" ">" 
"&quot;" {"} 
"&auml;" "ä" 
"&Auml;" "Ä" 
"&ouml;" "ö" 
"&Ouml;" "Ö" 
"&uuml;" "ü"
"&Uuml" "Ü" 
"&szlig;" "ß" 
]
histobj: []
markup-hexcolors: func [Dialect-colors] [
    foreach [word-color with-hexcolor] incolor-series [replace/all Dialect-colors word-color :with-hexcolor]
]
incolor-series: to-hash [
   "Aliceblue" "#F0F8FF"  
   "Antiquewhite" "#FAEBD7"
   "Aqua" "#00FFFF"
   "Aquamarine" "#7FFFD4"   
   "Azure" "#F0FFFF"
   "Base-color" "#8F7F6F"
   "Beige" "#FFE4C4"
   "Bisque" "#FFE4C4" 
   "Black" "#000000" 
   "Blueviolet" "#8A2BE2"
   "Blanchedalmond" "#FFEBCD"
   "Brown" "#A52A2A"
   "Brick" "#B22222"
   "Burlywood" "#DEB887"    
   "Cadetblue" "#5F9EA0"  
   "Chartreuse" "#7FFF00" 
   "Coal" "#404040"
   "Coffee" "#4C1A00"
   "Chocolate" "#D2691E"  
   "Coral" "#FF7F50"
   "Cornflowerblue" "#6495ED" 
   "Cornsilk" "#FFF8DC" 
   "Crimson" "#DC143C" 
   "Cyan" "#00FFFF"  
   "Darkblue" "#00008B" 
   "Darkcyan" "#008B8B"
   "Darkgoldenrod" "#B8860B"
   "Darkgray" "#A9A9A9"
   "Darkgreen" "#006400" 
   "Darkkhaki" "#BDB76B"
   "Darkmagenta" "#8B008B"
   "Darkolivegreen" "#556B2F"
   "Darkorange" "#FF8C00"
   "Darkorchid" "#9932CC"
   "Darkred" "#8B0000"
   "Darksalmon" "#E9967A"
   "Darkseagreen" "#8FBC8F"
   "Darkturquoise" "#00CED1"
   "Darkslateblue" "#483D8B"
   "Darkslategray" "#2F4F4F"
   "Darkviolet" "#9400D3"
   "Deepskyblue" "#00BFFF"   
   "Dimgray" "#696969"
   "Firebrick" "#B22222" 
   "Floralwhite" "#FFFAF0"
   "Forest" "#003000"
   "Forestgreen" "#228B22"
   "Fuchsia" "#FF00FF"
   "Gainsboro" "#DCDCDC"
   "Ghostwhite" "#F8F8FF"
   "Gold" "#FFCD28"
   "Goldenrod" "#DAA520"  
   "Gray" "#808080"  
   "Green" "#00FF00"
   "Greenyellow" "#ADFF2F"  
   "Honeydew" "#F0FFF0"  
   "Hotpink" "#FF69B4"  
   "Indianred" "#CD5C5C"  
   "Indigo" "#4B0082"  
   "Ivory" "#FFFFF0"  
   "Khaki" "#F0E68C"  
   "Lavender" "#E6E6FA"  
   "Lavenderblush" "#FFF0F5"  
   "Lawngreen" "#7CFC00"  
   "Lemonchiffon" "#FFFACD"  
   "Lightblue" "#ADD8E6"  
   "Lightcoral" "#F08080"  
   "Lightcyan" "#E0FFFF"  
   "Lightgoldenrodyellow" "#FAFAD2"  
   "Lightgreen" "#90EE90"  
   "Lightgrey" "#D3D3D3"  
   "Lightpink" "#FFB6C1"   
   "Lightsalmon" "#FFA07A"  
   "Lightseagreen" "#20B2AA"  
   "Lightskyblue" "#87CEFA"  
   "Lightslategray" "#778899"  
   "Lightyellow" "#FFFFE0"  
   "Lime" "#00CD00"  
   "Limegreen" "#32CD32"  
   "Linen" "#FAF0E6" 
   "Leaf" "#008000"
   "Magenta" "#FF00FF" 
   "Maroon" "#800000"
   "Mint" "#648874"
   "Mediumauqamarine" "#66CDAA"  
   "Mediumblue" "#0000CD"  
   "Mediumorchid" "#BA55D3"  
   "Mediumpurple" "#9370D8"  
   "Mediumseagreen" "#3CB371"  
   "Mediumslateblue" "#7B68EE"  
   "Mediumspringgreen" "#00FA9A"  
   "Mediumturquoise" "#48D1CC"  
   "Mediumvioletred" "#C71585"  
   "Midnightblue" "#191970"  
   "Mintcream" "#F5FFFA"  
   "Mistyrose" "#FFE4E1"    
   "Moccasin" "#FFE4B5"  
   "Navajowhite" "#FFDEAD"  
   "Navy" "#000080"  
   "Oldrab" "#484810"
   "Olive" "#808000"  
   "Olivedrab" "#688E23"  
   "Orange" "#FFA500"
   "Orangepumpkin" "#FFA500"  
   "Orangered" "#FF4500"  
   "Orchid" "#DA70D6"  
   "Papaya" "#FF5025"
   "Palegoldenrod" "#EEE8AA"  
   "Palegreen" "#98FB98"  
   "Paleturquoise" "#AFEEEE"  
   "Palevioletred" "#D87093"  
   "Papayawhip" "#FFEFD5"  
   "Peachpuff" "#FFDAB9"  
   "Peru" "#CD853F"  
   "Pewter" "#AAAAAA"
   "Pink" "#FFC0CB"  
   "Palepink" "#FFC0CB" 
   "Plum" "#DDA0DD"  
   "Powderblue" "#B0E0E6"  
   "Purple" "#800080" 
   "Rebolor" "#8E806E"
   "red" "#FF0000"  
   "Rosybrown" "#BC8F8F"  
   "Royalblue" "#4169E1"  
   "Saddlebrown" "#8B4513"  
   "Salmon" "#FA8072"  
   "Sandybrown" "#F4A460"  
   "Seagreen" "#2E8B57"  
   "Seashell" "#FFF5EE"  
   "Sienna" "#A0522D"  
   "Silver" "#C0C0C0"  
   "Sky" "#A4C8FF"
   "Skyblue" "#87CEEB"    
   "Slateblue" "#6A5ACD"  
   "Slategray" "#708090"  
   "Snow" "#FFFAFA"  
   "Springgreen" "#00FF7F"  
   "Steelblue" "#4682B4"  
   "Tan" "#D2B48C"  
   "Teal" "#008080"  
   "Thistle" "#D8BFD8"   
   "Tomato" "#FF6347"  
   "Turquoise" "#40E0D0"  
   "Violet" "#EE82EE"  
   "Water" "#506C8E"
   "Wheat" "#F5DEB3"
   "White" "#FFFFFF"
   "Whightsmoke" "#F5F5F5"  
   "Yellow" "#FFFF00"  
   "YellowGreen" "#9ACD32" 
   "Blue" "#0000ff"
   "amp;" "&&" 
    "lt;" "<" 
    "gt;" ">" 
    "quot;" {&"} 
    "auml;" "&ä" 
    "Auml;" "&Ä" 
    "ouml;" "&ö" 
    "Ouml;" "&Ö" 
    "uuml;" "&ü"
    "Uuml" "&Ü" 
    "szlig;" "&ß"
    "&nbsp;" " "
    "&&" "&"
    "!--" ""
    "%100" "%99"
    "100%" "99%"
    <head> <body background-color="#FFFFFF" text="#000000">
    "backdrop-color" "background-color"
    "<div>" {<div width="500">}
    "<p>" {<p width="500">}
    "<table>" {<table width="500">}
    "<li>" {<li width="500">}
    "<p>" {<p width="500">}
    "<tr>" {<tr width="500">}
    {a# } <a > { #a} </a>
   ]

   
markup-DTD: func [DTD] [
    foreach [doc-tag with-definition] in-dtd [replace/all DTD doc-tag with-definition]
]

in-dtd: [
    "!--" ""
    "64-" "64 "
    "&nbsp;" " "
    "&#" " "    
    "%100" "%99"
    "100%" "99%"
    <body> <body background-color="#FFFFFF" text="#000000">
    "body bgcolor" "body background-color"
    ]

get-color: does [either error? try [
    baseclr: to-tuple debase/base baseclr 16] [this-color?] [this-color: any [baseclr this-color]]
]

color=: func [this-color][
    parse to-string this-color [(baseclr: "") to "#"
    copy baseclr to end]  
    this-color?: txt-clr
    either find baseclr "#" [remove baseclr get-color][this-color: any [attempt [to-tuple this-color]txt-clr]]
]
   
bgcolor=: func [this-color][
    parse to-string this-color [(baseclr: "") to "#"
    copy baseclr to end] 
    this-color?: bkclr
    either find baseclr "#" [remove baseclr get-color][this-color:  any [attempt [to-tuple this-color]bgclr]]
]

remove-tail-char?: func [in-node element][ =: :equal?
                   foreach char element [
                   if char = back tail to string! in-node[
                   remove back tail in-node]
                   ]
]

remove-head-char?: func [in-node element][ =: :equal?
                  type: type? in-node 
                  foreach char element [
                  all [char = any [first to-string in-node form first in-node]
                  to type trim to-string any [attempt [remove in-node] remove form in-node]]
                  ]	  
]

quote-node-attributes: does [with-these-attributes: copy ""
 
remove-tail-char? in-node-element "/"

this-node: form find/match in-node-element node-name: first parse/all in-node-element { =">}

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
            ] replace this-node style-obj *style.node)]
]

foreach part replace/all this-node: parse/all this-node {<{} __,=":;[]>} [""] [] [
            part: any [if find/match part "'" [
            replace/all part "'" ""] part ]
            strip-obj-chars-from part ["  " " " {,} " " "&&" "://" ". " "."
            {=null} {=""} "'" "" {""} "" "none" ""]
            append with-these-attributes mold form part
            ]
]
 
create-tag-element: func [these-attr][
            in-attribute-blk: to-block these-attr 
            foreach [attr-name attr-value] in-attribute-blk [
            replace in-attribute-blk attr-name to-word attr-name
            attempt [trim attr-value]
            ]
            attempt [insert in-attribute-blk to-word trim/all strip-chars-from node-name none]
            data-node: build-tag in-attribute-blk 
]

this-width: 100

div: prg: tbl: tds: hd: lst: ul: spn: fnt: 0
img: hrl: fld: btn: txt-btn: hdn: chk: rdo: txt-sz: width=: 0
Dialect: "" 

parent-x: para-x: div-x: tbl-x: hr-x: hr-xy: face-x: tdx: x-size: gt-str-sz: 0
slf: child: use-methods: last-node: with-these-attributes: ""
styles: .style: ""
imgurl: go-here: copy [] 
parent-sz: font-size=: str-sz: 0
DOM: face-styles: "" fnt-styles: [] fnt-style: ""
data-node: face-node: node-name: node-type: tag-node: tag-head: text-node:   
in-parent?: in-node?: end-tag-token?: slf*: none

div_clr: p_clr: tb_clr: tr_clr: td_clr: ul_clr: li_clr: f_clr: b_clr: i_clr: clr: txt-clr: border=: none 

div_bgclr: p_bgclr: tb_bgclr: tr_bgclr: td_bgclr: ul_bgclr: li_bgclr: f_bgclr: b_bgclr: i_bgclr: bgclr: bkclr: none 
fnt-nm: "" 

.border?: border?: does [if not none = border= [
                    border: to-block foreach [a b]["(" "" ". " "." ")" ""] [replace/all form border= a b] 
                    append face-styles to-string reduce [ 
                    to-path reduce [slf 'edge 'size] ": " either attempt [pair: first find border pair!][pair][0x0] " "
                    to-path reduce [slf 'edge 'color] ": " clr: first any [find border tuple! 0.0.0] " show " slf " "] ]
                    
            ]
.color?: color?: does [append face-styles to-string reduce ["foreach fclr " to-path reduce [slf 'pane] " [if clr != fclr/effect/draw/pen [fclr/effect/draw/pen: " clr " show fclr]] "]] 
                ] 
.bgcolor?: bgcolor?: does [append face-styles to-string reduce ["foreach clr " this: to-path reduce [slf 'pane] " [if bgclr != " to-path reduce [slf 'color] " [clr/color: " bgclr " ] show clr] " slf "/color: " bgclr " show " slf " "]
                ] 
.font-size?: font-size?: does [if none != font-size= [append face-styles to-string reduce [
" foreach fnt " to-path reduce [slf 'pane] { [ if error? try [fnt-style: to-word fnt/effect/draw/font][][fnt-style: font_] }
join fnt-style font-size= {: make face/font any [attempt [font_]attempt[b.]] fnt/effect/draw/font: } join fnt-style font-size= " "
join fnt-style font-size= {/size: } 
font-size= " show fnt ]" ] ]
] 
.font-style?: font-style?: does [if font-style= [append face-styles to-string reduce [" foreach fnt " to-path reduce [slf 'pane] " [fnt-style: font_ *fnt: fnt/effect/draw replace *fnt select *fnt fnt-style/style " font-style= " show fnt ]"]]font_/style: none]         
    
.width?: width?: does [attempt [append face-styles to-string reduce [" " width=: to-path reduce [slf 'size 'x] ": " face-x/x: any [face-x width=] " show " slf " "]]]           



            
select-this: func [this-token][
            do select tag-tokens reduce this-token
            ]

              
tag-tokens: to-hash [
            body [bgclr: clr: none clear-colors in-parent?: false][{ backcolor } bkclr { backdrop } imgurl " effect [merge] " {below across } ]
            /body [][{}]
            div [parent-sz: div-x: face-x div_clr: clr div_bgclr: bgclr divs: divs + 1][{ below across space 10 }]
            /div [face-x: div_clr: div_bgclr: none ][{ close. } div-x " " div_bgclr { edge [] below }] 
            area [ar-x: any [face-x 100x50]][{ below across area #text } ar-x " "]
            /area [ar-x: face-x: none][{ close. } bgclr " "]
            textarea [ar-x: any [face-x 100x50]][{ below across area #text } ar-x " "]
            /textarea [ar-x: face-x: none][]
            p [parent-sz: para-x: face-x p_bgclr: bgclr p_clr: clr append main { below across } prg: prg + 1][{ below across } ]
            /p [p_bgclr: p_clr: face-x: none border?][{ close. } para-x " " p_bgclr { edge [] }]
            li [face-x: any [size= none] li_clr: any [clr ul_clr] li_bgclr: any [bgclr ul_bgclr txt-clr] lst: lst + 1][{ space 0 across box 16x20 } li_bgclr 
            { effect [draw [fill-pen } li_clr { pen } li_clr { circle 3x8 2]] }]
            /li [face-x: li_clr: li_bgclr: bgclr: clr: none ][{ close. below across }]  
            ul [in-parent?: false ul_bgclr: bgclr ul_clr: clr bgclr: clr: none ul: ul + 1][" across "]
            /ul [ul_bgclr: ul_clr: bgclr: clr: none clear-colors][{ close. }] 
            tbody [tbl: tbl + 1][]
            /tbody [][{}]
            /table [parent-sz: tbl-x: tb_clr: tb_bgclr: bgclr: clr: none][{ close. }  " " tb_bgclr " edge [color: clr size: 1x1] "]
            table [parent-sz: tbl-x: face-x face-x: none get-colors tb_clr: clr tb_bgclr: bgclr tbl: tbl + 1][{ guide }]
            td [parent-sz: tdx: any [face-x tbl-x] td_bgclr: bgclr td_clr: clr get-colors tds: tds + 1][{ across }]
            /td [td_bgclr: td_clr: parent-sz: tdx: none][{] } tdx " " td_bgclr { edge [color: bgclr size: 1x1 effect [ibezel]] }]
            tr [tr_bgclr: bgclr tr_clr: clr get-colors][{ across space 0 }]
            /tr [tdx: tb_clr: td_clr: tr_bgclr: tr_clr: td_bgclr: td_clr: bgclr: clr: none][{ return }]
            b [to-font 'b. b_bgclr: bgclr b_clr: clr get-colors][face-node: { space 0 box #bgclr #string-size effect [draw [pen #clr font #font text #text ]] }]
            i [to-font 'i. i_bgclr: bgclr i_clr: clr get-colors][face-node: { space 0 box #bgclr #string-size effect [draw [pen #clr font #font text #text ]] }]
            a [to-font 'u. get-colors attempt [go-here: to-url styles/href=]][]
            /b [remove-font 'b. b_clr: b_bgclr: none][]
            /i [remove-font 'i. i_clr: i_bgclr: none][]
            /a [remove-font 'u. remove-style ][{ [attempt [markup: read } go-here { update clear Dialect html/text: } go-here { show html] ] }]
            font [f_bgclr: bgclr f_clr: clr get-colors][{ space 0 box #bgclr #string-size effect [draw [pen #clr font #font text #text ]] }]
            /font [f_clr: f_bgclr: none remove-style][{ }]
            span [f_clr: any [clr txt-clr]bgclr: any [bgclr bkclr]][{ space 0x20 box #bgclr #string-size effect [draw [pen #clr font #font text #text ]] }]
            /span [face-x: f_clr: f_bgclr: none remove-style][]
            br [face-x: none clear styles clear-colors ][{ below across }]
            button [btn-sz: size= btn: btn + 1][{ button } btn-sz " " value= " font-color " clr " " bgclr " [" onclick= "] "]
            btn [ btn-sz: size= btn: btn + 1][{ btn } btn-sz " " value= " font-color " clr " " bgclr " [" onclick= "] "]
            text [txt-sz: size= fld: fld + 1][{ field } value= { edge [size: 1] effect [draw [pen silver line-width 1 box ]]  font-color } clr " "]
            field [fld: fld + 1][{ field } value= { edge [size: 1] effect [draw [pen silver line-width 1 box ]]  font-color } clr " "]
            search [btn-sz: size= ][{ field } value= " " btn-sz " edge [size: 1] effect [draw [pen silver line-width 1 box ]]  font-color " clr " "]
            select [btn-sz: size= in-parent?: false][{ choice }]
            submit [btn-sz: size= btn: btn + 1][{ button } btn-sz " " value= " " clr " [" onclick= "] "]
            password [btn-sz: size= fld: fld + 1][{ field } value= " " btn-sz " edge [size: 1] effect [draw [pen silver line-width 1 box ]]  font-color " clr " "]
            option [][{ #text }]
            /option [][]       
            hidden [hdn: hdn + 1][""]
            input [size=: any [size= []] fld: fld + 1]['field " " value= { font-color } clr " " ]
            check [chk: chk + 1][{ space 12 check }]                       
            checkbox [chk: chk + 1][{ space 12 check }]                       
            radio [rdo: rdo + 1][{ radio space 12 } ]
            H1 [in-parent?: false hd: hd + 1][{ below text }]
            H2 [in-parent?: false hd: hd + 1][{ below text }]
            H3 [in-parent?: false hd: hd + 1][{ below H2 }]
            H4 [in-parent?: false hd: hd + 1][{ below H3 }]
            H5 [in-parent?: false hd: hd + 1][{ below H4 }]
            H6 [in-parent?: false hd: hd + 1]{ below text }
            /H1 [ remove-style]{ font-size 32 below across }
            /H2 [ remove-style]{ font-size 24 below across }
            /H3 [ remove-style]{ below across }
            /H4 [ remove-style]{ below across }
            /H5 [ remove-style]{ below across }
            /H6 [ remove-style]{ font-size 10 below across }
            hr [ hrl: hrl + 1][{ panel [ box } clr " " (as-pair hr-x - .5 1) { bevel 2 pad 0x-11 box } bgclr " " (as-pair hr-x - .5 2){] below across }]
            /hr [in-parent?: false ][{ close. below across } ]
            strong [to-font 'b. b_clr: clr b_bgclr: bgclr get-colors][{ space 0 box #bgclr #string-size effect [draw [pen #clr font #font text #text ]] }]
            /strong [remove-font 'b. b_clr: b_bgclr: none][]
            img [img: img + 1][{ image } img-url " " face-x " "]
            newline [""][{ below across }]
            style-obj-chars ["<" "" {style="} " " {style=} " " " : " { "} ": " { "} ":" {*"} " " {__} {=""} { " " }  "=" {*"} ";" {"*} {""} {"} { "} {"} {*"} { "} 
            {"*} {" } " >" "" ">" "" "rgb" "" {__"} {"} {" "} {"} "," "."]
            elemt-chars ["{" "}" {"} "(" ")" "/" "." "[" "]" "," ":" ";" "," "="]
            obj-chars [":" " " ";" " " "," " " "=" " "]
            ]


parent-width: 0
parse-html: func [Dialect][
    markup-DTD Dialect
    bkclr: none 
    return-parent-width: does [
    these-children: copy children 
    replace/all replace/all children "^/" "" <newline> " "
    replace/all Dialect "> " ">" 
    in-parent-node: load/markup children str-sz: 0 children: none
    foreach txt-node in-parent-node [ 
    if all [string! = type? txt-node find txt-node " "][str-sz: str-sz + string-size? txt-node
    replace in-parent-node txt-node txt-node*: parse txt-node " "  
    ]
    quote-node-attributes	
    create-tag-element with-these-attributes 
    parent-width: get-size select in-attribute-blk 'width
    if parent-width = 0 [switch node-name [
                                         "div" [parent-width: 650]	
                                         "p" [parent-width: 650]
                                         "p" [parent-width: 650]
                                         "td" [replace/all in-parent-node "<br" "<span " parent-width: 650]
                                         "li" [parent-width: str-sz]
                                         ]if [parent-width > 650 or parent-width = 0][parent-width: 650]
    ]
    replace Dialect in-node-element data-node 
]
    
txt-sz: 0        
foreach child-element in-parent-node [ 
        with-these-children: [] each-node: type? child-element 
        either string! = each-node [string-size? child-element face-x: face-x + 9 
        txt-sz: txt-sz + face-x text-face: none
        either txt-sz <= parent-width [append with-these-children child-element][
        txt-sz: face-x append with-these-children reduce [<newline> child-element]] 
        ][append with-these-children child-element if find child-element "br" [txt-sz: 0]]
]       
        size-x: txt-sz: 0 
        replace Dialect these-children form with-these-children
in-attribute-blk: with-these-children: in-node-element: these-children: child-element: children: in-parent-node: none
        ;replace/all replace/all Dialect "<<" "<" ">>" ">"
]
replace/all Dialect "> " ">"

    
validate-or-remove: func [with-end-tag][
        either none = children [replace Dialect in-node-element " "][
        if children [if not find children with-end-tag [replace Dialect children children: join children with-end-tag
        ] if </td> != end-tag [attempt [return-parent-width]]] 
        ]
]

P?: UL?: inP?: none

in?: [any "<div" | </body>]


parse Dialect [some[		
        to "<div" copy in-node-element thru ">" 
        copy children thru </div>
        (end-tag: </div> validate-or-remove </div>)
        ]skip       
] 


parse Dialect [some[		
        to "<div" copy bad-node-element thru ">" 
        copy children in?
        (if none != children [replace Dialect bad-node-element ""])
        ]skip       
]

parse Dialect [some[		
        to "<div" copy in-node-element thru ">" 
        copy children [thru </div> | to "<div" | to </body>]
        (end-tag: </div> validate-or-remove </div>)
        ]skip       
] 


in-node?: []
in-node?: [any  "<table" | "</table" | "</body"]        
        
parse/all Dialect [some[(children: none)to
        "<table" copy bad-node-element thru ">"
        copy children in-node? 
        (if none != children [replace Dialect bad-node-element ""])
        ]skip   
]

parse/all Dialect [any[(children: none)
        to "<table" copy in-node-element thru ">"
        copy children [thru </table> | to "<table"] 
        (end-tag: </table> validate-or-remove </table>)
        ]skip   
]


UL?: any [UL? insert replace UL?: copy in-parent_elem-type! [| "<ul" | "<li"] [] 'to]

        parse/all Dialect [some[(children: none)
        to "<ul" copy in-node-element thru ">"  
        copy children [thru "</ul>" | to "<ul" | UL? | to "<br" | to "</body>"] 
        (end-tag: </td> validate-or-remove "</ul>")
        ]skip
]       

parse/all Dialect [some[(children: none)to
        "<tr" copy in-node-element thru ">"
        copy children [thru "</tr>" | to "<tr" | to "</table"]
        (end-tag: </td> validate-or-remove </tr>)
        ]skip   
]


    
 
P?: any [P?  append append P?: copy in-parent_elem-type! [| "<h" | "</" |] out-parent_elem-type!]
inP?: any [inp? all [append append inP?: [any]  P? [| "<fieldset"] replace/all inP? [|] [| to]]] 

replace/all Dialect "<p><p" "<p"

parse/all Dialect [some[(children: none)to 
        "<p" copy bad-node-element thru ">" 
        copy invalid-node inP?
        (if invalid-node [replace Dialect bad-node-element ""])
        ]skip       
]
            
parse Dialect [some[(children: none)to                  
        "<p" copy in-node-element thru ">" 
        copy children to "<p" 
        (end-tag: </td> validate-or-remove "</p>")        
        ]skip         
]       
    
parse Dialect [some[(children: none)to                  
        "<p" copy in-node-element thru ">" 
        copy children thru "</p>"  
        (end-tag: </p> validate-or-remove end-tag)        
        ]skip         
] 
          
parse Dialect [some[(children: none)to                  
        "<pre" copy in-node-element thru ">" 
        copy children [thru "</pre>" | to </p>] 
        (end-tag: </pre> validate-or-remove end-tag)        
        ]skip         
]    
    
parse/all Dialect [some[(children: none)to 
        "<li" copy in-node-element thru ">" 
        copy children thru "</li>" 
        (end-tag: </li> validate-or-remove end-tag)
        ]skip
]

parse/all Dialect [some[(children: none)to 
        "<li" copy in-node-element thru ">" 
        copy children [thru "</li>" | to "<li>" | to "</UL>"] 
        (end-tag: </li> validate-or-remove end-tag)
        ]skip
]



parse/all Dialect [any[(children: none)
        to "<td" copy bad-node-element thru ">"
        copy children any ["</" | "<td" | "<table" | "<div"] 
        (if none != children [replace Dialect bad-node-element ""])
        ]skip   
]

parse/all Dialect [any[
        ["<td" copy in-node-element  thru ">"
        copy children [thru "</td>" | [to "</tr" | "<tr" | "</table" | "<table"]]
        (validate-or-remove "</td>" return-parent-width)
        ]
		]skip   
]

{
|
        [to "<td" copy in-node-element  thru ">"
        copy children to "<td" 
        (end-tag: </td> replace children "<br" "<span" validate-or-remove)
        ]

parse/all Dialect [some[to 
        "<a " copy element thru ">" 
        (this: copy element 
        foreach [a b][
            "?" {" } "-" "_" "=" {="} "&" { " } "+" "_" "%25" "_" ">" {">} {" ">}  {">} {""} {"}][replace/all this a b
            ]
    replace Dialect element this)
        ]skip   
]}
    recycle/off recycle/on 
]

make-face-obj: func [][
                self: mold to set-word! to string! reduce [last-node: copy node-name select-this tag-token: to word! node-name] 
                face-obj: reduce first skip find tag-tokens tag-token 2
                slf: to word! first slf: parse self ":" 
                foreach style-request [font-style? border?][attempt [do style-request]]
]

get-size: func [this.width][in-size: none this.width: form this.width
            *y: 20 attempt [*y: face-x/y]  
            attempt [parent-x: face-x/x] 
            attempt [parent-y: face-x/y] 
            hr-x: any [attempt[hr-xy/x]hr-xy]
        parse this.width [[(unit-type: "none") to #"%" (unit-type: "%") | to "px" (unit-type: "px") | to "pt" (unit-type: "pt")]to end]
            if error? try [to-integer replace this.width unit-type ""][this.width: 0  unit-type: "none"]
        switch unit-type [
        "%" [replace in-size: parse this.width "%" "" []
            if empty? in-size [in-size: to-block mold form length? value=]
            either 1 = length? in-size/1 [insert in-size/1 ".0" percent-size: to-decimal load in-size/1][insert in-size/1 "." percent-size: to-decimal load in-size/1]
            this.width: as-pair to-integer percent-size * either find/any ["button" "submit"] node-name [
            any [parent-x string-size? value=]][any [600 - 10]]  *y]
        "px" [replace/all in-size: parse this.width "px" "" [] this.width: attempt [to-integer in-size/1]]
        "pt" [replace/all in-size: parse this.width "pt" "" [] this.width: attempt [to-integer in-size/1]]
        "none" [if in-size: attempt [to-integer this.width] [this.width: in-size]]
    ]
]
                
             
get-attributes: func [element-node][
                in-node-element: node-element: element-node 
                quote-node-attributes 
                create-tag-element with-these-attributes
                markup-hexcolors styles: next node: to-block child: data-node
                if all [use-methods not find child "." ][use-attr-as-methods yes]
                slf: to-word any [slf* node/1]      
                bkclr: any [bkclr bkclr: bgcolor= any [select styles 'background-color= "#ffffff"]]
                attempt [get-image styles/background-image= imgurl: img-url]
                bgclr: bgcolor= any [select styles 'bgcolor= select styles '.bgcolor=]
                txt-clr: any [ color= select styles 'text= txt-clr 0.0.0]
                clr: color= any [select styles '.color= select styles 'color= ]
                value=: form mold any [select styles 'value= ""]
                either parent-sz [parent-sz][parent-sz: as-pair 10 / string-size? value= 0]
                size=: hr-xy: any [get-size select styles 'size= 99.2]
                border=: attempt [styles/border=]  
                font-size=: any [get-size select styles 'font-size= ]
                font-style=: any [select styles 'font-style= ]
                either 0 != size= [size= ][size=: none]
                valign=: any [select styles 'valign= ""]
                width=: any [get-size select styles 'width= 0]
                height=: any [get-size select styles 'height= 20]
                either not find reduce [width= height=] 0 [face-x: as-pair width= height= ][
                either 0 != width= [face-x: width=][face-x: width=: height=: none]]
                alt=: any [select styles 'alt= ""]
                onclick=: any [attempt [to-word select styles 'onclick= ]]
                get-image select styles 'src=  styles: head styles 
                
                ] 
                
set-attributes: does [ 
        either empty? styles [
                =: :equal? get-attributes node-element
                foreach [attr attrv] next styles [(attempt [do load replace form attr "=" "?"])]
                do face-styles show page clear face-styles
                ][
                parse styles [some[ to word! attr: to string! (attempt [do load replace form copy attr "=" "?"])]skip] 
                ]    
                replace/all face-styles "node-elementjoin" ""       
                do face-styles show page clear face-styles =: :equal?
]            
                
                
get-colors: does [
                  clr: any [clr f_clr i_clr b_clr div_clr p_clr td_clr tr_clr tb_clr li_clr ul_clr txt-clr]  
                  bgclr: any [bgclr f_bgclr i_bgclr b_bgclr div_bgclr p_bgclr td_bgclr tr_bgclr tb_bgclr li_bgclr ul_bgclr bkclr]
                  ]
clear-colors: does [
                    div_clr: p_clr: tb_clr: tr_clr: td_clr: ul_clr: li_clr: f_clr: b_clr: i_clr: clr: none
                    div_bgclr: p_bgclr: tb_bgclr: tr_bgclr: td_bgclr: ul_bgclr: li_bgclr: f_bgclr: b_bgclr: i_bgclr: bgclr: none 
                    remove-font remove-style
                  ]
        
                         
get-input-type: func [in-form-element][ 
                if "button" = node-name [node-name: 'btn]   
                if "input" = node-name [node-name: first to block! node-type: find/match in-form-element {input type=}]
                if "" = node-name [node-name: "input"]
                node-name: form any [node-name "input"]
                ]
                
to-font: func [style?][
                insert fnt-styles style?
                ]

get-fnt-styles: func [][either not empty? fnt-styles [fnt-style: trim/all form sort unique fnt-styles][fnt-style: "font_"]
                replace main "#font" fnt-style
                ]               
string-size?: func [txt-string][text-face: layout/tight [text txt-string] face-x: text-face/size/x]
                
                
get-string-size: func [txt-string][txt-string: form txt-string
        
        any [attempt [face-x: face-x/x] face-x face-x: none]
        any [   
        if "b." = fnt-style [text-face: layout/tight [text txt-string bold font-size 16]
         
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        if "i." = fnt-style [text-face: layout/tight [text txt-string italic font-size 16]
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        if "u." = fnt-style [text-face: layout/tight [text txt-string underline font-size 16 ]
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        if "i.u." = fnt-style [text-face: layout/tight [text txt-string italic underline font-size 16]
        i./valign: 'top
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        if "b.i." = fnt-style [text-face: layout/tight [text txt-string bold italic font-size 16 ]
        b.i./valign: 'top
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        if "b.u." = fnt-style [text-face: layout/tight [text txt-string bold underline font-size 16 ]
        b.i./valign: 'top
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        if "b.i.u." = fnt-style [text-face: layout/tight [text txt-string bold italic underline font-size 16]
        b.i./valign: 'top
        either face-x [replace main "#string-size"  as-pair face-x 20][ 
        replace main "#string-size" as-pair text-face/size/x - 18 20 text-face: ""]
        ]
        ]
        any [attempt [face-x: face-x/x] face-x face-x: none]
        
        if find main "#string-size" [text-face: layout/tight [text txt-string font-size 16]
        replace main "#string-size" as-pair text-face/size/x - 12 20 text-face: ""]
        face-x: none
]

remove-style: does [
                    border=: parent-sz: width=: height=: div-x: para-x: font-size=: face-x: none bgclr: any [i_bgclr b_bgclr li_bgclr ul_bgclr td_bgclr tr_bgclr tb_bgclr p_bgclr div_bgclr bkclr] 
                    clr: any [b_clr i_clr li_clr ul_clr td_clr tr_clr tb_clr p_clr div_clr txt-clr]replace main "#text" ""
                    ]

remove-font: func [style?][
        replace/all fnt-styles style? []
        ]

url-address: "http://www.rebol.com"

get-image: func [img-src] [the.image: ""
img-src: any [img-src img-src: "image"]
switch img-src/1 [
#"h" [replace img-src "p/" "p:/" the.image: to string! reduce img-src]
#"/" [either img-src/2 = #"/" [the.image: to string! reduce ["http:" img-src]][the.image: to string! reduce [url-address img-src]]]
#"w" [the.image: to string! reduce ["http://" img-src]]
#"%" [the.image: to-file img-src ]
]
image-type: [".png" ".jpg" ".gif"]
either find the.image any image-type [img-url: load the.image] [img-url: the.image]
]

font_: make face/font [style: [] size: 16]

b.: make face/font [style: 'bold size: 16 align: 'center]
i.: make face/font [style: 'italic size: 16 align: 'center]
u.: make face/font [style: 'underline size: 16 valign: "top"]
b.i.u.: make face/font [style: [bold italic underline] size: 16 align: 'center valign: "top"]
b.i.: make face/font [style: [bold italic] size: 16 align: 'center]
b.u.: make face/font [style: [bold underline] size: 16 align: 'center valign: "top"]
i.u.: make face/font [style: [italic underline] size: 16 align: 'center valign: "top"]
back.: make face/font [ size: 25 align: 'top valign: 'top color: silver]

in-parent_elem-type!: make hash! ["<div" | "<p" | "<table" | "<ul" | "<li" | "<td" | "<area"]
out-parent_elem-type!: make hash! ["</div" | "</p" | "</table" | "</ul" | "</li" | "</td" | "</area"]
in-style_elem-type!: make hash! ["body" "tbody" "h1" "h2" "h3" "h4" "h5" "h6" "strong" "br" "span" "tr" "a" "font" "b" "i" "newline" "option"]
out-style_elem-type!: make hash! ["/h1" "/h2" "/h3" "/h4" "/h5" "/h6" "/strong" "/body" "/tbody" "/span" "/tr" "/a" "/font" "/b" "/i"]
input_elem-type!: make hash! ["button" | "input" | "img" | "hr" | "select"]
as-block_elem-type!: make hash! [ "address"  "article"  "aside"  "blockquote"  "canvas"  "dd"  "div"  "dl"  "dt"  
 "fieldset"  "figcaption"  "figure"  "footer"  "form" "h1" "h2" "h3" "h4" "h5" "h6"   
 "header"  "hr"  "li"  "main"  "nav"  "noscript"  "ol"  "p"  "pre"  "section"  
 "table"  "tfoot"  "ul"  "video"]

input-as: func [DSL Dialect][
    ;replace/all Dialect #"^/" "" 
    strip-obj-chars-from Dialect [{ <} "<" {> } ">"]
    
    switch DSL [html [markup-DOM Dialect parse-html markup layout-html markup
                     markup-DOM load join "[" replace html-markup? "}" "}]"
                     ] html-markup?: none 
                     ]
]

update: does [
html/text: "http://www.rebol.com"
url-address: url: "" 
main: "" 
url-type: ["com" "net" "org"]
foreach url.type url-type [
if find html/text url.type [
parse/all html/text [to "h" copy url-address thru url.type ]]
]
divs: prg: tbl: td: hd: lst: ul: spn: fnt:
img: hrl: fld: btn: txt-btn: hdn: chk: rdo: 0 
width=: txt-sz: x-size: 0x0

clear main 
clear face-styles
clear-colors
recycle/off recycle/on
view/new view-port
 input-as 'html markup
    replace/all main "none" ""
    replace/all main "font #font" " "
    replace/all main "9400D3"
    window: load main main: none
            

doc: ""   
doc: layout/offset/size window 0x0  800x2000  attempt [clear do face-styles]
page/pane: doc page/pane/size/x: 1000
update-panel page s1 s2
page/color: bkclr show page
editor/text: markup show editor
{pagetitle: getnodename "title"
                
either find histobj pagetitle [][
append histobj reduce [pagetitle url]
]
}
]

layout-html: func [Dialect][
        
markup-DTD Dialect

replace/all in-html-markup: to-hash load/markup trim/lines Dialect  [" "] []

foreach data-node in-html-markup [of-data-node: data-node  
if string! = type? of-data-node [
            foreach [old new]["," "_." ";" "._" ][replace/all data-node old new]
            text-node: mold form trim data-node bgclr: clr: none 
            foreach part-of-node node: parse/all of-data-node " " [
                either none = attempt [load part-of-node][append html-markup? to-word rejoin ["<" part-of-node ">"]
                    ][append html-markup? rejoin [" " part-of-node " "]]
                ]
            foreach [old new]["_." "," "._" ";" ][replace/all text-node old new]    
            get-colors  
            either true = in-parent? [
            either find main "#text" [
                replace main "#text" text-node replace replace main "#bgclr" bgclr "#clr" clr
                get-fnt-styles gt-str-sz: get-string-size text-node
                ][
                append main reduce [" space 0 box " bgclr " " "#string-size effect[draw[pen " clr " font #font text " text-node "]] "]
                        face-x: none    get-fnt-styles get-string-size text-node text-node: none 
                  ]
                ][
                  if find main "#text" [replace main "#text" reduce [" " text-node " "]
                  get-fnt-styles get-string-size text-node text-node: none
                  ]
                  if all [text-node fnt-styles] [append main reduce [" box " bgclr " " "#string-size effect[draw[pen " clr " font #font text " text-node "]] "]
                  get-fnt-styles get-string-size text-node text-node: none
                  ]
                  if text-node [append main reduce [" " text-node " font-size 16 " clr " " bgclr " "]]
                  replace/all replace/all main "#bgclr" bgclr "#clr" clr
                  face-x: text-node: node: none 
                ]  
]
out-parent?: []
out-style?: []
html-markup?: end-tag-token?: {}

make-dom-element: does [append html-markup? reduce [" "
                            mold to-set-word node-name { [}]
                            if find data-node " " [
                            attributes: find data-node select data-node node-name
                            append html-markup? reduce [mold to-string attributes " "]
                            ]
]               

close-parent: func [][
            closed: reduce first skip find tag-tokens end-tag-token?  2 
            insert tail main closed]
            
close-dom-element: does [append html-markup? reduce [mold end-tag-token? {] }]]

        if tag! = type? of-data-node [ 
            either (length? parse/all of-data-node " ") > 1 [
            get-attributes of-data-node
            get-colors][node-name: to string! data-node]
            
        if find in-parent_elem-type! join "<" node-name [
            make-dom-element
            insert out-parent? to-refinement copy node-name 
            in-parent?: true make-face-obj  
            insert tail main reduce [" " self " panel [ pad 1 " face-obj " "]
            ]
]           
            
        if find input_elem-type! node-name [ 
            make-dom-element
            get-input-type of-data-node 
            {if found? this-parent: find/any [/p /li /ul] out-parent? [
            close-parent  
            select-this end-tag-token?: this-parent 
            replace out-parent? first this-parent []
            replace main "close." {] }
            remove-style in-parent?: false
            ]}
            in-parent?: false make-face-obj 
            insert tail main reduce [ 'space " " 12 " " self " " face-obj]
            append html-markup? {] }
            remove-style
            token?: end-tag-token?: none    
            
]           
        if find out-parent_elem-type! join "<" node-name [
            in-parent?: false 
            clear fnt-styles
            either find out-parent? end-tag-token?: load node-name [
            close-dom-element
            close-parent
            select-this end-tag-token?  
            replace/all main "close." {] }
            remove-style replace out-parent? end-tag-token? []
            ]["replace in-html-markup pick in-html-markup node []"]
            if find as-block_elem-type! form end-tag-token? [insert tail main { below across }]
            end-tag-token?: none    
]
            
        if find in-style_elem-type! node-name [
            either any ["br" = node-name "newline" = node-name][][make-dom-element]
            insert out-style? to-refinement node-name
            select-this style-token?: to word! node-name
            either find main "#font" [][
            insert tail main reduce first skip find tag-tokens style-token? 2
            ]
            replace replace out-style? /br [] /newline []
            node-name: ""
]
        
        if find out-style_elem-type! node-name [
            in-style?: false
            if find out-style? style-token?: load node-name [
            select-this style-token?
            insert tail main reduce first skip find tag-tokens style-token? 2
            append html-markup? { ]}
            replace out-style? style-token? []
            style-token?: []
            ]
            ]
            
]       replace html-markup? "}]" "}"
        replace/all main "none" ""
        clear in-html-markup
]

       
node-list: .style: []
equal?: :=
DOM: DSL: html: window: end-tag: ""
data-node: parent-node: slf*: node: key: *key: *value: k: v: none 

.body: .hr: .p: .b: .i: .tr: .ul: .li: .area: .table: .td: .button: .input: .div: .font: .span: count: 0
array-obj!: node-obj: node-element: *variable: *node-name: node-name: *name: use-methods: attr-name: attr-value: none

check: func [select-this][return pick parse trim strip-chars-from form select-this none " " 1]

*get: func[this][ attempt [this]]

affix: func [code][*get insert code [clear] | code]

reappend: func [with this-data][append with to-block mold rejoin this-data]

rescind: func [variable][var form variable]

imply: func [with][do load strip-obj-chars-from mold with inferred] 

insert-this: func [put-this at-here][do head insert here: find copy key at-here put-this]

void: does [data-node: node-element: none slf*: "" count: 0]

as-data-node*: func [data-node][to block! data-node]

as-series*: func [series with-chars][to block! strip-obj-chars-from form series with-chars]

as-sequence*: func [series with-this][
        to-block mold to-block strip-obj-chars-from strip-obj-chars-from form series with-this none
]

clear-node-list: does [foreach [var node] node-list [
        attempt [set to-set-word var none]]clear node-list]

use*=*to-set-values: does [=: func [value][any [value]]]

use-attr-as-methods: func [maybe [logic!]][
        if no != maybe [
		strip-obj-chars-from node-element [{" } {" .} ".." "."]]
        replace node-element " " " ." use-methods: off
]

elemt-chars: none 
strip-chars-from: func [node-name elemt-chars][
        foreach char elemt-chars: any [elemt-chars 
        ["<" ">" "{" "}" "(" ")" {"} "/" "." "[" "]" "," ":" ";" "," "=" "`"] 
        ][
        replace/all node-name char " "
        ]   
]
obj-chars: +char: none
strip-obj-chars-from: func [node-name obj-chars][
        attempt [replace replace node-element "={" {="} ";}" {;"}]
        attempt [trim form node-name if equal? #"^"" node-name/1 [remove node-name]
        foreach [-char +char] obj-chars: any [obj-chars [#"^/" " "
        "  " " " {" , "} {" } {", "} {" } "," " " {" "} {" } {" : "} {: "}
        {":"} {: "} {":} {:} { " } "" {"[["} {"[[" "} "{" "[" "}" "]" {""}
        {"} {  "} "" " : " ": " ":" " " { =} {=} {=} " " "'" "" "#" ""
        "<" "" ">" "" "`" "" "_" " "]
        ][
        replace/all node-name -char +char
        ]]
]

document.getnodename: func [request][document. getnodename request]

document.: func [request-as][
        DOM: head DOM use*=*to-set-values 
        any [ 
        all [data-node node-name: check node-element: data-node/1] 
        all [insert data-node: [] node-element: request-as node-name: check data-node/1
        ]]
        any [all [equal? tag! type? node-element
        strip-obj-chars-from node-element ["{" "" "[" "" "}" "" "]" ""]]
        node-element]
        either count >= 1 [me: parse slf* ":"
        var replace node-element node-name any [
        attempt [first to-block me] slf*]]
        [var node-element] me: parse slf* join ":" count .style: :array-obj!
        attempt [replace node-element first parse node-element " :" 
        last to-block me]
        return node-element count: 0
]
                
.return-tag-node: func [node-name][DOM: head DOM 
        node: either equal? word! type? node-name [
        either any [attempt [empty? node-element] equal? none node-element]
        [select node-list form node-name][node-name]][node-name]  
        any [
        all [equal? node none print rejoin [{node-name: (} node-name ") not in node-list."]]
        equal? tag! type? node-element: node
        attempt [node-element: data-node: build-tag 
        to-block strip-obj-chars-from form node none]
        set 'node-element node]node-name: check node-element 
        return probe node-element
]

getnodename: func [node-name][
        DOM: head DOM =: :equal? slf*: data-node: [] node-element: none
        either block! = type? node-name[.return-tag-node node-name][
        node-name: to block! strip-chars-from form node-name none
        count: any [attempt [count: pick find node-name integer! 1]1]
        nodename: to-word join  "." array-obj!: node-name/1 
        any [attempt [repeat ? count [data-node: first DOM: next node: find DOM nodename]]
        all [print rejoin [{node-name: (} node-name/1 "." count ") not found."]count: 0]
        ]
        slf*: join node-name/1 count
        ]
        if " " = data-node [data-node: form first DOM: next DOM]
        return either tag! = type? data-node/1 [node-element: data-node/1][node-element: data-node]
        	
]

getElementByTagName: func [Tag-Name selection [block!]][
        dom: head dom 
        repeat this count: first selection [
        node-element: first data-node: first dom: next find dom to-word join "." Tag-Name]
        if all [equal? true use-methods not find node-element " ."][use-attr-as-methods yes]
        use-methods: off slf*: join Tag-name count       
]

setnodename: func [old-name new-name][
        any [equal? this-name: check old-name check node-element getnodename old-name]
        any [equal? none not find node-element new-name try [
        replace node-element to string! this-name new-name 
        replace data-node to-tag join "/" this-name  to-tag join "/" new-name] 
        ]       
]
 
getattribute: func [attr-name][
        attr-value: none 
        print any [all [attr-value: array-obj!(attr-name) 
        [attr-name " " attr-value]
        ]["attribute: " attr-name " not found"]
        ]
]
 
setattribute: func [attr-name new-attr][
            *key: *value: none .style: array-obj!: 
            |: func [key] do compose/deep [body-of (to-get-word variable)] 
            any [
            all [.style((attr-name)) *value: *key `= (new-attr)]
            | [reappend [" " new-attr{="undefined"}]]
            print ["Must get a parent-node with this attribute: " attr-name]]
            obj-chars: [=[`=]]
            replace node-element form next parse variable reform ["*" count] next variable
            get-attributes node-element attempt [set-attributes]=: :equal?
]

setattributevalue: func [attr-name attr-value][
            *key: *value: none .style: array-obj!: 
            |: func [key] do compose/deep [body-of (to-get-word variable)] 
            any [
            all [.style((attr-name)) if *value [`= (attr-value)]]     
            | [reappend [" " attr-name{="}attr-value{"}]]
            print ["Must get a parent-node with this attribute: " attr-name]]
            obj-chars: [=[`=]]
            replace node-element form next parse variable reform ["*" count] next variable
            get-attributes node-element attempt [set-attributes]=: :equal?
]

look-deep-for: func [this from-this-parent][
            foreach in-child-tag-node from-this-parent [
            if all [tag! = type? child: in-child-tag-node find/any child this][
            insert data-node: [] node
            node-element: child slf*: rejoin [slf* ":" *name: first parse node-element " "]]
            if block! = type? node: in-child-tag-node [look-deep-for this in-child-tag-node]
            ]
]
            
getElementById: func [my-id][in-child-node: none count: 1
            id: copy join "id*" slf*: form my-id =: :equal?
            foreach in-parent-node dom [
            if block! = type? node: in-parent-node [look-deep-for id in-parent-node
            ]]
]

querySelecter: func [css-Selecter][in-child-node: none count: 1  
            id: rejoin [slf*: css-Selecter "*"] =: :equal?
            foreach in-parent-node dom [
            if block! = type? node: in-parent-node [look-deep-for id in-parent-node
            ]]
]


.innerHTML: func [with-html][
            some-children: copy/part next data-node find/last data-node tag!
            either equal? tag! type? node-element [
            any [all [empty? with-html some-children] replace data-node some-children with-html]
            ][print "The node-element has no innerHTML"]
]
            
var: func [var-data][node-element:  variable: "" .style: none
            any [
            attempt [variable: first parse node-element: var-data "=:, "]
            attempt [if equal? block! type? var-data [variable: first node-element: var-data]] 
            attempt [variable: var-data node-element: ""]
            ]
            use*=*to-set-values node-name: variable: join "*" to-string variable obj-chars: []
            replace node-element node-name nodename: first parse form node-name form count
            either empty? node-element [any [find node-list variable append node-list reduce 
            [variable node-element: any [attempt [do :variable] ""]]]] 
            [any [find node-list node-name append node-list reduce [form variable node-element]]] 
            set to-word variable array-obj!: func [key] compose/deep copy get-array-obj!
            any [find variable "." set to-word trim/all reform [variable "."] :array-obj!]
            use-methods: off *variable: none if equal? word! type? var-data [clear node-element]()
]

get-array-obj!: [
            node-element: select node-list variable: (form variable)
            |: &.: :array-obj! strip-obj-chars-from node-element ["={" {="} ";}" {;"}]
            attempt [all [inline: find/any node-element { style=*"}
            replace node-element inline
            replace/all replace replace inline {"} "{" {"} "}" "  " ": "]]
            if all [not find form node-element "1:" tag! != type? node-element][
            all [equal? (length? parse form node-element ":= ,") 1
            node-element: join {#1: } node-element ]]
            any [
            if empty? form key [strip-obj-chars-from node-element ["={" {="} ";}" {;"}]
            array-obj!: replace body-of :array-obj! select body-of :array-obj! [variable:] variable 
            |: array-obj!: func[key] array-obj!
            return any [
            if equal? tag! type? node-element [node-element]
            attempt [trim find/tail copy head node-element first parse node-element " ,"]
            next node-element]*key: key: *value: value: none
            ]
            if all [*key: first to-block key not find node-element rejoin [" " *key " "]
            equal? integer! type? *key][
            values: any [attempt [parse head node-element "<=;,`#: []>"]
            load strip-obj-chars-from mold node-element none]
            keys: length? replace/all values [""][]
            if odd? length? values [remove values]
            any [equal? 1 *key *key: *key + *key - 1]
            *value: any [*value: select values *key: pick values *key *value ]
            if *value [print ["*key:" *key  " *value: " *value: *value ]]
            node-name: keys: none
            ]
            if equal? path! type? key[]
            if equal? refinement! type? key[attempt [do replace/all form key "." "/."]]
            if find ["url!" "email!" "tag!" "refinement!"] mold type? key [
            attempt [key: to-string parse replace/all to-string  key "." "/." "/"]
            strip-obj-chars-from key [":" ":." "@" ": " ".." "."]
            replace/all from-method: parse key ".:" [""] []
            foreach key from-method [any [attempt [| to-block key] | mold key]]
            ]
            any [
            attempt [*value: load select/case parse strip-obj-chars-from copy node-element none none
            *key: trim head trim tail form key]
            attempt [*value: select/case load strip-obj-chars-from mold to-block node-element none *key: key]]
            any [
            attempt [do head append insert next copy key [node-element join] ""]
            attempt [if equal? string! type? key [do head replace copy key " " { node-element }]]]
            attempt [do load key] attempt [*get-methods key] attempt [do *get-expressions key none]
            if not find node-element key [*key: value: none obj-chars]]
]

new: func [previuos-node][as-variable: form copy variable
            with-element: do reform [previuos-node {""}]
            any [
            if find node-list double-variables: reduce [as-variable as-variable]
            [replace node-list double-variables []
            var reform [join as-variable ": " next load with-element]
            do reform [variable {""}]]
            if find node-list double-variables: reduce [as-variable to-word as-variable]
            [replace node-list double-variables []
            var reform [join as-variable ": " next load with-element]
            do reform [variable {""}]]
            if *variable [attempt [var reform [join *variable ": " next load with-element]
            do reform [*variable {""}]]]
            all [replace node-list [""] reform [join as-variable ":" next load with-element]
            do reform [as-variable {""}]]]
]

proto-type: func [as-object new-name][
            old-name: check as-object 
            append :as-object parent-url!: to-string reduce [new-name "::" new-name]
            var append replace replace node: copy head as-object
            old-name new-name parent-url! " " to-string reduce [" parent::" old-name]()
            				
]

*!: func [new-var][use*=*to-set-values
            either find node-list this: any [
            reduce [variable variable] 
            reduce [variable to-word variable]]
            [replace node-list this [] count: 0 
            var var-data: reform [new-var last this]
            ][strip-obj-chars-from node-element reduce [variable new-var "  " " "]
            slf*: rejoin [
            form new-var ":" node-name: new-var]
            data-node: none document. node-element]
]

.: func [value /local *val][either equal? block! type? *value [*val: copy *value
            any [
            if equal? integer! type? *key: first to-block value [
            any [equal? 1 *key *key: *key + *key - 1]
            attempt [do [value: select *value *key: pick *value *key *value: to-block value]]]
            attempt [*value: first next *value: find *value value]
            attempt [*value: head *value *value: next find *value value]
            attempt [*value: *val load value]]
            ][ do compose/deep reduce [*value [(load value)]]]
]

some: func [next-key][
            either obj-chars [translate next-key][
            foreach try-this next-key [
			all [equal? tag! type? try-this insert try-this  "'"]
            any [find-with: all [equal? block! type? try-this go-to: *key ]
            find-with: *key: *value: none]
            any [all [equal? *value none | try-this
            find node-element *key: any [try-this form try-this]
            function! != type? *key
            print ["*key: " *key " *value: " *value: form *value ]]
            any [all [find-with key: first back find next-key reduce [
            go-to try-this] find [url! email! tag! refinement!] to word! type? go-to
            | key key: *value do try-this]]] key: any [key *key try-this]]
            ()]
]

translate: func [transitive][intransitive: [] 
            any [all [
            equal? [] obj-chars/2 clear intransitive ]insert clear intransitive [|]]
            all [obj-chars strip-obj-chars-from transitive obj-chars]
            foreach next-key transitive [
            any [
            if equal? '. next-key [next-key: []]
            all [equal? word! type? next-key '`= != next-key
            append intransitive reduce ['| form next-key]]
            all [equal? block! type? next-key attempt [append intransitive do compose/deep [
            (load form strip-obj-chars-from next-key obj-chars)]]] append intransitive next-key]]
            replace/all intransitive [`= |] [`=] attempt [| append intransitive [return. 0]]
            probe strip-obj-chars-from intransitive reduce [|[] [] '| [] [return. 0] []]
            obj-chars: none()
]

into-any: :strip-obj-chars-from

*negate: :negate

negate: func [seq][any [attempt [*negate seq] into-any seq reduce [*variable 'get]()]]

delegate: func [seq with [email!] define action][
            any [
            all [equal? word! type? seq do reform [seq {""}] negate action
            set to-word skip form with 2 :|
            any [into-any (attempt [back back find action [get[]]])
            reduce ['get *variable: to-word variable]
            | insert action compose [(*variable: to-word variable) []]]
            ]
            all [equal? tag! type? seq var to-word skip form with 2
            affix [|[reappend [variable " " action]]]]
            all [do reform [action {""}] negate seq
            set to-word skip form with 2 :|
            any [into-any (attempt [back back find seq [get[]]])
            reduce ['get *variable: to-word variable]
            | insert seq compose [(*variable: to-word variable) []]]
            ]]
]

int: does [replace node-element *value *value: *value nil #]

string: does [replace node-element *value *value: mold mold form *value nil #]

char: does [replace node-element *value *value: mold mold form *value nil #]

*word: [replace replace node-element *value *value: join "'`" form as-sequence* *value ["@" ""]"'`'`" "'`" nil #]

nil: does [replace node-element [nil] {"unset!"} #]

of: func [this][ either equal? type? block! this [first attempt [do this]][attempt [do this]]]

destruct: func [*value][load find/match *value "'`"]

struc: []
`=: func[attr-value][
            any [
            attempt [if *key [replace find node-element *key *value *value: form do load form attr-value]]
            replace node-element form *value form *value: attr-value
            replace node-element mold form *value mold *value: attr-value
            attempt [*value: select node-element *key: load key] 
            ]all [not empty? struc do first back find struc load *key] node-element: head node-element
]

return.: func [value][
            any [
            attempt [*value: to-block value  
            foreach a *value [if not equal? word! type? a [do *value: a ]]]
            attempt [*value: do form reduce load value]
            ]
]

rel-xprsn: to-hash [
            "  " " " "*va" "-va" " ." "_$" "." " #" { = "} {:== "} {: "} ":::" " *" " set '" "};" {%>"}
            "] [" "]|[" "}}" "},}" "}," {%>"} "," " " ": " " 1 `= " ":::" {: "} {- "} {- ."} " = " " `= "
            " {"  " .{" " ${" { build-markup "<%} "* " "[] " "()" {("")} "==" " =" "function " "function '"
            "_$" " ." "var " "var reform " "-va" "*va" "= ." "= " ": ." ": " " #log" ".log" "&" ""
]

*get-expressions: func[this expressions][
            attempt [
            find this: mold this "return 0"
            strip-obj-chars-from this [{."} {"-} "1." "1-" "2." "2-" "3." "3-" "4." "4-" "5." "5-" 
                                      "6." "6-" "7." "7-" "8." "8-" "9." "9-" "0." "0-" "\." "~escp"] 		
            strip-obj-chars-from this expressions: any [expressions rel-xprsn]
            strip-obj-chars-from this [{"-} {."} "1-" "1." "2-" "2." "3-" "3." "4-" "4." "5-" "5."
                                      "6-" "6." "7-" "7." "8-" "8." "9-" "9." "0-" "0." "~escp" "."]
            all [
            ;| is exspressive, using Do won't eval sequence methods but is simpler and faster.
            any [attempt [| reduce . this] do this]
            ]]
]

*get-methods: func[this][
            attempt [
            this: mold this 
            if not find this: next find this "." "return 0" [
            | this: do strip-obj-chars-from head this [
            "[" "" "]" "" "." "@" {"} "" "ame@" "ame join form '" 
            "ent@" "ent. " "&" { join " " } "=" "`="]]
            ]
]

node-element: *node-name: *name: array-obj!: key: *key: *value: ""
            
markup-DOM: func [Dialect][
use-methods: no 
           
            DOM: copy/deep load replace/all mold Dialect "__" " "
            
get-data: func [data][  
            end-tag: none   
        any [
        if end-tag: find data refinement! [
            end-tag/1: to-tag join "/" end-tag/1
            ]   
        if end-tag: find data get-word! [
            end-tag/1: to-tag join "/" end-tag/1 
            ]
        insert tail data to-tag join "/" any [*name *node-name]
            ]
        if string! != type? data/1 [insert data to-tag node-name]
        
repeat in-data data [
        if set-word! = type? in-data [
            replace data in-data node-name: to-word join "." *node-name: form in-data
            ]
        if string! = type? in-data [
            in-node-element: rejoin [remove form node-name " " in-data]
            quote-node-attributes create-tag-element with-these-attributes  
            foreach [a b][{=" } "={" {" "} "*}" "*" {"}][replace/all child a b]
            replace data in-data data-node
            ]
        if block! = type? in-data [get-next in-data]
            ]    
]

get-next: func [in-data][
            end-tag: none
        any [
        if end-tag: find in-data refinement! [
            end-tag/1: to-tag join "/" end-tag/1
            ]   
        if end-tag: find in-data get-word! [
            end-tag/1: to-tag join "/" end-tag/1 
            ]
        insert tail in-data to-tag join "/" any [*node-name *name]
            ]
        if string! != type? in-data/1 [insert in-data to-tag node-name]
        
repeat data in-data [
        if set-word! = type? data [
            replace in-data data node-name: to-word join "." *name: form data
            ]
        if string! = type? data [
            in-node-element: rejoin [remove form node-name " " data]
            quote-node-attributes create-tag-element with-these-attributes  
            foreach [a b][{=" } "={" {" "} "*}" "*" {"}][replace/all child a b]
            replace in-data data data-node
            ]
        if block! = type? data [get-data data]
            ]
]

repeat with-this-data Dialect [
        if issue! = type? with-this-data [
            node-name: to-word join "." *name: copy form with-this-data
            ]
        if set-word! = type? with-this-data [
            replace Dialect with-this-data node-name: to-word join "." *name: copy form with-this-data
            ]
        if word! = type? with-this-data [
            either '= = with-this-data [string-is-data: yes replace Dialect with-this-data ""
            ][
            *name: copy form with-this-data
            replace Dialect with-this-data node-name: to-word join "." with-this-data] 
            replace Dialect reduce [node-name node-name] node-name
            ]
        if string! = type? with-this-data [
            either string-is-data [
            replace Dialect with-this-data rejoin [node-name " " with-this-data]
            ][
            created-data: copy with-this-data
            strip-obj-chars-from created-data none
            insert created-data reduce [node-name " "]
            child: build-tag to-block remove created-data 
            foreach [a b][{=" } "={" {" "} "*}" "*" {"}][replace/all child a b]
            replace Dialect with-this-data child
            ]
            string-is-data: no
            ]
        if block! = type? with-this-data [ 
            get-data with-this-data
            ]
            
        if get-word! = type? with-this-data [
            replace Dialect with-this-data to-tag mold to-refinement *name
            ]
]   
    DOM: copy Dialect         
    markup: form Dialect
        foreach [-char +char]["{" "<" "}" ">" "<." "<" "_. " ","][replace/all markup -char +char]
        
        foreach n-name [
                        ".body " ".hr " ".p " ".b " ".i " ".? " 
                        ".tr " ".table " ".td " ".button " ".input "
                        ".div " ".ul " ".li " ".font " ".span " ".hr "
                        ".area " ".img " ".a " ".strong " " ." 
                        ][replace/all markup n-name " "
                        ]
        append replace/all markup </body> "" </body>
        markup: any [find markup "<body" markup]
        ]
]           

old-mrkp: none

view-port: layout [ID: bck: backdrop 241.241.241
across at 0x0 
box black 805x40 
pad -805x10  
text 240x50 black "Click to load demo page" left font-size 12 241.241.241 effect [draw [pen black line-width 4.5
 fill-pen 241.241.241 box -3x-2 240x50 7]][editor/text: html-demo
show html markup: editor/text 
clear face-styles

update 
=: :equal?
]  pad -250x30 box 700x50 241.241.241
below across
pad -4x-56  
box 241.241.241 30x31 effect [draw[fill-pen 245.245.245 pen white circle 14x16 pen gray line-width 3 line 6x16 22x16 pen gray font back. text "<" 4x0]]
space 10
box 241.241.241 30x31 effect [draw[fill-pen 245.245.245 pen white circle 14x16 pen gray font back. text ">" 10x0 pen gray line-width 3 line 5x16 20x16]]
pad 0x6
Go: button "Go" white 30x24 [
txt-clr: none attempt [
case [
     if find/match html/text "www" [insert html/text "http://" markup: read to-url html/text update] 
     if find/match html/text "http://" [markup: read to-url html/text update]
     if find html/text {/rebol } [attempt [do html/text]]
     ;markup: mold any [attempt [load html/text] {<h6>404</h6>}]
     ]]
]
 edge [size: 0x0 effect: 'none ]  

html: field 500 edge [size: 1x1 color: blue ]
below
pad -20x28 box 805x1 gray /20 edge: ['none]


across pad -20x-10 page: box 241.241.241 edge[size: 0x0 effect: 'none ] 783x508
pad -10 s1: scroller 241.241.241 16x494 [attempt[scroll-panel-vert page s1]] 
below pad -20x-24 s2: scroller 241.241.241 788x16 [attempt [scroll-panel-horz page s2]] 
pad -10 editor: area white 805x130 wrap
pad 7
below across
pad -10x-10
btn "Up" 55   [if error? try [page/pane/offset/y: page/pane/offset/y + 100 show page
                                 page/pane/offset/y: page/pane/offset/y - 2 show page][]]
btn "Down" 55   [if error? try [page/pane/offset/y: page/pane/offset/y - 100 show page
                                   page/pane/offset/y: page/pane/offset/y + 1 show page][]]
btn "View code" 85 [markup: copy editor/text update
]

]
page/pane: "" 
 
 scroll-panel-vert: func [pnl bar][
        pnl/pane/offset/y: negate bar/data *
            (max 0 pnl/pane/size/y - pnl/size/y)
        show pnl pnl/pane/size/y - 1 show pnl
    ]

    scroll-panel-horz: func [pnl bar][
        pnl/pane/offset/x: negate bar/data *
            (max 0 pnl/pane/size/x - pnl/size/x)
        show pnl
    ]

    update-panel: func [pnl vbar hbar] [
        pnl/pane/offset: 0x0
        s1/data: s2/data: 0
        vbar/redrag pnl/size/y / pnl/pane/size/y
        hbar/redrag pnl/size/x / pnl/pane/size/x
        show [pnl vbar hbar]
    ]

    goo: does [get-attributes {p1 font-size "15" color "pink" bgcolor "blue"} set-attributes]    ;declarative
  gogo: does [document.(getnodename{p.1}).style[color]`= "blue" setattributevalue "bgcolor" "orange"]  ;functional
 
view-port/size: 805x800

view center-face view-port

