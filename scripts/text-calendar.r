REBOL [
    title: "Text Calendar"
    date: 31-Jan-2016 
    file: %text-calendar.r
    author:  Nick Antonaccio
    purpose: {
        Prints a calendar for every month, in the year chosen by the user
        (by default, the current year).
    }
]
if "" = y: ask "Year (ENTER for current):^/^/" [prin y: now/year]
foreach m system/locale/months [
  prin rejoin ["^/^/     " m "^/^/ "]
  foreach day system/locale/days [prin join copy/part day 2 " "]
  print ""  f: to-date rejoin ["1-"m"-"y]  loop f/weekday - 1 [prin "   "]
  repeat i 31 [
    if attempt [c: to-date rejoin [i"-"m"-"y]][
      prin join either 1 = length? form i ["  "][" "] i
      if c/weekday = 7 [print ""] 
    ]
  ]
] print "^/"  halt