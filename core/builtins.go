package core

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-gl/glfw/v3.2/glfw"
	"github.com/uzudil/benji4000/gfx"
	"github.com/uzudil/benji4000/sound"
	"github.com/uzudil/bscript/bscript"
)

func floatArgs(ctx *bscript.Context, count int, arg []interface{}) ([]float64, error) {
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

func intArgs(ctx *bscript.Context, count int, arg []interface{}) ([]int, error) {
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

func stringArgs(ctx *bscript.Context, count int, arg []interface{}) ([]string, error) {
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

func video(ctx *bscript.Context) *gfx.Gfx {
	return ctx.App["video"].(*gfx.Gfx)
}

func audio(ctx *bscript.Context) *sound.Sound {
	return ctx.App["sound"].(*sound.Sound)
}

func print(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	video(ctx).Println(bscript.EvalString(arg[0]), true)
	video(ctx).UpdateVideo()
	return nil, nil
}

func trace(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	fmt.Println(bscript.EvalString(arg[0]))
	return nil, nil
}

func sleep(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	ms, err := intArgs(ctx, 1, arg)
	if err != nil {
		return nil, err
	}
	time.Sleep(time.Duration(ms[0]) * time.Millisecond)
	return nil, nil
}

func limitFps(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	fps, err := floatArgs(ctx, 1, arg)
	if err != nil {
		return nil, err
	}
	video(ctx).Render.Fps = fps[0]
	return nil, nil
}

func getTicks(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	return video(ctx).Render.GetTicks(), nil
}

func input(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	video(ctx).Println(bscript.EvalString(arg[0]), false)
	video(ctx).UpdateVideo()

	var text strings.Builder
	// start capturing input
	video(ctx).Render.StartInput <- gfx.INPUT_MODE_ON

	// block until input mode is over
	for done := false; done != true; {
		select {
		case char := <-video(ctx).Render.CharInput:
			if char == 9 {
				if text.Len() > 0 {
					// try to remove it from the screen
					err := video(ctx).Backspace()
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
				video(ctx).Println(string(char), false)
			}
		case <-video(ctx).Render.StopInput:
			video(ctx).Println("", true)
			done = true
		}
		video(ctx).UpdateVideo()
	}
	return strings.TrimSpace(text.String()), nil
}

func length(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, ok := arg[0].(*[]interface{})
	if !ok {
		s, ok := arg[0].(string)
		if !ok {
			return nil, fmt.Errorf("%s argument to len() should be an array or a string", ctx.Pos)
		}
		return float64(len(s)), nil
	}
	return float64(len(*a)), nil
}

func split(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	s, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("%s argument 1 should be a string", ctx.Pos)
	}
	d, ok := arg[1].(string)
	if !ok {
		return nil, fmt.Errorf("%s argument 2 should be a string", ctx.Pos)
	}
	// a := strings.Split(s, d)
	a := regexp.MustCompile(d).Split(s, -1)
	arr := make([]interface{}, len(a))
	for i, aa := range a {
		arr[i] = aa
	}
	return &arr, nil
}

func substr(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	s, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("%s argument 1 to substr() should be a string", ctx.Pos)
	}
	index, ok := arg[1].(float64)
	if !ok {
		return nil, fmt.Errorf("%s argument 2 to substr() should be a number", ctx.Pos)
	}
	length := len(s)
	if len(arg) > 2 {
		f, ok := arg[2].(float64)
		if !ok {
			return nil, fmt.Errorf("%s argument 3 to substr() should be a number", ctx.Pos)
		}
		length = int(f)
	}
	start := int(math.Min(math.Max(index, 0), float64(len(s))))
	end := int(math.Min(math.Max(float64(start+length), 0), float64(len(s))))
	return string(s[start:end]), nil
}

func replace(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	s, err := stringArgs(ctx, 3, arg)
	if err != nil {
		return nil, err
	}
	return strings.ReplaceAll(s[0], s[1], s[2]), nil
}

func keys(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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

func setVideoMode(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	mode, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be the number of the video mode")
	}
	if mode < 0 || mode > 2 {
		return nil, fmt.Errorf("Invalid video mode")
	}
	video(ctx).VideoMode = int(mode)
	return nil, nil
}

func scroll(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	video(ctx).Scroll(i[0], i[1])
	return nil, nil
}

func setPixel(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 3, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).SetPixel(i[0], i[1], uint8(i[2]))
}

func drawText(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	text, ok := arg[4].(string)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a string")
	}
	return nil, video(ctx).DrawText(i[0], i[1], text, uint8(i[2]), uint8(i[3]))
}

