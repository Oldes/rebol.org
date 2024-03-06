Rebol [
	title: "libcairo library interface"
	file: %cairo-h.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 20-05-2019
	version: 0.6.0
	needs: {
		- zlib, libpng12, libcairo shared libraries
	}
	comment: {ONLY A FEW FUNCTIONs TESTED !!!! Use example code to test others.
		See Rebol specific functions at the end.
		
		Tested on W7 with libcairo-2.dll
		version 1.06.04 
		version 1.12.02 (found in "iverilog" program)
		
		other "libcairo-2.dll" libraries may require other dlls. For example the one in "Algodoo" program
		requires also its own freetype.dll and libpng.dll .
		Also set values for "cairo-features.h" to adapt them to your version.
		
		draw-cairo function is far from perfect, it could be improved and fixed ...
		It behaves differently from AGG in a few aspects; some are intentional, some other not ...
	}
	Purpose: "Code to bind cairo graphics shared library to Rebol."
	History: [
		0.1.0 [18-02-2019 "Started"]
		0.6.0 [20-05-2019 "Mature enough"]
	]
	Category: [library graphics]
	library: [
		level: 'advanced
		platform: 'all
		type: 'module
		domain: [graphics external-library]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
		see-also: none
	]
]
; library-support functions
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
		;c: head insert/dup copy [] [. [integer!]] length / 4
		;m: make struct! compose/deep [[save] bin [struct! (r: reduce [c])]] none
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

	lib: switch/default System/version/4 [
		2 [%libcairo.2.dylib]	;OSX
		3 [%libcairo-2.dll]	;Windows
	] [%libcairo.so.2]

	zlib: switch/default System/version/4 [
		2 [%zlib.dylib]	;OSX
		3 [%zlib1.dll]	;Windows
	] [%zlib.so]

	if not exists? zlib [alert "zlib library not found in current folder. libcairo needs it." quit]
	if not attempt [z-lib: load/library zlib] [alert rejoin ["Problems loading " zlib " . Quit"] quit]
	if not attempt [cairo-lib: load/library lib] [alert rejoin ["Problems loading " lib " . Quit"] quit]
;
{ cairo - a vector graphics library with display and print output
*
* Copyright © 2002 University of Southern California
* Copyright © 2005 Red Hat, Inc.
	 *
	 * This library is free software; you can redistribute it and/or
	 * modify it either under the terms of the GNU Lesser General Public
	 * License version 2.1 as published by the Free Software Foundation
	 * (the "LGPL") or, at your option, under the terms of the Mozilla
	 * Public License Version 1.1 (the "MPL"). If you do not alter this
	 * notice, a recipient may use your version of this file under either
	 * the MPL or the LGPL.
	 *
	 * You should have received a copy of the LGPL along with this library
	 * in the file COPYING-LGPL-2.1; if not, write to the Free Software
	 * Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA
	 * You should have received a copy of the MPL along with this library
	 * in the file COPYING-MPL-1.1
	 *
	 * The contents of this file are subject to the Mozilla Public License
	 * Version 1.1 (the "License"); you may not use this file except in
	 * compliance with the License. You may obtain a copy of the License at
	 * http:;www.mozilla.org/MPL/
	 *
	 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY
	 * OF ANY KIND, either express or implied. See the LGPL or the MPL for
	 * the specific language governing rights and limitations.
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is University of Southern
	 * California.
	 *
	 * Contributor(s):
	 *	Carl D. Worth <cworth@cworth.org>
}
{ cairo-features.h }

	CAIRO_HAS_COGL_SURFACE: false
	CAIRO_HAS_DRM_SURFACE: false
	CAIRO_HAS_FC_FONT: true
	CAIRO_HAS_FT_FONT: true
	CAIRO_HAS_GL_SURFACE: false
	CAIRO_HAS_GOBJECT_FUNCTIONS: false
	CAIRO_HAS_IMAGE_SURFACE: true
	CAIRO_HAS_PDF_SURFACE: true
	CAIRO_HAS_PNG_FUNCTIONS: true
	CAIRO_HAS_PS_SURFACE: true
	CAIRO_HAS_RECORDING_SURFACE: true
	CAIRO_HAS_SCRIPT_SURFACE: true
	CAIRO_HAS_SVG_SURFACE: true
	CAIRO_HAS_TEE_SURFACE: false
	CAIRO_HAS_QT_SURFACE: false
	CAIRO_HAS_USER_FONT: true
	CAIRO_HAS_VG_SURFACE: false
	CAIRO_HAS_WIN32_FONT: System/version/4 = 3
	CAIRO_HAS_WIN32_SURFACE: System/version/4 = 3
	CAIRO_HAS_XCB_SURFACE: false
	CAIRO_HAS_XLIB_SURFACE: false
	CAIRO_HAS_XML_SURFACE: false

	CAIRO_HAS_QUARTZ_FONT:
	CAIRO_HAS_QUARTZ_SURFACE: System/version/4 = 2

{ cairo-version.h }

	; this is the version of this header file NOT that of the library. Use cairo_version instead
	{
	CAIRO_VERSION_MAJOR: 1
	CAIRO_VERSION_MINOR: 16
	CAIRO_VERSION_MICRO: 0

	CAIRO_VERSION_ENCODE: func [major minor micro] [((major) * 10000)	+ ((minor) * 100) + ((micro) *  1)]

	CAIRO_VERSION: CAIRO_VERSION_ENCODE CAIRO_VERSION_MAJOR CAIRO_VERSION_MINOR CAIRO_VERSION_MICRO
	
	CAIRO_VERSION_STRING: rejoin ["" CAIRO_VERSION_MAJOR "." CAIRO_VERSION_MINOR "." CAIRO_VERSION_MICRO]
	}

	cairo_version: make routine! [ return: [integer!]] cairo-lib "cairo_version" 
	cairo_version_string: make routine! [ return: [string!] ] cairo-lib "cairo_version_string" 
	
	;print cairo_version
	;print cairo_version_string
	
	cairo_this_version: cairo_version

{*
* cairo_t:
	 *
	 * A #cairo_t contains the current state of the rendering device,
	 * including coordinates of yet to be drawn shapes.
	 *
	 * Memory management of #cairo_t is done with
	 * cairo_reference() and cairo_destroy().
	 *}
	;typedef struct _cairo cairo_t;
{*
* cairo_surface_t:
	 *
	 * A #cairo_surface_t represents an image, either as the destination
	 * of a drawing operation or as source when drawing onto another
	 * surface.  To draw to a #cairo_surface_t, create a cairo context
	 * with the surface as the target, using cairo_create().
	 *
	 * Memory management of #cairo_surface_t is done with
	 * cairo_surface_reference() and cairo_surface_destroy().
	 *}
	;typedef struct _cairo_surface cairo_surface_t;
{*
* cairo_device_t:
	 *
	 * A #cairo_device_t represents the driver interface for drawing
	 * operations to a #cairo_surface_t.  There are different subtypes of
	 * #cairo_device_t for different drawing backends; for example,
	 * cairo_xcb_device_create() creates a device that wraps the connection
	 * to an X Windows System using the XCB library.
	 *
	 * The type of a device can be queried with cairo_device_get_type().
	 *
	 * Memory management of #cairo_device_t is done with
	 * cairo_device_reference() and cairo_device_destroy().
	 *
	 * Since: 1.10
	 *}
	;	typedef struct _cairo_device cairo_device_t;

{*
* cairo_matrix_t:
	 * @xx: xx component of the affine transformation
	 * @yx: yx component of the affine transformation
	 * @xy: xy component of the affine transformation
	 * @yy: yy component of the affine transformation
	 * @x0: X translation component of the affine transformation
	 * @y0: Y translation component of the affine transformation
	 *
	 * A #cairo_matrix_t holds an affine transformation, such as a scale,
	 * rotation, shear, or a combination of those. The transformation of
	 * a point (x, y) is given by:
	 * <programlisting>
	 *     x_new = xx * x + xy * y + x0;
	 *     y_new = yx * x + yy * y + y0;
	 * </programlisting>
	 *}
	cairo_matrix_t: _cairo_matrix: make struct! [
	  xx [double]  yx [double]
	  xy [double]  yy [double]
	  x0 [double]  y0 [double]
	] none ;
{*
* cairo_pattern_t:
	 *
	 * A #cairo_pattern_t represents a source when drawing onto a
	 * surface. There are different subtypes of #cairo_pattern_t,
	 * for different types of sources; for example,
	 * cairo_pattern_create_rgb() creates a pattern for a solid
	 * opaque color.
	 *
	 * Memory management of #cairo_pattern_t is done with
	 * cairo_pattern_reference() and cairo_pattern_destroy().
	 *}
	;typedef struct _cairo_pattern cairo_pattern_t;
{*
* cairo_user_data_key_t:
	 * @unused: not used; ignore.
	 *
	 * #cairo_user_data_key_t is used for attaching user data to cairo
	 * data structures.  The actual contents of the struct is never used,
	 * and there is no need to initialize the object; only the unique
	 * address of a #cairo_data_key_t object is used.  Typically, you
	 * would just use the address of a static #cairo_data_key_t object.
	 *}
	cairo_user_data_key_t: _cairo_user_data_key: make struct! [
	  unused [integer!]
	] none ;
{*
* cairo_status_t:
	 *
	 * #cairo_status_t is used to indicate errors that can occur when
	 * using Cairo. In some cases it is returned directly by functions.
	 * but when using #cairo_t, the last error, if any, is stored in
	 * the context and can be retrieved with cairo_status().
	 *
	 * New entries may be added in future versions.  Use cairo_status_to_string()
	 * to get a human-readable representation of an error message.
	 *}

	CAIRO_STATUS_SUCCESS: 0
	CAIRO_STATUS_NO_MEMORY: 1
	CAIRO_STATUS_INVALID_RESTORE: 2
	CAIRO_STATUS_INVALID_POP_GROUP: 3
	CAIRO_STATUS_NO_CURRENT_POINT: 4
	CAIRO_STATUS_INVALID_MATRIX: 5
	CAIRO_STATUS_INVALID_STATUS: 6
	CAIRO_STATUS_NULL_POINTER: 7
	CAIRO_STATUS_INVALID_STRING: 8
	CAIRO_STATUS_INVALID_PATH_DATA: 9
	CAIRO_STATUS_READ_ERROR: 10
	CAIRO_STATUS_WRITE_ERROR: 11
	CAIRO_STATUS_SURFACE_FINISHED: 12
	CAIRO_STATUS_SURFACE_TYPE_MISMATCH: 13
	CAIRO_STATUS_PATTERN_TYPE_MISMATCH: 14
	CAIRO_STATUS_INVALID_CONTENT: 15
	CAIRO_STATUS_INVALID_FORMAT: 16
	CAIRO_STATUS_INVALID_VISUAL: 17
	CAIRO_STATUS_FILE_NOT_FOUND: 18
	CAIRO_STATUS_INVALID_DASH: 19
	CAIRO_STATUS_INVALID_DSC_COMMENT: 20
	CAIRO_STATUS_INVALID_INDEX: 21
	CAIRO_STATUS_CLIP_NOT_REPRESENTABLE: 22
	CAIRO_STATUS_TEMP_FILE_ERROR: 23
	CAIRO_STATUS_INVALID_STRIDE: 24
	CAIRO_STATUS_FONT_TYPE_MISMATCH: 25
	CAIRO_STATUS_USER_FONT_IMMUTABLE: 26
	CAIRO_STATUS_USER_FONT_ERROR: 27
	CAIRO_STATUS_NEGATIVE_COUNT: 28
	CAIRO_STATUS_INVALID_CLUSTERS: 29
	CAIRO_STATUS_INVALID_SLANT: 30
	CAIRO_STATUS_INVALID_WEIGHT: 31
	CAIRO_STATUS_INVALID_SIZE: 32
	CAIRO_STATUS_USER_FONT_NOT_IMPLEMENTED: 33
	CAIRO_STATUS_DEVICE_TYPE_MISMATCH: 34
	CAIRO_STATUS_DEVICE_ERROR: 35
	CAIRO_STATUS_INVALID_MESH_CONSTRUCTION: 36
	CAIRO_STATUS_DEVICE_FINISHED: 37
	CAIRO_STATUS_JBIG2_GLOBAL_MISSING: 38
	CAIRO_STATUS_PNG_ERROR: 39
	CAIRO_STATUS_FREETYPE_ERROR: 40
	CAIRO_STATUS_WIN32_GDI_ERROR: 41
	CAIRO_STATUS_TAG_ERROR: 42

	CAIRO_STATUS_LAST_STATUS: 43

	cairo_status_t: integer!;
{*
* cairo_content_t:
	 * @CAIRO_CONTENT_COLOR: The surface will hold color content only.
	 * @CAIRO_CONTENT_ALPHA: The surface will hold alpha content only.
	 * @CAIRO_CONTENT_COLOR_ALPHA: The surface will hold color and alpha content.
	 *
	 *}

	CAIRO_CONTENT_COLOR: 4096
	CAIRO_CONTENT_ALPHA: 8192
	CAIRO_CONTENT_COLOR_ALPHA: 12288

	cairo_content_t: integer!;
{*
* cairo_format_t:
	 * @CAIRO_FORMAT_INVALID: no such format exists or is supported.
	 * @CAIRO_FORMAT_ARGB32: each pixel is a 32-bit quantity, with
	 *   alpha in the upper 8 bits, then red, then green, then blue.
	 *   The 32-bit quantities are stored native-endian. Pre-multiplied
	 *   alpha is used. (That is, 50% transparent red is -2139095040,
	 *   not -2130771968.)
	 * @CAIRO_FORMAT_RGB24: each pixel is a 32-bit quantity, with
	 *   the upper 8 bits unused. Red, Green, and Blue are stored
	 *   in the remaining 24 bits in that order.
	 * @CAIRO_FORMAT_A8: each pixel is a 8-bit quantity holding
	 *   an alpha value.
	 * @CAIRO_FORMAT_A1: each pixel is a 1-bit quantity holding
	 *   an alpha value. Pixels are packed together into 32-bit
	 *   quantities. The ordering of the bits matches the
	 *   endianess of the platform. On a big-endian machine, the
	 *   first pixel is in the uppermost bit, on a little-endian
	 *   machine the first pixel is in the least-significant bit.
	 * @CAIRO_FORMAT_RGB16_565: each pixel is a 16-bit quantity
	 *   with red in the upper 5 bits, then green in the middle
	 *   6 bits, and blue in the lower 5 bits.
	 * @CAIRO_FORMAT_RGB30: like RGB24 but with 10bpc. (Since 1.12)
	 *
	 * #cairo_format_t is used to identify the memory format of
	 * image data.
	 *
	 * New entries may be added in future versions.
	 *}

	CAIRO_FORMAT_INVALID: -1
	CAIRO_FORMAT_ARGB32: 0
	CAIRO_FORMAT_RGB24: 1
	CAIRO_FORMAT_A8: 2
	CAIRO_FORMAT_A1: 3
	CAIRO_FORMAT_RGB16_565: 4
	CAIRO_FORMAT_RGB30: 5

	cairo_format_t: integer!;
{*
* cairo_rectangle_int_t:
	 * @x: X coordinate of the left side of the rectangle
	 * @y: Y coordinate of the the top side of the rectangle
	 * @width: width of the rectangle
	 * @height: height of the rectangle
	 *
	 * A data structure for holding a rectangle with integer coordinates.
	 *
	 * Since: 1.10
	 *}

	cairo_rectangle_int_t: _cairo_rectangle_int: make struct! [
	  x [integer!]  y [integer!]
	  width [integer!]  height [integer!]
	] none ;
;
{ Functions for manipulating state objects }
	cairo_create: make routine! [ target [integer!] return: [integer!] ] cairo-lib "cairo_create" 
	cairo_reference: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_reference" 
	cairo_destroy: make routine! [ cr [integer!] ] cairo-lib "cairo_destroy" 
	if cairo_this_version >= 10400 [
	cairo_get_reference_count: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_reference_count" 
	cairo_get_user_data: make routine! [ cr [integer!]
	 key [integer!] return: [integer!] ] cairo-lib "cairo_get_user_data" 
	]
	if cairo_this_version >= 10400 [
	cairo_set_user_data: make routine! [ cr [integer!]
	 key [integer!]
	 user_data [integer!]
	 destroy [integer!] return: [integer!] ] cairo-lib "cairo_set_user_data" 
	]
	cairo_save: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_save" 
	cairo_restore: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_restore" 
	if cairo_this_version >= 10200 [
	cairo_push_group: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_push_group" 
	cairo_push_group_with_content: make routine! [ cr [integer!] content [integer!] return: [integer!] ] cairo-lib "cairo_push_group_with_content" 
	cairo_pop_group: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_pop_group" 
	cairo_pop_group_to_source: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_pop_group_to_source" 
	]
;

{*
* cairo_operator_t:
	 *
	 * #cairo_operator_t is used to set the compositing operator for all cairo
	 * drawing operations.
	 *
	 * The default operator is %CAIRO_OPERATOR_OVER.
	 *
	 * For a more detailed explanation of the effects of each operator, including
	 * the mathematical definitions, see
	 * <ulink url="http:;cairographics.org/operators/">http:;cairographics.org/operators/</ulink>.
	 *}

	CAIRO_OPERATOR_CLEAR: 0

	CAIRO_OPERATOR_SOURCE: 1
	CAIRO_OPERATOR_OVER: 2
	CAIRO_OPERATOR_IN: 3
	CAIRO_OPERATOR_OUT: 4
	CAIRO_OPERATOR_ATOP: 5

	CAIRO_OPERATOR_DEST: 6
	CAIRO_OPERATOR_DEST_OVER: 7
	CAIRO_OPERATOR_DEST_IN: 8
	CAIRO_OPERATOR_DEST_OUT: 9
	CAIRO_OPERATOR_DEST_ATOP: 10

	CAIRO_OPERATOR_XOR: 11
	CAIRO_OPERATOR_ADD: 12
	CAIRO_OPERATOR_SATURATE: 13

	CAIRO_OPERATOR_MULTIPLY: 14
	CAIRO_OPERATOR_SCREEN: 15
	CAIRO_OPERATOR_OVERLAY: 16
	CAIRO_OPERATOR_DARKEN: 17
	CAIRO_OPERATOR_LIGHTEN: 18
	CAIRO_OPERATOR_COLOR_DODGE: 19
	CAIRO_OPERATOR_COLOR_BURN: 20
	CAIRO_OPERATOR_HARD_LIGHT: 21
	CAIRO_OPERATOR_SOFT_LIGHT: 22
	CAIRO_OPERATOR_DIFFERENCE: 23
	CAIRO_OPERATOR_EXCLUSION: 24
	CAIRO_OPERATOR_HSL_HUE: 25
	CAIRO_OPERATOR_HSL_SATURATION: 26
	CAIRO_OPERATOR_HSL_COLOR: 27

	CAIRO_OPERATOR_HSL_LUMINOSITY: 28

	cairo_operator_t: integer!;

	cairo_set_operator: make routine! [ cr [integer!] op [integer!] return: [integer!] ] cairo-lib "cairo_set_operator" 
	cairo_set_source: make routine! [ cr [integer!] source [integer!] return: [integer!] ] cairo-lib "cairo_set_source" 
	cairo_set_source_rgb: make routine! [ cr [integer!] red [double] green [double] blue [double] return: [integer!] ] cairo-lib "cairo_set_source_rgb" 
	cairo_set_source_rgba: make routine! [ cr [integer!]
	 red [double] green [double] blue [double]
	 alpha [double] return: [integer!] ] cairo-lib "cairo_set_source_rgba" 

	cairo_set_source_surface: make routine! [ cr [integer!]
	 surface [integer!]
	 x [double]
	 y [double] return: [integer!] ] cairo-lib "cairo_set_source_surface" 

	cairo_set_tolerance: make routine! [ cr [integer!] tolerance [double] return: [integer!] ] cairo-lib "cairo_set_tolerance" 

{*
* cairo_antialias_t:
	 * @CAIRO_ANTIALIAS_DEFAULT: Use the default antialiasing for
	 *   the subsystem and target device
	 * @CAIRO_ANTIALIAS_NONE: Use a bilevel alpha mask
	 * @CAIRO_ANTIALIAS_GRAY: Perform single-color antialiasing (using
	 *  shades of gray for black text on a white background, for example).
	 * @CAIRO_ANTIALIAS_SUBPIXEL: Perform antialiasing by taking
	 *  advantage of the order of subpixel elements on devices
	 *  such as LCD panels
	 *
	 * Specifies the type of antialiasing to do when rendering text or shapes.
	 *}

	CAIRO_ANTIALIAS_DEFAULT: 0
	CAIRO_ANTIALIAS_NONE: 1
	CAIRO_ANTIALIAS_GRAY: 2
	CAIRO_ANTIALIAS_SUBPIXEL: 3

	 { hints }
	CAIRO_ANTIALIAS_FAST: 4
	CAIRO_ANTIALIAS_GOOD: 5
	CAIRO_ANTIALIAS_BEST: 6

	cairo_antialias_t: integer!;

	cairo_set_antialias: make routine! [ cr [integer!] antialias [integer!] return: [integer!] ] cairo-lib "cairo_set_antialias" 
{*
* cairo_fill_rule_t:
	 * @CAIRO_FILL_RULE_WINDING: If the path crosses the ray from
	 * left-to-right, counts +1. If the path crosses the ray
	 * from right to left, counts -1. (Left and right are determined
	 * from the perspective of looking along the ray from the starting
	 * point.) If the total count is non-zero, the point will be filled.
	 * @CAIRO_FILL_RULE_EVEN_ODD: Counts the total number of
	 * intersections, without regard to the orientation of the contour. If
	 * the total number of intersections is odd, the point will be
	 * filled.
	 *
	 * The default fill rule is %CAIRO_FILL_RULE_WINDING.
	 *
	 * New entries may be added in future versions.
	 *}

	CAIRO_FILL_RULE_WINDING: 0
	CAIRO_FILL_RULE_EVEN_ODD: 1

	cairo_fill_rule_t: integer!;

	cairo_set_fill_rule: make routine! [ cr [integer!] fill_rule [integer!] return: [integer!] ] cairo-lib "cairo_set_fill_rule" 
	cairo_set_line_width: make routine! [ cr [integer!] width [double] return: [integer!] ] cairo-lib "cairo_set_line_width" 
{*
* cairo_line_cap_t:
	 * @CAIRO_LINE_CAP_BUTT: start(stop) the line exactly at the start(end) point
	 * @CAIRO_LINE_CAP_ROUND: use a round ending, the center of the circle is the end point
	 * @CAIRO_LINE_CAP_SQUARE: use squared ending, the center of the square is the end point
	 *
	 * Specifies how to render the endpoints of the path when stroking.
	 *
	 * The default line cap style is %CAIRO_LINE_CAP_BUTT.
	 *}

	CAIRO_LINE_CAP_BUTT: 0
	CAIRO_LINE_CAP_ROUND: 1
	CAIRO_LINE_CAP_SQUARE: 2

	cairo_line_cap_t: integer!;

	cairo_set_line_cap: make routine! [ cr [integer!] line_cap [integer!] return: [integer!] ] cairo-lib "cairo_set_line_cap" 
{*
* cairo_line_join_t:
	 * @CAIRO_LINE_JOIN_MITER: use a sharp (angled) corner, see
	 * cairo_set_miter_limit()
	 * @CAIRO_LINE_JOIN_ROUND: use a rounded join, the center of the circle is the
	 * joint point
	 * @CAIRO_LINE_JOIN_BEVEL: use a cut-off join, the join is cut off at half
	 * the line width from the joint point
	 *
	 * Specifies how to render the junction of two lines when stroking.
	 *
	 * The default line join style is %CAIRO_LINE_JOIN_MITER.
	 *}

	CAIRO_LINE_JOIN_MITER: 0
	CAIRO_LINE_JOIN_ROUND: 1
	CAIRO_LINE_JOIN_BEVEL: 2

	cairo_line_join_t: integer!;

	cairo_set_line_join: make routine! [ cr [integer!] line_join [integer!] return: [integer!] ] cairo-lib "cairo_set_line_join" 
