REBOL [
    title: "HTML Form Generator and Server"
    date: 1-Jan-2017
    file: %html-form-generator-and-server.r
    author:  Nick Antonaccio
    purpose: {
        Creates an HTML form, with any fields, areas, check boxes,
        and drop-down selectors you specify, then runs a server to
        collect any data entered into the form by users.  A cgi version
        is also provided, which can be run on most shared host providers.
        A little GUI app is also provided to demonstrate how search and
        browse collected data.
        Taken from http://re-bol.com/examples.txt
    }
]
view center-face gui: layout [
    style area area 500x100
    across
    h4 200 "Form Title:" 
    h4 200 "Data File:" return
    f1: field 200 "Form #1"
    f2: field 200 "form1.db"
    below
    h4 "FORM CHECK BOX OPTIONS:"
    a1: area {Uploaded To Server^/Private/Secure}
    h4 "FORM TEXT ENTRY FIELDS:"
    a2: area {Name^/Date^/Location^/Device Model^/File Name}
    h4 "FORM TEXT ENTRY AREAS:"
    a3: area {Description^/Notes}
    h4 "FORM DROPDOWN SELECTIONS:"
    a4: area {---COLOR^/Red^/Green^/Blue^/---OPTION^/AAA^/BBB^/CCC}
    across
    btn "SUBMIT" [
        checks: parse/all a1/text "^/" remove-each i checks [i = ""]
        texts: parse/all a2/text "^/" remove-each i texts [i = ""]
        areas: parse/all a3/text "^/" remove-each i areas [i = ""]
        drops: parse/all a4/text "^/" remove-each i areas [i = ""]
        title: join uppercase f1/text ":"
        data-file: to-file f2/text
        unview
    ]
    btn "Save" [
        save to-file request-file/save/file %formsettings reduce [
            f1/text f2/text a1/text a2/text a3/text a4/text
        ]
    ]
    btn "Load" [attempt [
        settings: load to-file request-file/file %formsettings
        f1/text: settings/1 f2/text: settings/2 a1/text: settings/3
        a2/text: settings/4 a3/text: settings/5 a4/text: settings/6
        show gui
    ]]
]
poll: copy "^/"
repeat i len: length? checks [
    append poll rejoin [
        {<input type="checkbox" name="checks" value="} i {">}
        checks/:i {<br>} newline
    ]
]
append poll {<br>}
repeat i len: length? texts [
    append poll rejoin [
        texts/:i {:<br><INPUT TYPE="TEXT" NAME="text} i 
        {" SIZE="38"><br>} newline
    ]
]
append poll {<br>}
repeat i len: length? areas [
    append poll rejoin [
        areas/:i {:<br><TEXTAREA COLS="40" ROWS="3" NAME="area} i 
        {"></TEXTAREA><br>} newline
    ]
]
append poll {<br>}
repeat i len: length? drops [
    either find drops/:i "---" [
        closer: either i = 1 [{}][{</option></select><br>}]
        append poll rejoin [
            closer newline droptitle: replace/all drops/:i "---" ""
            {: <select NAME="} droptitle {">}
        ]
    ][
        append poll rejoin [{<option>} drops/:i]
    ]
]
append poll {</option></select><br>^/}
append poll {<br><INPUT TYPE="SUBMIT" NAME="Submit" VALUE="Submit">^/}
either exists? data-file [responses: load data-file][responses: copy[]]
port: open/lines tcp://:80
l: read join dns:// read dns://
print rejoin ["Waiting on:  " l] 
browse join l "?"
forever [
    p: first port
    if error? try [
        z: decode-cgi replace next find first p "?" " HTTP/1.1" ""
        if not empty? z [
            append z reduce [to-set-word 'timestamp now]
            append/only responses z
            save data-file responses
            received: construct z  ?? received
        ]
        d: rejoin [
            {HTTP/1.0 200 OK^/Content-type: text/html^/^/
            ^/<HTML><BODY><FORM ACTION="} l {">} title {<br><br>} poll
            {</FORM></BODY></HTML>}
        ] 
        write-io p d length? d
    ] [] ;[print "(empty submission)"]
    close p
]
halt


; Here's a CGI version you can run on shared hosts:

#!/usr/bin/rebol.exe -cs
REBOL [title "HTML form builder (CRUD app maker)"]
print "content-type: text/html^/"
print [<HTML><HEAD><TITLE>"Formbuilder"</TITLE></HEAD><BODY>]
submitted: decode-cgi submitted-bin: read-cgi
if ((submitted/2 = none) or (submitted/4 = none)) [
    print rejoin [{
    <FORM METHOD="post">
      Form File: <BR>
      <input type=text size="50" value="form1.html" name="formtitle"><BR>
      Data File: <br>
      <input type=text size="50" value="form1data.db" name="datafile"><BR>
      FORM CHECK BOX OPTIONS:<BR>
      <TEXTAREA COLS="40" ROWS="3" NAME="checks">}
          {Uploaded To Server^/Private/Secure</TEXTAREA><br>
      FORM TEXT ENTRY FIELDS:<br>
      <TEXTAREA COLS="40" ROWS="3" NAME="texts">}
          {Name^/Date^/Location^/Device Model^/File Name</TEXTAREA><br>
      FORM TEXT ENTRY AREAS:<br>
      <TEXTAREA COLS="40" ROWS="3" NAME="areas">}
          {Description^/Notes</TEXTAREA><br>
      FORM DROPDOWN SELECTIONS:<br>
      <TEXTAREA COLS="40" ROWS="3" NAME="drops">}
          {---COLOR^/Red^/Green^/Blue^/---OPTION^/AAA^/BBB^/CCC}
          {</TEXTAREA><br><br>
      <INPUT TYPE=hidden NAME="formsubmitted" VALUE="formsubmitted">
      <INPUT TYPE="SUBMIT" NAME="Submit" VALUE="Submit">
    </FORM>
    </BODY></HTML>}]
    quit
]
if submitted/14 ="formsubmitted" [
    checks: parse/all submitted/6 "^/" remove-each i checks [i = ""]
    texts: parse/all submitted/8 "^/" remove-each i texts [i = ""]
    areas: parse/all submitted/10 "^/" remove-each i areas [i = ""]
    drops: parse/all submitted/12 "^/" remove-each i areas [i = ""]
    title: submitted/2
    data-file: to-file submitted/4
    poll: copy {<FORM METHOD="post" action="index.cgi">^/}  
    ; EDIT ABO8VE TO MATCH FILE NAME OF THIS SCRIPT
    append poll {<INPUT TYPE=hidden NAME="formdata" VALUE="formdata">^/}
    append poll rejoin [
        {<INPUT TYPE=hidden NAME="datafile" VALUE="} data-file {">^/}
    ]
    repeat i len: length? checks [
        append poll rejoin [
            {<input type="checkbox" name="checks" value="} i {">}
            checks/:i {<br>} newline
        ]
    ]
    append poll {<br>}
    repeat i len: length? texts [
        append poll rejoin [
            texts/:i {:<br><INPUT TYPE="TEXT" NAME="text} i 
            {" SIZE="38"><br>} newline
        ]
    ]
    append poll {<br>}
    repeat i len: length? areas [
        append poll rejoin [
            areas/:i {:<br><TEXTAREA COLS="40" ROWS="3" NAME="area} i
            {"></TEXTAREA><br>} newline
        ]
    ]
    append poll {<br>}
    repeat i len: length? drops [
        either find drops/:i "---" [
            closer: either i = 1 [{}][{</option></select><br>}]
            append poll rejoin [
                closer newline droptitle: replace/all drops/:i "---" ""
                {: <select NAME="} droptitle {">}
            ]
        ][
            append poll rejoin [{<option>} drops/:i]
        ]
    ]
    append poll {</option></select><br>^/}
    append poll {<br><INPUT TYPE="SUBMIT" NAME="Submit" VALUE="Submit">
        </FORM>}
    write to-file submitted/2 poll 
    print rejoin [
        {<strong><a href="./} submitted/2 {">} submitted/2
        {</a></strong> created:<br><br>}
    ]
    print poll
]
if submitted/2 = "formdata" [
    append submitted reduce [to-set-word 'timestamp now]
    write/append to-file submitted/4 mold at submitted 5
    print "<strong>Saved:</strong><br><br>" 
    probe submitted
]
quit


rebol [title: "Search HTML Logs"]
data: load %./form1.db
view layout [
    h4 "Search Phrase:"
    f1: field
    h4 "Search Fields: (CTRL to select multiple)"
    t1: text-list data ["text1" "text2" "text3" "text4" "text5" "area1"]
    btn "Search" [
        foreach record data [
            obj: construct record
            foreach field t1/picked [
                if find (get in obj to-lit-word field) f1/text [
                    print rejoin [
                        mold f1/text " found in " field ", " obj/timestamp
                    ]
                ]
            ]
        ]
    ]
    h4 "View Record (paste timestamp in field)"
    f2: field
    btn "View" [
        foreach record data [
            obj: construct record
            if (form get in obj 'timestamp) = f2/text [
                editor obj 
            ]
        ]
    ]
]