package bscript

import (
	"fmt"
	"math"
	"math/rand"
	"strings"

	"github.com/go-gl/glfw/v3.2/glfw"
	"github.com/uzudil/benji4000/gfx"
)

func print(ctx *Context, arg ...interface{}) (interface{}, error) {
	ctx.Video.Println(EvalString(arg[0]), true)
	ctx.Video.UpdateVideo()
	return nil, nil
}

func trace(ctx *Context, arg ...interface{}) (interface{}, error) {
	fmt.Println(EvalString(arg[0]))
	return nil, nil
}

func getTicks(ctx *Context, arg ...interface{}) (interface{}, error) {
	return ctx.Video.Render.GetTicks(), nil
}

func input(ctx *Context, arg ...interface{}) (interface{}, error) {
	ctx.Video.Println(EvalString(arg[0]), false)
	ctx.Video.UpdateVideo()

	var text strings.Builder
	// start capturing input
	ctx.Video.Render.StartInput <- 1

	// block until input mode is over
	for done := false; done != true; {
		select {
		case char := <-ctx.Video.Render.CharInput:
			if char == 9 {
				if text.Len() > 0 {
					// try to remove it from the screen
					err := ctx.Video.Backspace()
					if err == nil {
						// remove the last character from memory
						s := text.String()
						text = strings.Builder{}
						text.WriteString(s[0 : len(s)-1])
					} else {
						fmt.Println("Can't backspace")
					}
				}
			} else {
				text.WriteRune(char)
				ctx.Video.Println(string(char), false)
			}
		case <-ctx.Video.Render.StopInput:
			ctx.Video.Println("", true)
			done = true
		}
		ctx.Video.UpdateVideo()
	}
	return strings.TrimSpace(text.String()), nil
}

func length(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, ok := arg[0].(*[]interface{})
	if !ok {
		s, ok := arg[0].(string)
		if !ok {
			return nil, fmt.Errorf("argument to len() should be an array or a string")
		}
		return float64(len(s)), nil
	}
	return float64(len(*a)), nil
}

func substr(ctx *Context, arg ...interface{}) (interface{}, error) {
	s, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("argument 1 to substr() should be a string")
	}
	index, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("argument 2 to substr() should be a number")
	}
	length := len(s)
	if len(arg) > 2 {
		f, ok := arg[2].(float64)
		if !ok {
			return nil, fmt.Errorf("argument 3 to substr() should be a number")
		}
		length = int(f)
	}
	start := int(math.Min(math.Max(index, 0), float64(len(s))))
	end := int(math.Min(math.Max(float64(start+length), 0), float64(len(s))))
	return string(s[start:end]), nil
}

func replace(ctx *Context, arg ...interface{}) (interface{}, error) {
	s, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("argument 1 to replace() should be a string")
	}
	oldstring, ok := arg[1].(string)
	if !ok {
		return nil, fmt.Errorf("argument 2 to replace() should be a string")
	}
	newstring, ok := arg[2].(string)
	if !ok {
		return nil, fmt.Errorf("argument 3 to replace() should be a string")
	}

	return strings.ReplaceAll(s, oldstring, newstring), nil
}

func keys(ctx *Context, arg ...interface{}) (interface{}, error) {
	m, ok := arg[0].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("argument to key() should be a map")
	}
	keys := make([]interface{}, len(m))
	index := 0
	for k := range m {
		keys[index] = k
		index++
	}
	return &keys, nil
}

func setVideoMode(ctx *Context, arg ...interface{}) (interface{}, error) {
	mode, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be the number of the video mode")
	}
	ctx.Video.VideoMode = int(mode)
	return nil, nil
}

func scroll(ctx *Context, arg ...interface{}) (interface{}, error) {
	dx, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	dy, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	ctx.Video.Scroll(int(dx), int(dy))
	return nil, nil
}

func setPixel(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	color, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	return nil, ctx.Video.SetPixel(int(x), int(y), uint8(color))
}

func drawText(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	fg, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	bg, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	text, ok := arg[4].(string)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a string")
	}
	return nil, ctx.Video.DrawText(int(x), int(y), text, uint8(fg), uint8(bg))
}

func drawFont(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	fg, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	bg, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	ch, ok := arg[4].(float64)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a number")
	}
	return nil, ctx.Video.DrawFont(int(x), int(y), rune(ch), uint8(fg), uint8(bg))
}

func drawLine(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	x2, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	y2, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	color, ok := arg[4].(float64)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a number")
	}
	return nil, ctx.Video.DrawLine(int(x), int(y), int(x2), int(y2), uint8(color))
}

