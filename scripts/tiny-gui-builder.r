REBOL [
    title: "Tiny GUI Builder"
    date: 4-feb-2017
    file: %tiny-gui-builder.r
    author:  Nick Antonaccio
    purpose: {
        A cut down version of the appbuilder, without any code to
        deal with actions, data structures, styles, extra help features,
        etc.  Just point and click to build little GUI layouts.
    }
]
rebol [title: "Tiny GUI Builder"]
g: copy []  req: func [x y] [request-text/title/default copy x copy y]
run: does [write %r.r rejoin["rebol[] w: view layout" mold g] launch %r.r]
act: does [load req "Action (replace with your code):" "Alert form value"]
ad: func [v] [
  w: copy v
  append g reduce select [
    btn ['btn w/2 w/3]  field [w/2 'field to-integer w/3 w/4 w/5]
    area [w/2 'area to-pair w/3 w/4] text ['text w/2 w/3]
    check [w/2 'check] image [w/2 'image to-file w/3 w/4] across ['across]
    below ['below] return ['return] box [w/2 'box to-pair w/3 w/4 w/5 w/6]
    do ['do w/2] text-list [w/2 'text-list to-pair w/3 'data w/4 w/5]
  ] w/1  
  set-face code mold g  run
]
view center-face layout [
  h3 "Add a widget or layout word to your app:" bar 410  across
  info "" [ad reduce ['field to-set-word "FIELD1" 200 copy "" act]]
  btn "Button" [
    if not txt: req "Button text:" "" [return]
    ad reduce ['btn txt act]
  ]
  check [ad reduce ['check (to-set-word "CHECK1")]]
  image logo.gif 80x20 [
    if not img: request-file/only [return]
    ad reduce ['image (to-set-word "IMAGE1") img act]
  ]
  text "TEXT" [ad reduce ['text "TEXT" act]] return
  area 200x60 trim {Type some default text which you
      want to appear in this area (or just
      erase this), then press the TAB key.} [
    ad reduce ['area (to-set-word "AREA1") "200x100" face/text]
  ] 
  text-list 200x60 data ["This is a text-list" "ITEM1" "ITEM2"] [
    ms: copy []
    do itms: [if m: req "Add line to textlist:" "" [append ms m  do itms]]
    ad reduce ['text-list (to-set-word "TEXTLIST1") "200x100" ms act]
  ] return
  box wheat 50x24 "Box" [
    ad reduce ['box (to-set-word "BOX1") "50x50" red "TEXT" act]
  ]
  text "Across" [ad [across]]  text "Below" [ad [below]]
  text "Return" [ad [return]]  text "Do" [ad reduce ['do act]]
  below  bar 410  h3 {EDIT this code (sizes, "texts", UPPERCASE labels)}
  code: area wrap 410x200 [g: load code/text] across  btn "Save/RUN" [run]
  btn "Load" [if request "Erase current app?" [attempt [
    set-face code mold g: load find/tail read %r.r "layout"
  ]]]
]