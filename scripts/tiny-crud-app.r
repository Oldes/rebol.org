REBOL [
    title: "Tiny Generic CRUD App" 
    date: 6-Jan-2017
    file: %tiny-crud-app.r
    author:  Nick Antonaccio
    purpose: {
        A very short generic data storage/retrieval app example.
        CRUD = create read update delete records.  This can be used
        as the basis for any sort of rolodex-like app which allows users
        to enter and edit 'cards' full of information.
        From http://re-bol.com/short_rebol_examples.r
    }
]
f: no  n: [clear-fields gui a/text: none show gui focus f1 f: no]
x: [write/append %d reduce[mold f1/text mold f2/text mold a/text]]
y: [attempt[r: copy/part find d: load %d request-list"" extract d 3 3
f1/text: r/1 f2/text: r/2 a/text: r/3 show gui f: yes]]
z: [attempt[save %d head remove/part find d: load %d f1/text 3 do n]]
view gui: layout[f1: field"Name" f2: field"Phone" a: area"Notes" across 
    btn"New"[do n] btn"Save"[do x do either f[z][n]] 
    btn"Load"[do y] btn"Delete (right-click)"[][do z] btn"Raw"[editor %d]
]