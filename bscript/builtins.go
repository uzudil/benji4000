package bscript

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math"
	"math/rand"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/go-gl/glfw/v3.2/glfw"
	"github.com/uzudil/benji4000/gfx"
)

func floatArgs(ctx *Context, count int, arg []interface{}) ([]float64, error) {
	if len(arg) < count {
		return nil, fmt.Errorf("%s Wrong number of arguments. Got %d instead of %d", ctx.Pos, count, len(arg))
	}
	r := make([]float64, count)
	for index, a := range arg[0:count] {
		f, ok := a.(float64)
		if !ok {
			return nil, fmt.Errorf("%s Argument %d should be a number (%v)", ctx.Pos, index, a)
		}
		r[index] = f
	}
	return r, nil
}

func intArgs(ctx *Context, count int, arg []interface{}) ([]int, error) {
	f, err := floatArgs(ctx, count, arg)
	if err != nil {
		return nil, err
	}
	r := make([]int, count)
	for index, value := range f {
		r[index] = int(value)
	}
	return r, nil
}

func stringArgs(ctx *Context, count int, arg []interface{}) ([]string, error) {
	if len(arg) < count {
		return nil, fmt.Errorf("%s Wrong number of arguments. Got %d instead of %d", ctx.Pos, count, len(arg))
	}
	r := make([]string, count)
	for index, a := range arg[0:count] {
		s, ok := a.(string)
		if !ok {
			return nil, fmt.Errorf("%s Argument %d should be a string (%v)", ctx.Pos, index, s)
		}
		r[index] = s
	}
	return r, nil
}

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
	s, err := stringArgs(ctx, 3, arg)
	if err != nil {
		return nil, err
	}
	return strings.ReplaceAll(s[0], s[1], s[2]), nil
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
	if mode < 0 || mode > 2 {
		return nil, fmt.Errorf("Invalid video mode")
	}
	ctx.Video.VideoMode = int(mode)
	return nil, nil
}

func scroll(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	ctx.Video.Scroll(i[0], i[1])
	return nil, nil
}

func setPixel(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 3, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.SetPixel(i[0], i[1], uint8(i[2]))
}

func drawText(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	text, ok := arg[4].(string)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a string")
	}
	return nil, ctx.Video.DrawText(i[0], i[1], text, uint8(i[2]), uint8(i[3]))
}

func drawFont(ctx *Context, arg ...interface{}) (interface{}, error) {
	f, err := floatArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	ch, ok := arg[4].(float64)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a number")
	}
	return nil, ctx.Video.DrawFont(int(f[0]), int(f[1]), rune(ch), uint8(f[2]), uint8(f[3]))
}

func drawLine(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.DrawLine(i[0], i[1], i[2], i[3], uint8(i[4]))
}

func drawCircle(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.DrawCircle(i[0], i[1], i[2], uint8(i[3]))
}

func fillCircle(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.FillCircle(i[0], i[1], i[2], uint8(i[3]))
}

func setBackground(ctx *Context, arg ...interface{}) (interface{}, error) {
	c, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	ctx.Video.SetBackgroundColor(byte(c))
	return nil, nil
}

func fillRect(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.FillRect(i[0], i[1], i[2], i[3], uint8(i[4]))
}

func drawRect(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.DrawRect(i[0], i[1], i[2], i[3], uint8(i[4]))
}

func getImage(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	return ctx.Video.GetImage(i[0], i[1], i[2], i[3])
}

func drawImage(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	img, ok := arg[2].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("Third argument should be an image")
	}
	return nil, ctx.Video.DrawImage(i[0], i[1], img)
}

func getImageWidth(ctx *Context, arg ...interface{}) (interface{}, error) {
	img, ok := arg[0].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("First argument should be an image")
	}
	return float64(img["width"].(int)), nil
}

func getImageHeight(ctx *Context, arg ...interface{}) (interface{}, error) {
	img, ok := arg[0].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("First argument should be an image")
	}
	return float64(img["height"].(int)), nil
}

func setSprite(ctx *Context, arg ...interface{}) (interface{}, error) {
	index, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	a, ok := arg[1].(*[]interface{})
	if !ok {
		return nil, fmt.Errorf("Second argument should be an array")
	}
	imgs := make([]map[string]interface{}, len(*a))
	for index, aa := range *a {
		img, ok := aa.(map[string]interface{})
		if !ok {
			return nil, fmt.Errorf("Second argument should be an array of images")
		}
		imgs[index] = img
	}
	return nil, ctx.Video.SetSprite(int(index), imgs)
}

func delSprite(ctx *Context, arg ...interface{}) (interface{}, error) {
	index, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return nil, ctx.Video.DelSprite(int(index))
}

func drawSprite(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 6, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.DrawSprite(i[0], i[1], i[2], i[3], i[4], i[5])
}

func checkSpriteCollision(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	return ctx.Video.CheckSpriteCollision(i[0], i[1])
}