func drawCircle(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	r, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	color, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	return nil, ctx.Video.DrawCircle(int(x), int(y), int(r), uint8(color))
}

func fillCircle(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	r, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	color, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	return nil, ctx.Video.FillCircle(int(x), int(y), int(r), uint8(color))
}

func setBackground(ctx *Context, arg ...interface{}) (interface{}, error) {
	c, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	ctx.Video.BackgroundColor = byte(c)
	return nil, nil
}

func fillRect(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	x2, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	y2, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	color, ok := arg[4].(float64)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a number")
	}
	return nil, ctx.Video.FillRect(int(x), int(y), int(x2), int(y2), uint8(color))
}

func drawRect(ctx *Context, arg ...interface{}) (interface{}, error) {
	x, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	y, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a number")
	}
	x2, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third parameter should be a number")
	}
	y2, ok := arg[3].(float64)
	if !ok {
		return nil, fmt.Errorf("Fourth parameter should be a number")
	}
	color, ok := arg[4].(float64)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a number")
	}
	return nil, ctx.Video.DrawRect(int(x), int(y), int(x2), int(y2), uint8(color))
}

func clearVideo(ctx *Context, arg ...interface{}) (interface{}, error) {
	return nil, ctx.Video.ClearVideo()
}

func updateVideo(ctx *Context, arg ...interface{}) (interface{}, error) {
	if ctx.Video == nil {
		panic("Video card not initialized")
	}
	// todo: delay here to achive a requested max framerate (default to 60)
	return nil, ctx.Video.UpdateVideo()
}

func random(ctx *Context, arg ...interface{}) (interface{}, error) {
	return rand.Float64(), nil
}

func debug(ctx *Context, arg ...interface{}) (interface{}, error) {
	message, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("argument to debug() should be a string")
	}
	ctx.debug(message)
	return nil, nil
}

func toAbs(ctx *Context, arg ...interface{}) (interface{}, error) {
	n, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return math.Abs(n), nil
}

func toInt(ctx *Context, arg ...interface{}) (interface{}, error) {
	n, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return math.Round(n), nil
}

func toRound(ctx *Context, arg ...interface{}) (interface{}, error) {
	n, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return float64(int(n)), nil
}

func isKeyDown(ctx *Context, arg ...interface{}) (interface{}, error) {
	key, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	// action := ctx.Video.Render.Window.GetKey(glfw.Key(key))
	// return (action == glfw.Press || action == glfw.Repeat), nil
	gfx.KeyLock.Lock()
	b := gfx.KeyDown[glfw.Key(key)]
	gfx.KeyLock.Unlock()

	return b, nil
}

func assert(ctx *Context, arg ...interface{}) (interface{}, error) {
	a := arg[0]
	b := arg[1]
	msg := "Incorrect value"
	if len(arg) > 2 {
		msg = arg[2].(string)
	}

	var res bool

	// for arrays, compare the values
	arr, ok := a.(*[]interface{})
	if ok {
		// array
		brr, ok := b.(*[]interface{})
		if !ok {
			res = true
		} else {
			if len(*arr) == len(*brr) {
				res = false
				for i := range *arr {
					if (*arr)[i] != (*brr)[i] {
						res = true
						break
					}
				}
			} else {
				res = true
			}
		}
	} else {
		// map
		amap, ok := a.(map[string]interface{})
		if ok {
			bmap, ok := b.(map[string]interface{})
			if !ok {
				res = true
			} else {
				if len(amap) == len(bmap) {
					res = false
					for k := range amap {
						if amap[k] != bmap[k] {
							res = true
							break
						}
					}
				} else {
					res = true
				}
			}
		} else {
			// default is to compare equality
			res = a != b
		}
	}

	if res {
		debug(ctx, fmt.Sprintf("Assertion failure: %s: %v != %v", msg, a, b))
		return nil, fmt.Errorf("%s Assertion failure: %s: %v != %v", ctx.Pos, msg, a, b)
	}
	return nil, nil
}

func Builtins() map[string]Builtin {
	return map[string]Builtin{
		"print":         print,
		"input":         input,
		"len":           length,
		"keys":          keys,
		"substr":        substr,
		"replace":       replace,
		"debug":         debug,
		"assert":        assert,
		"setVideoMode":  setVideoMode,
		"setPixel":      setPixel,
		"random":        random,
		"updateVideo":   updateVideo,
		"clearVideo":    clearVideo,
		"drawLine":      drawLine,
		"drawCircle":    drawCircle,
		"fillCircle":    fillCircle,
		"drawRect":      drawRect,
		"fillRect":      fillRect,
		"drawText":      drawText,
		"drawFont":      drawFont,
		"scroll":        scroll,
		"trace":         trace,
		"getTicks":      getTicks,
		"isKeyDown":     isKeyDown,
		"setBackground": setBackground,
		"int":           toInt,
		"round":         toRound,
		"abs":           toAbs,
	}
}

