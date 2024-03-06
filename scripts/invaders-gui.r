REBOL [
    title: "Invaders (GUI version)"
    date: 11-Jan-2016 
    file: %invaders-gui.r
    author:  Nick Antonaccio
    purpose: {
        The draw dialect is not used in this example, only VID GUI,
        so it's short and full featured for a tiny example.  A video
        explaining the code is at https://youtu.be/NbbHRaG3K8c
        Taken from http://re-bol.com/short_rebol_examples.r
        ; KEYS:  a=left s=right space=fire
        ; VARS: b boxes m missile s invaders l player e end-func p speed d dir
    }
] 
e: func[x][alert x q]s:[2 3 4 5 6 32 33 34 35 36]p: .1 m: 0 l: 586 d: 1 g:[
  key #"a"[if l > 571 [do rejoin["b"l"/image:{}"]l: l - 1]]
  key #"s"[if l < 600 [do rejoin["b"l"/image:{}"]l: l + 1]]
  key #" "[if m < 1[m: l]] across origin 0x0 space 1x1 backcolor snow
] repeat i 600[
  repend g[to-set-word join"b"i 'box 20x20]
  if i // 30 = 0[append g 'return]
] w: view/new layout g forever[
  remove find s m attempt[do rejoin["b"m"/image:{}"]]if s =[][e"Win!"]
  repeat i length? s[do rejoin["b"s/:i"/image:{}"]] 
  oldd: d  foreach i s[if i // 30 = 0[d: no] if i // 30 = 1[d: yes]]
  if oldd <> d[repeat i length? s[s/(:i): s/:i + 30]]  p: p - .0002  
  repeat i length? s[
    either d[s/(:i): s/:i + 1][s/(:i): s/:i - 1]
    if error? try[do rejoin["b"s/:i"/image: stop.gif"]][e"Lose!"]
  ]attempt[do rejoin["b"m"/text:{}"]m: m - 30 do rejoin["b"m"/text:{|}"]]
  do rejoin["b"l"/image: info.gif"] show w  if not viewed? w[q]  wait p
]