func flood(ctx *Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 3, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.FloodFill(i[0], i[1], uint8(i[2]))
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
		s, ok := arg[0].(string)
		if !ok {
			return nil, fmt.Errorf("First argument should be a number or a string")
		}
		i, err := strconv.Atoi(s)
		if err != nil {
			i = 0
		}
		return float64(i), nil
	}
	return float64(int(n)), nil
}

func toRound(ctx *Context, arg ...interface{}) (interface{}, error) {
	n, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return float64(int(n)), nil
}

func anyKeyDown(ctx *Context, arg ...interface{}) (interface{}, error) {
	gfx.KeyLock.Lock()
	b := false
	for _, v := range gfx.KeyDown {
		if v {
			b = true
			break
		}
	}
	gfx.KeyLock.Unlock()
	return b, nil
}

func anyNonHelperKeyDown(ctx *Context, arg ...interface{}) (interface{}, error) {
	gfx.KeyLock.Lock()
	b := false
	for k, v := range gfx.KeyDown {
		if !(k == glfw.KeyLeftShift || k == glfw.KeyRightShift || k == glfw.KeyLeftAlt || k == glfw.KeyRightAlt || k == glfw.KeyLeftControl || k == glfw.KeyRightControl || k == glfw.KeyLeftSuper || k == glfw.KeyRightSuper) && v {
			b = true
			break
		}
	}
	gfx.KeyLock.Unlock()
	return b, nil
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

func fontIndex(ctx *Context, arg []interface{}) (int, error) {
	// Font *[512][8]uint8
	f, ok := arg[0].(float64)
	if !ok {
		return 0, fmt.Errorf("%s first arg should be a number (%v)", ctx.Pos, arg[0])
	}
	index := int(f)
	if index < 0 || index >= len(ctx.Video.Font) {
		return 0, fmt.Errorf("%s index out of bounds - should be 0 to %d", ctx.Pos, len(ctx.Video.Font))
	}
	return index, nil
}

func getFont(ctx *Context, arg ...interface{}) (interface{}, error) {
	index, err := fontIndex(ctx, arg)
	if err != nil {
		return nil, err
	}
	font := [8]float64{}
	for i, f := range ctx.Video.Font[index] {
		font[i] = float64(f)
	}
	return font, nil
}

func setFont(ctx *Context, arg ...interface{}) (interface{}, error) {
	index, err := fontIndex(ctx, arg)
	if err != nil {
		return nil, err
	}
	a, ok := arg[1].(*[]interface{})
	if !ok {
		return nil, fmt.Errorf("%s second argument should be an array (%v)", ctx.Pos, arg[1])
	}
	if len(*a) != 8 {
		return nil, fmt.Errorf("%s font array should have length of 8", ctx.Pos)
	}
	font := [8]uint8{}
	for i, aa := range *a {
		f, ok := aa.(float64)
		if !ok {
			return nil, fmt.Errorf("%s second argument should contain only numbers (%v)", ctx.Pos, arg[1])
		}
		font[i] = uint8(f)
	}
	for i, v := range font {
		ctx.Video.Font[index][i] = v
	}
	return nil, nil
}

func getColor(ctx *Context, arg ...interface{}) (interface{}, error) {
	f, ok := arg[0].(float64)
	if !ok {
		return 0, fmt.Errorf("%s first arg should be a number (%v)", ctx.Pos, arg[0])
	}
	index := int(f)
	if index < 0 || index >= len(ctx.Video.Colors) {
		return 0, fmt.Errorf("%s index out of bounds - should be 0 to %d", ctx.Pos, len(ctx.Video.Colors))
	}
	return [3]float64{
		float64(ctx.Video.Colors[index*3]),
		float64(ctx.Video.Colors[index*3+1]),
		float64(ctx.Video.Colors[index*3+2]),
	}, nil
}

func setColor(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	index := a[0]
	if index < 0 || index >= len(ctx.Video.Colors) {
		return 0, fmt.Errorf("%s index out of bounds - should be 0 to %d", ctx.Pos, len(ctx.Video.Colors))
	}
	ctx.Video.Colors[index*3] = uint8(a[1])
	ctx.Video.Colors[index*3+1] = uint8(a[2])
	ctx.Video.Colors[index*3+2] = uint8(a[3])
	return nil, nil
}

func checkFilename(filename string) error {
	if strings.Contains(filename, "/") || strings.Contains(filename, "\\") {
		return fmt.Errorf("Invalid filename: %s", filename)
	}
	return nil
}

func saveFile(ctx *Context, arg ...interface{}) (interface{}, error) {
	if ctx.Sandbox == nil {
		return nil, fmt.Errorf("Not running in a sandbox")
	}
	filename, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("First parameter is the filename")
	}
	err := checkFilename(filename)
	if err != nil {
		return nil, err
	}
	data, ok := arg[1].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("Second parameter should be a map")
	}
	jsonstr, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}
	return nil, ioutil.WriteFile(filepath.Join(*ctx.Sandbox, filename), []byte(jsonstr), 0644)
}