;
; dash, miter , trasform, matrix, device
	cairo_set_dash: make routine! [ cr [integer!]
	 dashes [struct![]]
	 num_dashes [integer!]
	 offset [double] return: [integer!] ] cairo-lib "cairo_set_dash" 

	cairo_set_miter_limit: make routine! [ cr [integer!] limit [double] return: [integer!] ] cairo-lib "cairo_set_miter_limit" 
	cairo_translate: make routine! [ cr [integer!] tx [double] ty [double] return: [integer!] ] cairo-lib "cairo_translate" 
	cairo_scale: make routine! [ cr [integer!] sx [double] sy [double] return: [integer!] ] cairo-lib "cairo_scale" 
	cairo_rotate: make routine! [ cr [integer!] angle [double] return: [integer!] ] cairo-lib "cairo_rotate" 
	cairo_transform: make routine! [ cr [integer!] matrix [struct![]] ] cairo-lib "cairo_transform" 
	;cairo_set_matrix: make routine! [ cr [integer!] matrix [binary!] ] cairo-lib "cairo_set_matrix" 
	;cairo_set_matrix: make routine! probe compose/deep [ cr [integer!] matrix [struct! [(first cairo_matrix_t)]] ] cairo-lib "cairo_set_matrix" 
	cairo_set_matrix: make routine! [ cr [integer!] matrix [struct![]] ] cairo-lib "cairo_set_matrix" 
	cairo_identity_matrix: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_identity_matrix" 
	cairo_user_to_device: make routine! [ cr [integer!] x [integer!] y [integer!] return: [integer!] ] cairo-lib "cairo_user_to_device" 
	cairo_user_to_device_distance: make routine! [ cr [integer!] dx [integer!] dy [integer!] return: [integer!] ] cairo-lib "cairo_user_to_device_distance" 
	cairo_device_to_user: make routine! [ cr [integer!] x [integer!] y [integer!] return: [integer!] ] cairo-lib "cairo_device_to_user" 
	cairo_device_to_user_distance: make routine! [ cr [integer!] dx [integer!] dy [integer!] return: [integer!] ] cairo-lib "cairo_device_to_user_distance" 

{ Path creation functions }
	cairo_new_path: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_new_path" 
	cairo_move_to: make routine! [ cr [integer!] x [double] y [double] return: [integer!] ] cairo-lib "cairo_move_to" 
	if cairo_this_version >= 10200 [
	cairo_new_sub_path: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_new_sub_path" 
	]
	cairo_line_to: make routine! [ cr [integer!] x [double] y [double] return: [integer!] ] cairo-lib "cairo_line_to" 
	cairo_curve_to: make routine! [ cr [integer!]
	 x1 [double] y1 [double]
	 x2 [double] y2 [double]
	 x3 [double] y3 [double] return: [integer!] ] cairo-lib "cairo_curve_to" 

	cairo_arc: make routine! [ cr [integer!]
	 xc [double] yc [double]
	 radius [double]
	 angle1 [double] angle2 [double] return: [integer!] ] cairo-lib "cairo_arc" 

	cairo_arc_negative: make routine! [ cr [integer!]
	 xc [double] yc [double]
	 radius [double]
	 angle1 [double] angle2 [double] return: [integer!] ] cairo-lib "cairo_arc_negative" 

	{ XXX: NYI }

	if cairo_this_version >= 11300 [;11000
	cairo_arc_to: make routine! [ cr [integer!]
	 x1 [double] y1 [double]
	 x2 [double] y2 [double]
	 radius [double] return: [integer!] ] cairo-lib "cairo_arc_to" 
	]

	cairo_rel_move_to: make routine! [ cr [integer!] dx [double] dy [double] return: [integer!] ] cairo-lib "cairo_rel_move_to" 
	cairo_rel_line_to: make routine! [ cr [integer!] dx [double] dy [double] return: [integer!] ] cairo-lib "cairo_rel_line_to" 

	cairo_rel_curve_to: make routine! [ cr [integer!]
	 dx1 [double] dy1 [double]
	 dx2 [double] dy2 [double]
	 dx3 [double] dy3 [double] return: [integer!] ] cairo-lib "cairo_rel_curve_to" 

	cairo_rectangle: make routine! [ cr [integer!]
	 x [double] y [double]
	 width [double] height [double] return: [integer!] ] cairo-lib "cairo_rectangle" 

	{ XXX: NYI }
	if cairo_this_version >= 11300 [;11000
	cairo_stroke_to_path: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_stroke_to_path" 
	]
	cairo_close_path: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_close_path" 
	if cairo_this_version >= 10600 [
	cairo_path_extents: make routine! [ cr [integer!]
	 x1 [integer!] y1 [integer!]
	 x2 [integer!] y2 [integer!] return: [integer!] ] cairo-lib "cairo_path_extents" 
	]
{ Painting functions }
	cairo_paint: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_paint" 
	cairo_paint_with_alpha: make routine! [ cr [integer!]
	 alpha [double] return: [integer!] ] cairo-lib "cairo_paint_with_alpha" 

	cairo_mask: make routine! [ cr [integer!]
	 pattern [integer!] return: [integer!] ] cairo-lib "cairo_mask" 

	cairo_mask_surface: make routine! [ cr [integer!]
	 surface [integer!]
	 surface_x [double]
	 surface_y [double] return: [integer!] ] cairo-lib "cairo_mask_surface" 

	cairo_stroke: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_stroke" 
	cairo_stroke_preserve: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_stroke_preserve" 
	cairo_fill: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_fill" 
	cairo_fill_preserve: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_fill_preserve" 
	cairo_copy_page: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_copy_page" 
	cairo_show_page: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_show_page" 

{ Insideness testing }
	cairo_in_stroke: make routine! [ cr [integer!] x [double] y [double] return: [integer!] ] cairo-lib "cairo_in_stroke" 
	cairo_in_fill: make routine! [ cr [integer!] x [double] y [double] return: [double] ] cairo-lib "cairo_in_fill" 
	if cairo_this_version >= 11000 [
	cairo_in_clip: make routine! [ cr [integer!] x [double] y [double] return: [double] ] cairo-lib "cairo_in_clip" 
	]

{ Rectangular extents }
	cairo_stroke_extents: make routine! [ cr [integer!]
	 x1 [integer!] y1 [integer!]
	 x2 [integer!] y2 [integer!] return: [integer!] ] cairo-lib "cairo_stroke_extents" 

	cairo_fill_extents: make routine! [ cr [integer!]
	 x1 [integer!] y1 [integer!]
	 x2 [integer!] y2 [integer!] return: [integer!] ] cairo-lib "cairo_fill_extents" 

{ Clipping }
	cairo_reset_clip: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_reset_clip" 
	cairo_clip: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_clip" 
	cairo_clip_preserve: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_clip_preserve" 
	if cairo_this_version >= 10400 [
	cairo_clip_extents: make routine! [ cr [integer!]
	 x1 [struct![]] y1 [struct![]]
	 x2 [struct![]] y2 [struct![]] return: [integer!] ] cairo-lib "cairo_clip_extents" 
	]
{*
* cairo_rectangle_t:
	 * @x: X coordinate of the left side of the rectangle
	 * @y: Y coordinate of the the top side of the rectangle
	 * @width: width of the rectangle
	 * @height: height of the rectangle
	 *
	 * A data structure for holding a rectangle.
	 *
	 * Since: 1.4
	 *}
	cairo_rectangle_t: _cairo_rectangle: make struct! [
		  x [double]  y [double]  width [double]  height [double]
	] none ;
{*
* cairo_rectangle_list_t:
	 * @status: Error status of the rectangle list
	 * @rectangles: Array containing the rectangles
	 * @num_rectangles: Number of rectangles in this list
	 * 
	 * A data structure for holding a dynamically allocated
	 * array of rectangles.
	 *
	 * Since: 1.4
	 *}
	cairo_rectangle_list_t: _cairo_rectangle_list: make struct! [
	  status [cairo_status_t]
	  rectangles [integer!]
	  num_rectangles [integer!]
	] none ;
;
; rectangle_list, tag
	if cairo_this_version >= 10400 [
	cairo_copy_clip_rectangle_list: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_copy_clip_rectangle_list" 
	cairo_rectangle_list_destroy: make routine! [ rectangle_list [integer!] return: [integer!] ] cairo-lib "cairo_rectangle_list_destroy" 
	]

	{ Logical structure tagging functions }
	CAIRO_TAG_DEST: "cairo.dest"
	CAIRO_TAG_LINK: "Link"

	if cairo_this_version >= 11600 [
	cairo_tag_begin: make routine! [ cr [integer!] tag_name [string!] attributes [string!] return: [integer!] ] cairo-lib "cairo_tag_begin" 
	cairo_tag_end: make routine! [ cr [integer!] tag_name [string!] return: [integer!] ] cairo-lib "cairo_tag_end" 
	]
;
{ Font/Text functions }
{*
* cairo_glyph_t:
	 * @index: glyph index in the font. The exact interpretation of the
	 *      glyph index depends on the font technology being used.
	 * @x: the offset in the X direction between the origin used for
	 *     drawing or measuring the string and the origin of this glyph.
	 * @y: the offset in the Y direction between the origin used for
	 *     drawing or measuring the string and the origin of this glyph.
	 *
	 * Note that the offsets given by @x and @y are not cumulative. When
	 * drawing or measuring text, each glyph is individually positioned
	 * with respect to the overall origin
	 *}
	cairo_glyph_t: make struct! [
	  index [integer!]
	  x [double]
	  y [double]
	] none ;

	if cairo_this_version >= 10800 [
	cairo_glyph_allocate: make routine! [ num_glyphs [integer!] return: [integer!] ] cairo-lib "cairo_glyph_allocate" 
	cairo_glyph_free: make routine! [ glyphs [integer!] return: [integer!] ] cairo-lib "cairo_glyph_free" 
	]

{*
* cairo_text_cluster_t:
	 * @num_bytes: the number of bytes of UTF-8 text covered by cluster
	 * @num_glyphs: the number of glyphs covered by cluster
	 *
	 * See cairo_show_text_glyphs() for how clusters are used in advanced
	 * text operations.
	 *
	 * Since: 1.8
	 *}
	cairo_text_cluster_t: make struct! [
	  num_bytes [integer!]
	  num_glyphs [integer!]
	] none ;

	if cairo_this_version >= 10800 [
	cairo_text_cluster_allocate: make routine! [ num_clusters [integer!] return: [integer!] ] cairo-lib "cairo_text_cluster_allocate" 
	cairo_text_cluster_free: make routine! [ clusters [integer!] return: [integer!] ] cairo-lib "cairo_text_cluster_free" 
	]