func drawFont(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	f, err := floatArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	ch, ok := arg[4].(float64)
	if !ok {
		return nil, fmt.Errorf("Fifth parameter should be a number")
	}
	return nil, video(ctx).DrawFont(int(f[0]), int(f[1]), rune(ch), uint8(f[2]), uint8(f[3]))
}

func drawLine(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).DrawLine(i[0], i[1], i[2], i[3], uint8(i[4]))
}

func drawCircle(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).DrawCircle(i[0], i[1], i[2], uint8(i[3]))
}

func fillCircle(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).FillCircle(i[0], i[1], i[2], uint8(i[3]))
}

func setBackground(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	c, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First parameter should be a number")
	}
	video(ctx).SetBackgroundColor(byte(c))
	return nil, nil
}

func fillRect(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).FillRect(i[0], i[1], i[2], i[3], uint8(i[4]))
}

func drawRect(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).DrawRect(i[0], i[1], i[2], i[3], uint8(i[4]))
}

func getImage(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	return video(ctx).GetImage(i[0], i[1], i[2], i[3])
}

func drawImage(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	img, ok := arg[2].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("Third argument should be an image")
	}
	return nil, video(ctx).DrawImage(i[0], i[1], img, 0, 0, 0)
}

func drawImageRot(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	img, ok := arg[5].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("Fifth argument should be an image")
	}
	return nil, video(ctx).DrawImage(i[0], i[1], img, i[2], i[3], i[4])
}

func getImageWidth(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	img, ok := arg[0].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("First argument should be an image")
	}
	return float64(img["width"].(int)), nil
}

func getImageHeight(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	img, ok := arg[0].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("First argument should be an image")
	}
	return float64(img["height"].(int)), nil
}

func setSprite(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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
	return nil, video(ctx).SetSprite(int(index), imgs)
}

func delSprite(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	index, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return nil, video(ctx).DelSprite(int(index))
}

func drawSprite(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 6, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).DrawSprite(i[0], i[1], i[2], i[3], i[4], i[5])
}

func checkSpriteCollision(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	return video(ctx).CheckSpriteCollision(i[0], i[1])
}

func flood(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	i, err := intArgs(ctx, 3, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).FloodFill(i[0], i[1], uint8(i[2]))
}

func clearVideo(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	return nil, video(ctx).ClearVideo()
}

func updateVideo(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	if video(ctx) == nil {
		panic("Video card not initialized")
	}
	// todo: delay here to achive a requested max framerate (default to 60)
	return nil, video(ctx).UpdateVideo()
}

func toAbs(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	n, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return math.Abs(n), nil
}

func toMax(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	f, err := floatArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	return math.Max(f[0], f[1]), nil
}

func toMin(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	f, err := floatArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	return math.Min(f[0], f[1]), nil
}

