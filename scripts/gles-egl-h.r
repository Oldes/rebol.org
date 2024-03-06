REBOL [
	title: "GLES and EGL library interface"
	Purpose: "Use modern OpenGL with shaders"
	Notes: {
		I think this is quite an impressive achievement (for Rebol 2 ;) )
	
		PLEASE READ THESE NOTES or you will miss some important things and Rebol will crush more often.
		
		IMPORTANT: Change GLES_this_version, EGL_this_version and libs paths as needed by your libraries.
		
		I tried Regal, GLFW+(recompiled) GLEW, Firefox32bit EGL+mozglue+GLES with no success and then...
		...Chrome32bit version 50 EGL+GLES and bang! . Also 32bit version 79 is working.
		After I made hello_triangle work also Firefox32bit is working.
		
		A few differences between Chrome32bit and Firefox32bit.
		Chrome32bit:
			Shaders version is only #version 100
			Setting EGL_CONTEXT_CLIENT_VERSION to 1 will disable shaders (and enable old begin/end API ? I have not tried)
			The possible framebuffer configs allowed are very reduced.
			No multi-sampling support.
			Its EGL reports version 1.4 but there are also 1.5 functions inside it
			Initialization is fast
		Firefox32bit:
			Shaders version is #version 100 or #version 300 es
			Setting EGL_CONTEXT_CLIENT_VERSION to 2 or 1 is allowed.
			A lot of possible framebuffer configs allowed.
			Yes multi-sampling support.
			Its EGL reports version 1.4 but there are also 1.5 functions inside it
			Initialization is _slow_ (about 1 second !)
		
		Beware to properly use float32 and/or convert to/from float32/decimal!

		Using pointers to send and receive data is not simple. Sometimes it is simpler to use integer!
		other times struct! other times binary! other times string! !
		The provided function '&' (yes only ampersand) is made to be similar to "C" version:
		use it on a binary!, string! or struct! to pass a pointer made with the provided int-ptr function
		and use path notation .../value to acces its member. If there is need to store more then one
		element (e.g. an array of pointers to strings) use block-to-struct instead of int-ptr and
		use .../_1 or .../_2 etc. to get a member.
		All this means that some functions expect a parameter to be integer! others expect it to be
		struct! etc. If Rebol crashes look for the parameter type.
		Of course you can change all this if you prefer !

		As noted above only 32bit version of Chrome and Firefox libraries will work (I have not tried other browsers).
		This means that if you have, say, Chrome 64bit installed and want to try its 32bit libraries you probably will
		have to uninstall it, intall 32bit version, copy libEGL and libGLES somewhere, uninstall it and re-install
		64bit version. This is what I have done. Unless you find pre-compiled libraries somewhere, or you are able to
		recompile them from sources.
		One last thing: the libGLES library of Firefox32bit also opens "mozglue.dll" that must be put in the same
		directory of this script.

		DISCLAIMER: USE AT YOUR OWN RISK!
		It works on my system:
			OpenGL renderer string: ATI Mobility Radeon HD 4570
			OpenGL version string: 3.3.11653 Compatibility Profile Context
			AMD Athlon II Dual-Core M300 2.00 GHz
			Windows 7 64 bit
	}
	file: %gles-egl-h.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	Copyright: "(C) 2020 Marco Antoniazzi."
	date: 25-04-2020
	version: 0.6.2
	comment: {ONLY A FEW FUNCTIONS TESTED !!!! Use example code to test others.
		See Rebol specific functions at the end.
	}
	History: [
		0.0.1 [21-12-2019 "Started"]
		0.0.2 [02-01-2020 "IT... COULD... WORK!!"]
		0.4.0 [03-01-2020 "UPD: various clean-up and helper functions"]
		0.5.0 [06-01-2020 "UPD: nice fragment shader from http://glslsandbox.com/e#59828.0"]
		0.5.1 [19-01-2020 "UPD: another nice fragment shader from http://glslsandbox.com/e#58416.0"]
		0.5.2 [26-01-2020 "UPD: improved gles-make-buffer with glBindBuffer type 0"]
		0.5.3 [26-01-2020 "UPD: simplified main rendering loop deleting unecessary glBindBuffer and modifing last parameter of glDrawElements"]
		0.5.4 [03-04-2020 "FIX: gles-free-program , FIX: fall down to a possible config in egl-Start"]
		0.5.5 [05-04-2020 "FIX: gles-set-vertex-attribute , UPD: moved example shaders and func inside examples's 'do"]
		0.5.6 [05-04-2020 "FIX: gles-free-program, UPD: gles-make-program, ADD: gles-set-uniform"]
		0.6.1 [10-04-2020 "ADD: gles-make-texture, FIX: gles-make-shader error string"]
		0.6.2 [25-04-2020 "FIX: gles-set-uniform, FIX: egl-start verbose printing GL strings"]
	]
	Category: [library graphics]
	library: [
		level: 'advanced
		platform: 'win
		type: [module tool]
		domain: [graphics external-library]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: 'BSD
		see-also: none
	]

]


	; Please adjust these values and the path


GLES_this_version: 3.2.0 ; change as needed       ; FIXME: or adjust by getting it from GL context
EGL_this_version: 1.5.0 ; change as needed        ; FIXME: or adjust by getting it from EGL lib

;lib-path: to-rebol-file "E:\Programmi\Web\FireFox32bit"
lib-path: to-rebol-file "E:\Programmi\Prog\Rebol\local\libs\GL\Chrome32bit_v79"



