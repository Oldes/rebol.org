REBOL [
	Title: "Open a file or directory requester"
	Date: 16-09-2017
	Version: 1.4.11
	File: %file-requester.r
	Author: "Marco Antoniazzi"
	Rights: "Copyright (C) 2012-2017 Marco Antoniazzi"
	Purpose: "Requests a file or directory"
	eMail: [luce80 AT libero DOT it]
	History: [
		0.0.1 [02-09-2012 "First version"]
		1.0.0 [08-09-2012 "Finished"]
		1.0.1 [09-09-2012 "Minor fixes"]
		1.0.2 [21-09-2012 "Sort drop down path tree, update scroller on resize"]
		1.0.3 [27-10-2012 "Fixed what-dir for keep, returned full path"]
		1.0.4 [03-11-2012 "Minor fixes, return rebol file!"]
		1.0.5 [09-06-2013 "Fixed external loading of tooltip style"]
		1.0.6 [12-06-2013 "Fixed All filter on Linux, hide hidden files on Linux,made styles local"]
		1.0.7 [15-06-2013 "Added some key shortcuts, wheel-scroll on drop-list"]
		1.2.1 [16-06-2013 "Added multi-selection and sorting (now has same functionality as original)"]
		1.2.2 [17-06-2013 "Fixed silly bug of convert string to block of files, default All filter on Linux"]
		1.3.1 [18-06-2013 "Added file renaming (press F2)"]
		1.3.2 [21-06-2013 "Fixed list size on Linux"]
		1.3.3 [23-06-2013 "Fixed keep"]
		1.3.4 [25-06-2013 "Added selection on key, fixed multi selection"]
		1.4.1 [30-06-2013 "Added showing of sizes and dates, various fixes"]
		1.4.2 [03-07-2013 "Various fixes for key shortcuts and multi selection"]
		1.4.3 [23-11-2013 "Adapted to Rebol 3 (with vid1r3.r3)"]
		1.4.4 [08-12-2013 "Changed gather-each"]
		1.4.5 [26-02-2014 "Fixed dialogs offsets"]
		1.4.6 [23-03-2014 "Changed behavior of left-right keys, improved load-script-thru"]
		1.4.7 [12-04-2015 "Fixed find-any, fixed enquoting single file, fixed global cancelled"]
		1.4.8 [28-03-2016 "Fixed single file selection when saving, improved enter handling"]
		1.4.9 [17-04-2016 "Fixed update_list, fixed auto executing examples"]
		1.4.10 [10-06-2016 "Added if not value?"]
		1.4.11 [16-09-2017 "Fixed updating after changing sorting type"]
	]
	Note: { Filters can be in the form: "*.a" or "*.a;*.b" or "Short description (*.a)" or "Short description (*.a;*.b)" or
		a block of such strings.
		Use arrows to move in list of files.
		Use also <Ctrl> to multi-select
		Use F2 to rename currently selected file
	}
	Category: [util vid files]
	library: [
		level: 'intermediate
		platform: 'all
		type: 'function
		domain: [gui files]
		tested-under: [View 2.7.8.3.1 2.7.8.4.3 Atronix-View 3.0.0.3.3]
		support: none
		license: 'LGPL2
		see-also: none
	]
	thumbnail: http://i40.tinypic.com/nvse8h.png
	comment: "2-Sep-2012 GUI automatically generated by VID_build. Author: Marco Antoniazzi"
	todo: {
		- add possibility to not show hidden files (done for Linux)
		- allow searching
		- display preview
		- add status bar that shows number of selected files and the total size
		- check if new folder already exists
		- add /safe option when saveing to check if file already exists
	}
]
;**** please set correct path to vid1r3.r3 and sdk sources (or use empty string to use default path to sdk) ****
if all [system/version > 2.9.0 not value? 'mimic-do-event] [do/args %../../r3/local/vid1r3.r3 %../../sdk-2706031/rebol-sdk-276/source]

if not value? 'file-req-ctx [

file-req-ctx: context [
	; files, filter, new folder, rename, drop-list
		suffix?: func [
			{Return the suffix (ext) of a filename or url, else tail of it.} 
			path [any-string!]
			/local
			suff
			][
		    either all [
		        suff: find/last path #"." 
		        not find suff #"/"
		    ] [suff] [tail path]
		]

		dir?: func [file [file!]] [#"/" = last file]

		is-link?: func [file [file!] /local str] [ ; WARNING: THIS IS A DIRTY HACK!
			if all [
				equal? suffix? file %.lnk
				System/version/4 = 3 ;Win
				;System/version <= 2.7.8 ; temporarily disable for R3 since find/any does not work
				attempt [str: read file]
				equal? head str find str #{4C000000} 
			] [str]
		]
		
		undirize: func ["Returns a copy of the path turned into a file."
			path [file! string! url!]
			][
			path: copy path
			while [find "/\" pick path: back tail path 1] [remove path]
			head path
		]

		parent-dir: func ["Returns the parent directory of given path"
			file [file!]
			][
			if equal? length? file 1 [return %/]
			head clear find/tail/last undirize file %/
		]

		get-win-vols: func [/local vols drive char] [
			vols: copy []
			repeat char 26 [
				if attempt [read join %/ drive: to-file rejoin [to-char char + #"a" - 1 "/"]]  [
					append vols drive
				]
			]
			vols
		]

		online?: does [not error? try [close open tcp://www.google.com:80]]
		
		on-win?: system/version/4 = 3

		to-itime: func [time [time!]] [ ; same as to-itime but MUCH faster
			time: form to time! to integer! time ; strip micros
			if 2 = index? find time ":" [insert time "0"]
			if 5 = length? time [insert tail time ":00"]
			head time
		]

		find-any: func [
			"Finds a value in a string using wildcards and returns the string at the start of it."
			series [series!] value [string!] /match /last
			/local last* str give_head emit pos pos2 non-wild-chars plain-chars tmp rule
			][
			last*: get load "last"
			give_head: none
			str: copy series
			value: copy value
			if empty? value [return none]
			; normalize pattern
			while [find value "**"] [replace/all value "**" "*"]
			while [find value "*?"] [replace/all value "*?" "*"]
			if value = "*" [return series]
			if last [
				reverse value
				reverse str
			]
			if #"*" = first value [
				remove value
				if not any [last match] [give_head: series]
				match: none
			]

			emit: func [arg][append rule arg]

			non-wild-chars: complement charset "*?"
			plain-chars: [copy tmp some non-wild-chars (emit copy tmp)]

			rule: copy []
			parse/all value [
				some [plain-chars | "*" (emit 'thru) | "?" (emit 'skip)]
			]
			; If the last thing in our pattern is thru, it won't work so we
			; remove the trailing thru.
			if 'thru = last* rule [remove back tail rule]
			value: compose/deep [any [(all [none? match 'to]) (first rule) pos: (rule) pos2: to end | thru (first rule)] ]
			if none? parse/all str value [return none]
			if last [pos: skip series (length? series) - (index? pos2) + 1]
			any [give_head pos]
		]

		gather-each: func ['word [word!] data [series!] body [block!] /into result [block!] /local n] [;collect
			result: any [result copy []]
			foreach n data [set word n if do body [insert tail result n]]
			head result
		]

		sort_files: func [files [block!]] [
			sort/compare files func [a b] select [
				"Name" [a < b]
				"Size" [(any [size? a 0]) < any [size? b 0]] 
				"Date" [(any [modified? a 1-1-0]) < any [modified? b 1-1-0]]
			] get-face choice-sort
			if "decreasing" = get-face choice-order [reverse files]
			files
		]

		filter_and_sort: func [list [block!] /local temp-list filters par temp-dir-list temp-files-list] [
			temp-dir-list: copy list
			if not get-face check-hidden [remove-each item temp-dir-list [find-any/match to-string item ".*"]]
			remove-each item temp-dir-list [not dir? item]
			sort_files temp-dir-list
			dirs-count: length? temp-dir-list
			if only-dirs [return temp-dir-list]

			; apply filters
			filters: copy get-face choice-filter
			if par: find filters "(" [filters: next par]
			if par: find filters ")" [clear par]
			filters: parse filters ";"
			temp-list: copy []
			forall filters [
				gather-each/into item list [find-any/match item first filters] temp-list
			]

			temp-files-list: copy temp-list
			if not get-face check-hidden [remove-each item temp-files-list [find-any/match to-string item ".*"]]
			remove-each item temp-files-list [dir? item]
			sort_files temp-files-list

			clear temp-list
			insert temp-files-list temp-dir-list
			temp-files-list
		]
		
		add_folder: func [/local name][
			name: request-text/title/default/offset "Enter the new folder name below" "New folder" (screen-offset? btn-+) - 290x26
			unless none? name [attempt [make-dir path-name/:name replace_file-list path-name]]
		]
		
		rename_file: func [/local scroller-pos old-name name] [
			if (length? list-of-files/picked) = 1 [
				scroller-pos: get-face list-of-files/sld
				old-name: first list-of-files/picked
				name: request-text/title/default/offset "Enter the new file name below" form old-name (screen-offset? btn-rename) - 220x26
				unless none? name [
					attempt [
						rename old-name to-rebol-file name
						replace_file-list path-name
						set-face/no-show list-of-files/sld scroller-pos
						do-face list-of-files/sld none
					]
				]
				focus list-of-files ; to unfocus fields
			]
		]

		build_path-tree: func [/local path-tree paths n] [
			path-tree: copy []
			insert path-tree either on-win? [get-win-vols][read %/]
			remove-each item path-tree [error? try [read/part join %/ item 1]]
			forall path-tree [
				change path-tree to-local-file first path-tree
				if find "\/" last first path-tree [change path-tree head remove back tail first path-tree]
			]
			sort path-tree

			paths: parse/all path-name "/"
			paths: next next paths
			n: 0
			forall paths [insert/dup first paths " " n: n + 2]
			if (length? head paths) >= 2 [
				insert next find path-tree second head paths paths
			]

			head path-tree
		]
		show_drop-list: func [face [object!]] [
			paths-list/data: build_path-tree
			show paths-list/update
			show-popup/window/away paths-lay face/parent-face
			do-events
		]
		select_folder: func [dir [string!] /local path] [
			path: find/tail copy path-name dirize trim dir
			dir: either path [dirize head clear path][to-file rejoin ["/" dir "/"]]
			if replace_file-list dir [add_to_undo-list]
			hide-popup
		]
	; update, replace_file-list, enquote, select_line, undo

		update_list: func [/local file file-info] [
			file-list: filter_and_sort orig-file-list
			forall file-list [
				file: first file-list
				file: path-name/:file
				either file-info: info? file [
					change/only file-list reduce [file-list/1 set-size file-info/size file-info/date]
				][
					change/only file-list reduce [file-list/1 "" ""]
				]
			]
			file-list: head file-list

			clear list-of-files/data
			; update and redraw file names text-list
			append list-of-files/data file-list
			set-face list-of-files/sld 0 ; FIXME: remember and restore last scroller pos (in undo-list)
			show list-of-files/update
		]

		replace_file-list: func [dir-name [file! none!] /init /local temp-dir-list current] [
			if error? try [temp-dir-list: read dir-name] [request/ok/type/offset "Can not read directory, please verify that the name is correct" 'alert req-win/offset + 100x100 return false]
			current: what-dir
			change-dir dir-name
			focus list-of-files ; to unfocus fields
			old-path-name: path-name
			unless any [init saving path-name = dir-name] [clear-face field-selected]
			path-name: dir-name
			clear orig-file-list
			orig-file-list: copy temp-dir-list
			set-face info-path to-local-file dir-name
			fn1/state: none ; reset this to avoid re-selecting when changing dir
			fn1/user-data: none ; reset
			update_list
			clear list-of-files/picked
			if init [
				temp-dir-list: unique compose [(names)]
				forall temp-dir-list [alter list-of-files/picked to-file first temp-dir-list]
			]
			show list-of-files/update
			change-dir current
			
			true
		]
		
		enclose: func [s [series!] vals][head insert tail insert copy s first vals last vals]
		enquote: func [s [series!]][enclose s {"}]    ;-- "

		set-size: func [value [integer!] /local num um bbb div index] [
			um: [" KB" " KB" " MB" " GB"]
			bbb: [1024 1024 1048576 1073741824]
			num: value
			if num = 0 [num: 1]
			div: pick bbb index: to-integer (log-2 num) / 10 + 1 
			value: value / div
			value: case [value = 0.0 [0] value < 0.1 [0.1] 'else [round/to value 0.1]]
			rejoin ["" value pick um index]
		]
		find-data: func [data [block!] value /local item] [
			forall data [item: first data if find item value [return data]] 
		]
		select_line: func [/key dir [word!] control /local path str old-index new-index files] [
			if empty? list-of-files/data [return false]
			focus list-of-files
			if empty? path: list-of-files/picked [
				if find [up down home end] dir [
					; try to select 1st file
					append clear list-of-files/picked first pick list-of-files/data 1
					show list-of-files/update
					if not dir? first list-of-files/picked [set-face field-selected list-of-files/picked]
					fn1/user-data: 1
					return true
				]
				return false
			]
			path: first path
			either none? dir [
				case [
					dir? path [
						if replace_file-list path-name/:path [add_to_undo-list]
					]
					str: is-link? path-name/:path [ ; WARNING: THIS IS A DIRTY HACK!
						str: back find-any/last str "?:" ; find a: b: c: etc. drive letters
						str: to-string copy/part str find str #{00000000}
						str: trim/with/all str {^@} ; trim 0s
						if replace_file-list dirize to-rebol-file str [add_to_undo-list]
					]
					'else [
						files: unique list-of-files/picked
						if (length? files) > 1 [forall files [change files enquote first files]]
						set-face field-selected files
						return false
					]
				]
			][
				dir: switch/default dir [
						up [-1]
						down [1]
						;page-up [negate visible-lines]
						;page-down [visible-lines]
						home [-1000000] ; a great number
						end [1000000] ; a great number
					] [return false]
				new-index: dir + old-index: any [fn1/user-data 0]
				new-index: min max 1 new-index length? list-of-files/data
				if new-index = old-index [return false]
				fn1/user-data: new-index ; set "key-cursor"
				
				unless control [clear list-of-files/picked]
				alter list-of-files/picked first pick list-of-files/data new-index
				show list-of-files/update
				either any[empty? list-of-files/picked dir? first list-of-files/picked] [
					clear-face field-selected
				][
					files: unique list-of-files/picked
					if (length? files) > 1 [forall files [change files enquote first files]]
					set-face field-selected files
				]
				true
			]
		]
		select_line-letter: func [letter /local list line] [
			list: list-of-files/data
			if all [(length? list-of-files/picked) = 1 find/match first list-of-files/picked to-file letter] [list: next find-data list-of-files/data list-of-files/picked]
			forall list [
				if line: find/match first first list to-file letter [
					fn1/user-data: index? list ; set "key-cursor"
					line: head line
					append clear list-of-files/picked line
					show list-of-files/update
					if not dir? first list-of-files/picked [set-face field-selected list-of-files/picked]
					break
				]
			]
		]
		add_to_undo-list: does [
			if old-path-name <> path-name [insert undo-list old-path-name]
		]
		undo: does [
			if empty? undo-list [exit]
			insert redo-list path-name
			path-name: take undo-list
			replace_file-list path-name
		]
		redo: does [
			if empty? redo-list [exit]
			insert undo-list path-name
			path-name: take redo-list
			replace_file-list path-name
		]
	; gui
	
		load-script-thru: func ["Load a script from www.rebol.org thru the cache"
			name [file!]
			/flash "Flash a message to the user"
			/warn "Alert user if script not found"
			/from path [file!] "Optional path where to search for the script"
			/local cache-name modul
			][
			if not value? 'view-root [view-root: either system/version/4 = 3 [%/C/Users/Public/Documents] [%/tmp]]
			cache-name: view-root/:name
			modul: any [
				attempt [read cache-name] ; try the cache
				attempt [read name] ; try current dir
				attempt [read rejoin [undirize path "/" name]] ; try optional dir 
				attempt [ ; try downloading it from www.rebol.org
					modul: rejoin [http://www.rebol.org/download-a-script.r?script-name= name]
					read either flash [request-download/to modul cache-name cache-name][modul]
				]
			]
			if modul [clear back back tail modul: load modul] ; remove example code
			if all [not modul warn] [alert rejoin ["Script <" name "> not found."]]
			modul
		]

		if not value? 'Add-tooltip-2-faces [; tooltip style already loaded?
			attempt [do load-script-thru/flash %simple-tooltip-style.r]
		]
		
		fcnt: 0
		files: none
		; make styles local
		info-path: arrow-d: btn-+: choice-sort: choice-order: btn-rename: list-of-files:
		field-selected: text-filter: choice-filter: check-hidden: btn-ok: btn-cancel: none
		fn1: fn2: fn3: fn4: none
		ticker-scroll: none
		file-req-styles: stylize [
			choice: choice white - 20  font [style: none size: 11 colors: [0.0.0 255.150.55] shadow: none] edge [size: 1x1]
			ticker: sensor 0x0 rate none feel [engage: func [face action event][if event/type = 'time [do-face face face/data none]]]
			files-list: panel [
				across space 0
				list [
					across space 0x0
					fn1: txt 280x16	no-wrap feel [
						redraw: func [face action position] [
							picked: face/parent-face/parent-face/parent-face/picked
							face/color: either find picked face/text [yello][240.240.240]
						]
						over: func [face into position] [
							if all [many into integer? face/state][
								clear picked
								if empty? list-of-files/data [exit]
								for n face/state min fcnt length? list-of-files/data either fcnt > face/state [1][-1][
									if not dir? first pick list-of-files/data n [append picked first pick list-of-files/data n]
								]
								show list-of-files
							]
							if all [many integer? face/state][
								case [
									position/y < (list-of-files/offset/y + 4) [ticker-scroll/set -1]
									position/y > (list-of-files/offset/y + list-of-files/size/y - fn1/size/y) [ticker-scroll/set 1]
									'else [ticker-scroll/stop]
								]
							]
						]
						engage: func [face action event] [
							if fcnt > length? list-of-files/data [exit]
							if event/double-click [
								hide-popup
								face/state: none
								exit
							]
							switch action [
								down [
									either all [many event/shift] [
										if not event/control [clear picked]
										face/user-data: any [face/user-data fcnt]
										for n face/user-data min fcnt length? list-of-files/data either fcnt > face/user-data [1][-1][
											if not dir? first pick list-of-files/data n [append picked first pick list-of-files/data n]
										]
									][
										if any [not many dir? to-file face/text not event/control] [face/state: fcnt clear picked]
										alter picked face/text
									]
									select_line ; update field-select and reshow
								]
								over [if integer? face/state [append clear picked face/text ]]
								away [
									if all [many integer? face/state][
										case [
											all [event/offset/y < 0 (fcnt - list-of-files/top) = 1] [ticker-scroll/set -1]
											all [event/offset/y > 20 (fcnt - list-of-files/top) = to-integer (list-of-files/size/y / fn1/size/y)] [ticker-scroll/set 1]
										]
									]
								]
								up [
									face/state: none
									if not event/shift [face/user-data: fcnt]
									select_line ; update field-select and reshow
									ticker-scroll/stop
								]
							]
						]
					]

					fn2: txt 60x16 right feel none
					fn3: txt 80x16 right feel none
					fn4: txt 55x16 right feel none
				] supply [
					fcnt: count: count + list-of-files/top
					files: file-list
					face/font/color: black
					face/font/style: []
					face/text: ""
					if count > length? files [return none]
					if all [index = 1 dir? files/:count/1] [face/font/color: blue face/font/style: 'bold]
					if all [index = 1 is-link? join path-name files/:count/1] [face/font/color: blue]
					face/text: do pick [
						[files/:count/1]
						[either dir? files/:count/1 [""] [files/:count/2]]
						[all [date? files/:count/3 files/:count/3/date]]
						[all [date? files/:count/3 to-itime files/:count/3/time]]
					] index
				]
				scroller with [list: none] [
					list: face/parent-face
					if face/user-data = value: max 0 to-integer value * ((length? list-of-files/data) - (list-of-files/size/y / fn1/size/y) + 1) [exit]
						face/user-data: list-of-files/top: value
						show list
				]
				ticker-scroll: ticker (0x0 - sp) [either value > 0 [scroll-drag list-of-files/sld] [scroll-drag/back list-of-files/sld]] with [
					stop: does [data: 0 rate: none show self]
					set: func [dir][data: dir rate: 20 show self]
				]
			] with [
				data: copy []
				picked: copy []
				top: 0
				column1: none
				sld: none

				update: func [/local tot-rows visible-rows item] [
					tot-rows: length? data visible-rows: to-integer (size/y / column1/size/y)
					sld/redrag visible-rows / max 1 tot-rows
					either visible-rows >= tot-rows [
						sld/step: 0.0
					][
						sld/step: 1 / (tot-rows - visible-rows)
						if column1/user-data [
							sld/data: (column1/user-data) / tot-rows ; simple but it works
							if sld/data < sld/step [sld/data: 0]
							top: to-integer sld/data / sld/step
						]
					]
					sld/page: sld/ratio / 1.5
					do-face sld sld/data
					self
				]
				resize: func [new /x /y /local siz][
					siz: new - size
					either any [x y] [
						if x [size/x: new]
						if y [size/y: new]
					][
						size: any [new size]
					]

					sld/page: sld/ratio / 1.5

					foreach [face pair] reduce [
						fn2 1x0
						fn3 1x0
						fn4 1x0
						pane/2 1x0
					][face/offset: face/offset + (siz * pair)]
					foreach [face pair] reduce [
						pane/1 1x1
						pane/1/subface 1x0
						fn1 1x0
					][face/size: face/size + (siz * pair)]
					foreach [face pair] reduce [
						pane/2 0x1
					][face/resize face/size + (siz * pair)]
				]
				append init [
					sld: pane/2
					sld/parent-face: pane
					column1: pane/1/subface/pane/1
					pane/1/size: size - (pane/2/size * 1x0)
					pane/1/subface/size/x: size/x
					pane/2/offset: pane/1/offset + (pane/1/size * 1x0)
					pane/2/resize/y size/y
				]
			]
		]
		req-win: [
			do [sp: 4x4] origin sp space sp 
			styles file-req-styles
			Across 
			style text text black feel none
			style btn btn 24x24 
			btn "<" [undo] help "Back to previous folder"
			btn ">" [redo] help "Forward"
			btn "^^"  [
				if not none? path-name [
					replace_file-list parent-dir path-name
					add_to_undo-list
				]
			] help "Go up one folder"
			style field field white white edge [color: gray + 30 effect: 'ibevel size: 1x1] 
			info-path: field 365 [if replace_file-list dirize to-rebol-file face/text [add_to_undo-list]]
			pad (sp * -1x0)
			arrow-d: arrow down white 24x24 [show_drop-list face] help "Select a parent directory"
			btn-+: btn "+" 252.223.44 [add_folder] help "Create a new folder"
			return 
			text "Sort by"
			choice-sort: choice "Name" "Size" "Date" 100x20 [replace_file-list path-name]
			text "in"
			choice-order: choice "increasing" "decreasing" 100x20 [replace_file-list path-name]
			text "order"
			btn-rename: btn "Rename" 100x20 252.223.44 [rename_file] help "Rename selected file or folder"
			return
			list-of-files: files-list 500x200
			return
			field-selected: field 336
			pad 0x2 
			text-filter: text "Filter:" 
			pad 0x-2 
			choice-filter: choice "All files (*.*)" "Rebol files (*.r)" 120  [replace_file-list path-name]
			return 
			pad 0x10 
			check-hidden: check-line "Show hidden files" no [replace_file-list path-name]
			pad 172x0 
			btn-ok: btn "Select" 100x24 #"^M" [cancelled: false hide-popup]
			btn-cancel: btn "Cancel" 100 #"^(esc)" [set-face field-selected "" cancelled: true hide-popup]
			key keycode [left] (0x0 - sp) [if replace_file-list parent-dir path-name [add_to_undo-list]]
			key keycode [right] (0x0 - sp) [undo]
			key keycode [f2] (0x0 - sp) [rename_file]
			do [btn-rename/offset/x: btn-cancel/offset/x]
		]
		req-win: layout req-win
		if on-win? [remove find req-win/pane check-hidden]
		remove find req-win/pane list-of-files
		insert tail req-win/pane list-of-files ; put on top (to hide lower styles)
		req-win/user-data: reduce ['size req-win/size]
		req-win/options: [resize min-size 500x306]
		if value? 'Add-tooltip-2-faces [Add-tooltip-2-faces req-win]
		field-selected/feel: ctx-text/edit ; restore this

		paths-lay: layout/offset [
			origin 0x0 at 0x0
			paths-list: text-list (info-path/size * 1x0 + arrow-d/size * 1x0 + 0x200) [select_folder value]
		] info-path/offset + (info-path/size * 0x1)
		; patch to avoid closing pop-up with scroll-wheel
		system/view/popface-feel-win-away: make system/view/popface-feel-win [
			process-outside-event: func [event] [
				unless find [move time active inactive scroll-line] event/type [hide-popup]
				event
			]
		]
	
		resize-faces: func [siz [pair!]] [
			foreach [face pair] reduce [
				arrow-d 1x0
				btn-+ 1x0
				btn-rename 1x0
				field-selected 0x1
				text-filter 1x1
				choice-filter 1x1
				check-hidden 0x1
				btn-ok 1x1
				btn-cancel 1x1
			][face/offset: face/offset + (siz * pair)]
			foreach [face pair] reduce [
				info-path 1x0
				field-selected 1x0
				paths-lay 1x0
				list-of-files 1x1
				paths-list 1x0
			][either in face 'resize [face/resize face/size + (siz * pair)][face/size: face/size + (siz * pair)]]

			list-of-files/update
		]
		req-win/feel: make req-win/feel [
			detect: func [face event /local siz][
				if any [event/face = req-win event/face = paths-lay] [
				switch event/type [
					close [set-face field-selected "" cancelled: true  hide-popup return none]
					scroll-line [
						either found? find req-win/pane paths-lay [
							either event/offset/y >= 0 [scroll-drag/page paths-list/sld] [scroll-drag/page/back paths-list/sld]
						][
							either event/offset/y >= 0 [scroll-drag/page list-of-files/sld] [scroll-drag/page/back list-of-files/sld]
						]
					]
					resize [
						face: event/face
						siz: face/size - face/user-data/size     ; compute size difference
						face/user-data/size: face/size          ; store new size

						resize-faces siz
						show face
					]
					key [
						if all [system/view/focal-face system/view/focal-face/feel = ctx-text/edit] [ ; editing has precedence
							return event
						]
						if word? event/key [if select_line/key event/key event/control [return none]]
						if all [event/key = #"^M" system/view/focal-face = list-of-files dir? any [pick list-of-files/picked 1 %a]] [if select_line [return none]]
						if all [event/key = #"^M" system/view/focal-face = info-path] [if replace_file-list dirize to-rebol-file info-path/text [add_to_undo-list] return none]
						if event/key = #"^M" [if "" = trim get-face field-selected [return none]]
						select_line-letter event/key
						if face: find-key-face face event/key [
							if get in face 'action [do-face face event/key]
							return none
						]
					]
				]
				]
				event
			]
		]
	; main
		old-path-name:
		path-name: none
		orig-file-list: ; the unsorted file list
		file-list: [] ; the sorted file list
		undo-list: copy []
		redo-list: copy []
		only-dirs: false
		dirs-count: 0
		many: true
		saving: false
		names: none
		cancelled: none

		set 'request_file func [
			"Requests a file using a popup list of files and directories."
			/title "Change heading on request."
				title-line "Title line of request"
				button-text "Button text for selection"
			/file name "Default file name or block of file names"
			/filter filt "Filter or block of filters"
			/keep "Keep previous settings and results"
			/only "Return only a single file, not a block."
			/path "Return absolute path followed by relative files."
			/save "Request file for saving, otherwise loading."
			/local result dir-path
			][
			req-win/text: any [title-line "Select a File:"]
			many: not only
			if save [many: false]
			if all [not many block? name] [name: pick name 1]
			field-selected/text: any [all [name form name] ""]
			names: any [name []]
			if filt [
				filt: compose [(filt)]
				either on-win? [if not find form filt "*.*" [insert tail filt "All files (*.*)"]][insert tail filt "All files (*)"]
				choice-filter/text: first choice-filter/data: choice-filter/texts: filt
			]
			btn-ok/text: any [button-text either save ["Save"]["Select"]]
			if only-dirs [list-of-files/resize list-of-files/size - 0x30]
			saving: to logic! save

			only-dirs: false
			replace_file-list/init any [path-name path-name: what-dir]

			show-popup req-win
			do-events
			unfocus

			if none? keep [ ; restore defaults
				choice-filter/text: first choice-filter/data: choice-filter/texts: ["All files (*.*)" "Rebol files (*.r)"]
				choice-sort/text: first choice-sort/data: head choice-sort/data
				choice-order/text: first choice-order/data: head choice-order/data
				path-name: none
			]
			result: get-face field-selected
			if "" = trim result [return none]
			if any [only #"^"" <> first result] [result: enquote result]
			; convert string to block of files
			result: parse result none
			forall result [change result to-rebol-file first result]
			dir-path: dirize to-rebol-file get-face info-path
			if only [return join dir-path result/1]
			either path [
				insert result dir-path
			][
				foreach file result [insert file dir-path]
			]
			head result
		]
		set 'request_dir func [
			"Requests a directory using a popup list."
			/title "Change heading on request." title-line
			/dir "Set starting directory" where [file!]
			/keep "Keep previous directory path"
			/offset xy [pair!]
			/local offs result
			][
			req-win/text: any [title-line "Select a directory:"]
			if offset [offs: req-win/offset req-win/offset: xy]
			btn-ok/text: "Select" ; restore default value
			if not only-dirs [list-of-files/resize list-of-files/size + 0x30]

			only-dirs: true
			replace_file-list any [where path-name path-name: what-dir]

			show-popup req-win
			do-events
			unfocus

			result: path-name
			if none? keep [ ; restore defaults
				req-win/offset: offs
				choice-sort/text: first choice-sort/data: head choice-sort/data
				choice-order/text: first choice-order/data: head choice-order/data
				path-name: none
			]
			if cancelled [return none]
			result
		]
]

] ; value?

do ; just comment this line to avoid executing examples
[
if system/script/title = "Open a file or directory requester" [; script not started by some else script
probe request_file/keep/title/filter "gimme file" "Load" ["*.r; *.c" "files (*.s ; *.t)"]
probe request_dir/title/offset "gimme dir" 100x100
probe request_dir/title/offset "gimme dir" 100x100
probe request_file/only/path/title "gimme file again" "Get it"
halt
]
]