func toInt(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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

func toRound(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	n, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	return float64(int(n)), nil
}

func anyKeyDown(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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

func anyNonHelperKeyDown(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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

func isKeyDown(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	key, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be a number")
	}
	// action := video(ctx).Render.Window.GetKey(glfw.Key(key))
	// return (action == glfw.Press || action == glfw.Repeat), nil
	gfx.KeyLock.Lock()
	b := gfx.KeyDown[glfw.Key(key)]
	gfx.KeyLock.Unlock()

	return b, nil
}

func textInput(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	// start capturing input (just capture a single key)
	video(ctx).Render.StartInput <- gfx.INPUT_MODE_CHAR

	// block until input mode is over
	select {
	case char := <-video(ctx).Render.CharInput:
		if char == 9 {
			return "backspace", nil
		} else if char == 27 {
			return "escape", nil
		}
		// stop input mode and return char
		var text strings.Builder
		text.WriteRune(char)
		return strings.TrimSpace(text.String()), nil
	case <-video(ctx).Render.StopInput:
		return nil, nil
	}
}

func fontIndex(ctx *bscript.Context, arg []interface{}) (int, error) {
	// Font *[512][8]uint8
	f, ok := arg[0].(float64)
	if !ok {
		return 0, fmt.Errorf("%s first arg should be a number (%v)", ctx.Pos, arg[0])
	}
	index := int(f)
	if index < 0 || index >= len(video(ctx).Font) {
		return 0, fmt.Errorf("%s index out of bounds - should be 0 to %d", ctx.Pos, len(video(ctx).Font))
	}
	return index, nil
}

func getFont(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	index, err := fontIndex(ctx, arg)
	if err != nil {
		return nil, err
	}
	font := [8]float64{}
	for i, f := range video(ctx).Font[index] {
		font[i] = float64(f)
	}
	return font, nil
}

func setFont(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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
		video(ctx).Font[index][i] = v
	}
	return nil, nil
}

func getColor(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	f, ok := arg[0].(float64)
	if !ok {
		return 0, fmt.Errorf("%s first arg should be a number (%v)", ctx.Pos, arg[0])
	}
	index := int(f)
	if index < 0 || index >= len(video(ctx).Colors) {
		return 0, fmt.Errorf("%s index out of bounds - should be 0 to %d", ctx.Pos, len(video(ctx).Colors))
	}
	return [3]float64{
		float64(video(ctx).Colors[index*3]),
		float64(video(ctx).Colors[index*3+1]),
		float64(video(ctx).Colors[index*3+2]),
	}, nil
}

func setColor(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	index := a[0]
	if index < 0 || index >= len(video(ctx).Colors) {
		return 0, fmt.Errorf("%s index out of bounds - should be 0 to %d", ctx.Pos, len(video(ctx).Colors))
	}
	video(ctx).Colors[index*3] = uint8(a[1])
	video(ctx).Colors[index*3+1] = uint8(a[2])
	video(ctx).Colors[index*3+2] = uint8(a[3])
	return nil, nil
}

func checkFilename(filename string) error {
	if strings.Contains(filename, "/") || strings.Contains(filename, "\\") {
		return fmt.Errorf("Invalid filename: %s", filename)
	}
	return nil
}

func getDir(ctx *bscript.Context, homeDirName string, create bool) (string, error) {
	var dir string
	if homeDirName != "" {
		err := checkFilename(homeDirName)
		if err != nil {
			return "", err
		}
		userHomeDir, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		dir = filepath.Join(userHomeDir, homeDirName)
	} else {
		dir = filepath.Join(*ctx.Sandbox, "files")
	}
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		os.Mkdir(dir, os.ModePerm)
	}
	return dir, nil
}

func saveFile(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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
	homeDirName := ""
	if len(arg) > 2 {
		homeDirName, ok = arg[2].(string)
		if !ok {
			return nil, fmt.Errorf("third param should be a directory name")
		}
	}
	dir, err := getDir(ctx, homeDirName, true)
	if err != nil {
		return nil, err
	}
	return nil, ioutil.WriteFile(filepath.Join(dir, filename), []byte(jsonstr), 0644)
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

func fixArrays(data interface{}) {

	mapdata, ok := data.(map[string]interface{})
	if ok {
		for k, v := range mapdata {
			m, ok := v.(map[string]interface{})
			if ok {
				fixArrays(m)
			}

			arr, ok := v.([]interface{})
			if ok {
				fixArrays(arr)
				mapdata[k] = &arr
			}
		}
	}

	arrdata, ok := data.([]interface{})
	if ok {
		for i, v := range arrdata {
			m, ok := v.(map[string]interface{})
			if ok {
				fixArrays(m)
			}

			arr, ok := v.([]interface{})
			if ok {
				fixArrays(arr)
				arrdata[i] = &arr
			}
		}
	}
}

func rmFile(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	if ctx.Sandbox == nil {
		return nil, fmt.Errorf("Not running in a sandbox")
	}
	filename, ok := arg[0].(string)
	if !ok {
		return nil, fmt.Errorf("First parameter is the filename")
	}

	homeDirName := ""
	if len(arg) > 1 {
		homeDirName, ok = arg[1].(string)
		if !ok {
			return nil, fmt.Errorf("second param should be a directory name")
		}
	}
	dir, err := getDir(ctx, homeDirName, false)
	if err != nil {
		return nil, err
	}

	files, err := filepath.Glob(filepath.Join(dir, filename))
	if err != nil {
		return nil, err
	}
	for _, f := range files {
		_, ff := filepath.Split(f)
		err := checkFilename(ff)
		if err != nil {
			return nil, err
		}
		fmt.Printf("Removing file: %s\n", ff)
		if err := os.Remove(f); err != nil {
			return nil, err
		}
	}
	return nil, nil
}

func loadFile(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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
	homeDirName := ""
	if len(arg) > 1 {
		homeDirName, ok = arg[1].(string)
		if !ok {
			return nil, fmt.Errorf("second param should be a directory name")
		}
	}
	dir, err := getDir(ctx, homeDirName, false)
	if err != nil {
		return nil, err
	}
	bytes, err := ioutil.ReadFile(filepath.Join(dir, filename))
	if err != nil {
		// return nil not error: file missing is not an error
		return nil, nil
	}
	data := map[string]interface{}{}
	err = json.Unmarshal(bytes, &data)
	if err != nil {
		return nil, err
	}
	fixArrays(data)
	fixImages(data)
	return data, nil
}

func addBoundingBox(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	index, err := video(ctx).AddBoundingBox(a[0], a[1], a[2], a[3], a[4])
	return float64(index), err
}

func getBoundingBox(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	x, y, x2, y2, err := video(ctx).GetBoundingBox(a[0], a[1])
	r := make([]interface{}, 4)
	r[0] = float64(x)
	r[1] = float64(y)
	r[2] = float64(x2)
	r[3] = float64(y2)
	return &r, err
}

func delBoundingBox(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 2, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).DelBoundingBox(a[0], a[1])
}

