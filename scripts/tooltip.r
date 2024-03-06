REBOL [  title: "Tooltip example  and other... to be continued  "
         file: %tooltip.r
         author: "saulius_g"
         date: 17-12-2019
         Purpose: {Simplest tooltip to VID GUIs + ... }
         
         Category: [util vid view]
         library: [
             level: 'beginner
             platform: 'win
             type: 'how-to
         ]
]    

;--- anti-aliased text ---;
stylize/master [
    a-text: text with [ 
        text-draw: none
        insert tail init [
          text-draw: text
          text: " " 
        ]
        effect: [ draw [ pen self/font/color self/font/colors/2  
                 font self/font
                 text anti-aliased self/text-draw
                ] 
             ]
    ]
]

;------------------------------------;
tooltip-size: function [tx wd] [x] [
;------------------------------------;
  x: reduce [ make face [ text: tx
    if wd > 0 [size: as-pair wd -1]
    para: make object!
      [ origin: 2x2  margin: 2x2  indent: 0x0  tabs: 40  wrap?: wd > 0  scroll: 0x0 ]
    edge: make object!
      [ color: 0.0.0  image: none  effect: none  size: 1x1 ]
    size: size-text self
  ] ]
  either wd > 0 [return as-pair wd x/1/size/2 + 6] [return as-pair x/1/size/1 + 6 20]
]

;----------------------------------;
helper: function [f a] [tx w xy] [
;----------------------------------; 
  either a [ either block? f/h [tx: f/h/1 w: f/h/2] [tx: f/h w: -1] 
             either find f 'xy  [xy: f/xy] [xy: 0x0]
             tooltip/text: tx
             tooltip/size: tooltip-size tx w
             tooltip/offset: f/offset + (as-pair 0 f/size/y) + xy
             show tooltip ] 
           [hide tooltip]
]


L: layout/size [
   
  button "1"    with [h: "button 1 red"]                     feel [over: :helper]  red  

  button "2"    with [h: ["button2 width 200" 200]]          feel [over: :helper]  blue
  
  button "3"    with [h: ["button3 width 60" 60]]            feel [over: :helper]  yellow

  button "Exit" with [h: "button 4 shift offset" xy: 40x-40] feel [over: :helper]  green [halt] 

  text   "SO" font-name 'Verdana font-size 100 black white
  a-text "SO" font-name 'Tahoma  font-size  100 black white 

  ;--- Last element ---;
  tooltip: text " " as-is edge [size: 1x1 color: 112.112.112] 0.0.0 255.255.224  with [show?: false]
                    rate 00:00:02 feel [engage: func [f a e] [ if a = 'time [hide tooltip] ] ]
]  200x440

view/title center-face L " "