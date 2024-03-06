REBOL [
    Title: "Save Scheme"
    Date: 2-Nov-2016
    Version: 1.0.0
    File: %save-scheme.r
    Author: "Annick Ecuyer"
    Purpose: "Saves scheme specification to a file."
    Usage: {
        save-scheme where scheme /header header-data

        Write a formatted scheme specification to a file:
            save-scheme %ftp-protocol.r 'ftp
        Do-ing the generated script install the protocol:
            do %ftp-protocol.r

        * where [string! binary! file! url! none!]

        Destination can be a string too:
            save-scheme scheme: copy {} 'nntp
            write %nntp-protocol.r
        or none:
            write %nntp-protocol.r save-scheme none 'nntp

        * scheme [word! object! port!]

        The scheme can be a word:
            save-scheme %http-protocol.r 'http
        an object:
            save-scheme %http-protocol.r system/schemes/http
        a port (opened or not):
            port: open http://www.rebol.net
            close port
            save-scheme %http-protocol port

        * /header header-data [block! object! logic! none!]

        Specify the script header to use:
            save-scheme/header %whois-protocol.r compose [
                Title: "WhoIs"
                Date: (system/build)
                Version: (system/version)
            ]
        Disable the script header:
            save-scheme/header %daytime-protocol.r 'Daytime none
    }
    Library: [
        level: 'intermediate
        platform: 'all
        type: [tool]
        domain: [testing debug protocols schemes dialects]
        tested-under: [
            core 2.2    on [Macintosh os755-68k]
            view 1.0.0  on [Amiga os31-68k]
            view 1.2.10 on [Windows xp-x86]
            core 2.7.8  on [Macintosh osx-x86]
            saphir-view 2.101.0 on [Macintosh osx-x86]
        ]
        support: none
        license: 'bsd
        see-also: none
    ]
]
save-scheme: func [
    "Saves scheme specification to a file."
    where  [file! url! binary! string! none!] "Where to save it."
    scheme [word! object! port!] "Scheme to save."
    /header "Uses the supplied REBOL header"
        header-data [block! object! logic! none!] "Header block or object, TRUE for default, or NONE for none"
    /local
        emit out pad
        words? search-word compare-objects list-fields
        differences template scheme-name
][
    scheme: any [
        all [word? scheme get in system/schemes scheme]
        all [port? scheme object? scheme/scheme scheme/scheme]
        scheme
    ]
    if error? try [scheme-name: scheme/scheme] [scheme-name: scheme/name]

    out: either any [binary? where string? where] [where] [copy ""]
    emit: func [value][append out join "" :value]
    pad: copy "    "

    words?: either value? 'words-of [:words-of][func [value][next first :value]]
    search-word: func [value][
        foreach word words? system/words [
            if all [value? word: in system/words word] [
                if same? get word :value [return word]
            ]
        ]
        none
    ]
    compare-objects: func [
        object1 object2
        /local changed append-field field-type
    ][
        changed: copy []

        append-field: [
            append changed to-word field
            field-type: type? field: get f: in object2 :field 
            append changed any [
                all [find [native! action!] to-word mold field-type
                    join "get in system/words '" to-word mold search-word :field]
                all [word! = field-type
                    mold to-lit-word field]
                all ['port-flags = last changed any [
                    all [
                        field = system/standard/port-flags/direct
                        "system/standard/port-flags/direct"
                    ]
                    all [
                        field = system/standard/port-flags/pass-thru
                        "system/standard/port-flags/pass-thru"
                    ]
                    mold system/standard/port-flags/pass-thru
                ]]
                mold :field
            ]
        ]

        foreach field words? object1 [
            if (load mold get in object1 field) <> (load mold get in object2 field)
                bind append-field 'field
        ]

        foreach field skip words? object2 length? words? object1
            append-field

        changed
    ]
    list-fields: func [fields padding /interline] [
        if object? fields [fields: compare-objects make object! [] fields]
        padding: join "" padding
        foreach [field value] fields compose/deep [
            emit [(padding)
                mold :field
                ": "
                replace/all copy value "^/" (join "^/" padding)
                newline
                (either interline [newline][""])
            ]
        ]
    ]

    if any [none? header all [header header-data]] [
        header-data: any [
            all [block?  header-data make object! header-data]
            all [object? header-data header-data]
            make object! [Title: join mold scheme-name " Protocol" Date: now]
        ]
        emit ["REBOL [" newline]
        list-fields header-data [pad]
        emit ["]" newline newline]
    ]

    either value? 'Root-Protocol [
        emit ["make Root-Protocol [" newline]
        emit [pad {"} form scheme/scheme { protocol."} newline newline]
        list-fields/interline compare-objects Root-Protocol scheme/handler [pad]
        emit [pad
            "net-utils/net-install "
            form scheme-name
            " self "
            scheme/port-id
            newline
        ]
        template: [scheme: port-id: handler: proxy: passive: cache-size: none]
        differences: either port? scheme [
            []
        ][
            compare-objects
                make system/standard/port template
                make scheme template
        ]
        if not empty? differences [
            emit [pad
                "system/schemes/"
                scheme/scheme
                ": make system/schemes/"
                scheme/scheme
                " [" newline
            ]
            list-fields differences [pad pad]
            emit [pad "]" newline]
        ]
        emit ["]" newline]
    ][
        emit ["sys/make-scheme [" newline]
        emit [pad "name: '" mold scheme/name newline]
        emit [pad "title: " mold scheme/title newline]
        if all [not none? in scheme 'spec object? scheme/spec] [
            template: either find words? scheme/spec 'host [
                'system/standard/port-spec-net
            ][
                'system/standard/port-spec-head
            ]
            differences: compare-objects get template scheme/spec
            emit [pad "spec: make " form template " ["]
            either empty? differences [
                emit ["]" newline]
            ][
                emit [newline]
                list-fields differences [pad pad]
                emit [pad "]" newline]
            ]
        ]
        if all [not none? in scheme 'info object? scheme/info] [
            template: either find words? scheme/info 'local-ip [
                'system/standard/net-info
            ][
                'system/standard/file-info
            ]
            differences: compare-objects get template scheme/info
            emit [pad "info: make " form template " ["]
            either empty? differences [
                emit ["]" newline]
            ][
                emit [newline]
                list-fields differences [pad pad]
                emit [pad "]" newline]
            ]
        ]
        either object? get in scheme 'actor [
            emit [pad "actor: [ " newline]
            foreach [field value] body-of scheme/actor [
                emit [
                    pad pad field " func "
                    replace/all mold spec-of :value "^/" join "^/" [pad pad]
                    " "
                    replace/all mold body-of :value "^/" join "^/" [pad pad]
                    newline
                ]
            ]
            emit [pad "]" newline]
        ][
            if native? get in scheme 'actor [
                emit [";" pad "actor: " mold get in scheme 'actor newline]
            ]
        ]
        either function? get in scheme 'awake [
            emit [pad
                "awake: "
                replace/all mold get in scheme 'awake "^/" join "^/" pad
                newline
            ]
        ][
            if native? get in scheme 'awake [
                emit [";" pad "awake: " mold get in scheme 'awake newline]
            ]
        ]
        differences: compare-objects
            make system/standard/scheme [name: title: spec: info: actor: awake: none]
            make scheme                 [name: title: spec: info: actor: awake: none]
        if not empty? differences [
            list-fields differences [pad]
        ]
        emit ["]" newline]
    ]
    if any [file? where url? where] [write where out]
    out
]