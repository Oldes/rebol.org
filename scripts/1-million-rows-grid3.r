REBOL [
    title: "1 million rows grid 3"
    date: 11-mar-2017
    file: %1-million-rows-grid3.r
    author:  Nick Antonaccio
    purpose: {
        Demo of grid data display, with lots of features (save/load, add/remove, undo,
        multiline edit, sort, search, key scroll, separator lines, etc.) using VID's 'list style.
        See the minimal examples (grids 1 and 2) to learn the basics about using the
        VID list widget.
    }
] 
REBOL [title: "GRID: SAVE/LOAD, ADD/REMOVE, UNDO, EDIT, SORT, FIND, KEYS"]
sp: 0   asc: false   mx: cnt: 9999
repeat i cnt [repend/only x:[] [i random now join random"ab"random"cde^/"]]
scrl: func [arg] [sp: sp + arg  sl/data: sp / length? x  show g]
srt: func [f] [
  sort/compare x func[a b][(at a f) < (at b f)]
  if asc: not asc [reverse x] show li
]
do [request-big: do replace replace replace mold :request-text 
  {field 300} "area 400x300" {with [flags: [return]]} "" {194} "294"]
updt: func [f] [f/text: request-big/default f/text show li]
view center-face g: layout [
  across h4 "ID" 55 [srt 1] h4 "Date" 170 [srt 2] h4 "Text" [srt 3] return
  li: list 330x400 [
    across
    text 55 blue [cnt: face/data]
    text 170 
    text 80x30 rebolor [updt face]
    return box black 400x1
  ] supply [
    if none? e: pick x count: count + sp [face/text: none exit]
    face/text: pick e index   face/data: count
  ]
  sl: slider 20x400 [sp: value * length? x  show li]  return
  btn #"^~" "Remove" [ud: first at x cnt  remove at x cnt  show li]
  btn "Undo" [if value? 'ud [insert/only at x cnt ud unset 'ud show g]]
  btn "Add" [
    mx: mx + 1
    insert/only at x ++ cnt + 1 reduce[mx random now random "abcd"] show li
  ]
  btn "Search" [
    if find reduce[p: request-list"Field:"[1 2 3]h: request-text]none[exit]
    u: copy[] foreach i x [foreach [j k l] i [
      if find pick reduce [form j form k form l] p h [append u form i]
    ]] if empty? u [notify "Not found" exit] fnd: request-list "" u
    repeat i length? x [if (fnd = form x/:i)[sp: i - 1 break]] show g
  ]
  btn "Col2" [foreach [i j] x [append y:[] i/2] editor y]
  btn "Save" [attempt [save to-file request-file/save/file %grid.txt x]]
  btn "Load" [attempt [x: load request-file/only/file %grid.txt show li]]
  key keycode [down][scrl 10]  key keycode [up][scrl -10]  
]