// Images need extra processing. Look for images in the loaded data...
func fixImages(data map[string]interface{}) {
	for _, v := range data {
		m, ok := v.(map[string]interface{})
		if ok {
			t, ok := m["_type_"]
			if ok && t == "image" {
				m["width"] = int(m["width"].(float64))
				m["height"] = int(m["height"].(float64))

				// decode base64 string
				s := m["data"].(string)
				data := make([]byte, base64.StdEncoding.DecodedLen(len(s)))
				l, _ := base64.StdEncoding.Decode(data, []byte(s))
				m["data"] = data[:l]
			}
			fixImages(m)
		}

		arr, ok := v.(*[]interface{})
		if ok {
			for _, v := range *arr {
				m, ok := v.(map[string]interface{})
				if ok {
					fixImages(m)
				}
			}
		}
	}
}

func loadFile(ctx *Context, arg ...interface{}) (interface{}, error) {
	if ctx.Sandbox == nil {
		return nil, fmt.Errorf("Not running in a sandbox")
	}
	filename, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("First parameter is the filename")
	}
	err := checkFilename(filename)
	if err != nil {
		return nil, err
	}
	bytes, err := ioutil.ReadFile(filepath.Join(*ctx.Sandbox, filename))
	if err != nil {
		return nil, nil
	}
	data := map[string]interface{}{}
	err = json.Unmarshal(bytes, &data)
	if err != nil {
		return nil, err
	}
	fixImages(data)
	return data, nil
}

func addBoundingBox(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	index, err := ctx.Video.AddBoundingBox(a[0], a[1], a[2], a[3], a[4])
	return float64(index), err
}

func getBoundingBox(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	x, y, x2, y2, err := ctx.Video.GetBoundingBox(a[0], a[1])
	r := make([]interface{}, 4)
	r[0] = float64(x)
	r[1] = float64(y)
	r[2] = float64(x2)
	r[3] = float64(y2)
	return &r, err
}

func delBoundingBox(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.DelBoundingBox(a[0], a[1])
}

func clearBoundingBoxes(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 1, arg)
	if err != nil {
		return nil, err
	}
	return nil, ctx.Video.ClearBoundingBoxes(a[0])
}

func checkBoundingBoxes(ctx *Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	index, err := ctx.Video.CheckBoundingBoxes(a[0], a[1], a[2], a[3], a[4])
	return float64(index), err
}

func clearSound(ctx *Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	return nil, ctx.Sound.Clear(int(playerIndex))
}

func pauseSound(ctx *Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	enabled, ok := arg[1].(bool)
	if !ok {
		return nil, fmt.Errorf("Second argument should be a boolean")
	}
	return nil, ctx.Sound.Pause(int(playerIndex), enabled)
}

func loopSound(ctx *Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	enabled, ok := arg[1].(bool)
	if !ok {
		return nil, fmt.Errorf("Second argument should be a boolean")
	}
	return nil, ctx.Sound.Loop(int(playerIndex), enabled)
}

func playSound(ctx *Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	freq, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("Second argument should be the frequency")
	}
	duration, ok := arg[2].(float64)
	if !ok {
		return nil, fmt.Errorf("Third argument should be the duration")
	}
	return nil, ctx.Sound.Play(int(playerIndex), freq, duration)
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
		"print":                print,
		"input":                input,
		"len":                  length,
		"keys":                 keys,
		"substr":               substr,
		"replace":              replace,
		"debug":                debug,
		"assert":               assert,
		"setVideoMode":         setVideoMode,
		"setPixel":             setPixel,
		"random":               random,
		"updateVideo":          updateVideo,
		"clearVideo":           clearVideo,
		"drawLine":             drawLine,
		"drawCircle":           drawCircle,
		"fillCircle":           fillCircle,
		"drawRect":             drawRect,
		"fillRect":             fillRect,
		"drawText":             drawText,
		"drawFont":             drawFont,
		"scroll":               scroll,
		"trace":                trace,
		"getTicks":             getTicks,
		"isKeyDown":            isKeyDown,
		"setBackground":        setBackground,
		"int":                  toInt,
		"round":                toRound,
		"abs":                  toAbs,
		"getFont":              getFont,
		"setFont":              setFont,
		"getColor":             getColor,
		"setColor":             setColor,
		"getImage":             getImage,
		"drawImage":            drawImage,
		"getImageWidth":        getImageWidth,
		"getImageHeight":       getImageHeight,
		"setSprite":            setSprite,
		"drawSprite":           drawSprite,
		"flood":                flood,
		"anyKeyDown":           anyKeyDown,
		"anyNonHelperKeyDown":  anyNonHelperKeyDown,
		"save":                 saveFile,
		"load":                 loadFile,
		"addBoundingBox":       addBoundingBox,
		"getBoundingBox":       getBoundingBox,
		"delBoundingBox":       delBoundingBox,
		"clearBoundingBoxes":   clearBoundingBoxes,
		"checkBoundingBoxes":   checkBoundingBoxes,
		"checkSpriteCollision": checkSpriteCollision,
		"delSprite":            delSprite,
		"playSound":            playSound,
		"pauseSound":           pauseSound,
		"loopSound":            loopSound,
		"clearSound":           clearSound,
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
