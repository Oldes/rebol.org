REBOL [
    title: "1 million rows grid - simplest"
    date: 11-mar-2017
    file: %1-million-rows-grid1.r
    author:  Nick Antonaccio
    purpose: {
        Simplest demo of grid data display, using VID's 'list style
        See http://re-bol.com/grid-list.r for more features
    }
] 
sp: 0  repeat i 1000000 [repend/only x:[] [i random now random "abcd"]]
view layout [
  across li: list 310x400 [
    across  text 55 blue  text 170  text 80 brown
  ] supply [
    face/text: either e: pick x count: count + sp [e/:index][none]
  ]
  sl: slider 20x400 [sp: value * length? x  show li]
]