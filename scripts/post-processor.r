Rebol [
	Title:	"Add post-effects with shaders"
	Purpose: "Example use of %gles-egl-h.r"
	file: %post-processor.r
	author: "Marco Antoniazzi"
	email: [luce80 AT libero DOT it]
	date: 02-05-2020
	version: 0.4.0
	needs: [
		 %gles-egl-h.r
	]
	History: [
		0.0.1 [05-04-2020 "Started"]
		0.4.0 [02-05-2020 "Completed main aspects"]
	]
	Category: [graphics]
	library: [
		level: 'intermediate
		platform: 'win
		type: 'how-to
		domain: [graphics]
		tested-under: [View 2.7.8.3.1]
		support: none
		license: none
	]
	Notes: {
		Inspired by: https://learnopengl.com/In-Practice/2D-Game/Postprocessing
	}
]

	; misc functions
		undirize: func ["Returns a copy of the path turned into a file."
			path [file! string! url!]
			][
			path: copy path
			while [find "/\" pick path: back tail path 1] [remove path]
			head path
		]
		download: func [
			url [url!]
			/local lo bar cbk-fn data
			][
			view/new lo: center-face layout [
				lbl "Downloading"
				text (form url)
				bar: progress
			]
			cbk-fn: func [total bytes][
				set-face bar bytes / total
			]
			data: read-net/progress url :cbk-fn
			unview/only lo
			data
		]
		load-script-thru: func ["Load a script from www.rebol.org thru the cache"
			name [file! url!]
			/flash "Flash a message to the user"
			/warn "Alert user if script not found"
			/from path [file! url!] "Optional path where to search for the script"
			/local cache-name modul
			][
			if not value? 'view-root [view-root: either system/version/4 = 3 [%/C/Users/Public/Documents] [%/tmp]]
			cache-name: view-root/:name
			modul: any [
				attempt [read cache-name] ; try the cache
				attempt [read name] ; try current dir
				attempt [read rejoin [undirize path "/" name]] ; try optional dir 
				attempt [ ; try downloading it from www.rebol.org
					if not request [rejoin [form name " not found, download it from www.rebol.org or quit?"] "Download" "Quit"][quit]
					modul: rejoin [http://www.rebol.org/download-a-script.r?script-name= name]
					modul: as-string either flash [download modul][read modul]
					if not find modul "REBOL [" [make error! "Script not found"]
					write cache-name modul
					modul
				]
			]
			if all [not modul warn] [alert rejoin ["Script <" name "> not found."]]
			modul
		]

if error? try [do load load-script-thru/flash/warn %gles-egl-h.r] [quit] ; use "do load" to avoid executing script example

PostProcessor: context [
	vbo: none
	Texture.ID: none
	indices: none
	inited: false
	convolution: none
	
	v_shader: {
		precision mediump float;
		//#version 300 es
		attribute vec4 vertex; // <vec2 position, vec2 texCoords>

		varying vec2 TexCoords;

		void main() {
			TexCoords = vertex.zw;
			gl_Position = vec4(vertex.xy, 0.0, 1.0); 
		}  
	}
	; FIXME: I could use only one shader and build its string dynamically
	shaders-effects: compose [
	"no-operation" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			gl_FragColor = vec4(texture2D(scene,TexCoords).rgb, 1.0);
		}
	}
	"flip-x" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			gl_FragColor = vec4(texture2D(scene,vec2(1.0 - TexCoords.x, TexCoords.y)).rgb, 1.0);
		}
	}
	"flip-y" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			gl_FragColor = vec4(texture2D(scene,vec2(TexCoords.x, 1.0 - TexCoords.y)).rgb, 1.0);
		}
	}
	"inverse" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			gl_FragColor = vec4(1.0 - texture2D(scene,TexCoords).rgb, 1.0);
		}
	}
	"grayscale" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			vec3 color = texture2D(scene,TexCoords).rgb;
			color = vec3(color.r * .30 + color.g * .59 + color.b * .11) ;
			gl_FragColor = vec4(color, 1.0);
		}
	}
	"Red*2" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			vec3 color = texture2D(scene,TexCoords).rgb;
			color.r *= 2.0;
			gl_FragColor = vec4(color, 1.0);
		}
	}
	"Red+0.1" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			vec3 color = texture2D(scene,TexCoords).rgb;
			color.r += 0.10;
			gl_FragColor = vec4(color, 1.0);
		}
	}
	"Red/2" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			vec3 color = texture2D(scene,TexCoords).rgb;
			color.r /= 2.0;
			gl_FragColor = vec4(color, 1.0);
		}
	}
	"Red-0.1" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			vec3 color = texture2D(scene,TexCoords).rgb;
			color.r -= 0.10;
			gl_FragColor = vec4(color, 1.0);
		}
	}
	"Brighter" id {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		void main() {
			vec3 color = texture2D(scene,TexCoords).rgb;
			color = mix(color,vec3(1.6),.1); //mix with (over) white
			gl_FragColor = vec4(color, 1.0);
		}
	}
	"Outline" id (convolution: {precision mediump float; varying vec2 TexCoords; uniform sampler2D scene;
		uniform vec2 u_Resolution;
		uniform float kernel[9]; // 3x3 kernel
		vec2 toffs(float i, vec2 res) {
			vec2 count;
			count.x = mod(i , 3.0) - 1.0; // -1,0,1,-1,0,1,-1,0,1,
			count.y = floor(i / 3.0) - 1.0; // -1,-1,-1,0,0,0,1,1,1
			return (1.0 / res) * count;
		}
		void main() {
			vec3 color = vec3(0.0);
			vec3 samp;
			// sample from texture offsets if using convolution matrix
			for(int i = 0; i < 9; i++) {
				samp = vec3(texture2D(scene, TexCoords + toffs(float(i),u_Resolution)));
				color += samp * kernel[i];
			}
			gl_FragColor = vec4(color, 1.0);
		}
	})
	"Emboss" id (convolution)
	"SmallBlur" id (convolution)
	]

	current-shaders: copy []

	Init: func [[catch]
		size
		/local
			prog
			shader
		][
		
		glGetIntegerv GL_CURRENT_PROGRAM & prog: int-ptr

		;// Initialize render texture
		Texture.ID: gles-make-texture/no-mipmap size 

		; build all programs
		forskip shaders-effects 3 [
			shaders-effects/2: shader: gles-make-program v_shader shaders-effects/3

			;// Tell the shader we bound the texture to texture unit 0
			;gles-set-uniform shader "scene" 0 ; optional in this case because there is only one texture
		]
		;// Initialize common render data
		initRenderData
		
		;edges 
		kernel:
		[
		-1.0 -1 -1 ; 1st number is decimal! so that gles-set-uniform will use ALL floats
		-1    8 -1
		-1   -1 -1
		]
		glUseProgram shader: select shaders-effects "Outline"
		gles-set-uniform shader "kernel" kernel
		;emboss
		kernel:
		[
		-2.0 -1 0
		-1    1 1
		 0    1 2
		]
		glUseProgram shader: select shaders-effects "Emboss"
		gles-set-uniform shader "kernel" kernel
		;gaussian blur
		kernel: reduce
		[
		1.0 / 16 2.0 / 16 1.0 / 16
		2.0 / 16 4.0 / 16 2.0 / 16
		1.0 / 16 2.0 / 16 1.0 / 16
		]
		glUseProgram shader: select shaders-effects "SmallBlur"
		gles-set-uniform shader "kernel" kernel

		glUseProgram prog/value
		inited: true
	]
	initRenderData: func [/local vertices]
		[
		;// Configure VBO
		vertices: [
		;// Pos    ;// Tex
		-1.0 -1.0  0.0 0.0
		 1.0  1.0  1.0 1.0
		-1.0  1.0  0.0 1.0

		-1.0 -1.0  0.0 0.0
		 1.0 -1.0  1.0 0.0
		 1.0  1.0  1.0 1.0
		]
		; make vertex buffer object and upload data (returned type is struct!)
		vbo: gles-make-buffer GL_ARRAY_BUFFER GL_STATIC_DRAW vertices

		indices: [
			0 1 2
			3 4 5
		]
		indices: block-to-struct indices

	]

	set 'PostProcessor.Render func [
		size
		/local prog PostProcessingShader
		][
		if not inited [
			Init size
		]
		glGetIntegerv GL_CURRENT_PROGRAM & prog: int-ptr
		glActiveTexture GL_TEXTURE0
		glBindTexture GL_TEXTURE_2D Texture.ID
		
		forall current-shaders [
			glGetError
			; copy from framebuffer lower-left corner to temp-texture unit 0
			glCopyTexSubImage2D
				GL_TEXTURE_2D 0
				0 0
				0 0 size/x size/y
				0
			gles-check_error "glCopyTexSubImage2D"
			
			glUseProgram PostProcessingShader: current-shaders/1
			
			gles-set-vertex-attribute PostProcessingShader "vertex" vbo 4     ; 2 + 2 = 4 FLOATs

			;// Set uniforms/options
			gles-set-uniform PostProcessingShader "u_Resolution" size

			;// Render textured quad
			glDrawElements GL_TRIANGLES length? second indices GL_UNSIGNED_INT & indices
		]
		; restore old shader
		glUseProgram prog/value
	]

]
; main
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
	hello_triangle+: funct [frag-shader][
		
		vs: {
			//#version 300 es // for Chrome it is unsupported even in context version 2 :(
			precision highp float;
			attribute vec3 va_Position;
			attribute vec3 va_Color;
			varying vec4 vertexColor;
			void main() {
			  //vertexColor = vec4(0.0,1.0,0.0,1.0);
			  vertexColor = vec4(va_Color,1.0);
			  // alter points position to check that they are passed to shader
			  gl_Position = vec4(va_Position.x, va_Position.y / 1.50, 0,1.0);
			}
		}

		fs: frag-shader

		shaders_program: gles-make-program vs fs
		
		points: [
			; pos		; color (only for test purposes, unused in woah-circle shader)
			-1.0 -1.0	1.0 1.0 0.0
			 1.0 -1.0	0.5 0.0 0.5
			 0.0  1.0	1.0 1.0 1.0
		]
		; make vertex buffer object and upload data (returned type is struct!)
		vbo: gles-make-buffer GL_ARRAY_BUFFER GL_STATIC_DRAW points

		indices: [
			0 1 2
		]
		indices: block-to-struct indices

		; define current program
		glUseProgram shaders_program

		u_TimeLoc: glGetUniformLocation shaders_program "u_Time"
		u_ResolutionLoc: glGetUniformLocation shaders_program "u_Resolution"
		
		u_speedLoc: glGetUniformLocation shaders_program "u_speed"
		u_radiusLoc: glGetUniformLocation shaders_program "u_radius"

		t0: now/time/precise
		; repeatedly draw
		while [running] [

			va_PositionLoc: gles-set-vertex-attribute/skip shaders_program "va_Position" vbo 2 2 + 3 * 4      ; 2 + 3 FLOATs
			va_ColorLoc: gles-set-vertex-attribute/skip/offset shaders_program "va_Color" vbo 3 2 + 3 * 4 2 * 4  ; 2 + 3 FLOATs , first color after 2 * FLOAT bytes

			; assign changing variables values
			glUniform1f u_TimeLoc to decimal! now/time/precise - t0
			glUniform2f u_ResolutionLoc box-3D/size/x box-3D/size/y
			
			glUniform1f u_speedLoc any [attempt [5 * get-face sld-speed] 0.0]
			glUniform1f u_radiusLoc any [attempt [get-face sld-radius] 0.0]

			;{ clear the color buffer }
			glClearColor 0.80 0.10 0.20 1.00
			glClear GL_COLOR_BUFFER_BIT
			
			; draw triangle made of 3 points (indices) from the given indices array with current in-use shader
			glDrawElements GL_TRIANGLES 3 GL_UNSIGNED_INT & indices

			; apply effects. Will change current program but also restore it
			PostProcessor.Render box-3D/size

			; copy from framebuffer to our face
			gles-swap-buffers box-3D
			
			wait 0.02 ; allow GUI msgs to be processed 
		]
		
		glDeleteBuffers 1 vbo ; use the struct! !

		gles-free-program shaders_program
	]
	update-shaders-list: func [
		/local effects
		][
		effects: parse list-current/data none
		remove-each item effects [not find Postprocessor/shaders-effects item]
		clear head Postprocessor/current-shaders
		foreach item effects [append Postprocessor/current-shaders Postprocessor/shaders-effects/(item)]
	]

	;{ create a native window }
	win-face: view/new layout [
		across
		h3 "Use sliders to control speed and radius"
		sld-speed: slider 100x20 .2
		sld-radius: slider 100x20 .3
		return 
		here: at 
		origin here 
		Below 
		text "Choose effect" 
		list-choose: text-list 150x200 data extract Postprocessor/shaders-effects 3 [
			append list-current/data join face/picked newline
			show list-current
			update-shaders-list
		]
		text "Current effect(s)" 
		list-current: field 150x200 [update-shaders-list]
		return 
		box-3D: image (make image! 640x480) feel none
	]
	insert-event-func func [face event ] [
		if event/type = 'close [running: false]
		event
	]

	running: true

	set [display surface eglctx] egl-Start win-face [EGL_NONE] [EGL_NONE] 
	
	glViewport 0 0 box-3D/size/x box-3D/size/y

	hello_triangle+ woah-circle
	
	egl-End display surface eglctx
	;
	free egl-lib ; optional
	free gles32-lib ; optional
;