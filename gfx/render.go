package gfx

import (
	"fmt"
	"log"
	"runtime"
	"strings"
	"sync"

	"github.com/go-gl/gl/v4.1-core/gl"
	"github.com/go-gl/glfw/v3.2/glfw"
)

const (
	scale = 2

	vertexShaderSource = `
		#version 410
		layout (location = 0) in vec3 aPos;
		layout (location = 1) in vec3 aColor;
		layout (location = 2) in vec2 aTexCoord;

		out vec3 ourColor;
		out vec2 TexCoord;

		void main() {
			gl_Position = vec4(aPos, 1.0);
			ourColor = aColor;
			TexCoord = aTexCoord;
		}
	` + "\x00"

	fragmentShaderSource = `
		#version 410
		out vec4 FragColor;
  
		in vec3 ourColor;
		in vec2 TexCoord;

		uniform sampler2D ourTexture;

		void main()
		{
			FragColor = texture(ourTexture, TexCoord);
		}
	` + "\x00"
)

var (
	KeyLock = sync.Mutex{}
	KeyDown = map[glfw.Key]bool{}
	screen  = []float32{
		// xyz		color		texture coords
		-1, 1, 0, 1, 1, 1, 0, 0,
		-1, -1, 0, 1, 1, 1, 0, 1,
		1, -1, 0, 1, 1, 1, 1, 1,
		1, 1, 0, 1, 1, 1, 1, 0,
		-1, 1, 0, 1, 1, 1, 0, 0,
		1, -1, 0, 1, 1, 1, 1, 1,
	}
)

type Render struct {
	// the video memory
	PixelMemory [Width * Height * 3]byte
	Lock        sync.Mutex
	Window      *glfw.Window
	Program     uint32
	Vao         uint32
	// the desired framerate of the bscript code. This is how often the video texture is updated
	Fps float64

	// input mode channels
	InputMode  bool
	StartInput chan int
	StopInput  chan int
	CharInput  chan rune
}

func NewRender() *Render {
	// make sure this happens first
	render := &Render{
		PixelMemory: [Width * Height * 3]byte{},
		Lock:        sync.Mutex{},
		Fps:         60,
		InputMode:   false,
		StartInput:  make(chan int, 100),
		StopInput:   make(chan int, 100),
		CharInput:   make(chan rune, 1000),
	}
	render.Window = initGlfw(render)
	render.Program = initOpenGL()
	render.Vao = makeVao()

	runtime.LockOSThread()

	return render
}

// initGlfw initializes glfw and returns a Window to use.
func initGlfw(render *Render) *glfw.Window {
	if err := glfw.Init(); err != nil {
		panic(err)
	}
	glfw.WindowHint(glfw.Resizable, glfw.True)
	glfw.WindowHint(glfw.ContextVersionMajor, 4)
	glfw.WindowHint(glfw.ContextVersionMinor, 1)
	glfw.WindowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile)
	glfw.WindowHint(glfw.OpenGLForwardCompatible, glfw.True)

	window, err := glfw.CreateWindow(Width*scale, Height*scale, "Benji4000", nil, nil)
	if err != nil {
		panic(err)
	}
	window.MakeContextCurrent()
	window.SetCharCallback(func(w *glfw.Window, char rune) {
		if render.InputMode {
			render.CharInput <- char
		}
	})
	window.SetKeyCallback(func(w *glfw.Window, key glfw.Key, scancode int, action glfw.Action, mods glfw.ModifierKey) {
		// fmt.Printf("Key pressed: %v, Action=%v, scancode=%d\n", key, action, scancode)
		if render.InputMode {
			if action == glfw.Release {
				if key == glfw.KeyEnter {
					render.StopInput <- 1
					render.InputMode = false
				} else if key == glfw.KeyBackspace {
					render.CharInput <- 9
				}
			}
		}

		KeyLock.Lock()
		KeyDown[key] = action == glfw.Repeat || action == glfw.Press
		KeyLock.Unlock()
	})

	return window
}

