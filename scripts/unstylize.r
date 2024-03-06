REBOL [
    Title: "Unstylize"
    Date: 1-Nov-2016
    Version: 1.0.0
    File: %unstylize.r
    Author: "Annick Ecuyer"
    Purpose: "Converts a style sheet to the VID stylize dialect who generated it."
    Needs: [view 1.0.0]
    Usage: {
        Two functions: 'unstylize and 'save-styles

        [unstylize]

            unstylize /styles stylesheet

        Converts a style sheet:
            [
                BUTTON make object! [...]
                TOGGLE make object! [...]
                ...
            ]
        to a style sheet specification:
            [
                BUTTON: FACE 100x24 with [...]
                TOGGLE: BUTTON with [...]
                ...
            ]

        Style sheet definition block for all the VID styles:
            styles: unstylize

        Style sheet definition block for a specific style sheet:
            styles: unstylize/styles stylesheet

        Style sheet definition for a specific style:
            styles: unstylize/styles compose [button (get-style 'button)]

        Compatible with 'stylize:
            stylesheet: stylize unstylize

        [save-styles]

            save-style where /style stylesheet /header header-data

        Write a formatted style specification (master style sheet) to a file.
            save-styles %view-styles.r

        The generated script is 'do-able:
            stylesheet: do %view-styles.r

        where :

        Destination can be a string too:
            save-styles styles: copy {}
            write %vid-styles.r

        or none:
            write %my-styles.r save-styles/styles none my-styles

        /styles :

        Write a formatted style specification (custom style sheet) to a file.
            save-styles/styles %view-styles.r stylesheet

        /header :

        Specifies the script header to use:
            save-styles/header %view-styles.r compose [
                Title: "VID Styles"
                Date: (system/build)
                Version: (system/version)
            ]

        Disables the script header:
            save-styles/header %view-styles.r none
    }
    Library: [
        level: 'intermediate
        platform: 'all
        type: [tool]
        domain: [testing ui gui vid dialects]
        tested-under: [
            view 1.0.0  on [WinXP]
            view 1.2.10 on [WinXP]
            face 2.7.8  on [WinXP]
            view 2.7.8  on [WinXP]
        ]
        support: none
        license: 'bsd
        see-also: none
    ]
]

unstylize: func [
    "Returns a style specification."
    /styles
        stylesheet [block!] "Source style sheet (default: master)"
    /local specs
] [
    stylesheet: any [stylesheet all [
        in system/view 'vid system/view/vid
        in system/view/vid 'vid-styles system/view/vid/vid-styles
    ] copy []]
    specs: copy []

    foreach [style face] stylesheet [
        if word? face [face: get :face]
        if all [in face 'facets block? face/facets] [
            append specs compose [(to-set-word style) (face/style) (face/facets)]
        ]
    ]

    specs
]

save-styles: func [
    "Saves style specification to a file."
    where [file! url! binary! string! none!] "Where to save it."
    /styles
        stylesheet [block!] "Source style sheet (default: master)"
    /header "Uses the supplied REBOL header"
         header-data [block! object! logic! none!] "Header block or object, TRUE for default, or NONE for none"
    /local out emit pad name def
] [
    stylesheet: any [stylesheet all [
        in system/view 'vid system/view/vid
        in system/view/vid 'vid-styles system/view/vid/vid-styles
    ] copy []]
    out: either any [binary? where string? where] [where] [copy ""]
    emit: func [value] [append out join "" value]
    pad: copy "    "

    if any [none? header all [header header-data]] [
        header-data: any [
            all [block?  header-data make object! header-data]
            all [object? header-data header-data]
            make object! [Title: "Style Sheet" Date: now]
        ]
        emit ["REBOL [" newline]
        foreach word either value? 'words-of [words-of header-data][next first header-data][
            emit [
                pad mold to-set-word word " "
                either word? header-data/:word [mold to-lit-word header-data/:word] [mold header-data/:word]
                newline
            ]
        ]
        emit ["]" newline newline]
    ]

    emit ["stylize [" newline]
    parse unstylize/styles stylesheet [
        any [
            copy name set-word! (emit [pad mold name/1 " "])
            copy def [to set-word! | to end] (
                emit [copy/part next def: mold def back tail def newline]
            )
            [end | (emit [newline])]
        ]
    ]
    emit ["]" newline]

    if any [file? where url? where] [write where out]
    out
]