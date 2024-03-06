REBOL [
	title: "libpango library interface"
	file: %pango-h.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 09-06-2019
	version: 0.5.1
	needs: {
		%cairo-h.r
		- libgobject, libpangocairo shared libraries
	}
	comment: {ONLY A FEW FUNCTIONs TESTED !!!! Use example code to test others.
		See Rebol specific functions at the end.
		
		I know the exact name of shared library only for Windows: please check and , if necessary, change the others
		
		THIS SCRIPT NEEDS %cairo-h.r SINCE THIS PANGO DEPENDS ON CAIRO
		
	}
	Purpose: "Code to bind pango and pango-cairo shared libraries to Rebol."
	History: [
		0.1.0 [30-03-2019 "Started"]
		0.5.0 [28-05-2019 "Mature enough"]
		0.5.1 [09-06-2019 "Fixed flush_events (at last !!!) renamed as eat_events"]
	]
	Category: [library graphics]
	library: [
		level: 'advanced
		platform: 'all
		type: 'module
		domain: [graphics text external-library]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
		see-also: none
	]
]
;;;; library-support functions
	;;;
	;;;REBOL-NOTE: use this function to access pointers
	;;;
	int-ptr: does [make struct! [value [integer!]] none]
	dbl-ptr: does [make struct! [value [double]] none]
	
	*int: make struct! [[save] ptr [struct! [value [integer!]]]] none
	addr: func [ptr [binary! string!]] [third make struct! [s [string!]] reduce [ptr]]
	get&: func [ptr] [change third *int addr ptr *int/ptr/value]
	&: func [ptr] [ptr: addr ptr to-integer either 'little = get-modes system:// 'endian [head reverse copy ptr][ptr]]
	
	get-mem?: func [; author: Ladislav Mecir
		"get the byte from a memory address"
		address [integer!]
		/nts "a null-terminated string"
		/part "a binary with a specified length"
		length [integer!]
		/local address_ m c r
		] [
		address_: make struct! [i [integer!]] reduce [address]
		if nts [
		m: make struct! [s [string!]] none
		change third m third address_
		return m/s
		]
		if part [
		m: make struct! compose/deep [bin [char-array (length)]] none
		change third m third address_
		return as-binary any [m/bin #{}]
		]
		m: make struct! [c [struct! [chr [char!]]]] none
		change third m third address_
		m/c/chr
	]
	;;;
	;;;REBOL-NOTE: use this function to convert a block to an initialized struct! (and use eg. as: probe third block-to-struct/doubles [1.5 3])
	;;;
	block-to-struct: func [
		"Construct a struct! and initialize it based on given block"
		block [block!] /doubles /local spec type n
		] [
		block: copy block
		replace/all block 'none 0
		spec: copy []
		n: 1
		forall block [
			append spec compose/deep/only [(to-word join '_ n) [(
				type: type?/word first block
				either any [equal? type 'decimal! doubles]['double][type]
			)]]
			n: n + 1
		]
		make struct! spec block
	]
;
;;;; load libraries


	;; NEEDED ;;;; adjust path if necessary
	; 	FIXME: do-load-thru request "Download it" "Load it"
	;do load %../cairo/cairo-h.r    ; using load to avoid executing example
	
	do any [
		attempt [load %cairo-h.r]
		attempt [load %../cairo-h.r]
		attempt [load %../../cairo-h.r]
		attempt [load %../cairo/cairo-h.r]
		attempt [
			alert rejoin ["Problems finding cairo-h.r . Load it"]
			load request-file/only/title "Load cairo-h.r" "Load"
		]
		do [alert rejoin ["Problems loading cairo-h.r . Quit"] quit]
	]

	
	gobjectlib-name: switch/default System/version/4 [
		2 [%libgobject-2.0-0.dylib]	;OSX
		3 [%libgobject-2.0-0.dll]	;Windows
	] [%libgobject.so.2]
	if not exists? gobjectlib-name [alert "libgobject library not found in current folder. libpango needs it." quit]
	if not attempt [gobject-lib: load/library gobjectlib-name] [alert rejoin ["Problems loading " gobjectlib-name " . Quit"] quit]

	pango-lib-name: switch/default System/version/4 [
		2 [%libpango-1.0-0.dylib]	;OSX
		3 [%libpango-1.0-0.dll]	;Windows
	] [%libpango.so.1]
	if not attempt [pango-lib: load/library pango-lib-name] [alert rejoin ["Problems loading " pango-lib-name " . Quit"] quit]
;
; g_object_unref
	g_object_unref: make routine! [ object [integer!] ] gobject-lib "g_object_unref"
;
; types
	guchar: char!
	guint8: char!
	guint16: integer!
	gushort: integer!
	guint: integer!
	gint: integer!
	guint32: integer!
	gulong: integer!
	;gdouble: decimal!
	gpointer: integer!
	gboolean: integer!
	gunichar: integer!
	GObject: integer!

	PangoAttribute: integer!
	PangoColor: integer!
	PangoRectangle: integer!
	PangoStyle: integer!
	PangoWeight: integer!
	PangoVariant: integer!
	PangoStretch: integer!
	PangoGravity: integer!
	PangoGravityHint: integer!
	PangoDirection: integer!
	PangoEngine: integer!
	PangoScript: integer!
	PangoGlyph: integer!
	PangoGlyphUnit: integer!
	PangoGlyphGeometry: integer!
	PangoGlyphVisAttr: integer!
	PangoAnalysis: integer!
	PangoFontMap: integer!
	PangoFcFontMap: integer!
	PangoFont: integer!
	PangoMatrix: integer!
	PangoFcFont: integer!
	PangoFontFace: integer!

	PangoCoreTextFontMap: integer!
	cairo_matrix_t: integer!
	cairo_font_type_t: integer!
	PangoWin32FontMap: integer!
	
	FT_Face: integer!
	
	HDC: integer!
;
; constants
	G_MAXUINT: to integer! #{7FFFFFFF}
;
; features
	Pango_HAS_FC_FONT: false
	Pango_HAS_FT2: false
	Pango_HAS_WIN32: false
	Pango_HAS_XFT: false

	lib: switch/default System/version/4 [
		2 [%libpangocairo-1.0-0.dylib]	;OSX
		3 [%libpangocairo-1.0-0.dll]	;Windows
	] [%libpangocairo.so.1]
	either not pango-cairo-lib: attempt [load/library lib] [
		alert rejoin ["Problems loading " lib " ."]; Quit"] quit
		Pango_HAS_PANGOCAIRO: false
	][
		Pango_HAS_PANGOCAIRO: true
	]
;
{ pango_.h }
{ Pango
 * pango.h:
 *
 * Copyright (C) 1999 Red Hat Software
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.

 }
{ Pango version checking }

	{ Return encoded version of Pango at run-time }

	pango_version: make routine! [ return: [integer!] ] pango-lib "pango_version" 
	;probe 
	pango_this_version: pango_version

	{ Return run-time Pango version as an string }

	pango_version_string: make routine! [ return: [string!] ] pango-lib "pango_version_string" 
	;probe pango_version_string

	{ Check that run-time Pango is as new as required }

	pango_version_check: make routine! [ required_major [integer!] required_minor [integer!] required_micro [integer!] return: [string!] ] pango-lib "pango_version_check" 


{ pango-attributes.h }
{ Pango
 * pango-attributes.h: Attributed text
 *
 * Copyright (C) 2000 Red Hat Software
 *

 }

{ PangoColor }

;typedef struct _PangoColor PangoColor;

{*
 * PangoColor:
	 * @red: value of red component
	 * @green: value of green component
	 * @blue: value of blue component
	 *
	 * The #PangoColor structure is used to
	 * represent a color in an uncalibrated RGB color-space.
	 }
	_PangoColor: make struct! [
		red [guint16]
		green [guint16]
		blue [guint16]
	] none ;

	{*
	 * PANGO_TYPE_COLOR:
	 *
	 * The #GObject type for #PangoColor.
	 }
	pango_color_get_type: make routine! [ return: [GType] ] pango-lib "pango_color_get_type" 
	pango_color_copy: make routine! [ src [integer!] return: [integer!] ] pango-lib "pango_color_copy" 
	pango_color_free: make routine! [ color [integer!] return: [integer!] ] pango-lib "pango_color_free" 
	pango_color_parse: make routine! [ color [integer!] spec [string!] return: [gboolean] ] pango-lib "pango_color_parse" 
	pango_color_to_string: make routine! [ color [integer!] return: [integer!] ] pango-lib "pango_color_to_string" 