func clearBoundingBoxes(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 1, arg)
	if err != nil {
		return nil, err
	}
	return nil, video(ctx).ClearBoundingBoxes(a[0])
}

func checkBoundingBoxes(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	a, err := intArgs(ctx, 5, arg)
	if err != nil {
		return nil, err
	}
	index, err := video(ctx).CheckBoundingBoxes(a[0], a[1], a[2], a[3], a[4])
	return float64(index), err
}

func clearSound(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	return nil, audio(ctx).Clear(int(playerIndex))
}

func pauseSound(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	enabled, ok := arg[1].(bool)
	if !ok {
		return nil, fmt.Errorf("Second argument should be a boolean")
	}
	return nil, audio(ctx).Pause(int(playerIndex), enabled)
}

func loopSound(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	playerIndex, ok := arg[0].(float64)
	if !ok {
		return nil, fmt.Errorf("First argument should be the player index")
	}
	enabled, ok := arg[1].(bool)
	if !ok {
		return nil, fmt.Errorf("Second argument should be a boolean")
	}
	return nil, audio(ctx).Loop(int(playerIndex), enabled)
}

func playSound(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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
	return nil, audio(ctx).Play(int(playerIndex), freq, duration)
}

func typeof(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	if arg[0] == nil {
		return "null", nil
	}
	_, ok := arg[0].(float64)
	if ok {
		return "number", nil
	}
	_, ok = arg[0].(string)
	if ok {
		return "string", nil
	}
	_, ok = arg[0].(bool)
	if ok {
		return "boolean", nil
	}
	_, ok = arg[0].(*bscript.Closure)
	if ok {
		return "function", nil
	}
	_, ok = arg[0].(map[string]interface{})
	if ok {
		return "map", nil
	}
	_, ok = arg[0].(*[]interface{})
	if ok {
		return "array", nil
	}
	return nil, fmt.Errorf("%s Unknown variable type", ctx.Pos)
}

func distance(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	pos, err := floatArgs(ctx, 4, arg)
	if err != nil {
		return nil, err
	}
	ax := pos[0]
	ay := pos[1]
	bx := pos[2]
	by := pos[3]
	return math.Sqrt(((bx - ax) * (bx - ax)) + ((by - ay) * (by - ay))), nil
}

func exit(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
	os.Exit(0)
	return nil, nil
}

func assert(ctx *bscript.Context, arg ...interface{}) (interface{}, error) {
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
		fmt.Println(ctx, fmt.Sprintf("Assertion failure: %s: %v != %v\n", msg, a, b))
		return nil, fmt.Errorf("%s Assertion failure: %s: %v != %v", ctx.Pos, msg, a, b)
	}
	return nil, nil
}

func Builtins() map[string]bscript.Builtin {
	return map[string]bscript.Builtin{
		"print":                print,
		"input":                input,
		"textInput":            textInput,
		"len":                  length,
		"keys":                 keys,
		"substr":               substr,
		"split":                split,
		"replace":              replace,
		"assert":               assert,
		"setVideoMode":         setVideoMode,
		"setPixel":             setPixel,
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
		"min":                  toMin,
		"max":                  toMax,
		"getFont":              getFont,
		"setFont":              setFont,
		"getColor":             getColor,
		"setColor":             setColor,
		"getImage":             getImage,
		"drawImage":            drawImage,
		"drawImageRot":         drawImageRot,
		"getImageWidth":        getImageWidth,
		"getImageHeight":       getImageHeight,
		"setSprite":            setSprite,
		"drawSprite":           drawSprite,
		"flood":                flood,
		"anyKeyDown":           anyKeyDown,
		"anyNonHelperKeyDown":  anyNonHelperKeyDown,
		"save":                 saveFile,
		"load":                 loadFile,
		"erase":                rmFile,
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
		"limitFps":             limitFps,
		"sleep":                sleep,
		"typeof":               typeof,
		"exit":                 exit,
		"distance":             distance,
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