// initOpenGL initializes OpenGL and returns an intiialized program.
func initOpenGL() uint32 {
	if err := gl.Init(); err != nil {
		panic(err)
	}
	version := gl.GoStr(gl.GetString(gl.VERSION))
	log.Println("OpenGL version", version)

	vertexShader, err := compileShader(vertexShaderSource, gl.VERTEX_SHADER)
	if err != nil {
		panic(err)
	}

	fragmentShader, err := compileShader(fragmentShaderSource, gl.FRAGMENT_SHADER)
	if err != nil {
		panic(err)
	}

	prog := gl.CreateProgram()
	gl.AttachShader(prog, vertexShader)
	gl.AttachShader(prog, fragmentShader)
	gl.LinkProgram(prog)
	return prog
}

func compileShader(source string, shaderType uint32) (uint32, error) {
	shader := gl.CreateShader(shaderType)

	csources, free := gl.Strs(source)
	gl.ShaderSource(shader, 1, csources, nil)
	free()
	gl.CompileShader(shader)

	var status int32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &status)
	if status == gl.FALSE {
		var logLength int32
		gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &logLength)

		log := strings.Repeat("\x00", int(logLength+1))
		gl.GetShaderInfoLog(shader, logLength, nil, gl.Str(log))

		return 0, fmt.Errorf("failed to compile %v: %v", source, log)
	}

	return shader, nil
}

// makeVao initializes and returns a vertex array from the points provided.
func makeVao() uint32 {
	var vbo uint32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 4*len(screen), gl.Ptr(screen), gl.STATIC_DRAW)

	var vao uint32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	var offset int

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8*4, gl.PtrOffset(offset))
	gl.EnableVertexAttribArray(0)
	offset += 3 * 4

	// color attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8*4, gl.PtrOffset(offset))
	gl.EnableVertexAttribArray(1)
	offset += 3 * 4

	// texture coord attribute
	gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8*4, gl.PtrOffset(offset))
	gl.EnableVertexAttribArray(2)
	offset += 2 * 4

	return vao
}

func (render *Render) GetTicks() float64 {
	return glfw.GetTime()
}

// MainLoop is the main rendering loop where the video ram is sent to the screen.
func (render *Render) MainLoop() {
	defer glfw.Terminate()

	// texture setup
	var texture uint32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

	// disable texture filtering for that old-school pixelated look
	// gl.TexParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAX_ANISOTROPY, 0)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, Width, Height, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	// gl.GenerateMipmap(gl.TEXTURE_2D)

	// bind to shader
	gl.UseProgram(render.Program)
	gl.Uniform1i(gl.GetUniformLocation(render.Program, gl.Str("ourTexture\x00")), 0)

	var lastTime, delta, lastUpdate float64
	var nbFrames int
	for !render.Window.ShouldClose() {
		currentTime := glfw.GetTime()
		delta = currentTime - lastTime
		nbFrames++
		if delta >= 1.0 { // If last cout was more than 1 sec ago
			render.Window.SetTitle(fmt.Sprintf("FPS: %.2f", float64(nbFrames)/delta))
			nbFrames = 0
			lastTime = currentTime
		}

		// Cap bscript code fps to the desired limit
		// This can mean that the video memory in gfx is not what is shown on screen...
		delta = currentTime - lastUpdate
		if delta > 1.0/render.Fps {
			// make sure the video ram is not being updated in another goroutine
			render.Lock.Lock()
			// need to do this so go.Ptr() works. This could be a bug in go: https://github.com/golang/go/issues/14210
			pixels := render.PixelMemory
			gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, Width, Height, gl.RGB, gl.UNSIGNED_BYTE, gl.Ptr(&pixels[0]))
			render.Lock.Unlock()
			lastUpdate = currentTime
		}

		// are we in capture input mode?
		select {
		case <-render.StartInput:
			render.InputMode = true
		default:
			// don't block
		}

		// gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.UseProgram(render.Program)

		gl.BindVertexArray(render.Vao)
		gl.DrawArrays(gl.TRIANGLES, 0, int32(len(screen)/8))

		glfw.PollEvents()
		render.Window.SwapBuffers()
	}
}
