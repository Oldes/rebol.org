REBOL [
    title: "Hangman, with word generator"
    date: 1-Jan-2016
    file: %hangman.r
    author:  Nick Antonaccio
    purpose: {
        A little hangman game, from http://re-bol.com/short_rebol_examples.r
    }
]
body: [[line 1x20 400x20] [line 200x20 200x40] [circle 200x60 20]
[line 200x80 200x120] [line 200x100 160x80] [line 200x100 240x80] 
[line 200x120 170x150] [line 200x120 230x150]]
wrds: remove-each wrd copy first system/words [(length? form wrd) < 4]
foreach c "!?-.~+*'1234567890" [remove-each wrd wrds [find form wrd c]]
random/seed now   wrd: form first random wrds
gui: [
    a: area 400x200 effect [draw []]  across
    s: text 140 font-size 30
    text "Guesses:"  k: text 190 font-size 25  return
    style bt btn 38x38 [
        append k/text copy face/text
        if not find wrd face/text [
            append a/effect/draw body/1  remove head body
        ]
        foreach char s/text: copy wrd [if not find k/text char [
            replace/all s/text char "*"
        ]] show g
        if wrd = s/text [alert "You win!"  q]
        if empty? body [alert join "No, it was: " wrd  q]
    ]
    do [loop length? wrd [append s/text "*"]]
]
repeat c length? cs: "abcdefghijklmnopqrstuvwxyz" [
    append gui reduce ['bt form pick cs c]
    if 0 = (c // 9) [append gui 'return]
] view center-face g: layout gui