func Constants() map[string]interface{} {
	return map[string]interface{}{
		// colors
		"COLOR_BLACK":       float64(gfx.COLOR_BLACK),
		"COLOR_WHITE":       float64(gfx.COLOR_WHITE),
		"COLOR_RED":         float64(gfx.COLOR_RED),
		"COLOR_TEAL":        float64(gfx.COLOR_TEAL),
		"COLOR_PURPLE":      float64(gfx.COLOR_PURPLE),
		"COLOR_GREEN":       float64(gfx.COLOR_GREEN),
		"COLOR_DARK_BLUE":   float64(gfx.COLOR_DARK_BLUE),
		"COLOR_YELLOW":      float64(gfx.COLOR_YELLOW),
		"COLOR_BROWN":       float64(gfx.COLOR_BROWN),
		"COLOR_DARK_BROWN":  float64(gfx.COLOR_DARK_BROWN),
		"COLOR_TAN":         float64(gfx.COLOR_TAN),
		"COLOR_DARK_GRAY":   float64(gfx.COLOR_DARK_GRAY),
		"COLOR_MID_GRAY":    float64(gfx.COLOR_MID_GRAY),
		"COLOR_LIGHT_GREEN": float64(gfx.COLOR_LIGHT_GREEN),
		"COLOR_LIGHT_BLUE":  float64(gfx.COLOR_LIGHT_BLUE),
		"COLOR_LIGHT_GRAY":  float64(gfx.COLOR_LIGHT_GRAY),

		// keyboard keys
		"KeyUnknown":      float64(glfw.KeyUnknown),
		"KeySpace":        float64(glfw.KeySpace),
		"KeyApostrophe":   float64(glfw.KeyApostrophe),
		"KeyComma":        float64(glfw.KeyComma),
		"KeyMinus":        float64(glfw.KeyMinus),
		"KeyPeriod":       float64(glfw.KeyPeriod),
		"KeySlash":        float64(glfw.KeySlash),
		"Key0":            float64(glfw.Key0),
		"Key1":            float64(glfw.Key1),
		"Key2":            float64(glfw.Key2),
		"Key3":            float64(glfw.Key3),
		"Key4":            float64(glfw.Key4),
		"Key5":            float64(glfw.Key5),
		"Key6":            float64(glfw.Key6),
		"Key7":            float64(glfw.Key7),
		"Key8":            float64(glfw.Key8),
		"Key9":            float64(glfw.Key9),
		"KeySemicolon":    float64(glfw.KeySemicolon),
		"KeyEqual":        float64(glfw.KeyEqual),
		"KeyA":            float64(glfw.KeyA),
		"KeyB":            float64(glfw.KeyB),
		"KeyC":            float64(glfw.KeyC),
		"KeyD":            float64(glfw.KeyD),
		"KeyE":            float64(glfw.KeyE),
		"KeyF":            float64(glfw.KeyF),
		"KeyG":            float64(glfw.KeyG),
		"KeyH":            float64(glfw.KeyH),
		"KeyI":            float64(glfw.KeyI),
		"KeyJ":            float64(glfw.KeyJ),
		"KeyK":            float64(glfw.KeyK),
		"KeyL":            float64(glfw.KeyL),
		"KeyM":            float64(glfw.KeyM),
		"KeyN":            float64(glfw.KeyN),
		"KeyO":            float64(glfw.KeyO),
		"KeyP":            float64(glfw.KeyP),
		"KeyQ":            float64(glfw.KeyQ),
		"KeyR":            float64(glfw.KeyR),
		"KeyS":            float64(glfw.KeyS),
		"KeyT":            float64(glfw.KeyT),
		"KeyU":            float64(glfw.KeyU),
		"KeyV":            float64(glfw.KeyV),
		"KeyW":            float64(glfw.KeyW),
		"KeyX":            float64(glfw.KeyX),
		"KeyY":            float64(glfw.KeyY),
		"KeyZ":            float64(glfw.KeyZ),
		"KeyLeftBracket":  float64(glfw.KeyLeftBracket),
		"KeyBackslash":    float64(glfw.KeyBackslash),
		"KeyRightBracket": float64(glfw.KeyRightBracket),
		"KeyGraveAccent":  float64(glfw.KeyGraveAccent),
		"KeyWorld1":       float64(glfw.KeyWorld1),
		"KeyWorld2":       float64(glfw.KeyWorld2),
		"KeyEscape":       float64(glfw.KeyEscape),
		"KeyEnter":        float64(glfw.KeyEnter),
		"KeyTab":          float64(glfw.KeyTab),
		"KeyBackspace":    float64(glfw.KeyBackspace),
		"KeyInsert":       float64(glfw.KeyInsert),
		"KeyDelete":       float64(glfw.KeyDelete),
		"KeyRight":        float64(glfw.KeyRight),
		"KeyLeft":         float64(glfw.KeyLeft),
		"KeyDown":         float64(glfw.KeyDown),
		"KeyUp":           float64(glfw.KeyUp),
		"KeyPageUp":       float64(glfw.KeyPageUp),
		"KeyPageDown":     float64(glfw.KeyPageDown),
		"KeyHome":         float64(glfw.KeyHome),
		"KeyEnd":          float64(glfw.KeyEnd),
		"KeyCapsLock":     float64(glfw.KeyCapsLock),
		"KeyScrollLock":   float64(glfw.KeyScrollLock),
		"KeyNumLock":      float64(glfw.KeyNumLock),
		"KeyPrintScreen":  float64(glfw.KeyPrintScreen),
		"KeyPause":        float64(glfw.KeyPause),
		"KeyF1":           float64(glfw.KeyF1),
		"KeyF2":           float64(glfw.KeyF2),
		"KeyF3":           float64(glfw.KeyF3),
		"KeyF4":           float64(glfw.KeyF4),
		"KeyF5":           float64(glfw.KeyF5),
		"KeyF6":           float64(glfw.KeyF6),
		"KeyF7":           float64(glfw.KeyF7),
		"KeyF8":           float64(glfw.KeyF8),
		"KeyF9":           float64(glfw.KeyF9),
		"KeyF10":          float64(glfw.KeyF10),
		"KeyF11":          float64(glfw.KeyF11),
		"KeyF12":          float64(glfw.KeyF12),
		"KeyF13":          float64(glfw.KeyF13),
		"KeyF14":          float64(glfw.KeyF14),
		"KeyF15":          float64(glfw.KeyF15),
		"KeyF16":          float64(glfw.KeyF16),
		"KeyF17":          float64(glfw.KeyF17),
		"KeyF18":          float64(glfw.KeyF18),
		"KeyF19":          float64(glfw.KeyF19),
		"KeyF20":          float64(glfw.KeyF20),
		"KeyF21":          float64(glfw.KeyF21),
		"KeyF22":          float64(glfw.KeyF22),
		"KeyF23":          float64(glfw.KeyF23),
		"KeyF24":          float64(glfw.KeyF24),
		"KeyF25":          float64(glfw.KeyF25),
		"KeyKP0":          float64(glfw.KeyKP0),
		"KeyKP1":          float64(glfw.KeyKP1),
		"KeyKP2":          float64(glfw.KeyKP2),
		"KeyKP3":          float64(glfw.KeyKP3),
		"KeyKP4":          float64(glfw.KeyKP4),
		"KeyKP5":          float64(glfw.KeyKP5),
		"KeyKP6":          float64(glfw.KeyKP6),
		"KeyKP7":          float64(glfw.KeyKP7),
		"KeyKP8":          float64(glfw.KeyKP8),
		"KeyKP9":          float64(glfw.KeyKP9),
		"KeyKPDecimal":    float64(glfw.KeyKPDecimal),
		"KeyKPDivide":     float64(glfw.KeyKPDivide),
		"KeyKPMultiply":   float64(glfw.KeyKPMultiply),
		"KeyKPSubtract":   float64(glfw.KeyKPSubtract),
		"KeyKPAdd":        float64(glfw.KeyKPAdd),
		"KeyKPEnter":      float64(glfw.KeyKPEnter),
		"KeyKPEqual":      float64(glfw.KeyKPEqual),
		"KeyLeftShift":    float64(glfw.KeyLeftShift),
		"KeyLeftControl":  float64(glfw.KeyLeftControl),
		"KeyLeftAlt":      float64(glfw.KeyLeftAlt),
		"KeyLeftSuper":    float64(glfw.KeyLeftSuper),
		"KeyRightShift":   float64(glfw.KeyRightShift),
		"KeyRightControl": float64(glfw.KeyRightControl),
		"KeyRightAlt":     float64(glfw.KeyRightAlt),
		"KeyRightSuper":   float64(glfw.KeyRightSuper),
		"KeyMenu":         float64(glfw.KeyMenu),
		"KeyLast":         float64(glfw.KeyLast),
	}
}