; misc funcs
	form-error: func [
		"Forms a disarmed error"
		err [object!]
		/local arg1 arg2 arg3 message
		][;derived from 11-Feb-2007 Guest2
		arg1: any [attempt [get in err 'arg1] 'unset]
		arg2: any [attempt [get in err 'arg2] 'unset]
		arg3: any [attempt [get in err 'arg3] 'unset]
		message: get err/id
		if block? message [bind message 'arg1]
		message: rejoin ["** " get in get in system/error err/type 'type ": " form reduce message newline
						  "** Near:" either block? err/near [mold/only err/near][err/near] newline]
	]
	form-on-error: func [
		"Evaluates a block, which if it results in an error, forms that error."
		blk [block!]
		][
		if error? set/any 'blk try blk [form-error disarm blk] 
	]
	fill: func [
		"Duplicates an append a specified number of times. (modifies)"
		series [series!]
		value
		count [integer!]
		][
		head insert/dup tail series value count
	]
	;;;
	;;;REBOL-NOTE: use this function to access pointers
	;;;
	int-ptr: does [make struct! [value [integer!]] none]
	flt-ptr: does [make struct! [value [float]] none]
	dbl-ptr: does [make struct! [value [double]] none]
	coords-ptr: does [make struct! [x [float] y [float] z [float] w [float]] none]
	
	int32: make struct! [num [integer!]] none
	to-int32: func [value][int32/num: value copy third int32] ; endianess aware
	from-int32: func [value [binary!]][change third int32 copy/part value 4 int32/num]

	*int: make struct! [[save] ptr [struct! [value [integer!]]]] none
	addr: func [ptr [binary! string! struct!]] [if struct? ptr [ptr: third ptr] third make struct! [s [string!]] reduce [ptr]]
	get&: func [ptr] [change third *int addr ptr *int/ptr/value]
	;&: func [ptr] [ptr: addr ptr to-integer either 'little = get-modes system:// 'endian [head reverse copy ptr][ptr]]

	;;;
	;;;REBOL-NOTE: use this function to pass a binary!, string! or struct! as an integer! to a routine!
	;;;
	&: func [ptr [binary! string! struct!]] [from-int32 addr ptr]

	;;;
	;;;REBOL-NOTE: use this function to map data to a struct! to be able to access its members
	;;;
	addr-to-struct: func [
		"returns the given struct! initialized with content of memory at given address"
		addr [integer! ] struct [struct!] /local int-ptr tstruct
		][
		int-ptr: make struct! [value [integer!]] reduce [addr]
		tstruct: make struct! compose/deep/only [ptr [struct! (first struct)]] none
		change third tstruct third int-ptr
		change third struct third tstruct/ptr
		struct
	]

	;;;
	;;;REBOL-NOTE: use this function to convert a block to an initialized struct! (and use eg. as: probe third block-to-struct/floats [1.5 3])
	;;;
	block-to-struct: func [
		"Construct a struct! and initialize it based on given block"
		block [block!] /no-ints /floats /local spec type n
		] [
		block: reduce block
		replace/all block 'none 0
		spec: copy []
		n: 1
		forall block [
			append spec compose/deep/only [(to-word join '_ n) [(
				type: type?/word first block
				if all [no-ints equal? type 'integer!] [block/1: to decimal! block/1 type: 'decimal!]
				either all [equal? type 'decimal! floats]['float][type]
			)]]
			n: n + 1
		]
		make struct! spec block
	]

	assign-struct: func [
		"Assign src struct data to dst"
		dst [struct!] src [struct!]
		] [
		change third dst third src
	]
	get-mem?: func [; author: Ladislav Mecir
		"get the data from a memory address. Default is to return a byte"
		address [integer!]
		/nts "a null-terminated string"
		/part length [integer!] "a binary with a specified length"
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
;
; load libs

	lib: switch/default System/version/4 [
		2 [%libGLES.dylib]	;OSX
		3 [%libGLESv2.dll]	;Windows
	] [%libGLES.so.2]
	;probe exists? lib-path/:lib

	if not attempt [gles32-lib: load/library lib-path/:lib] [alert rejoin ["Unable to find or open " lib " . Quit"] quit]


	lib: switch/default System/version/4 [
		2 [%libEGL.dylib]	;OSX
		3 [%libEGL.dll]	;Windows
	] [%libEGL.so]
	;probe exists? lib-path/:lib

	if not attempt [egl-lib: load/library lib-path/:lib] [alert rejoin ["Unable to find or open " lib " . Quit"] quit]

;
{** Copyright (c) 2013-2018 The Khronos Group Inc.
	**
	** Permission is hereby granted, free of charge, to any person obtaining a
	** copy of this software and/or associated documentation files (the
	** "Materials"), to deal in the Materials without restriction, including
	** without limitation the rights to use, copy, modify, merge, publish,
	** distribute, sublicense, and/or sell copies of the Materials, and to
	** permit persons to whom the Materials are furnished to do so, subject to
	** the following conditions:
	**
	** The above copyright notice and this permission notice shall be included
	** in all copies or substantial portions of the Materials.
	**
	** THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	** MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
	}
{************************************************************
**  gles.h
************************************************************}
	; types
		GLbyte: char! ; khronos_int8_t
		;GLclampf: decimal! ; NO !! must use float; khronos_float_t
		GLfixed: integer! ; khronos_int32_t
		;GLshort: short; khronos_int16_t
		;GLushort: ushort; khronos_uint16_t
		GLvoid: integer! ; void
		GLsync: binary! ;struct __GLsync *GLsync;
		;GLint64: int64; khronos_int64_t
		;GLuint64: double ;decimal! ; uint64; khronos_uint64_t
		GLenum: integer! ; unsigned int
		GLuint: integer! ; unsigned int
		GLchar: char! ; char
		;GLfloat: decimal! ; NO !! must use float; khronos_float_t
		GLsizeiptr: integer! ; khronos_ssize_t
		GLintptr: integer! ; khronos_intptr_t
		GLbitfield: integer! ; unsigned int
		GLint: integer! ; int
		GLboolean: char!; unsigned char
		GLsizei: integer! ; int
		GLubyte: char! ;
		;GLhalf: integer! ; khronos_uint16_t
	;
	if GLES_this_version >= 2.0.0 glesblock200: [
	; GLES 2.0 defines
		GL_DEPTH_BUFFER_BIT:               256
		GL_STENCIL_BUFFER_BIT:             1024
		GL_COLOR_BUFFER_BIT:               16384
		GL_FALSE:                          0
		GL_TRUE:                           1
		GL_POINTS:                         0
		GL_LINES:                          1
		GL_LINE_LOOP:                      2
		GL_LINE_STRIP:                     3
		GL_TRIANGLES:                      4
		GL_TRIANGLE_STRIP:                 5
		GL_TRIANGLE_FAN:                   6
		GL_ZERO:                           0
		GL_ONE:                            1
		GL_SRC_COLOR:                      768
		GL_ONE_MINUS_SRC_COLOR:            769
		GL_SRC_ALPHA:                      770
		GL_ONE_MINUS_SRC_ALPHA:            771
		GL_DST_ALPHA:                      772
		GL_ONE_MINUS_DST_ALPHA:            773
		GL_DST_COLOR:                      774
		GL_ONE_MINUS_DST_COLOR:            775
		GL_SRC_ALPHA_SATURATE:             776
		GL_FUNC_ADD:                       32774
		GL_BLEND_EQUATION:                 32777
		GL_BLEND_EQUATION_RGB:             32777
		GL_BLEND_EQUATION_ALPHA:           34877
		GL_FUNC_SUBTRACT:                  32778
		GL_FUNC_REVERSE_SUBTRACT:          32779
		GL_BLEND_DST_RGB:                  32968
		GL_BLEND_SRC_RGB:                  32969
		GL_BLEND_DST_ALPHA:                32970
		GL_BLEND_SRC_ALPHA:                32971
		GL_CONSTANT_COLOR:                 32769
		GL_ONE_MINUS_CONSTANT_COLOR:       32770
		GL_CONSTANT_ALPHA:                 32771
		GL_ONE_MINUS_CONSTANT_ALPHA:       32772
		GL_BLEND_COLOR:                    32773
		GL_ARRAY_BUFFER:                   34962
		GL_ELEMENT_ARRAY_BUFFER:           34963
		GL_ARRAY_BUFFER_BINDING:           34964
		GL_ELEMENT_ARRAY_BUFFER_BINDING:   34965
		GL_STREAM_DRAW:                    35040
		GL_STATIC_DRAW:                    35044
		GL_DYNAMIC_DRAW:                   35048
		GL_BUFFER_SIZE:                    34660
		GL_BUFFER_USAGE:                   34661
		GL_CURRENT_VERTEX_ATTRIB:          34342
		GL_FRONT:                          1028
		GL_BACK:                           1029
		GL_FRONT_AND_BACK:                 1032
		GL_TEXTURE_2D:                     3553
		GL_CULL_FACE:                      2884
		GL_BLEND:                          3042
		GL_DITHER:                         3024
		GL_STENCIL_TEST:                   2960
		GL_DEPTH_TEST:                     2929
		GL_SCISSOR_TEST:                   3089
		GL_POLYGON_OFFSET_FILL:            32823
		GL_SAMPLE_ALPHA_TO_COVERAGE:       32926
		GL_SAMPLE_COVERAGE:                32928

		GL_NO_ERROR:                       0
		GL_INVALID_ENUM:                   1280
		GL_INVALID_VALUE:                  1281
		GL_INVALID_OPERATION:              1282
		GL_OUT_OF_MEMORY:                  1285

		GL_CW:                             2304
		GL_CCW:                            2305
		GL_LINE_WIDTH:                     2849
		GL_ALIASED_POINT_SIZE_RANGE:       33901
		GL_ALIASED_LINE_WIDTH_RANGE:       33902
		GL_CULL_FACE_MODE:                 2885
		GL_FRONT_FACE:                     2886
		GL_DEPTH_RANGE:                    2928
		GL_DEPTH_WRITEMASK:                2930
		GL_DEPTH_CLEAR_VALUE:              2931
		GL_DEPTH_FUNC:                     2932
		GL_STENCIL_CLEAR_VALUE:            2961
		GL_STENCIL_FUNC:                   2962
		GL_STENCIL_FAIL:                   2964
		GL_STENCIL_PASS_DEPTH_FAIL:        2965
		GL_STENCIL_PASS_DEPTH_PASS:        2966
		GL_STENCIL_REF:                    2967
		GL_STENCIL_VALUE_MASK:             2963
		GL_STENCIL_WRITEMASK:              2968
		GL_STENCIL_BACK_FUNC:              34816
		GL_STENCIL_BACK_FAIL:              34817
		GL_STENCIL_BACK_PASS_DEPTH_FAIL:   34818
		GL_STENCIL_BACK_PASS_DEPTH_PASS:   34819
		GL_STENCIL_BACK_REF:               36003
		GL_STENCIL_BACK_VALUE_MASK:        36004
		GL_STENCIL_BACK_WRITEMASK:         36005
		GL_VIEWPORT:                       2978
		GL_SCISSOR_BOX:                    3088
		GL_COLOR_CLEAR_VALUE:              3106
		GL_COLOR_WRITEMASK:                3107
		GL_UNPACK_ALIGNMENT:               3317
		GL_PACK_ALIGNMENT:                 3333
		GL_MAX_TEXTURE_SIZE:               3379
		GL_MAX_VIEWPORT_DIMS:              3386
		GL_SUBPIXEL_BITS:                  3408
		GL_RED_BITS:                       3410
		GL_GREEN_BITS:                     3411
		GL_BLUE_BITS:                      3412
		GL_ALPHA_BITS:                     3413
		GL_DEPTH_BITS:                     3414
		GL_STENCIL_BITS:                   3415
		GL_POLYGON_OFFSET_UNITS:           10752
		GL_POLYGON_OFFSET_FACTOR:          32824
		GL_TEXTURE_BINDING_2D:             32873
		GL_SAMPLE_BUFFERS:                 32936
		GL_SAMPLES:                        32937
		GL_SAMPLE_COVERAGE_VALUE:          32938
		GL_SAMPLE_COVERAGE_INVERT:         32939
		GL_NUM_COMPRESSED_TEXTURE_FORMATS: 34466
		GL_COMPRESSED_TEXTURE_FORMATS:     34467
		GL_DONT_CARE:                      4352
		GL_FASTEST:                        4353
		GL_NICEST:                         4354
		GL_GENERATE_MIPMAP_HINT:           33170
		GL_BYTE:                           5120
		GL_UNSIGNED_BYTE:                  5121
		GL_SHORT:                          5122
		GL_UNSIGNED_SHORT:                 5123
		GL_INT:                            5124
		GL_UNSIGNED_INT:                   5125
		GL_FLOAT:                          5126
		GL_FIXED:                          5132
		GL_DEPTH_COMPONENT:                6402
		GL_ALPHA:                          6406
		GL_RGB:                            6407
		GL_RGBA:                           6408
		GL_LUMINANCE:                      6409
		GL_LUMINANCE_ALPHA:                6410
		GL_UNSIGNED_SHORT_4_4_4_4:         32819
		GL_UNSIGNED_SHORT_5_5_5_1:         32820
		GL_UNSIGNED_SHORT_5_6_5:           33635
		GL_FRAGMENT_SHADER:                35632
		GL_VERTEX_SHADER:                  35633
		GL_MAX_VERTEX_ATTRIBS:             34921
		GL_MAX_VERTEX_UNIFORM_VECTORS:     36347
		GL_MAX_VARYING_VECTORS:            36348
		GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS: 35661
		GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS: 35660
		GL_MAX_TEXTURE_IMAGE_UNITS:        34930
		GL_MAX_FRAGMENT_UNIFORM_VECTORS:   36349
		GL_SHADER_TYPE:                    35663
		GL_DELETE_STATUS:                  35712
		GL_LINK_STATUS:                    35714
		GL_VALIDATE_STATUS:                35715
		GL_ATTACHED_SHADERS:               35717
		GL_ACTIVE_UNIFORMS:                35718
		GL_ACTIVE_UNIFORM_MAX_LENGTH:      35719
		GL_ACTIVE_ATTRIBUTES:              35721
		GL_ACTIVE_ATTRIBUTE_MAX_LENGTH:    35722
		GL_SHADING_LANGUAGE_VERSION:       35724
		GL_CURRENT_PROGRAM:                35725
		GL_NEVER:                          512
		GL_LESS:                           513
		GL_EQUAL:                          514
		GL_LEQUAL:                         515
		GL_GREATER:                        516
		GL_NOTEQUAL:                       517
		GL_GEQUAL:                         518
		GL_ALWAYS:                         519
		GL_KEEP:                           7680
		GL_REPLACE:                        7681
		GL_INCR:                           7682
		GL_DECR:                           7683
		GL_INVERT:                         5386
		GL_INCR_WRAP:                      34055
		GL_DECR_WRAP:                      34056
		GL_VENDOR:                         7936
		GL_RENDERER:                       7937
		GL_VERSION:                        7938
		GL_EXTENSIONS:                     7939
		GL_NEAREST:                        9728
		GL_LINEAR:                         9729
		GL_NEAREST_MIPMAP_NEAREST:         9984
		GL_LINEAR_MIPMAP_NEAREST:          9985
		GL_NEAREST_MIPMAP_LINEAR:          9986
		GL_LINEAR_MIPMAP_LINEAR:           9987
		GL_TEXTURE_MAG_FILTER:             10240
		GL_TEXTURE_MIN_FILTER:             10241
		GL_TEXTURE_WRAP_S:                 10242
		GL_TEXTURE_WRAP_T:                 10243
		GL_TEXTURE:                        5890
		GL_TEXTURE_CUBE_MAP:               34067
		GL_TEXTURE_BINDING_CUBE_MAP:       34068
		GL_TEXTURE_CUBE_MAP_POSITIVE_X:    34069
		GL_TEXTURE_CUBE_MAP_NEGATIVE_X:    34070
		GL_TEXTURE_CUBE_MAP_POSITIVE_Y:    34071
		GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:    34072
		GL_TEXTURE_CUBE_MAP_POSITIVE_Z:    34073
		GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:    34074
		GL_MAX_CUBE_MAP_TEXTURE_SIZE:      34076
		GL_TEXTURE0:                       33984
		GL_TEXTURE1:                       33985
		GL_TEXTURE2:                       33986
		GL_TEXTURE3:                       33987
		GL_TEXTURE4:                       33988
		GL_TEXTURE5:                       33989
		GL_TEXTURE6:                       33990
		GL_TEXTURE7:                       33991
		GL_TEXTURE8:                       33992
		GL_TEXTURE9:                       33993
		GL_TEXTURE10:                      33994
		GL_TEXTURE11:                      33995
		GL_TEXTURE12:                      33996
		GL_TEXTURE13:                      33997
		GL_TEXTURE14:                      33998
		GL_TEXTURE15:                      33999
		GL_TEXTURE16:                      34000
		GL_TEXTURE17:                      34001
		GL_TEXTURE18:                      34002
		GL_TEXTURE19:                      34003
		GL_TEXTURE20:                      34004
		GL_TEXTURE21:                      34005
		GL_TEXTURE22:                      34006
		GL_TEXTURE23:                      34007
		GL_TEXTURE24:                      34008
		GL_TEXTURE25:                      34009
		GL_TEXTURE26:                      34010
		GL_TEXTURE27:                      34011
		GL_TEXTURE28:                      34012
		GL_TEXTURE29:                      34013
		GL_TEXTURE30:                      34014
		GL_TEXTURE31:                      34015
		GL_ACTIVE_TEXTURE:                 34016
		GL_REPEAT:                         10497
		GL_CLAMP_TO_EDGE:                  33071
		GL_MIRRORED_REPEAT:                33648
		GL_FLOAT_VEC2:                     35664
		GL_FLOAT_VEC3:                     35665
		GL_FLOAT_VEC4:                     35666
		GL_INT_VEC2:                       35667
		GL_INT_VEC3:                       35668
		GL_INT_VEC4:                       35669
		GL_BOOL:                           35670
		GL_BOOL_VEC2:                      35671
		GL_BOOL_VEC3:                      35672
		GL_BOOL_VEC4:                      35673
		GL_FLOAT_MAT2:                     35674
		GL_FLOAT_MAT3:                     35675
		GL_FLOAT_MAT4:                     35676
		GL_SAMPLER_2D:                     35678
		GL_SAMPLER_CUBE:                   35680
		GL_VERTEX_ATTRIB_ARRAY_ENABLED:    34338
		GL_VERTEX_ATTRIB_ARRAY_SIZE:       34339
		GL_VERTEX_ATTRIB_ARRAY_STRIDE:     34340
		GL_VERTEX_ATTRIB_ARRAY_TYPE:       34341
		GL_VERTEX_ATTRIB_ARRAY_NORMALIZED: 34922
		GL_VERTEX_ATTRIB_ARRAY_POINTER:    34373
		GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING: 34975
		GL_IMPLEMENTATION_COLOR_READ_TYPE: 35738
		GL_IMPLEMENTATION_COLOR_READ_FORMAT: 35739
		GL_COMPILE_STATUS:                 35713
		GL_INFO_LOG_LENGTH:                35716
		GL_SHADER_SOURCE_LENGTH:           35720
		GL_SHADER_COMPILER:                36346
		GL_SHADER_BINARY_FORMATS:          36344
		GL_NUM_SHADER_BINARY_FORMATS:      36345
		GL_LOW_FLOAT:                      36336
		GL_MEDIUM_FLOAT:                   36337
		GL_HIGH_FLOAT:                     36338
		GL_LOW_INT:                        36339
		GL_MEDIUM_INT:                     36340
		GL_HIGH_INT:                       36341
		GL_FRAMEBUFFER:                    36160
		GL_RENDERBUFFER:                   36161
		GL_RGBA4:                          32854
		GL_RGB5_A1:                        32855
		GL_RGB565:                         36194
		GL_DEPTH_COMPONENT16:              33189
		GL_STENCIL_INDEX8:                 36168
		GL_RENDERBUFFER_WIDTH:             36162
		GL_RENDERBUFFER_HEIGHT:            36163
		GL_RENDERBUFFER_INTERNAL_FORMAT:   36164
		GL_RENDERBUFFER_RED_SIZE:          36176
		GL_RENDERBUFFER_GREEN_SIZE:        36177
		GL_RENDERBUFFER_BLUE_SIZE:         36178
		GL_RENDERBUFFER_ALPHA_SIZE:        36179
		GL_RENDERBUFFER_DEPTH_SIZE:        36180
		GL_RENDERBUFFER_STENCIL_SIZE:      36181
		GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE: 36048
		GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME: 36049
		GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL: 36050
		GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE: 36051
		GL_COLOR_ATTACHMENT0:              36064
		GL_DEPTH_ATTACHMENT:               36096
		GL_STENCIL_ATTACHMENT:             36128
		GL_NONE:                           0
		GL_FRAMEBUFFER_COMPLETE:           36053
		GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: 36054
		GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: 36055
		GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS: 36057
		GL_FRAMEBUFFER_UNSUPPORTED:        36061
		GL_FRAMEBUFFER_BINDING:            36006
		GL_RENDERBUFFER_BINDING:           36007
		GL_MAX_RENDERBUFFER_SIZE:          34024

		GL_INVALID_FRAMEBUFFER_OPERATION:  1286
	;
	; GLES 2.0 PROTOTYPES
		glActiveTexture: make routine! [ texture [GLenum] ] gles32-lib "glActiveTexture" 
		glAttachShader: make routine! [ program [GLuint] shader [GLuint] ] gles32-lib "glAttachShader" 
		glBindAttribLocation: make routine! [ program [GLuint] index [GLuint] name [string!] ] gles32-lib "glBindAttribLocation" 
		glBindBuffer: make routine! [ target [GLenum] buffer [GLuint] ] gles32-lib "glBindBuffer" 
		glBindFramebuffer: make routine! [ target [GLenum] framebuffer [GLuint] ] gles32-lib "glBindFramebuffer" 
		glBindRenderbuffer: make routine! [ target [GLenum] renderbuffer [GLuint] ] gles32-lib "glBindRenderbuffer" 
		glBindTexture: make routine! [ target [GLenum] texture [GLuint] ] gles32-lib "glBindTexture" 
		glBlendColor: make routine! [ red [float] green [float] blue [float] alpha [float] ] gles32-lib "glBlendColor" 
		glBlendEquation: make routine! [ mode [GLenum] ] gles32-lib "glBlendEquation" 
		glBlendEquationSeparate: make routine! [ modeRGB [GLenum] modeAlpha [GLenum] ] gles32-lib "glBlendEquationSeparate" 
		glBlendFunc: make routine! [ sfactor [GLenum] dfactor [GLenum] ] gles32-lib "glBlendFunc" 
		glBlendFuncSeparate: make routine! [ sfactorRGB [GLenum] dfactorRGB [GLenum] sfactorAlpha [GLenum] dfactorAlpha [GLenum] ] gles32-lib "glBlendFuncSeparate" 
		glBufferData: make routine! [ target [GLenum] size [GLsizeiptr] data [struct! []] usage [GLenum] ] gles32-lib "glBufferData" 
		glBufferSubData: make routine! [ target [GLenum] offset [GLintptr] size [GLsizeiptr] data [integer!] ] gles32-lib "glBufferSubData" 
		glCheckFramebufferStatus: make routine! [ target [GLenum] return: [GLenum] ] gles32-lib "glCheckFramebufferStatus" 
		glClear: make routine! [ mask [GLbitfield] ] gles32-lib "glClear" 
		glClearColor: make routine! [ red [float] green [float] blue [float] alpha [float] ] gles32-lib "glClearColor" 
		glClearDepthf: make routine! [ d [float] ] gles32-lib "glClearDepthf" 
		glClearStencil: make routine! [ s [GLint] ] gles32-lib "glClearStencil" 
		glColorMask: make routine! [ red [GLboolean] green [GLboolean] blue [GLboolean] alpha [GLboolean] ] gles32-lib "glColorMask" 
		glCompileShader: make routine! [ shader [GLuint] ] gles32-lib "glCompileShader" 
		glCompressedTexImage2D: make routine! [ target [GLenum] level [GLint] internalformat [GLenum] width [GLsizei] height [GLsizei] border [GLint] imageSize [GLsizei] data [integer!] ] gles32-lib "glCompressedTexImage2D" 
		glCompressedTexSubImage2D: make routine! [ target [GLenum] level [GLint] xoffset [GLint] yoffset [GLint] width [GLsizei] height [GLsizei] format [GLenum] imageSize [GLsizei] data [integer!] ] gles32-lib "glCompressedTexSubImage2D" 
		glCopyTexImage2D: make routine! [ target [GLenum] level [GLint] internalformat [GLenum] x [GLint] y [GLint] width [GLsizei] height [GLsizei] border [GLint] ] gles32-lib "glCopyTexImage2D" 
		glCopyTexSubImage2D: make routine! [ target [GLenum] level [GLint] xoffset [GLint] yoffset [GLint] x [GLint] y [GLint] width [GLsizei] height [GLsizei] ] gles32-lib "glCopyTexSubImage2D" 
		glCreateProgram: make routine! [ return: [GLuint] ] gles32-lib "glCreateProgram" 
		glCreateShader: make routine! [ type [GLenum] return: [GLuint] ] gles32-lib "glCreateShader" 
		glCullFace: make routine! [ mode [GLenum] ] gles32-lib "glCullFace" 
		glDeleteBuffers: make routine! [ n [GLsizei] buffers [struct! []] ] gles32-lib "glDeleteBuffers" 
		glDeleteFramebuffers: make routine! [ n [GLsizei] framebuffers [integer!] ] gles32-lib "glDeleteFramebuffers" 
		glDeleteProgram: make routine! [ program [GLuint] ] gles32-lib "glDeleteProgram" 
		glDeleteRenderbuffers: make routine! [ n [GLsizei] renderbuffers [integer!] ] gles32-lib "glDeleteRenderbuffers" 
		glDeleteShader: make routine! [ shader [GLuint] ] gles32-lib "glDeleteShader" 
		glDeleteTextures: make routine! [ n [GLsizei] textures [integer!] ] gles32-lib "glDeleteTextures" 
		glDepthFunc: make routine! [ func [GLenum] ] gles32-lib "glDepthFunc" 
		glDepthMask: make routine! [ flag [GLboolean] ] gles32-lib "glDepthMask" 
		glDepthRangef: make routine! [ n [float] f [float] ] gles32-lib "glDepthRangef" 
		glDetachShader: make routine! [ program [GLuint] shader [GLuint] ] gles32-lib "glDetachShader" 
		glDisable: make routine! [ cap [GLenum] ] gles32-lib "glDisable" 
		glDisableVertexAttribArray: make routine! [ index [GLuint] ] gles32-lib "glDisableVertexAttribArray" 
		glDrawArrays: make routine! [ mode [GLenum] first [GLint] count [GLsizei] ] gles32-lib "glDrawArrays" 
		glDrawElements: make routine! [ mode [GLenum] count [GLsizei] type [GLenum] indices [integer!] ] gles32-lib "glDrawElements" 
		glEnable: make routine! [ cap [GLenum] ] gles32-lib "glEnable" 
		glEnableVertexAttribArray: make routine! [ index [GLuint] ] gles32-lib "glEnableVertexAttribArray" 
		glFinish: make routine! [ ] gles32-lib "glFinish" 
		glFlush: make routine! [ ] gles32-lib "glFlush" 
		glFramebufferRenderbuffer: make routine! [ target [GLenum] attachment [GLenum] renderbuffertarget [GLenum] renderbuffer [GLuint] ] gles32-lib "glFramebufferRenderbuffer" 
		glFramebufferTexture2D: make routine! [ target [GLenum] attachment [GLenum] textarget [GLenum] texture [GLuint] level [GLint] ] gles32-lib "glFramebufferTexture2D" 
		glFrontFace: make routine! [ mode [GLenum] ] gles32-lib "glFrontFace" 
		glGenBuffers: make routine! [ n [GLsizei] buffers [integer!] ] gles32-lib "glGenBuffers" 
		glGenerateMipmap: make routine! [ target [GLenum] ] gles32-lib "glGenerateMipmap" 
		glGenFramebuffers: make routine! [ n [GLsizei] framebuffers [integer!] ] gles32-lib "glGenFramebuffers" 
		glGenRenderbuffers: make routine! [ n [GLsizei] renderbuffers [integer!] ] gles32-lib "glGenRenderbuffers" 
		glGenTextures: make routine! [ n [GLsizei] textures [integer!] ] gles32-lib "glGenTextures" 
		glGetActiveAttrib: make routine! [ program [GLuint] index [GLuint] bufSize [GLsizei] length [integer!] size [integer!] type [integer!] name [integer!] ] gles32-lib "glGetActiveAttrib" 
		glGetActiveUniform: make routine! [ program [GLuint] index [GLuint] bufSize [GLsizei] length [integer!] size [integer!] type [integer!] name [integer!] ] gles32-lib "glGetActiveUniform" 
		glGetAttachedShaders: make routine! [ program [GLuint] maxCount [GLsizei] count [integer!] shaders [integer!] ] gles32-lib "glGetAttachedShaders" 
		glGetAttribLocation: make routine! [ program [GLuint] name [string!] return: [GLint] ] gles32-lib "glGetAttribLocation" 
		glGetBooleanv: make routine! [ pname [GLenum] data [integer!] ] gles32-lib "glGetBooleanv" 
		glGetBufferParameteriv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetBufferParameteriv" 
		glGetError: make routine! [ return: [GLenum] ] gles32-lib "glGetError" 
		glGetFloatv: make routine! [ pname [GLenum] data [integer!] ] gles32-lib "glGetFloatv" 
		glGetFramebufferAttachmentParameteriv: make routine! [ target [GLenum] attachment [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetFramebufferAttachmentParameteriv" 
		glGetIntegerv: make routine! [ pname [GLenum] data [integer!] ] gles32-lib "glGetIntegerv" 
		glGetProgramiv: make routine! [ program [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetProgramiv" 
		glGetProgramInfoLog: make routine! [ program [GLuint] bufSize [GLsizei] length [integer!] infoLog [string!] ] gles32-lib "glGetProgramInfoLog" 
		glGetRenderbufferParameteriv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetRenderbufferParameteriv" 
		glGetShaderiv: make routine! [ shader [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetShaderiv" 
		glGetShaderInfoLog: make routine! [ shader [GLuint] bufSize [GLsizei] length [integer!] infoLog [string!] ] gles32-lib "glGetShaderInfoLog" 
		glGetShaderPrecisionFormat: make routine! [ shadertype [GLenum] precisiontype [GLenum] range [integer!] precision [integer!] ] gles32-lib "glGetShaderPrecisionFormat" 
		glGetShaderSource: make routine! [ shader [GLuint] bufSize [GLsizei] length [integer!] source [integer!] ] gles32-lib "glGetShaderSource" 
		glGetString: make routine! [ name [GLenum] return: [string!] ] gles32-lib "glGetString" 
		glGetTexParameterfv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetTexParameterfv" 
		glGetTexParameteriv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetTexParameteriv" 
		glGetUniformfv: make routine! [ program [GLuint] location [GLint] params [integer!] ] gles32-lib "glGetUniformfv" 
		glGetUniformiv: make routine! [ program [GLuint] location [GLint] params [integer!] ] gles32-lib "glGetUniformiv" 
		glGetUniformLocation: make routine! [ program [GLuint] name [string!] return: [GLint] ] gles32-lib "glGetUniformLocation" 
		glGetVertexAttribfv: make routine! [ index [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetVertexAttribfv" 
		glGetVertexAttribiv: make routine! [ index [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetVertexAttribiv" 
		glGetVertexAttribPointerv: make routine! [ index [GLuint] pname [GLenum] pointer [integer!] ] gles32-lib "glGetVertexAttribPointerv" 
		glHint: make routine! [ target [GLenum] mode [GLenum] ] gles32-lib "glHint" 
		glIsBuffer: make routine! [ buffer [GLuint] return: [GLboolean] ] gles32-lib "glIsBuffer" 
		glIsEnabled: make routine! [ cap [GLenum] return: [GLboolean] ] gles32-lib "glIsEnabled" 
		glIsFramebuffer: make routine! [ framebuffer [GLuint] return: [GLboolean] ] gles32-lib "glIsFramebuffer" 
		glIsProgram: make routine! [ program [GLuint] return: [GLboolean] ] gles32-lib "glIsProgram" 
		glIsRenderbuffer: make routine! [ renderbuffer [GLuint] return: [GLboolean] ] gles32-lib "glIsRenderbuffer" 
		glIsShader: make routine! [ shader [GLuint] return: [GLboolean] ] gles32-lib "glIsShader" 
		glIsTexture: make routine! [ texture [GLuint] return: [GLboolean] ] gles32-lib "glIsTexture" 
		glLineWidth: make routine! [ width [float] ] gles32-lib "glLineWidth" 
		glLinkProgram: make routine! [ program [GLuint] ] gles32-lib "glLinkProgram" 
		glPixelStorei: make routine! [ pname [GLenum] param [GLint] ] gles32-lib "glPixelStorei" 
		glPolygonOffset: make routine! [ factor [float] units [float] ] gles32-lib "glPolygonOffset" 
		glReadPixels: make routine! [ x [GLint] y [GLint] width [GLsizei] height [GLsizei] format [GLenum] type [GLenum] pixels [binary!] ] gles32-lib "glReadPixels" 
		glReleaseShaderCompiler: make routine! [ ] gles32-lib "glReleaseShaderCompiler" 
		glRenderbufferStorage: make routine! [ target [GLenum] internalformat [GLenum] width [GLsizei] height [GLsizei] ] gles32-lib "glRenderbufferStorage" 
		glSampleCoverage: make routine! [ value [float] invert [GLboolean] ] gles32-lib "glSampleCoverage" 
		glScissor: make routine! [ x [GLint] y [GLint] width [GLsizei] height [GLsizei] ] gles32-lib "glScissor" 
		glShaderBinary: make routine! [ count [GLsizei] shaders [integer!] binaryformat [GLenum] binary [integer!] length [GLsizei] ] gles32-lib "glShaderBinary" 
		glShaderSource: make routine! [ shader [GLuint] count [GLsizei] string [struct! []] length [integer!] ] gles32-lib "glShaderSource" 
		glStencilFunc: make routine! [ func [GLenum] ref [GLint] mask [GLuint] ] gles32-lib "glStencilFunc" 
		glStencilFuncSeparate: make routine! [ face [GLenum] func [GLenum] ref [GLint] mask [GLuint] ] gles32-lib "glStencilFuncSeparate" 
		glStencilMask: make routine! [ mask [GLuint] ] gles32-lib "glStencilMask" 
		glStencilMaskSeparate: make routine! [ face [GLenum] mask [GLuint] ] gles32-lib "glStencilMaskSeparate" 
		glStencilOp: make routine! [ fail [GLenum] zfail [GLenum] zpass [GLenum] ] gles32-lib "glStencilOp" 
		glStencilOpSeparate: make routine! [ face [GLenum] sfail [GLenum] dpfail [GLenum] dppass [GLenum] ] gles32-lib "glStencilOpSeparate" 
		glTexImage2D: make routine! [ target [GLenum] level [GLint] internalformat [GLint] width [GLsizei] height [GLsizei] border [GLint] format [GLenum] type [GLenum] pixels [integer!] ] gles32-lib "glTexImage2D" 
		glTexParameterf: make routine! [ target [GLenum] pname [GLenum] param [float] ] gles32-lib "glTexParameterf" 
		glTexParameterfv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glTexParameterfv" 
		glTexParameteri: make routine! [ target [GLenum] pname [GLenum] param [GLint] ] gles32-lib "glTexParameteri" 
		glTexParameteriv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glTexParameteriv" 
		glTexSubImage2D: make routine! [ target [GLenum] level [GLint] xoffset [GLint] yoffset [GLint] width [GLsizei] height [GLsizei] format [GLenum] type [GLenum] pixels [integer!] ] gles32-lib "glTexSubImage2D" 
		glUniform1f: make routine! [ location [GLint] v0 [float] ] gles32-lib "glUniform1f" 
		glUniform1fv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform1fv" 
		glUniform1i: make routine! [ location [GLint] v0 [GLint] ] gles32-lib "glUniform1i" 
		glUniform1iv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform1iv" 
		glUniform2f: make routine! [ location [GLint] v0 [float] v1 [float] ] gles32-lib "glUniform2f" 
		glUniform2fv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform2fv" 
		glUniform2i: make routine! [ location [GLint] v0 [GLint] v1 [GLint] ] gles32-lib "glUniform2i" 
		glUniform2iv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform2iv" 
		glUniform3f: make routine! [ location [GLint] v0 [float] v1 [float] v2 [float] ] gles32-lib "glUniform3f" 
		glUniform3fv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform3fv" 
		glUniform3i: make routine! [ location [GLint] v0 [GLint] v1 [GLint] v2 [GLint] ] gles32-lib "glUniform3i" 
		glUniform3iv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform3iv" 
		glUniform4f: make routine! [ location [GLint] v0 [float] v1 [float] v2 [float] v3 [float] ] gles32-lib "glUniform4f" 
		glUniform4fv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform4fv" 
		glUniform4i: make routine! [ location [GLint] v0 [GLint] v1 [GLint] v2 [GLint] v3 [GLint] ] gles32-lib "glUniform4i" 
		glUniform4iv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform4iv" 
		glUniformMatrix2fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix2fv" 
		glUniformMatrix3fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix3fv" 
		glUniformMatrix4fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix4fv" 
		glUseProgram: make routine! [ program [GLuint] ] gles32-lib "glUseProgram" 
		glValidateProgram: make routine! [ program [GLuint] ] gles32-lib "glValidateProgram" 
		glVertexAttrib1f: make routine! [ index [GLuint] x [float] ] gles32-lib "glVertexAttrib1f" 
		glVertexAttrib1fv: make routine! [ index [GLuint] v [integer!] ] gles32-lib "glVertexAttrib1fv" 
		glVertexAttrib2f: make routine! [ index [GLuint] x [float] y [float] ] gles32-lib "glVertexAttrib2f" 
		glVertexAttrib2fv: make routine! [ index [GLuint] v [integer!] ] gles32-lib "glVertexAttrib2fv" 
		glVertexAttrib3f: make routine! [ index [GLuint] x [float] y [float] z [float] ] gles32-lib "glVertexAttrib3f" 
		glVertexAttrib3fv: make routine! [ index [GLuint] v [integer!] ] gles32-lib "glVertexAttrib3fv" 
		glVertexAttrib4f: make routine! [ index [GLuint] x [float] y [float] z [float] w [float] ] gles32-lib "glVertexAttrib4f" 
		glVertexAttrib4fv: make routine! [ index [GLuint] v [integer!] ] gles32-lib "glVertexAttrib4fv" 
		glVertexAttribPointer: make routine! [ index [GLuint] size [GLint] type [GLenum] normalized [GLboolean] stride [GLsizei] pointer [integer!] ] gles32-lib "glVertexAttribPointer" 
		glViewport: make routine! [ x [GLint] y [GLint] width [GLsizei] height [GLsizei] ] gles32-lib "glViewport" 
	;
	] ; if GLES_this_version
	if GLES_this_version >= 3.0.0 [
	; GLES 3.0 defines
		GL_READ_BUFFER:                    3074
		GL_UNPACK_ROW_LENGTH:              3314
		GL_UNPACK_SKIP_ROWS:               3315
		GL_UNPACK_SKIP_PIXELS:             3316
		GL_PACK_ROW_LENGTH:                3330
		GL_PACK_SKIP_ROWS:                 3331
		GL_PACK_SKIP_PIXELS:               3332
		GL_COLOR:                          6144
		GL_DEPTH:                          6145
		GL_STENCIL:                        6146
		GL_RED:                            6403
		GL_RGB8:                           32849
		GL_RGBA8:                          32856
		GL_RGB10_A2:                       32857
		GL_TEXTURE_BINDING_3D:             32874
		GL_UNPACK_SKIP_IMAGES:             32877
		GL_UNPACK_IMAGE_HEIGHT:            32878
		GL_TEXTURE_3D:                     32879
		GL_TEXTURE_WRAP_R:                 32882
		GL_MAX_3D_TEXTURE_SIZE:            32883
		GL_UNSIGNED_INT_2_10_10_10_REV:    33640
		GL_MAX_ELEMENTS_VERTICES:          33000
		GL_MAX_ELEMENTS_INDICES:           33001
		GL_TEXTURE_MIN_LOD:                33082
		GL_TEXTURE_MAX_LOD:                33083
		GL_TEXTURE_BASE_LEVEL:             33084
		GL_TEXTURE_MAX_LEVEL:              33085
		GL_MIN:                            32775
		GL_MAX:                            32776
		GL_DEPTH_COMPONENT24:              33190
		GL_MAX_TEXTURE_LOD_BIAS:           34045
		GL_TEXTURE_COMPARE_MODE:           34892
		GL_TEXTURE_COMPARE_FUNC:           34893
		GL_CURRENT_QUERY:                  34917
		GL_QUERY_RESULT:                   34918
		GL_QUERY_RESULT_AVAILABLE:         34919
		GL_BUFFER_MAPPED:                  35004
		GL_BUFFER_MAP_POINTER:             35005
		GL_STREAM_READ:                    35041
		GL_STREAM_COPY:                    35042
		GL_STATIC_READ:                    35045
		GL_STATIC_COPY:                    35046
		GL_DYNAMIC_READ:                   35049
		GL_DYNAMIC_COPY:                   35050
		GL_MAX_DRAW_BUFFERS:               34852
		GL_DRAW_BUFFER0:                   34853
		GL_DRAW_BUFFER1:                   34854
		GL_DRAW_BUFFER2:                   34855
		GL_DRAW_BUFFER3:                   34856
		GL_DRAW_BUFFER4:                   34857
		GL_DRAW_BUFFER5:                   34858
		GL_DRAW_BUFFER6:                   34859
		GL_DRAW_BUFFER7:                   34860
		GL_DRAW_BUFFER8:                   34861
		GL_DRAW_BUFFER9:                   34862
		GL_DRAW_BUFFER10:                  34863
		GL_DRAW_BUFFER11:                  34864
		GL_DRAW_BUFFER12:                  34865
		GL_DRAW_BUFFER13:                  34866
		GL_DRAW_BUFFER14:                  34867
		GL_DRAW_BUFFER15:                  34868
		GL_MAX_FRAGMENT_UNIFORM_COMPONENTS: 35657
		GL_MAX_VERTEX_UNIFORM_COMPONENTS:  35658
		GL_SAMPLER_3D:                     35679
		GL_SAMPLER_2D_SHADOW:              35682
		GL_FRAGMENT_SHADER_DERIVATIVE_HINT: 35723
		GL_PIXEL_PACK_BUFFER:              35051
		GL_PIXEL_UNPACK_BUFFER:            35052
		GL_PIXEL_PACK_BUFFER_BINDING:      35053
		GL_PIXEL_UNPACK_BUFFER_BINDING:    35055
		GL_FLOAT_MAT2x3:                   35685
		GL_FLOAT_MAT2x4:                   35686
		GL_FLOAT_MAT3x2:                   35687
		GL_FLOAT_MAT3x4:                   35688
		GL_FLOAT_MAT4x2:                   35689
		GL_FLOAT_MAT4x3:                   35690
		GL_SRGB:                           35904
		GL_SRGB8:                          35905
		GL_SRGB8_ALPHA8:                   35907
		GL_COMPARE_REF_TO_TEXTURE:         34894
		GL_MAJOR_VERSION:                  33307
		GL_MINOR_VERSION:                  33308
		GL_NUM_EXTENSIONS:                 33309
		GL_RGBA32F:                        34836
		GL_RGB32F:                         34837
		GL_RGBA16F:                        34842
		GL_RGB16F:                         34843
		GL_VERTEX_ATTRIB_ARRAY_INTEGER:    35069
		GL_MAX_ARRAY_TEXTURE_LAYERS:       35071
		GL_MIN_PROGRAM_TEXEL_OFFSET:       35076
		GL_MAX_PROGRAM_TEXEL_OFFSET:       35077
		GL_MAX_VARYING_COMPONENTS:         35659
		GL_TEXTURE_2D_ARRAY:               35866
		GL_TEXTURE_BINDING_2D_ARRAY:       35869
		GL_R11F_G11F_B10F:                 35898
		GL_UNSIGNED_INT_10F_11F_11F_REV:   35899
		GL_RGB9_E5:                        35901
		GL_UNSIGNED_INT_5_9_9_9_REV:       35902
		GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH: 35958
		GL_TRANSFORM_FEEDBACK_BUFFER_MODE: 35967
		GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS: 35968
		GL_TRANSFORM_FEEDBACK_VARYINGS:    35971
		GL_TRANSFORM_FEEDBACK_BUFFER_START: 35972
		GL_TRANSFORM_FEEDBACK_BUFFER_SIZE: 35973
		GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN: 35976
		GL_RASTERIZER_DISCARD:             35977
		GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS: 35978
		GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS: 35979
		GL_INTERLEAVED_ATTRIBS:            35980
		GL_SEPARATE_ATTRIBS:               35981
		GL_TRANSFORM_FEEDBACK_BUFFER:      35982
		GL_TRANSFORM_FEEDBACK_BUFFER_BINDING: 35983
		GL_RGBA32UI:                       36208
		GL_RGB32UI:                        36209
		GL_RGBA16UI:                       36214
		GL_RGB16UI:                        36215
		GL_RGBA8UI:                        36220
		GL_RGB8UI:                         36221
		GL_RGBA32I:                        36226
		GL_RGB32I:                         36227
		GL_RGBA16I:                        36232
		GL_RGB16I:                         36233
		GL_RGBA8I:                         36238
		GL_RGB8I:                          36239
		GL_RED_INTEGER:                    36244
		GL_RGB_INTEGER:                    36248
		GL_RGBA_INTEGER:                   36249
		GL_SAMPLER_2D_ARRAY:               36289
		GL_SAMPLER_2D_ARRAY_SHADOW:        36292
		GL_SAMPLER_CUBE_SHADOW:            36293
		GL_UNSIGNED_INT_VEC2:              36294
		GL_UNSIGNED_INT_VEC3:              36295
		GL_UNSIGNED_INT_VEC4:              36296
		GL_INT_SAMPLER_2D:                 36298
		GL_INT_SAMPLER_3D:                 36299
		GL_INT_SAMPLER_CUBE:               36300
		GL_INT_SAMPLER_2D_ARRAY:           36303
		GL_UNSIGNED_INT_SAMPLER_2D:        36306
		GL_UNSIGNED_INT_SAMPLER_3D:        36307
		GL_UNSIGNED_INT_SAMPLER_CUBE:      36308
		GL_UNSIGNED_INT_SAMPLER_2D_ARRAY:  36311
		GL_BUFFER_ACCESS_FLAGS:            37151
		GL_BUFFER_MAP_LENGTH:              37152
		GL_BUFFER_MAP_OFFSET:              37153
		GL_DEPTH_COMPONENT32F:             36012
		GL_DEPTH32F_STENCIL8:              36013
		GL_FLOAT_32_UNSIGNED_INT_24_8_REV: 36269
		GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING: 33296
		GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE: 33297
		GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE: 33298
		GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE: 33299
		GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE: 33300
		GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE: 33301
		GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE: 33302
		GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE: 33303
		GL_FRAMEBUFFER_DEFAULT:            33304
		GL_FRAMEBUFFER_UNDEFINED:          33305
		GL_DEPTH_STENCIL_ATTACHMENT:       33306
		GL_DEPTH_STENCIL:                  34041
		GL_UNSIGNED_INT_24_8:              34042
		GL_DEPTH24_STENCIL8:               35056
		GL_UNSIGNED_NORMALIZED:            35863
		GL_DRAW_FRAMEBUFFER_BINDING:       36006
		GL_READ_FRAMEBUFFER:               36008
		GL_DRAW_FRAMEBUFFER:               36009
		GL_READ_FRAMEBUFFER_BINDING:       36010
		GL_RENDERBUFFER_SAMPLES:           36011
		GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER: 36052
		GL_MAX_COLOR_ATTACHMENTS:          36063
		GL_COLOR_ATTACHMENT1:              36065
		GL_COLOR_ATTACHMENT2:              36066
		GL_COLOR_ATTACHMENT3:              36067
		GL_COLOR_ATTACHMENT4:              36068
		GL_COLOR_ATTACHMENT5:              36069
		GL_COLOR_ATTACHMENT6:              36070
		GL_COLOR_ATTACHMENT7:              36071
		GL_COLOR_ATTACHMENT8:              36072
		GL_COLOR_ATTACHMENT9:              36073
		GL_COLOR_ATTACHMENT10:             36074
		GL_COLOR_ATTACHMENT11:             36075
		GL_COLOR_ATTACHMENT12:             36076
		GL_COLOR_ATTACHMENT13:             36077
		GL_COLOR_ATTACHMENT14:             36078
		GL_COLOR_ATTACHMENT15:             36079
		GL_COLOR_ATTACHMENT16:             36080
		GL_COLOR_ATTACHMENT17:             36081
		GL_COLOR_ATTACHMENT18:             36082
		GL_COLOR_ATTACHMENT19:             36083
		GL_COLOR_ATTACHMENT20:             36084
		GL_COLOR_ATTACHMENT21:             36085
		GL_COLOR_ATTACHMENT22:             36086
		GL_COLOR_ATTACHMENT23:             36087
		GL_COLOR_ATTACHMENT24:             36088
		GL_COLOR_ATTACHMENT25:             36089
		GL_COLOR_ATTACHMENT26:             36090
		GL_COLOR_ATTACHMENT27:             36091
		GL_COLOR_ATTACHMENT28:             36092
		GL_COLOR_ATTACHMENT29:             36093
		GL_COLOR_ATTACHMENT30:             36094
		GL_COLOR_ATTACHMENT31:             36095
		GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE: 36182
		GL_MAX_SAMPLES:                    36183
		GL_HALF_FLOAT:                     5131
		GL_MAP_READ_BIT:                   1
		GL_MAP_WRITE_BIT:                  2
		GL_MAP_INVALIDATE_RANGE_BIT:       4
		GL_MAP_INVALIDATE_BUFFER_BIT:      8
		GL_MAP_FLUSH_EXPLICIT_BIT:         16
		GL_MAP_UNSYNCHRONIZED_BIT:         32
		GL_RG:                             33319
		GL_RG_INTEGER:                     33320
		GL_R8:                             33321
		GL_RG8:                            33323
		GL_R16F:                           33325
		GL_R32F:                           33326
		GL_RG16F:                          33327
		GL_RG32F:                          33328
		GL_R8I:                            33329
		GL_R8UI:                           33330
		GL_R16I:                           33331
		GL_R16UI:                          33332
		GL_R32I:                           33333
		GL_R32UI:                          33334
		GL_RG8I:                           33335
		GL_RG8UI:                          33336
		GL_RG16I:                          33337
		GL_RG16UI:                         33338
		GL_RG32I:                          33339
		GL_RG32UI:                         33340
		GL_VERTEX_ARRAY_BINDING:           34229
		GL_R8_SNORM:                       36756
		GL_RG8_SNORM:                      36757
		GL_RGB8_SNORM:                     36758
		GL_RGBA8_SNORM:                    36759
		GL_SIGNED_NORMALIZED:              36764
		GL_PRIMITIVE_RESTART_FIXED_INDEX:  36201
		GL_COPY_READ_BUFFER:               36662
		GL_COPY_WRITE_BUFFER:              36663
		GL_COPY_READ_BUFFER_BINDING:       36662
		GL_COPY_WRITE_BUFFER_BINDING:      36663
		GL_UNIFORM_BUFFER:                 35345
		GL_UNIFORM_BUFFER_BINDING:         35368
		GL_UNIFORM_BUFFER_START:           35369
		GL_UNIFORM_BUFFER_SIZE:            35370
		GL_MAX_VERTEX_UNIFORM_BLOCKS:      35371
		GL_MAX_FRAGMENT_UNIFORM_BLOCKS:    35373
		GL_MAX_COMBINED_UNIFORM_BLOCKS:    35374
		GL_MAX_UNIFORM_BUFFER_BINDINGS:    35375
		GL_MAX_UNIFORM_BLOCK_SIZE:         35376
		GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS: 35377
		GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS: 35379
		GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT: 35380
		GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH: 35381
		GL_ACTIVE_UNIFORM_BLOCKS:          35382
		GL_UNIFORM_TYPE:                   35383
		GL_UNIFORM_SIZE:                   35384
		GL_UNIFORM_NAME_LENGTH:            35385
		GL_UNIFORM_BLOCK_INDEX:            35386
		GL_UNIFORM_OFFSET:                 35387
		GL_UNIFORM_ARRAY_STRIDE:           35388
		GL_UNIFORM_MATRIX_STRIDE:          35389
		GL_UNIFORM_IS_ROW_MAJOR:           35390
		GL_UNIFORM_BLOCK_BINDING:          35391
		GL_UNIFORM_BLOCK_DATA_SIZE:        35392
		GL_UNIFORM_BLOCK_NAME_LENGTH:      35393
		GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS:  35394
		GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES: 35395
		GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER: 35396
		GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER: 35398
		GL_INVALID_INDEX:                  -1
		GL_MAX_VERTEX_OUTPUT_COMPONENTS:   37154
		GL_MAX_FRAGMENT_INPUT_COMPONENTS:  37157
		GL_MAX_SERVER_WAIT_TIMEOUT:        37137
		GL_OBJECT_TYPE:                    37138
		GL_SYNC_CONDITION:                 37139
		GL_SYNC_STATUS:                    37140
		GL_SYNC_FLAGS:                     37141
		GL_SYNC_FENCE:                     37142
		GL_SYNC_GPU_COMMANDS_COMPLETE:     37143
		GL_UNSIGNALED:                     37144
		GL_SIGNALED:                       37145
		GL_ALREADY_SIGNALED:               37146
		GL_TIMEOUT_EXPIRED:                37147
		GL_CONDITION_SATISFIED:            37148
		GL_WAIT_FAILED:                    37149
		GL_SYNC_FLUSH_COMMANDS_BIT:        1
		{#define GL_TIMEOUT_IGNORED                0xFFFFFFFFFFFFFFFFull}
		GL_VERTEX_ATTRIB_ARRAY_DIVISOR:    35070
		GL_ANY_SAMPLES_PASSED:             35887
		GL_ANY_SAMPLES_PASSED_CONSERVATIVE: 36202
		GL_SAMPLER_BINDING:                35097
		GL_RGB10_A2UI:                     36975
		GL_TEXTURE_SWIZZLE_R:              36418
		GL_TEXTURE_SWIZZLE_G:              36419
		GL_TEXTURE_SWIZZLE_B:              36420
		GL_TEXTURE_SWIZZLE_A:              36421
		GL_GREEN:                          6404
		GL_BLUE:                           6405
		GL_INT_2_10_10_10_REV:             36255
		GL_TRANSFORM_FEEDBACK:             36386
		GL_TRANSFORM_FEEDBACK_PAUSED:      36387
		GL_TRANSFORM_FEEDBACK_ACTIVE:      36388
		GL_TRANSFORM_FEEDBACK_BINDING:     36389
		GL_PROGRAM_BINARY_RETRIEVABLE_HINT: 33367
		GL_PROGRAM_BINARY_LENGTH:          34625
		GL_NUM_PROGRAM_BINARY_FORMATS:     34814
		GL_PROGRAM_BINARY_FORMATS:         34815
		GL_COMPRESSED_R11_EAC:             37488
		GL_COMPRESSED_SIGNED_R11_EAC:      37489
		GL_COMPRESSED_RG11_EAC:            37490
		GL_COMPRESSED_SIGNED_RG11_EAC:     37491
		GL_COMPRESSED_RGB8_ETC2:           37492
		GL_COMPRESSED_SRGB8_ETC2:          37493
		GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2: 37494
		GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2: 37495
		GL_COMPRESSED_RGBA8_ETC2_EAC:      37496
		GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC: 37497
		GL_TEXTURE_IMMUTABLE_FORMAT:       37167
		GL_MAX_ELEMENT_INDEX:              36203
		GL_NUM_SAMPLE_COUNTS:              37760
		GL_TEXTURE_IMMUTABLE_LEVELS:       33503
	;
	; GLES 3.0 PROTOTYPES
		glReadBuffer: make routine! [ src [GLenum] ] gles32-lib "glReadBuffer" 
		glDrawRangeElements: make routine! [ mode [GLenum] start [GLuint] end [GLuint] count [GLsizei] type [GLenum] indices [integer!] ] gles32-lib "glDrawRangeElements" 
		glTexImage3D: make routine! [ target [GLenum] level [GLint] internalformat [GLint] width [GLsizei] height [GLsizei] depth [GLsizei] border [GLint] format [GLenum] type [GLenum] pixels [integer!] ] gles32-lib "glTexImage3D" 
		glTexSubImage3D: make routine! [ target [GLenum] level [GLint] xoffset [GLint] yoffset [GLint] zoffset [GLint] width [GLsizei] height [GLsizei] depth [GLsizei] format [GLenum] type [GLenum] pixels [integer!] ] gles32-lib "glTexSubImage3D" 
		glCopyTexSubImage3D: make routine! [ target [GLenum] level [GLint] xoffset [GLint] yoffset [GLint] zoffset [GLint] x [GLint] y [GLint] width [GLsizei] height [GLsizei] ] gles32-lib "glCopyTexSubImage3D" 
		glCompressedTexImage3D: make routine! [ target [GLenum] level [GLint] internalformat [GLenum] width [GLsizei] height [GLsizei] depth [GLsizei] border [GLint] imageSize [GLsizei] data [integer!] ] gles32-lib "glCompressedTexImage3D" 
		glCompressedTexSubImage3D: make routine! [ target [GLenum] level [GLint] xoffset [GLint] yoffset [GLint] zoffset [GLint] width [GLsizei] height [GLsizei] depth [GLsizei] format [GLenum] imageSize [GLsizei] data [integer!] ] gles32-lib "glCompressedTexSubImage3D" 
		glGenQueries: make routine! [ n [GLsizei] ids [integer!] ] gles32-lib "glGenQueries" 
		glDeleteQueries: make routine! [ n [GLsizei] ids [integer!] ] gles32-lib "glDeleteQueries" 
		glIsQuery: make routine! [ id [GLuint] return: [GLboolean] ] gles32-lib "glIsQuery" 
		glBeginQuery: make routine! [ target [GLenum] id [GLuint] ] gles32-lib "glBeginQuery" 
		glEndQuery: make routine! [ target [GLenum] ] gles32-lib "glEndQuery" 
		glGetQueryiv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetQueryiv" 
		glGetQueryObjectuiv: make routine! [ id [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetQueryObjectuiv" 
		glUnmapBuffer: make routine! [ target [GLenum] return: [GLboolean] ] gles32-lib "glUnmapBuffer" 
		glGetBufferPointerv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetBufferPointerv" 
		glDrawBuffers: make routine! [ n [GLsizei] bufs [integer!] ] gles32-lib "glDrawBuffers" 
		glUniformMatrix2x3fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix2x3fv" 
		glUniformMatrix3x2fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix3x2fv" 
		glUniformMatrix2x4fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix2x4fv" 
		glUniformMatrix4x2fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix4x2fv" 
		glUniformMatrix3x4fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix3x4fv" 
		glUniformMatrix4x3fv: make routine! [ location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glUniformMatrix4x3fv" 
		glBlitFramebuffer: make routine! [ srcX0 [GLint] srcY0 [GLint] srcX1 [GLint] srcY1 [GLint] dstX0 [GLint] dstY0 [GLint] dstX1 [GLint] dstY1 [GLint] mask [GLbitfield] filter [GLenum] ] gles32-lib "glBlitFramebuffer" 
		glRenderbufferStorageMultisample: make routine! [ target [GLenum] samples [GLsizei] internalformat [GLenum] width [GLsizei] height [GLsizei] ] gles32-lib "glRenderbufferStorageMultisample" 
		glFramebufferTextureLayer: make routine! [ target [GLenum] attachment [GLenum] texture [GLuint] level [GLint] layer [GLint] ] gles32-lib "glFramebufferTextureLayer" 
		glMapBufferRange: make routine! [ target [GLenum] offset [GLintptr] length [GLsizeiptr] access [GLbitfield] return: [integer!] ] gles32-lib "glMapBufferRange" 
		glFlushMappedBufferRange: make routine! [ target [GLenum] offset [GLintptr] length [GLsizeiptr] ] gles32-lib "glFlushMappedBufferRange" 
		glBindVertexArray: make routine! [ array [GLuint] ] gles32-lib "glBindVertexArray" 
		glDeleteVertexArrays: make routine! [ n [GLsizei] arrays [integer!] ] gles32-lib "glDeleteVertexArrays" 
		; better avoid using this ? At least with Firefox32bit ?
		;glGenVertexArrays: make routine! [ n [GLsizei] arrays [struct! []] ] gles32-lib "glGenVertexArrays" 
		;
		glIsVertexArray: make routine! [ array [GLuint] return: [GLboolean] ] gles32-lib "glIsVertexArray" 
		glGetIntegeri_v: make routine! [ target [GLenum] index [GLuint] data [integer!] ] gles32-lib "glGetIntegeri_v" 
		glBeginTransformFeedback: make routine! [ primitiveMode [GLenum] ] gles32-lib "glBeginTransformFeedback" 
		glEndTransformFeedback: make routine! [ ] gles32-lib "glEndTransformFeedback" 
		glBindBufferRange: make routine! [ target [GLenum] index [GLuint] buffer [GLuint] offset [GLintptr] size [GLsizeiptr] ] gles32-lib "glBindBufferRange" 
		glBindBufferBase: make routine! [ target [GLenum] index [GLuint] buffer [GLuint] ] gles32-lib "glBindBufferBase" 
		glTransformFeedbackVaryings: make routine! [ program [GLuint] count [GLsizei] varyings [integer!] bufferMode [GLenum] ] gles32-lib "glTransformFeedbackVaryings"
		glGetTransformFeedbackVarying: make routine! [ program [GLuint] index [GLuint] bufSize [GLsizei] length [integer!] size [integer!] type [integer!] name [string!] ] gles32-lib "glGetTransformFeedbackVarying" 
		glVertexAttribIPointer: make routine! [ index [GLuint] size [GLint] type [GLenum] stride [GLsizei] pointer [integer!] ] gles32-lib "glVertexAttribIPointer" 
		glGetVertexAttribIiv: make routine! [ index [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetVertexAttribIiv" 
		glGetVertexAttribIuiv: make routine! [ index [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetVertexAttribIuiv" 
		glVertexAttribI4i: make routine! [ index [GLuint] x [GLint] y [GLint] z [GLint] w [GLint] ] gles32-lib "glVertexAttribI4i" 
		glVertexAttribI4ui: make routine! [ index [GLuint] x [GLuint] y [GLuint] z [GLuint] w [GLuint] ] gles32-lib "glVertexAttribI4ui" 
		glVertexAttribI4iv: make routine! [ index [GLuint] v [integer!] ] gles32-lib "glVertexAttribI4iv" 
		glVertexAttribI4uiv: make routine! [ index [GLuint] v [integer!] ] gles32-lib "glVertexAttribI4uiv" 
		glGetUniformuiv: make routine! [ program [GLuint] location [GLint] params [integer!] ] gles32-lib "glGetUniformuiv" 
		glGetFragDataLocation: make routine! [ program [GLuint] name [string!] return: [GLint] ] gles32-lib "glGetFragDataLocation" 
		glUniform1ui: make routine! [ location [GLint] v0 [GLuint] ] gles32-lib "glUniform1ui" 
		glUniform2ui: make routine! [ location [GLint] v0 [GLuint] v1 [GLuint] ] gles32-lib "glUniform2ui" 
		glUniform3ui: make routine! [ location [GLint] v0 [GLuint] v1 [GLuint] v2 [GLuint] ] gles32-lib "glUniform3ui" 
		glUniform4ui: make routine! [ location [GLint] v0 [GLuint] v1 [GLuint] v2 [GLuint] v3 [GLuint] ] gles32-lib "glUniform4ui" 
		glUniform1uiv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform1uiv" 
		glUniform2uiv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform2uiv" 
		glUniform3uiv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform3uiv" 
		glUniform4uiv: make routine! [ location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glUniform4uiv" 
		glClearBufferiv: make routine! [ buffer [GLenum] drawbuffer [GLint] value [integer!] ] gles32-lib "glClearBufferiv" 
		glClearBufferuiv: make routine! [ buffer [GLenum] drawbuffer [GLint] value [integer!] ] gles32-lib "glClearBufferuiv" 
		glClearBufferfv: make routine! [ buffer [GLenum] drawbuffer [GLint] value [integer!] ] gles32-lib "glClearBufferfv" 
		glClearBufferfi: make routine! [ buffer [GLenum] drawbuffer [GLint] depth [float] stencil [GLint] ] gles32-lib "glClearBufferfi" 
		glGetStringi: make routine! [ name [GLenum] index [GLuint] return: [string!] ] gles32-lib "glGetStringi" 
		glCopyBufferSubData: make routine! [ readTarget [GLenum] writeTarget [GLenum] readOffset [GLintptr] writeOffset [GLintptr] size [GLsizeiptr] ] gles32-lib "glCopyBufferSubData" 
		glGetUniformIndices: make routine! [ program [GLuint] uniformCount [GLsizei] uniformNames [integer!] uniformIndices [integer!] ] gles32-lib "glGetUniformIndices"
		glGetActiveUniformsiv: make routine! [ program [GLuint] uniformCount [GLsizei] uniformIndices [integer!] pname [GLenum] params [integer!] ] gles32-lib "glGetActiveUniformsiv" 
		glGetUniformBlockIndex: make routine! [ program [GLuint] uniformBlockName [integer!] return: [GLuint] ] gles32-lib "glGetUniformBlockIndex" 
		glGetActiveUniformBlockiv: make routine! [ program [GLuint] uniformBlockIndex [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetActiveUniformBlockiv" 
		glGetActiveUniformBlockName: make routine! [ program [GLuint] uniformBlockIndex [GLuint] bufSize [GLsizei] length [integer!] uniformBlockName [integer!] ] gles32-lib "glGetActiveUniformBlockName" 
		glUniformBlockBinding: make routine! [ program [GLuint] uniformBlockIndex [GLuint] uniformBlockBinding [GLuint] ] gles32-lib "glUniformBlockBinding" 
		glDrawArraysInstanced: make routine! [ mode [GLenum] first [GLint] count [GLsizei] instancecount [GLsizei] ] gles32-lib "glDrawArraysInstanced" 
		glDrawElementsInstanced: make routine! [ mode [GLenum] count [GLsizei] type [GLenum] indices [integer!] instancecount [GLsizei] ] gles32-lib "glDrawElementsInstanced" 
		glFenceSync: make routine! [ condition [GLenum] flags [GLbitfield] return: [GLsync] ] gles32-lib "glFenceSync" 
		glIsSync: make routine! [ sync [GLsync] return: [GLboolean] ] gles32-lib "glIsSync" 
		glDeleteSync: make routine! [ sync [GLsync] ] gles32-lib "glDeleteSync" 
		glClientWaitSync: make routine! [ sync [GLsync] flags [GLbitfield] timeout [double] return: [GLenum] ] gles32-lib "glClientWaitSync" 
		glWaitSync: make routine! [ sync [GLsync] flags [GLbitfield] timeout [double] ] gles32-lib "glWaitSync" 
		glGetInteger64v: make routine! [ pname [GLenum] data [integer!] ] gles32-lib "glGetInteger64v" 
		glGetSynciv: make routine! [ sync [GLsync] pname [GLenum] bufSize [GLsizei] length [integer!] values [integer!] ] gles32-lib "glGetSynciv" 
		glGetInteger64i_v: make routine! [ target [GLenum] index [GLuint] data [integer!] ] gles32-lib "glGetInteger64i_v" 
		glGetBufferParameteri64v: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetBufferParameteri64v" 
		glGenSamplers: make routine! [ count [GLsizei] samplers [integer!] ] gles32-lib "glGenSamplers" 
		glDeleteSamplers: make routine! [ count [GLsizei] samplers [integer!] ] gles32-lib "glDeleteSamplers" 
		glIsSampler: make routine! [ sampler [GLuint] return: [GLboolean] ] gles32-lib "glIsSampler" 
		glBindSampler: make routine! [ unit [GLuint] sampler [GLuint] ] gles32-lib "glBindSampler" 
		glSamplerParameteri: make routine! [ sampler [GLuint] pname [GLenum] param [GLint] ] gles32-lib "glSamplerParameteri" 
		glSamplerParameteriv: make routine! [ sampler [GLuint] pname [GLenum] param [integer!] ] gles32-lib "glSamplerParameteriv" 
		glSamplerParameterf: make routine! [ sampler [GLuint] pname [GLenum] param [float] ] gles32-lib "glSamplerParameterf" 
		glSamplerParameterfv: make routine! [ sampler [GLuint] pname [GLenum] param [integer!] ] gles32-lib "glSamplerParameterfv" 
		glGetSamplerParameteriv: make routine! [ sampler [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetSamplerParameteriv" 
		glGetSamplerParameterfv: make routine! [ sampler [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetSamplerParameterfv" 
		glVertexAttribDivisor: make routine! [ index [GLuint] divisor [GLuint] ] gles32-lib "glVertexAttribDivisor" 
		glBindTransformFeedback: make routine! [ target [GLenum] id [GLuint] ] gles32-lib "glBindTransformFeedback" 
		glDeleteTransformFeedbacks: make routine! [ n [GLsizei] ids [integer!] ] gles32-lib "glDeleteTransformFeedbacks" 
		glGenTransformFeedbacks: make routine! [ n [GLsizei] ids [integer!] ] gles32-lib "glGenTransformFeedbacks" 
		glIsTransformFeedback: make routine! [ id [GLuint] return: [GLboolean] ] gles32-lib "glIsTransformFeedback" 
		glPauseTransformFeedback: make routine! [ ] gles32-lib "glPauseTransformFeedback" 
		glResumeTransformFeedback: make routine! [ ] gles32-lib "glResumeTransformFeedback" 
		glGetProgramBinary: make routine! [ program [GLuint] bufSize [GLsizei] length [integer!] binaryFormat [integer!] binary [integer!] ] gles32-lib "glGetProgramBinary" 
		glProgramBinary: make routine! [ program [GLuint] binaryFormat [GLenum] binary [integer!] length [GLsizei] ] gles32-lib "glProgramBinary" 
		glProgramParameteri: make routine! [ program [GLuint] pname [GLenum] value [GLint] ] gles32-lib "glProgramParameteri" 
		glInvalidateFramebuffer: make routine! [ target [GLenum] numAttachments [GLsizei] attachments [integer!] ] gles32-lib "glInvalidateFramebuffer" 
		glInvalidateSubFramebuffer: make routine! [ target [GLenum] numAttachments [GLsizei] attachments [integer!] x [GLint] y [GLint] width [GLsizei] height [GLsizei] ] gles32-lib "glInvalidateSubFramebuffer" 
		glTexStorage2D: make routine! [ target [GLenum] levels [GLsizei] internalformat [GLenum] width [GLsizei] height [GLsizei] ] gles32-lib "glTexStorage2D" 
		glTexStorage3D: make routine! [ target [GLenum] levels [GLsizei] internalformat [GLenum] width [GLsizei] height [GLsizei] depth [GLsizei] ] gles32-lib "glTexStorage3D" 
		glGetInternalformativ: make routine! [ target [GLenum] internalformat [GLenum] pname [GLenum] bufSize [GLsizei] params [integer!] ] gles32-lib "glGetInternalformativ" 
	;
	] ; if GLES_this_version
	if GLES_this_version >= 3.1.0 [
	; GLES 3.1 defines
		GL_COMPUTE_SHADER:                 37305
		GL_MAX_COMPUTE_UNIFORM_BLOCKS:     37307
		GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS: 37308
		GL_MAX_COMPUTE_IMAGE_UNIFORMS:     37309
		GL_MAX_COMPUTE_SHARED_MEMORY_SIZE: 33378
		GL_MAX_COMPUTE_UNIFORM_COMPONENTS: 33379
		GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS: 33380
		GL_MAX_COMPUTE_ATOMIC_COUNTERS:    33381
		GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS: 33382
		GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS: 37099
		GL_MAX_COMPUTE_WORK_GROUP_COUNT:   37310
		GL_MAX_COMPUTE_WORK_GROUP_SIZE:    37311
		GL_COMPUTE_WORK_GROUP_SIZE:        33383
		GL_DISPATCH_INDIRECT_BUFFER:       37102
		GL_DISPATCH_INDIRECT_BUFFER_BINDING: 37103
		GL_COMPUTE_SHADER_BIT:             32
		GL_DRAW_INDIRECT_BUFFER:           36671
		GL_DRAW_INDIRECT_BUFFER_BINDING:   36675
		GL_MAX_UNIFORM_LOCATIONS:          33390
		GL_FRAMEBUFFER_DEFAULT_WIDTH:      37648
		GL_FRAMEBUFFER_DEFAULT_HEIGHT:     37649
		GL_FRAMEBUFFER_DEFAULT_SAMPLES:    37651
		GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS: 37652
		GL_MAX_FRAMEBUFFER_WIDTH:          37653
		GL_MAX_FRAMEBUFFER_HEIGHT:         37654
		GL_MAX_FRAMEBUFFER_SAMPLES:        37656
		GL_UNIFORM:                        37601
		GL_UNIFORM_BLOCK:                  37602
		GL_PROGRAM_INPUT:                  37603
		GL_PROGRAM_OUTPUT:                 37604
		GL_BUFFER_VARIABLE:                37605
		GL_SHADER_STORAGE_BLOCK:           37606
		GL_ATOMIC_COUNTER_BUFFER:          37568
		GL_TRANSFORM_FEEDBACK_VARYING:     37620
		GL_ACTIVE_RESOURCES:               37621
		GL_MAX_NAME_LENGTH:                37622
		GL_MAX_NUM_ACTIVE_VARIABLES:       37623
		GL_NAME_LENGTH:                    37625
		GL_TYPE:                           37626
		GL_ARRAY_SIZE:                     37627
		GL_OFFSET:                         37628
		GL_BLOCK_INDEX:                    37629
		GL_ARRAY_STRIDE:                   37630
		GL_MATRIX_STRIDE:                  37631
		GL_IS_ROW_MAJOR:                   37632
		GL_ATOMIC_COUNTER_BUFFER_INDEX:    37633
		GL_BUFFER_BINDING:                 37634
		GL_BUFFER_DATA_SIZE:               37635
		GL_NUM_ACTIVE_VARIABLES:           37636
		GL_ACTIVE_VARIABLES:               37637
		GL_REFERENCED_BY_VERTEX_SHADER:    37638
		GL_REFERENCED_BY_FRAGMENT_SHADER:  37642
		GL_REFERENCED_BY_COMPUTE_SHADER:   37643
		GL_TOP_LEVEL_ARRAY_SIZE:           37644
		GL_TOP_LEVEL_ARRAY_STRIDE:         37645
		GL_LOCATION:                       37646
		GL_VERTEX_SHADER_BIT:              1
		GL_FRAGMENT_SHADER_BIT:            2
		GL_ALL_SHADER_BITS:                -1
		GL_PROGRAM_SEPARABLE:              33368
		GL_ACTIVE_PROGRAM:                 33369
		GL_PROGRAM_PIPELINE_BINDING:       33370
		GL_ATOMIC_COUNTER_BUFFER_BINDING:  37569
		GL_ATOMIC_COUNTER_BUFFER_START:    37570
		GL_ATOMIC_COUNTER_BUFFER_SIZE:     37571
		GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS: 37580
		GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS: 37584
		GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS: 37585
		GL_MAX_VERTEX_ATOMIC_COUNTERS:     37586
		GL_MAX_FRAGMENT_ATOMIC_COUNTERS:   37590
		GL_MAX_COMBINED_ATOMIC_COUNTERS:   37591
		GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE: 37592
		GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS: 37596
		GL_ACTIVE_ATOMIC_COUNTER_BUFFERS:  37593
		GL_UNSIGNED_INT_ATOMIC_COUNTER:    37595
		GL_MAX_IMAGE_UNITS:                36664
		GL_MAX_VERTEX_IMAGE_UNIFORMS:      37066
		GL_MAX_FRAGMENT_IMAGE_UNIFORMS:    37070
		GL_MAX_COMBINED_IMAGE_UNIFORMS:    37071
		GL_IMAGE_BINDING_NAME:             36666
		GL_IMAGE_BINDING_LEVEL:            36667
		GL_IMAGE_BINDING_LAYERED:          36668
		GL_IMAGE_BINDING_LAYER:            36669
		GL_IMAGE_BINDING_ACCESS:           36670
		GL_IMAGE_BINDING_FORMAT:           36974
		GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT: 1
		GL_ELEMENT_ARRAY_BARRIER_BIT:      2
		GL_UNIFORM_BARRIER_BIT:            4
		GL_TEXTURE_FETCH_BARRIER_BIT:      8
		GL_SHADER_IMAGE_ACCESS_BARRIER_BIT: 32
		GL_COMMAND_BARRIER_BIT:            64
		GL_PIXEL_BUFFER_BARRIER_BIT:       128
		GL_TEXTURE_UPDATE_BARRIER_BIT:     256
		GL_BUFFER_UPDATE_BARRIER_BIT:      512
		GL_FRAMEBUFFER_BARRIER_BIT:        1024
		GL_TRANSFORM_FEEDBACK_BARRIER_BIT: 2048
		GL_ATOMIC_COUNTER_BARRIER_BIT:     4096
		GL_ALL_BARRIER_BITS:               -1
		GL_IMAGE_2D:                       36941
		GL_IMAGE_3D:                       36942
		GL_IMAGE_CUBE:                     36944
		GL_IMAGE_2D_ARRAY:                 36947
		GL_INT_IMAGE_2D:                   36952
		GL_INT_IMAGE_3D:                   36953
		GL_INT_IMAGE_CUBE:                 36955
		GL_INT_IMAGE_2D_ARRAY:             36958
		GL_UNSIGNED_INT_IMAGE_2D:          36963
		GL_UNSIGNED_INT_IMAGE_3D:          36964
		GL_UNSIGNED_INT_IMAGE_CUBE:        36966
		GL_UNSIGNED_INT_IMAGE_2D_ARRAY:    36969
		GL_IMAGE_FORMAT_COMPATIBILITY_TYPE: 37063
		GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE: 37064
		GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS: 37065
		GL_READ_ONLY:                      35000
		GL_WRITE_ONLY:                     35001
		GL_READ_WRITE:                     35002
		GL_SHADER_STORAGE_BUFFER:          37074
		GL_SHADER_STORAGE_BUFFER_BINDING:  37075
		GL_SHADER_STORAGE_BUFFER_START:    37076
		GL_SHADER_STORAGE_BUFFER_SIZE:     37077
		GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS: 37078
		GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS: 37082
		GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS: 37083
		GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS: 37084
		GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS: 37085
		GL_MAX_SHADER_STORAGE_BLOCK_SIZE:  37086
		GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT: 37087
		GL_SHADER_STORAGE_BARRIER_BIT:     8192
		GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES: 36665
		GL_DEPTH_STENCIL_TEXTURE_MODE:     37098
		GL_STENCIL_INDEX:                  6401
		GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET: 36446
		GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET: 36447
		GL_SAMPLE_POSITION:                36432
		GL_SAMPLE_MASK:                    36433
		GL_SAMPLE_MASK_VALUE:              36434
		GL_TEXTURE_2D_MULTISAMPLE:         37120
		GL_MAX_SAMPLE_MASK_WORDS:          36441
		GL_MAX_COLOR_TEXTURE_SAMPLES:      37134
		GL_MAX_DEPTH_TEXTURE_SAMPLES:      37135
		GL_MAX_INTEGER_SAMPLES:            37136
		GL_TEXTURE_BINDING_2D_MULTISAMPLE: 37124
		GL_TEXTURE_SAMPLES:                37126
		GL_TEXTURE_FIXED_SAMPLE_LOCATIONS: 37127
		GL_TEXTURE_WIDTH:                  4096
		GL_TEXTURE_HEIGHT:                 4097
		GL_TEXTURE_DEPTH:                  32881
		GL_TEXTURE_INTERNAL_FORMAT:        4099
		GL_TEXTURE_RED_SIZE:               32860
		GL_TEXTURE_GREEN_SIZE:             32861
		GL_TEXTURE_BLUE_SIZE:              32862
		GL_TEXTURE_ALPHA_SIZE:             32863
		GL_TEXTURE_DEPTH_SIZE:             34890
		GL_TEXTURE_STENCIL_SIZE:           35057
		GL_TEXTURE_SHARED_SIZE:            35903
		GL_TEXTURE_RED_TYPE:               35856
		GL_TEXTURE_GREEN_TYPE:             35857
		GL_TEXTURE_BLUE_TYPE:              35858
		GL_TEXTURE_ALPHA_TYPE:             35859
		GL_TEXTURE_DEPTH_TYPE:             35862
		GL_TEXTURE_COMPRESSED:             34465
		GL_SAMPLER_2D_MULTISAMPLE:         37128
		GL_INT_SAMPLER_2D_MULTISAMPLE:     37129
		GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE: 37130
		GL_VERTEX_ATTRIB_BINDING:          33492
		GL_VERTEX_ATTRIB_RELATIVE_OFFSET:  33493
		GL_VERTEX_BINDING_DIVISOR:         33494
		GL_VERTEX_BINDING_OFFSET:          33495
		GL_VERTEX_BINDING_STRIDE:          33496
		GL_VERTEX_BINDING_BUFFER:          36687
		GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET: 33497
		GL_MAX_VERTEX_ATTRIB_BINDINGS:     33498
		GL_MAX_VERTEX_ATTRIB_STRIDE:       33509
	;
	; GLES 3.1 PROTOTYPES
		glDispatchCompute: make routine! [ num_groups_x [GLuint] num_groups_y [GLuint] num_groups_z [GLuint] ] gles32-lib "glDispatchCompute" 
		glDispatchComputeIndirect: make routine! [ indirect [GLintptr] ] gles32-lib "glDispatchComputeIndirect" 
		glDrawArraysIndirect: make routine! [ mode [GLenum] indirect [integer!] ] gles32-lib "glDrawArraysIndirect" 
		glDrawElementsIndirect: make routine! [ mode [GLenum] type [GLenum] indirect [integer!] ] gles32-lib "glDrawElementsIndirect" 
		glFramebufferParameteri: make routine! [ target [GLenum] pname [GLenum] param [GLint] ] gles32-lib "glFramebufferParameteri" 
		glGetFramebufferParameteriv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetFramebufferParameteriv" 
		glGetProgramInterfaceiv: make routine! [ program [GLuint] programInterface [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetProgramInterfaceiv" 
		glGetProgramResourceIndex: make routine! [ program [GLuint] programInterface [GLenum] name [string!] return: [GLuint] ] gles32-lib "glGetProgramResourceIndex" 
		glGetProgramResourceName: make routine! [ program [GLuint] programInterface [GLenum] index [GLuint] bufSize [GLsizei] length [integer!] name [string!] ] gles32-lib "glGetProgramResourceName" 
		glGetProgramResourceiv: make routine! [ program [GLuint] programInterface [GLenum] index [GLuint] propCount [GLsizei] props [integer!] bufSize [GLsizei] length [integer!] params [integer!] ] gles32-lib "glGetProgramResourceiv" 
		glGetProgramResourceLocation: make routine! [ program [GLuint] programInterface [GLenum] name [string!] return: [GLint] ] gles32-lib "glGetProgramResourceLocation" 
		glUseProgramStages: make routine! [ pipeline [GLuint] stages [GLbitfield] program [GLuint] ] gles32-lib "glUseProgramStages" 
		glActiveShaderProgram: make routine! [ pipeline [GLuint] program [GLuint] ] gles32-lib "glActiveShaderProgram" 
		glCreateShaderProgramv: make routine! [ type [GLenum] count [GLsizei] strings [integer!] return: [GLuint] ] gles32-lib "glCreateShaderProgramv" 
		glBindProgramPipeline: make routine! [ pipeline [GLuint] ] gles32-lib "glBindProgramPipeline" 
		glDeleteProgramPipelines: make routine! [ n [GLsizei] pipelines [integer!] ] gles32-lib "glDeleteProgramPipelines" 
		glGenProgramPipelines: make routine! [ n [GLsizei] pipelines [integer!] ] gles32-lib "glGenProgramPipelines" 
		glIsProgramPipeline: make routine! [ pipeline [GLuint] return: [GLboolean] ] gles32-lib "glIsProgramPipeline" 
		glGetProgramPipelineiv: make routine! [ pipeline [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetProgramPipelineiv" 
		glProgramUniform1i: make routine! [ program [GLuint] location [GLint] v0 [GLint] ] gles32-lib "glProgramUniform1i" 
		glProgramUniform2i: make routine! [ program [GLuint] location [GLint] v0 [GLint] v1 [GLint] ] gles32-lib "glProgramUniform2i" 
		glProgramUniform3i: make routine! [ program [GLuint] location [GLint] v0 [GLint] v1 [GLint] v2 [GLint] ] gles32-lib "glProgramUniform3i" 
		glProgramUniform4i: make routine! [ program [GLuint] location [GLint] v0 [GLint] v1 [GLint] v2 [GLint] v3 [GLint] ] gles32-lib "glProgramUniform4i" 
		glProgramUniform1ui: make routine! [ program [GLuint] location [GLint] v0 [GLuint] ] gles32-lib "glProgramUniform1ui" 
		glProgramUniform2ui: make routine! [ program [GLuint] location [GLint] v0 [GLuint] v1 [GLuint] ] gles32-lib "glProgramUniform2ui" 
		glProgramUniform3ui: make routine! [ program [GLuint] location [GLint] v0 [GLuint] v1 [GLuint] v2 [GLuint] ] gles32-lib "glProgramUniform3ui" 
		glProgramUniform4ui: make routine! [ program [GLuint] location [GLint] v0 [GLuint] v1 [GLuint] v2 [GLuint] v3 [GLuint] ] gles32-lib "glProgramUniform4ui" 
		glProgramUniform1f: make routine! [ program [GLuint] location [GLint] v0 [float] ] gles32-lib "glProgramUniform1f" 
		glProgramUniform2f: make routine! [ program [GLuint] location [GLint] v0 [float] v1 [float] ] gles32-lib "glProgramUniform2f" 
		glProgramUniform3f: make routine! [ program [GLuint] location [GLint] v0 [float] v1 [float] v2 [float] ] gles32-lib "glProgramUniform3f" 
		glProgramUniform4f: make routine! [ program [GLuint] location [GLint] v0 [float] v1 [float] v2 [float] v3 [float] ] gles32-lib "glProgramUniform4f" 
		glProgramUniform1iv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform1iv" 
		glProgramUniform2iv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform2iv" 
		glProgramUniform3iv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform3iv" 
		glProgramUniform4iv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform4iv" 
		glProgramUniform1uiv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform1uiv" 
		glProgramUniform2uiv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform2uiv" 
		glProgramUniform3uiv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform3uiv" 
		glProgramUniform4uiv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform4uiv" 
		glProgramUniform1fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform1fv" 
		glProgramUniform2fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform2fv" 
		glProgramUniform3fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform3fv" 
		glProgramUniform4fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] value [integer!] ] gles32-lib "glProgramUniform4fv" 
		glProgramUniformMatrix2fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix2fv" 
		glProgramUniformMatrix3fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix3fv" 
		glProgramUniformMatrix4fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix4fv" 
		glProgramUniformMatrix2x3fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix2x3fv" 
		glProgramUniformMatrix3x2fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix3x2fv" 
		glProgramUniformMatrix2x4fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix2x4fv" 
		glProgramUniformMatrix4x2fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix4x2fv" 
		glProgramUniformMatrix3x4fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix3x4fv" 
		glProgramUniformMatrix4x3fv: make routine! [ program [GLuint] location [GLint] count [GLsizei] transpose [GLboolean] value [integer!] ] gles32-lib "glProgramUniformMatrix4x3fv" 
		glValidateProgramPipeline: make routine! [ pipeline [GLuint] ] gles32-lib "glValidateProgramPipeline" 
		glGetProgramPipelineInfoLog: make routine! [ pipeline [GLuint] bufSize [GLsizei] length [integer!] infoLog [integer!] ] gles32-lib "glGetProgramPipelineInfoLog" 
		glBindImageTexture: make routine! [ unit [GLuint] texture [GLuint] level [GLint] layered [GLboolean] layer [GLint] access [GLenum] format [GLenum] ] gles32-lib "glBindImageTexture" 
		glGetBooleani_v: make routine! [ target [GLenum] index [GLuint] data [integer!] ] gles32-lib "glGetBooleani_v" 
		glMemoryBarrier: make routine! [ barriers [GLbitfield] ] gles32-lib "glMemoryBarrier" 
		glMemoryBarrierByRegion: make routine! [ barriers [GLbitfield] ] gles32-lib "glMemoryBarrierByRegion" 
		glTexStorage2DMultisample: make routine! [ target [GLenum] samples [GLsizei] internalformat [GLenum] width [GLsizei] height [GLsizei] fixedsamplelocations [GLboolean] ] gles32-lib "glTexStorage2DMultisample" 
		glGetMultisamplefv: make routine! [ pname [GLenum] index [GLuint] val [integer!] ] gles32-lib "glGetMultisamplefv" 
		glSampleMaski: make routine! [ maskNumber [GLuint] mask [GLbitfield] ] gles32-lib "glSampleMaski" 
		glGetTexLevelParameteriv: make routine! [ target [GLenum] level [GLint] pname [GLenum] params [integer!] ] gles32-lib "glGetTexLevelParameteriv" 
		glGetTexLevelParameterfv: make routine! [ target [GLenum] level [GLint] pname [GLenum] params [integer!] ] gles32-lib "glGetTexLevelParameterfv" 
		glBindVertexBuffer: make routine! [ bindingindex [GLuint] buffer [GLuint] offset [GLintptr] stride [GLsizei] ] gles32-lib "glBindVertexBuffer" 
		glVertexAttribFormat: make routine! [ attribindex [GLuint] size [GLint] type [GLenum] normalized [GLboolean] relativeoffset [GLuint] ] gles32-lib "glVertexAttribFormat" 
		glVertexAttribIFormat: make routine! [ attribindex [GLuint] size [GLint] type [GLenum] relativeoffset [GLuint] ] gles32-lib "glVertexAttribIFormat" 
		glVertexAttribBinding: make routine! [ attribindex [GLuint] bindingindex [GLuint] ] gles32-lib "glVertexAttribBinding" 
		glVertexBindingDivisor: make routine! [ bindingindex [GLuint] divisor [GLuint] ] gles32-lib "glVertexBindingDivisor" 
	;
	;typedef void ( *GLDEBUGPROC)(GLenum source,GLenum type,GLuint id,GLenum severity,GLsizei length,const GLchar *message,const void *userParam);
	] ; if GLES_this_version
	if GLES_this_version >= 3.2.0 [
	; GLES 3.2 defines
		GL_MULTISAMPLE_LINE_WIDTH_RANGE:   37761
		GL_MULTISAMPLE_LINE_WIDTH_GRANULARITY: 37762
		GL_MULTIPLY:                       37524
		GL_SCREEN:                         37525
		GL_OVERLAY:                        37526
		GL_DARKEN:                         37527
		GL_LIGHTEN:                        37528
		GL_COLORDODGE:                     37529
		GL_COLORBURN:                      37530
		GL_HARDLIGHT:                      37531
		GL_SOFTLIGHT:                      37532
		GL_DIFFERENCE:                     37534
		GL_EXCLUSION:                      37536
		GL_HSL_HUE:                        37549
		GL_HSL_SATURATION:                 37550
		GL_HSL_COLOR:                      37551
		GL_HSL_LUMINOSITY:                 37552
		GL_DEBUG_OUTPUT_SYNCHRONOUS:       33346
		GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH: 33347
		GL_DEBUG_CALLBACK_FUNCTION:        33348
		GL_DEBUG_CALLBACK_USER_PARAM:      33349
		GL_DEBUG_SOURCE_API:               33350
		GL_DEBUG_SOURCE_WINDOW_SYSTEM:     33351
		GL_DEBUG_SOURCE_SHADER_COMPILER:   33352
		GL_DEBUG_SOURCE_THIRD_PARTY:       33353
		GL_DEBUG_SOURCE_APPLICATION:       33354
		GL_DEBUG_SOURCE_OTHER:             33355
		GL_DEBUG_TYPE_ERROR:               33356
		GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR: 33357
		GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:  33358
		GL_DEBUG_TYPE_PORTABILITY:         33359
		GL_DEBUG_TYPE_PERFORMANCE:         33360
		GL_DEBUG_TYPE_OTHER:               33361
		GL_DEBUG_TYPE_MARKER:              33384
		GL_DEBUG_TYPE_PUSH_GROUP:          33385
		GL_DEBUG_TYPE_POP_GROUP:           33386
		GL_DEBUG_SEVERITY_NOTIFICATION:    33387
		GL_MAX_DEBUG_GROUP_STACK_DEPTH:    33388
		GL_DEBUG_GROUP_STACK_DEPTH:        33389
		GL_BUFFER:                         33504
		GL_SHADER:                         33505
		GL_PROGRAM:                        33506
		GL_VERTEX_ARRAY:                   32884
		GL_QUERY:                          33507
		GL_PROGRAM_PIPELINE:               33508
		GL_SAMPLER:                        33510
		GL_MAX_LABEL_LENGTH:               33512
		GL_MAX_DEBUG_MESSAGE_LENGTH:       37187
		GL_MAX_DEBUG_LOGGED_MESSAGES:      37188
		GL_DEBUG_LOGGED_MESSAGES:          37189
		GL_DEBUG_SEVERITY_HIGH:            37190
		GL_DEBUG_SEVERITY_MEDIUM:          37191
		GL_DEBUG_SEVERITY_LOW:             37192
		GL_DEBUG_OUTPUT:                   37600
		GL_CONTEXT_FLAG_DEBUG_BIT:         2

		GL_STACK_OVERFLOW:                 1283
		GL_STACK_UNDERFLOW:                1284

		GL_GEOMETRY_SHADER:                36313
		GL_GEOMETRY_SHADER_BIT:            4
		GL_GEOMETRY_VERTICES_OUT:          35094
		GL_GEOMETRY_INPUT_TYPE:            35095
		GL_GEOMETRY_OUTPUT_TYPE:           35096
		GL_GEOMETRY_SHADER_INVOCATIONS:    34943
		GL_LAYER_PROVOKING_VERTEX:         33374
		GL_LINES_ADJACENCY:                10
		GL_LINE_STRIP_ADJACENCY:           11
		GL_TRIANGLES_ADJACENCY:            12
		GL_TRIANGLE_STRIP_ADJACENCY:       13
		GL_MAX_GEOMETRY_UNIFORM_COMPONENTS: 36319
		GL_MAX_GEOMETRY_UNIFORM_BLOCKS:    35372
		GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS: 35378
		GL_MAX_GEOMETRY_INPUT_COMPONENTS:  37155
		GL_MAX_GEOMETRY_OUTPUT_COMPONENTS: 37156
		GL_MAX_GEOMETRY_OUTPUT_VERTICES:   36320
		GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS: 36321
		GL_MAX_GEOMETRY_SHADER_INVOCATIONS: 36442
		GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS: 35881
		GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS: 37583
		GL_MAX_GEOMETRY_ATOMIC_COUNTERS:   37589
		GL_MAX_GEOMETRY_IMAGE_UNIFORMS:    37069
		GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS: 37079
		GL_FIRST_VERTEX_CONVENTION:        36429
		GL_LAST_VERTEX_CONVENTION:         36430
		GL_UNDEFINED_VERTEX:               33376
		GL_PRIMITIVES_GENERATED:           35975
		GL_FRAMEBUFFER_DEFAULT_LAYERS:     37650
		GL_MAX_FRAMEBUFFER_LAYERS:         37655
		GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS: 36264
		GL_FRAMEBUFFER_ATTACHMENT_LAYERED: 36263
		GL_REFERENCED_BY_GEOMETRY_SHADER:  37641
		GL_PRIMITIVE_BOUNDING_BOX:         37566
		GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT: 4
		GL_CONTEXT_FLAGS:                  33310
		GL_LOSE_CONTEXT_ON_RESET:          33362
		GL_GUILTY_CONTEXT_RESET:           33363
		GL_INNOCENT_CONTEXT_RESET:         33364
		GL_UNKNOWN_CONTEXT_RESET:          33365
		GL_RESET_NOTIFICATION_STRATEGY:    33366
		GL_NO_RESET_NOTIFICATION:          33377
		GL_CONTEXT_LOST:                   1287
		GL_SAMPLE_SHADING:                 35894
		GL_MIN_SAMPLE_SHADING_VALUE:       35895
		GL_MIN_FRAGMENT_INTERPOLATION_OFFSET: 36443
		GL_MAX_FRAGMENT_INTERPOLATION_OFFSET: 36444
		GL_FRAGMENT_INTERPOLATION_OFFSET_BITS: 36445
		GL_PATCHES:                        14
		GL_PATCH_VERTICES:                 36466
		GL_TESS_CONTROL_OUTPUT_VERTICES:   36469
		GL_TESS_GEN_MODE:                  36470
		GL_TESS_GEN_SPACING:               36471
		GL_TESS_GEN_VERTEX_ORDER:          36472
		GL_TESS_GEN_POINT_MODE:            36473
		GL_ISOLINES:                       36474
		GL_QUADS:                          7
		GL_FRACTIONAL_ODD:                 36475
		GL_FRACTIONAL_EVEN:                36476
		GL_MAX_PATCH_VERTICES:             36477
		GL_MAX_TESS_GEN_LEVEL:             36478
		GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS: 36479
		GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS: 36480
		GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS: 36481
		GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS: 36482
		GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS: 36483
		GL_MAX_TESS_PATCH_COMPONENTS:      36484
		GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS: 36485
		GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS: 36486
		GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS: 36489
		GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS: 36490
		GL_MAX_TESS_CONTROL_INPUT_COMPONENTS: 34924
		GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS: 34925
		GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS: 36382
		GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS: 36383
		GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS: 37581
		GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS: 37582
		GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS: 37587
		GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS: 37588
		GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS: 37067
		GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS: 37068
		GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS: 37080
		GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS: 37081
		GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED: 33313
		GL_IS_PER_PATCH:                   37607
		GL_REFERENCED_BY_TESS_CONTROL_SHADER: 37639
		GL_REFERENCED_BY_TESS_EVALUATION_SHADER: 37640
		GL_TESS_CONTROL_SHADER:            36488
		GL_TESS_EVALUATION_SHADER:         36487
		GL_TESS_CONTROL_SHADER_BIT:        8
		GL_TESS_EVALUATION_SHADER_BIT:     16
		GL_TEXTURE_BORDER_COLOR:           4100
		GL_CLAMP_TO_BORDER:                33069
		GL_TEXTURE_BUFFER:                 35882
		GL_TEXTURE_BUFFER_BINDING:         35882
		GL_MAX_TEXTURE_BUFFER_SIZE:        35883
		GL_TEXTURE_BINDING_BUFFER:         35884
		GL_TEXTURE_BUFFER_DATA_STORE_BINDING: 35885
		GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT: 37279
		GL_SAMPLER_BUFFER:                 36290
		GL_INT_SAMPLER_BUFFER:             36304
		GL_UNSIGNED_INT_SAMPLER_BUFFER:    36312
		GL_IMAGE_BUFFER:                   36945
		GL_INT_IMAGE_BUFFER:               36956
		GL_UNSIGNED_INT_IMAGE_BUFFER:      36967
		GL_TEXTURE_BUFFER_OFFSET:          37277
		GL_TEXTURE_BUFFER_SIZE:            37278
		GL_COMPRESSED_RGBA_ASTC_4x4:       37808
		GL_COMPRESSED_RGBA_ASTC_5x4:       37809
		GL_COMPRESSED_RGBA_ASTC_5x5:       37810
		GL_COMPRESSED_RGBA_ASTC_6x5:       37811
		GL_COMPRESSED_RGBA_ASTC_6x6:       37812
		GL_COMPRESSED_RGBA_ASTC_8x5:       37813
		GL_COMPRESSED_RGBA_ASTC_8x6:       37814
		GL_COMPRESSED_RGBA_ASTC_8x8:       37815
		GL_COMPRESSED_RGBA_ASTC_15:      37816
		GL_COMPRESSED_RGBA_ASTC_16:      37817
		GL_COMPRESSED_RGBA_ASTC_18:      37818
		GL_COMPRESSED_RGBA_ASTC_116:     37819
		GL_COMPRESSED_RGBA_ASTC_12x10:     37820
		GL_COMPRESSED_RGBA_ASTC_12x12:     37821
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4: 37840
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4: 37841
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5: 37842
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5: 37843
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6: 37844
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5: 37845
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6: 37846
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8: 37847
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_15: 37848
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_16: 37849
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_18: 37850
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_116: 37851
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10: 37852
		GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12: 37853
		GL_TEXTURE_CUBE_MAP_ARRAY:         36873
		GL_TEXTURE_BINDING_CUBE_MAP_ARRAY: 36874
		GL_SAMPLER_CUBE_MAP_ARRAY:         36876
		GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW:  36877
		GL_INT_SAMPLER_CUBE_MAP_ARRAY:     36878
		GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY: 36879
		GL_IMAGE_CUBE_MAP_ARRAY:           36948
		GL_INT_IMAGE_CUBE_MAP_ARRAY:       36959
		GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY: 36970
		GL_TEXTURE_2D_MULTISAMPLE_ARRAY:   37122
		GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY: 37125
		GL_SAMPLER_2D_MULTISAMPLE_ARRAY:   37131
		GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY: 37132
		GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY: 37133
	;
	; GLES 3.2 PROTOTYPES
		glBlendBarrier: make routine! [ ] gles32-lib "glBlendBarrier" 
		glCopyImageSubData: make routine! [ srcName [GLuint] srcTarget [GLenum] srcLevel [GLint] srcX [GLint] srcY [GLint] srcZ [GLint] dstName [GLuint] dstTarget [GLenum] dstLevel [GLint] dstX [GLint] dstY [GLint] dstZ [GLint] srcWidth [GLsizei] srcHeight [GLsizei] srcDepth [GLsizei] ] gles32-lib "glCopyImageSubData" 
		glDebugMessageControl: make routine! [ source [GLenum] type [GLenum] severity [GLenum] count [GLsizei] ids [integer!] enabled [GLboolean] ] gles32-lib "glDebugMessageControl" 
		glDebugMessageInsert: make routine! [ source [GLenum] type [GLenum] id [GLuint] severity [GLenum] length [GLsizei] buf [integer!] ] gles32-lib "glDebugMessageInsert" 
		glDebugMessageCallback: make routine! [ callback [callback] userParam [integer!] ] gles32-lib "glDebugMessageCallback" 
		glGetDebugMessageLog: make routine! [ count [GLuint] bufSize [GLsizei] sources [integer!] types [integer!] ids [integer!] severities [integer!] lengths [integer!] messageLog [integer!] return: [GLuint] ] gles32-lib "glGetDebugMessageLog" 
		glPushDebugGroup: make routine! [ source [GLenum] id [GLuint] length [GLsizei] message [integer!] ] gles32-lib "glPushDebugGroup" 
		glPopDebugGroup: make routine! [ ] gles32-lib "glPopDebugGroup" 
		glObjectLabel: make routine! [ identifier [GLenum] name [GLuint] length [GLsizei] label [integer!] ] gles32-lib "glObjectLabel" 
		glGetObjectLabel: make routine! [ identifier [GLenum] name [GLuint] bufSize [GLsizei] length [integer!] label [integer!] ] gles32-lib "glGetObjectLabel" 
		glObjectPtrLabel: make routine! [ ptr [integer!] length [GLsizei] label [integer!] ] gles32-lib "glObjectPtrLabel" 
		glGetObjectPtrLabel: make routine! [ ptr [integer!] bufSize [GLsizei] length [integer!] label [integer!] ] gles32-lib "glGetObjectPtrLabel" 
		glGetPointerv: make routine! [ pname [GLenum] params [integer!] ] gles32-lib "glGetPointerv" 
		glEnablei: make routine! [ target [GLenum] index [GLuint] ] gles32-lib "glEnablei" 
		glDisablei: make routine! [ target [GLenum] index [GLuint] ] gles32-lib "glDisablei" 
		glBlendEquationi: make routine! [ buf [GLuint] mode [GLenum] ] gles32-lib "glBlendEquationi" 
		glBlendEquationSeparatei: make routine! [ buf [GLuint] modeRGB [GLenum] modeAlpha [GLenum] ] gles32-lib "glBlendEquationSeparatei" 
		glBlendFunci: make routine! [ buf [GLuint] src [GLenum] dst [GLenum] ] gles32-lib "glBlendFunci" 
		glBlendFuncSeparatei: make routine! [ buf [GLuint] srcRGB [GLenum] dstRGB [GLenum] srcAlpha [GLenum] dstAlpha [GLenum] ] gles32-lib "glBlendFuncSeparatei" 
		glColorMaski: make routine! [ index [GLuint] r [GLboolean] g [GLboolean] b [GLboolean] a [GLboolean] ] gles32-lib "glColorMaski" 
		glIsEnabledi: make routine! [ target [GLenum] index [GLuint] return: [GLboolean] ] gles32-lib "glIsEnabledi" 
		glDrawElementsBaseVertex: make routine! [ mode [GLenum] count [GLsizei] type [GLenum] indices [integer!] basevertex [GLint] ] gles32-lib "glDrawElementsBaseVertex" 
		glDrawRangeElementsBaseVertex: make routine! [ mode [GLenum] start [GLuint] end [GLuint] count [GLsizei] type [GLenum] indices [integer!] basevertex [GLint] ] gles32-lib "glDrawRangeElementsBaseVertex" 
		glDrawElementsInstancedBaseVertex: make routine! [ mode [GLenum] count [GLsizei] type [GLenum] indices [integer!] instancecount [GLsizei] basevertex [GLint] ] gles32-lib "glDrawElementsInstancedBaseVertex" 
		glFramebufferTexture: make routine! [ target [GLenum] attachment [GLenum] texture [GLuint] level [GLint] ] gles32-lib "glFramebufferTexture" 
		glPrimitiveBoundingBox: make routine! [ minX [float] minY [float] minZ [float] minW [float] maxX [float] maxY [float] maxZ [float] maxW [float] ] gles32-lib "glPrimitiveBoundingBox" 
		glGetGraphicsResetStatus: make routine! [ return: [GLenum] ] gles32-lib "glGetGraphicsResetStatus" 
		glReadnPixels: make routine! [ x [GLint] y [GLint] width [GLsizei] height [GLsizei] format [GLenum] type [GLenum] bufSize [GLsizei] data [integer!] ] gles32-lib "glReadnPixels" 
		glGetnUniformfv: make routine! [ program [GLuint] location [GLint] bufSize [GLsizei] params [integer!] ] gles32-lib "glGetnUniformfv" 
		glGetnUniformiv: make routine! [ program [GLuint] location [GLint] bufSize [GLsizei] params [integer!] ] gles32-lib "glGetnUniformiv" 
		glGetnUniformuiv: make routine! [ program [GLuint] location [GLint] bufSize [GLsizei] params [integer!] ] gles32-lib "glGetnUniformuiv" 
		glMinSampleShading: make routine! [ value [float] ] gles32-lib "glMinSampleShading" 
		glPatchParameteri: make routine! [ pname [GLenum] value [GLint] ] gles32-lib "glPatchParameteri" 
		glTexParameterIiv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glTexParameterIiv" 
		glTexParameterIuiv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glTexParameterIuiv" 
		glGetTexParameterIiv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetTexParameterIiv" 
		glGetTexParameterIuiv: make routine! [ target [GLenum] pname [GLenum] params [integer!] ] gles32-lib "glGetTexParameterIuiv" 
		glSamplerParameterIiv: make routine! [ sampler [GLuint] pname [GLenum] param [integer!] ] gles32-lib "glSamplerParameterIiv" 
		glSamplerParameterIuiv: make routine! [ sampler [GLuint] pname [GLenum] param [integer!] ] gles32-lib "glSamplerParameterIuiv" 
		glGetSamplerParameterIiv: make routine! [ sampler [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetSamplerParameterIiv" 
		glGetSamplerParameterIuiv: make routine! [ sampler [GLuint] pname [GLenum] params [integer!] ] gles32-lib "glGetSamplerParameterIuiv" 
		glTexBuffer: make routine! [ target [GLenum] internalformat [GLenum] buffer [GLuint] ] gles32-lib "glTexBuffer" 
		glTexBufferRange: make routine! [ target [GLenum] internalformat [GLenum] buffer [GLuint] offset [GLintptr] size [GLsizeiptr] ] gles32-lib "glTexBufferRange" 
		glTexStorage3DMultisample: make routine! [ target [GLenum] samples [GLsizei] internalformat [GLenum] width [GLsizei] height [GLsizei] depth [GLsizei] fixedsamplelocations [GLboolean] ] gles32-lib "glTexStorage3DMultisample" 
	;
	] ; if GLES_this_version
	;
	; extensions
		GL_BGR_EXT:                        32992
		GL_BGRA_EXT:                       32993
	;
{************************************************************
**  egl.h
************************************************************}

	EGLint: integer!
	EGLNativePixmapType: integer!
	EGLNativeWindowType: integer!
	EGLNativeDisplayType: integer!

	if EGL_this_version >= 1.0.0 [
		EGL_VERSION_1_0: 1

		EGLBoolean: integer! ; unsigned int 
		EGLDisplay: integer! ; void *
		EGLConfig: integer! ; void *
		EGLSurface: integer! ; void *
		EGLContext: integer! ; void *

		;typedef void (*__eglMustCastToProperFunctionPointerType)(void);

		EGL_ALPHA_SIZE:                    12321
		EGL_BAD_ACCESS:                    12290
		EGL_BAD_ALLOC:                     12291
		EGL_BAD_ATTRIBUTE:                 12292
		EGL_BAD_CONFIG:                    12293
		EGL_BAD_CONTEXT:                   12294
		EGL_BAD_CURRENT_SURFACE:           12295
		EGL_BAD_DISPLAY:                   12296
		EGL_BAD_MATCH:                     12297
		EGL_BAD_NATIVE_PIXMAP:             12298
		EGL_BAD_NATIVE_WINDOW:             12299
		EGL_BAD_PARAMETER:                 12300
		EGL_BAD_SURFACE:                   12301
		EGL_BLUE_SIZE:                     12322
		EGL_BUFFER_SIZE:                   12320
		EGL_CONFIG_CAVEAT:                 12327
		EGL_CONFIG_ID:                     12328
		EGL_CORE_NATIVE_ENGINE:            12379
		EGL_DEPTH_SIZE:                    12325
		EGL_DONT_CARE:                     -1
		EGL_DRAW:                          12377
		EGL_EXTENSIONS:                    12373
		EGL_FALSE:                         0
		EGL_GREEN_SIZE:                    12323
		EGL_HEIGHT:                        12374
		EGL_LARGEST_PBUFFER:               12376
		EGL_LEVEL:                         12329
		EGL_MAX_PBUFFER_HEIGHT:            12330
		EGL_MAX_PBUFFER_PIXELS:            12331
		EGL_MAX_PBUFFER_WIDTH:             12332
		EGL_NATIVE_RENDERABLE:             12333
		EGL_NATIVE_VISUAL_ID:              12334
		EGL_NATIVE_VISUAL_TYPE:            12335
		EGL_NONE:                          12344
		EGL_NON_CONFORMANT_CONFIG:         12369
		EGL_NOT_INITIALIZED:               12289
		EGL_NO_CONTEXT:                    0 ;EGL_CAST(EGLContext,0)
		EGL_NO_DISPLAY:                    0 ;EGL_CAST(EGLDisplay,0)
		EGL_NO_SURFACE:                    0 ;EGL_CAST(EGLSurface,0)
		EGL_PBUFFER_BIT:                   1
		EGL_PIXMAP_BIT:                    2
		EGL_READ:                          12378
		EGL_RED_SIZE:                      12324
		EGL_SAMPLES:                       12337
		EGL_SAMPLE_BUFFERS:                12338
		EGL_SLOW_CONFIG:                   12368
		EGL_STENCIL_SIZE:                  12326
		EGL_SUCCESS:                       12288
		EGL_SURFACE_TYPE:                  12339
		EGL_TRANSPARENT_BLUE_VALUE:        12341
		EGL_TRANSPARENT_GREEN_VALUE:       12342
		EGL_TRANSPARENT_RED_VALUE:         12343
		EGL_TRANSPARENT_RGB:               12370
		EGL_TRANSPARENT_TYPE:              12340
		EGL_TRUE:                          1
		EGL_VENDOR:                        12371
		EGL_VERSION:                       12372
		EGL_WIDTH:                         12375
		EGL_WINDOW_BIT:                    4

		eglChooseConfig: make routine! [ dpy [EGLDisplay] attrib_list [integer!] configs [EGLConfig] config_size [EGLint] num_config [integer!] return: [EGLBoolean] ] egl-lib "eglChooseConfig" 
		eglCopyBuffers: make routine! [ dpy [EGLDisplay] surface [EGLSurface] target [EGLNativePixmapType] return: [EGLBoolean] ] egl-lib "eglCopyBuffers" 
		eglCreateContext: make routine! [ dpy [EGLDisplay] config [EGLConfig] share_context [EGLContext] attrib_list [integer!] return: [EGLContext] ] egl-lib "eglCreateContext" 
		eglCreatePbufferSurface: make routine! [ dpy [EGLDisplay] config [EGLConfig] attrib_list [integer!] return: [EGLSurface] ] egl-lib "eglCreatePbufferSurface" 
		eglCreatePixmapSurface: make routine! [ dpy [EGLDisplay] config [EGLConfig] pixmap [EGLNativePixmapType] attrib_list [integer!] return: [EGLSurface] ] egl-lib "eglCreatePixmapSurface" 
		eglCreateWindowSurface: make routine! [ dpy [EGLDisplay] config [EGLConfig] win [EGLNativeWindowType] attrib_list [integer!] return: [EGLSurface] ] egl-lib "eglCreateWindowSurface" 
		eglDestroyContext: make routine! [ dpy [EGLDisplay] ctx [EGLContext] return: [EGLBoolean] ] egl-lib "eglDestroyContext" 
		eglDestroySurface: make routine! [ dpy [EGLDisplay] surface [EGLSurface] return: [EGLBoolean] ] egl-lib "eglDestroySurface" 
		eglGetConfigAttrib: make routine! [ dpy [EGLDisplay] config [EGLConfig] attribute [EGLint] value [integer!] return: [EGLBoolean] ] egl-lib "eglGetConfigAttrib" 
		eglGetConfigs: make routine! [ dpy [EGLDisplay] configs [integer!] config_size [EGLint] num_config [integer!] return: [EGLBoolean] ] egl-lib "eglGetConfigs" 
		eglGetCurrentDisplay: make routine! [ return: [EGLDisplay] ] egl-lib "eglGetCurrentDisplay" 
		eglGetCurrentSurface: make routine! [ readdraw [EGLint] return: [EGLSurface] ] egl-lib "eglGetCurrentSurface" 
		eglGetDisplay: make routine! [ display_id [EGLNativeDisplayType] return: [EGLDisplay] ] egl-lib "eglGetDisplay" 
		eglGetError: make routine! [ return: [EGLint] ] egl-lib "eglGetError" 
		;__eglMustCastToProperFunctionPointerType eglGetProcAddress (const char *procname);
		eglInitialize: make routine! [ dpy [EGLDisplay] major [integer!] minor [integer!] return: [EGLBoolean] ] egl-lib "eglInitialize" 
		eglMakeCurrent: make routine! [ dpy [EGLDisplay] draw [EGLSurface] read [EGLSurface] ctx [EGLContext] return: [EGLBoolean] ] egl-lib "eglMakeCurrent" 
		eglQueryContext: make routine! [ dpy [EGLDisplay] ctx [EGLContext] attribute [EGLint] value [integer!] return: [EGLBoolean] ] egl-lib "eglQueryContext" 
		eglQueryString: make routine! [ dpy [EGLDisplay] name [EGLint] return: [string!] ] egl-lib "eglQueryString" 
		eglQuerySurface: make routine! [ dpy [EGLDisplay] surface [EGLSurface] attribute [EGLint] value [integer!] return: [EGLBoolean] ] egl-lib "eglQuerySurface" 
		eglSwapBuffers: make routine! [ dpy [EGLDisplay] surface [EGLSurface] return: [EGLBoolean] ] egl-lib "eglSwapBuffers" 
		eglTerminate: make routine! [ dpy [EGLDisplay] return: [EGLBoolean] ] egl-lib "eglTerminate" 
		eglWaitGL: make routine! [ return: [EGLBoolean] ] egl-lib "eglWaitGL" 
		eglWaitNative: make routine! [ engine [EGLint] return: [EGLBoolean] ] egl-lib "eglWaitNative" 
	]
	if EGL_this_version >= 1.1.0 [
		EGL_VERSION_1_1: 1
		EGL_BACK_BUFFER:                   12420
		EGL_BIND_TO_TEXTURE_RGB:           12345
		EGL_BIND_TO_TEXTURE_RGBA:          12346
		EGL_CONTEXT_LOST:                  12302
		EGL_MIN_SWAP_INTERVAL:             12347
		EGL_MAX_SWAP_INTERVAL:             12348
		EGL_MIPMAP_TEXTURE:                12418
		EGL_MIPMAP_LEVEL:                  12419
		EGL_NO_TEXTURE:                    12380
		EGL_TEXTURE_2D:                    12383
		EGL_TEXTURE_FORMAT:                12416
		EGL_TEXTURE_RGB:                   12381
		EGL_TEXTURE_RGBA:                  12382
		EGL_TEXTURE_TARGET:                12417

		eglBindTexImage: make routine! [ dpy [EGLDisplay] surface [EGLSurface] buffer [EGLint] return: [EGLBoolean] ] egl-lib "eglBindTexImage" 
		eglReleaseTexImage: make routine! [ dpy [EGLDisplay] surface [EGLSurface] buffer [EGLint] return: [EGLBoolean] ] egl-lib "eglReleaseTexImage" 
		eglSurfaceAttrib: make routine! [ dpy [EGLDisplay] surface [EGLSurface] attribute [EGLint] value [EGLint] return: [EGLBoolean] ] egl-lib "eglSurfaceAttrib" 
		eglSwapInterval: make routine! [ dpy [EGLDisplay] interval [EGLint] return: [EGLBoolean] ] egl-lib "eglSwapInterval" 
	]
	if EGL_this_version >= 1.2.0 eglblock120: [
		EGL_VERSION_1_2: 1

		EGLenum: integer! ; unsigned int 
		EGLClientBuffer: integer! ; void *

		EGL_ALPHA_FORMAT:                  12424
		EGL_ALPHA_FORMAT_NONPRE:           12427
		EGL_ALPHA_FORMAT_PRE:              12428
		EGL_ALPHA_MASK_SIZE:               12350
		EGL_BUFFER_PRESERVED:              12436
		EGL_BUFFER_DESTROYED:              12437
		EGL_CLIENT_APIS:                   12429
		EGL_COLORSPACE:                    12423
		EGL_COLORSPACE_sRGB:               12425
		EGL_COLORSPACE_LINEAR:             12426
		EGL_COLOR_BUFFER_TYPE:             12351
		EGL_CONTEXT_CLIENT_TYPE:           12439
		EGL_DISPLAY_SCALING:               10000
		EGL_HORIZONTAL_RESOLUTION:         12432
		EGL_LUMINANCE_BUFFER:              12431
		EGL_LUMINANCE_SIZE:                12349
		EGL_OPENGL_ES_BIT:                 1
		EGL_OPENVG_BIT:                    2
		EGL_OPENGL_ES_API:                 12448
		EGL_OPENVG_API:                    12449
		EGL_OPENVG_IMAGE:                  12438
		EGL_PIXEL_ASPECT_RATIO:            12434
		EGL_RENDERABLE_TYPE:               12352
		EGL_RENDER_BUFFER:                 12422
		EGL_RGB_BUFFER:                    12430
		EGL_SINGLE_BUFFER:                 12421
		EGL_SWAP_BEHAVIOR:                 12435
		EGL_UNKNOWN:                       -1 ;EGL_CAST(EGLint,-1)
		EGL_VERTICAL_RESOLUTION:           12433

		eglBindAPI: make routine! [ api [EGLenum] return: [EGLBoolean] ] egl-lib "eglBindAPI" 
		eglQueryAPI: make routine! [ return: [EGLenum] ] egl-lib "eglQueryAPI" 
		eglCreatePbufferFromClientBuffer: make routine! [ dpy [EGLDisplay] buftype [EGLenum] buffer [EGLClientBuffer] config [EGLConfig] attrib_list [integer!] return: [EGLSurface] ] egl-lib "eglCreatePbufferFromClientBuffer" 
		eglReleaseThread: make routine! [ return: [EGLBoolean] ] egl-lib "eglReleaseThread" 
		eglWaitClient: make routine! [ return: [EGLBoolean] ] egl-lib "eglWaitClient" 
	]
	if EGL_this_version >= 1.3.0 [
		EGL_VERSION_1_3: 1
		EGL_CONFORMANT:                    12354
		EGL_CONTEXT_CLIENT_VERSION:        12440
		EGL_MATCH_NATIVE_PIXMAP:           12353
		EGL_OPENGL_ES2_BIT:                4
		EGL_VG_ALPHA_FORMAT:               12424
		EGL_VG_ALPHA_FORMAT_NONPRE:        12427
		EGL_VG_ALPHA_FORMAT_PRE:           12428
		EGL_VG_ALPHA_FORMAT_PRE_BIT:       64
		EGL_VG_COLORSPACE:                 12423
		EGL_VG_COLORSPACE_sRGB:            12425
		EGL_VG_COLORSPACE_LINEAR:          12426
		EGL_VG_COLORSPACE_LINEAR_BIT:      32
	]
	if EGL_this_version >= 1.4.0 [
		EGL_VERSION_1_4: 1
		EGL_DEFAULT_DISPLAY:               0 ;EGL_CAST(EGLNativeDisplayType,0)
		EGL_MULTISAMPLE_RESOLVE_BOX_BIT:   512
		EGL_MULTISAMPLE_RESOLVE:           12441
		EGL_MULTISAMPLE_RESOLVE_DEFAULT:   12442
		EGL_MULTISAMPLE_RESOLVE_BOX:       12443
		EGL_OPENGL_API:                    12450
		EGL_OPENGL_BIT:                    8
		EGL_SWAP_BEHAVIOR_PRESERVED_BIT:   1024

		eglGetCurrentContext: make routine! [ return: [EGLContext] ] egl-lib "eglGetCurrentContext" 
	]
	if EGL_this_version >= 1.5.0 [
		EGL_VERSION_1_5: 1

		EGLSync: integer! ; void *
		EGLAttrib: integer! ; intptr_t 
		;EGLTime: decimal! ;;typedef khronos_utime_nanoseconds_t EGLTime;
		EGLImage: integer! ; void *

		EGL_CONTEXT_MAJOR_VERSION:         12440
		EGL_CONTEXT_MINOR_VERSION:         12539
		EGL_CONTEXT_OPENGL_PROFILE_MASK:   12541
		EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY: 12733
		EGL_NO_RESET_NOTIFICATION:         12734
		EGL_LOSE_CONTEXT_ON_RESET:         12735
		EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT: 1
		EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT: 2
		EGL_CONTEXT_OPENGL_DEBUG:          12720
		EGL_CONTEXT_OPENGL_FORWARD_COMPATIBLE: 12721
		EGL_CONTEXT_OPENGL_ROBUST_ACCESS:  12722
		EGL_OPENGL_ES3_BIT:                64
		EGL_CL_EVENT_HANDLE:               12444
		EGL_SYNC_CL_EVENT:                 12542
		EGL_SYNC_CL_EVENT_COMPLETE:        12543
		EGL_SYNC_PRIOR_COMMANDS_COMPLETE:  12528
		EGL_SYNC_TYPE:                     12535
		EGL_SYNC_STATUS:                   12529
		EGL_SYNC_CONDITION:                12536
		EGL_SIGNALED:                      12530
		EGL_UNSIGNALED:                    12531
		EGL_SYNC_FLUSH_COMMANDS_BIT:       1
		;EGL_FOREVER:                       0xFFFFFFFFFFFFFFFFull
		EGL_TIMEOUT_EXPIRED:               12533
		EGL_CONDITION_SATISFIED:           12534
		EGL_NO_SYNC:                       0 ;EGL_CAST(EGLSync,0)
		EGL_SYNC_FENCE:                    12537
		EGL_GL_COLORSPACE:                 12445
		EGL_GL_COLORSPACE_SRGB:            12425
		EGL_GL_COLORSPACE_LINEAR:          12426
		EGL_GL_RENDERBUFFER:               12473
		EGL_GL_TEXTURE_2D:                 12465
		EGL_GL_TEXTURE_LEVEL:              12476
		EGL_GL_TEXTURE_3D:                 12466
		EGL_GL_TEXTURE_ZOFFSET:            12477
		EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_X: 12467
		EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_X: 12468
		EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Y: 12469
		EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Y: 12470
		EGL_GL_TEXTURE_CUBE_MAP_POSITIVE_Z: 12471
		EGL_GL_TEXTURE_CUBE_MAP_NEGATIVE_Z: 12472
		EGL_IMAGE_PRESERVED:               12498
		EGL_NO_IMAGE:                      0 ;EGL_CAST(EGLImage,0)

		eglCreateSync: make routine! [ dpy [EGLDisplay] type [EGLenum] attrib_list [integer!] return: [EGLSync] ] egl-lib "eglCreateSync" 
		eglDestroySync: make routine! [ dpy [EGLDisplay] sync [EGLSync] return: [EGLBoolean] ] egl-lib "eglDestroySync" 
		eglClientWaitSync: make routine! [ dpy [EGLDisplay] sync [EGLSync] flags [EGLint] timeout [double] return: [EGLint] ] egl-lib "eglClientWaitSync" 
		eglGetSyncAttrib: make routine! [ dpy [EGLDisplay] sync [EGLSync] attribute [EGLint] value [integer!] return: [EGLBoolean] ] egl-lib "eglGetSyncAttrib" 
		eglCreateImage: make routine! [ dpy [EGLDisplay] ctx [EGLContext] target [EGLenum] buffer [EGLClientBuffer] attrib_list [integer!] return: [EGLImage] ] egl-lib "eglCreateImage" 
		eglDestroyImage: make routine! [ dpy [EGLDisplay] image [EGLImage] return: [EGLBoolean] ] egl-lib "eglDestroyImage" 
		eglGetPlatformDisplay: make routine! [ platform [EGLenum] native_display [integer!] attrib_list [integer!] return: [EGLDisplay] ] egl-lib "eglGetPlatformDisplay" 
		eglCreatePlatformWindowSurface: make routine! [ dpy [EGLDisplay] config [EGLConfig] native_window [integer!] attrib_list [integer!] return: [EGLSurface] ] egl-lib "eglCreatePlatformWindowSurface" 
		eglCreatePlatformPixmapSurface: make routine! [ dpy [EGLDisplay] config [EGLConfig] native_pixmap [integer!] attrib_list [integer!] return: [EGLSurface] ] egl-lib "eglCreatePlatformPixmapSurface" 
		eglWaitSync: make routine! [ dpy [EGLDisplay] sync [EGLSync] flags [EGLint] return: [EGLBoolean] ] egl-lib "eglWaitSync" 
	]
{************************************************************
** GLES Rebol specific functions
************************************************************}
; errors
	system/error: make system/error [
		gles-lib: make object! [
			code: 1000
			type: "GLES Error"
			in: [:arg1 "in:" :arg2]
			simple1: [:arg1]
		]
	]
	gles-GetErrorString: func [error [integer!]][
		any [select reduce [
		0    "GL_NO_ERROR"
		1280 "GL_INVALID_ENUM"
		1281 "GL_INVALID_VALUE"
		1282 "GL_INVALID_OPERATION"
		1283 "GL_STACK_OVERFLOW"
		1284 "GL_STACK_UNDERFLOW"
		1285 "GL_OUT_OF_MEMORY"
		1286 "GL_INVALID_FRAMEBUFFER_OPERATION"

		GL_FRAMEBUFFER_UNDEFINED "target is the default framebuffer, but the default framebuffer does not exist."
		GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT "any of the framebuffer attachment points are framebuffer incomplete."
		GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT "the framebuffer does not have at least one image attached to it."
		GL_FRAMEBUFFER_UNSUPPORTED "depth and stencil attachments, if present, are not the same renderbuffer, or if the combination of internal formats of the attached images violates an implementation-dependent set of restrictions."
		GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE "the value of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers or, if the attached images are a mix of renderbuffers and textures, the value of GL_RENDERBUFFER_SAMPLES is not zero."

		] error "UNKNOWN GLES ERROR"]
	]
	gles-make_error: func [[catch] error [integer!] msg [string!] ][
		throw make error! reduce ['gles-lib 'in gles-GetErrorString error msg]
	]
	gles-throw_error: func [[catch] msg [string!] /local error][
		if GL_NO_ERROR <> error: glGetError [
			throw gles-make_error error msg
		]
	]
	gles-check_error: func [[catch] msg [string!] /local error][
		throw-on-error [gles-throw_error msg]
	]
	gles-get_error: func [[catch] msg [string!] /local error][
		print form-on-error [gles-throw_error msg]
	]
	to-gles-error: func [ msg [string! block!] ][
		if block? msg [msg: rejoin msg]
		make error! reduce ['gles-lib 'simple1 msg]
	]
; shaders, buffers, set attribute and uniform, textures
	gles-make-shader: func [[catch]
		"Constructs and returns a shader"
		type [word! string! integer!] "GL_VERTEX_SHADER or GL_FRAGMENT_SHADER"
		source [string! file! url!] "Shader source"   ; FIXME: accept also block! (of string!s), 
		; FIXME: allow continue on error
		/local
		string-type shader InfoLogLength msg
		][
		either integer? type [
			string-type: attempt [form first back find glesblock200 type]
		][
			type: get to-word string-type: form type
		]
		return try [ ; REBOL-NOTE: must use <return> to return the right value for "Near:" in error description
		if find [file! url!] type?/word source [source: read/string source] ; FIXME: common pattern ! make a function of this
		source: make struct! [_1 [string!]] reduce [ source ]
		glGetError ; flush possible current error
		shader: glCreateShader type
		gles-check_error "glCreateShader"
		glShaderSource shader 1 source 0
		gles-check_error "glShaderSource"
		glCompileShader shader
		gles-check_error "glCompileShader"
		InfoLogLength: int-ptr
		glGetShaderiv shader GL_INFO_LOG_LENGTH  & InfoLogLength
		if InfoLogLength/value > 0 [
			msg: fill copy "" " " InfoLogLength/value
			glGetShaderInfoLog shader InfoLogLength/value  & InfoLogLength msg
			glDeleteShader shader
			to-gles-error [string-type " error: " msg]
		]
		shader
		]
	]
	gles-make-program: func [[catch]
		"Constructs and returns a shaders program"
		vertex-shader [integer! string! file! url!] "value returned by gles-make-shader or glCreateShader or a string"
		fragment-shader [integer! string! file! url!] "value returned by gles-make-shader or glCreateShader or a string"
		/validate
		/local
		program Result InfoLogLength msg
		][
		return try [ ; REBOL-NOTE: must use <return> to return the right value for "Near:" in error description
		glGetError ; flush possible current error
		program: glCreateProgram
		gles-check_error "glCreateProgram"
		if not integer? vertex-shader [vertex-shader: gles-make-shader 'GL_VERTEX_SHADER vertex-shader]
		glAttachShader program vertex-shader
		gles-check_error "glAttachShader"
		if not integer? fragment-shader [fragment-shader: gles-make-shader GL_FRAGMENT_SHADER fragment-shader]
		glAttachShader program fragment-shader
		gles-check_error "glAttachShader"
		
		Result: int-ptr
		InfoLogLength: int-ptr

		glLinkProgram program 
		gles-check_error "glLinkProgram"
		; it can happen that linking fails but without log
		glGetProgramiv program GL_LINK_STATUS  & Result
		gles-check_error "GL_LINK_STATUS"
		glGetProgramiv program GL_INFO_LOG_LENGTH  & InfoLogLength
		gles-check_error "GL_INFO_LOG_LENGTH"
		if InfoLogLength/value > 0 [
			msg: fill copy "" " " InfoLogLength/value
			glGetProgramInfoLog program InfoLogLength/value  & InfoLogLength msg
			either find msg "warning" [
				print form-on-error [to-gles-error msg]
			][
				glDeleteProgram program
				to-gles-error msg
			]
		]
		if validate [
			;FIXME: can a program be correctly linked but not validated ?
			glValidateProgram program
			gles-check_error "glValidateProgram"
			glGetProgramiv program GL_VALIDATE_STATUS  & Result
			gles-check_error "GL_VALIDATE_STATUS"
			glGetProgramiv program GL_INFO_LOG_LENGTH  & InfoLogLength
			gles-check_error "GL_INFO_LOG_LENGTH" 
			if InfoLogLength/value > 0 [
				msg: fill copy "" " " InfoLogLength/value
				glGetProgramInfoLog program InfoLogLength/value  & InfoLogLength msg
				glDeleteProgram program
				to-gles-error msg
			]
		]
		; FIXME: we could glDeleteShader(s) right now
		program
		]
	]
	gles-free-program: func [[catch]
		"Detach and delete shaders and program"
		program [integer!] "Value returned by gles-make-program or glCreateProgram"
		/local
		count
		shaders
		item
		][
		return try [
		glGetError ; flush possible current error
		glUseProgram 0
		gles-check_error "glUseProgram"
		count: int-ptr
		shaders: block-to-struct [0 0 0 0 0 0]
		glGetAttachedShaders program 6 & count & shaders
		repeat n count/value [
			item: pick second shaders n
			glDetachShader program item
			gles-check_error "glDetachShader"
			glDeleteShader item
			gles-check_error "glDeleteShader"
		]
		glDeleteProgram program
		gles-check_error "glDeleteProgram"
		]
	]
	gles-make-buffer: func [
		; FIXME: allow more then one buffer or make user call this function as many times as needed ?
		"Make buffer object and upload data (returned type is struct!)"
		type [integer!] "GL_ARRAY_BUFFER or GL_ELEMENT_ARRAY_BUFFER"
		usage [integer!] "GL_STREAM_DRAW, GL_STATIC_DRAW, or GL_DYNAMIC_DRAW"
		data [block! struct!]
		/local
		bo
		][
		if block? data [
			data: either type = GL_ELEMENT_ARRAY_BUFFER [block-to-struct data][block-to-struct/floats data]
		]
		bo: make struct! [[save] value [integer!]] none ; use save to be sure ?
		glGetError ; flush possible current error
		glGenBuffers 1 & bo
		gles-check_error "glGenBuffers"
		glBindBuffer type bo/value
		gles-check_error "glBindBuffer"
		glBufferData type length? third data data usage
		gles-check_error "glBufferData"
		glBindBuffer type 0
		gles-check_error "glBindBuffer"
		bo
	]
	gles-set-vertex-attribute: func [[catch]
		"Assign a buffer to a vertex attribute"
		program [integer!] "Value returned by gles-make-program or glCreateProgram"
		varname [string!] "Symbolic name of vertex attribute"
		buffer [struct!] "struct! returned by gles-make-buffer"
		size [integer!] "Number of components for this vertex attribute. Must be 1, 2, 3, or 4."
		/skip stride [integer!] "Bytes to skip to reach next components of this attribute. Default is 0"
		/offset start [integer!] "Offset in bytes of first element of this attribute. Default is 0"
		/local
		vertexLoc
		][
		stride: any [stride 0]
		start: any [start 0]
		return try [
		; get attribute location corrisponding to <varname> variable in vertex shader
		glGetError ; flush possible current error
		vertexLoc: glGetAttribLocation program varname
		gles-check_error "glGetAttribLocation"
		;// Tell OpenGL how to pull out the positions from the position buffer into the vertexPosition attribute
		glBindBuffer GL_ARRAY_BUFFER buffer/value
		gles-check_error "glBindBuffer"
		glVertexAttribPointer vertexLoc size GL_FLOAT to-char GL_FALSE stride start ; use <to-char> because that is the parameter type expected by glVertexAttribPointer
		gles-check_error "glVertexAttribPointer"
		glEnableVertexAttribArray vertexLoc
		gles-check_error "glEnableVertexAttribArray"
		glBindBuffer GL_ARRAY_BUFFER 0
		vertexLoc
		]
	]
	gles-set-uniform: func [[catch]
		"Assign one or more values to a uniform "
		program [integer!] "Value returned by gles-make-program or glCreateProgram"
		varname [string!] "Symbolic name of uniform"
		value [number! pair! tuple! block!] "A number, a block of 1,2,3 or 4 numbers, or a block with a block of numbers"
		/skip size [integer!] "row length if value inside value is a block"
		/local
		uniformLoc
		glUniform
		arity
		type
		postfix
		][
		size: any [size 1]
		arity: case [
			number? value [1]
			pair? value [2]
			tuple? value [
				case [
					attempt [value/5] [ value: reduce [to-block replace/all form value "." " "] ]
					attempt [value/4] [ value: reduce [value/1 / 255 value/2 / 255 value/3 / 255 value/4 / 255] ]
					'else [value: reduce [value/1 / 255 value/2 / 255 value/3 / 255] ]
				]
				length? value
			]
			block? attempt [value/1][size]
			block? value [
				either (length? value) <= 4 [
					max 1 length? value
				][
					value: reduce [value]
					size
				]
			]
			;'else [to-error "Unreconized type inside block"]
		]
		type: select [integer! "i" decimal! "f"] type?/word any [attempt [value/1/1] attempt [value/1] value] ; FIXME: better always use "f" to avoid rounding errors? 
		if none? type [throw to-gles-error "Unreconized type inside block"] 
		if pair? value [type: "f"]
		postfix: rejoin [
			arity
			type
			any [attempt [value/1/1 size: arity arity: 0.5 "v"] ""]
		]
		glUniform: get to word! append copy "glUniform" postfix 
		;intentionally avoid checking errors
		;glGetError ; flush possible current error
		uniformLoc: glGetUniformLocation program varname
		;if uniformLoc = -1 [return try [to-gles-error ["Not an active uniform: " varname]]]

		switch arity [
			1 [glUniform uniformLoc value]
			2 [glUniform uniformLoc value/1 value/2]
			3 [glUniform uniformLoc value/1 value/2 value/3]
			4 [glUniform uniformLoc value/1 value/2 value/3 value/4]
			0.5 [
				glUniform uniformLoc to integer! (length? value/1) / size
				& do either type = "i" ['block-to-struct]['block-to-struct/no-ints/floats]
				value/1 
			]
		]
		; FIXME: better check errors? : gles-check_error "glUniform"
		
	]

	gles-make-texture: func [[catch]
		"Makes a texture from given image"
		image [pair! image! file! url!] "size for a new black image or an image"
		/with params [block!] "texture parameters"
		/no-mipmap "Do not generate mipmaps"
		/no-alpha "Do not consider alpha channel"
		/local
		texture
		alpha
		][
		return try [
		params: reduce either block? params [
			params
		][
			[
				GL_TEXTURE_WRAP_S GL_REPEAT
				GL_TEXTURE_WRAP_T GL_REPEAT
				GL_TEXTURE_MIN_FILTER either no-mipmap [GL_LINEAR][GL_LINEAR_MIPMAP_LINEAR]
				GL_TEXTURE_MAG_FILTER GL_LINEAR
			]
		]
		glGetIntegerv GL_ALPHA_BITS & alpha: int-ptr
		alpha: either alpha/value = 0 [GL_RGB][GL_RGBA]
		if no-alpha [alpha: GL_RGB]
		if pair? image [
			if any [image/x = 0 image/y = 0] [to-gles-error "Image size cannot be 0 in gles-make-texture"]
			image: make image! either alpha = GL_RGBA [reduce [image 0.0.0 255]][image]
		]
		if find [file! url!] type?/word image [
			image: load image
			if not image? image [to-gles-error "Unrecognized image format"]
			;image/alpha: complement image/alpha ; FIXME is this necessary ?
		]
		glGenTextures 1 & texture: int-ptr
		glBindTexture GL_TEXTURE_2D texture/value
		;// set the texture wrapping/filtering options on the currently bound texture object
		foreach [param value] params [
			glTexParameteri GL_TEXTURE_2D param value
		]
		glGetError ; flush possible current error
		;// load and generate the texture
		glTexImage2D GL_TEXTURE_2D 0 alpha image/size/x image/size/y 0 alpha GL_UNSIGNED_BYTE & to binary! image
		gles-check_error "glTexImage2D"
		unless no-mipmap [glGenerateMipmap GL_TEXTURE_2D]
		glBindTexture GL_TEXTURE_2D 0
		texture/value
		]
	]
; swap-buffers
	gles-swap-buffers-ctx: context [ ; FIXME: better use an anonymous context ?
		; allocate memory to store gl "hidden" color buffer
		; allocate it once and as large as the entire screen
		back-buffer: fill copy #{} #{00000000} (System/view/screen-face/size/x * System/view/screen-face/size/y)

	set 'gles-swap-buffers func [
		"Copies color buffer to a face's image!"
		face [object!] "Destination face that must have an image!"
		/local size buffer
		][
		size: face/image/size ; if face has no image will give error!
		buffer: back-buffer

		; copy 3d image (size of widget) to a binary and then assign that binary to rgb of our image widget
		glReadPixels 0 0 size/x size/y GL_BGRA_EXT GL_UNSIGNED_BYTE buffer

		buffer: to image! buffer
		buffer/size: as-pair size/x size/y
		buffer/alpha: complement buffer/alpha       ; this is quite slow :(

		face/image: buffer
		face/effect: [flip 0x1] ; <<<<<==== IMPORTANT! MUST flip image upside down     ; FIXME: better append it if not alread there ?
		
		;draw face/image compose [image (buffer) (size * 0x1) (size) (size * 1x0) 0x0] ; slower

		; FIXME: is there a way to invert alpha and flip image with GL "transparently" ?

		show face
	]
	]
;	
{************************************************************
** EGL Rebol specific functions
************************************************************}
; EGL errors
	to-error: func [[catch] ; gives a better error message
		value
		][
		throw 
		to error! :value
	]
	system/error: make system/error [
		egl-lib: make object! [
			code: 1000
			type: "EGL Error"
			in: [:arg1 "in:" :arg2]
			frame-buffer: ["No possible EGL frame buffer configuration exists."]
		]
	]
	egl-GetErrorString: func [error [integer!]][
		switch/default error reduce [
			EGL_SUCCESS [ "Success" ]
			EGL_NOT_INITIALIZED [ "EGL is not or could not be initialized" ]
			EGL_BAD_ACCESS [ "EGL cannot access a requested resource" ]
			EGL_BAD_ALLOC [ "EGL failed to allocate resources for the requested operation" ]
			EGL_BAD_ATTRIBUTE [ "An unrecognized attribute or attribute value was passed in the attribute list" ]
			EGL_BAD_CONTEXT [ "An EGLContext argument does not name a valid EGL rendering context" ]
			EGL_BAD_CONFIG [ "An EGLConfig argument does not name a valid EGL frame buffer configuration" ]
			EGL_BAD_CURRENT_SURFACE [ "The current surface of the calling thread is a window pixel buffer or pixmap that is no longer valid" ]
			EGL_BAD_DISPLAY [ "An EGLDisplay argument does not name a valid EGL display connection" ]
			EGL_BAD_SURFACE [ "An EGLSurface argument does not name a valid surface configured for GL rendering" ]
			EGL_BAD_MATCH [ "Arguments are inconsistent" ]
			EGL_BAD_PARAMETER [ "One or more argument values are invalid" ]
			EGL_BAD_NATIVE_PIXMAP [ "A NativePixmapType argument does not refer to a valid native pixmap" ]
			EGL_BAD_NATIVE_WINDOW [ "A NativeWindowType argument does not refer to a valid native window" ]
			EGL_CONTEXT_LOST [ "The application must destroy all contexts and reinitialise" ]
		]
		[ "UNKNOWN EGL ERROR"]
	]
	egl-make_error: func [[catch] error [integer!] msg [string!] ][
		throw make error! reduce ['egl-lib 'in egl-GetErrorString error msg]
	]
	egl-check_error: func [[catch] msg [string!] /local error][
		if EGL_SUCCESS <> error: eglGetError [
			throw-on-error [egl-make_error error msg]
		]
	]

; start/end
	get-win-handle: func [face [object!] /local user32 hWND][
		face: find-window face
		user32: load/library %user32.dll

		FindWindow-by-class: make routine! [class [string!]  name [integer!] return: [integer!]] user32 "FindWindowA"
		FindWindow-by-title: make routine! [class [integer!] name [string!]  return: [integer!]] user32 "FindWindowA"
		;SetFocus: make routine! [hwnd [int] return: [int]] user32 "SetFocus"

		hWND: FindWindow-by-title 0 head insert copy face/text "REBOL - "
		if hWND = 0 [hWND: FindWindow-by-class "REBOLWind" 0]
		free user32
		hWND
	]
	; some comments taken from eglIntro.html
	egl-Start: funct [ ; auto-locals
		[catch]
		"Creates and assigns an OpenGL context to given window"
		face [object!] "Window to assign the new context to"
		fb_list [block!] "Block with keys=names and values of desired frame buffer"
		ctx_list [block!] "Block with keys=names and values of desired context attributes"
		/verbose "Print some information"
		][
		if not find ctx_list: reduce ctx_list EGL_CONTEXT_CLIENT_VERSION [
			; try an high version
			attempt [insert find ctx_list EGL_NONE [EGL_CONTEXT_CLIENT_VERSION 2]]
		]
		fb_list: block-to-struct fb_list
		ctx_list: block-to-struct ctx_list

		NULL: 0

		;{ get an EGL display connection }
		display: eglGetDisplay EGL_DEFAULT_DISPLAY
		egl-check_error "eglGetDisplay"

		;{ initialize the EGL display connection }
		major: int-ptr
		minor: int-ptr
		eglInitialize display & major & minor
		egl-check_error "eglInitialize"
		if verbose [print rejoin ["EGL version: " major/value "." minor/value]]

		; optional ?
		;eglBindAPI EGL_OPENGL_ES_API
		;egl-check_error "eglBindAPI"

		; return total number of possible configs
		num_config: int-ptr
		eglGetConfigs display NULL 0 & num_config
		egl-check_error "eglGetConfigs"
		if verbose [print ["total number of possible EGL frame buffer configs:" num_config/value]]
		if num_config/value = 0 [throw make error! reduce ['egl-lib 'frame-buffer] ]

		;{ get an appropriate EGL frame buffer configuration }

		; return total number of configs that match given attributes
		eglChooseConfig display & fb_list NULL 0 & num_config
		egl-check_error "eglChooseConfig GET"
		if verbose [print ["total number of configs that match given attributes:" num_config/value]]
		; fall down to a possible config
		if num_config/value = 0 [
			fb_list: block-to-struct [EGL_NONE]
			eglChooseConfig display & fb_list NULL 0 & num_config
			egl-check_error "eglChooseConfig GET"
		]

		; alloc mem for the possible configs
		configs: block-to-struct fill clear [] 0 num_config/value
		
		; fill configs array of matching configs
		eglChooseConfig display & fb_list & configs num_config/value & num_config
		egl-check_error "eglChooseConfig UPD"

		;{ create an EGL rendering context }
		; try to find a valid config. Seems that last ones are better ? so reverse the list ? ; FIXME: should try to find the best match
		config: 0
		last-error: 0
		foreach elem second configs [
			eglctx: eglCreateContext display elem EGL_NO_CONTEXT & ctx_list
			either EGL_SUCCESS = error: eglGetError [
				config: elem
				break
			][
				;eglDestroyContext display eglctx ; since context was not created avoid this ?
				last-error: error
			]
		]
		if last-error > 0 [egl-make_error error "eglCreateContext" ]

		if verbose [
		; some information for the curious
		result: int-ptr
		eglQueryContext display eglctx EGL_CONFIG_ID & result print ["EGL_CONFIG_ID" result/value]
		egl-check_error "eglQueryContext"
		eglQueryContext display eglctx EGL_CONTEXT_CLIENT_TYPE & result print ["EGL_CONTEXT_CLIENT_TYPE" attempt [form first back find eglblock120 result/value]]
		eglQueryContext display eglctx EGL_CONTEXT_CLIENT_VERSION & result print ["EGL_CONTEXT_CLIENT_VERSION" result/value]
		]
		
		;{ create an EGL window surface }
		surface: eglCreateWindowSurface display config get-win-handle face NULL
		egl-check_error "eglCreateWindowSurface"

		;{ connect the context to the surface }
		eglMakeCurrent display surface surface eglctx
		egl-check_error "eglMakeCurrent"
		
		if verbose [
			prin "GL_VERSION: " print glGetString GL_VERSION
			prin "GL_VENDOR: " print glGetString GL_VENDOR
			prin "GL_RENDERER: " print glGetString GL_RENDERER
			prin "GL_SHADING_LANGUAGE_VERSION: " print glGetString GL_SHADING_LANGUAGE_VERSION
			print "GL_EXTENSIONS:" print replace/all glGetString GL_EXTENSIONS " " "^/"
		]

		eglSwapInterval display 1
		
		reduce [display surface eglctx]
	]
	egl-End: func [
		"Free EGL resources"
		display [integer!] "void *EGLDisplay"
		surface [integer!] "void *EGLSurface"
		eglctx [integer!] "void *EGLContext"
		][
		eglMakeCurrent display EGL_NO_SURFACE EGL_NO_SURFACE EGL_NO_CONTEXT
		eglDestroyContext display eglctx
		eglDestroySurface display surface
		eglTerminate display
	]
;
{************************************************************
** example
************************************************************}
do ; just comment this line to avoid executing example
[
if system/script/title = "GLES and EGL library interface" [;do examples only if script started by us

	glslsandbox.com_e59828.0: {//http://glslsandbox.com/e#59828.0
		//translate variable names
		#define time u_Time
		#define resolution u_Resolution

		#ifdef GL_ES
		precision mediump float;
		#endif

		uniform float time;
		uniform vec2 resolution;

		#define t time

		vec2 pos_for_aspect_min(vec2 fragCoord , vec2 resolution) {
			return ( fragCoord * 2.0 - resolution ) / min(resolution.x,resolution.y);
		}

		void main() {
			vec2 p = pos_for_aspect_min( gl_FragCoord.xy , resolution);

			float c = 0.0;
			for(float l = 0.0;l < 10.0;l++){
				for (float i = 0.0;i < 10.0;i++){
					float j = i - 1.0; 
					float si = sin(t + i * 0.628318) / 2.0 - sin(t/4.-l);
					float co = cos(t - i * 0.628318) / 8.0 + tan(t/8.-l);
					c += 0.003 / abs(length(p - vec2(si,co)/(1.25/abs(cos(t/4.0)))) - 0.1 );
				}
			}
			gl_FragColor = vec4(vec3(abs(c*atan(t))- 0.5,c*cos(t),abs(c*sin(t))), 1.0 );
		}
	}
	woah-circle: {//http://glslsandbox.com/e#58416.0 woah circle
		#ifdef GL_ES
		precision highp float;
		#endif

		uniform float u_Time;
		uniform vec2 u_Resolution;
		
		uniform float u_speed;
		uniform float u_radius;

		void main() {

			float t = u_Time * u_speed;
			vec2 r = u_Resolution,
			     o = gl_FragCoord.xy - r/2.;
			o = vec2(length(o) / r.y - u_radius, atan(o.y,o.x));    
			vec4 s = 0.08*cos(1.5*vec4(0,1,2,3) + t + o.y + sin(o.y) * cos(t)),
			     e = s.yzwx, 
			     f = max(o.x-s,e-o.x);

			gl_FragColor = dot(clamp(f*r.y,0.,1.), 72.*(s-e)) * (s-.1) + f;
			gl_FragColor.a = 1.0;
		}
	}
	hello_triangle+: funct [frag-shader /fullwindow][
		
		vs: {
			//#version 300 es // for Chrome it is unsupported even in context version 2 :(
			precision highp float;
			attribute vec3 va_Position;
			//varying vec4 vertexColor;
			void main() {
			  //vertexColor = vec4(0.0,1.0,0.0,1.0);
			  // alter points position to check that they are passed to shader
			  gl_Position = vec4(va_Position.x, va_Position.y / 1.50, 0,1.0);
			}
		}

		fs: frag-shader

		; simple unused fragment shader to be used for test purposes
		{
			//#version 300 es
			precision mediump float;
			//varying vec4 vertexColor;
			void main() {
			  // use a color different from background and from white (that is OpenGL default color) to check that shader works
			  gl_FragColor = vec4(0.0,1.0,0.0,1.0); 
			}
		}
		
		shaders_program: gles-make-program vs fs
		
		points: [
			-1.0 -1.0 0.0
			 1.0 -1.0 0.0
			 0.0  1.0 0.0
		]
		; make vertex buffer object and upload data (returned type is struct!)
		vbo: gles-make-buffer GL_ARRAY_BUFFER GL_STATIC_DRAW points

		va_PositionLoc: gles-set-vertex-attribute shaders_program "va_Position" vbo 3        ; 3 elements (x, y, z) per vertex

		indices: [
			0 1 2
		]
		indices: block-to-struct indices

		u_TimeLoc: glGetUniformLocation shaders_program "u_Time"
		u_ResolutionLoc: glGetUniformLocation shaders_program "u_Resolution"
		
		u_speedLoc: glGetUniformLocation shaders_program "u_speed"
		u_radiusLoc: glGetUniformLocation shaders_program "u_radius"

		t0: now/time/precise
		; repeatedly draw
		while [running] [
			; assign changing variables values
			glUniform1f u_TimeLoc to decimal! now/time/precise - t0
			glUniform2f u_ResolutionLoc 640 480
			
			glUniform1f u_speedLoc any [attempt [5.0 * get-face sld-speed] 0.0]
			glUniform1f u_radiusLoc any [attempt [get-face sld-radius] 0.0]

			;{ clear the color buffer }
			glClearColor 1.00 0.0 0.0 1.0
			glClear GL_COLOR_BUFFER_BIT
			
			glUseProgram shaders_program
			
			; draw triangle made of 3 points (indices) from the given indices array with current in-use shader
			glDrawElements GL_TRIANGLES 3 GL_UNSIGNED_INT & indices

			either fullwindow [
				eglSwapBuffers display surface
			][
				gles-swap-buffers box-3D
			]
			
			wait 0.02 ; allow GUI msgs to be processed 
		]
		; we're done with this vertex attribute
		glDisableVertexAttribArray va_PositionLoc
		
		glDeleteBuffers 1 vbo ; use the struct! !

		gles-free-program shaders_program
	]

	framebuffer-attribs: [
		EGL_SURFACE_TYPE		EGL_WINDOW_BIT
		;EGL_RENDERABLE_TYPE	EGL_OPENGL_ES2_BIT
		EGL_RED_SIZE 8
		EGL_GREEN_SIZE 8
		EGL_BLUE_SIZE 8
		EGL_ALPHA_SIZE 8
		EGL_DEPTH_SIZE 16
		EGL_STENCIL_SIZE 8
		;EGL_SAMPLES 4 ; multi-sampled 4x antialiasing
		EGL_NONE
	]
	context-attribs: [
		;EGL_CONTEXT_CLIENT_VERSION 1 ; if we are using Chrome this is WebGL version ! and corrisonds to #version 100
		EGL_CONTEXT_CLIENT_VERSION 2 ; if we are using Chrome this is WebGL version ! and corrisonds to #version 300 es
		; these are not possible with Chrome libGLES !
		;EGL_CONTEXT_OPENGL_PROFILE_MASK EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT
		;EGL_CONTEXT_OPENGL_PROFILE_MASK EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT
		;EGL_CONTEXT_MAJOR_VERSION 3
		;EGL_CONTEXT_MINOR_VERSION 3
		EGL_NONE EGL_NONE
	]

	;=== 1st window ===

		;{ create a native window }
		; make a window without faces to minimize flickering during refresh. if you have a dark background use [origin 0 space 0 box 640x480 black] instead
		win-face: view/new layout [size 640x480]
		insert-event-func func [face event ] [
			if event/type = 'close [running: false]
			event
		]

		running: true

		; if you're curious use /verbose
		set [display surface eglctx] egl-Start win-face framebuffer-attribs context-attribs 
		
		glViewport 0 0 640 480 ; optional if viewport is entire window.

		hello_triangle+/fullwindow glslsandbox.com_e59828.0
		
		egl-End display surface eglctx

	;=== 2nd window ===

		;{ create a native window }
		win-face: view/new layout [
			h3 "Use sliders to control speed and radius"
			across
			sld-speed: slider .2
			sld-radius: slider .3
			box-3D: image (make image! 640x480) feel none
		]

		running: true

		set [display surface eglctx] egl-Start win-face framebuffer-attribs context-attribs 
		
		glViewport 0 0 box-3D/size/x box-3D/size/y

		hello_triangle+ woah-circle
		
		egl-End display surface eglctx
	;
	free egl-lib ; optional
	free gles32-lib ; optional

	;halt

] ; if title
] ; do
