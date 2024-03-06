REBOL [
    title: "Snake Game (tiny GUI version)"
    date: 6-Jan-2016 
    file: %snake-gui.r
    author:  Nick Antonaccio
    purpose: {
        The draw dialect is not used in this example, only VID GUI,
        so it's short and full featured for a tiny example.  A video
        explaining the code is at https://youtu.be/rnKvmwe2F6w
        Taken from http://re-bol.com/short_rebol_examples.r
        Variables Key:  f food  p speed  d direction  s snake-block  g gui  e end  i count
    } 
]
random/seed now  f: random 400  p: .3  d: 20  s:[1]  g:[
  across key #"w"[d: -20]key #"s"[d: 20]key #"a"[d: -1]key #"d"[d: 1]origin
] repeat i 400 [
  append g reduce [to-set-word join "p"i 'box 'snow 20x20]
  if i // 20 = 0 [append g 'return]
] e: does [alert "Oops" q]  w: view/new layout g  forever [
  if any [all[d = -1 s/1 // 20 = 1] all[d = 1 s/1 // 20 = 0]] [e]
  if find s h: s/1 + d[e]insert head s h do rejoin["p"last s"/color: snow"]
  either f = s/1 [f: random 400  p: p - .01][remove at s length? s]
  repeat i length? s[if error? try[do rejoin["p"s/:i"/color: red"]][e]]
  do rejoin ["p"f"/color: blue"]  show w  if not viewed? w [q]  wait p
]