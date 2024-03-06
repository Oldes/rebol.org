REBOL [
    	File: %rebol-dom.r
    	Date: 05-01-2021
    	Title: "Dialect Object Model"
        Emai: inetw3.dm(a)gmail.com
        author: daniel murrill
        version: 1.0     
    	Purpose: {
             Use an exstensible, Rebol user-mode, Markup function to parse DSL's that will return an
             easy to follow tagged key value Dialect Object Model. It will allow different DSL's or
             programming languages to work with, or together through a Central Processing
             interpreter. Yes Rebol/Core. A demo example of a HTML DSL is parsed by
             the Dialect Object Model to return valid HTML, then processed by the %Mdlparser
             wich in return creates UI VID code. All scripting takes place in the DOM and then
             passed as VID code to Rebol/View. So instead of writing parse rules for DSL's, you
             work with your DSL as a DOM and immediatley began to write code for it as if it's is 
             programming.}
]

Notes:  {
             All code and data should be in the Sequence data type. In Rebol, the way to send, recieve,
             or save your code/data is by way of MOLD(). In the DOM, code/data and Var are never loaded
             outside of the DOM or node-list. When parsing takes place, it loads as a sequence of strings.
             They should be READ() or streamed in or out. Limited executions. The Var methods must use Return.()
             if you want to return values. Only the returning Key values are loaded. This defualt behavoir
             can easily be changed. Once a Var is created, its variable, node-name, and elements are strings,
             unless you set the sequence as a series, wich should not be loaded. So in the interpreter,
             key-values, variables and node-elements have no #value, and no context. Because it's not code,
             nor data turned into code. It's all Domain specific data in an exstensible Dialect Object Model.}

library: [
        author: daniel murrill
    	level: 'advanced
        platform: 'all
        type: [Dialects Markup]
        domain: [html vid css json js array]
        tested-under: 'windows
        support: none
        license: none
        see-also: %Mdlparser.r
        version: 1.0
    ]

;Demonstration data: Copy&Paste....  You must replace all "%----" with ".@", due to obfuscation.
;Download or use the last updated copy from the history page.

my-dialect: [
rebol-DOM: [{DSL-type="html/block" type="text/html"}]

lua-tbl = {[first] = "fred", [last] = "cougar"} 
    
#this-issue [{color: "purple" bgcolor: "orange"}]

var anObj = {`100: 'a', `2: 'b', `7: 'c', };

body: [{background-color="blue" text "white"} ]

p: [
    {"color":"#0000ff", "bgcolor":"yellow", "width" : "399", "height" : "100" "font-styles": "big" } 
 This is an example of an Dialect Oject Model
b: [
    {id="my-p1" color = "Chocolate" bgcolor = "yellow"} 
    
 that can be written to look like json' html' javascript arrays' css'  
i: [
    {color = "green"} 
    
 VID' or plain old rebol ] 
  ] 
 if you like.
  ]


hr: [{color="red" bgcolor="yellow"}]

div: [
    {width="399" bgcolor="orange"}  
b: [
    {color: "purple" bgcolor: "orange"} 
    
 Maybe it would be easier to write  
i: [
    {id="my-p1" color: "green"}
    
 MakeDoc.r code but the purpose of this rebol DOM is']  
   ]
]

p: [
    {width "399" height= 200 
    style="color: red;  bgcolor: brown; border: 2x2;" 
    } 
b: [     
    {color="red"}
 to read or load as many well known dialects of coding styles as possible
 and write all of it as a single or seperate legible rebol series that's
 quickly manipulated' transcoded as html' and viewed as a VID. ]
  ]



]

node-list: to hash! []  .style: []
equal?: :=
DOM: DSL: html: window: end-tag: ""
data-node: parent-node: slf*: node: key: *key: *value: k: v: none 

.body: .hr: .p: .b: .i: .tr: .ul: .li: .area: .table: .td: .button: .input: .div: .font: .span: count: 0
array-obj!: node-obj: node-element: *variable: *node-name: node-name: *name: use-methods: attr-name: attr-value: none

check: func [select-this][return pick parse trim strip-chars-from form select-this none " " 1]

*get: func[this][ attempt [this]]

affix: func [code][*get insert code [clear ] | code]

reappend: func [with this-data][append with to-block mold rejoin this-data]

rescind: func [variable][var form variable]

imply: func [with][do load strip-obj-chars-from mold self: with inferred] 

insert-this: func [put-this at-here][do head insert here: find copy key at-here put-this]

void: does [data-node: node-element: none slf*: "" count: 0]

as-data-node*: func [data-node][to block! data-node]

as-series*: func [series with-chars][to block! strip-obj-chars-from form series with-chars]

as-sequence*: func [series with-this][
         to block! strip-obj-chars-from strip-obj-chars-from form series with-this none
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
        any [switch count [0 [slf*: join node-name/1 " "]] slf*: join node-name/1 count]
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
        obj-chars: [=[`=]]();get-attributes node-element attempt [set-attributes]
        ]       

