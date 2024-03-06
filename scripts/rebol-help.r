REBOL [
    title: "Rebol Help"
    date: 5-feb-2017
    file: %rebol-help.r
    author:  Nick Antonaccio
    purpose: {
        Provides help for all functions, various elements of VID (GUI system), 
        key codes, colors, built in images, etc. which are the source of
        common questions by Rebol users.
    }
]
print ""
insert-event-func func [f e] [if e/type = 'key [print mold e/key] e]
remove-each i (fcts: copy svv/facet-words) [any-function? :i]
hlp: [
  size 720x500  h4 {VID Styles (GUI widgets):}
  text-list 180x150 data extract svv/vid-styles 2 [
    set-face a copy form z: select svv/vid-styles value  focus a
    if z/words [
      alert join "Special: " replace/all form z/words "?function?" ""
    ]
  ] return 
  h4 "Layout Words:" text-list 105x150 data svv/vid-words return
  h4 "Facet Words:" text-list 105x150 data fcts return
  at 20x200 a: area 410x160
  h4 "Built in images (click for label):" across
]
cnt: 1  foreach i is: svv/image-stock [
  if image! = type? i [
    append hlp reduce ['image i ] 
    append/only hlp compose [alert form pick is(index? find is i)- 1]
    cnt: cnt + 1 if cnt = 9 [append hlp 'return]
  ]
]
append hlp [return h2 underline "Type any key to see its key code"]
w: copy []  colors: copy []  foreach i copy first system/words [
  attempt [if any-function? get to-word i [append w i]]
  attempt [if tuple? get to-word i [append colors to-word i]]
] 
append hlp [
  origin 440x20 h4 "Functions" return 
  text-list 150x440 data sort w [x: to-word value ? :x]
  origin 600x20 text 80 bold "Colors:" return space 0x0
] c: 0
foreach color colors [
  append hlp reduce ['text 'font-size 10 62 color form color] 
  c: c + 1 if c = 2 [append hlp 'return c: 0]
] 
view center-face layout hlp