{*
* cairo_text_cluster_flags_t:
	 * @CAIRO_TEXT_CLUSTER_FLAG_BACKWARD: The clusters in the cluster array
	 * map to glyphs in the glyph array from end to start.
	 *
	 * Specifies properties of a text cluster mapping.
	 *
	 * Since: 1.8
	 *}

	CAIRO_TEXT_CLUSTER_FLAG_BACKWARD: 1

	cairo_text_cluster_flags_t: integer!;
{*
* cairo_text_extents_t:
	 * @x_bearing: the horizontal distance from the origin to the
	 *   leftmost part of the glyphs as drawn. Positive if the
	 *   glyphs lie entirely to the right of the origin.
	 * @y_bearing: the vertical distance from the origin to the
	 *   topmost part of the glyphs as drawn. Positive only if the
	 *   glyphs lie completely below the origin; will usually be
	 *   negative.
	 * @width: width of the glyphs as drawn
	 * @height: height of the glyphs as drawn
	 * @x_advance:distance to advance in the X direction
	 *    after drawing these glyphs
	 * @y_advance: distance to advance in the Y direction
	 *   after drawing these glyphs. Will typically be zero except
	 *   for vertical text layout as found in East-Asian languages.
	 *
	 *}
	cairo_text_extents_t: make struct! [
	  x_bearing [double]
	  y_bearing [double]
	  width [double]
	  height [double]
	  x_advance [double]
	  y_advance [double]
	] none ;
{*
* cairo_font_extents_t:
	 * @ascent: the distance that the font extends above the baseline.
	 *          Note that this is not always exactly equal to the maximum
	 *          of the extents of all the glyphs in the font, but rather
	 *          is picked to express the font designer's intent as to
	 *          how the font should align with elements above it.
	 * @descent: the distance that the font extends below the baseline.
	 *           This value is positive for typical fonts that include
	 *           portions below the baseline. Note that this is not always
	 *           exactly equal to the maximum of the extents of all the
	 *           glyphs in the font, but rather is picked to express the
	 *           font designer's intent as to how the the font should
	 *           align with elements below it.
	 * @height: the recommended vertical distance between baselines when
	 *          setting consecutive lines of text with the font. This
	 *          is greater than @ascent+@descent by a
	 *          quantity known as the <firstterm>line spacing</firstterm>
	 *          or <firstterm>external leading</firstterm>. When space
	 *          is at a premium, most fonts can be set with only
	 *          a distance of @ascent+@descent between lines.
	 * @max_x_advance: the maximum distance in the X direction that
	 *         the the origin is advanced for any glyph in the font.
	 * @max_y_advance: the maximum distance in the Y direction that
	 *         the the origin is advanced for any glyph in the font.
	 *         this will be zero for normal fonts used for horizontal
	 *         writing. (The scripts of East Asia are sometimes written
	 *         vertically.)
	 *
	 *}
	cairo_font_extents_t: make struct! [
	  ascent [double]
	  descent [double]
	  height [double]
	  max_x_advance [double]
	  max_y_advance [double]
	] none ;
{*
* cairo_font_slant_t:
	 * @CAIRO_FONT_SLANT_NORMAL: Upright font style
	 * @CAIRO_FONT_SLANT_ITALIC: Italic font style
	 * @CAIRO_FONT_SLANT_OBLIQUE: Oblique font style
	 *
	 * Specifies variants of a font face based on their slant.
	 *}

	CAIRO_FONT_SLANT_NORMAL: 0
	CAIRO_FONT_SLANT_ITALIC: 1
	CAIRO_FONT_SLANT_OBLIQUE: 2

	cairo_font_slant_t: integer!;
{*
* cairo_font_weight_t:
	 * @CAIRO_FONT_WEIGHT_NORMAL: Normal font weight
	 * @CAIRO_FONT_WEIGHT_BOLD: Bold font weight
	 *
	 * Specifies variants of a font face based on their weight.
	 *}

	CAIRO_FONT_WEIGHT_NORMAL: 0
	CAIRO_FONT_WEIGHT_BOLD: 1

	cairo_font_weight_t: integer!;
{*
* cairo_subpixel_order_t:
	 * @CAIRO_SUBPIXEL_ORDER_DEFAULT: Use the default subpixel order for
	 *   for the target device
	 * @CAIRO_SUBPIXEL_ORDER_RGB: Subpixel elements are arranged horizontally
	 *   with red at the left
	 * @CAIRO_SUBPIXEL_ORDER_BGR:  Subpixel elements are arranged horizontally
	 *   with blue at the left
	 * @CAIRO_SUBPIXEL_ORDER_VRGB: Subpixel elements are arranged vertically
	 *   with red at the top
	 * @CAIRO_SUBPIXEL_ORDER_VBGR: Subpixel elements are arranged vertically
	 *   with blue at the top
	 *
	 * The subpixel order specifies the order of color elements within
	 * each pixel on the display device when rendering with an
	 * antialiasing mode of %CAIRO_ANTIALIAS_SUBPIXEL.
	 *}

	CAIRO_SUBPIXEL_ORDER_DEFAULT: 0
	CAIRO_SUBPIXEL_ORDER_RGB: 1
	CAIRO_SUBPIXEL_ORDER_BGR: 2
	CAIRO_SUBPIXEL_ORDER_VRGB: 3
	CAIRO_SUBPIXEL_ORDER_VBGR: 4

	cairo_subpixel_order_t: integer!;
{*
* cairo_hint_style_t:
	 * @CAIRO_HINT_STYLE_DEFAULT: Use the default hint style for
	 *   font backend and target device
	 * @CAIRO_HINT_STYLE_NONE: Do not hint outlines
	 * @CAIRO_HINT_STYLE_SLIGHT: Hint outlines slightly to improve
	 *   contrast while retaining good fidelity to the original
	 *   shapes.
	 * @CAIRO_HINT_STYLE_MEDIUM: Hint outlines with medium strength
	 *   giving a compromise between fidelity to the original shapes
	 *   and contrast
	 * @CAIRO_HINT_STYLE_FULL: Hint outlines to maximize contrast
	 *
	 *}

	CAIRO_HINT_STYLE_DEFAULT: 0
	CAIRO_HINT_STYLE_NONE: 1
	CAIRO_HINT_STYLE_SLIGHT: 2
	CAIRO_HINT_STYLE_MEDIUM: 3
	CAIRO_HINT_STYLE_FULL: 4

	cairo_hint_style_t: integer!;
{*
* cairo_hint_metrics_t:
	 * @CAIRO_HINT_METRICS_DEFAULT: Hint metrics in the default
	 *  manner for the font backend and target device
	 * @CAIRO_HINT_METRICS_OFF: Do not hint font metrics
	 * @CAIRO_HINT_METRICS_ON: Hint font metrics
	 *
	 *}

	CAIRO_HINT_METRICS_DEFAULT: 0
	CAIRO_HINT_METRICS_OFF: 1
	CAIRO_HINT_METRICS_ON: 2

	cairo_hint_metrics_t: integer!;
{*
* cairo_font_options_t:
	 *
	 * An opaque structure holding all options that are used when
	 * rendering fonts.
	 *
	 *}
	;typedef struct _cairo_font_options cairo_font_options_t;

	cairo_font_options_create: make routine! [ return: [integer!] ] cairo-lib "cairo_font_options_create" 
	cairo_font_options_copy: make routine! [ original [integer!] return: [integer!] ] cairo-lib "cairo_font_options_copy" 
	cairo_font_options_destroy: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_destroy" 
	cairo_font_options_status: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_status" 
	cairo_font_options_merge: make routine! [ options [integer!]
	 other [integer!] return: [integer!] ] cairo-lib "cairo_font_options_merge" 

	cairo_font_options_equal: make routine! [ options [integer!]
	 other [integer!] return: [integer!] ] cairo-lib "cairo_font_options_equal" 

	cairo_font_options_hash: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_hash" 
	cairo_font_options_set_antialias: make routine! [ options [integer!]
	 antialias [integer!] return: [integer!] ] cairo-lib "cairo_font_options_set_antialias" 

	cairo_font_options_get_antialias: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_get_antialias" 
	cairo_font_options_set_subpixel_order: make routine! [ options [integer!]
	 subpixel_order [integer!] return: [integer!] ] cairo-lib "cairo_font_options_set_subpixel_order" 

	cairo_font_options_get_subpixel_order: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_get_subpixel_order" 
	cairo_font_options_set_hint_style: make routine! [ options [integer!]
	 hint_style [integer!] return: [integer!] ] cairo-lib "cairo_font_options_set_hint_style" 

	cairo_font_options_get_hint_style: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_get_hint_style" 
	cairo_font_options_set_hint_metrics: make routine! [ options [integer!]
	 hint_metrics [integer!] return: [integer!] ] cairo-lib "cairo_font_options_set_hint_metrics" 

	cairo_font_options_get_hint_metrics: make routine! [ options [integer!] return: [integer!] ] cairo-lib "cairo_font_options_get_hint_metrics" 
	
	if cairo_this_version >= 11600 [
	cairo_font_options_get_variations: make routine! [ options [integer!] return: [string!] ] cairo-lib "cairo_font_options_get_variations" 
	cairo_font_options_set_variations: make routine! [ options [integer!]
	 variations [string!] return: [integer!] ] cairo-lib "cairo_font_options_set_variations" 
	]
	{ This interface is for dealing with text as text, not caring about the
	   font object inside the the cairo_t. }

	cairo_select_font_face: make routine! [ cr [integer!]
	 family [string!]
	 slant [cairo_font_slant_t]
	 weight [cairo_font_weight_t] return: [integer!] ] cairo-lib "cairo_select_font_face" 

	cairo_set_font_size: make routine! [ cr [integer!] size [double] return: [integer!] ] cairo-lib "cairo_set_font_size" 
	cairo_set_font_matrix: make routine! [ cr [integer!]
	 matrix [struct! []] return: [integer!] ] cairo-lib "cairo_set_font_matrix" 

	cairo_get_font_matrix: make routine! [ cr [integer!]
	 matrix [struct! []] return: [integer!] ] cairo-lib "cairo_get_font_matrix" 

	cairo_set_font_options: make routine! [ cr [integer!]
	 options [integer!] return: [integer!] ] cairo-lib "cairo_set_font_options" 

	cairo_get_font_options: make routine! [ cr [integer!]
	 options [integer!] return: [integer!] ] cairo-lib "cairo_get_font_options" 

	cairo_set_font_face: make routine! [ cr [integer!] font_face [integer!] return: [integer!] ] cairo-lib "cairo_set_font_face" 
	cairo_get_font_face: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_font_face" 
	if cairo_this_version >= 10200 [
	cairo_set_scaled_font: make routine! [ cr [integer!]
	 scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_set_scaled_font" 
	]
	if cairo_this_version >= 10400 [
	cairo_get_scaled_font: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_scaled_font" 
	]
	cairo_show_text: make routine! [ cr [integer!] utf8 [string!] return: [integer!] ] cairo-lib "cairo_show_text" 
	cairo_show_glyphs: make routine! [ cr [integer!] glyphs [integer!] num_glyphs [integer!] return: [integer!] ] cairo-lib "cairo_show_glyphs" 

	if cairo_this_version >= 10800 [
	cairo_show_text_glyphs: make routine! [ cr [integer!]
	 utf8 [string!]
	 utf8_len [integer!]
	 glyphs [integer!]
	 num_glyphs [integer!]
	 clusters [integer!]
	 num_clusters [integer!]
	 cluster_flags [integer!] return: [integer!] ] cairo-lib "cairo_show_text_glyphs" 
	]

	cairo_text_path: make routine! [ cr [integer!] utf8 [string!] return: [integer!] ] cairo-lib "cairo_text_path" 
	cairo_glyph_path: make routine! [ cr [integer!] glyphs [integer!] num_glyphs [integer!] return: [integer!] ] cairo-lib "cairo_glyph_path" 
	cairo_text_extents: make routine! [ cr [integer!]
	 utf8 [string!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_text_extents" 

	cairo_glyph_extents: make routine! [ cr [integer!]
	 glyphs [integer!]
	 num_glyphs [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_glyph_extents" 

	cairo_font_extents: make routine! [ cr [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_font_extents" 

	{ Generic identifier for a font style }

	cairo_font_face_reference: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_font_face_reference" 
	cairo_font_face_destroy: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_font_face_destroy" 
	if cairo_this_version >= 10400 [
	cairo_font_face_get_reference_count: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_font_face_get_reference_count" 
	]
	cairo_font_face_status: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_font_face_status" 
{*
* cairo_font_type_t:
	 * @CAIRO_FONT_TYPE_TOY: The font was created using cairo's toy font api
	 * @CAIRO_FONT_TYPE_FT: The font is of type FreeType
	 * @CAIRO_FONT_TYPE_WIN32: The font is of type Win32
	 * @CAIRO_FONT_TYPE_QUARTZ: The font is of type Quartz (Since: 1.6)
	 * @CAIRO_FONT_TYPE_USER: The font was create using cairo's user font api (Since: 1.8)
	 *
	 * Since: 1.2
	 *}

	CAIRO_FONT_TYPE_TOY: 0
	CAIRO_FONT_TYPE_FT: 1
	CAIRO_FONT_TYPE_WIN32: 2
	CAIRO_FONT_TYPE_QUARTZ: 3
	CAIRO_FONT_TYPE_USER: 4

	cairo_font_type_t: integer!;
;
; font functions
	if cairo_this_version >= 10200 [
	cairo_font_face_get_type: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_font_face_get_type" 
	]
	cairo_font_face_get_user_data: make routine! [ font_face [integer!]
	 key [integer!] return: [integer!] ] cairo-lib "cairo_font_face_get_user_data" 

	cairo_font_face_set_user_data: make routine! [ font_face [integer!]
	 key [integer!]
	 user_data [integer!]
	 destroy [integer!] return: [integer!] ] cairo-lib "cairo_font_face_set_user_data" 

	{ Portable interface to general font features. }

	cairo_scaled_font_create: make routine! [ font_face [integer!]
	 font_matrix [integer!]
	 ctm [integer!]
	 options [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_create" 

	cairo_scaled_font_reference: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_reference" 
	cairo_scaled_font_destroy: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_destroy" 
	cairo_scaled_font_status: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_status" 
	if cairo_this_version >= 10400 [
	cairo_scaled_font_get_reference_count: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_reference_count" 
	cairo_scaled_font_get_user_data: make routine! [ scaled_font [integer!]
	 key [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_user_data" 

	cairo_scaled_font_set_user_data: make routine! [ scaled_font [integer!]
	 key [integer!]
	 user_data [integer!]
	 destroy [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_set_user_data" 
	]
	cairo_scaled_font_extents: make routine! [ scaled_font [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_extents" 

	cairo_scaled_font_glyph_extents: make routine! [ scaled_font [integer!]
	 glyphs [integer!]
	 num_glyphs [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_glyph_extents" 

	if cairo_this_version >= 10800 [
	cairo_scaled_font_text_to_glyphs: make routine! [ scaled_font [integer!]
	 x [double]
	 y [double]
	 utf8 [string!]
	 utf8_len [integer!]
	 glyphs [struct! []]
	 num_glyphs [integer!]
	 clusters [struct! []]
	 num_clusters [integer!]
	 cluster_flags [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_text_to_glyphs" 
	]

	if cairo_this_version >= 10200 [
	cairo_scaled_font_get_type: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_type" 
	cairo_scaled_font_text_extents: make routine! [ scaled_font [integer!]
	 utf8 [string!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_text_extents" 

	cairo_scaled_font_get_font_face: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_font_face" 
	cairo_scaled_font_get_font_matrix: make routine! [ scaled_font [integer!]
	 font_matrix [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_font_matrix" 

	cairo_scaled_font_get_font_options: make routine! [ scaled_font [integer!]
	 options [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_font_options" 
	cairo_scaled_font_get_ctm: make routine! [ scaled_font [integer!]
	 ctm [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_ctm" 
	]
	if cairo_this_version >= 10800 [
	cairo_scaled_font_get_scale_matrix: make routine! [ scaled_font [integer!]
	 scale_matrix [integer!] return: [integer!] ] cairo-lib "cairo_scaled_font_get_scale_matrix" 
	]


{ Toy fonts }
	if cairo_this_version >= 10800 [
	cairo_toy_font_face_create: make routine! [ family [string!]
	 slant [string!]
	 weight [string!] return: [integer!] ] cairo-lib "cairo_toy_font_face_create" 

	cairo_toy_font_face_get_family: make routine! [ font_face [integer!] return: [string!] ] cairo-lib "cairo_toy_font_face_get_family" 
	cairo_toy_font_face_get_slant: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_toy_font_face_get_slant" 
	cairo_toy_font_face_get_weight: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_toy_font_face_get_weight" 
	]

{ User fonts }
	if cairo_this_version >= 11000 [
	cairo_user_font_face_create: make routine! [ return: [integer!] ] cairo-lib "cairo_user_font_face_create" 
	]

{ User-font method signatures }

{ User-font method setters }
	if cairo_this_version >= 10800 [
	cairo_user_font_face_set_init_func: make routine! [ font_face [integer!]
	 init_func [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_set_init_func" 

	cairo_user_font_face_set_render_glyph_func: make routine! [ font_face [integer!]
	 render_glyph_func [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_set_render_glyph_func" 

	cairo_user_font_face_set_text_to_glyphs_func: make routine! [ font_face [integer!]
	 text_to_glyphs_func [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_set_text_to_glyphs_func" 

	cairo_user_font_face_set_unicode_to_glyph_func: make routine! [ font_face [integer!]
	 unicode_to_glyph_func [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_set_unicode_to_glyph_func" 
	]

{ User-font method getters }
	if cairo_this_version >= 10800 [
	cairo_user_font_face_get_init_func: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_get_init_func" 
	cairo_user_font_face_get_render_glyph_func: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_get_render_glyph_func" 
	cairo_user_font_face_get_text_to_glyphs_func: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_get_text_to_glyphs_func" 
	cairo_user_font_face_get_unicode_to_glyph_func: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_user_font_face_get_unicode_to_glyph_func" 
	]

{ Query functions }
	cairo_get_operator: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_operator" 
	cairo_get_source: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_source" 
	cairo_get_tolerance: make routine! [ cr [integer!] return: [double] ] cairo-lib "cairo_get_tolerance" 
	cairo_get_antialias: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_antialias" 
	if cairo_this_version >= 10600 [
	cairo_has_current_point: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_has_current_point" 
	]
	cairo_get_current_point: make routine! [ cr [integer!] x [integer!] y [integer!] return: [integer!] ] cairo-lib "cairo_get_current_point" 
	cairo_get_fill_rule: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_fill_rule" 
	cairo_get_line_width: make routine! [ cr [integer!] return: [double] ] cairo-lib "cairo_get_line_width" 
	cairo_get_line_cap: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_line_cap" 
	cairo_get_line_join: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_line_join" 
	cairo_get_miter_limit: make routine! [ cr [integer!] return: [double] ] cairo-lib "cairo_get_miter_limit" 
	if cairo_this_version >= 10400 [
	cairo_get_dash_count: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_dash_count" 
	cairo_get_dash: make routine! [ cr [integer!] dashes [integer!] offset [integer!] return: [integer!] ] cairo-lib "cairo_get_dash" 
	]
	;cairo_get_matrix: make routine! [ cr [integer!] matrix [binary!] ] cairo-lib "cairo_get_matrix" 
	cairo_get_matrix: make routine! [ cr [integer!] matrix [struct![]] ] cairo-lib "cairo_get_matrix" 
	cairo_get_target: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_target" 
	if cairo_this_version >= 10200 [
	cairo_get_group_target: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_get_group_target" 
	]

{*
* cairo_path_data_type_t:
	 * @CAIRO_PATH_MOVE_TO: A move-to operation
	 * @CAIRO_PATH_LINE_TO: A line-to operation
	 * @CAIRO_PATH_CURVE_TO: A curve-to operation
	 * @CAIRO_PATH_CLOSE_PATH: A close-path operation
	 *
	 * #cairo_path_data_t is used to describe the type of one portion
	 * of a path when represented as a #cairo_path_t.
	 * See #cairo_path_data_t for details.
	 *}

	CAIRO_PATH_MOVE_TO: 0
	CAIRO_PATH_LINE_TO: 1
	CAIRO_PATH_CURVE_TO: 2
	CAIRO_PATH_CLOSE_PATH: 3

	cairo_path_data_type_t: integer!;
{*
* cairo_path_data_t:
	 *
	 * #cairo_path_data_t is used to represent the path data inside a
	 * #cairo_path_t.
	 *
	 *}
	;typedef union _cairo_path_data_t cairo_path_data_t;
	;union _cairo_path_data_t {
	cairo_path_data_t: make struct! [
	header: [struct! [
	  type [cairo_path_data_type_t]
	  length [integer!]
	]]] none
	    point: make struct! [
	  x [double]  y [double]
	] none 
	
{*
* cairo_path_t:
	 * @status: the current error status
	 * @data: the elements in the path
	 * @num_data: the number of elements in the data array
	 *
	 *}
	cairo_path_t: cairo_path: make struct! [
	  status [cairo_status_t]
	  data [integer!]
	  num_data [integer!]
	] none ;

	cairo_copy_path: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_copy_path" 
	cairo_copy_path_flat: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_copy_path_flat" 
	cairo_append_path: make routine! [ cr [integer!]
	 path [integer!] return: [integer!] ] cairo-lib "cairo_append_path" 

	cairo_path_destroy: make routine! [ path [integer!] return: [integer!] ] cairo-lib "cairo_path_destroy" 

{ Error status queries }
	cairo_status: make routine! [ cr [integer!] return: [integer!] ] cairo-lib "cairo_status" 
	cairo_status_to_string: make routine! [ status [char!] return: [string!] ] cairo-lib "cairo_status_to_string" 

{ Backend device manipulation }
	if cairo_this_version >= 11000 [
	cairo_device_reference: make routine! [ device [integer!] return: [string!] ] cairo-lib "cairo_device_reference" 
	]

{*
* cairo_device_type_t:
	 * @CAIRO_DEVICE_TYPE_DRM: The surface is of type Direct Render Manager
	 * @CAIRO_DEVICE_TYPE_GL: The surface is of type OpenGL
	 * @CAIRO_DEVICE_TYPE_SCRIPT: The surface is of type script
	 * @CAIRO_DEVICE_TYPE_XCB: The surface is of type xcb
	 * @CAIRO_DEVICE_TYPE_XLIB: The surface is of type xlib
	 * @CAIRO_DEVICE_TYPE_XML: The surface is of type XML
	 * @CAIRO_DEVICE_TYPE_COGL: The device is of type cogl, since 1.12
	 * @CAIRO_DEVICE_TYPE_WIN32: The device is of type win32, since 1.12
	 * @CAIRO_DEVICE_TYPE_INVALID: The device is invalid, since 1.10
	 *
	 * Since: 1.10
	 *}

	CAIRO_DEVICE_TYPE_DRM: 0
	CAIRO_DEVICE_TYPE_GL: 1
	CAIRO_DEVICE_TYPE_SCRIPT: 2
	CAIRO_DEVICE_TYPE_XCB: 3
	CAIRO_DEVICE_TYPE_XLIB: 4
	CAIRO_DEVICE_TYPE_XML: 5
	CAIRO_DEVICE_TYPE_COGL: 6
	CAIRO_DEVICE_TYPE_WIN32: 7

	CAIRO_DEVICE_TYPE_INVALID: -1

	cairo_device_type_t: integer!;

	if cairo_this_version >= 11000 [
	cairo_device_get_type: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_get_type" 
	cairo_device_status: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_status" 
	cairo_device_acquire: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_acquire" 
	cairo_device_release: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_release" 
	cairo_device_flush: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_flush" 
	cairo_device_finish: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_finish" 
	cairo_device_destroy: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_destroy" 
	cairo_device_get_reference_count: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_device_get_reference_count" 
	cairo_device_get_user_data: make routine! [ device [integer!]
	 key [integer!] return: [integer!] ] cairo-lib "cairo_device_get_user_data" 

	cairo_device_set_user_data: make routine! [ device [integer!]
	 key [integer!]
	 user_data [integer!]
	 destroy [integer!] return: [integer!] ] cairo-lib "cairo_device_set_user_data" 
	]

{ Surface manipulation }
	cairo_surface_create_similar: make routine! [ other [integer!]
	 content [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_surface_create_similar" 

	if cairo_this_version >= 11200 [
	cairo_surface_create_similar_image: make routine! [ other [integer!]
	 format [cairo_format_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_surface_create_similar_image" 

	cairo_surface_map_to_image: make routine! [ surface [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_surface_map_to_image" 

	cairo_surface_unmap_image: make routine! [ surface [integer!]
	 image [integer!] return: [integer!] ] cairo-lib "cairo_surface_unmap_image" 
	]
	if cairo_this_version >= 11000 [
	cairo_surface_create_for_rectangle: make routine! [ target [integer!]
	 x [double]
	 y [double]
	 width [double]
	 height [double] return: [integer!] ] cairo-lib "cairo_surface_create_for_rectangle" 
	]

	cairo_surface_reference: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_reference" 
	cairo_surface_finish: make routine! [ surface [integer!] ] cairo-lib "cairo_surface_finish" 
	cairo_surface_destroy: make routine! [ surface [integer!] ] cairo-lib "cairo_surface_destroy" 
	if cairo_this_version >= 11000 [
	cairo_surface_get_device: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_device" 
	]
	if cairo_this_version >= 10400 [
	cairo_surface_get_reference_count: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_reference_count" 
	]
	cairo_surface_status: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_status" 

{*
* cairo_surface_observer_mode_t:
	 * @CAIRO_SURFACE_OBSERVER_NORMAL: no recording is done
	 * @CAIRO_SURFACE_OBSERVER_RECORD_OPERATIONS: operations are recorded
	 *
	 * Whether operations should be recorded.
	 *
	 * Since: 1.12
	 *}

	CAIRO_SURFACE_OBSERVER_NORMAL: 0
	CAIRO_SURFACE_OBSERVER_RECORD_OPERATIONS: 1

	cairo_surface_observer_mode_t: integer!;

	if cairo_this_version >= 11200 [
	cairo_surface_create_observer: make routine! [ target [integer!]
		 mode [cairo_surface_observer_mode_t] return: [integer!] ] cairo-lib "cairo_surface_create_observer" 
	{
	typedef void (*cairo_surface_observer_callback_t) (cairo_surface_t *observer,
								   cairo_surface_t *target,
								   void *data);
	}
	cairo_surface_observer_add_paint_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_paint_callback" 

	cairo_surface_observer_add_mask_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_mask_callback" 

	cairo_surface_observer_add_fill_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_fill_callback" 

	cairo_surface_observer_add_stroke_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_stroke_callback" 

	cairo_surface_observer_add_glyphs_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_glyphs_callback" 

	cairo_surface_observer_add_flush_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_flush_callback" 

	cairo_surface_observer_add_finish_callback: make routine! [ abstract_surface [integer!]
	 func [callback]
	 data [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_add_finish_callback" 

	cairo_surface_observer_print: make routine! [ surface [integer!]
	 write_func [callback]
	 closure [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_observer_print" 

	cairo_surface_observer_elapsed: make routine! [ surface [integer!] return: [double] ] cairo-lib "cairo_surface_observer_elapsed" 
	cairo_device_observer_print: make routine! [ device [integer!]
	 write_func [callback]
	 closure [integer!] return: [cairo_status_t] ] cairo-lib "cairo_device_observer_print" 

	cairo_device_observer_elapsed: make routine! [ device [integer!] return: [double] ] cairo-lib "cairo_device_observer_elapsed" 
	cairo_device_observer_paint_elapsed: make routine! [ device [integer!] return: [double] ] cairo-lib "cairo_device_observer_paint_elapsed" 
	cairo_device_observer_mask_elapsed: make routine! [ device [integer!] return: [double] ] cairo-lib "cairo_device_observer_mask_elapsed" 
	cairo_device_observer_fill_elapsed: make routine! [ device [integer!] return: [double] ] cairo-lib "cairo_device_observer_fill_elapsed" 
	cairo_device_observer_stroke_elapsed: make routine! [ device [integer!] return: [double] ] cairo-lib "cairo_device_observer_stroke_elapsed" 
	cairo_device_observer_glyphs_elapsed: make routine! [ device [integer!] return: [double] ] cairo-lib "cairo_device_observer_glyphs_elapsed" 
	]
	cairo_surface_reference: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_reference" 
	cairo_surface_finish: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_finish" 
	cairo_surface_destroy: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_destroy" 
	if cairo_this_version >= 11000 [
	cairo_surface_get_device: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_device" 
	cairo_surface_get_reference_count: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_reference_count" 
	]
	cairo_surface_status: make routine! [ surface [integer!] return: [cairo_status_t] ] cairo-lib "cairo_surface_status" 

{*
* cairo_surface_type_t:
	 *
	 * Since: 1.2
	 *}

	CAIRO_SURFACE_TYPE_IMAGE: 0
	CAIRO_SURFACE_TYPE_PDF: 1
	CAIRO_SURFACE_TYPE_PS: 2
	CAIRO_SURFACE_TYPE_XLIB: 3
	CAIRO_SURFACE_TYPE_XCB: 4
	CAIRO_SURFACE_TYPE_GLITZ: 5
	CAIRO_SURFACE_TYPE_QUARTZ: 6
	CAIRO_SURFACE_TYPE_WIN32: 7
	CAIRO_SURFACE_TYPE_BEOS: 8
	CAIRO_SURFACE_TYPE_DIRECTFB: 9
	CAIRO_SURFACE_TYPE_SVG: 10
	CAIRO_SURFACE_TYPE_OS2: 11
	CAIRO_SURFACE_TYPE_WIN32_PRINTING: 12
	CAIRO_SURFACE_TYPE_QUARTZ_IMAGE: 13
	CAIRO_SURFACE_TYPE_SCRIPT: 14
	CAIRO_SURFACE_TYPE_QT: 15
	CAIRO_SURFACE_TYPE_RECORDING: 16
	CAIRO_SURFACE_TYPE_VG: 17
	CAIRO_SURFACE_TYPE_GL: 18
	CAIRO_SURFACE_TYPE_DRM: 19
	CAIRO_SURFACE_TYPE_TEE: 20
	CAIRO_SURFACE_TYPE_XML: 21
	CAIRO_SURFACE_TYPE_SKIA: 22
	CAIRO_SURFACE_TYPE_SUBSURFACE: 23

	cairo_surface_type_t: integer!;
;
; surface functions
	if cairo_this_version >= 10200 [
	cairo_surface_get_type: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_type" 
	cairo_surface_get_content: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_content" 
	]

	if CAIRO_HAS_PNG_FUNCTIONS [
	cairo_surface_write_to_png: make routine! [ surface [integer!]
	 filename [string!] return: [integer!] ] cairo-lib "cairo_surface_write_to_png" 

	cairo_surface_write_to_png_stream: make routine! [ surface [integer!]
	 ;write_func [integer!]
	 write_func [callback [int int int return: [int]]]
	 closure [integer!] return: [integer!] ] cairo-lib "cairo_surface_write_to_png_stream" 
	]

	cairo_surface_get_user_data: make routine! [ surface [integer!]
	 key [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_user_data" 

	cairo_surface_set_user_data: make routine! [ surface [integer!]
	 key [integer!]
	 user_data [integer!]
	 destroy [integer!] return: [integer!] ] cairo-lib "cairo_surface_set_user_data" 

	CAIRO_MIME_TYPE_JPEG: "image/jpeg"
	CAIRO_MIME_TYPE_PNG: "image/png"
	CAIRO_MIME_TYPE_JP2: "image/jp2"
	CAIRO_MIME_TYPE_URI: "text/x-uri"
	CAIRO_MIME_TYPE_UNIQUE_ID: "application/x-cairo.uuid"
	CAIRO_MIME_TYPE_JBIG2: "application/x-cairo.jbig2"
	CAIRO_MIME_TYPE_JBIG2_GLOBAL: "application/x-cairo.jbig2-global"
	CAIRO_MIME_TYPE_JBIG2_GLOBAL_ID: "application/x-cairo.jbig2-global-id"
	CAIRO_MIME_TYPE_CCITT_FAX: "image/g3fax"
	CAIRO_MIME_TYPE_CCITT_FAX_PARAMS: "application/x-cairo.ccitt.params"
	CAIRO_MIME_TYPE_EPS: "application/postscript"
	CAIRO_MIME_TYPE_EPS_PARAMS: "application/x-cairo.eps.params"

	if cairo_this_version >= 11000 [
	cairo_surface_get_mime_data: make routine! [ surface [integer!]
	 mime_type [string!]
	 data [struct! []]
	 length [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_mime_data" 

	cairo_surface_set_mime_data: make routine! [ surface [integer!]
	 mime_type [string!]
	 data [string!]
	 length [integer!]
	 destroy [integer!]
	 closure [integer!] return: [integer!] ] cairo-lib "cairo_surface_set_mime_data" 

	cairo_surface_supports_mime_type: make routine! [ surface [integer!]
	 mime_type [string!] return: [cairo_bool_t] ] cairo-lib "cairo_surface_supports_mime_type" 
	]

	cairo_surface_get_font_options: make routine! [ surface [integer!]
	 options [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_font_options" 

	cairo_surface_flush: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_flush" 
	cairo_surface_mark_dirty: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_mark_dirty" 
	cairo_surface_mark_dirty_rectangle: make routine! [ surface [integer!]
	 x [integer!]
	 y [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_surface_mark_dirty_rectangle" 

	if cairo_this_version >= 11400 [
	cairo_surface_set_device_scale: make routine! [ surface [integer!]
	 x_scale [double]
	 y_scale [double] return: [integer!] ] cairo-lib "cairo_surface_set_device_scale" 

	cairo_surface_get_device_scale: make routine! [ surface [integer!]
	 x_scale [integer!]
	 y_scale [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_device_scale" 
	]

	cairo_surface_set_device_offset: make routine! [ surface [integer!]
	 x_offset [double]
	 y_offset [double] return: [integer!] ] cairo-lib "cairo_surface_set_device_offset" 

	if cairo_this_version >= 10200 [
	cairo_surface_get_device_offset: make routine! [ surface [integer!]
	 x_offset [integer!]
	 y_offset [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_device_offset" 

	cairo_surface_set_fallback_resolution: make routine! [ surface [integer!]
	 x_pixels_per_inch [double]
	 y_pixels_per_inch [double] return: [integer!] ] cairo-lib "cairo_surface_set_fallback_resolution" 
	]
	if cairo_this_version >= 10800 [
	cairo_surface_get_fallback_resolution: make routine! [ surface [integer!]
	 x_pixels_per_inch [integer!]
	 y_pixels_per_inch [integer!] return: [integer!] ] cairo-lib "cairo_surface_get_fallback_resolution" 
	]

	if cairo_this_version >= 10600 [
	cairo_surface_copy_page: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_copy_page" 
	cairo_surface_show_page: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_show_page" 
	]
	if cairo_this_version >= 10800 [
	cairo_surface_has_show_text_glyphs: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_surface_has_show_text_glyphs" 
	]

{ Image-surface functions }

	cairo_image_surface_create: make routine! [ format [cairo_format_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_create" 

	if cairo_this_version >= 10600 [
	cairo_format_stride_for_width: make routine! [ format [integer!]
	 width [integer!] return: [integer!] ] cairo-lib "cairo_format_stride_for_width" 
	]
	cairo_image_surface_create_for_data: make routine! [ data [binary!]
	 format [integer!]
	 width [integer!]
	 height [integer!]
	 stride [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_create_for_data" 

	if cairo_this_version >= 10200 [
	cairo_image_surface_get_data: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_get_data" 
	cairo_image_surface_get_format: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_get_format" 
	cairo_image_surface_get_stride: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_get_stride" 
	]
	cairo_image_surface_get_width: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_get_width" 
	cairo_image_surface_get_height: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_get_height" 

	if CAIRO_HAS_PNG_FUNCTIONS [
	cairo_image_surface_create_from_png: make routine! [ filename [string!] return: [integer!] ] cairo-lib "cairo_image_surface_create_from_png" 
	cairo_image_surface_create_from_png_stream: make routine! [ read_func [integer!]
	 closure [integer!] return: [integer!] ] cairo-lib "cairo_image_surface_create_from_png_stream" 
	]

{ Recording-surface functions }

	if cairo_this_version >= 11000 [
	cairo_recording_surface_create: make routine! [ content [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_recording_surface_create" 

	cairo_recording_surface_ink_extents: make routine! [ surface [integer!]
	 x0 [integer!]
	 y0 [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_recording_surface_ink_extents" 
	]
	if cairo_this_version >= 11200 [
	cairo_recording_surface_get_extents: make routine! [ surface [integer!]
	 extents [integer!] return: [cairo_bool_t] ] cairo-lib "cairo_recording_surface_get_extents" 
	]
{ raster source functions }
	if cairo_this_version >= 11200 [
	cairo_pattern_create_raster_source: make routine! [ user_data [integer!]
	 content [cairo_content_t]
	 width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_pattern_create_raster_source" 
	cairo_raster_source_pattern_set_callback_data: make routine! [ pattern [integer!]
	 data [integer!] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_set_callback_data" 

	cairo_raster_source_pattern_get_callback_data: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_get_callback_data" 
	cairo_raster_source_pattern_set_acquire: make routine! [ pattern [integer!]
	 acquire [callback]
	 release [callback] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_set_acquire" 

	cairo_raster_source_pattern_get_acquire: make routine! [ pattern [integer!]
	 acquire [integer!]
	 release [integer!] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_get_acquire" 

	cairo_raster_source_pattern_set_snapshot: make routine! [ pattern [integer!]
	 snapshot [callback] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_set_snapshot" 

	cairo_raster_source_pattern_get_snapshot: make routine! [ pattern [integer!] return: [cairo_raster_source_snapshot_func_t] ] cairo-lib "cairo_raster_source_pattern_get_snapshot" 
	cairo_raster_source_pattern_set_copy: make routine! [ pattern [integer!]
	 copy [callback] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_set_copy" 

	cairo_raster_source_pattern_get_copy: make routine! [ pattern [integer!] return: [cairo_raster_source_copy_func_t] ] cairo-lib "cairo_raster_source_pattern_get_copy" 
	cairo_raster_source_pattern_set_finish: make routine! [ pattern [integer!]
	 finish [callback] return: [integer!] ] cairo-lib "cairo_raster_source_pattern_set_finish" 

	cairo_raster_source_pattern_get_finish: make routine! [ pattern [integer!] return: [cairo_raster_source_finish_func_t] ] cairo-lib "cairo_raster_source_pattern_get_finish" 
	]

{ Pattern creation functions }
	cairo_pattern_create_rgb: make routine! [ red [double] green [double] blue [double] return: [integer!] ] cairo-lib "cairo_pattern_create_rgb" 
	cairo_pattern_create_rgba: make routine! [ red [double] green [double] blue [double]
	 alpha [double] return: [integer!] ] cairo-lib "cairo_pattern_create_rgba" 

	cairo_pattern_create_for_surface: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_pattern_create_for_surface" 
	cairo_pattern_create_linear: make routine! [ x0 [double] y0 [double]
	 x1 [double] y1 [double] return: [integer!] ] cairo-lib "cairo_pattern_create_linear" 

	cairo_pattern_create_radial: make routine! [ cx0 [double] cy0 [double] radius0 [double]
	 cx1 [double] cy1 [double] radius1 [double] return: [integer!] ] cairo-lib "cairo_pattern_create_radial" 

	cairo_pattern_reference: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_reference" 
	cairo_pattern_destroy: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_destroy" 
	cairo_pattern_get_reference_count: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_reference_count" 
	cairo_pattern_status: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_status" 
	if cairo_this_version >= 10400 [
	cairo_pattern_get_user_data: make routine! [ pattern [integer!]
	 key [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_user_data" 

	cairo_pattern_set_user_data: make routine! [ pattern [integer!]
	 key [integer!]
	 user_data [integer!]
	 destroy [integer!] return: [integer!] ] cairo-lib "cairo_pattern_set_user_data" 
	]
{*
* cairo_pattern_type_t:
	 * @CAIRO_PATTERN_TYPE_SOLID: The pattern is a solid (uniform)
	 * color. It may be opaque or translucent.
	 * @CAIRO_PATTERN_TYPE_SURFACE: The pattern is a based on a surface (an image).
	 * @CAIRO_PATTERN_TYPE_LINEAR: The pattern is a linear gradient.
	 * @CAIRO_PATTERN_TYPE_RADIAL: The pattern is a radial gradient.
	 *
	 * Since: 1.2
	 *}

	CAIRO_PATTERN_TYPE_SOLID: 0
	CAIRO_PATTERN_TYPE_SURFACE: 1
	CAIRO_PATTERN_TYPE_LINEAR: 2
	CAIRO_PATTERN_TYPE_RADIAL: 3
	CAIRO_PATTERN_TYPE_MESH: 4
	CAIRO_PATTERN_TYPE_RASTER_SOURCE: 5

	cairo_pattern_type_t: integer!;

	if cairo_this_version >= 10200 [
	cairo_pattern_get_type: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_type" 
	]
; cairo_pattern_add_color_stop_rgb 
	cairo_pattern_add_color_stop_rgb: make routine! [ pattern [integer!]
	 offset [double]
	 red [double] green [double] blue [double] return: [integer!] ] cairo-lib "cairo_pattern_add_color_stop_rgb" 

	cairo_pattern_add_color_stop_rgba: make routine! [ pattern [integer!]
	 offset [double]
	 red [double] green [double] blue [double]
	 alpha [double] return: [integer!] ] cairo-lib "cairo_pattern_add_color_stop_rgba" 

; cairo_mesh_pattern_begin_patch
	if cairo_this_version >= 11200 [
	cairo_mesh_pattern_begin_patch: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_mesh_pattern_begin_patch" 
	cairo_mesh_pattern_end_patch: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_mesh_pattern_end_patch" 
	cairo_mesh_pattern_curve_to: make routine! [ pattern [integer!]
	 x1 [double] y1 [double]
	 x2 [double] y2 [double]
	 x3 [double] y3 [double] return: [integer!] ] cairo-lib "cairo_mesh_pattern_curve_to" 

	cairo_mesh_pattern_line_to: make routine! [ pattern [integer!]
	 x [double] y [double] return: [integer!] ] cairo-lib "cairo_mesh_pattern_line_to" 

	cairo_mesh_pattern_move_to: make routine! [ pattern [integer!]
	 x [double] y [double] return: [integer!] ] cairo-lib "cairo_mesh_pattern_move_to" 

	cairo_mesh_pattern_set_control_point: make routine! [ pattern [integer!]
	 point_num [integer!]
	 x [double] y [double] return: [integer!] ] cairo-lib "cairo_mesh_pattern_set_control_point" 

	cairo_mesh_pattern_set_corner_color_rgb: make routine! [ pattern [integer!]
	 corner_num [integer!]
	 red [double] green [double] blue [double] return: [integer!] ] cairo-lib "cairo_mesh_pattern_set_corner_color_rgb" 

	cairo_mesh_pattern_set_corner_color_rgba: make routine! [ pattern [integer!]
	 corner_num [integer!]
	 red [double] green [double] blue [double]
	 alpha [double] return: [integer!] ] cairo-lib "cairo_mesh_pattern_set_corner_color_rgba" 

	]
; cairo_pattern_set_matrix
	cairo_pattern_set_matrix: make routine! [ pattern [integer!] matrix [struct![]] return: [integer!] ] cairo-lib "cairo_pattern_set_matrix" 
	cairo_pattern_get_matrix: make routine! [ pattern [integer!] matrix [struct![]] return: [integer!] ] cairo-lib "cairo_pattern_get_matrix" 
{*
* cairo_extend_t:
	 * @CAIRO_EXTEND_NONE: pixels outside of the source pattern
	 *   are fully transparent
	 * @CAIRO_EXTEND_REPEAT: the pattern is tiled by repeating
	 * @CAIRO_EXTEND_REFLECT: the pattern is tiled by reflecting
	 *   at the edges (Implemented for surface patterns since 1.6)
	 * @CAIRO_EXTEND_PAD: pixels outside of the pattern copy
	 *   the closest pixel from the source (Since 1.2; but only
	 *   implemented for surface patterns since 1.6)
	 *
	 *}

	CAIRO_EXTEND_NONE: 0
	CAIRO_EXTEND_REPEAT: 1
	CAIRO_EXTEND_REFLECT: 2
	CAIRO_EXTEND_PAD: 3

	cairo_extend_t: integer!;

	cairo_pattern_set_extend: make routine! [ pattern [integer!] extend [integer!] return: [integer!] ] cairo-lib "cairo_pattern_set_extend" 
	cairo_pattern_get_extend: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_extend" 
{*
* cairo_filter_t:
	 * @CAIRO_FILTER_FAST: A high-performance filter, with quality similar
	 *     to %CAIRO_FILTER_NEAREST
	 * @CAIRO_FILTER_GOOD: A reasonable-performance filter, with quality
	 *     similar to %CAIRO_FILTER_BILINEAR
	 * @CAIRO_FILTER_BEST: The highest-quality available, performance may
	 *     not be suitable for interactive use.
	 * @CAIRO_FILTER_NEAREST: Nearest-neighbor filtering
	 * @CAIRO_FILTER_BILINEAR: Linear interpolation in two dimensions
	 * @CAIRO_FILTER_GAUSSIAN: This filter value is currently
	 *     unimplemented, and should not be used in current code.
	 *
	 }

	CAIRO_FILTER_FAST: 0
	CAIRO_FILTER_GOOD: 1
	CAIRO_FILTER_BEST: 2
	CAIRO_FILTER_NEAREST: 3
	CAIRO_FILTER_BILINEAR: 4
	CAIRO_FILTER_GAUSSIAN: 5

	cairo_filter_t: integer!;

	cairo_pattern_set_filter: make routine! [ pattern [integer!] filter [integer!] return: [integer!] ] cairo-lib "cairo_pattern_set_filter" 
	cairo_pattern_get_filter: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_filter" 
	if cairo_this_version >= 10400 [
	cairo_pattern_get_rgba: make routine! [ pattern [integer!]
	 red [integer!] green [integer!]
	 blue [integer!] alpha [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_rgba" 

	cairo_pattern_get_surface: make routine! [ pattern [integer!]
	 surface [struct! []] return: [integer!] ] cairo-lib "cairo_pattern_get_surface" 

	cairo_pattern_get_color_stop_rgba: make routine! [ pattern [integer!]
	 index [integer!] offset [integer!]
	 red [integer!] green [integer!]
	 blue [integer!] alpha [integer!] return: [struct! []] ] cairo-lib "cairo_pattern_get_color_stop_rgba" 

	cairo_pattern_get_color_stop_count: make routine! [ pattern [integer!]
	 count [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_color_stop_count" 

	cairo_pattern_get_linear_points: make routine! [ pattern [integer!]
	 x0 [integer!] y0 [integer!]
	 x1 [integer!] y1 [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_linear_points" 

	cairo_pattern_get_radial_circles: make routine! [ pattern [integer!]
	 x0 [integer!] y0 [integer!] r0 [integer!]
	 x1 [integer!] y1 [integer!] r1 [integer!] return: [integer!] ] cairo-lib "cairo_pattern_get_radial_circles" 
	]
	if cairo_this_version >= 11000 [
	cairo_mesh_pattern_get_patch_count: make routine! [ pattern [integer!]
	 count [integer!] return: [cairo_status_t] ] cairo-lib "cairo_mesh_pattern_get_patch_count" 

	cairo_mesh_pattern_get_path: make routine! [ pattern [integer!]
	 patch_num [integer!] return: [integer!] ] cairo-lib "cairo_mesh_pattern_get_path" 

	cairo_mesh_pattern_get_corner_color_rgba: make routine! [ pattern [integer!]
	 patch_num [integer!]
	 corner_num [integer!]
	 red [integer!] green [integer!]
	 blue [integer!] alpha [integer!] return: [cairo_status_t] ] cairo-lib "cairo_mesh_pattern_get_corner_color_rgba" 

	cairo_mesh_pattern_get_control_point: make routine! [ pattern [integer!]
	 patch_num [integer!]
	 point_num [integer!]
	 x [integer!] y [integer!] return: [cairo_status_t] ] cairo-lib "cairo_mesh_pattern_get_control_point" 
	]
{ Matrix functions }
	cairo_matrix_init: make routine! [ matrix [struct![]]
	 xx [double] yx [double]
	 xy [double] yy [double]
	 x0 [double] y0 [double] return: [integer!] ] cairo-lib "cairo_matrix_init" 

	cairo_matrix_init_identity: make routine! [ matrix [struct! []] return: [integer!] ] cairo-lib "cairo_matrix_init_identity" 
	cairo_matrix_init_translate: make routine! [ matrix [struct! []] tx [double] ty [double] return: [integer!] ] cairo-lib "cairo_matrix_init_translate" 
	cairo_matrix_init_scale: make routine! [ matrix [struct! []] sx [double] sy [double] return: [integer!] ] cairo-lib "cairo_matrix_init_scale" 
	cairo_matrix_init_rotate: make routine! [ matrix [struct! []] radians [double] return: [integer!] ] cairo-lib "cairo_matrix_init_rotate" 
	cairo_matrix_translate: make routine! [ matrix [struct! []] tx [double] ty [double] return: [integer!] ] cairo-lib "cairo_matrix_translate" 
	cairo_matrix_scale: make routine! [ matrix [struct! []] sx [double] sy [double] return: [integer!] ] cairo-lib "cairo_matrix_scale" 
	cairo_matrix_rotate: make routine! [ matrix [struct! []] radians [double] return: [integer!] ] cairo-lib "cairo_matrix_rotate" 
	cairo_matrix_invert: make routine! [ matrix [struct! []] return: [double] ] cairo-lib "cairo_matrix_invert" 
	cairo_matrix_multiply: make routine! [ result [struct![]]
	 a [struct![]]
	 b [struct![]] return: [integer!] ] cairo-lib "cairo_matrix_multiply" 

	cairo_matrix_transform_distance: make routine! [ matrix [struct! []]
	 dx [struct![]] dy [struct![]] return: [integer!] ] cairo-lib "cairo_matrix_transform_distance" 

	cairo_matrix_transform_point: make routine! [ matrix [struct! []]
	 x [struct![]] y [struct![]] return: [integer!] ] cairo-lib "cairo_matrix_transform_point" 

{ Region functions }
{*
* cairo_rectangle_int_t:
	 * @x: X coordinate of the left side of the rectangle
	 * @y: Y coordinate of the the top side of the rectangle
	 * @width: width of the rectangle
	 * @height: height of the rectangle
	 *
	 * A data structure for holding a rectangle with integer coordinates.
	 *
	 * Since: 1.10
	 *}

	cairo_rectangle_int_t: _cairo_rectangle_int: make struct! [
	  x [integer!]  y [integer!]
	  width [integer!]  height [integer!]
	] none ;

	CAIRO_REGION_OVERLAP_IN: 0;		{ completely inside region }
	CAIRO_REGION_OVERLAP_OUT: 1;		{ completely outside region }
	CAIRO_REGION_OVERLAP_PART: 2;		{ partly inside region }

	cairo_region_overlap_t: integer!;

	if cairo_this_version >= 11000 [
	cairo_region_create: make routine! [ return: [integer!] ] cairo-lib "cairo_region_create" 
	cairo_region_create_rectangle: make routine! [ rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_create_rectangle" 
	cairo_region_create_rectangles: make routine! [ rects [integer!]
	 count [integer!] return: [integer!] ] cairo-lib "cairo_region_create_rectangles" 

	cairo_region_copy: make routine! [ original [integer!] return: [integer!] ] cairo-lib "cairo_region_copy" 
	cairo_region_reference: make routine! [ region [integer!] return: [integer!] ] cairo-lib "cairo_region_reference" 
	cairo_region_destroy: make routine! [ region [integer!] return: [integer!] ] cairo-lib "cairo_region_destroy" 
	cairo_region_equal: make routine! [ a [integer!] b [integer!] return: [integer!] ] cairo-lib "cairo_region_equal" 
	cairo_region_status: make routine! [ region [integer!] return: [integer!] ] cairo-lib "cairo_region_status" 
	cairo_region_get_extents: make routine! [ region [integer!]
	 extents [integer!] return: [integer!] ] cairo-lib "cairo_region_get_extents" 

	cairo_region_num_rectangles: make routine! [ region [integer!] return: [integer!] ] cairo-lib "cairo_region_num_rectangles" 
	cairo_region_get_rectangle: make routine! [ region [integer!]
	 nth [integer!]
	 rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_get_rectangle" 

	cairo_region_is_empty: make routine! [ region [integer!] return: [integer!] ] cairo-lib "cairo_region_is_empty" 
	cairo_region_contains_rectangle: make routine! [ region [integer!]
	 rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_contains_rectangle" 

	cairo_region_contains_point: make routine! [ region [integer!] x [integer!] y [integer!] return: [integer!] ] cairo-lib "cairo_region_contains_point" 
	cairo_region_translate: make routine! [ region [integer!] dx [integer!] dy [integer!] return: [integer!] ] cairo-lib "cairo_region_translate" 
	cairo_region_subtract: make routine! [ dst [integer!] other [integer!] return: [integer!] ] cairo-lib "cairo_region_subtract" 
	cairo_region_subtract_rectangle: make routine! [ dst [integer!]
	 rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_subtract_rectangle" 

	cairo_region_intersect: make routine! [ dst [integer!] other [integer!] return: [integer!] ] cairo-lib "cairo_region_intersect" 
	cairo_region_intersect_rectangle: make routine! [ dst [integer!]
	 rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_intersect_rectangle" 

	cairo_region_union: make routine! [ dst [integer!] other [integer!] return: [integer!] ] cairo-lib "cairo_region_union" 
	cairo_region_union_rectangle: make routine! [ dst [integer!]
	 rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_union_rectangle" 

	cairo_region_xor: make routine! [ dst [integer!] other [integer!] return: [integer!] ] cairo-lib "cairo_region_xor" 
	cairo_region_xor_rectangle: make routine! [ dst [integer!]
	 rectangle [integer!] return: [integer!] ] cairo-lib "cairo_region_xor_rectangle" 
	]

{ Functions to be used while debugging (not intended for use in production code) }
	cairo_debug_reset_static_data: make routine! [ return: [integer!] ] cairo-lib "cairo_debug_reset_static_data" 

{ cairo-cogl.h }
	if CAIRO_HAS_COGL_SURFACE [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2011 Intel Corporation.
	 *
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is Mozilla Corporation.
	 *
	 * Contributor(s):
	 *      Robert Bragg <robert@linux.intel.com>
	 }

	if cairo_this_version >= 11000 [
	cairo_cogl_device_create: make routine! [ context [integer!] return: [integer!] ] cairo-lib "cairo_cogl_device_create" 
	cairo_cogl_surface_create: make routine! [ device [integer!]
	 framebuffer [integer!] return: [integer!] ] cairo-lib "cairo_cogl_surface_create" 

	cairo_cogl_surface_get_framebuffer: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_cogl_surface_get_framebuffer" 
	cairo_cogl_surface_get_texture: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_cogl_surface_get_texture" 
	cairo_cogl_surface_end_frame: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_cogl_surface_end_frame" 
	]
	]

{ cairo-deprecated.h }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2006 Red Hat, Inc.
	 *
	 * Contributor(s):
	 *	Carl D. Worth <cworth@cworth.org>
	 }

	CAIRO_FONT_TYPE_ATSUI: CAIRO_FONT_TYPE_QUARTZ

{ cairo-drm.h }
	if CAIRO_HAS_DRM_SURFACE [
	{ Cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2009 Chris Wilson
	 *
	 * The Initial Developer of the Original Code is Chris Wilson.
	 }

	;struct udev_device;

	if cairo_this_version >= 11000 [
	cairo_drm_device_get: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_drm_device_get" 
	cairo_drm_device_get_for_fd: make routine! [ fd [integer!] return: [integer!] ] cairo-lib "cairo_drm_device_get_for_fd" 
	cairo_drm_device_default: make routine! [ return: [integer!] ] cairo-lib "cairo_drm_device_default" 
	cairo_drm_device_get_fd: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_drm_device_get_fd" 
	cairo_drm_device_throttle: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_drm_device_throttle" 
	cairo_drm_surface_create: make routine! [ device [integer!]
	 format [cairo_format_t]
	 width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_create" 

	cairo_drm_surface_create_for_name: make routine! [ device [integer!]
	 name [integer!]
	 format [cairo_format_t]
	 width [integer!] height [integer!] stride [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_create_for_name" 

	cairo_drm_surface_create_from_cacheable_image: make routine! [ device [integer!]
	 surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_create_from_cacheable_image" 

	cairo_drm_surface_enable_scan_out: make routine! [ surface [integer!] return: [cairo_status_t] ] cairo-lib "cairo_drm_surface_enable_scan_out" 
	cairo_drm_surface_get_handle: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_get_handle" 
	cairo_drm_surface_get_name: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_get_name" 
	cairo_drm_surface_get_format: make routine! [ surface [integer!] return: [cairo_format_t] ] cairo-lib "cairo_drm_surface_get_format" 
	cairo_drm_surface_get_width: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_get_width" 
	cairo_drm_surface_get_height: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_get_height" 
	cairo_drm_surface_get_stride: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_get_stride" 

	{ XXX map/unmap, general surface layer? }

	{ Rough outline, culled from a conversation on IRC:
	 *   map() returns an image-surface representation of the drm-surface,
	 *   which you unmap() when you are finished, i.e. map() pulls the buffer back
	 *   from the GPU, maps it into the CPU domain and gives you direct access to
	 *   the pixels.  With the unmap(), the buffer is ready to be used again by the
	 *   GPU and *until* the unmap(), all operations will be done in software.
	 *
	 *  (Technically calling cairo_surface_flush() on the underlying drm-surface
	 *  will also disassociate the mapping.)
	}

	cairo_drm_surface_map_to_image: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_map_to_image" 
	cairo_drm_surface_unmap: make routine! [ drm_surface [integer!]
	 image_surface [integer!] return: [integer!] ] cairo-lib "cairo_drm_surface_unmap" 
	]
	]
{ cairo-ft.h }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2005 Red Hat, Inc
	 *
	 * Contributor(s):
	 *      Graydon Hoare <graydon@redhat.com>
	 *	Owen Taylor <otaylor@redhat.com>
	 }

	{ Fontconfig/Freetype platform-specific font interface }

	cairo_ft_font_face_create_for_ft_face: make routine! [ face [integer!]
	 load_flags [integer!] return: [integer!] ] cairo-lib "cairo_ft_font_face_create_for_ft_face" 

	cairo_ft_scaled_font_lock_face: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_ft_scaled_font_lock_face" 
	cairo_ft_scaled_font_unlock_face: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_ft_scaled_font_unlock_face" 
{*
* cairo_ft_synthesize_t:
	 * @CAIRO_FT_SYNTHESIZE_BOLD: Embolden the glyphs (redraw with a pixel offset)
	 * @CAIRO_FT_SYNTHESIZE_OBLIQUE: Slant the glyph outline by 12 degrees to the
	 * right.
	 *
	 * Since: 1.12
	 *}

	CAIRO_FT_SYNTHESIZE_BOLD: 1 ;1 << 0
	CAIRO_FT_SYNTHESIZE_OBLIQUE: 2 ;1 << 1

	cairo_ft_synthesize_t: integer!;

	if cairo_this_version >= 11200 [
	cairo_ft_font_face_set_synthesize: make routine! [ font_face [integer!]
	 synth_flags [integer!] return: [integer!] ] cairo-lib "cairo_ft_font_face_set_synthesize" 

	cairo_ft_font_face_unset_synthesize: make routine! [ font_face [integer!]
	 synth_flags [integer!] return: [integer!] ] cairo-lib "cairo_ft_font_face_unset_synthesize" 

	cairo_ft_font_face_get_synthesize: make routine! [ font_face [integer!] return: [integer!] ] cairo-lib "cairo_ft_font_face_get_synthesize" 
	]
	cairo_ft_scaled_font_lock_face: make routine! [ scaled_font [integer!] return: [FT_Face] ] cairo-lib "cairo_ft_scaled_font_lock_face" 
	cairo_ft_scaled_font_unlock_face: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_ft_scaled_font_unlock_face" 

	if CAIRO_HAS_FC_FONT [
	cairo_ft_font_face_create_for_pattern: make routine! [ pattern [integer!] return: [integer!] ] cairo-lib "cairo_ft_font_face_create_for_pattern" 
	cairo_ft_font_options_substitute: make routine! [ options [integer!]
	 pattern [integer!] return: [integer!] ] cairo-lib "cairo_ft_font_options_substitute" 
	]

{ cairo-gl.h }
	if CAIRO_HAS_GL_SURFACE [
	{ Cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2009 Eric Anholt
	 * Copyright © 2009 Chris Wilson
	 *
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is Eric Anholt.
	 }

	{
	 * cairo-gl.h:
	 *
	 * The cairo-gl backend provides an implementation of possibly
	 * hardware-accelerated cairo rendering by targeting the OpenGL API.
	 * The goal of the cairo-gl backend is to provide better performance
	 * with equal functionality to image-cairo where possible.  It does
	 * not directly provide for applying additional OpenGL effects to
	 * cairo surfaces.
	 *
	 * Cairo-gl allows interoperability with other GL rendering through GL
	 * context sharing.  Cairo-gl surfaces are created in reference to a
	 * #cairo_device_t, which represents a GL context created by the user.
	 * When that GL context is created with its sharePtr set to another
	 * context (or vice versa), its objects (textures backing cairo-gl
	 * surfaces) can be accessed in the other OpenGL context.  This allows
	 * cairo-gl to maintain its drawing state in one context while the
	 * user's 3D rendering occurs in the user's other context.
	 *
	 * However, as only one context can be current to a thread at a time,
	 * cairo-gl may make its context current to the thread on any cairo
	 * call which interacts with a cairo-gl surface or the cairo-gl
	 * device.  As a result, the user must make their own context current
	 * between any cairo calls and their own OpenGL rendering.
	 *}

	;#if CAIRO_HAS_GL_SURFACE || CAIRO_HAS_GLESV2_SURFACE || CAIRO_HAS_GLESV3_SURFACE

	if cairo_this_version >= 11000 [
	cairo_gl_surface_create: make routine! [ device [integer!]
	 content [cairo_content_t]
	 width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_create" 

	cairo_gl_surface_create_for_texture: make routine! [ abstract_device [integer!]
	 content [cairo_content_t]
	 tex [integer!]
	 width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_create_for_texture" 

	cairo_gl_surface_set_size: make routine! [ surface [integer!] width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_set_size" 
	cairo_gl_surface_get_width: make routine! [ abstract_surface [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_get_width" 
	cairo_gl_surface_get_height: make routine! [ abstract_surface [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_get_height" 
	cairo_gl_surface_swapbuffers: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_swapbuffers" 
	cairo_gl_device_set_thread_aware: make routine! [ device [integer!]
	 thread_aware [cairo_bool_t] return: [integer!] ] cairo-lib "cairo_gl_device_set_thread_aware" 

	;#if CAIRO_HAS_GLX_FUNCTIONS

	cairo_glx_device_create: make routine! [ dpy [integer!] gl_ctx [GLXContext] return: [integer!] ] cairo-lib "cairo_glx_device_create" 
	cairo_glx_device_get_display: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_glx_device_get_display" 
	cairo_glx_device_get_context: make routine! [ device [integer!] return: [GLXContext] ] cairo-lib "cairo_glx_device_get_context" 
	cairo_gl_surface_create_for_window: make routine! [ device [integer!]
	 win [Window]
	 width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_create_for_window" 

	;#if CAIRO_HAS_WGL_FUNCTIONS

	cairo_wgl_device_create: make routine! [ rc [integer!] return: [integer!] ] cairo-lib "cairo_wgl_device_create" 
	cairo_wgl_device_get_context: make routine! [ device [integer!] return: [HGLRC] ] cairo-lib "cairo_wgl_device_get_context" 
	cairo_gl_surface_create_for_dc: make routine! [ device [integer!]
	 dc [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_create_for_dc" 

	;#if CAIRO_HAS_EGL_FUNCTIONS

	cairo_egl_device_create: make routine! [ dpy [EGLDisplay] egl [EGLContext] return: [integer!] ] cairo-lib "cairo_egl_device_create" 
	cairo_gl_surface_create_for_egl: make routine! [ device [integer!]
	 egl [EGLSurface]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_gl_surface_create_for_egl" 

	cairo_egl_device_get_display: make routine! [ device [integer!] return: [EGLDisplay] ] cairo-lib "cairo_egl_device_get_display" 
	cairo_egl_device_get_context: make routine! [ device [integer!] return: [EGLSurface] ] cairo-lib "cairo_egl_device_get_context" 
	]
	]

{ cairo-gobject.h }
	if CAIRO_HAS_GOBJECT_FUNCTIONS [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2010 Red Hat Inc.
	 *
	 * Contributor(s):
	 *	Benjamin Otte <otte@redhat.com>
	 }


	{ structs }

	if cairo_this_version >= 11000 [
	cairo_gobject_context_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_context_get_type" 
	cairo_gobject_device_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_device_get_type" 
	cairo_gobject_pattern_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_pattern_get_type" 
	cairo_gobject_surface_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_surface_get_type" 
	cairo_gobject_rectangle_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_rectangle_get_type" 
	cairo_gobject_scaled_font_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_scaled_font_get_type" 
	cairo_gobject_font_face_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_font_face_get_type" 
	cairo_gobject_font_options_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_font_options_get_type" 
	cairo_gobject_rectangle_int_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_rectangle_int_get_type" 
	cairo_gobject_region_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_region_get_type" 

	{ enums }
	cairo_gobject_status_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_status_get_type" 
	cairo_gobject_content_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_content_get_type" 
	cairo_gobject_operator_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_operator_get_type" 
	cairo_gobject_antialias_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_antialias_get_type" 
	cairo_gobject_fill_rule_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_fill_rule_get_type" 
	cairo_gobject_line_cap_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_line_cap_get_type" 
	cairo_gobject_line_join_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_line_join_get_type" 
	cairo_gobject_text_cluster_flags_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_text_cluster_flags_get_type" 
	cairo_gobject_font_slant_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_font_slant_get_type" 
	cairo_gobject_font_weight_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_font_weight_get_type" 
	cairo_gobject_subpixel_order_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_subpixel_order_get_type" 
	cairo_gobject_hint_style_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_hint_style_get_type" 
	cairo_gobject_hint_metrics_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_hint_metrics_get_type" 
	cairo_gobject_font_type_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_font_type_get_type" 
	cairo_gobject_path_data_type_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_path_data_type_get_type" 
	cairo_gobject_device_type_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_device_type_get_type" 
	cairo_gobject_surface_type_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_surface_type_get_type" 
	cairo_gobject_format_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_format_get_type" 
	cairo_gobject_pattern_type_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_pattern_type_get_type" 
	cairo_gobject_extend_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_extend_get_type" 
	cairo_gobject_filter_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_filter_get_type" 
	cairo_gobject_region_overlap_get_type: make routine! [ return: [integer!] ] cairo-lib "cairo_gobject_region_overlap_get_type" 
	]
	]

{ cairo-pdf.h }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2002 University of Southern California
	 *
	 * Contributor(s):
	 *	Carl D. Worth <cworth@cworth.org>
	 }

	if CAIRO_HAS_PDF_SURFACE [

	{*
	 * cairo_pdf_version_t:
	 * @CAIRO_PDF_VERSION_1_4: The version 1.4 of the PDF specification.
	 * @CAIRO_PDF_VERSION_1_5: The version 1.5 of the PDF specification.
	 *
	 * #cairo_pdf_version_t is used to describe the version number of the PDF
	 * specification that a generated PDF file will conform to.
	 *
	 * Since 1.10
	 }

	CAIRO_PDF_VERSION_1_4: 0
	CAIRO_PDF_VERSION_1_5: 1

	cairo_pdf_version_t: integer!;

	if cairo_this_version >= 10200 [
	cairo_pdf_surface_create: make routine! [ filename [string!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_pdf_surface_create" 

	cairo_pdf_surface_create_for_stream: make routine! [ write_func [integer!]
	 closure [integer!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_pdf_surface_create_for_stream" 
	]
	 if cairo_this_version >= 11000 [
	cairo_pdf_surface_restrict_to_version: make routine! [ surface [integer!]
	 version [integer!] return: [integer!] ] cairo-lib "cairo_pdf_surface_restrict_to_version" 

	cairo_pdf_get_versions: make routine! [ versions [integer!] num_versions [integer!] return: [integer!] ] cairo-lib "cairo_pdf_get_versions" 
	cairo_pdf_version_to_string: make routine! [ version [char!] return: [string!] ] cairo-lib "cairo_pdf_version_to_string" 
	]
	if cairo_this_version >= 10200 [
	cairo_pdf_surface_set_size: make routine! [ surface [integer!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_pdf_surface_set_size" 
	]
	{*
	* cairo_pdf_outline_flags_t:
	 * @CAIRO_PDF_OUTLINE_FLAG_OPEN: The outline item defaults to open in the PDF viewer (Since 1.16)
	 * @CAIRO_PDF_OUTLINE_FLAG_BOLD: The outline item is displayed by the viewer in bold text (Since 1.16)
	 * @CAIRO_PDF_OUTLINE_FLAG_ITALIC: The outline item is displayed by the viewer in italic text (Since 1.16)
	 *
	 * #cairo_pdf_outline_flags_t is used by the
	 * cairo_pdf_surface_add_outline() function specify the attributes of
	 * an outline item. These flags may be bitwise-or'd to produce any
	 * combination of flags.
	 *
	 * Since: 1.16
	 *}
	CAIRO_PDF_OUTLINE_FLAG_OPEN: 1
	CAIRO_PDF_OUTLINE_FLAG_BOLD: 2
	CAIRO_PDF_OUTLINE_FLAG_ITALIC: 4

	cairo_pdf_outline_flags_t: integer!;

	CAIRO_PDF_OUTLINE_ROOT: 0

	if cairo_this_version >= 11600 [
	cairo_pdf_surface_add_outline: make routine! [ surface [integer!]
	 parent_id [integer!]
	 utf8 [string!]
	 link_attribs [string!]
	 flags [cairo_pdf_outline_flags_t] return: [integer!] ] cairo-lib "cairo_pdf_surface_add_outline" 
	]
	{*
	* cairo_pdf_metadata_t:
	 * @CAIRO_PDF_METADATA_TITLE: The document title (Since 1.16)
	 * @CAIRO_PDF_METADATA_AUTHOR: The document author (Since 1.16)
	 * @CAIRO_PDF_METADATA_SUBJECT: The document subject (Since 1.16)
	 * @CAIRO_PDF_METADATA_KEYWORDS: The document keywords (Since 1.16)
	 * @CAIRO_PDF_METADATA_CREATOR: The document creator (Since 1.16)
	 * @CAIRO_PDF_METADATA_CREATE_DATE: The document creation date (Since 1.16)
	 * @CAIRO_PDF_METADATA_MOD_DATE: The document modification date (Since 1.16)
	 *
	 * #cairo_pdf_metadata_t is used by the
	 * cairo_pdf_surface_set_metadata() function specify the metadata to set.
	 *
	 * Since: 1.16
	 *}
	CAIRO_PDF_METADATA_TITLE: 0
	CAIRO_PDF_METADATA_AUTHOR: 1
	CAIRO_PDF_METADATA_SUBJECT: 2
	CAIRO_PDF_METADATA_KEYWORDS: 3
	CAIRO_PDF_METADATA_CREATOR: 4
	CAIRO_PDF_METADATA_CREATE_DATE: 5
	CAIRO_PDF_METADATA_MOD_DATE: 6

	cairo_pdf_metadata_t: integer!;

	if cairo_this_version >= 11600 [
	cairo_pdf_surface_set_metadata: make routine! [ surface [integer!]
	 metadata [cairo_pdf_metadata_t]
	 utf8 [string!] return: [integer!] ] cairo-lib "cairo_pdf_surface_set_metadata" 

	cairo_pdf_surface_set_page_label: make routine! [ surface [integer!]
	 utf8 [string!] return: [integer!] ] cairo-lib "cairo_pdf_surface_set_page_label" 

	cairo_pdf_surface_set_thumbnail_size: make routine! [ surface [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_pdf_surface_set_thumbnail_size" 
	]
	]
{ cairo-ps.h }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2002 University of Southern California
	 *
	 * Contributor(s):
	 *	Carl D. Worth <cworth@cworth.org>
	 }


	if CAIRO_HAS_PS_SURFACE [

	{ PS-surface functions }

	{*
	 * cairo_ps_level_t:
	 * @CAIRO_PS_LEVEL_2: The language level 2 of the PostScript specification.
	 * @CAIRO_PS_LEVEL_3: The language level 3 of the PostScript specification.
	 *
	 }

	CAIRO_PS_LEVEL_2: 0
	CAIRO_PS_LEVEL_3: 1

	cairo_ps_level_t: integer!;

	if cairo_this_version >= 10200 [
	cairo_ps_surface_create: make routine! [ filename [string!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_ps_surface_create" 

	cairo_ps_surface_create_for_stream: make routine! [ write_func [integer!]
	 closure [integer!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_ps_surface_create_for_stream" 
	]
	if cairo_this_version >= 10600 [
	cairo_ps_surface_restrict_to_level: make routine! [ surface [integer!]
	 level [integer!] return: [integer!] ] cairo-lib "cairo_ps_surface_restrict_to_level" 

	cairo_ps_get_levels: make routine! [ levels [integer!] num_levels  [integer!] ] cairo-lib "cairo_ps_get_levels"
	cairo_ps_level_to_string: make routine! [ level [integer!] return: [integer!] ] cairo-lib "cairo_ps_level_to_string" 
	cairo_ps_surface_set_eps: make routine! [ surface [integer!]
	 eps [integer!] return: [integer!] ] cairo-lib "cairo_ps_surface_set_eps" 

	cairo_ps_surface_get_eps: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_ps_surface_get_eps" 
	]
	if cairo_this_version >= 10200 [
	cairo_ps_surface_set_size: make routine! [ surface [integer!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_ps_surface_set_size" 

	cairo_ps_surface_dsc_comment: make routine! [ surface [integer!]
	 comment [string!] return: [integer!] ] cairo-lib "cairo_ps_surface_dsc_comment" 

	cairo_ps_surface_dsc_begin_setup: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_ps_surface_dsc_begin_setup" 
	cairo_ps_surface_dsc_begin_page_setup: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_ps_surface_dsc_begin_page_setup" 
	]
	]
{ cairo-qt.h }
	if CAIRO_HAS_QT_SURFACE [
	if cairo_this_version >= 11000 [

	{ -*- Mode: c; c-basic-offset: 4; indent-tabs-mode: t; tab-width: 8; -*- }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2008 Mozilla Corporation
	 *
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is Mozilla Corporation.
	 *
	 * Contributor(s):
	 *      Vladimir Vukicevic <vladimir@mozilla.com>
	 }

	cairo_qt_surface_create: make routine! [ painter [integer!] return: [integer!] ] cairo-lib "cairo_qt_surface_create" 
	cairo_qt_surface_create_with_qimage: make routine! [ format [cairo_format_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_qt_surface_create_with_qimage" 

	cairo_qt_surface_create_with_qpixmap: make routine! [ content [cairo_content_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_qt_surface_create_with_qpixmap" 

	cairo_qt_surface_get_qpainter: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_qt_surface_get_qpainter" 

	{ XXX needs hooking to generic surface layer, my vote is for
	cairo_public cairo_surface_t *
	cairo_surface_map_image (cairo_surface_t *surface);
	cairo_public void
	cairo_surface_unmap_image (cairo_surface_t *surface, cairo_surface_t *image);
	}
	cairo_qt_surface_get_image: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_qt_surface_get_image" 
	cairo_qt_surface_get_qimage: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_qt_surface_get_qimage" 
	]
	]
{ cairo-quartz.h }
	if cairo_this_version >= 10600 [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2006, 2007 Mozilla Corporation
	 *
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is Mozilla Foundation.
	 *
	 * Contributor(s):
	 *      Vladimir Vukicevic <vladimir@mozilla.com>
	 }

	if CAIRO_HAS_QUARTZ_SURFACE [

	cairo_quartz_surface_create: make routine! [ format [cairo_format_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_quartz_surface_create" 

	cairo_quartz_surface_create_for_cg_context: make routine! [ cgContext [CGContextRef]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_quartz_surface_create_for_cg_context" 

	cairo_quartz_surface_get_cg_context: make routine! [ surface [integer!] return: [CGContextRef] ] cairo-lib "cairo_quartz_surface_get_cg_context" 
	]

	if CAIRO_HAS_QUARTZ_FONT [

	{
	* Quartz font support
	}

	cairo_quartz_font_face_create_for_cgfont: make routine! [ font [CGFontRef] return: [integer!] ] cairo-lib "cairo_quartz_font_face_create_for_cgfont" 
	cairo_quartz_font_face_create_for_atsu_font_id: make routine! [ font_id [ATSUFontID] return: [integer!] ] cairo-lib "cairo_quartz_font_face_create_for_atsu_font_id" 
	]
	]
{ cairo-script.h }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2008 Chris Wilson
	 *
	 * The Initial Developer of the Original Code is Chris Wilson
	 *
	 * Contributor(s):
	 *	Chris Wilson <chris@chris-wilson.co.uk>
	 }

	if CAIRO_HAS_SCRIPT_SURFACE [

	{*
	 * cairo_script_mode_t:
	 * @CAIRO_SCRIPT_MODE_ASCII: the output will be in readable text (default). (Since 1.12)
	 * @CAIRO_SCRIPT_MODE_BINARY: the output will use byte codes. (Since 1.12)
	 *
	 * A set of script output variants.
	 *
	 * Since: 1.12
	 *}

	CAIRO_SCRIPT_MODE_ASCII: 0
	CAIRO_SCRIPT_MODE_BINARY: 1

	cairo_script_mode_t: integer!;

	if cairo_this_version >= 11200 [
	cairo_script_create: make routine! [ filename [string!] return: [integer!] ] cairo-lib "cairo_script_create" 
	cairo_script_create_for_stream: make routine! [ write_func [callback]
	 closure [integer!] return: [integer!] ] cairo-lib "cairo_script_create_for_stream" 

	cairo_script_write_comment: make routine! [ script [integer!]
	 comment [string!]
	 len [integer!] return: [integer!] ] cairo-lib "cairo_script_write_comment" 

	cairo_script_set_mode: make routine! [ script [integer!]
	 mode [cairo_script_mode_t] return: [integer!] ] cairo-lib "cairo_script_set_mode" 

	cairo_script_get_mode: make routine! [ script [integer!] return: [cairo_script_mode_t] ] cairo-lib "cairo_script_get_mode" 
	cairo_script_surface_create: make routine! [ script [integer!]
	 content [cairo_content_t]
	 width [double]
	 height [double] return: [integer!] ] cairo-lib "cairo_script_surface_create" 

	cairo_script_surface_create_for_target: make routine! [ script [integer!]
	 target [integer!] return: [integer!] ] cairo-lib "cairo_script_surface_create_for_target" 

	cairo_script_from_recording_surface: make routine! [ script [integer!]
	 recording_surface [integer!] return: [cairo_status_t] ] cairo-lib "cairo_script_from_recording_surface" 
	]
	]
{ cairo-script-interpreter.h }
	[
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2008 Chris Wilson
	 *
	 * Contributor(s):
	 *	Chris Wilson <chris@chris-wilson.co.uk>
	 }

	;typedef struct _cairo_script_interpreter cairo_script_interpreter_t;

	{ XXX expose csi_dictionary_t and pass to hooks }
	{
	typedef void
	(*csi_destroy_func_t) (void *closure,
			       void *ptr);

	typedef cairo_surface_t *
	(*csi_surface_create_func_t) (void *closure,
				      cairo_content_t content,
				      double width,
				      double height,
				      long uid);
	typedef cairo_t *
	(*csi_context_create_func_t) (void *closure,
				      cairo_surface_t *surface);
	typedef void
	(*csi_show_page_func_t) (void *closure,
				 cairo_t *cr);

	typedef void
	(*csi_copy_page_func_t) (void *closure,
				 cairo_t *cr);
	}
	cairo_script_interpreter_hooks_t: _cairo_script_interpreter_hooks: make struct! [
	  closure [integer!]
	  surface_create [callback]
	  surface_destroy [callback]
	  context_create [callback]
	  context_destroy [callback]
	  show_page [callback]
	  copy_page [callback]
	] none ;

	if cairo_this_version >= 11000 [
	cairo_script_interpreter_create: make routine! [ return: [integer!] ] cairo-lib "cairo_script_interpreter_create" 
	cairo_script_interpreter_install_hooks: make routine! [ ctx [integer!]
	 hooks [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_install_hooks" 

	cairo_script_interpreter_run: make routine! [ ctx [integer!]
	 filename [string!] return: [integer!] ] cairo-lib "cairo_script_interpreter_run" 

	cairo_script_interpreter_feed_stream: make routine! [ ctx [integer!]
	 stream [integer!] return: [string!] ] cairo-lib "cairo_script_interpreter_feed_stream" 

	cairo_script_interpreter_feed_string: make routine! [ ctx [integer!]
	 line [string!]
	 len [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_feed_string" 

	cairo_script_interpreter_get_line_number: make routine! [ ctx [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_get_line_number" 
	cairo_script_interpreter_reference: make routine! [ ctx [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_reference" 
	cairo_script_interpreter_finish: make routine! [ ctx [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_finish" 
	cairo_script_interpreter_destroy: make routine! [ ctx [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_destroy" 
	cairo_script_interpreter_translate_stream: make routine! [ stream [integer!]
	 write_func [integer!]
	 closure [integer!] return: [integer!] ] cairo-lib "cairo_script_interpreter_translate_stream" 
	]
	]

{ cairo-svg.h }
	{ cairo - a vector graphics library with display and print output
	 *
	 * cairo-svg.h
	 *
	 * Copyright © 2005 Emmanuel Pacaud <emmanuel.pacaud@univ-poitiers.fr>
	 *
	 }

	{*
	 * cairo_svg_version_t:
	 * @CAIRO_SVG_VERSION_1_1: The version 1.1 of the SVG specification.
	 * @CAIRO_SVG_VERSION_1_2: The version 1.2 of the SVG specification.
	 *
	 }

	CAIRO_SVG_VERSION_1_1: 0
	CAIRO_SVG_VERSION_1_2: 1

	cairo_svg_version_t: integer!;

	{*
	 * cairo_svg_unit_t:
	 *
	 * @CAIRO_SVG_UNIT_USER: User unit, a value in the current coordinate system.
	 *   If used in the root element for the initial coordinate systems it
	 *   corresponds to pixels. (Since 1.16)
	 * @CAIRO_SVG_UNIT_EM: The size of the element's font. (Since 1.16)
	 * @CAIRO_SVG_UNIT_EX: The x-height of the element’s font. (Since 1.16)
	 * @CAIRO_SVG_UNIT_PX: Pixels (1px = 1/96th of 1in). (Since 1.16)
	 * @CAIRO_SVG_UNIT_IN: Inches (1in = 2.54cm = 96px). (Since 1.16)
	 * @CAIRO_SVG_UNIT_CM: Centimeters (1cm = 96px/2.54). (Since 1.16)
	 * @CAIRO_SVG_UNIT_MM: Millimeters (1mm = 1/10th of 1cm). (Since 1.16)
	 * @CAIRO_SVG_UNIT_PT: Points (1pt = 1/72th of 1in). (Since 1.16)
	 * @CAIRO_SVG_UNIT_PC: Picas (1pc = 1/6th of 1in). (Since 1.16)
	 * @CAIRO_SVG_UNIT_PERCENT: Percent, a value that is some fraction of another
	 *   reference value. (Since 1.16)
	 *
	 * Since: 1.16
	 *}

	CAIRO_SVG_UNIT_USER: 0
	CAIRO_SVG_UNIT_EM: 1
	CAIRO_SVG_UNIT_EX: 2
	CAIRO_SVG_UNIT_PX: 3
	CAIRO_SVG_UNIT_IN: 4
	CAIRO_SVG_UNIT_CM: 5
	CAIRO_SVG_UNIT_MM: 6
	CAIRO_SVG_UNIT_PT: 7
	CAIRO_SVG_UNIT_PC: 8
	CAIRO_SVG_UNIT_PERCENT: 9

	cairo_svg_unit_t: integer!;

	if cairo_this_version >= 10200 [
	cairo_svg_surface_create: make routine! [ filename [string!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_svg_surface_create" 

	cairo_svg_surface_create_for_stream: make routine! [ write_func [integer!]
	 closure [integer!]
	 width_in_points [double]
	 height_in_points [double] return: [integer!] ] cairo-lib "cairo_svg_surface_create_for_stream" 

	cairo_svg_surface_restrict_to_version: make routine! [ surface [integer!]
	 version [integer!] return: [integer!] ] cairo-lib "cairo_svg_surface_restrict_to_version" 

	cairo_svg_get_versions: make routine! [ versions [integer!] num_versions  [integer!] ] cairo-lib "cairo_svg_get_versions" 
	cairo_svg_version_to_string: make routine! [ version [char!] return: [string!] ] cairo-lib "cairo_svg_version_to_string" 
	]
	if cairo_this_version >= 11600 [
	cairo_svg_surface_get_document_unit: make routine! [ surface [integer!] return: [cairo_svg_unit_t] ] cairo-lib "cairo_svg_surface_get_document_unit" 
	cairo_svg_surface_set_document_unit: make routine! [ surface [integer!] unit [integer!] ] cairo-lib "cairo_svg_surface_set_document_unit" 
	]

{ cairo-tee.h }
	if CAIRO_HAS_TEE_SURFACE [
	if cairo_this_version >= 11000 [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2009 Chris Wilson
	 *
	 * The Initial Developer of the Original Code is Chris Wilson
	 *
	 * Contributor(s):
	 *	Chris Wilson <chris@chris-wilson.co.uk>
	 }


	cairo_tee_surface_create: make routine! [ master [integer!] return: [integer!] ] cairo-lib "cairo_tee_surface_create" 
	cairo_tee_surface_add: make routine! [ surface [integer!]
	 target [integer!] return: [integer!] ] cairo-lib "cairo_tee_surface_add" 

	cairo_tee_surface_remove: make routine! [ surface [integer!]
	 target [integer!] return: [integer!] ] cairo-lib "cairo_tee_surface_remove" 

	cairo_tee_surface_index: make routine! [ surface [integer!]
	 index [integer!] return: [integer!] ] cairo-lib "cairo_tee_surface_index" 
	]
	]

{ cairo-vg.h }
	if CAIRO_HAS_VG_SURFACE [
	{ -*- Mode: c; tab-width: 8; c-basic-offset: 4; indent-tabs-mode: t; -*- }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2007 * Mozilla Corporation
	 * Copyright © 2009 Chris Wilson
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is Mozilla Corporation.
	 *
	 * Contributor(s):
	 *      Vladimir Vukicevic <vladimir@mozilla.com>
	 *      Chris Wilson <chris@chris-wilson.co.uk>
	 }


	;typedef struct _cairo_vg_context cairo_vg_context_t;

	if CAIRO_HAS_GLX_FUNCTIONS [
	;typedef struct __GLXcontextRec *GLXContext;
	;typedef struct _XDisplay Display;

	cairo_vg_context_create_for_glx: make routine! [ dpy [integer!]
	 ctx [integer!] return: [integer!] ] cairo-lib "cairo_vg_context_create_for_glx" 
	]

	if CAIRO_HAS_EGL_FUNCTIONS [
	cairo_vg_context_create_for_egl: make routine! [ egl_display [struct! []]
	 egl_context [EGLContext] return: [integer!] ] cairo-lib "cairo_vg_context_create_for_egl" 
	]

	cairo_vg_context_status: make routine! [ context [integer!] return: [cairo_status_t] ] cairo-lib "cairo_vg_context_status" 
	cairo_vg_context_destroy: make routine! [ context [integer!] return: [integer!] ] cairo-lib "cairo_vg_context_destroy" 
	cairo_vg_surface_create: make routine! [ context [integer!]
	 content [cairo_content_t] width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_vg_surface_create" 

	cairo_vg_surface_create_for_image: make routine! [ context [integer!]
	 image [VGImage]
	 format [VGImageFormat]
	 width [integer!] height [integer!] return: [integer!] ] cairo-lib "cairo_vg_surface_create_for_image" 

	cairo_vg_surface_get_image: make routine! [ abstract_surface [integer!] return: [VGImage] ] cairo-lib "cairo_vg_surface_get_image" 
	cairo_vg_surface_get_format: make routine! [ abstract_surface [integer!] return: [VGImageFormat] ] cairo-lib "cairo_vg_surface_get_format" 
	cairo_vg_surface_get_height: make routine! [ abstract_surface [integer!] return: [integer!] ] cairo-lib "cairo_vg_surface_get_height" 
	cairo_vg_surface_get_width: make routine! [ abstract_surface [integer!] return: [integer!] ] cairo-lib "cairo_vg_surface_get_width" 
	]

{ cairo-win32.h }
	{ -*- Mode: c; tab-width: 8; c-basic-offset: 4; indent-tabs-mode: t; -*- }
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2005 Red Hat, Inc
	 *
	 * Contributor(s):
	 *	Owen Taylor <otaylor@redhat.com>
	 }

	;#include <windows.h>

	cairo_win32_surface_create: make routine! [ hdc [string!] return: [string!] ] cairo-lib "cairo_win32_surface_create" 
	if cairo_this_version >= 11400 [
	cairo_win32_surface_create_with_format: make routine! [ hdc [integer!]
	 format [cairo_format_t] return: [integer!] ] cairo-lib "cairo_win32_surface_create_with_format" 
	]
	if cairo_this_version >= 10600 [
	cairo_win32_printing_surface_create: make routine! [ hdc [integer!] return: [integer!] ] cairo-lib "cairo_win32_printing_surface_create" 
	]
	if cairo_this_version >= 10400 [
	cairo_win32_surface_create_with_ddb: make routine! [ hdc [integer!]
	 format [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_win32_surface_create_with_ddb" 
	cairo_win32_surface_get_image: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_win32_surface_get_image" 
	]
	if cairo_this_version >= 10200 [
	cairo_win32_surface_create_with_dib: make routine! [ format [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_win32_surface_create_with_dib" 

	cairo_win32_surface_get_dc: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_win32_surface_get_dc" 
	]

	{
	* Win32 font support
	}

		cairo_win32_font_face_create_for_logfontw: make routine! [ logfont [integer!] return: [integer!] ] cairo-lib "cairo_win32_font_face_create_for_logfontw" 
		cairo_win32_font_face_create_for_hfont: make routine! [ font [integer!] return: [integer!] ] cairo-lib "cairo_win32_font_face_create_for_hfont" 
		if cairo_this_version >= 10600 [
		cairo_win32_font_face_create_for_logfontw_hfont: make routine! [ logfont [integer!] font [integer!] return: [integer!] ] cairo-lib "cairo_win32_font_face_create_for_logfontw_hfont" 
		]
		cairo_win32_scaled_font_select_font: make routine! [ scaled_font [integer!]
		 hdc [integer!] return: [integer!] ] cairo-lib "cairo_win32_scaled_font_select_font" 

		cairo_win32_scaled_font_done_font: make routine! [ scaled_font [integer!] return: [integer!] ] cairo-lib "cairo_win32_scaled_font_done_font" 
		cairo_win32_scaled_font_get_metrics_factor: make routine! [ scaled_font [integer!] return: [double] ] cairo-lib "cairo_win32_scaled_font_get_metrics_factor" 
		if cairo_this_version >= 10400 [
		cairo_win32_scaled_font_get_logical_to_device: make routine! [ scaled_font [integer!]
		 logical_to_device [integer!] return: [integer!] ] cairo-lib "cairo_win32_scaled_font_get_logical_to_device" 

		cairo_win32_scaled_font_get_device_to_logical: make routine! [ scaled_font [integer!]
		 device_to_logical [integer!] return: [integer!] ] cairo-lib "cairo_win32_scaled_font_get_device_to_logical" 
		]
{ cairo-xcb.h }
	if CAIRO_HAS_XCB_SURFACE [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2002 University of Southern California
	 * Copyright © 2009 Intel Corporation
	 *
	 * The Initial Developer of the Original Code is University of Southern
	 * California.
	 *
	 * Contributor(s):
	 *	Carl D. Worth <cworth@cworth.org>
	 *	Chris Wilson <chris@chris-wilson.co.uk>
	 }


	if cairo_this_version >= 11200 [
	cairo_xcb_surface_create: make routine! [ connection [integer!]
	 drawable [integer!]
	 visual [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xcb_surface_create" 

	cairo_xcb_surface_create_for_bitmap: make routine! [ connection [integer!]
	 screen [integer!]
	 bitmap [xcb_pixmap_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xcb_surface_create_for_bitmap" 

	cairo_xcb_surface_create_with_xrender_format: make routine! [ connection [integer!]
	 screen [integer!]
	 drawable [xcb_drawable_t]
	 format [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xcb_surface_create_with_xrender_format" 

	cairo_xcb_surface_set_size: make routine! [ surface [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xcb_surface_set_size" 

	cairo_xcb_surface_set_drawable: make routine! [ surface [integer!]
	 drawable [xcb_drawable_t]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xcb_surface_set_drawable" 

	cairo_xcb_device_get_connection: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_xcb_device_get_connection" 

	{ debug interface }
	cairo_xcb_device_debug_cap_xshm_version: make routine! [ device [integer!]
	 major_version [integer!]
	 minor_version [integer!] return: [integer!] ] cairo-lib "cairo_xcb_device_debug_cap_xshm_version" 

	cairo_xcb_device_debug_cap_xrender_version: make routine! [ device [integer!]
	 major_version [integer!]
	 minor_version [integer!] return: [integer!] ] cairo-lib "cairo_xcb_device_debug_cap_xrender_version" 

	{
	 * @precision: -1 implies automatically choose based on antialiasing mode,
	 *            any other value overrides and sets the corresponding PolyMode.
	 }

	cairo_xcb_device_debug_set_precision: make routine! [ device [integer!]
	 precision [integer!] return: [integer!] ] cairo-lib "cairo_xcb_device_debug_set_precision" 

	cairo_xcb_device_debug_get_precision: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_xcb_device_debug_get_precision" 
	]
	]

{ cairo-xlib.h }
	if CAIRO_HAS_XLIB_SURFACE [
	if cairo_this_version >= 11000 [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2002 University of Southern California
	 *
	 * The Initial Developer of the Original Code is University of Southern
	 * California.
	 *
	 * Contributor(s):
	 *	Carl D. Worth <cworth@cworth.org>
	 }


	cairo_xlib_surface_create: make routine! [ dpy [integer!]
	 drawable [integer!]
	 visual [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_create" 

	cairo_xlib_surface_create_for_bitmap: make routine! [ dpy [integer!]
	 bitmap [Pixmap]
	 screen [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_create_for_bitmap" 

	cairo_xlib_surface_set_size: make routine! [ surface [integer!]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_set_size" 

	cairo_xlib_surface_set_drawable: make routine! [ surface [integer!]
	 drawable [Drawable]
	 width [integer!]
	 height [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_set_drawable" 

	if cairo_this_version >= 10200 [
	cairo_xlib_surface_get_display: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_get_display" 
	cairo_xlib_surface_get_drawable: make routine! [ surface [integer!] return: [Drawable] ] cairo-lib "cairo_xlib_surface_get_drawable" 
	cairo_xlib_surface_get_screen: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_get_screen" 
	cairo_xlib_surface_get_visual: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_get_visual" 
	cairo_xlib_surface_get_depth: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_get_depth" 
	cairo_xlib_surface_get_width: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_get_width" 
	cairo_xlib_surface_get_height: make routine! [ surface [integer!] return: [integer!] ] cairo-lib "cairo_xlib_surface_get_height" 
	]
	{ debug interface }
	cairo_xlib_device_debug_cap_xrender_version: make routine! [ device [integer!]
	 major_version [integer!]
	 minor_version [integer!] return: [integer!] ] cairo-lib "cairo_xlib_device_debug_cap_xrender_version" 

	{
	 * @precision: -1 implies automatically choose based on antialiasing mode,
	 *            any other value overrides and sets the corresponding PolyMode.
	 }

	cairo_xlib_device_debug_set_precision: make routine! [ device [integer!]
	 precision [integer!] return: [integer!] ] cairo-lib "cairo_xlib_device_debug_set_precision" 

	cairo_xlib_device_debug_get_precision: make routine! [ device [integer!] return: [integer!] ] cairo-lib "cairo_xlib_device_debug_get_precision" 
	]
	]

{ cairo-xml.h }
	if CAIRO_HAS_XML_SURFACE [
	if cairo_this_version >= 11000 [
	{ cairo - a vector graphics library with display and print output
	 *
	 * Copyright © 2009 Chris Wilson
	 *
	 *
	 * The Original Code is the cairo graphics library.
	 *
	 * The Initial Developer of the Original Code is Chris Wilson
	 *
	 * Contributor(s):
	 *	Chris Wilson <chris@chris-wilson.co.uk>
	 }


	cairo_xml_create: make routine! [ filename [string!] return: [integer!] ] cairo-lib "cairo_xml_create" 
	cairo_xml_create_for_stream: make routine! [ write_func [cairo_write_func_t]
	 closure [integer!] return: [integer!] ] cairo-lib "cairo_xml_create_for_stream" 

	cairo_xml_surface_create: make routine! [ xml [integer!]
	 content [cairo_content_t]
	 width [double] height [double] return: [integer!] ] cairo-lib "cairo_xml_surface_create" 

	cairo_xml_for_recording_surface: make routine! [ xml [integer!]
	 surface [integer!] return: [cairo_status_t] ] cairo-lib "cairo_xml_for_recording_surface" 

	]
	]
;
{************************************************************
** Rebol specific functions
************************************************************}
surface-to-image: func [
	"Convert a cairo surface to a Rebol image!"
	surface [integer!] "pointer to cairo surface"
	/local
		width height stride
		image
	][
	
	{
	cairo_surface_write_to_png surface "c.png"
	image: load %c.png
	delete %c.png
	}
	width: cairo_image_surface_get_width surface
	height: cairo_image_surface_get_height surface
	if any [width = 0 height = 0] [return none]
	stride: cairo_image_surface_get_stride surface
	; convert to binary!
	image: get-mem?/part cairo_image_surface_get_data surface stride * height
	image: to image! image
	image/size: as-pair width height
	image/alpha: complement image/alpha

	image
]
image-to-surface: func [
	"Convert image! to a cairo surface"
	image [image!]
	/local
		stride surf
	][
	stride: cairo_format_stride_for_width CAIRO_FORMAT_ARGB32 image/size/x
	image/alpha: complement image/alpha
	surf: cairo_image_surface_create_for_data to binary! image CAIRO_FORMAT_ARGB32 image/size/x image/size/y stride
	image/alpha: complement image/alpha ; restore rebol alpha
	surf
]
fetch: func [
	"Returns first found element (or given default) and removes it"
	block [block! none!] value default
	][
	if none? block [return default]
	if block: find block value [
		default: pick block 1
		remove block
	]
	default
]
system/error: make system/error [
	draw-cairo: make object! [
		code: 1000
		type: "Draw cairo Error"
		syntax: ["in draw block Near: " :arg1]
		syntax-shape: ["in shape block Near: " :arg1]
	]
]
; things of Rebol2-AGG to be rethinked/re-implemented in a different way
{
 gradients are different (not linear?)
 dashes are placed over lines, should be separated
 were a (multiple)scalar value is accepted, less types should be accepted (instead of so musch tolerance)
 off (false) , none or nothing means disable
 on (true) shoukd be: restore previous value
 nothing could mean set default value
 line-width scaling or uniform
 line with many points should be a multi-line instead of many "independent" lines
 circle could have (in whatever order) center pair! axes number!s or pair!
 circle with nothing should be centered circle with max radius
 circle with number! should be centered circle with that radius
 ellipse could have (in whatever order) center pair! axes number!s or ul-point pair! lr-point pair!
 ellipse with ... similar to circle as above
 box with one pair! should be centered box with given ul-point and diagonal-symmetrical lr-point
 box's negative radius values should give "inset" rounded corners
 add "rectangle" with center pair! axes number!s or pair!
 curve of Rebol-AGG shape IMHO is wrong, mine is correct
 arc with only one pair! should be centered on the image and given pair! gives radii
 shape-arc rotation angle in Rebol2-AGG is given in radians (while all other angles are in degrees)
}
;
;set 'setted copy []
convert-block-words: func [
	; recursively convert none pair! number! tuple! logic! object! image!, unset!
	block [block!]
	/local
		item
	][
	forskip block 1 [
		if 'none = block/1 [block/1: none]
		if word? block/1 [
			if find [pair! number! tuple! logic! object! image!] type?/word item: attempt [get block/1] [block/1: item]
		]
		if unset? block/1 [remove block]
		
		if block? block/1 [block/1: convert-block-words block/1]
	]
	;probe
	head block
]
draw-cairo: funct [ ; all locals
	"Draws scalable vector graphics using cairo graphics to an image (returned)."
	[catch]
	image [image!]
	
	block [block!]
	/local
		; these are "setted" inside rules
		pen1 pen2 mode stroke-size dash-size disable toffset matrix-setup draw-block shape-block border var
	][
	recycle
	recycle/off ; avoid crush when using images
	
	image/alpha: 255 ; clear alpha

	cairo-ctx: cairo_create surfac: image-to-surface image

	; make clear transparent background (otherwise transparencies are "partial")
	cairo_set_operator cairo-ctx CAIRO_OPERATOR_CLEAR
	cairo_set_source_rgba cairo-ctx 1 1 1 1
	cairo_paint cairo-ctx
	cairo_set_operator cairo-ctx CAIRO_OPERATOR_OVER ; restore default

	;
	block: convert-block-words compose/deep block

	; init
		degrees: pi / 180.0
		to-radians: pi / 180.0
		to-degrees: 180.0 / pi
		pen: white
		fill-pen: none
		dpen: none
		line-width: 1.0
		line-points: copy []
		poly-points: copy []
		dashes: copy []
		text-vals: [0 0 0]
		mat-pat: copy [1 0 0 1 0 0]
		font-object: make system/standard/face/font [
			color: pen
		]
		&x1: dbl-ptr &y1: dbl-ptr &x2: dbl-ptr &y2: dbl-ptr
		cairo_clip_extents cairo-ctx &x1 &y1 &x2 &y2
		;print [&x1/value &y1/value &x2/value &y2/value]
	; defaults
		cairo_set_line_width cairo-ctx line-width
	

	arc_svg: funct [ ; auto-locals
		x1 y1
		rx ry
		angle
		large_arc_flag
		sweep_flag
		x2 y2
		] [
		{;--------------------------
			; origin will be 2nd point
			; translate, then rotate, then scale
			; force minimum radius
			; calc intersection(s) of 2 circles
			; find angle and rotate circle
			; find angle of pie
		};--------------------------

		if any [rx = 0.0 ry = 0.0] [return none]
		
		point-point-distance: func [p1x p1y p2x p2y][
			square-root (((p2x - p1x) ** 2) + ((p2y - p1y) ** 2))
		]
		circle-circle-intersections: funct [c1x c1y r1 c2x c2y r2][
			d: point-point-distance c1x c1y c2x c2y
			a: ((r1 ** 2) - (r2 ** 2) + (d ** 2) ) / (2 * d)
			h_d: (square-root abs (r1 ** 2) - (a ** 2)) / d
			px: (c2x - c1x) * a / d + c1x
			py: (c2y - c1y) * a / d + c1y
			i1x: (c2y - c1y) * h_d + px
			i1y: (c2x - c1x) * - h_d + py
			;i2x: (c2y - c1y) * - h_d + px
			;i2y: (c2x - c1x) * h_d + py
			i2x: px + px - i1x
			i2y: py + py - i1y
			reduce [i1x i1y i2x i2y]
		]
		atan2: func [; author: Steeve Antoine 2009
			"Angle in radians of the vector (0,0)-(x,y) with arctangent y / x. The resulting angle is extended to -pi,+pi"
			x [number!] y [number!]
			][
			if x = 0 [x: 0.0000000001]
			;add arctangent y / x pick [0 180] x > 0
			add arctangent/radians y / x pick reduce [0 pi] x > 0
		]
		three-points-angle: func [Ax Ay Vx Vy Bx By][
			(atan2 Ax - Vx Ay - Vy) - (atan2 Bx - Vx By - Vy)
		]

		rx: abs rx
		ry: abs ry

		old_x2: x2
		old_y2: y2
		
		max_r: max rx ry
		either rx < ry [
			sx: ry / rx
			sy: 1
		][
			sx: 1
			sy: rx / ry
		]
		ptr_x: dbl-ptr ptr_y: dbl-ptr

		; translate, then rotate, then scale
		; the 1st point relative to 2nd point after translating this to the origin
		;------------------------
		cairo_matrix_init_identity mat: block-to-struct/doubles [1 0 0 1 0 0]
		
		ptr_x/value: x1 ptr_y/value: y1
		cairo_matrix_scale mat sx sy
		cairo_matrix_rotate mat (- angle)
		cairo_matrix_translate mat (- x2) (- y2)
		cairo_matrix_transform_point mat ptr_x ptr_y
		x1: ptr_x/value y1: ptr_y/value

		x2: y2: 0.0 ; 2nd point is on the origin

		dist: point-point-distance x1 y1 x2 y2
		old_max_r: max_r
		if dist > (max_r * 2) [max_r: dist / 2]

		cx: 0
		cy: max_r
		ccis: circle-circle-intersections cx cy max_r x2 y2 dist

		; find angles
		either large_arc_flag = sweep_flag [
			ang: three-points-angle ccis/1 ccis/2 x2 y2 x1 y1
		][
			ang: three-points-angle ccis/3 ccis/4 x2 y2 x1 y1
		]

		ptr_x/value: cx ptr_y/value: cy
		cairo_matrix_init_identity mat
		cairo_matrix_rotate mat (- ang)
		cairo_matrix_transform_point mat ptr_x ptr_y
		cx: ptr_x/value cy: ptr_y/value

		ang-s:  three-points-angle x2 y2 cx cy cx + 1 cy
		ang-e: ang-s + three-points-angle x1 y1 cx cy x2 y2

		; place center of ellipse where it should be
		ptr_x/value: cx ptr_y/value: cy
		cairo_matrix_init_identity mat
		cairo_matrix_translate mat old_x2 old_y2
		cairo_matrix_rotate mat angle
		cairo_matrix_scale mat 1 / sx 1 / sy
		cairo_matrix_transform_point mat ptr_x ptr_y
		cx: ptr_x/value cy: ptr_y/value
		
		;probe 
		reduce [ cx cy ang-s ang-e max_r / old_max_r]
	]
	; convert spline to bezier curves
		; "manually" draw a bezier curve because cairo does not allow setting subdivision parameter
		bezier_to_lines: func [
			res
			p1_x p1_y p2_x p2_y p3_x p3_y p4_x p4_y
			/local
				ax bx cx dx ay by cy dy
				t s tx ty
			][
			dx: p1_x
			cx: 3 * (p2_x - p1_x)
			bx: 3 * (p3_x - p2_x) - cx
			ax: p4_x - p1_x - cx - bx

			dy: p1_y
			cy: 3 * (p2_y - p1_y)
			by: 3 * (p3_y - p2_y) - cy
			ay: p4_y - p1_y - cy - by

			t: 0 ; ensure curve passes through first point
			s: 1 / res ;this value sets the quality of the curve
			while [true][
				tx: ax * t + bx * t + cx * t + dx ; cubeless form
				ty: ay * t + by * t + cy * t + dy ; cubeless form

				cairo_line_to cairo-ctx tx ty

				if t = 1.0 [break]
				t: min t + s 1.0 ; step to next value but also ensure curve passes through last point
			]
		]
		cfor: func [
			{General loop}
			[throw catch]
			init [block!]
			test [block!]
			inc [block!]
			body [block!]
			/local result
			] [
			do init while [do test] [set/any 'result do body do inc] get/any 'result
		]
		;https://www.codeproject.com/Articles/31859/Draw-a-Smooth-Curve-through-a-Set-of-2D-Points-wit
		;http://www.particleincell.com/2012/bezier-splines/
		computeControlPoints: func [
			"computes control points given knots K"
			K [block!] 
			/local
			 p1 p2 n
			 a b c r i m
			][
			n: length? K ;.length-1
			;?? n
			p1: array/initial n 0 ;new Array
			p2: array/initial n 0 ;new Array
			
			;/*rhs vector*/
			a: array/initial n 0 ;new Array
			b: array/initial n 0 ;new Array
			c: array/initial n 0 ;new Array
			r: array/initial n 0 ;new Array
			
			;/*left most segment*/
			a/1: 0
			b/1: 2
			c/1: 1
			r/1: K/1 + (2 * K/2)
			
			;/*internal segments*/
			cfor [i: 2] [i <= (n - 1)] [i: i + 1]
			[
				a/(i): 1
				b/(i): 4
				c/(i): 1
				r/(i): (4 * K/(i)) + (2 * K/(i + 1))
			]
					
			;/*right segment*/
			a/(n - 1): 2
			b/(n - 1): 7
			c/(n - 1): 0
			r/(n - 1): (8 * K/(n - 1)) + K/(n)

			;?? a ?? b ?? c ?? r
			
			;/*solves Ax = b with the Thomas algorithm from Wikipedia */
			cfor [i: 2] [i <= n] [i: i + 1]
			[
				m: a/(i) / b/(i - 1)
				b/(i): b/(i) - (m * c/(i - 1))
				r/(i): r/(i) - (m * r/(i - 1))
			]

			p1/(n - 1): r/(n - 1) / b/(n - 1)

			cfor [i: n - 1] [i >= 1] [i: i - 1]
			[
				p1/(i): (r/(i) - (c/(i) * p1/(i + 1))) / b/(i)
			]
			;/*we have p1 now compute p2*/
			cfor [i: 1] [i <= (n - 2)] [i: i + 1]
			[
				p2/(i): 2 * K/(i + 1) - p1/(i + 1)
			]
			p2/(n - 1): 0.5 * (K/(n) + p1/(n - 1))
			
			;probe
			append p1 p2
		]
	;
	
	fill_and_stroke: func [
		/local
			mat pat surf old-mat
		][
		case [
		tuple? fill-pen [
			fill-pen: fill-pen + 0.0.0.0
			cairo_set_source_rgba cairo-ctx fill-pen/1 / 255.0 fill-pen/2 / 255.0 fill-pen/3 / 255.0 255 - fill-pen/4 / 255.0

			cairo_fill_preserve cairo-ctx
		]
		word? fill-pen [
			switch/default fill-pen [
				linear [pat: cairo_pattern_create_linear g-offset/x g-offset/y g-offset/x + g-end g-offset/y]
				radial [pat: cairo_pattern_create_radial g-offset/x g-offset/y 0 g-offset/x g-offset/y g-end]
			] [pat: false]
			if pat [
				t: 0 s: 1 / ((length? colors) - 1)
				foreach color colors [
					cairo_pattern_add_color_stop_rgb pat t color/1 / 255 color/2 / 255 color/3 / 255
					t: t + s
				]
				cairo_set_source cairo-ctx pat
				cairo_fill_preserve cairo-ctx
				cairo_pattern_destroy pat
			]
		]
		image? fill-pen [
		
			surf: image-to-surface fill-pen
			pat: cairo_pattern_create_for_surface surf
			cairo_pattern_set_extend pat CAIRO_EXTEND_REPEAT
			cairo_matrix_init_identity mat: block-to-struct/doubles [1 0 0 1 0 0]
			; rebol or cairo or my bug (?) makes me to not have a "right" not scaled image
			cairo_matrix_scale mat mat-pat/1 + .0000000000001 mat-pat/4 + .0000000000001
			cairo_matrix_translate mat mat-pat/5 mat-pat/6
			cairo_pattern_set_matrix pat mat ;block-to-struct/doubles mat-pat 

			cairo_set_source cairo-ctx pat

			cairo_fill_preserve cairo-ctx

			cairo_pattern_destroy pat
			cairo_surface_destroy surf
		]
		]
		;prin "fs " ?? pen ?? dpen
		if none? pen [pen: 0.0.0.255] ; transparent
		if none? dpen [dpen: 0.0.0.255] ; transparent
		if pen [
			cairo_get_matrix cairo-ctx mat: block-to-struct/doubles [0 0 0 0 0 0]
			old-mat: make struct! mat second mat
			mat/_1: mat/_4: max mat/_1 mat/_4; uniform scaling
			mat/_2: mat/_3: 0 ; avoid skew
			; avoid scaling stroke
			cairo_set_matrix cairo-ctx mat
			; FIXME: is this a better implementation?
			{
			if tuple? dpen [
				dpen: dpen + 0.0.0.0 ; add also alpha channel
				cairo_set_source_rgba cairo-ctx dpen/1 / 255.0 dpen/2 / 255.0 dpen/3 / 255.0 255 - dpen/4 / 255.0
				bin-dashes: block-to-struct reverse copy dashes
				cairo_set_dash cairo-ctx bin-dashes length? dashes negate any [dashes/1 0]
				cairo_stroke_preserve cairo-ctx
			]
			pen: pen + 0.0.0.0 ; add also alpha channel
			cairo_set_source_rgba cairo-ctx pen/1 / 255.0 pen/2 / 255.0 pen/3 / 255.0 255 - pen/4 / 255.0
			either tuple? dpen [
				bin-dashes: block-to-struct dashes
				cairo_set_dash cairo-ctx bin-dashes length? dashes 0;dashes/1
			][
				cairo_set_dash cairo-ctx make struct! [] none 0 0
			]
			cairo_stroke cairo-ctx
			}
			; same as Rebol-AGG
			pen: pen + 0.0.0.0 ; add also alpha channel
			cairo_set_source_rgba cairo-ctx pen/1 / 255.0 pen/2 / 255.0 pen/3 / 255.0 255 - pen/4 / 255.0
			if tuple? dpen [
				cairo_set_dash cairo-ctx make struct! [] none 0 0
				cairo_stroke_preserve cairo-ctx
				dpen: dpen + 0.0.0.0 ; add also alpha channel
				cairo_set_source_rgba cairo-ctx dpen/1 / 255.0 dpen/2 / 255.0 dpen/3 / 255.0 255 - dpen/4 / 255.0
				bin-dashes: block-to-struct/doubles reverse copy dashes
				cairo_set_dash cairo-ctx bin-dashes length? dashes negate any [dashes/1 0]
			]
			cairo_stroke cairo-ctx
			;restore pen color
			cairo_set_source_rgba cairo-ctx pen/1 / 255.0 pen/2 / 255.0 pen/3 / 255.0 255 - pen/4 / 255.0

			cairo_set_matrix cairo-ctx old-mat
		]
	]
	fail: [end skip]
	not-rule: [[b (go: fail) | (go: none)] go] 
	quote: func ['b /local rul] [rul: [copy c skip (d: unless equal? c [_] [fail]) d] rul/4/5/1: :b rul]; author: Ladislav Mecir

	quadratic-to-cubic: [
				; convert quadratic to cubic
				point4: point3
				temp:   2 / 3 * (point2 - point1) + point1 ; FIXME: truncated results
				point3: 1 / 3 * (point3 - point2) + point2
				point2: temp
	]
	arc-abs: [
				radius-x: fetch values number! 0.1
				radius-y: fetch values number! radius-x
				angle: fetch values number! 0
				sweep: fetch values logic! false
				large: fetch values logic! false

				if
				arc_svg_bl: arc_svg point1/x point1/y radius-x radius-y angle large sweep point2/x point2/y
				[
				angle-begin: arc_svg_bl/3
				angle-end: arc_svg_bl/4
				cairo_save cairo-ctx
				cairo_translate cairo-ctx arc_svg_bl/1 arc_svg_bl/2 ; center
				cairo_rotate cairo-ctx angle
				cairo_scale cairo-ctx radius-x * arc_svg_bl/5 radius-y * arc_svg_bl/5
				either sweep [
					cairo_arc cairo-ctx 0 0 1 angle-begin angle-end
				][
					cairo_arc_negative cairo-ctx 0 0 1 angle-begin angle-end
				]
				cairo_restore cairo-ctx
				]
	]

	next-word-rule: [to word! | to lit-word! | to end]
	text-rule: [
		  pos: string! :pos set text-string string!
		| pos: pair! :pos set offset pair!
		| pos: word! :pos set render-mode ['anti-aliased | 'aliased | 'vectorial]
	]
	shape-rule: [
		  'MOVE set point1 pair! (cairo_move_to cairo-ctx point1/x point1/y)
		| 'LINE any [set point1 pair! (cairo_line_to cairo-ctx point1/x point1/y)]
		| 'HLINE any [set point2 number! (point1/x: point2 cairo_line_to cairo-ctx point1/x point1/y)]
		| 'VLINE any [set point2 number! (point1/y: point2 cairo_line_to cairo-ctx point1/x point1/y)]
		| 'ARC copy values next-word-rule ;(prin "values " probe values)
			(
				point2: fetch values pair! 0x0
				do arc-abs
			)
		| 'CURV set point2 pair! (prev_p2: point2)
				set point3 pair! ; FIXME: make this optional
			(
				do quadratic-to-cubic
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)
			any [
				set point3 pair!
				set point4 pair! ; FIXME: make this optional
			(
				; add symmetric point
				point2: point1 + (point1 - prev_p2)

				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
				prev_p2: point3
			)
			]
		| 'CURVE some [
				set point2 pair!
				set point3 pair!
				set point4 pair!
			(
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)]
			; FIXME: allow also a number of points not divisible by 3
		| 'QCURV set point2 pair! (prev_p2: point1)
				set point3 pair! ; FIXME: make this optional
			(
				cairo_line_to cairo-ctx point2/x point2/y
				
				; add symmetric point
				point2: point2 + (point2 - prev_p2)
				prev_p2: point2

				;do quadratic-to-cubic
				; why does Rebol-AGG do this instead of above ?
				point4: point3
				temp:   3 / 4 * (point2 - point1) + point1 ; FIXME: truncated results
				point3: 1 / 4 * (point3 - point2) + point2
				point2: temp
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)
			any [
				set point3 pair!
			(
				; add symmetric point
				point2: point1 + (point1 - prev_p2)
				prev_p2: point2

				do quadratic-to-cubic
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)
				]
		| 'QCURVE some [
				set point2 pair!
				set point3 pair!
			(
				do quadratic-to-cubic
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)]
	]
	shape-rel-rule: [
		  (lw: quote 'MOVE) lw set point1 pair! (cairo_new_sub_path cairo-ctx cairo_move_to cairo-ctx point1/x point1/y)
		| (lw: quote 'LINE) lw any [set delta pair! (cairo_line_to cairo-ctx point1/x: point1/x + delta/x  point1/y: point1/y + delta/y)]
		| (lw: quote 'HLINE) lw any [set delta number! (point1/x: point1/x + delta cairo_line_to cairo-ctx point1/x point1/y)]
		| (lw: quote 'VLINE) lw any [set delta number! (point1/y: point1/y + delta cairo_line_to cairo-ctx point1/x point1/y)]
		| (lw: quote 'ARC) lw copy values next-word-rule ;(prin "values " probe values)
			(
				delta: fetch values pair! point1
				point2: point1 + delta
				
				do arc-abs
				point1: point2
			)
		| (lw: quote 'CURVE) lw some [
				set point2 pair!
				set point3 pair!
				set point4 pair!
			(
				point2: point1 + point2
				point3: point1 + point3
				point4: point1 + point4
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)]
		| (lw: quote 'QCURVE) lw some [
				set point2 pair!
				set point3 pair!
			(
				point2: point1 + point2
				point3: point1 + point3
				do quadratic-to-cubic
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				point1: point4
			)]
	]
	draw-rule: [
		  'PEN
			opt [
				  [number! | pair! | logic! | none!] (pen: none) ; FIXME: IMHO this is too "tolerant"
				| set pen tuple!
				| (pen: none)
			]
			opt [ ; only 2 colors allowed for dashes
				  [number! | pair! | logic! | none!] (dpen: none)
				| set dpen tuple!
			]
			; unimplemented | set img image!
		| 'FILL-PEN opt [(fill-pen: none)
			  number! | pair! | logic! | none!
			| set fill-pen image!
			| set fill-pen tuple!
			| (g-offset: 0x0 g-begin: 0 g-end: 1 angle: 0 scale-x: 1 scale-y: 1)
			 ;FIXME: this is a fixed sequence to make it simpler
				set fill-pen ['linear | 'radial]
				set g-offset pair!
				set g-begin number! set g-end number!
				set angle number! set scale-x number! set scale-y number!
				copy colors 3 255 tuple!
			
			]
		;
		| 'BOX copy values next-word-rule
			(
				p1: fetch values pair! 0x0
				p2: fetch values pair! as-pair &x2/value &y2/value
				if p1/x > p2/x [temp: p1/x p1/x: p2/x p2/x: temp]
				if p1/y > p2/y [temp: p1/y p1/y: p2/y p2/y: temp]
				radius: fetch values number! 0
				diffx: p2/x - p1/x
				diffy: p2/y - p1/y
				radius: min min radius diffx / 2 diffy / 2
				either radius <> 0 [
					a: p1/x b: p2/x c: p1/y d: p2/y
					; FIXME: this is as Rebol-AGG but I think it would be better to have "inset" arcs for negative radius
					if radius < 0 [radius: (max diffx diffy) / 2]

					cairo_new_sub_path cairo-ctx
					cairo_arc cairo-ctx p1/x + radius p1/y + radius radius 180 * degrees 270 * degrees
					cairo_arc cairo-ctx p2/x - radius p1/y + radius radius 270 * degrees 0 * degrees
					cairo_arc cairo-ctx p2/x - radius p2/y - radius radius 0 * degrees 90 * degrees
					cairo_arc cairo-ctx p1/x + radius p2/y - radius radius 90 * degrees 180 * degrees
					cairo_close_path cairo-ctx
				][
					cairo_rectangle cairo-ctx p1/x p1/y diffx diffy
				]
				fill_and_stroke
			)
		| [   'CIRCLE copy values next-word-rule
			| 'ELLIPSE (radius: 10x10) set center pair! opt [set radius pair!] (values: reduce [center radius/x radius/y])
		  ]
			(
				center: fetch values pair! 0x0
				radius-x: fetch values number! 10
				radius-y: fetch values number! radius-x
				cairo_save cairo-ctx
				cairo_new_path cairo-ctx
				cairo_translate cairo-ctx center/x center/y
				cairo_scale cairo-ctx radius-x radius-y
				cairo_arc cairo-ctx 0 0 1 0 2 * pi
				cairo_close_path cairo-ctx
				cairo_restore cairo-ctx
				fill_and_stroke
			)
		| 'LINE
			opt  [set point1 pair! | set point1 number! (point1: point1 * 1x0)]
			any [[set point2 pair! | set point2 number! (point2: point2 * 1x0)]
			(
				cairo_move_to cairo-ctx point1/x point1/y
				cairo_line_to cairo-ctx point2/x point2/y
				fill_and_stroke
				point1: point2
			)
			]
		| 'POLYGON set point pair! 
			(
				cairo_new_path cairo-ctx
				cairo_line_to cairo-ctx point/x point/y
			)
			some [set point pair!
			(
				cairo_line_to cairo-ctx point/x point/y
			)
			]
			(
				cairo_close_path cairo-ctx
				fill_and_stroke
			)
		| 'ARC	(closed: none) copy values next-word-rule
				opt [set closed 'closed copy values2 next-word-rule (append values: any [values copy []] any [values2 copy []] )]
			(
				center: fetch values pair! 0x0
				radius: fetch values pair! as-pair &x2/value &y2/value
				angle-begin: fetch values number! 0
				angle-length: fetch values number! 0
			
				cairo_save cairo-ctx
				cairo_translate cairo-ctx center/x center/y
				cairo_scale cairo-ctx radius/x radius/y
				cairo_arc cairo-ctx 0 0 1 angle: angle-begin * degrees angle-length * degrees + angle
				if closed [
					cairo_line_to cairo-ctx 0 0
					cairo_arc cairo-ctx 0 0 1 angle-begin * degrees angle-begin * degrees
					cairo_close_path cairo-ctx
				]
				cairo_restore cairo-ctx
				
				fill_and_stroke
			)
		| 'CURVE set point1 pair!
				set point2 pair!
				set point3 opt pair!
				set point4 opt pair!
			(
				if none? point3 [point3: point2 point2: point3 - point1 / 2 + point1] ; make a line
				if none? point4 [do quadratic-to-cubic]
				cairo_move_to cairo-ctx point1/x point1/y
				cairo_curve_to cairo-ctx point2/x point2/y point3/x point3/y point4/x point4/y
				fill_and_stroke
			)
		| 'SPLINE (closed: none) copy values next-word-rule
				opt [set closed 'closed copy values2 next-word-rule (append values: any [values copy []] any [values2 copy []] )]
			(
				res: fetch values number! 1
				if all [values 2 <= length? values] [
					remove-each item values [number? item]
					either 2 = length? values [
						cairo_move_to cairo-ctx values/1/x values/1/y
						cairo_line_to cairo-ctx values/2/x values/2/y
					][
						if closed [insert insert insert tail values values/1 values/2 values/3] ; FIXME: Rebol-AGG inserts at head ?
						values-x: copy []
						repeat pair values [insert tail values-x pair/x]
						values-y: copy []
						repeat pair values [insert tail values-y pair/y]
						; convert B-spline to Beziers
						ckx: computeControlPoints values-x
						cky: computeControlPoints values-y
						
						knots: length? values

						if closed [
							; remove first curve
							remove values
							remove ckx
							remove cky
							remove at ckx knots
							remove at cky knots
							knots: knots - 1

							; remove last curve
							remove back tail values
							remove at ckx knots - 1
							remove at cky knots - 1
							remove at tail ckx -1
							remove at tail cky -1
							knots: knots - 1
						]
				
						cairo_new_path cairo-ctx
						repeat i knots - 1 [
							bezier_to_lines res values/(i)/x values/(i)/y ckx/(i) cky/(i) ckx/(i + knots) cky/(i + knots) values/(i + 1)/x values/(i + 1)/y
						]
			
					]
					fill_and_stroke
				]

			)
		; 'TRIANGLE ;unimplemented
		;
		| 'TEXT (offset: none text-string: "" render-mode: 'anti-aliased) opt text-rule opt text-rule opt text-rule
			(
				f.o: cairo_font_options_create
				cairo_font_options_set_antialias f.o switch render-mode ['anti-aliased 'vectorial [CAIRO_ANTIALIAS_DEFAULT][ CAIRO_ANTIALIAS_NONE]]
				cairo_set_font_options cairo-ctx f.o

				style: compose [(font-object/style)]
				slant: either find style 'italic [CAIRO_FONT_SLANT_ITALIC] [CAIRO_FONT_SLANT_NORMAL]
				weight: either find style 'bold [CAIRO_FONT_WEIGHT_BOLD] [CAIRO_FONT_WEIGHT_NORMAL]
				cairo_select_font_face cairo-ctx font-object/name slant weight
				cairo_set_font_size cairo-ctx font-object/size
				; using pen instead
				;cairo_set_source_rgba cairo-ctx font-object/color/1 / 255.0 font-object/color/2 / 255.0 font-object/color/3 / 255.0 255 - (any [font-object/color/4 0]) / 255.0
				if pair? offset [cairo_move_to cairo-ctx offset/x offset/y]
				either render-mode = 'vectorial [
					cairo_text_path cairo-ctx text-string
					fill_and_stroke
				][
					pen: pen + 0.0.0.0
					cairo_set_source_rgba cairo-ctx pen/1 / 255.0 pen/2 / 255.0 pen/3 / 255.0 255 - pen/4 / 255.0
					cairo_show_text cairo-ctx text-string
				]

				cairo_font_options_destroy f.o
			)
		| 'FONT opt [set font-object object!]

		| 'LINE-WIDTH (line-width: 0) [logic! | none! | set line-width opt number!] (cairo_set_line_width cairo-ctx any [line-width 1])
		| 'LINE-JOIN opt [set mode ['miter | 'miter-bevel | 'round | 'bevel]
			(
				cairo_set_line_join cairo-ctx switch mode [
					miter [CAIRO_LINE_JOIN_MITER]
					miter-bevel [CAIRO_LINE_JOIN_MITER]
					round [CAIRO_LINE_JOIN_ROUND]
					bevel [CAIRO_LINE_JOIN_BEVEL]
				]
			)
			]
		| 'LINE-CAP opt [set mode ['butt | 'square | 'round]
			(
				cairo_set_line_cap cairo-ctx switch mode [
					butt [CAIRO_LINE_CAP_BUTT]
					square [CAIRO_LINE_CAP_SQUARE]
					round [CAIRO_LINE_CAP_ROUND]
				]
			)
			]
		| 'LINE-PATTERN set stroke-size opt number! (dashes: clear head dashes append dashes any [stroke-size 1]) set dash-size opt number! (append dashes any [dash-size 0])
		| 'CLIP (ul-point: 0x0 lr-point: as-pair &x2/value &y2/value)
			[
				  logic! | none!
				| opt [set ul-point pair!] opt [set lr-point pair!]
			]
			(
				cairo_reset_clip cairo-ctx
				cairo_rectangle cairo-ctx ul-point/x ul-point/y lr-point/x - ul-point/x lr-point/y - ul-point/y
				cairo_clip cairo-ctx
			)
		| 'ANTI-ALIAS set disable logic! (cairo_set_antialias cairo-ctx either disable [CAIRO_ANTIALIAS_DEFAULT][ CAIRO_ANTIALIAS_NONE])
		| 'FILL-RULE set mode ['non-zero | 'even-odd] (cairo_set_fill_rule cairo-ctx either mode = 'non-zero [CAIRO_FILL_RULE_WINDING][ CAIRO_FILL_RULE_EVEN_ODD])

		| 'TRANSLATE opt [[set toffset pair! | set toffset number! (toffset: toffset * 1x0)] (cairo_translate cairo-ctx toffset/x toffset/y)]
		| 'ROTATE opt [set angle number! (cairo_rotate cairo-ctx angle * degrees)]
		| 'SCALE opt [set scale-x number! set scale-y number! (cairo_scale cairo-ctx scale-x scale-y)]
		| 'SKEW opt [(skew-x: 0 skew-y: 0) set skew-x number! opt [pos: number! :pos set skew-y opt number! ]
			(
				cairo_transform cairo-ctx block-to-struct/doubles reduce [1 tangent skew-y tangent skew-x 1 0 0]
			)
			]
		| 'TRANSFORM
			set angle number!
			set center pair!
			set scale-x number!
			set scale-y number!
			set toffset pair!
			(
				cairo_translate cairo-ctx toffset/x toffset/y
				cairo_translate cairo-ctx center/x center/y
				cairo_rotate cairo-ctx angle * degrees
				cairo_scale cairo-ctx scale-x scale-y
				cairo_translate cairo-ctx 0 - center/x 0 - center/y
			)
		| 'MATRIX set matrix-setup block! (go: either 6 <> length? matrix-setup [fail][[]]) go
			(
				cairo_transform cairo-ctx block-to-struct/doubles matrix-setup
			)
		| 'RESET-MATRIX (cairo_identity_matrix cairo-ctx)
		| 'PUSH set draw-block block!
			(
				cairo_save cairo-ctx
				parse draw-block [some draw-rule]
				cairo_restore cairo-ctx
			)
		| 'POP (cairo_restore cairo-ctx)
		
		| 'SHAPE set shape-block block!
			(
				point1: 0x0
				cairo_new_path cairo-ctx 
				parse shape-block [
					some [
						  shape-rule
						| shape-rel-rule
						;
						| block! ; just skip
						;| set var word! (go: either none? get var [[]][fail]) go
						| pos: (if not tail? pos [throw make error! reduce ['draw-cairo 'syntax-shape mold pos]]) thru end
					]
				]
				cairo_close_path cairo-ctx
				
				fill_and_stroke ; FIXME: if level = 0 [fill_and_stroke]
			)
		;
		| 'IMAGE set border opt 'border copy values next-word-rule
				opt [set border 'border copy values2 next-word-rule (append values any [values2 []] )]
			(
				img: fetch values image! none
				if image? img [
					size: img/size
					key-color: fetch values tuple! none
					upper-left-point: fetch values pair! 0x0
					temp: fetch values pair! upper-left-point + size
					lower-right-point: fetch values pair! temp
					lower-left-point: fetch values pair! size

					upper-right-point: upper-left-point + (size * 1x0)
					;lower-right-point: upper-left-point + (size * 1x1)
					lower-left-point: upper-left-point + (size * 0x1)

					ix: lower-right-point/x - upper-left-point/x
					iy: lower-right-point/y - upper-left-point/y

					cairo_save cairo-ctx
					
					old-pen: pen
					if none? border [pen: none]
					old-fill-pen: fill-pen
					fill-pen: img
					
					cairo_rectangle cairo-ctx upper-left-point/x upper-left-point/y ix iy

					ix: either ix = 0 [0][size/x / ix]
					iy: either iy = 0 [0][size/y / iy]
					mat-pat: reduce [ix 0 0 iy 0 - upper-left-point/x 0 - upper-left-point/y]
					fill_and_stroke

					if pen [cairo_stroke cairo-ctx] ; erase path
					cairo_restore cairo-ctx
					fill-pen: old-fill-pen
					pen: old-pen
				]
				
			)
		;
		| 'FLOOD pair! opt tuple! ;unimplemented
		| 'GAMMA decimal! ;unimplemented
		;
		| block! ; just skip
		;| set var word! (go: either none? get var [[]][fail]) go
		| pos: (if not tail? pos [throw make error! reduce ['draw-cairo 'syntax mold pos]]) thru end
	]
	parse head block [some draw-rule]
	
	{
	pos: draw-rule
	while [pos: find/tail pos 'set][insert tail setted pos/1  ]
	pos: shape-rule
	while [pos: find/tail pos 'set][insert tail setted pos/1  ]
	pos: shape-rel-rule
	while [pos: find/tail pos 'set][insert tail setted pos/1  ]
	;probe setted
	}

	cairo_surface_flush surfac
	image/rgb: white image/alpha: 255 ; same as Rebol-AGG but doesn't seem the better choice
	draw image reduce ['image surface-to-image surfac]
	cairo_destroy cairo-ctx
	cairo_surface_destroy surfac

	recycle/on
	recycle
	image
]

{************************************************************
*** example
************************************************************}
do ; just comment this line to avoid executing example
[
	if system/script/title = "libcairo library interface" [;do examples only if script started by us
	width: 490 height: 356

	; draw sample cairo image
		surface: cairo_image_surface_create CAIRO_FORMAT_ARGB32 320 250
		cr: cairo_create surface

		; clear to white background
		cairo_set_source_rgb cr 1 1 1
		cairo_paint cr
		
		cairo_set_source_rgb cr 0 0 0
		cairo_select_font_face cr "Sans" CAIRO_FONT_SLANT_NORMAL CAIRO_FONT_WEIGHT_NORMAL
		cairo_set_font_size cr 40.0
		cairo_move_to cr 10.0 50.0
		cairo_show_text cr "cairo with Rebol."

		x: 25.6 y: 58.0
		x1: 102.4 y1: 230.4
		x2: 153.6 y2: 25.6
		x3: 230.4 y3: 128.0

		cairo_set_source_rgb cr 0 0 0
		cairo_move_to cr x y
		cairo_curve_to cr x1 y1 x2 y2 x3 y3

		cairo_set_line_width cr 10.0
		cairo_stroke cr

		cairo_set_source_rgba cr 1 0.2 0.2 0.6
		cairo_set_line_width cr 6.0
		cairo_move_to cr x y cairo_line_to cr x1 y1
		cairo_move_to cr x2 y2 cairo_line_to cr x3 y3
		cairo_stroke cr 

		;cairo_surface_write_to_png surface "image.png"
		
	;
	fon: make system/standard/face/font [
		name: "times"
		size: 18
		color: violet ; will use pen color instead
		style: [bold italic]
	]
	bay: attempt [load %bay.jpg]
	
	test-draw: {
		; try to find the differences ;)  between my cairo version and Rebol2-AGG
		; to make a multi-line comment use brackets [ ]
		line-width 1 pen blue
		;[
		box
		box 30
		box 20x10
		box 40 25x15
		box 30x20 50
		fill-pen white
		box 3000
		box 180x150 250x180 -10
		fill-pen bay ; 150.10.205
		box 40x50 20 100x180
		translate 70
		box 40x50 100x180 200
		translate 110
		rotate 20
		scale 1.5 .5
		box 40x30 100x180 10
		RESET-MATRIX
		;]
		translate 400x10
		pen red fill-pen none
		translate   0 line-width 10.7 line 10x0 10x40
		translate 10 line-width 0 line 10x0 10x40 box 10x50 15x60 ; different
		translate 10 line-width none line 10x0 10x40 ; different
		translate 10 line-width   line 10x0 10x40
		RESET-MATRIX

		translate 300x10
		line-width 1  pen black  fill-pen none
		ellipse 20x20 30x20 
		ellipse 30x30 ; different 
		line-width 2  pen magenta
		circle ; different
		circle 5x20 ; different
		circle 30 35x35
		circle 30x30 40 20
		RESET-MATRIX

		line-width 5
		fill-pen none 
		curve 45x128 102x140 153x-25 230x68 
		arc 200x90 60x40 20 240 closed

		translate 0x250
		pen (red + 0.0.0.100) 
		line-width 10 
		line 10x30 30x10 30x50 5x50 
		translate 35
		line-join bevel 
		line-cap round 
		line 10x30 30x10 30x50 5x50 
		RESET-MATRIX

		translate 35x30
		line-cap butt 
		line-pattern 30.0 10.0 
		pen brown (green + 0.0.0.200) translate 0x150 line 10x40 40x10 50x170 
		pen none red   translate 10x-25 line 10x40 40x10 50x170 
		pen red   translate 10x-25 line 10x40 40x10 50x170 
		pen none none  translate 10x-25 line 10x40 40x10 50x170 
		pen   translate 10x-25 line 10x40 40x10 50x170 
		pen green none  translate 10x-25 line 10x40 40x10 50x170 
		RESET-MATRIX

		translate 280x200
		image (bay) 80x90 152x50 (162x144 + 30x0) 30x144 border
		RESET-MATRIX

		translate 130x220 skew 20
		pen 250.55.250 
		line-width 4 
		fill-pen linear 50x30 0 70 0 1 1 0.0.255 255.0.0 0.255.0 
		box 50x30 120x80 10 
		fill-pen radial 30x60 0 70 0 1 1 0.0.255 255.0.0 0.255.0 
		box 30x60 110x120
		RESET-MATRIX 

		translate 50x80
		line-width 3 pen fill-pen black circle 4 (p1: 0x50) circle 4 (p2: 50x100) circle 4 (p3: 150x50) circle 4 (p4: 180x100) circle 4 (p5: 150x150) circle 4 (p6: 100x200) circle 4 (p7: 100x250)
		fill-pen none
		line-width 8 pen (red - 150) curve p1 p2 p3 p4
		line-width 5 pen (red - 10) curve p1 p2 p3
		line-width 10 pen (red - 50) curve p1 p2
		line-width 13 pen (blue - 10) spline closed 10 p2 p3 p4 p5 p6 p7
		line-width 8 pen (yellow - 10) spline 10 p1 p2 p3 p4 p5 p6 p7
		line-width 5 pen (green - 150) spline 10 p1 p2 p3 p4
		line-width 3 pen (green - 10) spline 10 p6 p5 p4
		line-width 5 pen (green - 50) spline 10 p7 p6
		line-width 3 pen (white - 20) polygon p1 p2 p3 p4 p5 p6 p7
		line-width 2 pen (red - 10) line p1 p2 p3 p4 p5 p6 p7
		line-width 3 pen fill-pen black circle 4 (p1: 0x50) circle 4 (p2: 50x100) circle 4 (p3: 150x50) circle 4 (p4: 180x100) circle 4 (p5: 150x150) circle 4 (p6: 100x200) circle 4 (p7: 100x250)
		RESET-MATRIX

		translate 250x80
		line-width 3 pen fill-pen black circle 4 (p1: 0x50) circle 4 (p2: 50x100) circle 4 (p3: 150x50) circle 4 (p4: 180x100) circle 4 (p5: 150x150) circle 4 (p6: 100x200) circle 4 (p7: 100x250)
		line-width 1 fill-pen none
		pen black shape [move p1 curv p2 p3 p4 p5 p6 p7] 
		pen red shape [move p1 curve p2 p3 p4 p5 p6 p7 ] ; Rebol-AGG is wrong ? 
		pen black shape [move p1 qcurv p2 p3 p4 p5 p6 p7 move 0x0] 
		pen blue shape [move p1 qcurve p2 p3 p4 p5 p6 p7 move 0x0 ] 
		RESET-MATRIX

		translate 300x80
		line-width 2 pen red
		shape [ move 0x0 'arc 100 60x50]
		shape [ move 10x-10 'arc 60 30 60x50 #[false] #[true]]
		shape [ move -10x10 'arc 60x50 80 30 true false]
		shape [ move -30x10 'arc 80 30 60x50 true true]
		shape [ move -30x-20 'arc 80 30 60x50 (pi / 180 * 60) true true]
		RESET-MATRIX

		pen black
		font (fon) 
		rotate 5 
		text "Drawing some text," 30x20 
		text " other words" aliased
	}
	
	update-draw: has [error][

		image-cairo/image/alpha: 255 ; clear alpha
		if any [ 
			;error? set/any 'error try [image-cairo/image: draw-cairo image-cairo/image compose [(compose/deep load get-face area-draw)]]
			error? set/any 'error try [draw-cairo image-cairo/image load get-face area-draw] ; compose is done inside draw-cairo
			error? set/any 'error try [show image-cairo]
			][
				;probe
				error: disarm error
				prin "** draw-cairo Error Near: " 
				either error/code < 1000 [
					print [error/arg1 error/near]
				][
					print copy/part error: form error/arg1 any [attempt [find find/tail error newline newline] tail error]
				]
		]
		show image-cairo
		
		if any [ 
			error? set/any 'error try [box-agg/effect/draw: compose [(compose/deep load get-face area-draw)]]
			error? set/any 'error try [show box-agg]
			][
				;probe
				error: disarm error
				prin "** draw Error " print form error/arg1 prin "Near: " print form error/near
				box-agg/effect/draw: clear []
				show box-agg
		]
		
	]
	print "Errors are printed here^/" ; open console
	view layout [
		image as-pair 320 250 with [append init [image: surface-to-image surface]]
		across
		area-draw: area 300x430 trim/auto test-draw;
			feel [
				engage-super: :engage
				engage: func [face action event /local qualified-event][	
					engage-super face action event
					if all [event/type = 'key not word? event/key] [update-draw]
					if face/para/scroll/y <> face/scroll/y [
						qualified-event: reform [event/key event/control]
						scroller-area/data: scroller-area/data + switch/default qualified-event [
							"down false" "right false" "right true" [scroller-area/step]
							"up false" "left false" "left true" [- scroller-area/step]
							"down true" [scroller-area/page]
							"up true" [- scroller-area/page]
						] [0]
					]
					face/scroll: face/para/scroll
					show scroller-area/refresh
				]
			]
			with [
				scroll: para/scroll
			]
		pad -8x0
		scroller-area: scroller area-draw/size/y * 0x1 + 16x0 0.0
			[
				scroll-para area-draw face
			] 
			with [
				vis-lines: 1 + to-integer area-draw/size/y / 16
				refresh: func [][
					; count lines
					tot-lines: 0
					parse area-draw/text [any [thru newline (tot-lines: tot-lines + 1)]]

					step: 1 / max 1 (tot-lines - vis-lines)
					redrag min (max 1 vis-lines) / (max 1 tot-lines) 1
					self
				]
				append init [
					refresh 
				]
			] 
		pad 8x0
		below
		btn "Save to %temp-draw.txt" area-draw/size/x [save %temp-draw.txt area-draw/text]
		return
		image-cairo: image as-pair width height with [append init [
			image: make image! as-pair width height
		]]
		box-agg: box as-pair width height effect [draw test-draw]
		do [update-draw]
		do [
			focus area-draw
			; move cursor to beginning
			ctx-text/edit-text area-draw compose [shift (false) control (true) key home] []
		]
	]
		
	cairo_destroy cr
	cairo_surface_destroy surface

	free cairo-lib
	free z-lib

	; print "leaked" vars
	;probe exclude unique head setted first :draw-cairo

	;halt
	] ; if title
	
]