setattributevalue: func [attr-name attr-value][
        *key: *value: none .style: array-obj!: 
        |: func [key] do compose/deep [body-of (to-get-word variable)] 
        any [
        all [.style((attr-name)) if *value [`= (attr-value)]]     
        | [reappend [" " attr-name{="}attr-value{"}]]
        print ["Must get a parent-node with this attribute: " attr-name]
        ]obj-chars: [=[`=]]() ;get-attributes node-element attempt [set-attributes]
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
            attempt [all [equal? datatype! type? do last load var-data 
            variable: pick var-data 1 type: length? var-data
            strip-obj-chars-from insert node-element: join [] do load reform [
            "to" var-data/(type) mold reform [var-data/2]] do reform [mold/only [#1: ] ] "'"]]
            attempt [if equal? block! type? var-data [variable: first node-element: var-data]] 
            attempt [variable: var-data node-element: ""]
            ]
            use*=*to-set-values node-name: variable: to-string variable obj-chars: []
            replace node-element node-name nodename: first parse form node-name form count
            either empty? node-element [any [find node-list variable append node-list reduce 
            [variable node-element: any [attempt [do :variable] node-element]]]] 
            [any [find node-list node-name append node-list reduce [form variable node-element]]] 
            set to-word variable array-obj!: func [key] compose/deep copy get-array-obj!
            any [find variable "." set to-word trim/all reform [variable "."] :array-obj!]
            use-methods: off *variable: none if equal? word! type? var-data [clear node-element] ()
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
            all [attempt [find struc reduce ['const to-word form key] const]]
            any [
            if empty? form key [strip-obj-chars-from node-element ["={" {="} ";}" {;"}]
            array-obj!: replace body-of :array-obj! select body-of :array-obj! [variable:] variable 
            |: array-obj!: func[key] array-obj!
            return any [
            if equal? tag! type? node-element [node-element]
            attempt [find/tail copy head node-element first parse node-element " ,"]
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
            *key: trim trim head tail form key]
            attempt [*value: select/case load strip-obj-chars-from mold to-block node-element none *key: key]]
            attempt [do head any [append insert next copy key [node-element join] ""
            insert next load key 'node-element]]
            attempt [do load key] attempt [*get-methods key] attempt [do *get-expressions key none]
            if not find node-element key [*key: value: none obj-chars]]
]

new: func [previuos-node][as-variable: form copy variable
            with-element: do reform [previuos-node {""}]
            any [ if find node-list double-variables: any [
            reduce [as-variable as-variable] reduce [as-variable ""]
            ][replace node-list double-variables []
            var reform [join as-variable ":" load with-element] do reform [variable {""}]]
            if *variable [attempt [var rejoin [*variable ": " with-element]
            do reform [*variable {""}]]]
            all [replace node-list [""] rejoin [as-variable ": " with-element]
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
            ][any [attempt [do compose/deep reduce [*value [(load value)]]]*value]]
]

some: func [next-key][
            either obj-chars [translate next-key][
            foreach try-this next-key [
            any [find-with: all [equal? block! type? try-this go-to: *key]
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
            replace/all intransitive [`= |] [`=] attempt [ | append intransitive [return. 0]]
            probe strip-obj-chars-from intransitive reduce [|[] [] '| [] [return. 0] []]
            obj-chars: none()
]

into-any: :strip-obj-chars-from

*negate: :negate

negate: func [seq][any [attempt [*negate seq] into-any seq reduce [*variable 'get]()]]

delegate: func [seq with [email!] define action][
            this: to-word skip form with 2
            any [
            all [equal? word! type? seq do reform [seq {""}] negate action
            set this :| set to-word join '. this does [| (action)]
            any [into-any (attempt [back back find action [get[]]])
            reduce ['get *variable: to-word variable]
            | insert action compose [(*variable: to-word variable) []]]
            ]
            all [equal? tag! type? seq var to-word skip form with 2
            affix [|[reappend [variable " " mold/only action]]]]
            all [do reform [action {""}] negate seq
            set this :| set to-word join '. this does [| (seq)]
            any [into-any (attempt [back back find seq [get[]]])
            reduce ['get *variable: to-word variable]
            | insert seq compose [(*variable: to-word variable) []]]
            ]]
]

const: does [*key: *value: none]

*word: [replace replace node-element *value *value: join "'`" form as-sequence* *value ["@" ""]"'`'`" "'`" nil]

str: string: does [replace node-element *value *value: mold mold form *value nil]

char: does [replace node-element *value *value: any [attempt[to char! form *value] *value: "unset!"] nil]

int: does [replace node-element *value *value: any [attempt[to integer! *value] *value: "unset!"] nil]

nil: does [replace node-element [nil] {"unset!"}]

of: func [this][ either equal? type? block! this [first attempt [do this]][attempt [do this]]]

destruct: func [*value][load find/match *value "'`"]

struc: []

`=: func[attr-value][
            if equal? block! type? *key [
            any [
            all [equal? integer! type? first *key *key: to issue! to string! reduce [*key ":"]] 
            attempt [*key: load *key/1] *key: (all [equal? set-word! type? *key *key])
            *key: to word! form *key]
            ]any [
            all [find struc reduce ['const to-word form *key] const] 
            attempt [if *key [replace with: find/last node-element *key *value *value: form do load form attr-value]]
            all [key replace node-element form *value form *value: attr-value]
            all [*value replace node-element *value *value: attr-value]
            attempt [*value: select node-element *key: load key] 
            ]all [not empty? struc do attempt [first back find struc load *key]] 
            node-element: head node-element
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



markup-DOM: func [DSL][
use-methods: string-is-data: no =: :equal?
        either block! = this-type?: type? DSL [
            DOM: copy/deep DSL: load replace/all replace/all mold DSL "__" " " {=""} {="undefined"}
            any [
            find DSL [rebol-DOM: [{DSL-type="html/block" type="text/html"}]]
            insert DSL [rebol-DOM: [{DSL-type="html/block" type="text/html"}]]]
            
            
get-data: func [data][  
        find-end-tag: find data get-word!
            either find-end-tag [
            replace data first find-end-tag  to-tag mold to-refinement first find-end-tag
            ][
            insert tail data to-tag join "/" any [*name *node-name]*name: none
            ]
repeat in-data data [
        if set-word! = type? in-data [*node-name: copy form in-data
            replace data in-data node-name: to-word join "." *node-name
            ]
        if string! = type? in-data [
            foreach key-value [{:*"}{:*:*}{=*"}{=*=}] [either find/any in-data key-value[
            strip-obj-chars-from in-data none
            insert in-data next reform [node-name " "]
            child: build-tag to-block in-data 
            foreach [a b][{=" } "={" {" "} "*}" "*" {"}][replace/all child a b]
            replace data in-data child][]]
            ]
        if block! = type? in-data [
            get-next in-data
            ]
        ]    
]

get-next: func [in-data][
	repeat data in-data [
        if set-word! = type? data [*name: copy form data
            replace in-data data node-name: to-word join "." *name
            ]
        if string! = type? data [
            foreach key-value [{:*"}{:*:*}{=*"}{=*=}][either find/any data key-value[
            created-data: copy data
            strip-obj-chars-from created-data none 
            insert created-data reduce [node-name " "]
            child: build-tag to-block remove created-data 
            foreach [a b][{=" } "={" {" "} "*}" "*" {"}][replace/all child a b]
            replace in-data data child][]]
            ]
        if block! = type? data [get-data data set to-word *node-name data]
            ] 
	    find-end-tag: find in-data get-word!
            either find-end-tag[
            replace in-data first find-end-tag  to-tag mold to-refinement first find-end-tag
            ][
            insert tail in-data to-tag join "/" any [*node-name *name] *node-name: none
            ]
]

repeat with-this-data DSL [
        if issue! = type? with-this-data [
            node-name: to-word join "." *name: form with-this-data
            ]
        if set-word! = type? with-this-data [
            replace DSL with-this-data node-name: to-word join "." *name: form with-this-data
            ]
        if word! = type? with-this-data [
            either '= = with-this-data [string-is-data: yes replace DSL with-this-data ""
            ][
            *name: form with-this-data
            replace DSL with-this-data node-name: to-word join "." with-this-data] 
            replace DSL reduce [node-name node-name] node-name
            ]
        if string! = type? with-this-data [
            either string-is-data [
            replace DSL with-this-data rejoin [node-name " " with-this-data]
            ][
            foreach key-value [{:*"}{:*:*}{=*"}{=*=}][either find/any with-this-data key-value[
            created-data: copy with-this-data
            strip-obj-chars-from created-data none  
            insert created-data reduce [node-name " "]
            child: build-tag to-block remove created-data 
            foreach [a b][{=" } "={" {" "} "*}" "*" {"}][replace/all child a b]
            replace DSL with-this-data child][]]
            ]
            string-is-data: no
            ]
        if block! = type? with-this-data [ 
            get-data with-this-data
            ]
            
        if get-word! = type? with-this-data [
            replace DSL with-this-data to-tag mold to-refinement *name
            ]
]
            replace/all dsl "" [] DOM: copy DSL
            ][
            view center-face layout [
            backcolor black space 8
            across
            h3 yellow "Need a Dialect Object Model as type! block"
            return
            text gray "Your DSL type is: " text red bold form :this-type? 
            return
            text gray "Some DOM functions will not work properly"]
            ]
        
]

format-this: func [node-element with-these-chars][
            foreach [-char +char] with-these-chars [
            replace/all node-element -char +char] 
            do last with-these-chars
]

as-js-object!: [
            { #} "" 
            {="} {: "} "={" ": {" {""} {"} {" } {", } {", "} {","}
            [if equal? tag! type? node-element [replace node-element " " ": {"] 
            replace/all node-element { "} {: "}
            replace/all node-element "::" ":"
            replace/all node-element " : " ": "
            if equal? tag! type? node-element [append node-element "}"]
            ]
]

.as-js-object: does [format-this node-element as-js-object!]

return-html-dsl: does [
        html: copy form any [find head DOM "<body" head DOM]    
        replace/all replace/all html "<." "<" "' " ", "
        replace/all replace/all html "{" "<" "}" ">" 
        foreach n-name [
                        ".body " ".hr " ".p " ".b " ".i " ".? " 
                        ".tr " ".table " ".td " ".button " ".input "
                        ".div " ".ul " ".li " ".font " ".span "
                        ".img " ".a " ".strong " " ." ".hr " "lua-tbl "
                        ][replace/all html n-name " "
                        ]
        append replace/all html </body> "" </body>
        html: any [find html "<body" html]
]


probe markup-DOM my-dialect

document.(getElementById 'my-p1)
        
data-node

setattributevalue 'id "my-p2"

;Void nulls the return of any identifyers from a node-element in scope, 
;so document.(tation) can create proper in scope context for any new node-element.

void document.[li size "2x2" color "red"] 
        
document.(querySelecter 'border)

data-node

setattributevalue 'height "xxx" ;Border references p2. Its height is also auto updated.

setattributevalue (*variable: "p3" new[li] "class") "choices" 	

;Use set words {
                           with: :some see: :any if-it: :| has-any: :.
;}, or imply inferred data.

inferred: [with some see any [if it] | [has any] .]

setattributevalue (var 'p4 new[li] "classic") "cars"
imply [   
     with [
           size = 0x0 color = yellow]
           see [if it has any {bgcolor} | [
           reappend [{ bgcolor="advacado"}]
            ]   
      ]
] 

p4[] 
 

.style[bgcolor]

;Check the node-list to see how key names with value associations are collected. 

probe node-list

var {.div 1=div.1 width="none" bgcolor=none}  ;create node-element with a set builder notation.
    
var document.getnodename(.div[1])  ;Use SBN. to get node-element from DOM.

;lets play with our div[] and .div[]

|[] ;using array-obj! as anonymous function 

|[div.`find-first-and-second-keys` |[2][1] return 0] ;use comment with multiple key selections.

document.getnodename{div[2]}

.style[div.bgcolor]`= red

;The DOM div[] node-element now can call/update the Var .div[] properties with update.div

update.div: [  ;This code is all user dialect styled. It can be written totaly different if need be. 
div[]
   *w | .@width
   *bg | .@bgcolor

.div[] 
     | width@ = &w 
     | bgcolor@ = &bg
print {"the width type is" type? do ${w}, "the bgcolor type is" type? do ${bg};}
return 0
]
.div[]

div(update.div)

.div[]

;Another more object oriented associative way to use sequences and Var node-elements, is to
;Delegate them with other Var's and sequences as methods. What's unique? All piping takes
;place on the last known parent-node: The last returned Var sequence: div by using [], as div[].

update.div: [
   *w | .@width .div[width] = &w
   *bg | .@bgcolor .div[bgcolor] = &bg
return 0
]

;The Delegate function is doing... apply :Div update.div as
;delegate Div() and Div show = new div(update.div) inline.

delegate 'div .@show. := update.div

struc: [const width]

; The width value is  a string that has a structure type? of constant. 
;It can't be changed with `= or replace(), until the struc is cleared.

.div[width]
.div[bgcolor]

show.[width] `= 1000 ;not allowed. width is a constant.

show.[bgcolor]`="green" show.(update.div) ;or use the method .show

.div[]

clear struc

delegate update.div .@main := 'border

main[width] `= 50
main[bgcolor] `= "red".main

.div[] affix [
                 |[insert {.div 1=div.1 width=none bgcolor=none}]
]

.div[]

;Create singular key-value Vars, with user defined datatypes!
;We'll make *demo* functions using the Inferred/imply series helpers. 

_: []

_poke: [#":" {[] poke |[] 1 to any [attempt [to type?/word last self]do compose [(last self)]]}]

_update: [#"=" {[] replace |[] first |[] do append join [to] back tail self select self [=] }]

find-any: func [node-element key ][*value: first next to-block find mold/only node-element key]

var [Hi: "Hello" tag!]

hi _

inferred: _poke 

imply [|: cats@ email!]hi[]

inferred: _update 

imply [hi = <rats>]hi[]

;Maybe the Var is a parameter in a block.

param: [hi] 

;And some relative expressions returning the parameters value, by index.

|[param.1]
do |[param/1][]
&.(param/1 _)
*value: param/1 .[]
*value: first |[] 

;Or maybe change the type! using simple Rebol code.

replace |[] *value to *value "bats"

;A *demo* Let function that's local to the in scope Variable node-element.

let: func [make-scope-with][obj-chars: none make-scope-with: load make-scope-with
            append |[] reduce ["  " to-set-word make-scope-with/1 
            any [
            all [equal? get-word! type? last make-scope-with to first |[] 
            trim strip-obj-chars-from mold/only next make-scope-with ["=" ":" ": :" "" "`" "" "1 " ""]]
            trim strip-obj-chars-from mold/only next make-scope-with ["=" ":" ": :" "" "`" "" "1 " ""]]
            ]remove find |[] ["  "]
]

;If the value is type! get-word!, it's value type is set to its' paren-node first key-value type!

let [me = :hello]

hi[me]

;find the key and return any value with set type!

find-any hi[] "me"


;You can also use Structures with Sequences.
;Just think, your molded data can remain molded
;and have types. 

;This will be hard coded for Delegate methods and
;as a user option for Sequences.

struc: [
            int width 
            *word height
]
		
delegate<char int => .@video #([width: nil height: nil])

video[width] `= 1620  

type? of *value

replace video[] |[width] "fancy"  

video[]

*value

type? of *value

video[width] `= length? "fancy"  

type? of *value

video[height] 

type? of *value

video[height] `= <100>

*value  

type? of *value  

type? destruct *value 

clear struc

;you must decide when to clear your Structure if
;you do not create them as a Var set builder notations.
;Demo

;struc: :var 

;struc Mystruc: = {Mystruc:
;                           char people 
;                            int 5000
;}

;Demo of collecting attribute values from a sequence.
;with Dialect Object Model functions.

DSV-value: [{="} {["} ;open-str='' to block
            { "} { "]} ;ending-str_'' to block
            {"/} {"]} ;closed-str-tag''/ to block
            { /} { ]}]  ;end-of-tag_/ to block
			_: []
selection: [
            DSV-value _
            as-action 'reappend
            'text _
            'value _
            ]

*collect: :collect

~: collect: func [SBN][
as-action: attempt [to-word first load to-string SBN]

obj-chars: reduce copy selection

            all [some as-data-node* mold as-sequence* SBN using: first obj-chars]
            replace  node-element last "0" ""	
]



fifo..: does [clear node-element] select=: :.

fifo..
foreach value-of select={<p text="_pop goes "> 
                    <span value="the weasle_" /> 
                    <span skipped="and the Charlie horse_" /> 
                    <span value="at the end." /> 
                </p>} [collect value-of]

alter selection ['skipped _]
replace selection ['text  _] _

Keys-value: {<p text="_pop goes "> 
                    <span value="the weasle_" /> 
                    <span skipped="and the Charlie horse_" /> 
                    <span value="at the end." /> 
                </p>} 
fifo..
foreach value-of select=(keys-value).{collect value-of}
                   

;Let's try to use lex + syntax analysis by coding our
;own token/key and function sequence to execute it.
;Sounds hard, but thats just fancy lingo for something
;Rebol finds easy to do many different ways.
;Here's one way to do it.
;To surpress the intransitive block value, remove the probe() word from Translate()

;Use obj-chars: [], but let's make it use Rule index selections.

eq?: [                         ;This is the eq? rule. it's lex/token is :=, it's syntax, [| *key `=]
      := [`=]
]
obj-chars: reduce [eq?/1 eq?/2]

my-p1[] some [              
              color := purple (|[2]) [print "wow"]
              id := 'i-robot
]|[]


eq?/1: 'as
obj-chars: reduce [eq?/1 eq?/2 <add-this  with-this> '+]

some [id as "geewiz" [2 <add-this  with-this> 3] ]|""

eq?/1: 'size-of
obj-chars: reduce [eq?/1 eq?/2 'push eq?/2 <add-this  with-this> '+]

div[] some [
            width size-of 5
            bgcolor push blue [setattributevalue "Fish-type" "Pufferfish"]
            me: [1 <add-this  with-this> 2]
]|{}
me
    
document.getnodename{("p")[2]}p2.(style.width@) `= "block-build"

setattributevalue 'height "really high" 

;Border Var is reference of p2. So its height is auto updated also. See node-list.
    
    node-element

    getattribute "height"

setnodename {hr[1]} "listview"

    node-element    
        
document.getnodename{("p")[1]}| style:font-styles `= "block-build"
    
    setattribute('font-styles)"whitehouse"

node-element 
    
    setattributevalue 'boogies "green-color"

node-element 

void data-node: do to-path [DOM .p .b] 

document.(data-node).style[color] `= "bluberry" 

    setattribute 'i-style "silly" 
    
node-element 

; Some examples of selecting keys and values set to Sequence variables as an array object.
; good to use with anything that's structured with {} , or "". It also can be used with [].
;IE (javascript, json objects/arrays.. lua table/arrays.. associative arrays etc.) 
;even DOM's and rebol data. The Sequence will honor punctuation. So ABC is != AbC.

;The insert, remove, append, and lookup of a group (a node-element) by way of a Var (variable)
;is done as a data-node and syntactically as an associative array. The associattion of key 
;values is done by index in Rebol therefore there is no need for the overhead of objects or 
;multi.dim arrays. But the cool part is you can do what ever you like!

;You must use use*=*to-set-values before setting the first variable.
;But it's included in some DOM functions just in case we forget to. 
;it will use = to queue any value to a variable (a set-word) 
;`= this literal equal is used to set values to keys. Feel free to use
;different function symbols for any !op function.  

use*=*to-set-values

;variables and there values (node-elements) are sent and fetched from a
;node-list block for demo purposes. They can/should be appended to the DOM.

;The variable name and the first word in it's value must be the same in order for
;the variable to be automatically bound to the node-element and array-obj!() function.
;Or use the select-all-fetch-as (shabang)function, *!.


var hello: = {hello 100: "a" 2: "two words" 7="c"}

hello[2]

hello[2] `= "a to z"

node-element

;When creating Var's with no sequence, you can't insert or append to an empty value. 
;It has no size, length, or context. It's null.

;The pointer, *value in scope will try to bind to any new null value 
;forced to mutate, therefore leading to value corruption.

;You must affix() it. Slice with replacement instead of copy and 
;appending the sequence to its assigned address.

var 'empty-sequence 

node-element

affix [
         |[append (add 50 50) ", "]
         |[reappend [" beautifull"]]
          your-to-old: empty-sequence.[100]
]

print ["hello" "there" your-to-old]


;if you use *use-methods: yes, use paths or refinements, /style.bgcolor 
;to get the value. Not implemented: may not be needed.

;use-methods: yes  

;The &. method initial call to Sequence, must be spaced:  &. .style@bgcolor
;or wrapped in parenths, &.(/style.bgcolor)
;After initiated call, no need for &.style:bgcolor. Just use `= .

app: = document.(getElementByTagName("p")[2])&. style@bgcolor `= "red"

`= blue

`= yellow

&.(/style.bgcolor) `= green 

;/* 

&.(.@style.bgcolor) `= blue

;*/

&.(style:bgcolor) `= "silver"

&.(border@)`= 5x5
    
  p2(.innerHTML "Lets change this, shall we.")

data-node

;You must call/associate the array-obj! with this variable name
;because the variable name "app" and the node-name/TagName "p"
;are not the same.

;Don't call/associate and just use the set node-name/TagName "p2"

p2.[bgcolor] 

;call/associate

*![app]  

;app[] and p2[] points to the same node-element. They reflect the
;same changes allthough they are independent in the node-list.
;Use New() if you want a seperate copy of p2[], independent of p2[].

p2[]

;or app: :array-obj!

;the style.obj! is auto created by using the document.() function

.style{bgcolor}

;is the same as calling, but without any block/parenths this time. 

app 'bgcolor

var choose: = {choose red: 250.0.0 green: 0.250.0 yellow: 250.250.0}

app[bgcolor]`= "'yellows" ;set as word with {'} 

app[bgcolor]`= 0.0.5

;or replace/all of apps "yellows"

strip-obj-chars-from app[] ["yellows" 0.0.5] 

;This is a relative exspession. it makes the for in, switch,case,if,
;looping, find, nesting, and temp variables to keep up with found
;values unnecessary. The "=" after the Var is not is-equal? or
;for assignment.  It denotes a queue wich will allow user-mode
;operations to be plugged into the Var/value's code and data.

;The set (set-word "app") of all x ("with its array sequence properties")
;can evaluate its value such that x method is tupple.

app = [choose.yellow = 15.56.10]  ;you don't need the Var queue...(=) to eval the value.

choose[yellow]

me: *value

app "bgcolor" `= *value + me  

app = "width"  ;you don't need the "=" to eval the value.
app = "whithouse"
app   "height"

;scripting the Var in place.

node-element 

replace-each: :strip-obj-chars-from

app = {replace-each app* ["border" 'boundery "bgcolor" 'back-color] return 0}

app[]

app ("back-color") `= to-string [purple]

;when you need to create a variable to use with an array-obj!

poppy: [#100: "a" street: "backside" #7="c"]

;Sequence set builder notations without the Set word/name, ie..(poppy) 
;should start with a space object-char delimiter. " " , ": ", "=",  or "|".

poppy: {| 100: "a" street : "backside" 7="c"} 

var poppy *![poppy]  

;Local or global hoisting. the set-word is added to the series/sequence
;name-space, node-name/slot position. Quick way to use normal rebol 
;blocks as Var's.

poppy[] 

var join {poppy2} { 200:"a" street : "backside" 7="c"}
poppy2[]

poppy[street]`="old rover rd."

poppy["7"] `= "cities"

;You do not need a variable word. If you apply Var to your 
;value, the variable will always be the first word found in 
;the value (node-element) followed by ": =", " =", ": ", or " " 
;you can allso access it with array-obj![] or |.

var {
    new-var: 
    1: a
    2: b
    3: c
}

new-var[1]  

var <new-var: 1: a 2: b 3: c> ;tags are allways node-elements. 

new-var[2]

;VAR values can also be set to an arrayed object.... Rebol Series.

var poppy3: = [poppy3 #100:"a" #3:"c" street: "backside"]

;Even though it's not the best idea to use integers as keys, you can.
;it can encourage mistakes when trying to get by index...  poppy2[3]
;But this is Rebol, so we will roll with this...
;You must always start block cell number keys with the pound sign. "#"
;if it's written as a set-word! ie, 7: "some-value", if not it will error
;It reminds you there's an issue with that key. becarefull

poppy3[street]`= "old rover rd."

poppy3[3]`= "cities"

;First it looks for any 3rd index key/value but then it
;returns any set-word! #issue keys' *value if it exists.

*value 

poppy3[100]

;WHY do this then? you can set your own index numbers, starting 
;at 0 or 1, in or out of order, as lua does with its table structure
;where some can be numbered keys mixed with normal keys/values.

;DOM variables are renamed to start with a dot "." so not to be confused with words.
;this may not change in the future. For now only DOM/parent-nodes can be type! word.
;Only Var type! set-word!'s can not be nested.

;Remember when calling a node-name or a tag! type node-element
;from the DOM, and using that name as the variable,

var .anObj: = getnodename "anobj"

;you dont have to call/associate the array-obj! with this variable name
;but the variable name must began with a dot. IE "."

.anobj["7"] 

;but with anObj you  do. 
; anObj and .anObj are'nt the same.

var anObj: = getnodename "anobj"


*![anObj]  ;or anObj: :array-obj!
 
anobj["7"]

;Set the sequence to none, in order to return a node, and tag it, if found in the node-list.
;Clear node-element  ...will null the sequence from the node-list.

;use void, (void<node-name>) or node-element: none 

void .return-tag-node '.anobj

;quick short parsing example of the node-element sequence.
;it,s not just top down, it's start and stop anywhere, with any
;repeat and backtracking, moving into or out of Vars and prototypes,
;code, and data by reference, linked or not.

this: [all [find node-element key print .{"I got the key " key}]]

in-node-element?: [any [all [find node-element key print .{key " In node-element"}]
                                      print .{key " not In node-element"}]]
obj-chars: none 
.anObj[] some [
         flys: in-node-element? 
         any [*value setattribute *value: "flys" *value]
         100 this  
         "flys" in-node-element?
         7 <| => [in-node-element?] ;7 is flagged as a procedure. Its *value is the param. used with the block code. 
         people: in-node-element?
]

;To use *keys as procedures, the infix op! needs to be a DOM method. A word of type? email, tag!, url!, etc.
;Example: get::, <get => get@, .@get, etc...

.anobj[]

;You can use any code between .[] .{} .<> to search/replace any Var code/data.

; .anobj[flys] any [
;                           *value |[append {flys="annoying knats"}]
;                            ]
;.[people]

;after calling some variable[key]/array-obj![key], you can replace the key and value.

;Long way
replace replace node-element *key 'this-key *value {some-value}

;or replace-each node-element [*key 'this-key *value some-value]

clear-node-list

var {
    try-that:
     width: "50px"
}   

try-that[]

;lets use this string node as prototype Object. this is some concept howto code..

;Using New() and proto-type() to create a new
;node-element sequence. New() node is independent,
;while proto-type() is OOP like. It's linked to 
;its parent node.

;*variable: "try-this" new "try-that"

;var "try-this" new[try-that]

;try-this[width]

;Example: Using new() while setting new key/values. 
 
setattributevalue (var "Span" new [try-that] "Footer") "Email contacts---" 	

node-list

try-that[proto-type 'try-this]

;lets give it a new key element.

setattribute try-this['vb][size]

node-element

try-that[try-this].[width]

try-this[parent].[]

;When ever a Var get corrupted, you can Rescind() it.

 try-that: "I lost it, get it back like before."  try-that

rescind[try-that]|[]

;give that key a value

try-this[size]`= #200px

;While the string node-element *try-that[] did'nt change

try-that[]

try-this[.innerHTML("change me please") ","]

try-this[]


;a roadmap for javascripting with the Dialect Object Model (DOM).

;A quick way to change op! functions between rebol and javascript.

js-op!: does [console.log: :print var 'use ops*: [" = " ": "] refer: func [referent ops-chars][
    replace-each referent ops-chars] js-do: func [this][ js-op! | (refer this ops*)]
]
reb-op!: does [=: :equal? reb-do: func [this][reb-op! | this]]

;This code...

{
function welcomeSite() {
   siteMessage = "Welcome to the...";
   Message-type: "Welcome"
   console.log(siteMessage);
   var siteMessage;
}
welcomeSite();

siteMessage.append("Rebolution") siteMessage
}

;Is changed to this code...

js-op!

function: func [fn params this-data][var rejoin [fn " " do *get-expressions refer this-data ops* none]]

function 'welcomeSite("") {
    siteMessage = "Welcome to the\.\.\. "
    Message-type: "Welcome"
    do reb-op! alert(siteMessage)
    console.log(siteMessage);
    var reform ['siteMessage siteMessage]; return 0
};

;Hey you can load welcomeSite from a DOM or files with variables, functions, key-values or Rebol code:

use[welcomeSite()];

;to use the welcomeSite Message-type in your code.

js-do {
    say-hi-to = Message-type
    console.log(["This is a message to" say-hi-to "you."]);
  }
    
siteMessage.{append ("Rebolution.")} siteMessage.[]

var first-obj: = {first-obj: first-name: "Brigsby" last-name: "Backfort"}

var second-obj: = {second-obj: first-name: "Krystal" last-name: "Frontbunker"}

first-obj[last-name]`="FortBack"  first-obj[]

second-obj[last-name]`="Bunkerfront"  second-obj[]

Var contacts: = {Bestfriend: "[{"first": "Besty", "last": "Bestest", "number": 777-9211}]"}

Bestfriend[first]   
*![contacts]
contacts[last]
;Does Var persist if not destroyed? YES.
first-obj[]

;and then back to Rebol

reb-do 2 * 2

clear-node-list

;Create a DOM from a nested javascript object DSL, search and update.
;A return-js-object-dsl() function will return the new js-object.
;Mold blocks and load strings to do quick formating like remove all ",".
 
markup-DOM load strip-chars-from {data: [
    fullName: {fullName: "James Zhan"},
    address: {
        city: "Shenzhen",
        state: {
            name: "Guangdone",
            abbr: "CN""
        },
        country: {
            local-name,Guangdone,abbr,CNN,id,jazzy},   ;CSV example.
    },   
    hobbies: ["coding", "reading"],
    projects: [
        { name: "form2json", language: "javascript", popular: true },
        { name: "peony", language: "ruby" }
    ]
]
} ","

getElementById("jazzy").as-js-object

var here: dom/.data/.projects/1

*![here]

here[name]`="funkacopics" 

format-this node-element as-js-object!

;using paths to get node-elements

var address: dom/.data/.address 

;using nested indexing by keys to get/set node-element values

address[state].[country].[abbr] `= "pop" ;

;this sets correct value even though .[country]'s not in [state] but has an .[abbr] key.

clear node-list

;And a cool but very simple trick in Rebol. For non-rebolers
;this IS code and data mixed together. First it's ALL string data.

var num: {num: a: 1 b: 2 c: 3}
;Rember, the *num value is a string Sequence, not an object.
 
amount: num[a]`= [amount '+ 15]
;And the new *formed() value is a [string: "1" word: '+ integer: 15]

;The DO() function binds each piece to/with a Rebol system symbols pointers/funcs table, and voila!

num[a]

;And now Var methods with linked node-element lists, a mixture of object and arrays
;in a simple DSL keeping track of data updates with set limits. Don't try to undestand
;it, it's silly. 

;methods are written as messages sending or recieving. So lets use a form of
;urls and emails.
;/*
get-numbers.has-a@variable-a ;or
get-numbers:has-a.variable-a ; cause theres a set-word in there.
get-numbers.has-a.variable-a@ 
;*/

;all methods must either start with "/", {'}, 1st word as a set-word or "@" appended
;somewhere or at the tail to be a valid  Var methods.

;if the word to start the method is a set-word *get-numbers: 
;the words to continue the method can each have "@" appended to them.

;/*get-numbers:has-a@variable-a@*/

;they will be looked up as Var words or set-words or else there
;is no vectoring/linking. 
;Yes if it's a string sequence word, it will be given local context.
;The string word will be matched as a pointer to it's literal word 
;to return the correct Var or local value.

;Sequence comments must either be removed from node-elements
;in order to select keys by index number. Try writting them as "comment: ..."
;key/value pairs, or leave them in if you just care about getting keys by name.

clear node-list

var check-if: = [
                check-if start: at-head 
                stop: at-tail 
                get-numbers: numbers  ;this is linked to local Var numbers
] 

var numbers: {
    numbers: 
        start-at: 1 
        has-a: limit  ;this is linked to local Var limit
               me: [a: "b" c: {d: "go-it"}] ;nest array objects with "{}" or "[]".  
        }

numbers[me].[c].[d]

var limit: = {
        variable-a: "yes" 
        info: "I am a returned method" ;using ancester Var to get info:
        variable-b: [function!(js-op!){console.log[(variable-a"info")]reb-op!}]
        } *![limit]
    
limit[variable-b]
    
numbers[start-at]

amount: numbers{start-at} `= {amount + 15}

;don't create a variable (*amount) to GC.

*value 

numbers{start-at} `= {*value + 15}

increased: "start-at"

;Returning a linked var's value with *do instead of (chaining) using .[] or .{}

do check-if 'get-numbers increased ;use ":" , "@" or "/" with key/values as metods.
do check-if [get-numbers](increased)
do check-if ('get-numbers)|{increased}
;or

question?: :? ?: :if Ohyea!: then: :.

check-if 'get-numbers all [ 
?(.[increased]) Ohyea! {
        `= money: $50.00 
        print .{"....... Yep it" *key "up to" *value} 
}       
?(numbers[me].[c].[d])then{
        print ."'I *value {, that cash you owed me. the} money"
}
?: :question?   
]

;Using .[] or .{} to load the last known variable and retun its node-element

check-if(get-numbers.has-a.variable-a@)*value: {
                                    ; this set attribute and value is appended to the last evaluated Var, Limit[].
                                    setattributevalue "last-variable" "value-off"
                                    .as-js-object
} 


;/*place *fetch, "@" before or after any key. use it in place of the set/get-word #":"

check-if get-numbers.has-a.variable-a@
;*/

;When "variable-a:" is found in Var limit[]'s namespace position with following data,
;its used as the Var name . Now we can use it as a stand alone method caller. 

variable-a[variable-b] ;with any array object data.

;Let's send get-numbers:has-a.variable-a data, wich is "yes" to /*daniel@mindsping.com*/

daniel: "get-numbers@" 
mindsping: "has-a" 
.com: ".variable-a"

;send /*daniel@mindsping.com check-if daniel@mindsping.com*/

;the node-element is now *limit[]

if (numbers has-a.variable-b@) .{
                print "this worked"
        }   
    
if!: :either then: else: :. ;or just use either 

=: :equal?

if! 16 = numbers<start-at> then {
    print "yessers"
       } else {  
        print "nossers"
}

numbers[] setattributevalue 'reset "check-if"

numbers[reset].[stop]

;This is a quick get by index example
;on strings, using parse and select
;The same string value, ie. node-element
;key can be selected by *key or index now. 

check-if[6]

check-if[1]

check-if[2]         

;get nested elements *values by index numbers.
;if Rebol style comments are in node-element, this 
;will not allways work properly.

numbers[me].[2].[1] ;same as [me][c][d]


;You can use any ancestor Var, (ie. variable-a) 
;in a Var method (ie. variable-b) to return a *value.

return.(limit 'variable-b) ;or
return.(limit{variable-b}) ;or
return. limit[variable-b] ;or
return. limit"variable-b"

;single element values are given an index as [#1:].

var age: "$user.age" 

*![age]

age[]

clear-node-list
reb-do 2 * 2

;Ason script DOM example...

probe markup-DOM  [user-database: [

  
    name: {name1:"John Smith"} ;values with spaces must be wrapped with name space.
    age:  22
    born: 1998-8-15
    usage: #8:22:45
    email: %jsmith--altscript--com
    website: http://altscript.com
    version: 3.2.14
    passhash: #A94A8FE5CCB19BA6
    colors: [ 255.100.50 50.50.80 ]
    allow: [ login admin upload edit ]
    check: [ if age > 60 [ add-to people.seniors ]]
  
    ;/*... more users ...*/
]
]
var dom/.user-database/.name ;get that name!

name[]  ;use "name.", "name" | or array-obj!
name "" 
name 1
name(1)
name[1]
name([])                   ;The purpose: DSL syntax styling.
name "name1"
name {name1}
name [name1]
name ("name1")
name name@name1
name </name.name1>
name /dom.user-database.name
array-obj![] ;use ".", array-obj!, name., "name" or |
array-obj! 'name1
array-obj! /name.name1
array-obj! name:name1  ;there's more, that could be pondered.
array-obj! name.name1@ data-node: []

use*=*to-set-values

;Very quick, easy, short demo scripting DOM node-elements.

var {x: yellow: 250.250.0 1: 10 2: 20} ;[] can be used in place of {}, "", <>, or these inside of ().

x.{find "10"} 
x.{replace "10" "30"}

var y: = "15" *![y]

;Lets make a quick relative expression that evals sequences and return statements. 
;Lets use Var X and Y.
 
x = {
        x.yellow = 20 + 20,      print {"x[yellow ] is now" *value}
        y: 15 - 3,          print {"y is now" *value}
        x.1 = 100 + 200     print {"x[1] is now" *value}
        return 0
    }

;Control duplicate key injection attacks due to
;different json/map encoding preferences for
;selecting first key but duplicate key is returned
;through decoding and shares an illegal value.


clear-node-list 

;Or use sequences as array,object, and blocks.

var {x: #1: 10 #1: 50 #2: 20}

of: create_key_*value: :.

if found? all of {
            key1: x.{find/any {#1:*#1*}} 
            key2: x.{find {#1: 50}}
            } create_key_*value   { 
            x.[1]`= 30
            add return. *value pick load maximum key1 key2 2
}

;A method is just putting the name of a Var in another Var as a key's value.
;None of the Vars need to share data structures, but can be linked, or put in a
;Var as *values with your *key variable names. Although it's a linked list all
;data structures are traversed and accessed individually. Thank you Rebol.
;You don't need objects, parsers, classes, or tricked out functions to use your
;DSL's. To start you just look up or set everything by key value pairs.
;methods are just a quicker way to get to local associated data.

