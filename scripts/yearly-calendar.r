REBOL [
    title: "Yearly Calendar"
    date: 3-feb-2017
    file: %yearly-calendar.r
    author:  Nick Antonaccio
    purpose: {
        Displays a calendar for the entire year chosen by the user.
        Click any date to edit that day's events.
    }
]
year: request-text/title/default "Year:" "2017"
write/append %mycal.txt ""
g: copy [
  size 595x480  space 0x0 across origin 15x10
  style txt info 18x18 font [name: "courier new"] edge [size: 0]
  style bn txt [
    d: to-date rejoin [face/text face/user-data]
    view/new center-face layout [ 
      txt bold form d 
      a: area form select (l: load %mycal.txt) d 
      btn "Save" [save %mycal.txt head insert l reduce[d a/text] unview]
    ] 
  ]
]
new-col: 160x10
foreach month system/locale/months [
  append g reduce ['txt 165 form month 'return]
  foreach day system/locale/days [
    append g reduce ['txt copy/part day 2]
  ]
  append g  'return
  f: to-date rejoin ["1-" month "-" year]
  w: 1  ; # of week lines in month
  loop (c: f/weekday - 1) [append g reduce ['box 18x18]]
  if c = 0 [w: w - 1]
  repeat i 31 [
    c: c + 1  ; at 7 days per line, start new line
    if attempt [to-date rejoin [i "-" month "-" year]][
      if c - 1 // 7 = 0 [append g 'return  c: 1  w: w + 1]
      append g reduce [
        'bn 'right form i 'with compose [
          user-data: (rejoin ["-" month "-" year])
        ]
      ]
    ]
  ]
  either (index? find system/locale/months month) // 3 = 0 [
    append g reduce ['origin new-col]
    new-col: new-col + 145x0
  ] [
    if w < 6 [append g reduce ['return 'box 18x18 'return]]
    append g reduce ['return 'box 18x18 'return]
  ]
]
view layout g