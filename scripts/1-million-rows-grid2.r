REBOL [
    title: "1 million rows grid 2"
    date: 11-mar-2017
    file: %1-million-rows-grid2.r
    author:  Nick Antonaccio
    purpose: {
        Demo of grid data display, with some features (edit, save, arrow keys scroll), 
        using VID's 'list style
        See http://re-bol.com/grid-list.r for more features
    }
] 
sp: 0 repeat i 1000 [repend/only x:[] [form i form random now copy"abcd"]]
scrl: func [arg] [sp: sp + arg  sl/data: sp / length? x  show g]
updt: func [f] [f/text: request-text/default f/text show li]
view g: layout [
  across li: list 310x400 [
    style tx text [updt face]  across  tx 55 blue  tx 170  tx 80 brown
  ] supply [
    face/text: either e: pick x count: count + sp [e/:index][none]
  ] sl: slider 20x400 [sp: value * length? x  show li]  return
  btn "Save" [save to-file request-file/save/file %grid.txt x]
  key keycode [down][scrl 10]  key keycode [up][scrl -10]
]