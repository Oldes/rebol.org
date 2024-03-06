REBOL [
    title: "Tic Tac Toe"
    date: 26-mar-2018
    file: %tic-tac-toe.r
    purpose: {
        A 5 minute response to:
        https://blog.plan99.net/reacts-tictactoe-tutorial-in-kotlin-javafx-715c75a947d2
    }
]
win?: func [f] [
  f/text: either turn: not turn ["X"]["O"]  show f
  lay: copy "" repeat i 9 [do rejoin ["append lay b" i "/text"]]
  wx: [{xxx??????}{???xxx???}{??????xxx}{x??x??x}{??x?x?x??}{x???x???x}]
  foreach i wx [if find/any lay i [alert "X wins"]]
  wo: [{ooo??????}{???ooo???}{??????ooo}{o??o??o}{??o?o?o??}{o???o???o}]
  foreach i wo [if find/any lay i [alert "O wins"]]
] turn: false
view center-face layout [
  style b btn 50x50 font-size 30 " " [win? face]
  b1: b b2: b b3: b return b4: b b5: b b6: b return b7: b b8: b b9: b
]