{ Attributes }
	{*
	 * PANGO_TYPE_ATTR_LIST:
	 *
	 * The #GObject type for #PangoAttrList.
	 }
	{*
	 * PangoAttrIterator:
	 *
	 * The #PangoAttrIterator structure is used to represent an
	 * iterator through a #PangoAttrList. A new iterator is created
	 * with pango_attr_list_get_iterator(). Once the iterator
	 * is created, it can be advanced through the style changes
	 * in the text using pango_attr_iterator_next(). At each
	 * style change, the range of the current style segment and the
	 * attributes currently in effect can be queried.
	 }
	{*
	 * PangoAttrList:
	 *
	 * The #PangoAttrList structure represents a list of attributes
	 * that apply to a section of text. The attributes are, in general,
	 * allowed to overlap in an arbitrary fashion, however, if the
	 * attributes are manipulated only through pango_attr_list_change(),
	 * the overlap between properties will meet stricter criteria.
	 *
	 * Since the #PangoAttrList structure is stored as a linear list,
	 * it is not suitable for storing attributes for large amounts
	 * of text. In general, you should not use a single #PangoAttrList
	 * for more than one paragraph of text.
	 }
	{*
	 * PangoAttrType:
	 * @PANGO_ATTR_INVALID: does not happen
	 * @PANGO_ATTR_LANGUAGE: language (#PangoAttrLanguage)
	 * @PANGO_ATTR_FAMILY: font family name list (#PangoAttrString)
	 * @PANGO_ATTR_STYLE: font slant style (#PangoAttrInt)
	 * @PANGO_ATTR_WEIGHT: font weight (#PangoAttrInt)
	 * @PANGO_ATTR_VARIANT: font variant (normal or small caps) (#PangoAttrInt)
	 * @PANGO_ATTR_STRETCH: font stretch (#PangoAttrInt)
	 * @PANGO_ATTR_SIZE: font size in points scaled by %PANGO_SCALE (#PangoAttrInt)
	 * @PANGO_ATTR_FONT_DESC: font description (#PangoAttrFontDesc)
	 * @PANGO_ATTR_FOREGROUND: foreground color (#PangoAttrColor)
	 * @PANGO_ATTR_BACKGROUND: background color (#PangoAttrColor)
	 * @PANGO_ATTR_UNDERLINE: whether the text has an underline (#PangoAttrInt)
	 * @PANGO_ATTR_STRIKETHROUGH: whether the text is struck-through (#PangoAttrInt)
	 * @PANGO_ATTR_RISE: baseline displacement (#PangoAttrInt)
	 * @PANGO_ATTR_SHAPE: shape (#PangoAttrShape)
	 * @PANGO_ATTR_SCALE: font size scale factor (#PangoAttrFloat)
	 * @PANGO_ATTR_FALLBACK: whether fallback is enabled (#PangoAttrInt)
	 * @PANGO_ATTR_LETTER_SPACING: letter spacing (#PangoAttrInt)
	 * @PANGO_ATTR_UNDERLINE_COLOR: underline color (#PangoAttrColor)
	 * @PANGO_ATTR_STRIKETHROUGH_COLOR: strikethrough color (#PangoAttrColor)
	 * @PANGO_ATTR_ABSOLUTE_SIZE: font size in pixels scaled by %PANGO_SCALE (#PangoAttrInt)
	 * @PANGO_ATTR_GRAVITY: base text gravity (#PangoAttrInt)
	 * @PANGO_ATTR_GRAVITY_HINT: gravity hint (#PangoAttrInt)
	 * @PANGO_ATTR_FONT_FEATURES: OpenType font features (#PangoAttrString). Since 1.38
	 * @PANGO_ATTR_FOREGROUND_ALPHA: foreground alpha (#PangoAttrInt). Since 1.38
	 * @PANGO_ATTR_BACKGROUND_ALPHA: background alpha (#PangoAttrInt). Since 1.38
	 *
	 * The #PangoAttrType
	 * distinguishes between different types of attributes. Along with the
	 * predefined values, it is possible to allocate additional values
	 * for custom attributes using pango_attr_type_register(). The predefined
	 * values are given below. The type of structure used to store the
	 * attribute is listed in parentheses after the description.
	 }

	PANGO_ATTR_INVALID: 0 { 0 is an invalid attribute type }
	PANGO_ATTR_LANGUAGE: 1 { PangoAttrLanguage }
	PANGO_ATTR_FAMILY: 2 { PangoAttrString }
	PANGO_ATTR_STYLE: 3 { PangoAttrInt }
	PANGO_ATTR_WEIGHT: 4 { PangoAttrInt }
	PANGO_ATTR_VARIANT: 5 { PangoAttrInt }
	PANGO_ATTR_STRETCH: 6 { PangoAttrInt }
	PANGO_ATTR_SIZE: 7 { PangoAttrSize }
	PANGO_ATTR_FONT_DESC: 8 { PangoAttrFontDesc }
	PANGO_ATTR_FOREGROUND: 9 { PangoAttrColor }
	PANGO_ATTR_BACKGROUND: 10 { PangoAttrColor }
	PANGO_ATTR_UNDERLINE: 11 { PangoAttrInt }
	PANGO_ATTR_STRIKETHROUGH: 12 { PangoAttrInt }
	PANGO_ATTR_RISE: 13 { PangoAttrInt }
	PANGO_ATTR_SHAPE: 14 { PangoAttrShape }
	PANGO_ATTR_SCALE: 15 { PangoAttrFloat }
	PANGO_ATTR_FALLBACK: 16 { PangoAttrInt }
	PANGO_ATTR_LETTER_SPACING: 17 { PangoAttrInt }
	PANGO_ATTR_UNDERLINE_COLOR: 18 { PangoAttrColor }
	PANGO_ATTR_STRIKETHROUGH_COLOR: 19 { PangoAttrColor }
	PANGO_ATTR_ABSOLUTE_SIZE: 20 { PangoAttrSize }
	PANGO_ATTR_GRAVITY: 21 { PangoAttrInt }
	PANGO_ATTR_GRAVITY_HINT: 22 { PangoAttrInt }
	PANGO_ATTR_FONT_FEATURES: 23 { PangoAttrString }
	PANGO_ATTR_FOREGROUND_ALPHA: 24 { PangoAttrInt }
	 { PangoAttrInt }
	PANGO_ATTR_BACKGROUND_ALPHA: 25 { PangoAttrInt }
	 { PangoAttrInt }
	PangoAttrType: integer!;

{*
* PangoUnderline:
	 * @PANGO_UNDERLINE_NONE: no underline should be drawn
	 * @PANGO_UNDERLINE_SINGLE: a single underline should be drawn
	 * @PANGO_UNDERLINE_DOUBLE: a double underline should be drawn
	 * @PANGO_UNDERLINE_LOW: a single underline should be drawn at a position
	 * beneath the ink extents of the text being
	 * underlined. This should be used only for underlining
	 * single characters, such as for keyboard
	 * accelerators. %PANGO_UNDERLINE_SINGLE should
	 * be used for extended portions of text.
	 * @PANGO_UNDERLINE_ERROR: a wavy underline should be drawn below.
	 * This underline is typically used to indicate
	 * an error such as a possilble mispelling; in some
	 * cases a contrasting color may automatically
	 * be used. This type of underlining is available since Pango 1.4.
	 *
	 * The #PangoUnderline enumeration is used to specify
	 * whether text should be underlined, and if so, the type
	 * of underlining.
	 }

	PANGO_UNDERLINE_NONE: 0
	PANGO_UNDERLINE_SINGLE: 1
	PANGO_UNDERLINE_DOUBLE: 2
	PANGO_UNDERLINE_LOW: 3
	PANGO_UNDERLINE_ERROR: 4

	PangoUnderline: integer!;

{*
 * PANGO_ATTR_INDEX_FROM_TEXT_BEGINNING:
	 *
	 * This value can be used to set the start_index member of a #PangoAttribute
	 * such that the attribute covers from the beginning of the text.
	 *
	 * Since: 1.24
	 }
	{*
	 * PANGO_ATTR_INDEX_TO_TEXT_END:
	 *
	 * This value can be used to set the end_index member of a #PangoAttribute
	 * such that the attribute covers to the end of the text.
	 *
	 * Since: 1.24
	 }
	PANGO_ATTR_INDEX_FROM_TEXT_BEGINNING:	0
	PANGO_ATTR_INDEX_TO_TEXT_END:		G_MAXUINT

{*
 * PangoAttribute:
	 * @klass: the class structure holding information about the type of the attribute
	 * @start_index: the start index of the range (in bytes).
	 * @end_index: end index of the range (in bytes). The character at this index
	 * is not included in the range.
	 *
	 * The #PangoAttribute structure represents the common portions of all
	 * attributes. Particular types of attributes include this structure
	 * as their initial portion. The common portion of the attribute holds
	 * the range to which the value in the type-specific part of the attribute
	 * applies and should be initialized using pango_attribute_init().
	 * By default an attribute will have an all-inclusive range of [0,%G_MAXUINT].
	 }
	_PangoAttribute: make struct! [

	  klass [integer!]
	  start_index [guint] { in bytes }
	  end_index [guint] { in bytes. The character at this index is not included }
	] none ;

	{*
	 * PangoAttrString:
	 * @attr: the common portion of the attribute
	 * @value: the string which is the value of the attribute
	 *
	 * The #PangoAttrString structure is used to represent attributes with
	 * a string value.
	 }
	_PangoAttrString: make struct! [
		attr [PangoAttribute]
		value [string!]
	] none ;
	{*
	 * PangoAttrLanguage:
	 * @attr: the common portion of the attribute
	 * @value: the #PangoLanguage which is the value of the attribute
	 *
	 * The #PangoAttrLanguage structure is used to represent attributes that
	 * are languages.
	 }
	_PangoAttrLanguage: make struct! [
		attr [PangoAttribute]
		value [integer!]
	] none ;
	{*
	 * PangoAttrInt:
	 * @attr: the common portion of the attribute
	 * @value: the value of the attribute
	 *
	 * The #PangoAttrInt structure is used to represent attributes with
	 * an integer or enumeration value.
	 }
	_PangoAttrInt: make struct! [
		attr [PangoAttribute]
		value [integer!]
	] none ;
	{*
	 * PangoAttrFloat:
	 * @attr: the common portion of the attribute
	 * @value: the value of the attribute
	 *
	 * The #PangoAttrFloat structure is used to represent attributes with
	 * a float or double value.
	 }
	_PangoAttrFloat: make struct! [
		attr [PangoAttribute]
		value [double]
	] none ;
	{*
	 * PangoAttrColor:
	 * @attr: the common portion of the attribute
	 * @color: the #PangoColor which is the value of the attribute
	 *
	 * The #PangoAttrColor structure is used to represent attributes that
	 * are colors.
	 }
	_PangoAttrColor: make struct! [
		attr [PangoAttribute]
		color [PangoColor]
	] none ;

	{*
	 * PangoAttrSize:
	 * @attr: the common portion of the attribute
	 * @size: size of font, in units of 1/%PANGO_SCALE of a point (for
	 * %PANGO_ATTR_SIZE) or of a device uni (for %PANGO_ATTR_ABSOLUTE_SIZE)
	 * @absolute: whether the font size is in device units or points.
	 * This field is only present for compatibility with Pango-1.8.0
	 * (%PANGO_ATTR_ABSOLUTE_SIZE was added in 1.8.1); and always will
	 * be %FALSE for %PANGO_ATTR_SIZE and %TRUE for %PANGO_ATTR_ABSOLUTE_SIZE.
	 *
	 * The #PangoAttrSize structure is used to represent attributes which
	 * set font size.
	 }
	_PangoAttrSize: make struct! [
		attr [PangoAttribute]
		size [integer!]
		absolute [guint] ; : 1;
	] none ;

	{*
	 * PangoAttrShape:
	 * @attr: the common portion of the attribute
	 * @ink_rect: the ink rectangle to restrict to
	 * @logical_rect: the logical rectangle to restrict to
	 * @data: user data set (see pango_attr_shape_new_with_data())
	 * @copy_func: copy function for the user data
	 * @destroy_func: destroy function for the user data
	 *
	 * The #PangoAttrShape structure is used to represent attributes which
	 * impose shape restrictions.
	 }
	_PangoAttrShape: make struct! [
		attr [PangoAttribute]
		ink_rect [PangoRectangle]
		logical_rect [PangoRectangle]
		data [gpointer]
		copy_func [integer!] ; callback]
		destroy_func [integer!] ; callback]
	] none ;

	{*
	 * PangoAttrFontDesc:
	 * @attr: the common portion of the attribute
	 * @desc: the font description which is the value of this attribute
	 *
	 * The #PangoAttrFontDesc structure is used to store an attribute that
	 * sets all aspects of the font description at once.
	 }
	_PangoAttrFontDesc: make struct! [
		attr [PangoAttribute]
		desc [integer!]
	] none ;

	{*
	 * PangoAttrFontFeatures:
	 * @attr: the common portion of the attribute
	 * @features: the featues, as a string in CSS syntax
	 *
	 * The #PangoAttrFontFeatures structure is used to represent OpenType
	 * font features as an attribute.
	 *
	 * Since: 1.38
	 }
	_PangoAttrFontFeatures: make struct! [
		attr [PangoAttribute]
		features [integer!]
	] none ;
; pango attribute functions
	pango_attr_type_register: make routine! [ name [integer!] return: [PangoAttrType] ] pango-lib "pango_attr_type_register" 
	pango_attr_type_get_name: make routine! [ type [PangoAttrType] return: [string!] ] pango-lib "pango_attr_type_get_name"
	pango_attribute_init: make routine! [ attr [integer!] klass [integer!] return: [integer!] ] pango-lib "pango_attribute_init" 
	pango_attribute_copy: make routine! [ attr [integer!] return: [integer!] ] pango-lib "pango_attribute_copy" 
	pango_attribute_destroy: make routine! [ attr [integer!] return: [integer!] ] pango-lib "pango_attribute_destroy" 
	pango_attribute_equal: make routine! [ attr1 [integer!] attr2 [integer!] return: [gboolean] ] pango-lib "pango_attribute_equal" 
	pango_attr_language_new: make routine! [ language [integer!] return: [integer!] ] pango-lib "pango_attr_language_new" 
	pango_attr_family_new: make routine! [ family [string!] return: [integer!] ] pango-lib "pango_attr_family_new" 
	pango_attr_foreground_new: make routine! [ red [guint16] green [guint16] blue [guint16] return: [integer!] ] pango-lib "pango_attr_foreground_new" 
	pango_attr_background_new: make routine! [ red [guint16] green [guint16] blue [guint16] return: [integer!] ] pango-lib "pango_attr_background_new" 
	pango_attr_size_new: make routine! [ size [integer!] return: [integer!] ] pango-lib "pango_attr_size_new" 
	pango_attr_size_new_absolute: make routine! [ size [integer!] return: [integer!] ] pango-lib "pango_attr_size_new_absolute" 
	pango_attr_style_new: make routine! [ style [PangoStyle] return: [integer!] ] pango-lib "pango_attr_style_new" 
	pango_attr_weight_new: make routine! [ weight [PangoWeight] return: [integer!] ] pango-lib "pango_attr_weight_new" 
	pango_attr_variant_new: make routine! [ variant [PangoVariant] return: [integer!] ] pango-lib "pango_attr_variant_new" 
	pango_attr_stretch_new: make routine! [ stretch [PangoStretch] return: [integer!] ] pango-lib "pango_attr_stretch_new" 
	pango_attr_font_desc_new: make routine! [ desc [integer!] return: [integer!] ] pango-lib "pango_attr_font_desc_new" 
	pango_attr_underline_new: make routine! [ underline [PangoUnderline] return: [integer!] ] pango-lib "pango_attr_underline_new" 
	pango_attr_underline_color_new: make routine! [ red [guint16] green [guint16] blue [guint16] return: [integer!] ] pango-lib "pango_attr_underline_color_new" 
	pango_attr_strikethrough_new: make routine! [ strikethrough [gboolean] return: [integer!] ] pango-lib "pango_attr_strikethrough_new" 
	pango_attr_strikethrough_color_new: make routine! [ red [guint16] green [guint16] blue [guint16] return: [integer!] ] pango-lib "pango_attr_strikethrough_color_new" 
	pango_attr_rise_new: make routine! [ rise [integer!] return: [integer!] ] pango-lib "pango_attr_rise_new" 
	pango_attr_scale_new: make routine! [ scale_factor [double] return: [integer!] ] pango-lib "pango_attr_scale_new" 
	pango_attr_fallback_new: make routine! [ enable_fallback [gboolean] return: [integer!] ] pango-lib "pango_attr_fallback_new" 
	pango_attr_letter_spacing_new: make routine! [ letter_spacing [integer!] return: [integer!] ] pango-lib "pango_attr_letter_spacing_new" 
	pango_attr_shape_new: make routine! [ ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_attr_shape_new" 
	pango_attr_shape_new_with_data: make routine! [ ink_rect [integer!]
	 logical_rect [integer!]
	 data [gpointer]
	 copy_func [integer!];[callback]
	 destroy_func [integer!];[callback]
	 return: [integer!] ] pango-lib "pango_attr_shape_new_with_data" 

	pango_attr_gravity_new: make routine! [ gravity [PangoGravity] return: [integer!] ] pango-lib "pango_attr_gravity_new" 
	pango_attr_gravity_hint_new: make routine! [ hint [PangoGravityHint] return: [integer!] ] pango-lib "pango_attr_gravity_hint_new" 
	if pango_this_version >= 13800 [
	pango_attr_font_features_new: make routine! [ features [integer!] return: [integer!] ] pango-lib "pango_attr_font_features_new" 
	pango_attr_foreground_alpha_new: make routine! [ alpha [guint16] return: [integer!] ] pango-lib "pango_attr_foreground_alpha_new" 
	pango_attr_background_alpha_new: make routine! [ alpha [guint16] return: [integer!] ] pango-lib "pango_attr_background_alpha_new" 
	]
	pango_attr_list_get_type: make routine! [ return: [GType] ] pango-lib "pango_attr_list_get_type" 
	pango_attr_list_new: make routine! [ return: [integer!] ] pango-lib "pango_attr_list_new" 
	pango_attr_list_ref: make routine! [ list [integer!] return: [integer!] ] pango-lib "pango_attr_list_ref" 
	pango_attr_list_unref: make routine! [ list [integer!] return: [integer!] ] pango-lib "pango_attr_list_unref" 
	pango_attr_list_copy: make routine! [ list [integer!] return: [integer!] ] pango-lib "pango_attr_list_copy" 
	pango_attr_list_insert: make routine! [ list [integer!] attr [integer!] return: [integer!] ] pango-lib "pango_attr_list_insert" 
	pango_attr_list_insert_before: make routine! [ list [integer!] attr [integer!] return: [integer!] ] pango-lib "pango_attr_list_insert_before" 
	pango_attr_list_change: make routine! [ list [integer!] attr [integer!] return: [integer!] ] pango-lib "pango_attr_list_change" 
	pango_attr_list_splice: make routine! [ list [integer!] other [integer!] pos [gint] len [gint] return: [integer!] ] pango-lib "pango_attr_list_splice" 
	pango_attr_list_filter: make routine! [ list [integer!] func [integer!] data [gpointer] return: [integer!] ] pango-lib "pango_attr_list_filter" 
	pango_attr_list_get_iterator: make routine! [ list [integer!] return: [integer!] ] pango-lib "pango_attr_list_get_iterator" 
	pango_attr_iterator_range: make routine! [ iterator [integer!] start [integer!] end [integer!] return: [integer!] ] pango-lib "pango_attr_iterator_range" 
	pango_attr_iterator_next: make routine! [ iterator [integer!] return: [gboolean] ] pango-lib "pango_attr_iterator_next" 
	pango_attr_iterator_copy: make routine! [ iterator [integer!] return: [integer!] ] pango-lib "pango_attr_iterator_copy" 
	pango_attr_iterator_destroy: make routine! [ iterator [integer!] return: [integer!] ] pango-lib "pango_attr_iterator_destroy" 
	pango_attr_iterator_get: make routine! [ iterator [integer!] type [PangoAttrType] return: [integer!] ] pango-lib "pango_attr_iterator_get" 
	pango_attr_iterator_get_font: make routine! [ iterator [integer!] desc [integer!] language [struct! []] extra_attrs [struct! []] return: [integer!] ] pango-lib "pango_attr_iterator_get_font" 
	pango_attr_iterator_get_attrs: make routine! [ iterator [integer!] return: [integer!] ] pango-lib "pango_attr_iterator_get_attrs" 
	pango_parse_markup: make routine! [ markup_text [string!]
	 length [integer!]
	 accel_marker [gunichar]
	 attr_list [struct! []]
	 text [struct! []]
	 accel_char [integer!]
	 error [struct! []] return: [gboolean] ] pango-lib "pango_parse_markup" 

	if pango_this_version >= 13200 [
	pango_markup_parser_new: make routine! [ accel_marker [gunichar] return: [integer!] ] pango-lib "pango_markup_parser_new" 
	pango_markup_parser_finish: make routine! [ context [integer!]
	 attr_list [struct! []]
	 text [struct! []]
	 accel_char [integer!]
	 error [struct! []] return: [gboolean] ] pango-lib "pango_markup_parser_finish" 
	]
;
{ pango-bidi-type.h }
	{ Pango
	 * pango-bidi-type.h: Bidirectional Character Types
	 *
	 * Copyright (C) 2008 Jürg Billeter <j@bitron.ch>
	 *

	 }

	{*
	 * PangoBidiType:
	 * @PANGO_BIDI_TYPE_L: Left-to-Right
	 * @PANGO_BIDI_TYPE_LRE: Left-to-Right Embedding
	 * @PANGO_BIDI_TYPE_LRO: Left-to-Right Override
	 * @PANGO_BIDI_TYPE_R: Right-to-Left
	 * @PANGO_BIDI_TYPE_AL: Right-to-Left Arabic
	 * @PANGO_BIDI_TYPE_RLE: Right-to-Left Embedding
	 * @PANGO_BIDI_TYPE_RLO: Right-to-Left Override
	 * @PANGO_BIDI_TYPE_PDF: Pop Directional Format
	 * @PANGO_BIDI_TYPE_EN: European Number
	 * @PANGO_BIDI_TYPE_ES: European Number Separator
	 * @PANGO_BIDI_TYPE_ET: European Number Terminator
	 * @PANGO_BIDI_TYPE_AN: Arabic Number
	 * @PANGO_BIDI_TYPE_CS: Common Number Separator
	 * @PANGO_BIDI_TYPE_NSM: Nonspacing Mark
	 * @PANGO_BIDI_TYPE_BN: Boundary Neutral
	 * @PANGO_BIDI_TYPE_B: Paragraph Separator
	 * @PANGO_BIDI_TYPE_S: Segment Separator
	 * @PANGO_BIDI_TYPE_WS: Whitespace
	 * @PANGO_BIDI_TYPE_ON: Other Neutrals
	 *
	 * The #PangoBidiType type represents the bidirectional character
	 * type of a Unicode character as specified by the
	 * <ulink url="http:;www.unicode.org/reports/tr9/">Unicode bidirectional algorithm</ulink>.
	 *
	 * Since: 1.22
	 * Deprecated: 1.44: Use fribidi for this information
	 *}

	{ Strong types }
	PANGO_BIDI_TYPE_L: 0
	PANGO_BIDI_TYPE_LRE: 1
	PANGO_BIDI_TYPE_LRO: 2
	PANGO_BIDI_TYPE_R: 3
	PANGO_BIDI_TYPE_AL: 4
	PANGO_BIDI_TYPE_RLE: 5
	PANGO_BIDI_TYPE_RLO: 6

	{ Weak types }
	PANGO_BIDI_TYPE_PDF: 7
	PANGO_BIDI_TYPE_EN: 8
	PANGO_BIDI_TYPE_ES: 9
	PANGO_BIDI_TYPE_ET: 10
	PANGO_BIDI_TYPE_AN: 11
	PANGO_BIDI_TYPE_CS: 12
	PANGO_BIDI_TYPE_NSM: 13
	PANGO_BIDI_TYPE_BN: 14

	{ Neutral types }
	PANGO_BIDI_TYPE_B: 15
	PANGO_BIDI_TYPE_S: 16
	PANGO_BIDI_TYPE_WS: 17
	PANGO_BIDI_TYPE_ON: 18

	PangoBidiType: integer!;

	pango_bidi_type_for_unichar: make routine! [ ch [gunichar] return: [PangoBidiType] ] pango-lib "pango_bidi_type_for_unichar" 
	pango_unichar_direction: make routine! [ ch [gunichar] return: [PangoDirection] ] pango-lib "pango_unichar_direction" 
	pango_find_base_dir: make routine! [ text [integer!] length [gint] return: [PangoDirection] ] pango-lib "pango_find_base_dir" 
	;PANGO_DEPRECATED_FOR(g_unichar_get_mirror_char)
	pango_get_mirror_char: make routine! [ ch [gunichar] mirrored_ch [integer!] return: [gboolean] ] pango-lib "pango_get_mirror_char" 

{ pango-break.h }
	{ Pango
	 * pango-break.h:
	 *
	 * Copyright (C) 1999 Red Hat Software
	 *

	 }


{ Logical attributes of a character.
 }
	{*
	 * PangoLogAttr:
	 * @is_line_break: if set, can break line in front of character
	 * @is_mandatory_break: if set, must break line in front of character
	 * @is_char_break: if set, can break here when doing character wrapping
	 * @is_white: is whitespace character
	 * @is_cursor_position: if set, cursor can appear in front of character.
	 * i.e. this is a grapheme boundary, or the first character
	 * in the text.
	 * This flag implements Unicode's
	 * <ulink url="http:;www.unicode.org/reports/tr29/">Grapheme
	 * Cluster Boundaries</ulink> semantics.
	 * @is_word_start: is first character in a word
	 * @is_word_end: is first non-word char after a word
	 * Note that in degenerate cases, you could have both @is_word_start
	 * and @is_word_end set for some character.
	 * @is_sentence_boundary: is a sentence boundary.
	 * There are two ways to divide sentences. The first assigns all
	 * inter-sentence whitespace/control/format chars to some sentence,
	 * so all chars are in some sentence; @is_sentence_boundary denotes
	 * the boundaries there. The second way doesn't assign
	 * between-sentence spaces, etc. to any sentence, so
	 * @is_sentence_start/@is_sentence_end mark the boundaries of those sentences.
	 * @is_sentence_start: is first character in a sentence
	 * @is_sentence_end: is first char after a sentence.
	 * Note that in degenerate cases, you could have both @is_sentence_start
	 * and @is_sentence_end set for some character. (e.g. no space after a
	 * period, so the next sentence starts right away)
	 * @backspace_deletes_character: if set, backspace deletes one character
	 * rather than the entire grapheme cluster. This
	 * field is only meaningful on grapheme
	 * boundaries (where @is_cursor_position is
	 * set).  In some languages, the full grapheme
	 * (e.g.  letter + diacritics) is considered a
	 * unit, while in others, each decomposed
	 * character in the grapheme is a unit. In the
	 * default implementation of pango_break(), this
	 * bit is set on all grapheme boundaries except
	 * those following Latin, Cyrillic or Greek base characters.
	 * @is_expandable_space: is a whitespace character that can possibly be
	 * expanded for justification purposes. (Since: 1.18)
	 * @is_word_boundary: is a word boundary.
	 * More specifically, means that this is not a position in the middle
	 * of a word.  For example, both sides of a punctuation mark are
	 * considered word boundaries.  This flag is particularly useful when
	 * selecting text word-by-word.
	 * This flag implements Unicode's
	 * <ulink url="http:;www.unicode.org/reports/tr29/">Word
	 * Boundaries</ulink> semantics. (Since: 1.22)
	 *
	 * The #PangoLogAttr structure stores information
	 * about the attributes of a single character.
	 }
	{
	struct _PangoLogAttr
	{
	  guint is_line_break       { Can break line in front of character }

	  guint is_mandatory_break  { Must break line in front of character }

	  guint is_char_break       { Can break here when doing char wrap }

	  guint is_white            { Whitespace character }

	  { Cursor can appear in front of character (i.e. this is a grapheme
	   * boundary, or the first character in the text).
	   }
	  guint is_cursor_position 

	  { Note that in degenerate cases, you could have both start/end set on
	   * some text, most likely for sentences (e.g. no space after a period, so
	   * the next sentence starts right away).
	   }

	  guint is_word_start       { first character in a word }
	  guint is_word_end         { is first non-word char after a word }

	  { There are two ways to divide sentences. The first assigns all
	   * intersentence whitespace/control/format chars to some sentence,
	   * so all chars are in some sentence; is_sentence_boundary denotes
	   * the boundaries there. The second way doesn't assign
	   * between-sentence spaces, etc. to any sentence, so
	   * is_sentence_start/is_sentence_end mark the boundaries of those
	   * sentences.
	   }
	  guint is_sentence_boundary 
	  guint is_sentence_start   { first character in a sentence }
	  guint is_sentence_end     { first non-sentence char after a sentence }

	  { If set, backspace deletes one character rather than
	   * the entire grapheme cluster.
	   }
	  guint backspace_deletes_character 

	  { Only few space variants (U+0020 and U+00A0) have variable
	   * width during justification.
	   }
	  guint is_expandable_space 

	  { Word boundary as defined by UAX#29 }
	  guint is_word_boundary 	{ is NOT in the middle of a word }
	};
	}
{ Determine information about cluster/word/line breaks in a string
 * of Unicode text.
 }

	pango_break: make routine! [ text [integer!]
	 length [integer!]
	 analysis [integer!]
	 attrs [integer!]
	 attrs_len [integer!] return: [integer!] ] pango-lib "pango_break" 

	pango_find_paragraph_boundary: make routine! [ text [integer!]
	 length [gint]
	 paragraph_delimiter_index [integer!]
	 next_paragraph_start [integer!] return: [integer!] ] pango-lib "pango_find_paragraph_boundary" 

	pango_get_log_attrs: make routine! [ text [string!]
	 length [integer!]
	 level [integer!]
	 language [integer!]
	 log_attrs [integer!]
	 attrs_len [integer!] return: [integer!] ] pango-lib "pango_get_log_attrs" 

	;#ifdef PANGO_ENABLE_ENGINE

	{ This is the default break algorithm, used if no language
	 * engine overrides it. Normally you should use pango_break()
	 * instead; this function is mostly useful for chaining up
	 * from a language engine override.
	 }

	pango_default_break: make routine! [ text [integer!]
	 length [integer!]
	 analysis [integer!]
	 attrs [integer!]
	 attrs_len [integer!] return: [integer!] ] pango-lib "pango_default_break" 


	ColorEntry: make struct! [
	  name_offset [guint16]
	  red [guchar]
	  green [guchar]
	  blue [guchar]
	] none ;

{ pango-context.h }
	{ Pango
	 * pango-context.h: Rendering contexts
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{ Sort of like a GC - application set information about how
	 * to handle scripts
	 }

;pango context functions
	pango_context_get_type: make routine! [ return: [GType] ] pango-lib "pango_context_get_type" 
	pango_context_new: make routine! [ return: [integer!] ] pango-lib "pango_context_new" 
	if pango_this_version >= 13200 [
	pango_context_changed: make routine! [ context [integer!] return: [integer!] ] pango-lib "pango_context_changed" 
	pango_context_get_serial: make routine! [ context [integer!] return: [guint] ] pango-lib "pango_context_get_serial" 
	]
	pango_context_set_font_map: make routine! [ context [integer!] font_map [integer!] return: [integer!] ] pango-lib "pango_context_set_font_map" 
	pango_context_get_font_map: make routine! [ context [integer!] return: [integer!] ] pango-lib "pango_context_get_font_map" 
	pango_context_list_families: make routine! [ context [integer!] families [integer!] n_families [integer!] return: [integer!] ] pango-lib "pango_context_list_families" 
	pango_context_load_font: make routine! [ context [integer!] desc [integer!] return: [integer!] ] pango-lib "pango_context_load_font" 
	pango_context_load_fontset: make routine! [ context [integer!] desc [integer!] language [integer!] return: [integer!] ] pango-lib "pango_context_load_fontset" 
	pango_context_get_metrics: make routine! [ context [integer!] desc [integer!] language [integer!] return: [integer!] ] pango-lib "pango_context_get_metrics" 
	pango_context_set_font_description: make routine! [ context [integer!] desc [integer!] return: [integer!] ] pango-lib "pango_context_set_font_description" 
	pango_context_get_font_description: make routine! [ context [integer!] return: [integer!] ] pango-lib "pango_context_get_font_description" 
	pango_context_get_language: make routine! [ context [integer!] return: [integer!] ] pango-lib "pango_context_get_language" 
	pango_context_set_language: make routine! [ context [integer!] language [integer!] return: [integer!] ] pango-lib "pango_context_set_language" 
	pango_context_set_base_dir: make routine! [ context [integer!] direction [PangoDirection] return: [integer!] ] pango-lib "pango_context_set_base_dir" 
	pango_context_get_base_dir: make routine! [ context [integer!] return: [PangoDirection] ] pango-lib "pango_context_get_base_dir" 
	pango_context_set_base_gravity: make routine! [ context [integer!] gravity [PangoGravity] return: [integer!] ] pango-lib "pango_context_set_base_gravity" 
	pango_context_get_base_gravity: make routine! [ context [integer!] return: [PangoGravity] ] pango-lib "pango_context_get_base_gravity" 
	pango_context_get_gravity: make routine! [ context [integer!] return: [PangoGravity] ] pango-lib "pango_context_get_gravity" 
	pango_context_set_gravity_hint: make routine! [ context [integer!] hint [PangoGravityHint] return: [integer!] ] pango-lib "pango_context_set_gravity_hint" 
	pango_context_get_gravity_hint: make routine! [ context [integer!] return: [PangoGravityHint] ] pango-lib "pango_context_get_gravity_hint" 
	pango_context_set_matrix: make routine! [ context [integer!] matrix [integer!] return: [integer!] ] pango-lib "pango_context_set_matrix" 
	pango_context_get_matrix: make routine! [ context [integer!] return: [integer!] ] pango-lib "pango_context_get_matrix" 

{ Break a string of Unicode characters into segments with
	 * consistent shaping/language engine and bidrectional level.
	 * Returns a #GList of #PangoItem's
	 }

	pango_itemize: make routine! [ context [integer!]
	 text [string!]
	 start_index [integer!]
	 length [integer!]
	 attrs [integer!]
	 cached_iter [integer!] return: [integer!] ] pango-lib "pango_itemize" 

	pango_itemize_with_base_dir: make routine! [ context [integer!]
	 base_dir [PangoDirection]
	 text [string!]
	 start_index [integer!]
	 length [integer!]
	 attrs [integer!]
	 cached_iter [integer!] return: [integer!] ] pango-lib "pango_itemize_with_base_dir" 

{ pango-coverage.h }
	{ Pango
	 * pango-coverage.h: Coverage sets for fonts
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{*
	 * PangoCoverageLevel:
	 * @PANGO_COVERAGE_NONE: The character is not representable with the font.
	 * @PANGO_COVERAGE_FALLBACK: The character is represented in a way that may be
	 * comprehensible but is not the correct graphical form.
	 * For instance, a Hangul character represented as a
	 * a sequence of Jamos, or a Latin transliteration of a Cyrillic word.
	 * @PANGO_COVERAGE_APPROXIMATE: The character is represented as basically the correct
	 * graphical form, but with a stylistic variant inappropriate for
	 * the current script.
	 * @PANGO_COVERAGE_EXACT: The character is represented as the correct graphical form.
	 *
	 * Used to indicate how well a font can represent a particular Unicode
	 * character point for a particular script.
	 }

	PANGO_COVERAGE_NONE: 0
	PANGO_COVERAGE_FALLBACK: 1
	PANGO_COVERAGE_APPROXIMATE: 2
	PANGO_COVERAGE_EXACT: 3

	PangoCoverageLevel: integer!;
; pango coverage functions
	pango_coverage_new: make routine! [ return: [integer!] ] pango-lib "pango_coverage_new" 
	pango_coverage_ref: make routine! [ coverage [integer!] return: [integer!] ] pango-lib "pango_coverage_ref" 
	pango_coverage_unref: make routine! [ coverage [integer!] return: [integer!] ] pango-lib "pango_coverage_unref" 
	pango_coverage_copy: make routine! [ coverage [integer!] return: [integer!] ] pango-lib "pango_coverage_copy" 
	pango_coverage_get: make routine! [ coverage [integer!] index_ [integer!] return: [PangoCoverageLevel] ] pango-lib "pango_coverage_get" 
	pango_coverage_set: make routine! [ coverage [integer!] index_ [integer!] level [PangoCoverageLevel] return: [integer!] ] pango-lib "pango_coverage_set" 
	pango_coverage_max: make routine! [ coverage [integer!] other [integer!] return: [integer!] ] pango-lib "pango_coverage_max" 
	pango_coverage_to_bytes: make routine! [ coverage [integer!] bytes [struct! []] n_bytes [integer!] return: [integer!] ] pango-lib "pango_coverage_to_bytes" 
	pango_coverage_from_bytes: make routine! [ bytes [integer!] n_bytes [integer!] return: [integer!] ] pango-lib "pango_coverage_from_bytes" 

{ pango-direction.h }
	{ Pango
	 * pango-direction.h: Unicode text direction
	 *
	 * Copyright (C) 2018 Matthias Clasen
	 *

	 }


	{*
	 * PangoDirection:
	 * @PANGO_DIRECTION_LTR: A strong left-to-right direction
	 * @PANGO_DIRECTION_RTL: A strong right-to-left direction
	 * @PANGO_DIRECTION_TTB_LTR: Deprecated value; treated the
	 *   same as %PANGO_DIRECTION_RTL.
	 * @PANGO_DIRECTION_TTB_RTL: Deprecated value; treated the
	 *   same as %PANGO_DIRECTION_LTR
	 * @PANGO_DIRECTION_WEAK_LTR: A weak left-to-right direction
	 * @PANGO_DIRECTION_WEAK_RTL: A weak right-to-left direction
	 * @PANGO_DIRECTION_NEUTRAL: No direction specified
	 *
	 * The #PangoDirection type represents a direction in the
	 * Unicode bidirectional algorithm; not every value in this
	 * enumeration makes sense for every usage of #PangoDirection;
	 * for example, the return value of pango_unichar_direction()
	 * and pango_find_base_dir() cannot be %PANGO_DIRECTION_WEAK_LTR
	 * or %PANGO_DIRECTION_WEAK_RTL, since every character is either
	 * neutral or has a strong direction; on the other hand
	 * %PANGO_DIRECTION_NEUTRAL doesn't make sense to pass
	 * to pango_itemize_with_base_dir().
	 *
	 * The %PANGO_DIRECTION_TTB_LTR, %PANGO_DIRECTION_TTB_RTL
	 * values come from an earlier interpretation of this
	 * enumeration as the writing direction of a block of
	 * text and are no longer used; See #PangoGravity for how
	 * vertical text is handled in Pango.
	 *
	 * If you are interested in text direction, you should
	 * really use fribidi directly. PangoDirection is only
	 * retained because it is used in some public apis.
	 *}

	PANGO_DIRECTION_LTR: 0
	PANGO_DIRECTION_RTL: 1
	PANGO_DIRECTION_TTB_LTR: 2
	PANGO_DIRECTION_TTB_RTL: 3
	PANGO_DIRECTION_WEAK_LTR: 4
	PANGO_DIRECTION_WEAK_RTL: 5
	PANGO_DIRECTION_NEUTRAL: 6

	PangoDirection: integer!;

{ pango-engine.h }
	{ Pango
	 * pango-engine.h: Engines for script and language specific processing
	 *
	 * Copyright (C) 2000,2003 Red Hat Software
	 *

	 }

	;#ifdef PANGO_ENABLE_ENGINE

	{*
	 * PANGO_RENDER_TYPE_NONE:
	 *
	 * A string constant defining the render type
	 * for engines that are not rendering-system specific.
	 *
	 * Deprecated: 1.38
	 }
	PANGO_RENDER_TYPE_NONE: "PangoRenderNone"
	{
	#define PANGO_TYPE_ENGINE              (pango_engine_get_type ())
	#define PANGO_ENGINE(object)           (G_TYPE_CHECK_INSTANCE_CAST ((object), PANGO_TYPE_ENGINE, PangoEngine))
	#define PANGO_IS_ENGINE(object)        (G_TYPE_CHECK_INSTANCE_TYPE ((object), PANGO_TYPE_ENGINE))
	#define PANGO_ENGINE_CLASS(klass)      (G_TYPE_CHECK_CLASS_CAST ((klass), PANGO_TYPE_ENGINE, PangoEngineClass))
	#define PANGO_IS_ENGINE_CLASS(klass)   (G_TYPE_CHECK_CLASS_TYPE ((klass), PANGO_TYPE_ENGINE))
	#define PANGO_ENGINE_GET_CLASS(obj)    (G_TYPE_INSTANCE_GET_CLASS ((obj), PANGO_TYPE_ENGINE, PangoEngineClass))
	}

;
pango_engine_get_type: make routine! [ return: [GType] ] pango-lib "pango_engine_get_type" 
;
;

	{*
	 * PangoEngineShape:
	 *
	 * The #PangoEngineShape class is implemented by engines that
	 * customize the rendering-system dependent part of the
	 * Pango pipeline for a particular script or language.
	 * A #PangoEngineShape implementation is then specific to both
	 * a particular rendering system or group of rendering systems
	 * and to a particular script. For instance, there is one
	 * #PangoEngineShape implementation to handle shaping Arabic
	 * for Fontconfig-based backends.
	 *
	 * Deprecated: 1.38
	 *}
	_PangoEngineShape: make struct! [
	  parent_instance [PangoEngine]
	] none ;


{ pango-font.h }
	{ Pango
	 * pango-font.h: Font handling
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{*
	 * PangoFontDescription:
	 *
	 * The #PangoFontDescription structure represents the description
	 * of an ideal font. These structures are used both to list
	 * what fonts are available on the system and also for specifying
	 * the characteristics of a font to load.
	 }
	{*
	 * PangoFontMetrics:
	 *
	 * A #PangoFontMetrics structure holds the overall metric information
	 * for a font (possibly restricted to a script). The fields of this
	 * structure are private to implementations of a font backend. See
	 * the documentation of the corresponding getters for documentation
	 * of their meaning.
	 }

	{*
	 * PangoStyle:
	 * @PANGO_STYLE_NORMAL: the font is upright.
	 * @PANGO_STYLE_OBLIQUE: the font is slanted, but in a roman style.
	 * @PANGO_STYLE_ITALIC: the font is slanted in an italic style.
	 *
	 * An enumeration specifying the various slant styles possible for a font.
	 *}

	PANGO_STYLE_NORMAL: 0
	PANGO_STYLE_OBLIQUE: 1
	PANGO_STYLE_ITALIC: 2

	PangoStyle: integer!;

	{*
	 * PangoVariant:
	 * @PANGO_VARIANT_NORMAL: A normal font.
	 * @PANGO_VARIANT_SMALL_CAPS: A font with the lower case characters
	 * replaced by smaller variants of the capital characters.
	 *
	 * An enumeration specifying capitalization variant of the font.
	 }

	PANGO_VARIANT_NORMAL: 0
	PANGO_VARIANT_SMALL_CAPS: 1

	PangoVariant: integer!;

	{*
	 * PangoWeight:
	 * @PANGO_WEIGHT_THIN: the thin weight (= 100; Since: 1.24)
	 * @PANGO_WEIGHT_ULTRALIGHT: the ultralight weight (= 200)
	 * @PANGO_WEIGHT_LIGHT: the light weight (= 300)
	 * @PANGO_WEIGHT_SEMILIGHT: the semilight weight (= 350; Since: 1.36.7)
	 * @PANGO_WEIGHT_BOOK: the book weight (= 380; Since: 1.24)
	 * @PANGO_WEIGHT_NORMAL: the default weight (= 400)
	 * @PANGO_WEIGHT_MEDIUM: the normal weight (= 500; Since: 1.24)
	 * @PANGO_WEIGHT_SEMIBOLD: the semibold weight (= 600)
	 * @PANGO_WEIGHT_BOLD: the bold weight (= 700)
	 * @PANGO_WEIGHT_ULTRABOLD: the ultrabold weight (= 800)
	 * @PANGO_WEIGHT_HEAVY: the heavy weight (= 900)
	 * @PANGO_WEIGHT_ULTRAHEAVY: the ultraheavy weight (= 1000; Since: 1.24)
	 *
	 * An enumeration specifying the weight (boldness) of a font. This is a numerical
	 * value ranging from 100 to 1000, but there are some predefined values:
	 }

	PANGO_WEIGHT_THIN: 100
	PANGO_WEIGHT_ULTRALIGHT: 200
	PANGO_WEIGHT_LIGHT: 300
	PANGO_WEIGHT_SEMILIGHT: 350
	PANGO_WEIGHT_BOOK: 380
	PANGO_WEIGHT_NORMAL: 400
	PANGO_WEIGHT_MEDIUM: 500
	PANGO_WEIGHT_SEMIBOLD: 600
	PANGO_WEIGHT_BOLD: 700
	PANGO_WEIGHT_ULTRABOLD: 800
	PANGO_WEIGHT_HEAVY: 900
	PANGO_WEIGHT_ULTRAHEAVY: 1000

	PangoWeight: integer!;

	{*
	 * PangoStretch:
	 * @PANGO_STRETCH_ULTRA_CONDENSED: ultra condensed width
	 * @PANGO_STRETCH_EXTRA_CONDENSED: extra condensed width
	 * @PANGO_STRETCH_CONDENSED: condensed width
	 * @PANGO_STRETCH_SEMI_CONDENSED: semi condensed width
	 * @PANGO_STRETCH_NORMAL: the normal width
	 * @PANGO_STRETCH_SEMI_EXPANDED: semi expanded width
	 * @PANGO_STRETCH_EXPANDED: expanded width
	 * @PANGO_STRETCH_EXTRA_EXPANDED: extra expanded width
	 * @PANGO_STRETCH_ULTRA_EXPANDED: ultra expanded width
	 *
	 * An enumeration specifying the width of the font relative to other designs
	 * within a family.
	 }

	PANGO_STRETCH_ULTRA_CONDENSED: 0
	PANGO_STRETCH_EXTRA_CONDENSED: 1
	PANGO_STRETCH_CONDENSED: 2
	PANGO_STRETCH_SEMI_CONDENSED: 3
	PANGO_STRETCH_NORMAL: 4
	PANGO_STRETCH_SEMI_EXPANDED: 5
	PANGO_STRETCH_EXPANDED: 6
	PANGO_STRETCH_EXTRA_EXPANDED: 7
	PANGO_STRETCH_ULTRA_EXPANDED: 8

	PangoStretch: integer!;

	{*
	 * PangoFontMask:
	 * @PANGO_FONT_MASK_FAMILY: the font family is specified.
	 * @PANGO_FONT_MASK_STYLE: the font style is specified.
	 * @PANGO_FONT_MASK_VARIANT: the font variant is specified.
	 * @PANGO_FONT_MASK_WEIGHT: the font weight is specified.
	 * @PANGO_FONT_MASK_STRETCH: the font stretch is specified.
	 * @PANGO_FONT_MASK_SIZE: the font size is specified.
	 * @PANGO_FONT_MASK_GRAVITY: the font gravity is specified (Since: 1.16.)
	 * @PANGO_FONT_MASK_VARIATIONS: OpenType font variations are specified (Since: 1.42)
	 *
	 * The bits in a #PangoFontMask correspond to fields in a
	 * #PangoFontDescription that have been set.
	 }
	PANGO_FONT_MASK_FAMILY: 1 ;  = 1 << 0,
	PANGO_FONT_MASK_STYLE: 2 ;  = 1 << 1,
	PANGO_FONT_MASK_VARIANT: 4 ; = 1 << 2,
	PANGO_FONT_MASK_WEIGHT: 8 ;  = 1 << 3,
	PANGO_FONT_MASK_STRETCH: 16 ; = 1 << 4,
	PANGO_FONT_MASK_SIZE: 32 ;    = 1 << 5,
	PANGO_FONT_MASK_GRAVITY: 64 ; = 1 << 6,
	PANGO_FONT_MASK_VARIATIONS: 128 ; = 1 << 7,

	PangoFontMask: integer!;

{ CSS scale factors (1.2 factor between each size) }
	{*
	 * PANGO_SCALE_XX_SMALL:
	 *
	 * The scale factor for three shrinking steps (1 / (1.2 * 1.2 * 1.2)).
	 }
	{*
	 * PANGO_SCALE_X_SMALL:
	 *
	 * The scale factor for two shrinking steps (1 / (1.2 * 1.2)).
	 }
	{*
	 * PANGO_SCALE_SMALL:
	 *
	 * The scale factor for one shrinking step (1 / 1.2).
	 }
	{*
	 * PANGO_SCALE_MEDIUM:
	 *
	 * The scale factor for normal size (1.0).
	 }
	{*
	 * PANGO_SCALE_LARGE:
	 *
	 * The scale factor for one magnification step (1.2).
	 }
	{*
	 * PANGO_SCALE_X_LARGE:
	 *
	 * The scale factor for two magnification steps (1.2 * 1.2).
	 }
	{*
	 * PANGO_SCALE_XX_LARGE:
	 *
	 * The scale factor for three magnification steps (1.2 * 1.2 * 1.2).
	 }
	PANGO_SCALE_XX_SMALL:    0.5787037037037 
	PANGO_SCALE_X_SMALL:     0.6444444444444 
	PANGO_SCALE_SMALL:       0.8333333333333 
	PANGO_SCALE_MEDIUM:      1.0 
	PANGO_SCALE_LARGE:       1.2 
	PANGO_SCALE_X_LARGE:     1.4399999999999 
	PANGO_SCALE_XX_LARGE:    1.728 

{
* PangoFontDescription
 }
	{*
	 * PANGO_TYPE_FONT_DESCRIPTION:
	 *
	 * The #GObject type for #PangoFontDescription.
	 }

	pango_font_description_get_type: make routine! [ return: [GType] ] pango-lib "pango_font_description_get_type" 
	pango_font_description_new: make routine! [ return: [integer!] ] pango-lib "pango_font_description_new" 
	pango_font_description_copy: make routine! [ desc [integer!] return: [integer!] ] pango-lib "pango_font_description_copy" 
	pango_font_description_copy_static: make routine! [ desc [integer!] return: [integer!] ] pango-lib "pango_font_description_copy_static" 
	pango_font_description_hash: make routine! [ desc [integer!] return: [guint] ] pango-lib "pango_font_description_hash" 
	pango_font_description_equal: make routine! [ desc1 [integer!] desc2 [integer!] return: [gboolean] ] pango-lib "pango_font_description_equal" 
	pango_font_description_free: make routine! [ desc [integer!] return: [integer!] ] pango-lib "pango_font_description_free" 
	pango_font_descriptions_free: make routine! [ descs [struct! []] n_descs [integer!] return: [integer!] ] pango-lib "pango_font_descriptions_free" 
	pango_font_description_set_family: make routine! [ desc [integer!] family [string!] return: [integer!] ] pango-lib "pango_font_description_set_family" 
	pango_font_description_set_family_static: make routine! [ desc [integer!] family [string!] return: [integer!] ] pango-lib "pango_font_description_set_family_static" 
	pango_font_description_get_family: make routine! [ desc [integer!] return: [string!] ] pango-lib "pango_font_description_get_family" 
	pango_font_description_set_style: make routine! [ desc [integer!] style [PangoStyle] return: [integer!] ] pango-lib "pango_font_description_set_style" 
	pango_font_description_get_style: make routine! [ desc [integer!] return: [PangoStyle] ] pango-lib "pango_font_description_get_style" 
	pango_font_description_set_variant: make routine! [ desc [integer!] variant [PangoVariant] return: [integer!] ] pango-lib "pango_font_description_set_variant" 
	pango_font_description_get_variant: make routine! [ desc [integer!] return: [PangoVariant] ] pango-lib "pango_font_description_get_variant" 
	pango_font_description_set_weight: make routine! [ desc [integer!] weight [PangoWeight] return: [integer!] ] pango-lib "pango_font_description_set_weight" 
	pango_font_description_get_weight: make routine! [ desc [integer!] return: [PangoWeight] ] pango-lib "pango_font_description_get_weight" 
	pango_font_description_set_stretch: make routine! [ desc [integer!] stretch [PangoStretch] return: [integer!] ] pango-lib "pango_font_description_set_stretch" 
	pango_font_description_get_stretch: make routine! [ desc [integer!] return: [PangoStretch] ] pango-lib "pango_font_description_get_stretch" 
	pango_font_description_set_size: make routine! [ desc [integer!] size [gint] return: [integer!] ] pango-lib "pango_font_description_set_size" 
	pango_font_description_get_size: make routine! [ desc [integer!] return: [gint] ] pango-lib "pango_font_description_get_size" 
	pango_font_description_set_absolute_size: make routine! [ desc [integer!] size [double] return: [integer!] ] pango-lib "pango_font_description_set_absolute_size" 
	pango_font_description_get_size_is_absolute: make routine! [ desc [integer!] return: [gboolean] ] pango-lib "pango_font_description_get_size_is_absolute" 
	pango_font_description_set_gravity: make routine! [ desc [integer!] gravity [PangoGravity] return: [integer!] ] pango-lib "pango_font_description_set_gravity" 
	pango_font_description_get_gravity: make routine! [ desc [integer!] return: [PangoGravity] ] pango-lib "pango_font_description_get_gravity" 
	if pango_this_version >= 14200 [
	pango_font_description_set_variations_static: make routine! [ desc [integer!] settings [string!] return: [integer!] ] pango-lib "pango_font_description_set_variations_static" 
	pango_font_description_set_variations: make routine! [ desc [integer!] settings [string!] return: [integer!] ] pango-lib "pango_font_description_set_variations" 
	pango_font_description_get_variations: make routine! [ desc [integer!] return: [string!] ] pango-lib "pango_font_description_get_variations" 
	]
	pango_font_description_get_set_fields: make routine! [ desc [integer!] return: [PangoFontMask] ] pango-lib "pango_font_description_get_set_fields" 
	pango_font_description_unset_fields: make routine! [ desc [integer!] to_unset [PangoFontMask] return: [integer!] ] pango-lib "pango_font_description_unset_fields" 
	pango_font_description_merge: make routine! [ desc [integer!] desc_to_merge [integer!] replace_existing [gboolean] return: [integer!] ] pango-lib "pango_font_description_merge" 
	pango_font_description_merge_static: make routine! [ desc [integer!] desc_to_merge [integer!] replace_existing [gboolean] return: [integer!] ] pango-lib "pango_font_description_merge_static" 
	pango_font_description_better_match: make routine! [ desc [integer!] old_match [integer!] new_match [integer!] return: [gboolean] ] pango-lib "pango_font_description_better_match" 
	pango_font_description_from_string: make routine! [ str [string!] return: [integer!] ] pango-lib "pango_font_description_from_string" 
	pango_font_description_to_string: make routine! [ desc [integer!] return: [string!] ] pango-lib "pango_font_description_to_string" 
	pango_font_description_to_filename: make routine! [ desc [integer!] return: [string!] ] pango-lib "pango_font_description_to_filename" 

{
* PangoFontMetrics
	}

	{*
	 * PANGO_TYPE_FONT_METRICS:
	 *
	 * The #GObject type for #PangoFontMetrics.
	 }
	pango_font_metrics_get_type: make routine! [ return: [GType] ] pango-lib "pango_font_metrics_get_type" 
	pango_font_metrics_ref: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_ref" 
	pango_font_metrics_unref: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_unref" 
	pango_font_metrics_get_ascent: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_ascent" 
	pango_font_metrics_get_descent: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_descent" 
	pango_font_metrics_get_approximate_char_width: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_approximate_char_width" 
	pango_font_metrics_get_approximate_digit_width: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_approximate_digit_width" 
	pango_font_metrics_get_underline_position: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_underline_position" 
	pango_font_metrics_get_underline_thickness: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_underline_thickness" 
	pango_font_metrics_get_strikethrough_position: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_strikethrough_position" 
	pango_font_metrics_get_strikethrough_thickness: make routine! [ metrics [integer!] return: [integer!] ] pango-lib "pango_font_metrics_get_strikethrough_thickness" 
	pango_font_metrics_new: make routine! [ return: [integer!] ] pango-lib "pango_font_metrics_new" 

	_PangoFontMetrics: make struct! [
	 { <private> }
	  ref_count [guint]
	  ascent [integer!]
	  descent [integer!]
	  approximate_char_width [integer!]
	  approximate_digit_width [integer!]
	  underline_position [integer!]
	  underline_thickness [integer!]
	  strikethrough_position [integer!]
	  strikethrough_thickness [integer!]
	] none ;
{
* PangoFontFamily
	}

	pango_font_family_get_type: make routine! [ return: [GType] ] pango-lib "pango_font_family_get_type" 
	pango_font_family_list_faces: make routine! [ family [integer!] faces [integer!] n_faces [integer!] return: [integer!] ] pango-lib "pango_font_family_list_faces" 
	pango_font_family_get_name: make routine! [ family [integer!] return: [string!] ] pango-lib "pango_font_family_get_name" 
	pango_font_family_is_monospace: make routine! [ family [integer!] return: [gboolean] ] pango-lib "pango_font_family_is_monospace" 
	if pango_this_version >= 14400 [
	pango_font_family_is_variable: make routine! [ family [integer!] return: [gboolean] ] pango-lib "pango_font_family_is_variable" 
	]

	{*
	 * PangoFontFamily:
	 *
	 * The #PangoFontFamily structure is used to represent a family of related
	 * font faces. The faces in a family share a common design, but differ in
	 * slant, weight, width and other aspects.
	 }
	_PangoFontFamily: make struct! [
	  parent_instance [GObject]
	] none ;

{
* PangoFontFace
	}

	pango_font_face_get_type: make routine! [ return: [GType] ] pango-lib "pango_font_face_get_type" 
	pango_font_face_describe: make routine! [ face [integer!] return: [integer!] ] pango-lib "pango_font_face_describe" 
	pango_font_face_get_face_name: make routine! [ face [integer!] return: [string!] ] pango-lib "pango_font_face_get_face_name" 
	pango_font_face_list_sizes: make routine! [ face [integer!] sizes [struct! []] n_sizes [integer!] return: [integer!] ] pango-lib "pango_font_face_list_sizes" 
	pango_font_face_is_synthesized: make routine! [ face [integer!] return: [gboolean] ] pango-lib "pango_font_face_is_synthesized" 

	{*
	 * PangoFontFace:
	 *
	 * The #PangoFontFace structure is used to represent a group of fonts with
	 * the same family, slant, weight, width, but varying sizes.
	 }
	_PangoFontFace: make struct! [
	  parent_instance [GObject]
	] none ;

{
* PangoFont
	}

	pango_font_get_type: make routine! [ return: [GType] ] pango-lib "pango_font_get_type" 
	pango_font_describe: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_font_describe" 
	pango_font_describe_with_absolute_size: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_font_describe_with_absolute_size" 
	pango_font_get_coverage: make routine! [ font [integer!] language [integer!] return: [integer!] ] pango-lib "pango_font_get_coverage" 
	pango_font_find_shaper: make routine! [ font [integer!] language [integer!] ch [guint32] return: [integer!] ] pango-lib "pango_font_find_shaper" 
	pango_font_get_metrics: make routine! [ font [integer!] language [integer!] return: [integer!] ] pango-lib "pango_font_get_metrics" 
	pango_font_get_glyph_extents: make routine! [ font [integer!]
	 glyph [PangoGlyph]
	 ink_rect [integer!]
	 logical_rect [integer!] return: [integer!] ] pango-lib "pango_font_get_glyph_extents" 

	pango_font_get_font_map: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_font_get_font_map" 

	{*
	 * PangoFont:
	 *
	 * The #PangoFont structure is used to represent
	 * a font in a rendering-system-independent matter.
	 * To create an implementation of a #PangoFont,
	 * the rendering-system specific code should allocate
	 * a larger structure that contains a nested
	 * #PangoFont, fill in the <structfield>klass</structfield> member of
	 * the nested #PangoFont with a pointer to
	 * a appropriate #PangoFontClass, then call
	 * pango_font_init() on the structure.
	 *
	 * The #PangoFont structure contains one member
	 * which the implementation fills in.
	 }
	_PangoFont: make struct! [
	  parent_instance [GObject]
	] none ;

	{ used for very rare and miserable situtations that we cannot even
	 * draw a hexbox
	 }
	PANGO_UNKNOWN_GLYPH_WIDTH:  10
	PANGO_UNKNOWN_GLYPH_HEIGHT: 14

; PANGO GLYPH
	{*
	 * PANGO_GLYPH_EMPTY:
	 *
	 * The %PANGO_GLYPH_EMPTY macro represents a #PangoGlyph value that has a
	 *  special meaning, which is a zero-width empty glyph.  This is useful for
	 * example in shaper modules, to use as the glyph for various zero-width
	 * Unicode characters (those passing pango_is_zero_width()).
	 }
	{*
	 * PANGO_GLYPH_INVALID_INPUT:
	 *
	 * The %PANGO_GLYPH_INVALID_INPUT macro represents a #PangoGlyph value that has a
	 * special meaning of invalid input.  #PangoLayout produces one such glyph
	 * per invalid input UTF-8 byte and such a glyph is rendered as a crossed
	 * box.
	 *
	 * Note that this value is defined such that it has the %PANGO_GLYPH_UNKNOWN_FLAG
	 * on.
	 *
	 * Since: 1.20
	 }
	{*
	 * PANGO_GLYPH_UNKNOWN_FLAG:
	 *
	 * The %PANGO_GLYPH_UNKNOWN_FLAG macro is a flag value that can be added to
	 * a #gunichar value of a valid Unicode character, to produce a #PangoGlyph
	 * value, representing an unknown-character glyph for the respective #gunichar.
	 }
	{*
	 * PANGO_GET_UNKNOWN_GLYPH:
	 * @wc: a Unicode character
	 *
	 * The way this unknown glyphs are rendered is backend specific.  For example,
	 * a box with the hexadecimal Unicode code-point of the character written in it
	 * is what is done in the most common backends.
	 *
	 * Returns: a #PangoGlyph value that means no glyph was found for @wc.
	 }

	PANGO_GLYPH_EMPTY:              268435455 
	PANGO_GLYPH_INVALID_INPUT:      -1 
	PANGO_GLYPH_UNKNOWN_FLAG:       268435456 
	;PANGO_GET_UNKNOWN_GLYPH(wc) PANGO_GLYPH_UNKNOWN_FLAG

{ pango-fontmap.h }
	{ Pango
	 * pango-font.h: Font handling
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *
	 }

	pango_font_map_get_type: make routine! [ return: [GType] ] pango-lib "pango_font_map_get_type" 
	pango_font_map_create_context: make routine! [ fontmap [integer!] return: [integer!] ] pango-lib "pango_font_map_create_context" 
	pango_font_map_load_font: make routine! [ fontmap [integer!] context [integer!] desc [integer!] return: [integer!] ] pango-lib "pango_font_map_load_font" 
	pango_font_map_load_fontset: make routine! [ fontmap [integer!]
	 context [integer!]
	 desc [integer!]
	 language [integer!] return: [integer!] ] pango-lib "pango_font_map_load_fontset" 

	pango_font_map_list_families: make routine! [ fontmap [integer!] families [integer!] n_families [integer!] return: [integer!] ] pango-lib "pango_font_map_list_families" 
	if pango_this_version >= 13200 [
	pango_font_map_get_serial: make routine! [ fontmap [integer!] return: [guint] ] pango-lib "pango_font_map_get_serial" 
	]
	if pango_this_version >= 13400 [
	pango_font_map_changed: make routine! [ fontmap [integer!] return: [integer!] ] pango-lib "pango_font_map_changed" 
	]

	{*
	 * PangoFontMap:
	 *
	 * The #PangoFontMap represents the set of fonts available for a
	 * particular rendering system. This is a virtual object with
	 * implementations being specific to particular rendering systems.  To
	 * create an implementation of a #PangoFontMap, the rendering-system
	 * specific code should allocate a larger structure that contains a nested
	 * #PangoFontMap, fill in the <structfield>klass</structfield> member of the nested #PangoFontMap with a
	 * pointer to a appropriate #PangoFontMapClass, then call
	 * pango_font_map_init() on the structure.
	 *
	 * The #PangoFontMap structure contains one member which the implementation
	 * fills in.
	 }
	_PangoFontMap: make struct! [
	  parent_instance [GObject]
	] none ;

	{*
	 * PangoFontMapClass:
	 * @parent_class: parent #GObjectClass.
	 * @load_font: a function to load a font with a given description. See
	 * pango_font_map_load_font().
	 * @list_families: A function to list available font families. See
	 * pango_font_map_list_families().
	 * @load_fontset: a function to load a fontset with a given given description
	 * suitable for a particular language. See pango_font_map_load_fontset().
	 * @shape_engine_type: the type of rendering-system-dependent engines that
	 * can handle fonts of this fonts loaded with this fontmap.
	 * @get_serial: a function to get the serial number of the fontmap.
	 * See pango_font_map_get_serial().
	 * @changed: See pango_font_map_changed()
	 *
	 * The #PangoFontMapClass structure holds the virtual functions for
	 * a particular #PangoFontMap implementation.
	 }

{ pango-fontset.h }
	{ Pango
	 * pango-fontset.h: Font set handling
	 *
	 * Copyright (C) 2001 Red Hat Software
	 *

	 }

	{
	 * PangoFontset
	 }

	pango_fontset_get_type: make routine! [ return: [GType] ] pango-lib "pango_fontset_get_type" 

	pango_fontset_get_font: make routine! [ fontset [integer!] wc [guint] return: [integer!] ] pango-lib "pango_fontset_get_font" 
	pango_fontset_get_metrics: make routine! [ fontset [integer!] return: [integer!] ] pango-lib "pango_fontset_get_metrics" 
	pango_fontset_foreach: make routine! [ fontset [integer!]
	func [integer!];[callback]
	data [gpointer] return: [integer!] ] pango-lib "pango_fontset_foreach" 

	{*
	 * PangoFontset:
	 *
	 * A #PangoFontset represents a set of #PangoFont to use
	 * when rendering text. It is the result of resolving a
	 * #PangoFontDescription against a particular #PangoContext.
	 * It has operations for finding the component font for
	 * a particular Unicode character, and for finding a composite
	 * set of metrics for the entire fontset.
	 }
	_PangoFontset: make struct! [
	  parent_instance [GObject]
	] none ;

	{*
	 * PangoFontsetClass:
	 * @parent_class: parent #GObjectClass.
	 * @get_font: a function to get the font in the fontset that contains the
	 * best glyph for the given Unicode character; see pango_fontset_get_font().
	 * @get_metrics: a function to get overall metric information for the fonts
	 * in the fontset; see pango_fontset_get_metrics().
	 * @get_language: a function to get the language of the fontset.
	 * @foreach: a function to loop over the fonts in the fontset. See
	 * pango_fontset_foreach().
	 *
	 * The #PangoFontsetClass structure holds the virtual functions for
	 * a particular #PangoFontset implementation.
	 }
	{
	 * PangoFontsetSimple
	 }

	{*
	 * PANGO_TYPE_FONTSET_SIMPLE:
	 *
	 * The #GObject type for #PangoFontsetSimple.
	 }
	{*
	 * PangoFontsetSimple:
	 *
	 * #PangoFontsetSimple is a implementation of the abstract
	 * #PangoFontset base class in terms of an array of fonts,
	 * which the creator provides when constructing the
	 * #PangoFontsetSimple.
	 }

	pango_fontset_simple_get_type: make routine! [ return: [GType] ] pango-lib "pango_fontset_simple_get_type" 
	pango_fontset_simple_new: make routine! [ language [integer!] return: [integer!] ] pango-lib "pango_fontset_simple_new" 
	pango_fontset_simple_append: make routine! [ fontset [integer!] font [integer!] return: [integer!] ] pango-lib "pango_fontset_simple_append" 
	pango_fontset_simple_size: make routine! [ fontset [integer!] return: [integer!] ] pango-lib "pango_fontset_simple_size" 

{ pango-glyph-item.h }
	{ Pango
	 * pango-glyph-item.h: Pair of PangoItem and a glyph string
	 *
	 * Copyright (C) 2002 Red Hat Software
	 *

	 }

	{*
	 * PangoGlyphItem:
	 * @item: corresponding #PangoItem.
	 * @glyphs: corresponding #PangoGlyphString.
	 *
	 * A #PangoGlyphItem is a pair of a #PangoItem and the glyphs
	 * resulting from shaping the text corresponding to an item.
	 * As an example of the usage of #PangoGlyphItem, the results
	 * of shaping text with #PangoLayout is a list of #PangoLayoutLine,
	 * each of which contains a list of #PangoGlyphItem.
	 }

	_PangoGlyphItem: make struct! [
		item [integer!]
		glyphs [integer!]
	] none ;

	pango_glyph_item_get_type: make routine! [ return: [GType] ] pango-lib "pango_glyph_item_get_type" 
	pango_glyph_item_split: make routine! [ orig [integer!] text [string!] split_index [integer!] return: [integer!] ] pango-lib "pango_glyph_item_split" 
	pango_glyph_item_copy: make routine! [ orig [integer!] return: [integer!] ] pango-lib "pango_glyph_item_copy" 
	pango_glyph_item_free: make routine! [ glyph_item [integer!] return: [integer!] ] pango-lib "pango_glyph_item_free" 
	pango_glyph_item_apply_attrs: make routine! [ glyph_item [integer!] text [string!] list [integer!] return: [integer!] ] pango-lib "pango_glyph_item_apply_attrs" 
	pango_glyph_item_letter_space: make routine! [ glyph_item [integer!]
	 text [string!]
	 log_attrs [integer!]
	 letter_spacing [integer!] return: [integer!] ] pango-lib "pango_glyph_item_letter_space" 

	pango_glyph_item_get_logical_widths: make routine! [ glyph_item [integer!] text [string!] logical_widths [integer!] return: [integer!] ] pango-lib "pango_glyph_item_get_logical_widths" 

	{*
	 * PangoGlyphItemIter:
	 *
	 * A #PangoGlyphItemIter is an iterator over the clusters in a
	 * #PangoGlyphItem.  The <firstterm>forward direction</firstterm> of the
	 * iterator is the logical direction of text.  That is, with increasing
	 * @start_index and @start_char values.  If @glyph_item is right-to-left
	 * (that is, if <literal>@glyph_item->item->analysis.level</literal> is odd),
	 * then @start_glyph decreases as the iterator moves forward.  Moreover,
	 * in right-to-left cases, @start_glyph is greater than @end_glyph.
	 *
	 * An iterator should be initialized using either of
	 * pango_glyph_item_iter_init_start() and
	 * pango_glyph_item_iter_init_end(), for forward and backward iteration
	 * respectively, and walked over using any desired mixture of
	 * pango_glyph_item_iter_next_cluster() and
	 * pango_glyph_item_iter_prev_cluster().  A common idiom for doing a
	 * forward iteration over the clusters is:
	 * <programlisting>
	 * PangoGlyphItemIter cluster_iter;
	 * gboolean have_cluster;
	 *
	 * for (have_cluster = pango_glyph_item_iter_init_start (&amp;cluster_iter,
	 *                                                       glyph_item, text);
	 *      have_cluster;
	 *      have_cluster = pango_glyph_item_iter_next_cluster (&amp;cluster_iter))
	 * {
	 *   ...
	 * }
	 * </programlisting>
	 *
	 * Note that @text is the start of the text for layout, which is then
	 * indexed by <literal>@glyph_item->item->offset</literal> to get to the
	 * text of @glyph_item.  The @start_index and @end_index values can directly
	 * index into @text.  The @start_glyph, @end_glyph, @start_char, and @end_char
	 * values however are zero-based for the @glyph_item.  For each cluster, the
	 * item pointed at by the start variables is included in the cluster while
	 * the one pointed at by end variables is not.
	 *
	 * None of the members of a #PangoGlyphItemIter should be modified manually.
	 *
	 * Since: 1.22
	 }

	_PangoGlyphItemIter: make struct! [
		glyph_item [integer!]
		text [integer!]
		start_glyph [integer!]
		start_index [integer!]
		start_char [integer!]
		end_glyph [integer!]
		end_index [integer!]
		end_char [integer!]
	] none ;

	pango_glyph_item_iter_get_type: make routine! [ return: [GType] ] pango-lib "pango_glyph_item_iter_get_type" 
	pango_glyph_item_iter_copy: make routine! [ orig [integer!] return: [integer!] ] pango-lib "pango_glyph_item_iter_copy" 
	pango_glyph_item_iter_free: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_glyph_item_iter_free" 
	pango_glyph_item_iter_init_start: make routine! [ iter [integer!] glyph_item [integer!] text [string!] return: [gboolean] ] pango-lib "pango_glyph_item_iter_init_start" 
	pango_glyph_item_iter_init_end: make routine! [ iter [integer!] glyph_item [integer!] text [string!] return: [gboolean] ] pango-lib "pango_glyph_item_iter_init_end" 
	pango_glyph_item_iter_next_cluster: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_glyph_item_iter_next_cluster" 
	pango_glyph_item_iter_prev_cluster: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_glyph_item_iter_prev_cluster" 

{ pango-glyph.h }
	{ Pango
	 * pango-glyph.h: Glyph storage
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{ 1024ths of a device unit }
	{*
	 * PangoGlyphUnit:
	 *
	 * The #PangoGlyphUnit type is used to store dimensions within
	 * Pango. Dimensions are stored in 1/%PANGO_SCALE of a device unit.
	 * (A device unit might be a pixel for screen display, or
	 * a point on a printer.) %PANGO_SCALE is currently 1024, and
	 * may change in the future (unlikely though), but you should not
	 * depend on its exact value. The PANGO_PIXELS() macro can be used
	 * to convert from glyph units into device units with correct rounding.
	 }

	{ Positioning information about a glyph
	 }
	{*
	 * PangoGlyphGeometry:
	 * @width: the logical width to use for the the character.
	 * @x_offset: horizontal offset from nominal character position.
	 * @y_offset: vertical offset from nominal character position.
	 *
	 * The #PangoGlyphGeometry structure contains width and positioning
	 * information for a single glyph.
	 }
	_PangoGlyphGeometry: make struct! [
		width [PangoGlyphUnit]
		x_offset [PangoGlyphUnit]
		y_offset [PangoGlyphUnit]
	] none ;

	{ Visual attributes of a glyph
	 }
	{*
	 * PangoGlyphVisAttr:
	 * @is_cluster_start: set for the first logical glyph in each cluster. (Clusters
	 * are stored in visual order, within the cluster, glyphs
	 * are always ordered in logical order, since visual
	 * order is meaningless; that is, in Arabic text, accent glyphs
	 * follow the glyphs for the base character.)
	 *
	 * The PangoGlyphVisAttr is used to communicate information between
	 * the shaping phase and the rendering phase.  More attributes may be
	 * added in the future.
	 }
	_PangoGlyphVisAttr: make struct! [
	  is_cluster_start [guint] ;: 1
	] none ;

	{ A single glyph
	 }
	{*
	 * PangoGlyphInfo:
	 * @glyph: the glyph itself.
	 * @geometry: the positional information about the glyph.
	 * @attr: the visual attributes of the glyph.
	 *
	 * The #PangoGlyphInfo structure represents a single glyph together with
	 * positioning information and visual attributes.
	 * It contains the following fields.
	 }
	_PangoGlyphInfo: make struct! [
	  glyph [PangoGlyph]
	  geometry [PangoGlyphGeometry]
	  attr [PangoGlyphVisAttr]
	] none ;

	{ A string of glyphs with positional information and visual attributes -
	 * ready for drawing
	 }
	{*
	 * PangoGlyphString:
	 * @num_glyphs: number of the glyphs in this glyph string.
	 * @glyphs: (array length=num_glyphs): array of glyph information
	 *          for the glyph string.
	 * @log_clusters: logical cluster info, indexed by the byte index
	 *                within the text corresponding to the glyph string.
	 *
	 * The #PangoGlyphString structure is used to store strings
	 * of glyphs with geometry and visual attribute information.
	 * The storage for the glyph information is owned
	 * by the structure which simplifies memory management.
	 }
	_PangoGlyphString: make struct! [
		num_glyphs [gint]
		glyphs [integer!]

		{ This is a memory inefficient way of representing the information
		* here - each value gives the byte index within the text
		* corresponding to the glyph string of the start of the cluster to
		* which the glyph belongs.
		}
		log_clusters [integer!]

		{< private >}
		space [gint]
	] none ;

	pango_glyph_string_new: make routine! [ return: [integer!] ] pango-lib "pango_glyph_string_new" 
	pango_glyph_string_set_size: make routine! [ string [integer!] new_len [gint] return: [integer!] ] pango-lib "pango_glyph_string_set_size" 
	pango_glyph_string_get_type: make routine! [ return: [GType] ] pango-lib "pango_glyph_string_get_type" 
	pango_glyph_string_copy: make routine! [ string [integer!] return: [integer!] ] pango-lib "pango_glyph_string_copy" 
	pango_glyph_string_free: make routine! [ string [integer!] return: [integer!] ] pango-lib "pango_glyph_string_free" 
	pango_glyph_string_extents: make routine! [ glyphs [integer!]
	 font [integer!]
	 ink_rect [integer!]
	 logical_rect [integer!] return: [integer!] ] pango-lib "pango_glyph_string_extents" 

	pango_glyph_string_get_width: make routine! [ glyphs [integer!] return: [integer!] ] pango-lib "pango_glyph_string_get_width" 
	pango_glyph_string_extents_range: make routine! [ glyphs [integer!]
	 start [integer!]
	 end [integer!]
	 font [integer!]
	 ink_rect [integer!]
	 logical_rect [integer!] return: [integer!] ] pango-lib "pango_glyph_string_extents_range" 

	pango_glyph_string_get_logical_widths: make routine! [ glyphs [integer!]
	 text [string!]
	 length [integer!]
	 embedding_level [integer!]
	 logical_widths [integer!] return: [integer!] ] pango-lib "pango_glyph_string_get_logical_widths" 

	pango_glyph_string_index_to_x: make routine! [ glyphs [integer!]
	 text [string!]
	 length [integer!]
	 analysis [integer!]
	 index_ [integer!]
	 trailing [gboolean]
	 x_pos [integer!] return: [integer!] ] pango-lib "pango_glyph_string_index_to_x" 

	pango_glyph_string_x_to_index: make routine! [ glyphs [integer!]
	 text [string!]
	 length [integer!]
	 analysis [integer!]
	 x_pos [integer!]
	 index_ [integer!]
	 trailing [integer!] return: [integer!] ] pango-lib "pango_glyph_string_x_to_index" 

	{ Turn a string of characters into a string of glyphs
	}

	pango_shape: make routine! [ text [integer!]
	 length [gint]
	 analysis [integer!]
	 glyphs [integer!] return: [integer!] ] pango-lib "pango_shape" 

	if pango_this_version >= 13200 [
	pango_shape_full: make routine! [ item_text [integer!]
	 item_length [gint]
	 paragraph_text [integer!]
	 paragraph_length [gint]
	 analysis [integer!]
	 glyphs [integer!] return: [integer!] ] pango-lib "pango_shape_full" 
	]
	pango_reorder_items: make routine! [ logical_items [integer!] return: [integer!] ] pango-lib "pango_reorder_items" 

{ pango-gravity.h }
	{ Pango
	 * pango-gravity.h: Gravity routines
	 *
	 * Copyright (C) 2006, 2007 Red Hat Software
	 *

	 }

	{*
	 * PangoGravity:
	 * @PANGO_GRAVITY_SOUTH: Glyphs stand upright (default)
	 * @PANGO_GRAVITY_EAST: Glyphs are rotated 90 degrees clockwise
	 * @PANGO_GRAVITY_NORTH: Glyphs are upside-down
	 * @PANGO_GRAVITY_WEST: Glyphs are rotated 90 degrees counter-clockwise
	 * @PANGO_GRAVITY_AUTO: Gravity is resolved from the context matrix
	 *
	 * The #PangoGravity type represents the orientation of glyphs in a segment
	 * of text.  This is useful when rendering vertical text layouts.  In
	 * those situations, the layout is rotated using a non-identity PangoMatrix,
	 * and then glyph orientation is controlled using #PangoGravity.
	 * Not every value in this enumeration makes sense for every usage of
	 * #PangoGravity; for example, %PANGO_GRAVITY_AUTO only can be passed to
	 * pango_context_set_base_gravity() and can only be returned by
	 * pango_context_get_base_gravity().
	 *
	 * See also: #PangoGravityHint
	 *
	 * Since: 1.16
	 *}

	PANGO_GRAVITY_SOUTH: 0
	PANGO_GRAVITY_EAST: 1
	PANGO_GRAVITY_NORTH: 2
	PANGO_GRAVITY_WEST: 3
	PANGO_GRAVITY_AUTO: 4

	PangoGravity: integer!;

	{*
	 * PangoGravityHint:
	 * @PANGO_GRAVITY_HINT_NATURAL: scripts will take their natural gravity based
	 * on the base gravity and the script.  This is the default.
	 * @PANGO_GRAVITY_HINT_STRONG: always use the base gravity set, regardless of
	 * the script.
	 * @PANGO_GRAVITY_HINT_LINE: for scripts not in their natural direction (eg.
	 * Latin in East gravity), choose per-script gravity such that every script
	 * respects the line progression.  This means, Latin and Arabic will take
	 * opposite gravities and both flow top-to-bottom for example.
	 *
	 * The #PangoGravityHint defines how horizontal scripts should behave in a
	 * vertical context.  That is, English excerpt in a vertical paragraph for
	 * example.
	 *
	 * See #PangoGravity.
	 *
	 * Since: 1.16
	 *}

	PANGO_GRAVITY_HINT_NATURAL: 0
	PANGO_GRAVITY_HINT_STRONG: 1
	PANGO_GRAVITY_HINT_LINE: 2

	PangoGravityHint: integer!;

	{*
	 * PANGO_GRAVITY_IS_VERTICAL:
	 * @gravity: the #PangoGravity to check
	 *
	 * Whether a #PangoGravity represents vertical writing directions.
	 *
	 * Returns: %TRUE if @gravity is %PANGO_GRAVITY_EAST or %PANGO_GRAVITY_WEST,
	 *          %FALSE otherwise.
	 *
	 * Since: 1.16
	 *}
	PANGO_GRAVITY_IS_VERTICAL: func [gravity][
		any [gravity = PANGO_GRAVITY_EAST gravity = PANGO_GRAVITY_WEST]
	]
	{*
	 * PANGO_GRAVITY_IS_IMPROPER:
	 * @gravity: the #PangoGravity to check
	 *
	 * Whether a #PangoGravity represents a gravity that results in reversal of text direction.
	 *
	 * Returns: %TRUE if @gravity is %PANGO_GRAVITY_WEST or %PANGO_GRAVITY_NORTH,
	 *          %FALSE otherwise.
	 *
	 * Since: 1.32
	 *}
	PANGO_GRAVITY_IS_IMPROPER: func [gravity][
		any [gravity = PANGO_GRAVITY_NORTH gravity = PANGO_GRAVITY_WEST]
	]

	pango_gravity_to_rotation: make routine! [ gravity [PangoGravity] return: [double] ] pango-lib "pango_gravity_to_rotation" 
	pango_gravity_get_for_matrix: make routine! [ matrix [integer!] return: [PangoGravity] ] pango-lib "pango_gravity_get_for_matrix" 
	pango_gravity_get_for_script: make routine! [ script [PangoScript] base_gravity [PangoGravity] hint [PangoGravityHint] return: [PangoGravity] ] pango-lib "pango_gravity_get_for_script" 
	pango_gravity_get_for_script_and_width: make routine! [
	 script [PangoScript]
	 wide [gboolean]
	 base_gravity [PangoGravity]
	 hint [PangoGravityHint] return: [PangoGravity] ] pango-lib "pango_gravity_get_for_script_and_width" 

{ pango-item.h }
	{ Pango
	 * pango-item.h: Structure for storing run information
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{*
	 * PANGO_ANALYSIS_FLAG_CENTERED_BASELINE:
	 *
	 * Whether the segment should be shifted to center around the baseline.
	 * Used in vertical writing directions mostly.
	 *
	 * Since: 1.16
	 }
	PANGO_ANALYSIS_FLAG_CENTERED_BASELINE: 1 ; (1 << 0)

	{*
	 * PANGO_ANALYSIS_FLAG_IS_ELLIPSIS:
	 *
	 * This flag is used to mark runs that hold ellipsized text,
	 * in an ellipsized layout.
	 *
	 * Since: 1.36.7
	 }
	PANGO_ANALYSIS_FLAG_IS_ELLIPSIS: 2 ; (1 << 1)

	{*
	 * PangoAnalysis:
	 * @shape_engine: the engine for doing rendering-system-dependent processing.
	 * @lang_engine: the engine for doing rendering-system-independent processing.
	 * @font: the font for this segment.
	 * @level: the bidirectional level for this segment.
	 * @gravity: the glyph orientation for this segment (A #PangoGravity).
	 * @flags: boolean flags for this segment (currently only one) (Since: 1.16).
	 * @script: the detected script for this segment (A #PangoScript) (Since: 1.18).
	 * @language: the detected language for this segment.
	 * @extra_attrs: extra attributes for this segment.
	 *
	 * The #PangoAnalysis structure stores information about
	 * the properties of a segment of text.
	 }
	_PangoAnalysis: make struct! [

	  shape_engine [integer!]
	  lang_engine [integer!]
	  font [integer!]

	  level [guint8]
	  gravity [guint8] { PangoGravity }
	  flags [guint8]

	  script [guint8] { PangoScript }
	  language [integer!]

	  extra_attrs [integer!]
	] none ;

	{*
	 * PangoItem:
	 * @offset: byte offset of the start of this item in text.
	 * @length: length of this item in bytes.
	 * @num_chars: number of Unicode characters in the item.
	 * @analysis: analysis results for the item.
	 *
	 * The #PangoItem structure stores information about a segment of text.
	 }
	_PangoItem: make struct! [
		offset [gint]
		length [gint]
		num_chars [gint]
		analysis [PangoAnalysis]
	] none ;

	pango_item_get_type: make routine! [ return: [GType] ] pango-lib "pango_item_get_type" 
	pango_item_new: make routine! [ return: [integer!] ] pango-lib "pango_item_new" 
	pango_item_copy: make routine! [ item [integer!] return: [integer!] ] pango-lib "pango_item_copy" 
	pango_item_free: make routine! [ item [integer!] return: [integer!] ] pango-lib "pango_item_free" 
	pango_item_split: make routine! [ orig [integer!] split_index [integer!] split_offset [integer!] return: [integer!] ] pango-lib "pango_item_split" 

{ pango-language.h }
	{ Pango
	 * pango-language.h: Language handling routines
	 *
	 * Copyright (C) 1999 Red Hat Software
	 *

	 }

	{*
	 * PANGO_TYPE_LANGUAGE:
	 *
	 * The #GObject type for #PangoLanguage.
	 }

	pango_language_get_type: make routine! [ return: [GType] ] pango-lib "pango_language_get_type" 
	pango_language_from_string: make routine! [ language [string!] return: [integer!] ] pango-lib "pango_language_from_string" 
	pango_language_to_string: make routine! [ language [integer!] return: [string!] ] pango-lib "pango_language_to_string" 

	pango_language_get_sample_string: make routine! [ language [integer!] return: [string!] ] pango-lib "pango_language_get_sample_string" 
	pango_language_get_default: make routine! [ return: [integer!] ] pango-lib "pango_language_get_default" 
	pango_language_matches: make routine! [ language [integer!] range_list [string!] return: [gboolean] ] pango-lib "pango_language_matches" 
	pango_language_includes_script: make routine! [ language [integer!] script [PangoScript] return: [gboolean] ] pango-lib "pango_language_includes_script" 
	pango_language_get_scripts: make routine! [ language [integer!] num_scripts [integer!] return: [integer!] ] pango-lib "pango_language_get_scripts" 
;
{ pango-layout.h }
	{ Pango
	 * pango-layout.h: High-level layout driver
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{*
	 * PangoLayoutRun:
	 *
	 * The #PangoLayoutRun structure represents a single run within
	 * a #PangoLayoutLine; it is simply an alternate name for
	 * #PangoGlyphItem.
	 * See the #PangoGlyphItem docs for details on the fields.
	 }

	{*
	 * PangoAlignment:
	 * @PANGO_ALIGN_LEFT: Put all available space on the right
	 * @PANGO_ALIGN_CENTER: Center the line within the available space
	 * @PANGO_ALIGN_RIGHT: Put all available space on the left
	 *
	 * A #PangoAlignment describes how to align the lines of a #PangoLayout within the
	 * available space. If the #PangoLayout is set to justify
	 * using pango_layout_set_justify(), this only has effect for partial lines.
	 }

	PANGO_ALIGN_LEFT: 0
	PANGO_ALIGN_CENTER: 1
	PANGO_ALIGN_RIGHT: 2

	PangoAlignment: integer!;

	{*
	 * PangoWrapMode:
	 * @PANGO_WRAP_WORD: wrap lines at word boundaries.
	 * @PANGO_WRAP_CHAR: wrap lines at character boundaries.
	 * @PANGO_WRAP_WORD_CHAR: wrap lines at word boundaries, but fall back to character boundaries if there is not
	 * enough space for a full word.
	 *
	 * A #PangoWrapMode describes how to wrap the lines of a #PangoLayout to the desired width.
	 }

	PANGO_WRAP_WORD: 0
	PANGO_WRAP_CHAR: 1
	PANGO_WRAP_WORD_CHAR: 2

	PangoWrapMode: integer!;

	{*
	 * PangoEllipsizeMode:
	 * @PANGO_ELLIPSIZE_NONE: No ellipsization
	 * @PANGO_ELLIPSIZE_START: Omit characters at the start of the text
	 * @PANGO_ELLIPSIZE_MIDDLE: Omit characters in the middle of the text
	 * @PANGO_ELLIPSIZE_END: Omit characters at the end of the text
	 *
	 * The #PangoEllipsizeMode type describes what sort of (if any)
	 * ellipsization should be applied to a line of text. In
	 * the ellipsization process characters are removed from the
	 * text in order to make it fit to a given width and replaced
	 * with an ellipsis.
	 }

	PANGO_ELLIPSIZE_NONE: 0
	PANGO_ELLIPSIZE_START: 1
	PANGO_ELLIPSIZE_MIDDLE: 2
	PANGO_ELLIPSIZE_END: 3

	PangoEllipsizeMode: integer!;

	{*
	 * PangoLayoutLine:
	 * @layout: (allow-none): the layout this line belongs to, might be %NULL
	 * @start_index: start of line as byte index into layout->text
	 * @length: length of line in bytes
	 * @runs: (allow-none) (element-type Pango.LayoutRun): list of runs in the
	 *        line, from left to right
	 * @is_paragraph_start: #TRUE if this is the first line of the paragraph
	 * @resolved_dir: #Resolved PangoDirection of line
	 *
	 * The #PangoLayoutLine structure represents one of the lines resulting
	 * from laying out a paragraph via #PangoLayout. #PangoLayoutLine
	 * structures are obtained by calling pango_layout_get_line() and
	 * are only valid until the text, attributes, or settings of the
	 * parent #PangoLayout are modified.
	 *
	 * Routines for rendering PangoLayout objects are provided in
	 * code specific to each rendering system.
	 }
	_PangoLayoutLine: make struct! [
		layout [integer!]
		start_index [gint] { start of line as byte index into layout->text }
		length [gint] { length of line in bytes }
		runs [integer!]
		is_paragraph_start [guint]{: 1} { TRUE if this is the first line of the paragraph }
		resolved_dir [guint] {: 3} { Resolved PangoDirection of line }
	] none ;

	pango_layout_get_type: make routine! [ return: [GType] ] pango-lib "pango_layout_get_type" 
	pango_layout_new: make routine! [ context [integer!] return: [integer!] ] pango-lib "pango_layout_new" 
	pango_layout_copy: make routine! [ src [integer!] return: [integer!] ] pango-lib "pango_layout_copy" 
	pango_layout_get_context: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_context" 
	pango_layout_set_attributes: make routine! [ layout [integer!] attrs [integer!] return: [integer!] ] pango-lib "pango_layout_set_attributes" 
	pango_layout_get_attributes: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_attributes" 
	pango_layout_set_text: make routine! [ layout [integer!] text [string!] length [integer!] return: [integer!] ] pango-lib "pango_layout_set_text" 
	pango_layout_get_text: make routine! [ layout [integer!] return: [string!] ] pango-lib "pango_layout_get_text" 
	pango_layout_get_character_count: make routine! [ layout [integer!] return: [gint] ] pango-lib "pango_layout_get_character_count" 
	pango_layout_set_markup: make routine! [ layout [integer!] markup [string!] length [integer!] return: [integer!] ] pango-lib "pango_layout_set_markup" 
	pango_layout_set_markup_with_accel: make routine! [ layout [integer!]
	 markup [string!]
	 length [integer!]
	 accel_marker [gunichar]
	 accel_char [integer!] return: [integer!] ] pango-lib "pango_layout_set_markup_with_accel" 

	pango_layout_set_font_description: make routine! [ layout [integer!] desc [integer!] return: [integer!] ] pango-lib "pango_layout_set_font_description" 
	pango_layout_get_font_description: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_font_description" 
	pango_layout_set_width: make routine! [ layout [integer!] width [integer!] return: [integer!] ] pango-lib "pango_layout_set_width" 
	pango_layout_get_width: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_width" 
	pango_layout_set_height: make routine! [ layout [integer!] height [integer!] return: [integer!] ] pango-lib "pango_layout_set_height" 
	pango_layout_get_height: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_height" 
	pango_layout_set_wrap: make routine! [ layout [integer!] wrap [PangoWrapMode] return: [integer!] ] pango-lib "pango_layout_set_wrap" 
	pango_layout_get_wrap: make routine! [ layout [integer!] return: [PangoWrapMode] ] pango-lib "pango_layout_get_wrap" 
	pango_layout_is_wrapped: make routine! [ layout [integer!] return: [gboolean] ] pango-lib "pango_layout_is_wrapped" 
	pango_layout_set_indent: make routine! [ layout [integer!] indent [integer!] return: [integer!] ] pango-lib "pango_layout_set_indent" 
	pango_layout_get_indent: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_indent" 
	pango_layout_set_spacing: make routine! [ layout [integer!] spacing [integer!] return: [integer!] ] pango-lib "pango_layout_set_spacing" 
	pango_layout_get_spacing: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_spacing" 
	pango_layout_set_justify: make routine! [ layout [integer!] justify [gboolean] return: [integer!] ] pango-lib "pango_layout_set_justify" 
	pango_layout_get_justify: make routine! [ layout [integer!] return: [gboolean] ] pango-lib "pango_layout_get_justify" 
	pango_layout_set_auto_dir: make routine! [ layout [integer!] auto_dir [gboolean] return: [integer!] ] pango-lib "pango_layout_set_auto_dir" 
	pango_layout_get_auto_dir: make routine! [ layout [integer!] return: [gboolean] ] pango-lib "pango_layout_get_auto_dir" 
	pango_layout_set_alignment: make routine! [ layout [integer!] alignment [PangoAlignment] return: [integer!] ] pango-lib "pango_layout_set_alignment" 
	pango_layout_get_alignment: make routine! [ layout [integer!] return: [PangoAlignment] ] pango-lib "pango_layout_get_alignment" 
	pango_layout_set_tabs: make routine! [ layout [integer!] tabs [integer!] return: [integer!] ] pango-lib "pango_layout_set_tabs" 
	pango_layout_get_tabs: make routine! [ layout [integer!] return: [integer|] ] pango-lib "pango_layout_get_tabs" 
	pango_layout_set_single_paragraph_mode: make routine! [ layout [integer!] setting [gboolean] return: [integer!] ] pango-lib "pango_layout_set_single_paragraph_mode" 
	pango_layout_get_single_paragraph_mode: make routine! [ layout [integer!] return: [gboolean] ] pango-lib "pango_layout_get_single_paragraph_mode" 
	pango_layout_set_ellipsize: make routine! [ layout [integer!] ellipsize [PangoEllipsizeMode] return: [integer!] ] pango-lib "pango_layout_set_ellipsize" 
	pango_layout_get_ellipsize: make routine! [ layout [integer!] return: [PangoEllipsizeMode] ] pango-lib "pango_layout_get_ellipsize" 
	pango_layout_is_ellipsized: make routine! [ layout [integer!] return: [gboolean] ] pango-lib "pango_layout_is_ellipsized" 
	pango_layout_get_unknown_glyphs_count: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_unknown_glyphs_count" 
	pango_layout_context_changed: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_context_changed" 
	if pango_this_version >= 13200 [
	pango_layout_get_serial: make routine! [ layout [integer!] return: [guint] ] pango-lib "pango_layout_get_serial" 
	]
	pango_layout_get_log_attrs: make routine! [ layout [integer!] attrs [struct! []] n_attrs [integer!] return: [integer!] ] pango-lib "pango_layout_get_log_attrs" 
	if pango_this_version >= 13000 [
	pango_layout_get_log_attrs_readonly: make routine! [ layout [integer!] n_attrs [integer!] return: [integer!] ] pango-lib "pango_layout_get_log_attrs_readonly" 
	]
	pango_layout_index_to_pos: make routine! [ layout [integer!] index_ [integer!] pos [integer!] return: [integer!] ] pango-lib "pango_layout_index_to_pos" 
	pango_layout_index_to_line_x: make routine! [ layout [integer!]
	 index_ [integer!]
	 trailing [gboolean]
	 line [integer!]
	 x_pos [integer!] return: [integer!] ] pango-lib "pango_layout_index_to_line_x" 

	pango_layout_get_cursor_pos: make routine! [ layout [integer!]
	 index_ [integer!]
	 strong_pos [integer!]
	 weak_pos [integer!] return: [integer!] ] pango-lib "pango_layout_get_cursor_pos" 

	pango_layout_move_cursor_visually: make routine! [ layout [integer!]
	 strong [gboolean]
	 old_index [integer!]
	 old_trailing [integer!]
	 direction [integer!]
	 new_index [integer!]
	 new_trailing [integer!] return: [integer!] ] pango-lib "pango_layout_move_cursor_visually" 

	pango_layout_xy_to_index: make routine! [ layout [integer!]
	 x [integer!]
	 y [integer!]
	 index_ [integer!]
	 trailing [integer!] return: [gboolean] ] pango-lib "pango_layout_xy_to_index" 

	pango_layout_get_extents: make routine! [ layout [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_get_extents" 
	pango_layout_get_pixel_extents: make routine! [ layout [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_get_pixel_extents" 
	pango_layout_get_size: make routine! [ layout [integer!] width [integer!] height [integer!] return: [integer!] ] pango-lib "pango_layout_get_size" 
	pango_layout_get_pixel_size: make routine! [ layout [integer!] width [struct![]] height [struct![]] return: [integer!] ] pango-lib "pango_layout_get_pixel_size" 
	pango_layout_get_baseline: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_baseline" 
	pango_layout_get_line_count: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_line_count" 
	pango_layout_get_line: make routine! [ layout [integer!] line [integer!] return: [integer!] ] pango-lib "pango_layout_get_line" 
	pango_layout_get_line_readonly: make routine! [ layout [integer!] line [integer!] return: [integer!] ] pango-lib "pango_layout_get_line_readonly" 
	pango_layout_get_lines: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_lines" 
	pango_layout_get_lines_readonly: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_lines_readonly" 

	pango_layout_line_get_type: make routine! [ return: [GType] ] pango-lib "pango_layout_line_get_type" 
	pango_layout_line_ref: make routine! [ line [integer!] return: [integer!] ] pango-lib "pango_layout_line_ref" 
	pango_layout_line_unref: make routine! [ line [integer!] return: [integer!] ] pango-lib "pango_layout_line_unref" 
	pango_layout_line_x_to_index: make routine! [ line [integer!]
	 x_pos [integer!]
	 index_ [integer!]
	 trailing [integer!] return: [gboolean] ] pango-lib "pango_layout_line_x_to_index" 

	pango_layout_line_index_to_x: make routine! [ line [integer!]
	 index_ [integer!]
	 trailing [gboolean]
	 x_pos [integer!] return: [integer!] ] pango-lib "pango_layout_line_index_to_x" 

	pango_layout_line_get_x_ranges: make routine! [ line [integer!]
	 start_index [integer!]
	 end_index [integer!]
	 ranges [struct! []]
	 n_ranges [integer!] return: [integer!] ] pango-lib "pango_layout_line_get_x_ranges" 

	pango_layout_line_get_extents: make routine! [ line [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_line_get_extents" 
	pango_layout_line_get_pixel_extents: make routine! [ layout_line [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_line_get_pixel_extents" 

	pango_layout_iter_get_type: make routine! [ return: [GType] ] pango-lib "pango_layout_iter_get_type" 
	pango_layout_get_iter: make routine! [ layout [integer!] return: [integer!] ] pango-lib "pango_layout_get_iter" 
	pango_layout_iter_copy: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_copy" 
	pango_layout_iter_free: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_free" 
	pango_layout_iter_get_index: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_index" 
	pango_layout_iter_get_run: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_run" 
	pango_layout_iter_get_run_readonly: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_run_readonly" 
	pango_layout_iter_get_line: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_line" 
	pango_layout_iter_get_line_readonly: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_line_readonly" 
	pango_layout_iter_at_last_line: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_layout_iter_at_last_line" 
	pango_layout_iter_get_layout: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_layout" 
	pango_layout_iter_next_char: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_layout_iter_next_char" 
	pango_layout_iter_next_cluster: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_layout_iter_next_cluster" 
	pango_layout_iter_next_run: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_layout_iter_next_run" 
	pango_layout_iter_next_line: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_layout_iter_next_line" 
	pango_layout_iter_get_char_extents: make routine! [ iter [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_char_extents" 
	pango_layout_iter_get_cluster_extents: make routine! [ iter [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_cluster_extents" 
	pango_layout_iter_get_run_extents: make routine! [ iter [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_run_extents" 
	pango_layout_iter_get_line_extents: make routine! [ iter [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_line_extents" 

	{ All the yranges meet, unlike the logical_rect's (i.e. the yranges
	 * assign between-line spacing to the nearest line)
	 }
	pango_layout_iter_get_line_yrange: make routine! [ iter [integer!] y0_ [integer!] y1_ [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_line_yrange" 
	pango_layout_iter_get_layout_extents: make routine! [ iter [integer!] ink_rect [integer!] logical_rect [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_layout_extents" 
	pango_layout_iter_get_baseline: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_layout_iter_get_baseline" 
;
{ pango-matrix.h }
	{ Pango
	 * pango-matrix.h: Matrix manipulation routines
	 *
	 * Copyright (C) 2002, 2006 Red Hat Software
	 *

	 }

	{*
	 * PangoMatrix:
	 * @xx: 1st component of the transformation matrix
	 * @xy: 2nd component of the transformation matrix
	 * @yx: 3rd component of the transformation matrix
	 * @yy: 4th component of the transformation matrix
	 * @x0: x translation
	 * @y0: y translation
	 *
	 * A structure specifying a transformation between user-space
	 * coordinates and device coordinates. The transformation
	 * is given by
	 *
	 * <programlisting>
	 * x_device = x_user * matrix->xx + y_user * matrix->xy + matrix->x0;
	 * y_device = x_user * matrix->yx + y_user * matrix->yy + matrix->y0;
	 * </programlisting>
	 *
	 * Since: 1.6
	 *}
	_PangoMatrix: make struct! [
		xx [double]
		xy [double]
		yx [double]
		yy [double]
		x0 [double]
		y0 [double]
	] none ;

	{*
	 * PANGO_MATRIX_INIT:
	 *
	 * Constant that can be used to initialize a PangoMatrix to
	 * the identity transform.
	 *
	 * <informalexample><programlisting>
	 * PangoMatrix matrix = PANGO_MATRIX_INIT;
	 * pango_matrix_rotate (&amp;matrix, 45.);
	 * </programlisting></informalexample>
	 *
	 * Since: 1.6
	 *}
	;#define PANGO_MATRIX_INIT { 1., 0., 0., 1., 0., 0. }

	{ for PangoRectangle }

	pango_matrix_get_type: make routine! [ return: [GType] ] pango-lib "pango_matrix_get_type" 
	pango_matrix_copy: make routine! [ matrix [integer!] return: [integer!] ] pango-lib "pango_matrix_copy" 
	pango_matrix_free: make routine! [ matrix [integer!] return: [integer!] ] pango-lib "pango_matrix_free" 
	pango_matrix_translate: make routine! [ matrix [integer!] tx [double] ty [double] return: [integer!] ] pango-lib "pango_matrix_translate" 
	pango_matrix_scale: make routine! [ matrix [integer!] scale_x [double] scale_y [double] return: [integer!] ] pango-lib "pango_matrix_scale" 
	pango_matrix_rotate: make routine! [ matrix [integer!] degrees [double] return: [integer!] ] pango-lib "pango_matrix_rotate" 
	pango_matrix_concat: make routine! [ matrix [integer!] new_matrix [integer!] return: [integer!] ] pango-lib "pango_matrix_concat" 
	pango_matrix_transform_point: make routine! [ matrix [integer!] x [integer!] y [integer!] return: [integer!] ] pango-lib "pango_matrix_transform_point" 
	pango_matrix_transform_distance: make routine! [ matrix [integer!] dx [integer!] dy [integer!] return: [integer!] ] pango-lib "pango_matrix_transform_distance" 
	pango_matrix_transform_rectangle: make routine! [ matrix [integer!] rect [integer!] return: [integer!] ] pango-lib "pango_matrix_transform_rectangle" 
	pango_matrix_transform_pixel_rectangle: make routine! [ matrix [integer!] rect [integer!] return: [integer!] ] pango-lib "pango_matrix_transform_pixel_rectangle" 
	pango_matrix_get_font_scale_factor: make routine! [ matrix [integer!] return: [double] ] pango-lib "pango_matrix_get_font_scale_factor" 
	if pango_this_version >= 13800 [
	pango_matrix_get_font_scale_factors: make routine! [ matrix [integer!] xscale [integer!] yscale [integer!] return: [integer!] ] pango-lib "pango_matrix_get_font_scale_factors" 
	]

{ pango-ot.h }
	{ Pango
	 * pango-ot.h:
	 *
	 * Copyright (C) 2000,2007 Red Hat Software
	 *

	 }

	{ Deprecated.  Use HarfBuzz directly! }

	{*
	 * PangoOTTag:
	 *
	 * The #PangoOTTag typedef is used to represent TrueType and OpenType
	 * four letter tags inside Pango. Use PANGO_OT_TAG_MAKE()
	 * or PANGO_OT_TAG_MAKE_FROM_STRING() macros to create <type>PangoOTTag</type>s manually.
	 }

	{*
	 * PANGO_OT_TAG_MAKE_FROM_STRING:
	 * @s: The string representation of the tag.
	 *
	 * Creates a #PangoOTTag from a string. The string should be at least
	 * four characters long (pad with space characters if needed), and need
	 * not be nul-terminated.  This is a convenience wrapper around
	 * PANGO_OT_TAG_MAKE(), but cannot be used in certain situations, for
	 * example, as a switch expression, as it dereferences pointers.
	 }
	{
	#define PANGO_OT_TAG_MAKE(c1,c2,c3,c4)		((PangoOTTag) FT_MAKE_TAG (c1, c2, c3, c4))
	#define PANGO_OT_TAG_MAKE_FROM_STRING(s)	(PANGO_OT_TAG_MAKE(((const char *) s)[0], \
									   ((const char *) s)[1], \
									   ((const char *) s)[2], \
									   ((const char *) s)[3]))

	}
	{*
	 * PangoOTTableType:
	 * @PANGO_OT_TABLE_GSUB: The GSUB table.
	 * @PANGO_OT_TABLE_GPOS: The GPOS table.
	 *
	 * The <type>PangoOTTableType</type> enumeration values are used to
	 * identify the various OpenType tables in the
	 * <function>pango_ot_info_*</function> functions.
	 }

	PANGO_OT_TABLE_GSUB: 0
	PANGO_OT_TABLE_GPOS: 1

	PangoOTTableType: integer!;

	{*
	 * PANGO_OT_ALL_GLYPHS:
	 *
	 * This is used as the property bit in pango_ot_ruleset_add_feature() when a
	 * feature should be applied to all glyphs.
	 *
	 * Since: 1.16
	 }
	{*
	 * PANGO_OT_NO_FEATURE:
	 *
	 * This is used as a feature index that represent no feature, that is, should be
	 * skipped.  It may be returned as feature index by pango_ot_info_find_feature()
	 * if the feature is not found, and pango_ot_ruleset_add_feature() function
	 * automatically skips this value, so no special handling is required by the user.
	 *
	 * Since: 1.18
	 }
	{*
	 * PANGO_OT_NO_SCRIPT:
	 *
	 * This is used as a script index that represent no script, that is, when the
	 * requested script was not found, and a default ('DFLT') script was not found
	 * either.  It may be returned as script index by pango_ot_info_find_script()
	 * if the script or a default script are not found, all other functions
	 * taking a script index essentially return if the input script index is
	 * this value, so no special handling is required by the user.
	 *
	 * Since: 1.18
	 }
	{*
	 * PANGO_OT_DEFAULT_LANGUAGE:
	 *
	 * This is used as the language index in pango_ot_info_find_feature() when
	 * the default language system of the script is desired.
	 *
	 * It is also returned by pango_ot_info_find_language() if the requested language
	 * is not found, or the requested language tag was PANGO_OT_TAG_DEFAULT_LANGUAGE.
	 * The end result is that one can always call pango_ot_tag_from_language()
	 * followed by pango_ot_info_find_language() and pass the result to
	 * pango_ot_info_find_feature() without having to worry about falling back to
	 * default language system explicitly.
	 *
	 * Since: 1.16
	 }
	PANGO_OT_ALL_GLYPHS:			    65535 
	PANGO_OT_NO_FEATURE:			    65535 
	PANGO_OT_NO_SCRIPT:			    65535 
	PANGO_OT_DEFAULT_LANGUAGE:		    65535 

	{*
	 * PANGO_OT_TAG_DEFAULT_SCRIPT:
	 *
	 * This is a #PangoOTTag representing the special script tag 'DFLT'.  It is
	 * returned as script tag by pango_ot_tag_from_script() if the requested script
	 * is not found.
	 *
	 * Since: 1.18
	 }
	{*
	 * PANGO_OT_TAG_DEFAULT_LANGUAGE:
	 *
	 * This is a #PangoOTTag representing a special language tag 'dflt'.  It is
	 * returned as language tag by pango_ot_tag_from_language() if the requested
	 * language is not found.  It is safe to pass this value to
	 * pango_ot_info_find_language() as that function falls back to returning default
	 * language-system if the requested language tag is not found.
	 *
	 * Since: 1.18
	 }
	;#define PANGO_OT_TAG_DEFAULT_SCRIPT		PANGO_OT_TAG_MAKE ('D', 'F', 'L', 'T')
	;#define PANGO_OT_TAG_DEFAULT_LANGUAGE		PANGO_OT_TAG_MAKE ('d', 'f', 'l', 't')

	{ Note that this must match hb_glyph_info_t }
	{*
	 * PangoOTGlyph:
	 * @glyph: the glyph itself.
	 * @properties: the properties value, identifying which features should be
	 * applied on this glyph.  See pango_ot_ruleset_add_feature().
	 * @cluster: the cluster that this glyph belongs to.
	 * @component: a component value, set by the OpenType layout engine.
	 * @ligID: a ligature index value, set by the OpenType layout engine.
	 * @internal: for Pango internal use
	 *
	 * The #PangoOTGlyph structure represents a single glyph together with
	 * information used for OpenType layout processing of the glyph.
	 * It contains the following fields.
	 }
	_PangoOTGlyph: make struct! [
		glyph [guint32]
		properties [guint]
		cluster [guint]
		component [gushort]
		ligID [gushort]
		internal [guint]
	] none ;

	{*
	 * PangoOTFeatureMap:
	 * @feature_name: feature tag in represented as four-letter ASCII string.
	 * @property_bit: the property bit to use for this feature.  See
	 * pango_ot_ruleset_add_feature() for details.
	 *
	 * The #PangoOTFeatureMap typedef is used to represent an OpenType
	 * feature with the property bit associated with it.  The feature tag is
	 * represented as a char array instead of a #PangoOTTag for convenience.
	 *
	 * Since: 1.18
	 }
	_PangoOTFeatureMap: make struct! [
		feature_name [char!] ;[5];
		_2 [char!]
		_3 [char!]
		_4 [char!]
		_5 [char!]
		property_bit [gulong]
	] none ;

	{*
	 * PangoOTRulesetDescription:
	 * @script: a #PangoScript.
	 * @language: a #PangoLanguage.
	 * @static_gsub_features: (nullable): static map of GSUB features,
	 * or %NULL.
	 * @n_static_gsub_features: length of @static_gsub_features, or 0.
	 * @static_gpos_features: (nullable): static map of GPOS features,
	 * or %NULL.
	 * @n_static_gpos_features: length of @static_gpos_features, or 0.
	 * @other_features: (nullable): map of extra features to add to both
	 * GSUB and GPOS, or %NULL.  Unlike the static maps, this pointer
	 * need not live beyond the life of function calls taking this
	 * struct.
	 * @n_other_features: length of @other_features, or 0.
	 *
	 * The #PangoOTRuleset structure holds all the information needed
	 * to build a complete #PangoOTRuleset from an OpenType font.
	 * The main use of this struct is to act as the key for a per-font
	 * hash of rulesets.  The user populates a ruleset description and
	 * gets the ruleset using pango_ot_ruleset_get_for_description()
	 * or create a new one using pango_ot_ruleset_new_from_description().
	 *
	 * Since: 1.18
	 }
	_PangoOTRulesetDescription: make struct! [
		script [PangoScript]
		language [integer!]
		static_gsub_features [integer!]
		n_static_gsub_features [guint]
		static_gpos_features [integer!]
		n_static_gpos_features [guint]
		other_features [integer!]
		n_other_features [guint]
	] none ;

{ pango-renderer.h }
	{ Pango
	 * pango-renderer.h: Base class for rendering
	 *
	 * Copyright (C) 2004, Red Hat, Inc.
	 *

	 }
	{*
	 * PangoRenderPart:
	 * @PANGO_RENDER_PART_FOREGROUND: the text itself
	 * @PANGO_RENDER_PART_BACKGROUND: the area behind the text
	 * @PANGO_RENDER_PART_UNDERLINE: underlines
	 * @PANGO_RENDER_PART_STRIKETHROUGH: strikethrough lines
	 *
	 * #PangoRenderPart defines different items to render for such
	 * purposes as setting colors.
	 *
	 * Since: 1.8
	 *}
	{ When extending, note N_RENDER_PARTS #define in pango-renderer.c }

	PANGO_RENDER_PART_FOREGROUND: 0
	PANGO_RENDER_PART_BACKGROUND: 1
	PANGO_RENDER_PART_UNDERLINE: 2
	PANGO_RENDER_PART_STRIKETHROUGH: 3

	PangoRenderPart: integer!;

	{*
	 * PangoRenderer:
	 * @matrix: (nullable): the current transformation matrix for
	 *    the Renderer; may be %NULL, which should be treated the
	 *    same as the identity matrix.
	 *
	 * #PangoRenderer is a base class for objects that are used to
	 * render Pango objects such as #PangoGlyphString and
	 * #PangoLayout.
	 *
	 * Since: 1.8
	 *}
	_PangoRenderer: make struct! [

		{< private >}
		parent_instance [GObject]

		underline [PangoUnderline]
		strikethrough [gboolean]
		active_count [integer!]

		{< public >}
		matrix [integer!] { May be NULL }

		{< private >}
		priv [integer!]
	] none ;

	{*
	 * PangoRendererClass:
	 * @draw_glyphs: draws a #PangoGlyphString
	 * @draw_rectangle: draws a rectangle
	 * @draw_error_underline: draws a squiggly line that approximately
	 * covers the given rectangle in the style of an underline used to
	 * indicate a spelling error.
	 * @draw_shape: draw content for a glyph shaped with #PangoAttrShape.
	 *   @x, @y are the coordinates of the left edge of the baseline,
	 *   in user coordinates.
	 * @draw_trapezoid: draws a trapezoidal filled area
	 * @draw_glyph: draws a single glyph
	 * @part_changed: do renderer specific processing when rendering
	 *  attributes change
	 * @begin: Do renderer-specific initialization before drawing
	 * @end: Do renderer-specific cleanup after drawing
	 * @prepare_run: updates the renderer for a new run
	 * @draw_glyph_item: draws a #PangoGlyphItem
	 *
	 * Class structure for #PangoRenderer.
	 *
	 * Since: 1.8
	 *}

	pango_renderer_get_type: make routine! [ return: [GType] ] pango-lib "pango_renderer_get_type" 
	pango_renderer_draw_layout: make routine! [ renderer [integer!]
	 layout [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_renderer_draw_layout" 

	pango_renderer_draw_layout_line: make routine! [ renderer [integer!]
	 line [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_renderer_draw_layout_line" 

	pango_renderer_draw_glyphs: make routine! [ renderer [integer!]
	 font [integer!]
	 glyphs [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_renderer_draw_glyphs" 

	pango_renderer_draw_glyph_item: make routine! [ renderer [integer!]
	 text [string!]
	 glyph_item [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_renderer_draw_glyph_item" 

	pango_renderer_draw_rectangle: make routine! [ renderer [integer!]
	 part [PangoRenderPart]
	 x [integer!]
	 y [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] pango-lib "pango_renderer_draw_rectangle" 

	pango_renderer_draw_error_underline: make routine! [ renderer [integer!]
	 x [integer!]
	 y [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] pango-lib "pango_renderer_draw_error_underline" 

	pango_renderer_draw_trapezoid: make routine! [ renderer [integer!]
	 part [PangoRenderPart]
	 y1_ [double]
	 x11 [double]
	 x21 [double]
	 y2 [double]
	 x12 [double]
	 x22 [double] return: [integer!] ] pango-lib "pango_renderer_draw_trapezoid" 

	pango_renderer_draw_glyph: make routine! [ renderer [integer!]
	 font [integer!]
	 glyph [PangoGlyph]
	 x [double]
	 y [double] return: [integer!] ] pango-lib "pango_renderer_draw_glyph" 

	pango_renderer_activate: make routine! [ renderer [integer!] return: [integer!] ] pango-lib "pango_renderer_activate" 
	pango_renderer_deactivate: make routine! [ renderer [integer!] return: [integer!] ] pango-lib "pango_renderer_deactivate" 
	pango_renderer_part_changed: make routine! [ renderer [integer!] part [PangoRenderPart] return: [integer!] ] pango-lib "pango_renderer_part_changed" 
	pango_renderer_set_color: make routine! [ renderer [integer!] part [PangoRenderPart] color [integer!] return: [integer!] ] pango-lib "pango_renderer_set_color" 
	pango_renderer_get_color: make routine! [ renderer [integer!] part [PangoRenderPart] return: [integer!] ] pango-lib "pango_renderer_get_color" 
	if pango_this_version >= 13800 [
	pango_renderer_set_alpha: make routine! [ renderer [integer!] part [PangoRenderPart] alpha [guint16] return: [integer!] ] pango-lib "pango_renderer_set_alpha" 
	pango_renderer_get_alpha: make routine! [ renderer [integer!] part [PangoRenderPart] return: [guint16] ] pango-lib "pango_renderer_get_alpha" 
	]
	pango_renderer_set_matrix: make routine! [ renderer [integer!] matrix [integer!] return: [integer!] ] pango-lib "pango_renderer_set_matrix" 
	pango_renderer_get_matrix: make routine! [ renderer [integer!] return: [integer!] ] pango-lib "pango_renderer_get_matrix" 
	pango_renderer_get_layout: make routine! [ renderer [integer!] return: [integer!] ] pango-lib "pango_renderer_get_layout" 
	pango_renderer_get_layout_line: make routine! [ renderer [integer!] return: [integer!] ] pango-lib "pango_renderer_get_layout_line" 


{ pango-script.h }
	{ Pango
	 * pango-script.h: Script tag handling
	 *
	 * Copyright (C) 2002 Red Hat Software
	 *

	 }

	{*
	 * PangoScript:
	 * @PANGO_SCRIPT_INVALID_CODE: a value never returned from pango_script_for_unichar()
	 * @PANGO_SCRIPT_COMMON: a character used by multiple different scripts
	 * @PANGO_SCRIPT_INHERITED: a mark glyph that takes its script from the
	 * base glyph to which it is attached
	 * @PANGO_SCRIPT_ARABIC: 	Arabic
	 * @PANGO_SCRIPT_ARMENIAN: Armenian
	 * @PANGO_SCRIPT_BENGALI: 	Bengali
	 * @PANGO_SCRIPT_BOPOMOFO: Bopomofo
	 * @PANGO_SCRIPT_CHEROKEE: 	Cherokee
	 * @PANGO_SCRIPT_COPTIC: 	Coptic
	 * @PANGO_SCRIPT_CYRILLIC: 	Cyrillic
	 * @PANGO_SCRIPT_DESERET: 	Deseret
	 * @PANGO_SCRIPT_DEVANAGARI: 	Devanagari
	 * @PANGO_SCRIPT_ETHIOPIC: 	Ethiopic
	 * @PANGO_SCRIPT_GEORGIAN: 	Georgian
	 * @PANGO_SCRIPT_GOTHIC: 	Gothic
	 * @PANGO_SCRIPT_GREEK: 	Greek
	 * @PANGO_SCRIPT_GUJARATI: 	Gujarati
	 * @PANGO_SCRIPT_GURMUKHI: 	Gurmukhi
	 * @PANGO_SCRIPT_HAN: 	Han
	 * @PANGO_SCRIPT_HANGUL: 	Hangul
	 * @PANGO_SCRIPT_HEBREW: 	Hebrew
	 * @PANGO_SCRIPT_HIRAGANA: 	Hiragana
	 * @PANGO_SCRIPT_KANNADA: 	Kannada
	 * @PANGO_SCRIPT_KATAKANA: 	Katakana
	 * @PANGO_SCRIPT_KHMER: 	Khmer
	 * @PANGO_SCRIPT_LAO: 	Lao
	 * @PANGO_SCRIPT_LATIN: 	Latin
	 * @PANGO_SCRIPT_MALAYALAM: 	Malayalam
	 * @PANGO_SCRIPT_MONGOLIAN: 	Mongolian
	 * @PANGO_SCRIPT_MYANMAR: 	Myanmar
	 * @PANGO_SCRIPT_OGHAM: 	Ogham
	 * @PANGO_SCRIPT_OLD_ITALIC: 	Old Italic
	 * @PANGO_SCRIPT_ORIYA: 	Oriya
	 * @PANGO_SCRIPT_RUNIC: 	Runic
	 * @PANGO_SCRIPT_SINHALA: 	Sinhala
	 * @PANGO_SCRIPT_SYRIAC: 	Syriac
	 * @PANGO_SCRIPT_TAMIL: 	Tamil
	 * @PANGO_SCRIPT_TELUGU: 	Telugu
	 * @PANGO_SCRIPT_THAANA: 	Thaana
	 * @PANGO_SCRIPT_THAI: 	Thai
	 * @PANGO_SCRIPT_TIBETAN: 	Tibetan
	 * @PANGO_SCRIPT_CANADIAN_ABORIGINAL: 	Canadian Aboriginal
	 * @PANGO_SCRIPT_YI: 	Yi
	 * @PANGO_SCRIPT_TAGALOG: 	Tagalog
	 * @PANGO_SCRIPT_HANUNOO: 	Hanunoo
	 * @PANGO_SCRIPT_BUHID: 	Buhid
	 * @PANGO_SCRIPT_TAGBANWA: 	Tagbanwa
	 * @PANGO_SCRIPT_BRAILLE: 	Braille
	 * @PANGO_SCRIPT_CYPRIOT: 	Cypriot
	 * @PANGO_SCRIPT_LIMBU: 	Limbu
	 * @PANGO_SCRIPT_OSMANYA: 	Osmanya
	 * @PANGO_SCRIPT_SHAVIAN: 	Shavian
	 * @PANGO_SCRIPT_LINEAR_B: 	Linear B
	 * @PANGO_SCRIPT_TAI_LE: 	Tai Le
	 * @PANGO_SCRIPT_UGARITIC: 	Ugaritic
	 * @PANGO_SCRIPT_NEW_TAI_LUE: 	New Tai Lue. Since 1.10
	 * @PANGO_SCRIPT_BUGINESE: 	Buginese. Since 1.10
	 * @PANGO_SCRIPT_GLAGOLITIC: 	Glagolitic. Since 1.10
	 * @PANGO_SCRIPT_TIFINAGH: 	Tifinagh. Since 1.10
	 * @PANGO_SCRIPT_SYLOTI_NAGRI: 	Syloti Nagri. Since 1.10
	 * @PANGO_SCRIPT_OLD_PERSIAN: 	Old Persian. Since 1.10
	 * @PANGO_SCRIPT_KHAROSHTHI: 	Kharoshthi. Since 1.10
	 * @PANGO_SCRIPT_UNKNOWN: 		an unassigned code point. Since 1.14
	 * @PANGO_SCRIPT_BALINESE: 		Balinese. Since 1.14
	 * @PANGO_SCRIPT_CUNEIFORM: 	Cuneiform. Since 1.14
	 * @PANGO_SCRIPT_PHOENICIAN: 	Phoenician. Since 1.14
	 * @PANGO_SCRIPT_PHAGS_PA: 		Phags-pa. Since 1.14
	 * @PANGO_SCRIPT_NKO: 		N'Ko. Since 1.14
	 * @PANGO_SCRIPT_KAYAH_LI:   Kayah Li. Since 1.20.1
	 * @PANGO_SCRIPT_LEPCHA:     Lepcha. Since 1.20.1
	 * @PANGO_SCRIPT_REJANG:     Rejang. Since 1.20.1
	 * @PANGO_SCRIPT_SUNDANESE:  Sundanese. Since 1.20.1
	 * @PANGO_SCRIPT_SAURASHTRA: Saurashtra. Since 1.20.1
	 * @PANGO_SCRIPT_CHAM:       Cham. Since 1.20.1
	 * @PANGO_SCRIPT_OL_CHIKI:   Ol Chiki. Since 1.20.1
	 * @PANGO_SCRIPT_VAI:        Vai. Since 1.20.1
	 * @PANGO_SCRIPT_CARIAN:     Carian. Since 1.20.1
	 * @PANGO_SCRIPT_LYCIAN:     Lycian. Since 1.20.1
	 * @PANGO_SCRIPT_LYDIAN:     Lydian. Since 1.20.1
	 * @PANGO_SCRIPT_BATAK:      Batak. Since 1.32
	 * @PANGO_SCRIPT_BRAHMI:     Brahmi. Since 1.32
	 * @PANGO_SCRIPT_MANDAIC:    Mandaic. Since 1.32
	 * @PANGO_SCRIPT_CHAKMA:               Chakma. Since: 1.32
	 * @PANGO_SCRIPT_MEROITIC_CURSIVE:     Meroitic Cursive. Since: 1.32
	 * @PANGO_SCRIPT_MEROITIC_HIEROGLYPHS: Meroitic Hieroglyphs. Since: 1.32
	 * @PANGO_SCRIPT_MIAO:                 Miao. Since: 1.32
	 * @PANGO_SCRIPT_SHARADA:              Sharada. Since: 1.32
	 * @PANGO_SCRIPT_SORA_SOMPENG:         Sora Sompeng. Since: 1.32
	 * @PANGO_SCRIPT_TAKRI:                Takri. Since: 1.32
	 * @PANGO_SCRIPT_BASSA_VAH:            Bassa. Since: 1.40
	 * @PANGO_SCRIPT_CAUCASIAN_ALBANIAN:   Caucasian Albanian. Since: 1.40
	 * @PANGO_SCRIPT_DUPLOYAN:             Duployan. Since: 1.40
	 * @PANGO_SCRIPT_ELBASAN:              Elbasan. Since: 1.40
	 * @PANGO_SCRIPT_GRANTHA:              Grantha. Since: 1.40
	 * @PANGO_SCRIPT_KHOJKI:               Kjohki. Since: 1.40
	 * @PANGO_SCRIPT_KHUDAWADI:            Khudawadi, Sindhi. Since: 1.40
	 * @PANGO_SCRIPT_LINEAR_A:             Linear A. Since: 1.40
	 * @PANGO_SCRIPT_MAHAJANI:             Mahajani. Since: 1.40
	 * @PANGO_SCRIPT_MANICHAEAN:           Manichaean. Since: 1.40
	 * @PANGO_SCRIPT_MENDE_KIKAKUI:        Mende Kikakui. Since: 1.40
	 * @PANGO_SCRIPT_MODI:                 Modi. Since: 1.40
	 * @PANGO_SCRIPT_MRO:                  Mro. Since: 1.40
	 * @PANGO_SCRIPT_NABATAEAN:            Nabataean. Since: 1.40
	 * @PANGO_SCRIPT_OLD_NORTH_ARABIAN:    Old North Arabian. Since: 1.40
	 * @PANGO_SCRIPT_OLD_PERMIC:           Old Permic. Since: 1.40
	 * @PANGO_SCRIPT_PAHAWH_HMONG:         Pahawh Hmong. Since: 1.40
	 * @PANGO_SCRIPT_PALMYRENE:            Palmyrene. Since: 1.40
	 * @PANGO_SCRIPT_PAU_CIN_HAU:          Pau Cin Hau. Since: 1.40
	 * @PANGO_SCRIPT_PSALTER_PAHLAVI:      Psalter Pahlavi. Since: 1.40
	 * @PANGO_SCRIPT_SIDDHAM:              Siddham. Since: 1.40
	 * @PANGO_SCRIPT_TIRHUTA:              Tirhuta. Since: 1.40
	 * @PANGO_SCRIPT_WARANG_CITI:          Warang Citi. Since: 1.40
	 * @PANGO_SCRIPT_AHOM:                 Ahom. Since: 1.40
	 * @PANGO_SCRIPT_ANATOLIAN_HIEROGLYPHS: Anatolian Hieroglyphs. Since: 1.40
	 * @PANGO_SCRIPT_HATRAN:               Hatran. Since: 1.40
	 * @PANGO_SCRIPT_MULTANI:              Multani. Since: 1.40
	 * @PANGO_SCRIPT_OLD_HUNGARIAN:        Old Hungarian. Since: 1.40
	 * @PANGO_SCRIPT_SIGNWRITING:          Signwriting. Since: 1.40
	 *
	 * The #PangoScript enumeration identifies different writing
	 * systems. The values correspond to the names as defined in the
	 * Unicode standard.
	 * Note that new types may be added in the future. Applications should be ready
	 * to handle unknown values.  This enumeration is interchangeable with
	 * #GUnicodeScript.  See <ulink
	 * url="http:;www.unicode.org/reports/tr24/">Unicode Standard Annex
	 * #24: Script names</ulink>.
	 }
	{ ISO 15924 code }
	PANGO_SCRIPT_INVALID_CODE: -1
	PANGO_SCRIPT_COMMON: 0 { Zyyy }
	PANGO_SCRIPT_INHERITED: 1 { Qaai }
	PANGO_SCRIPT_ARABIC: 2 { Arab }
	PANGO_SCRIPT_ARMENIAN: 3 { Armn }
	PANGO_SCRIPT_BENGALI: 4 { Beng }
	PANGO_SCRIPT_BOPOMOFO: 5 { Bopo }
	PANGO_SCRIPT_CHEROKEE: 6 { Cher }
	PANGO_SCRIPT_COPTIC: 7 { Qaac }
	PANGO_SCRIPT_CYRILLIC: 8 { Cyrl (Cyrs) }
	PANGO_SCRIPT_DESERET: 9 { Dsrt }
	PANGO_SCRIPT_DEVANAGARI: 10 { Deva }
	PANGO_SCRIPT_ETHIOPIC: 11 { Ethi }
	PANGO_SCRIPT_GEORGIAN: 12 { Geor (Geon, Geoa) }
	PANGO_SCRIPT_GOTHIC: 13 { Goth }
	PANGO_SCRIPT_GREEK: 14 { Grek }
	PANGO_SCRIPT_GUJARATI: 15 { Gujr }
	PANGO_SCRIPT_GURMUKHI: 16 { Guru }
	PANGO_SCRIPT_HAN: 17 { Hani }
	PANGO_SCRIPT_HANGUL: 18 { Hang }
	PANGO_SCRIPT_HEBREW: 19 { Hebr }
	PANGO_SCRIPT_HIRAGANA: 20 { Hira }
	PANGO_SCRIPT_KANNADA: 21 { Knda }
	PANGO_SCRIPT_KATAKANA: 22 { Kana }
	PANGO_SCRIPT_KHMER: 23 { Khmr }
	PANGO_SCRIPT_LAO: 24 { Laoo }
	PANGO_SCRIPT_LATIN: 25 { Latn (Latf, Latg) }
	PANGO_SCRIPT_MALAYALAM: 26 { Mlym }
	PANGO_SCRIPT_MONGOLIAN: 27 { Mong }
	PANGO_SCRIPT_MYANMAR: 28 { Mymr }
	PANGO_SCRIPT_OGHAM: 29 { Ogam }
	PANGO_SCRIPT_OLD_ITALIC: 30 { Ital }
	PANGO_SCRIPT_ORIYA: 31 { Orya }
	PANGO_SCRIPT_RUNIC: 32 { Runr }
	PANGO_SCRIPT_SINHALA: 33 { Sinh }
	PANGO_SCRIPT_SYRIAC: 34 { Syrc (Syrj, Syrn, Syre) }
	PANGO_SCRIPT_TAMIL: 35 { Taml }
	PANGO_SCRIPT_TELUGU: 36 { Telu }
	PANGO_SCRIPT_THAANA: 37 { Thaa }
	PANGO_SCRIPT_THAI: 38 { Thai }
	PANGO_SCRIPT_TIBETAN: 39 { Tibt }
	PANGO_SCRIPT_CANADIAN_ABORIGINAL: 40 { Cans }
	PANGO_SCRIPT_YI: 41 { Yiii }
	PANGO_SCRIPT_TAGALOG: 42 { Tglg }
	PANGO_SCRIPT_HANUNOO: 43 { Hano }
	PANGO_SCRIPT_BUHID: 44 { Buhd }
	PANGO_SCRIPT_TAGBANWA: 45 { Tagb }

	{ Unicode-4.0 additions }
	PANGO_SCRIPT_BRAILLE: 46 { Brai }
	PANGO_SCRIPT_CYPRIOT: 47 { Cprt }
	PANGO_SCRIPT_LIMBU: 48 { Limb }
	PANGO_SCRIPT_OSMANYA: 49 { Osma }
	PANGO_SCRIPT_SHAVIAN: 50 { Shaw }
	PANGO_SCRIPT_LINEAR_B: 51 { Linb }
	PANGO_SCRIPT_TAI_LE: 52 { Tale }
	PANGO_SCRIPT_UGARITIC: 53 { Ugar }

	{ Unicode-4.1 additions }
	PANGO_SCRIPT_NEW_TAI_LUE: 54 { Talu }
	PANGO_SCRIPT_BUGINESE: 55 { Bugi }
	PANGO_SCRIPT_GLAGOLITIC: 56 { Glag }
	PANGO_SCRIPT_TIFINAGH: 57 { Tfng }
	PANGO_SCRIPT_SYLOTI_NAGRI: 58 { Sylo }
	PANGO_SCRIPT_OLD_PERSIAN: 59 { Xpeo }
	PANGO_SCRIPT_KHAROSHTHI: 60 { Khar }

	{ Unicode-5.0 additions }
	PANGO_SCRIPT_UNKNOWN: 61 { Zzzz }
	PANGO_SCRIPT_BALINESE: 62 { Bali }
	PANGO_SCRIPT_CUNEIFORM: 63 { Xsux }
	PANGO_SCRIPT_PHOENICIAN: 64 { Phnx }
	PANGO_SCRIPT_PHAGS_PA: 65 { Phag }
	PANGO_SCRIPT_NKO: 66 { Nkoo }

	{ Unicode-5.1 additions }
	PANGO_SCRIPT_KAYAH_LI: 67 { Kali }
	PANGO_SCRIPT_LEPCHA: 68 { Lepc }
	PANGO_SCRIPT_REJANG: 69 { Rjng }
	PANGO_SCRIPT_SUNDANESE: 70 { Sund }
	PANGO_SCRIPT_SAURASHTRA: 71 { Saur }
	PANGO_SCRIPT_CHAM: 72 { Cham }
	PANGO_SCRIPT_OL_CHIKI: 73 { Olck }
	PANGO_SCRIPT_VAI: 74 { Vaii }
	PANGO_SCRIPT_CARIAN: 75 { Cari }
	PANGO_SCRIPT_LYCIAN: 76 { Lyci }
	PANGO_SCRIPT_LYDIAN: 77 { Lydi }

	{ Unicode-6.0 additions }
	PANGO_SCRIPT_BATAK: 78 { Batk }
	PANGO_SCRIPT_BRAHMI: 79 { Brah }
	PANGO_SCRIPT_MANDAIC: 80 { Mand }

	{ Unicode-6.1 additions }
	PANGO_SCRIPT_CHAKMA: 81 { Cakm }
	PANGO_SCRIPT_MEROITIC_CURSIVE: 82 { Merc }
	PANGO_SCRIPT_MEROITIC_HIEROGLYPHS: 83 { Mero }
	PANGO_SCRIPT_MIAO: 84 { Plrd }
	PANGO_SCRIPT_SHARADA: 85 { Shrd }
	PANGO_SCRIPT_SORA_SOMPENG: 86 { Sora }
	PANGO_SCRIPT_TAKRI: 87 { Takr }

	{ Unicode 7.0 additions }
	PANGO_SCRIPT_BASSA_VAH: 88 { Bass }
	PANGO_SCRIPT_CAUCASIAN_ALBANIAN: 89 { Aghb }
	PANGO_SCRIPT_DUPLOYAN: 90 { Dupl }
	PANGO_SCRIPT_ELBASAN: 91 { Elba }
	PANGO_SCRIPT_GRANTHA: 92 { Gran }
	PANGO_SCRIPT_KHOJKI: 93 { Khoj }
	PANGO_SCRIPT_KHUDAWADI: 94 { Sind }
	PANGO_SCRIPT_LINEAR_A: 95 { Lina }
	PANGO_SCRIPT_MAHAJANI: 96 { Mahj }
	PANGO_SCRIPT_MANICHAEAN: 97 { Manu }
	PANGO_SCRIPT_MENDE_KIKAKUI: 98 { Mend }
	PANGO_SCRIPT_MODI: 99 { Modi }
	PANGO_SCRIPT_MRO: 100 { Mroo }
	PANGO_SCRIPT_NABATAEAN: 101 { Nbat }
	PANGO_SCRIPT_OLD_NORTH_ARABIAN: 102 { Narb }
	PANGO_SCRIPT_OLD_PERMIC: 103 { Perm }
	PANGO_SCRIPT_PAHAWH_HMONG: 104 { Hmng }
	PANGO_SCRIPT_PALMYRENE: 105 { Palm }
	PANGO_SCRIPT_PAU_CIN_HAU: 106 { Pauc }
	PANGO_SCRIPT_PSALTER_PAHLAVI: 107 { Phlp }
	PANGO_SCRIPT_SIDDHAM: 108 { Sidd }
	PANGO_SCRIPT_TIRHUTA: 109 { Tirh }
	PANGO_SCRIPT_WARANG_CITI: 110 { Wara }

	{ Unicode 8.0 additions }
	PANGO_SCRIPT_AHOM: 111 { Ahom }
	PANGO_SCRIPT_ANATOLIAN_HIEROGLYPHS: 112 { Hluw }
	PANGO_SCRIPT_HATRAN: 113 { Hatr }
	PANGO_SCRIPT_MULTANI: 114 { Mult }
	PANGO_SCRIPT_OLD_HUNGARIAN: 115 { Hung }
	{ Sgnw }
	PANGO_SCRIPT_SIGNWRITING: 116 { Sgnw }
	{ Sgnw }
	PangoScript: integer!;

	pango_script_for_unichar: make routine! [ ch [gunichar] return: [PangoScript] ] pango-lib "pango_script_for_unichar" 
	pango_script_iter_new: make routine! [ text [string!] length [integer!] return: [integer!] ] pango-lib "pango_script_iter_new" 
	pango_script_iter_get_range: make routine! [ iter [integer!]
	 start [struct! []]
	 end [struct! []]
	 script [integer!] return: [integer!] ] pango-lib "pango_script_iter_get_range" 

	pango_script_iter_next: make routine! [ iter [integer!] return: [gboolean] ] pango-lib "pango_script_iter_next" 
	pango_script_iter_free: make routine! [ iter [integer!] return: [integer!] ] pango-lib "pango_script_iter_free" 
	pango_script_get_sample_language: make routine! [ script [PangoScript] return: [integer!] ] pango-lib "pango_script_get_sample_language" 

{ pango-tabs.h }
	{ Pango
	 * pango-tabs.h: Tab-related stuff
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{*
	 * PangoTabAlign:
	 * @PANGO_TAB_LEFT: the tab stop appears to the left of the text.
	 *
	 * A #PangoTabAlign specifies where a tab stop appears relative to the text.
	 }
	PANGO_TAB_LEFT: 0

	{ These are not supported now, but may be in the
	* future.
	*
	*  PANGO_TAB_RIGHT,
	*  PANGO_TAB_CENTER,
	*  PANGO_TAB_NUMERIC
	}
	PangoTabAlign: integer!;

	{*
	 * PANGO_TYPE_TAB_ARRAY:
	 }

	pango_tab_array_new: make routine! [ initial_size [gint] positions_in_pixels [gboolean] return: [integer!] ] pango-lib "pango_tab_array_new" 
	pango_tab_array_new_with_positions: make routine! [ size [gint]
	 positions_in_pixels [gboolean]
	 first_alignment [PangoTabAlign]
	 first_position [gint]
	 ;...
	 return: [integer!] ] pango-lib "pango_tab_array_new_with_positions" 

	pango_tab_array_get_type: make routine! [ return: [GType] ] pango-lib "pango_tab_array_get_type" 
	pango_tab_array_copy: make routine! [ src [integer!] return: [integer!] ] pango-lib "pango_tab_array_copy" 
	pango_tab_array_free: make routine! [ tab_array [integer!] return: [integer!] ] pango-lib "pango_tab_array_free" 
	pango_tab_array_get_size: make routine! [ tab_array [integer!] return: [gint] ] pango-lib "pango_tab_array_get_size" 
	pango_tab_array_resize: make routine! [ tab_array [integer!] new_size [gint] return: [integer!] ] pango-lib "pango_tab_array_resize" 
	pango_tab_array_set_tab: make routine! [ tab_array [integer!]
	 tab_index [gint]
	 alignment [PangoTabAlign]
	 location [gint] return: [integer!] ] pango-lib "pango_tab_array_set_tab" 

	pango_tab_array_get_tab: make routine! [ tab_array [integer!]
	 tab_index [gint]
	 alignment [integer!]
	 location [integer!] return: [integer!] ] pango-lib "pango_tab_array_get_tab" 

	pango_tab_array_get_tabs: make routine! [ tab_array [integer!] alignments [struct! []] locations [struct! []] return: [integer!] ] pango-lib "pango_tab_array_get_tabs" 
	pango_tab_array_get_positions_in_pixels: make routine! [ tab_array [integer!] return: [gboolean] ] pango-lib "pango_tab_array_get_positions_in_pixels" 

{ pango-types.h }
	{ Pango
	 * pango-types.h:
	 *
	 * Copyright (C) 1999 Red Hat Software
	 *

	 }

	{ A index of a glyph into a font. Rendering system dependent }
	{*
	 * PangoGlyph:
	 *
	 * A #PangoGlyph represents a single glyph in the output form of a string.
	 }

	{*
	 * PANGO_SCALE:
	 *
	 * The %PANGO_SCALE macro represents the scale between dimensions used
	 * for Pango distances and device units. (The definition of device
	 * units is dependent on the output device; it will typically be pixels
	 * for a screen, and points for a printer.) %PANGO_SCALE is currently
	 * 1024, but this may be changed in the future.
	 *
	 * When setting font sizes, device units are always considered to be
	 * points (as in "12 point font"), rather than pixels.
	 }
	{*
	 * PANGO_PIXELS:
	 * @d: a dimension in Pango units.
	 *
	 * Converts a dimension to device units by rounding.
	 *
	 * Return value: rounded dimension in device units.
	 }
	{*
	 * PANGO_PIXELS_FLOOR:
	 * @d: a dimension in Pango units.
	 *
	 * Converts a dimension to device units by flooring.
	 *
	 * Return value: floored dimension in device units.
	 * Since: 1.14
	 }
	{*
	 * PANGO_PIXELS_CEIL:
	 * @d: a dimension in Pango units.
	 *
	 * Converts a dimension to device units by ceiling.
	 *
	 * Return value: ceiled dimension in device units.
	 * Since: 1.14
	 }
	PANGO_SCALE: 1024
	{
	#define PANGO_PIXELS(d) (((int)(d) + 512) >> 10)
	#define PANGO_PIXELS_FLOOR(d) (((int)(d)) >> 10)
	#define PANGO_PIXELS_CEIL(d) (((int)(d) + 1023) >> 10)
	}
	{ The above expressions are just slightly wrong for floating point d;
	 * For example we'd expect PANGO_PIXELS(-512.5) => -1 but instead we get 0.
	 * That's unlikely to matter for practical use and the expression is much
	 * more compact and faster than alternatives that work exactly for both
	 * integers and floating point.
	 *
	 * PANGO_PIXELS also behaves differently for +512 and -512.
	 }

	{*
	 * PANGO_UNITS_ROUND:
	 * @d: a dimension in Pango units.
	 *
	 * Rounds a dimension to whole device units, but does not
	 * convert it to device units.
	 *
	 * Return value: rounded dimension in Pango units.
	 * Since: 1.18
	 }
	{
	#define PANGO_UNITS_ROUND(d)				\
	  (((d) + (PANGO_SCALE >> 1)) & ~(PANGO_SCALE - 1))
	}

	pango_units_from_double: make routine! [ d [double] return: [integer!] ] pango-lib "pango_units_from_double" 
	pango_units_to_double: make routine! [ i [integer!] return: [double] ] pango-lib "pango_units_to_double" 

	{*
	 * PangoRectangle:
	 * @x: X coordinate of the left side of the rectangle.
	 * @y: Y coordinate of the the top side of the rectangle.
	 * @width: width of the rectangle.
	 * @height: height of the rectangle.
	 *
	 * The #PangoRectangle structure represents a rectangle. It is frequently
	 * used to represent the logical or ink extents of a single glyph or section
	 * of text. (See, for instance, pango_font_get_glyph_extents())
	 *
	 }
	_PangoRectangle: make struct! [
		x [integer!]
		y [integer!]
		width [integer!]
		height [integer!]
	] none ;

	{ Macros to translate from extents rectangles to ascent/descent/lbearing/rbearing
	 }
	{*
	 * PANGO_ASCENT:
	 * @rect: a #PangoRectangle
	 *
	 * Extracts the <firstterm>ascent</firstterm> from a #PangoRectangle
	 * representing glyph extents. The ascent is the distance from the
	 * baseline to the highest point of the character. This is positive if the
	 * glyph ascends above the baseline.
	 }
	{*
	 * PANGO_DESCENT:
	 * @rect: a #PangoRectangle
	 *
	 * Extracts the <firstterm>descent</firstterm> from a #PangoRectangle
	 * representing glyph extents. The descent is the distance from the
	 * baseline to the lowest point of the character. This is positive if the
	 * glyph descends below the baseline.
	 }
	{*
	 * PANGO_LBEARING:
	 * @rect: a #PangoRectangle
	 *
	 * Extracts the <firstterm>left bearing</firstterm> from a #PangoRectangle
	 * representing glyph extents. The left bearing is the distance from the
	 * horizontal origin to the farthest left point of the character.
	 * This is positive for characters drawn completely to the right of the
	 * glyph origin.
	 }
	{*
	 * PANGO_RBEARING:
	 * @rect: a #PangoRectangle
	 *
	 * Extracts the <firstterm>right bearing</firstterm> from a #PangoRectangle
	 * representing glyph extents. The right bearing is the distance from the
	 * horizontal origin to the farthest right point of the character.
	 * This is positive except for characters drawn completely to the left of the
	 * horizontal origin.
	 }
	{
	#define PANGO_ASCENT(rect) (-(rect).y)
	#define PANGO_DESCENT(rect) ((rect).y + (rect).height)
	#define PANGO_LBEARING(rect) ((rect).x)
	#define PANGO_RBEARING(rect) ((rect).x + (rect).width)
	}

	pango_extents_to_pixels: make routine! [ inclusive [integer!] nearest [integer!] return: [integer!] ] pango-lib "pango_extents_to_pixels" 

{ pango-utils.h }
	{ Pango
	 * pango-utils.c: Utilities for internal functions and modules
	 *
	 * Copyright (C) 2000 Red Hat Software
	 *

	 }

	{ Functions for parsing textual representations
	 * of PangoFontDescription fields. They return TRUE if the input string
	 * contains a valid value, which then has been assigned to the corresponding
	 * field in the PangoFontDescription. If the warn parameter is TRUE,
	 * a warning is printed (with g_warning) if the string does not
	 * contain a valid value.
	 }

	pango_parse_style: make routine! [ str [string!] style [integer!] warn [gboolean] return: [gboolean] ] pango-lib "pango_parse_style" 
	pango_parse_variant: make routine! [ str [string!] variant [integer!] warn [gboolean] return: [gboolean] ] pango-lib "pango_parse_variant" 
	pango_parse_weight: make routine! [ str [string!] weight [integer!] warn [gboolean] return: [gboolean] ] pango-lib "pango_parse_weight" 
	pango_parse_stretch: make routine! [ str [string!] stretch [integer!] warn [gboolean] return: [gboolean] ] pango-lib "pango_parse_stretch" 

	{ Hint line position and thickness.
	}

	pango_quantize_line_geometry: make routine! [ thickness [integer!] position [integer!] return: [integer!] ] pango-lib "pango_quantize_line_geometry" 

	{ A routine from fribidi that we either wrap or provide ourselves.
	}

	pango_log2vis_get_embedding_levels: make routine! [ text [integer!] length [integer!] pbase_dir [integer!] return: [integer!] ] pango-lib "pango_log2vis_get_embedding_levels" 

	{ Unicode characters that are zero-width and should not be rendered
	* normally.
	}

	pango_is_zero_width: make routine! [ ch [gunichar] return: [gboolean] ] pango-lib "pango_is_zero_width"


{ pangocairo.h }
if Pango_HAS_PANGOCAIRO [
	{ Pango
	 * pangocairo.h:
	 *
	 * Copyright (C) 1999, 2004 Red Hat, Inc.
	 *

	 }

	{*
	* PangoCairoShapeRendererFunc:
	 * @cr: a Cairo context with current point set to where the shape should
	 * be rendered
	 * @attr: the %PANGO_ATTR_SHAPE to render
	 * @do_path: whether only the shape path should be appended to current
	 * path of @cr and no filling/stroking done.  This will be set
	 * to %TRUE when called from pango_cairo_layout_path() and
	 * pango_cairo_layout_line_path() rendering functions.
	 * @data: user data passed to pango_cairo_context_set_shape_renderer()
	 *
	 * Function type for rendering attributes of type %PANGO_ATTR_SHAPE
	 * with Pango's Cairo renderer.
	 }
	{
	typedef void (* PangoCairoShapeRendererFunc) (cairo_t        *cr,
						      PangoAttrShape *attr,
						      gboolean        do_path,
						      gpointer        data);
	}
{
* PangoCairoFontMap }

	pango_cairo_font_map_get_type: make routine! [ return: [GType] ] pango-cairo-lib "pango_cairo_font_map_get_type" 
	pango_cairo_font_map_new: make routine! [ return: [integer!] ] pango-cairo-lib "pango_cairo_font_map_new" 
	pango_cairo_font_map_new_for_font_type: make routine! [ fonttype [cairo_font_type_t] return: [integer!] ] pango-cairo-lib "pango_cairo_font_map_new_for_font_type" 
	pango_cairo_font_map_get_default: make routine! [ return: [integer!] ] pango-cairo-lib "pango_cairo_font_map_get_default" 
	pango_cairo_font_map_set_default: make routine! [ fontmap [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_font_map_set_default" 
	pango_cairo_font_map_get_font_type: make routine! [ fontmap [integer!] return: [cairo_font_type_t] ] pango-cairo-lib "pango_cairo_font_map_get_font_type" 
	pango_cairo_font_map_set_resolution: make routine! [ fontmap [integer!] dpi [double] return: [integer!] ] pango-cairo-lib "pango_cairo_font_map_set_resolution" 
	pango_cairo_font_map_get_resolution: make routine! [ fontmap [integer!] return: [double] ] pango-cairo-lib "pango_cairo_font_map_get_resolution" 
{
* PangoCairoFont }

	pango_cairo_font_get_type: make routine! [ return: [GType] ] pango-cairo-lib "pango_cairo_font_get_type" 
	pango_cairo_font_get_scaled_font: make routine! [ font [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_font_get_scaled_font" 

{ Update a Pango context for the current state of a cairo context
	}
	pango_cairo_update_context: make routine! [ cr [integer!] context [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_update_context" 
	pango_cairo_context_set_font_options: make routine! [ context [integer!] options [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_context_set_font_options" 
	pango_cairo_context_get_font_options: make routine! [ context [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_context_get_font_options" 
	pango_cairo_context_set_resolution: make routine! [ context [integer!] dpi [double] return: [integer!] ] pango-cairo-lib "pango_cairo_context_set_resolution" 
	pango_cairo_context_get_resolution: make routine! [ context [integer!] return: [double] ] pango-cairo-lib "pango_cairo_context_get_resolution" 
	pango_cairo_context_set_shape_renderer: make routine! [ context [integer!]
	 func [integer!];[callback]
	 data [gpointer]
	 dnotify [integer!];[callback]
	 return: [integer!] ] pango-cairo-lib "pango_cairo_context_set_shape_renderer" 

	pango_cairo_context_get_shape_renderer: make routine! [ context [integer!] data [integer!] return: [PangoCairoShapeRendererFunc] ] pango-cairo-lib "pango_cairo_context_get_shape_renderer" 

{ Convenience
 }
	pango_cairo_create_context: make routine! [ cr [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_create_context" 
	pango_cairo_create_layout: make routine! [ cr [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_create_layout" 
	pango_cairo_update_layout: make routine! [ cr [integer!] layout [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_update_layout" 

{
* Rendering }
	pango_cairo_show_glyph_string: make routine! [ cr [integer!] font [integer!] glyphs [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_show_glyph_string" 
	pango_cairo_show_glyph_item: make routine! [ cr [integer!] text [string!] glyph_item [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_show_glyph_item" 
	pango_cairo_show_layout_line: make routine! [ cr [integer!] line [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_show_layout_line" 
	pango_cairo_show_layout: make routine! [ cr [integer!] layout [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_show_layout" 
	pango_cairo_show_error_underline: make routine! [ cr [integer!]
	 x [double]
	 y [double]
	 width [double]
	 height [double] return: [integer!] ] pango-cairo-lib "pango_cairo_show_error_underline" 

{
* Rendering to a path }
	pango_cairo_glyph_string_path: make routine! [ cr [integer!] font [integer!] glyphs [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_glyph_string_path" 
	pango_cairo_layout_line_path: make routine! [ cr [integer!] line [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_layout_line_path" 
	pango_cairo_layout_path: make routine! [ cr [integer!] layout [integer!] return: [integer!] ] pango-cairo-lib "pango_cairo_layout_path" 
	pango_cairo_error_underline_path: make routine! [ cr [integer!]
	 x [double]
	 y [double]
	 width [double]
	 height [double] return: [integer!] ] pango-cairo-lib "pango_cairo_error_underline_path" 
]
{ pangocoretext.h }
	{ Pango
	 * pangocoretext.h:
	 *
	 * Copyright (C) 2005 Imendio AB
	 * Copyright (C) 2010  Kristian Rietveld  <kris@gtk.org>
	 *

	 }

	{*
	 * PANGO_RENDER_TYPE_CORE_TEXT:
	 *
	 * A string constant identifying the CoreText renderer. The associated quark (see
	 * g_quark_from_string()) is used to identify the renderer in pango_find_map().
	 }
	PANGO_RENDER_TYPE_CORE_TEXT: "PangoRenderCoreText"

	_PangoCoreTextFont: make struct! [
		parent_instance [PangoFont]
		priv [integer!]
	] none ;

if Pango_HAS_FC_FONT [
{ pangofc-decoder.h }
	{ Pango
	 * pangofc-decoder.h: Custom encoders/decoders on a per-font basis.
	 *
	 * Copyright (C) 2004 Red Hat Software
	 *

	 }

	{*
	 * PangoFcDecoder:
	 *
	 * #PangoFcDecoder is a virtual base class that implementations will
	 * inherit from.  It's the interface that is used to define a custom
	 * encoding for a font.  These objects are created in your code from a
	 * function callback that was originally registered with
	 * pango_fc_font_map_add_decoder_find_func().  Pango requires
	 * information about the supported charset for a font as well as the
	 * individual character to glyph conversions.  Pango gets that
	 * information via the #get_charset and #get_glyph callbacks into your
	 * object implementation.
	 *
	 * Since: 1.6
	 *}
	_PangoFcDecoder: make struct! [
		{< private >}
		parent_instance [GObject]
	] none ;

	{*
	 * PangoFcDecoderClass:
	 * @get_charset: This returns an #FcCharset given a #PangoFcFont that
	 *  includes a list of supported characters in the font.  The
	 *  #FcCharSet that is returned should be an internal reference to your
	 *  code.  Pango will not free this structure.  It is important that
	 *  you make this callback fast because this callback is called
	 *  separately for each character to determine Unicode coverage.
	 * @get_glyph: This returns a single #PangoGlyph for a given Unicode
	 *  code point.
	 *
	 * Class structure for #PangoFcDecoder.
	 *
	 * Since: 1.6
	 *}

{ pangofc-font.h }
	{ Pango
	 * pangofc-font.h: Base fontmap type for fontconfig-based backends
	 *
	 * Copyright (C) 2003 Red Hat Software
	 *

	 }

	{*
	 * PANGO_RENDER_TYPE_FC:
	 *
	 * A string constant used to identify shape engines that work
	 * with the fontconfig based backends. See the @engine_type field
	 * of #PangoEngineInfo.
	 *}
	PANGO_RENDER_TYPE_FC: "PangoRenderFc"

	{*
	 * PangoFcFont:
	 *
	 * #PangoFcFont is a base class for font implementations
	 * using the Fontconfig and FreeType libraries and is used in
	 * conjunction with #PangoFcFontMap. When deriving from this
	 * class, you need to implement all of its virtual functions
	 * other than shutdown() along with the get_glyph_extents()
	 * virtual function from #PangoFont.
	 *}
	_PangoFcFont: make struct! [
		parent_instance [PangoFont]

		font_pattern [integer!] { fully resolved pattern }
		fontmap [integer!] { associated map }
		priv [gpointer] { used internally }
		matrix [PangoMatrix] { used internally }
		description [integer!]

		metrics_by_lang [integer!]

		is_hinted [guint] {: 1;}
		is_transformed [guint] {: 1;}
	] none ;

	pango_fc_font_has_char: make routine! [ font [integer!] wc [gunichar] return: [gboolean] ] pango-lib "pango_fc_font_has_char" 
	pango_fc_font_get_glyph: make routine! [ font [integer!] wc [gunichar] return: [guint] ] pango-lib "pango_fc_font_get_glyph" 

	pango_fc_font_get_type: make routine! [ return: [GType] ] pango-lib "pango_fc_font_get_type" 
	pango_fc_font_lock_face: make routine! [ font [integer!] return: [FT_Face] ] pango-lib "pango_fc_font_lock_face" 
	pango_fc_font_unlock_face: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_fc_font_unlock_face" 

{ pangofc-fontmap.h }
	{ Pango
	 * pangofc-fontmap.h: Base fontmap type for fontconfig-based backends
	 *
	 * Copyright (C) 2003 Red Hat Software
	 *

	 }

	{*
	 * PangoFcFontsetKey:
	 *
	 * An opaque structure containing all the information needed for
	 * loading a fontset with the PangoFc fontmap.
	 *
	 * Since: 1.24
	 *}

	pango_fc_fontset_key_get_language: make routine! [ key [integer!] return: [integer!] ] pango-lib "pango_fc_fontset_key_get_language" 
	pango_fc_fontset_key_get_description: make routine! [ key [integer!] return: [integer!] ] pango-lib "pango_fc_fontset_key_get_description" 
	pango_fc_fontset_key_get_matrix: make routine! [ key [integer!] return: [integer!] ] pango-lib "pango_fc_fontset_key_get_matrix" 
	pango_fc_fontset_key_get_absolute_size: make routine! [ key [integer!] return: [double] ] pango-lib "pango_fc_fontset_key_get_absolute_size" 
	pango_fc_fontset_key_get_resolution: make routine! [ key [integer!] return: [double] ] pango-lib "pango_fc_fontset_key_get_resolution" 
	pango_fc_fontset_key_get_context_key: make routine! [ key [integer!] return: [gpointer] ] pango-lib "pango_fc_fontset_key_get_context_key" 

	{*
	 * PangoFcFontKey:
	 *
	 * An opaque structure containing all the information needed for
	 * loading a font with the PangoFc fontmap.
	 *
	 * Since: 1.24
	 *}

	pango_fc_font_key_get_pattern: make routine! [ key [integer!] return: [integer!] ] pango-lib "pango_fc_font_key_get_pattern" 
	pango_fc_font_key_get_matrix: make routine! [ key [integer!] return: [integer!] ] pango-lib "pango_fc_font_key_get_matrix" 
	pango_fc_font_key_get_context_key: make routine! [ key [integer!] return: [gpointer] ] pango-lib "pango_fc_font_key_get_context_key" 
	pango_fc_font_key_get_variations: make routine! [ key [integer!] return: [string!] ] pango-lib "pango_fc_font_key_get_variations" 

	{*
	 * PangoFcFontMap:
	 *
	 * #PangoFcFontMap is a base class for font map implementations
	 * using the Fontconfig and FreeType libraries. To create a new
	 * backend using Fontconfig and FreeType, you derive from this class
	 * and implement a new_font() virtual function that creates an
	 * instance deriving from #PangoFcFont.
	 *}
	_PangoFcFontMap: make struct! [
		parent_instance [PangoFontMap]
		priv [integer!]
	] none ;

	pango_fc_font_map_shutdown: make routine! [ fcfontmap [integer!] return: [integer!] ] pango-lib "pango_fc_font_map_shutdown" 
	pango_fc_font_map_get_type: make routine! [ return: [GType] ] pango-lib "pango_fc_font_map_get_type" 
	pango_fc_font_map_cache_clear: make routine! [ fcfontmap [integer!] return: [integer!] ] pango-lib "pango_fc_font_map_cache_clear" 
	pango_fc_font_map_config_changed: make routine! [ fcfontmap [integer!] return: [integer!] ] pango-lib "pango_fc_font_map_config_changed" 
	pango_fc_font_map_set_config: make routine! [ fcfontmap [integer!] fcconfig [integer!] return: [integer!] ] pango-lib "pango_fc_font_map_set_config" 
	pango_fc_font_map_get_config: make routine! [ fcfontmap [integer!] return: [integer!] ] pango-lib "pango_fc_font_map_get_config" 

	{*
	 * PangoFcDecoderFindFunc:
	 * @pattern: a fully resolved #FcPattern specifying the font on the system
	 * @user_data: user data passed to pango_fc_font_map_add_decoder_find_func()
	 *
	 * Callback function passed to pango_fc_font_map_add_decoder_find_func().
	 *
	 * Return value: a new reference to a custom decoder for this pattern,
	 *  or %NULL if the default decoder handling should be used.
	 *}

	pango_fc_font_map_add_decoder_find_func: make routine! [ fcfontmap [integer!]
	 findfunc [PangoFcDecoderFindFunc]
	 user_data [gpointer]
	 dnotify [integer!];[callback]
	 return: [integer!] ] pango-lib "pango_fc_font_map_add_decoder_find_func" 

	pango_fc_font_map_find_decoder: make routine! [ fcfontmap [integer!] pattern [integer!] return: [integer!] ] pango-lib "pango_fc_font_map_find_decoder" 
	pango_fc_font_description_from_pattern: make routine! [ pattern [integer!] include_size [gboolean] return: [integer!] ] pango-lib "pango_fc_font_description_from_pattern" 

	{*
	 * PANGO_FC_GRAVITY:
	 *
	 * String representing a fontconfig property name that Pango sets on any
	 * fontconfig pattern it passes to fontconfig if a #PangoGravity other
	 * than %PANGO_GRAVITY_SOUTH is desired.
	 *
	 * The property will have a #PangoGravity value as a string, like "east".
	 * This can be used to write fontconfig configuration rules to choose
	 * different fonts for horizontal and vertical writing directions.
	 *
	 * Since: 1.20
	 }
	PANGO_FC_GRAVITY: "pangogravity"

	{*
	 * PANGO_FC_VERSION:
	 *
	 * String representing a fontconfig property name that Pango sets on any
	 * fontconfig pattern it passes to fontconfig.
	 *
	 * The property will have an integer value equal to what
	 * pango_version() returns.
	 * This can be used to write fontconfig configuration rules that only affect
	 * certain pango versions (or only pango-using applications, or only
	 * non-pango-using applications).
	 *
	 * Since: 1.20
	 }
	PANGO_FC_VERSION: "pangoversion"

	{*
	 * PANGO_FC_PRGNAME:
	 *
	 * String representing a fontconfig property name that Pango sets on any
	 * fontconfig pattern it passes to fontconfig.
	 *
	 * The property will have a string equal to what
	 * g_get_prgname() returns.
	 * This can be used to write fontconfig configuration rules that only affect
	 * certain applications.
	 *
	 * This is equivalent to FC_PRGNAME in versions of fontconfig that have that.
	 *
	 * Since: 1.24
	 }
	PANGO_FC_PRGNAME: "prgname"

	{*
	 * PANGO_FC_FONT_FEATURES:
	 *
	 * String representing a fontconfig property name that Pango reads from font
	 * patterns to populate list of OpenType features to be enabled for the font
	 * by default.
	 *
	 * The property will have a number of string elements, each of which is the
	 * OpenType feature tag of one feature to enable.
	 *
	 * This is equivalent to FC_FONT_FEATURES in versions of fontconfig that have that.
	 *
	 * Since: 1.34
	 }
	PANGO_FC_FONT_FEATURES: "fontfeatures"

	{*
	 * PANGO_FC_FONT_VARIATIONS:
	 *
	 * String representing a fontconfig property name that Pango reads from font
	 * patterns to populate list of OpenType font variations to be used for a font.
	 *
	 * The property will have a string elements, each of which a comma-separated
	 * list of OpenType axis setting of the form AXIS=VALUE.
	 }
	PANGO_FC_FONT_VARIATIONS: "fontvariations"

]
if Pango_HAS_FT2 [
{ pangoft2.h }
	{ Pango
	 * pangoft2.h:
	 *
	 * Copyright (C) 1999 Red Hat Software
	 * Copyright (C) 2000 Tor Lillqvist
	 *

	 }

	{ Calls for applications }

	pango_ft2_render: make routine! [ bitmap [integer!]
	 font [integer!]
	 glyphs [integer!]
	 x [gint]
	 y [gint] return: [integer!] ] pango-lib "pango_ft2_render" 

	pango_ft2_render_transformed: make routine! [ bitmap [integer!]
	 matrix [integer!]
	 font [integer!]
	 glyphs [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_ft2_render_transformed" 

	pango_ft2_render_layout_line: make routine! [ bitmap [integer!]
	 line [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_ft2_render_layout_line" 

	pango_ft2_render_layout_line_subpixel: make routine! [ bitmap [integer!]
	 line [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_ft2_render_layout_line_subpixel" 

	pango_ft2_render_layout: make routine! [ bitmap [integer!]
	 layout [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_ft2_render_layout" 

	pango_ft2_render_layout_subpixel: make routine! [ bitmap [integer!]
	 layout [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_ft2_render_layout_subpixel" 

	pango_ft2_font_map_get_type: make routine! [ return: [GType] ] pango-lib "pango_ft2_font_map_get_type" 
	pango_ft2_font_map_new: make routine! [ return: [integer!] ] pango-lib "pango_ft2_font_map_new" 
	pango_ft2_font_map_set_resolution: make routine! [ fontmap [integer!] dpi_x [double] dpi_y [double] return: [integer!] ] pango-lib "pango_ft2_font_map_set_resolution" 
	pango_ft2_font_map_set_default_substitute: make routine! [ fontmap [integer!]
	 func [PangoFT2SubstituteFunc]
	 data [gpointer]
	 notify [GDestroyNotify] return: [integer!] ] pango-lib "pango_ft2_font_map_set_default_substitute" 

	pango_ft2_font_map_substitute_changed: make routine! [ fontmap [integer!] return: [integer!] ] pango-lib "pango_ft2_font_map_substitute_changed" 

	{ API for rendering modules
	 }
]
if Pango_HAS_WIN32 [
	{ TrueType defines: }
	{
	#define MAKE_TT_TABLE_NAME(c1, c2, c3, c4) \
	   (((guint32)c4) << 24 | ((guint32)c3) << 16 | ((guint32)c2) << 8 | ((guint32)c1))

	#define CMAP (MAKE_TT_TABLE_NAME('c','m','a','p'))
	}
	CMAP_HEADER_SIZE: 4

	;#define NAME (MAKE_TT_TABLE_NAME('n','a','m','e'))
	NAME_HEADER_SIZE: 6

	ENCODING_TABLE_SIZE: 8

	APPLE_UNICODE_PLATFORM_ID: 0
	MACINTOSH_PLATFORM_ID: 1
	ISO_PLATFORM_ID: 2
	MICROSOFT_PLATFORM_ID: 3

	SYMBOL_ENCODING_ID: 0
	UNICODE_ENCODING_ID: 1
	UCS4_ENCODING_ID: 10

	{ All the below structs must be packed! }

	cmap_encoding_subtable: make struct! [
		platform_id [guint16]
		encoding_id [guint16]
		offset [guint32]
	] none ;

	format_4_cmap: make struct! [
		format [guint16]
		length [guint16]
		language [guint16]
		seg_count_x_2 [guint16]
		search_range [guint16]
		entry_selector [guint16]
		range_shift [guint16]

		reserved [guint16]

		arrays [guint16] ;[1];
	] none ;

	format_12_cmap: make struct! [
		format [guint16]
		reserved [guint16]
		length [guint32]
		language [guint32]
		count [guint32]

		groups [guint32] ;[1];
	] none ;

	name_header: make struct! [
		format_selector [guint16]
		num_records [guint16]
		string_storage_offset [guint16]
	] none ;

	name_record: make struct! [
		platform_id [guint16]
		encoding_id [guint16]
		language_id [guint16]
		name_id [guint16]
		string_length [guint16]
		string_offset [guint16]
	] none ;

{ pangowin32.h }
	{ Pango
	 * pangowin32.h:
	 *
	 * Copyright (C) 1999 Red Hat Software
	 * Copyright (C) 2000 Tor Lillqvist
	 * Copyright (C) 2001 Alexander Larsson
	 *

	 }

	{*
	 * PANGO_RENDER_TYPE_WIN32:
	 *
	 * A string constant identifying the Win32 renderer. The associated quark (see
	 * g_quark_from_string()) is used to identify the renderer in pango_find_map().
	 }
	PANGO_RENDER_TYPE_WIN32: "PangoRenderWin32"

	{ Calls for applications
	 }
	pango_win32_render: make routine! [ hdc [HDC]
	 font [integer!]
	 glyphs [integer!]
	 x [gint]
	 y [gint] return: [integer!] ] pango-lib "pango_win32_render" 

	pango_win32_render_layout_line: make routine! [ hdc [HDC]
	 line [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_win32_render_layout_line" 

	pango_win32_render_layout: make routine! [ hdc [HDC]
	 layout [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_win32_render_layout" 

	pango_win32_render_transformed: make routine! [ hdc [HDC]
	 matrix [integer!]
	 font [integer!]
	 glyphs [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_win32_render_transformed" 

	;#ifdef PANGO_ENABLE_ENGINE

	pango_win32_font_get_glyph_index: make routine! [ font [integer!] wc [gunichar] return: [gint] ] pango-lib "pango_win32_font_get_glyph_index" 
	pango_win32_get_dc: make routine! [ return: [HDC] ] pango-lib "pango_win32_get_dc" 
	pango_win32_get_debug_flag: make routine! [ return: [gboolean] ] pango-lib "pango_win32_get_debug_flag" 
	pango_win32_font_select_font: make routine! [ font [integer!] hdc [HDC] return: [gboolean] ] pango-lib "pango_win32_font_select_font" 
	pango_win32_font_done_font: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_win32_font_done_font" 
	pango_win32_font_get_metrics_factor: make routine! [ font [integer!] return: [double] ] pango-lib "pango_win32_font_get_metrics_factor" 

	;#endif

	{ API for libraries that want to use PangoWin32 mixed with classic
	 * Win32 fonts.
	 }

	pango_win32_font_cache_new: make routine! [ return: [integer!] ] pango-lib "pango_win32_font_cache_new" 
	pango_win32_font_cache_free: make routine! [ cache [integer!] return: [integer!] ] pango-lib "pango_win32_font_cache_free" 
	pango_win32_font_cache_load: make routine! [ cache [integer!] logfont [integer!] return: [HFONT] ] pango-lib "pango_win32_font_cache_load" 
	pango_win32_font_cache_loadw: make routine! [ cache [integer!] logfont [integer!] return: [HFONT] ] pango-lib "pango_win32_font_cache_loadw" 
	pango_win32_font_cache_unload: make routine! [ cache [integer!] hfont [HFONT] return: [integer!] ] pango-lib "pango_win32_font_cache_unload" 
	pango_win32_font_map_for_display: make routine! [ return: [integer!] ] pango-lib "pango_win32_font_map_for_display" 
	pango_win32_shutdown_display: make routine! [ return: [integer!] ] pango-lib "pango_win32_shutdown_display" 
	pango_win32_font_map_get_font_cache: make routine! [ font_map [integer!] return: [integer!] ] pango-lib "pango_win32_font_map_get_font_cache" 
	pango_win32_font_logfont: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_win32_font_logfont" 
	pango_win32_font_logfontw: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_win32_font_logfontw" 
	pango_win32_font_description_from_logfont: make routine! [ lfp [integer!] return: [integer!] ] pango-lib "pango_win32_font_description_from_logfont" 
	pango_win32_font_description_from_logfontw: make routine! [ lfp [integer!] return: [integer!] ] pango-lib "pango_win32_font_description_from_logfontw" 
]
if Pango_HAS_XFT [
{ pangoxft-render.h }
	{ Pango
	 * pangoxft-render.h: Rendering routines for the Xft library
	 *
	 * Copyright (C) 2004 Red Hat Software
	 *

	 }

	{*
	 * PangoXftRenderer:
	 *
	 * #PangoXftRenderer is a subclass of #PangoRenderer used for rendering
	 * with Pango's Xft backend. It can be used directly, or it can be
	 * further subclassed to modify exactly how drawing of individual
	 * elements occurs.
	 *
	 * Since: 1.8
	 }
	_PangoXftRenderer: make struct! [
		{< private >}
		parent_instance [PangoRenderer]

		display [integer!]
		screen [integer!]
		draw [integer!]

		priv [integer!]
	] none ;

	pango_xft_renderer_get_type: make routine! [ return: [GType] ] pango-lib "pango_xft_renderer_get_type" 
	pango_xft_renderer_new: make routine! [ display [integer!] screen [integer!] return: [integer!] ] pango-lib "pango_xft_renderer_new" 
	pango_xft_renderer_set_draw: make routine! [ xftrenderer [integer!] draw [integer!] return: [integer!] ] pango-lib "pango_xft_renderer_set_draw" 
	pango_xft_renderer_set_default_color: make routine! [ xftrenderer [integer!] default_color [integer!] return: [integer!] ] pango-lib "pango_xft_renderer_set_default_color" 
	pango_xft_render: make routine! [ draw [integer!]
	 color [integer!]
	 font [integer!]
	 glyphs [integer!]
	 x [gint]
	 y [gint] return: [integer!] ] pango-lib "pango_xft_render" 

	pango_xft_picture_render: make routine! [ display [integer!]
	 src_picture [Picture]
	 dest_picture [Picture]
	 font [integer!]
	 glyphs [integer!]
	 x [gint]
	 y [gint] return: [integer!] ] pango-lib "pango_xft_picture_render" 

	pango_xft_render_transformed: make routine! [ draw [integer!]
	 color [integer!]
	 matrix [integer!]
	 font [integer!]
	 glyphs [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_xft_render_transformed" 

	pango_xft_render_layout_line: make routine! [ draw [integer!]
	 color [integer!]
	 line [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_xft_render_layout_line" 

	pango_xft_render_layout: make routine! [ draw [integer!]
	 color [integer!]
	 layout [integer!]
	 x [integer!]
	 y [integer!] return: [integer!] ] pango-lib "pango_xft_render_layout" 

{ pangoxft.h }
	{ Pango
	 * pangoxft.h:
	 *
	 * Copyright (C) 1999 Red Hat Software
	 * Copyright (C) 2000 SuSE Linux Ltd
	 *

	 }

	{ Calls for applications
	 }

	pango_xft_get_font_map: make routine! [ display [integer!] screen [integer!] return: [integer!] ] pango-lib "pango_xft_get_font_map" 

	pango_xft_shutdown_display: make routine! [ display [integer!] screen [integer!] return: [integer!] ] pango-lib "pango_xft_shutdown_display" 
	pango_xft_set_default_substitute: make routine! [ display [integer!]
	 screen [integer!]
	 func [PangoXftSubstituteFunc]
	 data [gpointer]
	 notify [GDestroyNotify] return: [integer!] ] pango-lib "pango_xft_set_default_substitute" 

	pango_xft_substitute_changed: make routine! [ display [integer!] screen [integer!] return: [integer!] ] pango-lib "pango_xft_substitute_changed" 
	pango_xft_font_map_get_type: make routine! [ return: [GType] ] pango-lib "pango_xft_font_map_get_type" 

	pango_xft_font_get_type: make routine! [ return: [GType] ] pango-lib "pango_xft_font_get_type" 

	{ For shape engines
	 }

	;#ifdef PANGO_ENABLE_ENGINE

	pango_xft_font_get_font: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_xft_font_get_font" 
	pango_xft_font_get_display: make routine! [ font [integer!] return: [integer!] ] pango-lib "pango_xft_font_get_display" 

	;#endif { PANGO_ENABLE_ENGINE }


]
;
{************************************************************
** Rebol specific functions
************************************************************}
mini_make-pango-doc: funct [string [string!] size][
	digit: charset [#"0" - #"9"]
	hexdigit: union digit charset "abcdefABCDEF"
	space: charset " ^-"
	no-dec: complement charset "^/*/_#"

	col: copy ""
	txt: copy ""
	text: copy ""
	bold: [
		  "**" (append text "*")
		| "*" copy txt to "*" "*" (append text <b> parse/all txt part-line append text </b>)
	]
	italic: [
		  "//" (append text "/")
		| "/" copy txt to "/" "/" (append text <i> parse/all txt part-line append text </i>)
	]
	underline: [
		  "__" (append text "_")
		| "_" copy txt to "_" "_" (append text <u> parse/all txt part-line append text </u>)
	]
	; color eg. the #green#tree# is a vegetable, the #00FF45#leafs of it# are another
	color: [
		  "##" (append text "#")
		| "#" [copy col 6 hexdigit (col: mold to-issue col) | copy col to "#" ] "#" copy txt to "#" "#"
		  (
			append text append copy <span color=> mold col
			parse/all txt part-line
			append text </span>
		  )
	]
	part-line: [some [
		  bold
		| italic
		| underline
		| color
		| copy txt some no-dec (append text txt)
	]]
	text-line: [some [part-line newline (append text newline)]]
	paragraph: [text-line (emit-size medium text)]
	bull-line: [part-line newline opt [newline (append text newline)] (emit indent 0 - (size * 2.5) head insert text "^-•^-") ]
	bull-list: [some [tab "*" some space bull-line]]
	section: [text-line (emit-size xx-large text)]
	subsect: [text-line (emit-size large text)]
	parts: [ 
		  newline
		| "===" section
		| "---" subsect
		| bull-list
		| paragraph
	]

	emit: func ['word value string] [
		append out reduce [word value 'markup form string]
		clear text
	]
	emit-size: func ['attr data][
		append out reduce ['indent 0 'markup rejoin [{<span size="} attr {">} data </span>]]
		clear text
	]
	out: copy []
	parse/all string [some parts]
	out
]
system/error: make system/error [
	pango-cairo: make object! [
		code: 1010
		type: "Pango cairo Error"
		syntax: ["in text block Near: " :arg1]
	]
]
draw-pango-text: funct [ ; all locals
	"Draws markup text using pango-cairo graphics to a face's image. Returns total size."
	[catch]
	face [object!]
	
	block [block!]
	/local
		; these are "setted" inside rules
		value
	][
	;recycle
	;recycle/off ; avoid crush when using images

	image: face/image: any [face/image make image! (face/size - edge-size? face)]
	image/alpha: 255 ; clear alpha

	cairo-ctx: cairo_create surface: image-to-surface image

	; make clear transparent background (otherwise transparencies are "partial")
	cairo_set_operator cairo-ctx CAIRO_OPERATOR_CLEAR
	cairo_set_source_rgba cairo-ctx 1 1 1 1
	cairo_paint cairo-ctx
	cairo_set_operator cairo-ctx CAIRO_OPERATOR_OVER ; restore default

	cairo_set_source_rgba cairo-ctx 0 0 0 1 ; default color is black

	pango-lay: pango_cairo_create_layout cairo-ctx

	if face/para/wrap? [
		pango_layout_set_width pango-lay image/size/x - (face/para/origin/x + face/para/margin/x) * PANGO_SCALE
	]
	;pango_layout_set_height pango-lay image/size/y - (face/para/origin/y + face/para/margin/y) * PANGO_SCALE
	
	tab-arr: pango_tab_array_new 0 1
	; these 2 tabs are for the bullet list, and should be inside pango-layout block
	pango_tab_array_set_tab tab-arr 0 PANGO_TAB_LEFT face/font/size
	pango_tab_array_set_tab tab-arr 1 PANGO_TAB_LEFT face/font/size * 2.5
	pango_layout_set_tabs pango-lay tab-arr
	
	f.d.: pango_font_description_from_string reform [face/font/name face/font/size]
	pango_layout_set_font_description pango-lay f.d.
	
	point1: face/para/origin
	offset: point1 + face/para/scroll
	cairo_move_to cairo-ctx offset/x offset/y
	
	pen: black
	bgpen: white
	
	left: top: right: bottom: 0
	;
	block: convert-block-words compose/deep block

	fail: [end skip]
	rules: [
		  'INDENT set value opt number! (pango_layout_set_indent pango-lay (any [value 0]) * PANGO_SCALE)
		| 'MARKUP set value string!
			(
				offset: point1 + face/para/scroll
				cairo_move_to cairo-ctx offset/x offset/y
				pango_layout_set_markup pango-lay value -1
				pango_cairo_show_layout cairo-ctx pango-lay
				&w: int-ptr &h: int-ptr
				pango_layout_get_pixel_size pango-lay &w &h
				{
				; only for debug
				;print [&w/value &h/value]
				cairo_set_line_width cairo-ctx 1
				cairo_rectangle cairo-ctx offset/x offset/y &w/value &h/value
				cairo_stroke cairo-ctx
				}
				point1: point1 + (&h/value * 0x1 + 0x1)
				right: max right (point1/x + &w/value)
				bottom: max bottom point1/y
			)
		| 'TEXT set value string!
			(
				bg: ""
				if tuple? bgpen [
					bg: mold copy/part to-hex to-integer to-binary bgpen + 0.0.0.0 6; ;alpha only v.>1.38
					bg: rejoin [{background="} bg {"}]
				]
				offset: point1 + face/para/scroll
				cairo_move_to cairo-ctx offset/x offset/y
				pango_layout_set_markup pango-lay rejoin ["<span " bg ">" value "</span>"] -1
				pango_cairo_show_layout cairo-ctx pango-lay
			)
		| 'MOVE set point1 pair!
			(
				cairo_move_to cairo-ctx point1/x point1/y
				left: min left point1/x
				top: min top point1/y
			)
		| 'FOREGROUND set pen tuple!
			(
				pen: pen + 0.0.0.0
				cairo_set_source_rgba cairo-ctx pen/1 / 255.0 pen/2 / 255.0 pen/3 / 255.0 255 - pen/4 / 255.0
			)
		| 'BACKGROUND set bgpen tuple!
		| 'ELLIPSIZE set value logic! (pango_layout_set_ellipsize pango-lay either value [PANGO_ELLIPSIZE_END][PANGO_ELLIPSIZE_NONE])
		;| tab | tabs | width | height | align | wrap | spacing | justify | font | font-description ; etc.
		;
		;| block! ; just skip
		;| set var word! (go: either none? try [get var] [[]][fail]) go
		| pos: (if not tail? pos [throw make error! reduce ['pango-cairo 'syntax mold pos]]) thru end
	]
	
	parse head block [some rules]
	
	cairo_surface_flush surface
	cairo_surface_finish surface
	image/rgb: white image/alpha: 255 ; same as Rebol-AGG but doesn't seem the better choice
	draw image reduce ['image surface-to-image surface]

	pango_font_description_free f.d.
	pango_tab_array_free tab-arr
	
	; SHOULD I REALLY NEED TO OPEN ANOTHER DLL ONLY TO FREE SOME MEM ALLOCATED BY PANGO ??!!!
	g_object_unref pango-lay
	cairo_destroy cairo-ctx
	cairo_surface_destroy surface

	;recycle/on
	;recycle
	face/para/margin + as-pair (right - left) (bottom - top)
]

{************************************************************
*** example •
************************************************************}
do ; just comment this line to avoid executing example
[
	if system/script/title = "libpango library interface" [;do examples only if script started by us
	
	; doc-ify and styl-ize license
		license: system/license
		replace/all license "^/^/" "##"
		replace/all license "^/" " "
		replace/all license "##" "^/^/"
		replace/case license "REBOL End" "===REBOL End"
		replace/case license "IMPORTANT. READ CAREFULLY." "---*IMPORTANT. READ CAREFULLY.*"
		replace/case license "REBOL grants" "^-* REBOL grants"
		replace/case license "The copy" "^-* The copy"
		replace/case license "You agree" "^-* You agree"
		replace/case license "You may re" "^-* You may re"
		replace/case license "WWW.REBOL.COM" "#blue#_WWW.REBOL.COM_#"
		replace/case/all license "REBOL " "#brown#*REBOL*# "
		replace/case/all license "AGREEMENT" "/*AGREEMENT*/"
		;probe
		markedup-license: mini_make-pango-doc license 12 ; 12 is font size

	width: 390 height: 256

	eat_events: func [{derived from flush_events 12-May-2007 Anton Rolls} /only events [block!] /local evt] [
		events: any [events [move]]
		; Remove the event-port
		remove find system/ports/wait-list system/view/event-port
		
		; Clear the event port of queued events
		while [evt: pick system/view/event-port 1][if not find events evt/type [do evt]] ; fixed by luce80
		
		; Re-add the event-port to the wait-list
		insert system/ports/wait-list system/view/event-port
	]
	insert-event-func func [face event /local siz][
		if event/type = 'resize [
			face: event/face
			siz: face/size - face/user-data/size     ; compute size difference
			face/user-data/size: face/size          ; store new size

			resize-faces face siz
			show face
		]
		event
	]
	resize-faces: func [window siz [pair!]] [
		image-title/size: image-title/size + (siz * 1x0)
		image-title/image: make image! (image-title/size - edge-size? image-title)
		image-pango/size: image-pango/size + (siz * 1x1)
		image-pango/image: make image! (image-pango/size - edge-size? image-pango)
		
		scroller-pango/offset: scroller-pango/offset + (siz * 1x0)
		scroller-pango/resize scroller-pango/size + (siz * 0x1)
		
		;sizer/offset: sizer/offset + (siz * 1x1)
		sizer/offset: win/size - sizer/size ; this flickers less
	]

	win: layout [
		image-title: image white as-pair width 50
			para [] ;;;;;; <<<<<--  MUST create a new para since all faces share the same para !
			feel [
				redraw: func [face action position][
					if action = 'show [
						draw-pango-text face [
							ellipsize true
							markup  {<span foreground="blue">Blue text</span><span foreground="red" background="yellow" font="20"> <b>is</b> <i>cool</i>!</span> and black text is not that bad.}
						]
					]
				]
			]
		across
		image-pango: image white as-pair width height
			effect none ; avoid stretching
			edge [size: 1x1]
			font [name: "Serif" size: 12]
			para [] ;;;;;; <<<<<--  MUST create a new para since all faces share the same para !
			feel [
				redraw: func [face action position /local pre-total visible total][
					if action = 'show [
						visible: face/size/y - second edge-size? face
						pre-total: total: face/pango-size/y
						face/para/scroll/y: min 0 0 - scroller-pango/data * (total - visible)

						face/pango-size: draw-pango-text face markedup-license

						; since total size could have been changed, recalc values
						total: face/pango-size/y
						face/para/scroll/y: min 0 0 - scroller-pango/data * (total - visible)
						scroller-pango/refresh visible total

						; if resizing changed total size and scrolling then redraw
						if pre-total <> total [draw-pango-text face markedup-license]
					]
				]
			]
			with [
				pango-size: 0x0
			]
		pad -8x0
		scroller-pango: scroller image-pango/size/y * 0x1 + 16x0 0.0
			[
				;scrolling is done inside image-pango show
				show image-pango
				eat_events; speedup movement by avoiding following all events
			] 
			with [
				refresh: func [visible total][
					step: 1 / max 1 (total - visible) / 10 ; FIXME: 10 is arbitrary, which is the right value ?
					redrag min (max 1 visible) / (max 1 total) 1

					self
				]
				append init [
					refresh 0 0
				]
			] 
		pad -28x0
			sizer: box 21x21 edge [size: 1x1 effect: 'ibevel color: 128.128.128.50]
				effect [
					draw [
						line-width 1
						pen 255.255.255.50 line 2x20 20x2 line 7x20 20x7 line 12x20 20x12
						pen 128.128.128.50 line 3x20 20x3 line 8x20 20x8 line 13x20 20x13
					]
				]
				feel [
					engage: func [face action event /local root-face] [
						if flag-face? face disabled [exit]
						if action = 'down [face/data: event/offset] 
						if find [over away] action [
							face/offset: face/offset + event/offset - face/data
							root-face: find-window face
							root-face/size: face/offset + face/size
							show root-face
							eat_events; speedup movement by avoiding following all events
						]
					]
				]
	]
	; put sizer on window's bottom-right corner and keep it there
	sizer/user-data: sizer/offset: win/size - sizer/size 
	win/user-data: reduce ['size win/size]

	view/options win 'resize
	
	free pango-cairo-lib
	free pango-lib
	free cairo-lib
	free gobject-lib

	] ; if title
]
