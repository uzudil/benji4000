package gfx

import (
	"fmt"
	"log"
	"runtime"
	"strings"
	"sync"

	"github.com/go-gl/gl/v4.1-core/gl"
	"github.com/go-gl/glfw/v3.2/glfw"
	"github.com/go-gl/mathgl/mgl32"
)

const (
	vertexShaderSource = `
		#version 410
		layout (location = 0) in vec3 aPos;
		layout (location = 1) in vec3 aColor;
		layout (location = 2) in vec2 aTexCoord;
		
		uniform mat4 model;

		out vec3 ourColor;
		out vec2 TexCoord;

		void main() {
			gl_Position = model * vec4(aPos, 1.0);
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
		uniform int flipX;
		uniform int flipY;

		float tx, ty;

		void main()
		{
			tx = TexCoord.x;
			if(flipX != 0) {
				tx = 1 - tx;
			}
			ty = TexCoord.y;
			if(flipY != 0) {
				ty = 1 - ty;
			}
			FragColor = texture(ourTexture, vec2(tx, ty));
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

type Sprite struct {
	Textures   []uint32
	Model      mgl32.Mat4
	X          int32
	Y          int32
	W          int32
	H          int32
	ImageIndex int32
	Show       bool
	FlipX      int32
	FlipY      int32
}

type SpriteCommand struct {
	Command string
	Index   int
	W       int
	H       int
	X       int
	Y       int
	Pixels  [][]byte
}

type Render struct {
	// the video memory
	PixelMemory [Width * Height * 4]byte
	Lock        sync.Mutex
	SpriteLock  sync.Mutex
	Window      *glfw.Window
	Program     uint32
	Vao         uint32
	Sprites     [8]Sprite
	// the desired framerate of the bscript code. This is how often the video texture is updated
	Fps float64

	// input mode channels
	InputMode     bool
	StartInput    chan int
	StopInput     chan int
	CharInput     chan rune
	SpriteChannel chan SpriteCommand
}

func setTextureParams() {
	// disable texture filtering for that old-school pixelated look
	// gl.TexParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAX_ANISOTROPY, 0)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
}

func NewRender(scale int, fullscreen bool) *Render {
	// make sure this happens first
	render := &Render{
		PixelMemory:   [Width * Height * 4]byte{},
		Lock:          sync.Mutex{},
		SpriteLock:    sync.Mutex{},
		Fps:           60,
		InputMode:     false,
		StartInput:    make(chan int, 100),
		StopInput:     make(chan int, 100),
		CharInput:     make(chan rune, 1000),
		SpriteChannel: make(chan SpriteCommand, 1000),
		Sprites:       [8]Sprite{},
	}
	render.Window = initGlfw(render, scale, fullscreen)
	render.Program = initOpenGL()
	render.Vao = makeVao(screen)

	runtime.LockOSThread()

	return render
}

// initGlfw initializes glfw and returns a Window to use.
func initGlfw(render *Render, scale int, fullscreen bool) *glfw.Window {
	if err := glfw.Init(); err != nil {
		panic(err)
	}

	glfw.WindowHint(glfw.ContextVersionMajor, 4)
	glfw.WindowHint(glfw.ContextVersionMinor, 1)
	glfw.WindowHint(glfw.OpenGLProfile, glfw.OpenGLCoreProfile)
	glfw.WindowHint(glfw.OpenGLForwardCompatible, glfw.True)

	var window *glfw.Window
	var err error
	if fullscreen {
		monitor := glfw.GetPrimaryMonitor()
		mode := monitor.GetVideoMode()
		fmt.Printf("dimensions=%dx%d\n", mode.Width, mode.Height)

		// doesn't work right on my mac's second monitor...
		window, err = glfw.CreateWindow(Width, Height, "Benji4000", monitor, nil)
	} else {
		glfw.WindowHint(glfw.Resizable, glfw.True)
		window, err = glfw.CreateWindow(Width*scale, Height*scale, "Benji4000", nil, nil)
	}
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
func makeVao(data []float32) uint32 {
	var vbo uint32
	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 4*len(data), gl.Ptr(data), gl.STATIC_DRAW)

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

func (render *Render) runSpriteCommand(command SpriteCommand) error {
	sprite := &(render.Sprites[command.Index])
	if command.Command == "new" {
		if sprite.Show {
			panic("Sprite already in use")
		}

		sprite.W = int32(command.W)
		sprite.H = int32(command.H)

		// update the texture
		sprite.Textures = make([]uint32, len(command.Pixels))
		gl.GenTextures(int32(len(sprite.Textures)), &sprite.Textures[0])
		for index, image := range command.Pixels {
			gl.BindTexture(gl.TEXTURE_2D, sprite.Textures[index])
			setTextureParams()
			gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, sprite.W, sprite.H, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)
			gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, sprite.W, sprite.H, gl.RGBA, gl.UNSIGNED_BYTE, gl.Ptr(&image[0]))
		}

		// translate
		sprite.Model = mgl32.Ident4().
			Mul4(mgl32.Scale3D(float32(sprite.W)/float32(Width), float32(sprite.H)/float32(Height), 1))

		// finally, enable it
		sprite.Show = true
	} else if command.Command == "move" {
		// moving sprites via a channel is too slow
	}
	return nil
}

// MainLoop is the main rendering loop where the video ram is sent to the screen.
func (render *Render) MainLoop() {
	defer glfw.Terminate()

	// texture setup
	var texture uint32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)
	setTextureParams()
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, Width, Height, 0, gl.RGBA, gl.UNSIGNED_BYTE, nil)

	// bind to shader
	gl.UseProgram(render.Program)
	// gl.Uniform1i(gl.GetUniformLocation(render.Program, gl.Str("ourTexture\x00")), 0)

	texUniform := gl.GetUniformLocation(render.Program, gl.Str("ourTexture\x00"))
	flipXUniform := gl.GetUniformLocation(render.Program, gl.Str("flipX\x00"))
	flipYUniform := gl.GetUniformLocation(render.Program, gl.Str("flipY\x00"))
	modelUniform := gl.GetUniformLocation(render.Program, gl.Str("model\x00"))
	identity := mgl32.Ident4()

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

		gl.UseProgram(render.Program)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture)

		// Cap bscript code fps to the desired limit
		// This can mean that the video memory in gfx is not what is shown on screen...
		delta = currentTime - lastUpdate
		if delta > 1.0/render.Fps {
			// make sure the video ram is not being updated in another goroutine
			render.Lock.Lock()
			// need to do this so go.Ptr() works. This could be a bug in go: https://github.com/golang/go/issues/14210
			pixels := render.PixelMemory
			gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, Width, Height, gl.RGBA, gl.UNSIGNED_BYTE, gl.Ptr(&pixels[0]))
			render.Lock.Unlock()
			lastUpdate = currentTime
		}

		// are we in capture input mode?
		select {
		case <-render.StartInput:
			render.InputMode = true
		case spriteCommand := <-render.SpriteChannel:
			render.runSpriteCommand(spriteCommand)
		default:
			// don't block
		}

		// gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
		gl.UniformMatrix4fv(modelUniform, 1, false, &identity[0])
		gl.Uniform1i(texUniform, 0)
		gl.Uniform1i(flipXUniform, 0)
		gl.Uniform1i(flipYUniform, 0)
		gl.BindVertexArray(render.Vao)
		gl.DrawArrays(gl.TRIANGLES, 0, int32(len(screen)/8))

		gl.Enable(gl.BLEND)
		gl.BlendEquation(gl.MAX)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
		render.SpriteLock.Lock()
		for _, sprite := range render.Sprites {
			if sprite.Show {
				gl.BindTexture(gl.TEXTURE_2D, sprite.Textures[sprite.ImageIndex])
				gl.Uniform1i(texUniform, 0)
				gl.Uniform1i(flipXUniform, sprite.FlipX)
				gl.Uniform1i(flipYUniform, sprite.FlipY)

				sprite.Model = mgl32.Ident4().
					Mul4(mgl32.Translate3D(float32(sprite.X-Width/2)/float32(Width/2), -float32(sprite.Y-Height/2)/float32(Height/2), 0)).
					Mul4(mgl32.Scale3D(float32(sprite.W)/float32(Width), float32(sprite.H)/float32(Height), 1))

				gl.UniformMatrix4fv(modelUniform, 1, false, &sprite.Model[0])
				gl.DrawArrays(gl.TRIANGLES, 0, int32(len(screen)/8))
			}
		}
		render.SpriteLock.Unlock()
		gl.Disable(gl.BLEND)

		glfw.PollEvents()
		render.Window.SwapBuffers()
	}
}
