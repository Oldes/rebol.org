REBOL [
    title: "Watch Various Webcams"
    date: 11-mar-2011
    file: %watch-various-webcams.r
    purpose: {
        Display video feeds from more than 130 live webcam servers.  
        The code used to gather the list of validated working cam URLs
        is also provided.
    }
]
view w: layout [
  i: image 320x240 
  text-list 320x200 data load http://re-bol.com/cams.txt [
    forever [
      set-face i load pick get-face face 1  wait 1
      if not viewed? w [quit]
    ]
  ]
]

; here's the code used to gather the list of validated working cam URLs:

repeat i 363 [append cams:[] rejoin [http://207.251.86.238/cctv i ".jpg"]]
bad-image: load http://207.251.86.238/cctv1.jpg
foreach cam cams [if bad-image <> load cam [print cam append c:[] cam]]
editor c
save ftp://user:pass@url.com/public_html/cams.txt c