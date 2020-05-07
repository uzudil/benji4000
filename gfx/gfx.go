package gfx

import (
	"fmt"
	"math"
)

const (
	Width  = 320
	Height = 200

	// GfxTextMode is a 40x25 char text mode, 16 color background, 16 color foreground
	GfxTextMode = 0

	// GfxHiresMode is a 320x200 pixels, 1 background color, each 8x8 block 16 colors graphics mode
	GfxHiresMode = 1

	// GfxMultiColorMode is a 160x200 pixels (double wide) 16 colors graphics mode
	GfxMultiColorMode = 2
)

type Cursor struct {
	X, Y   int
	Fg, Bg uint8
	Gfx    *Gfx
}

// Gfx is the "video card" api
type Gfx struct {
	// the video mode
	VideoMode int
	// video memory
	VideoMemory [Width * Height]byte
	// text memory
	TextMemory [Width / 8 * Height / 8]int32
	// the actual renderer
	Render *Render
	// Color definitions
	Colors [16 * 3]uint8
	// the global background color
	BackgroundColor byte
	// font memory
	Font *[512][8]uint8
	// the cursor in interactive mode
	Cursor *Cursor
}

const (
	COLOR_BLACK       = 0
	COLOR_WHITE       = 1
	COLOR_RED         = 2
	COLOR_TEAL        = 3
	COLOR_PURPLE      = 4
	COLOR_GREEN       = 5
	COLOR_DARK_BLUE   = 6
	COLOR_YELLOW      = 7
	COLOR_BROWN       = 8
	COLOR_DARK_BROWN  = 9
	COLOR_TAN         = 10
	COLOR_DARK_GRAY   = 11
	COLOR_MID_GRAY    = 12
	COLOR_LIGHT_GREEN = 13
	COLOR_LIGHT_BLUE  = 14
	COLOR_LIGHT_GRAY  = 15
)

const CURSOR_FONT = 128 + 3

// NewGfx lets you create a new Gfx video card
func NewGfx(scale int, fullscreen bool) *Gfx {
	videoMemory := [Width * Height]byte{}
	for i := range videoMemory {
		videoMemory[i] = COLOR_LIGHT_BLUE
	}
	gfx := &Gfx{
		VideoMode:   GfxTextMode,
		VideoMemory: videoMemory,
		TextMemory:  [Width / 8 * Height / 8]int32{},
		Render:      NewRender(scale, fullscreen),
		Colors: [16 * 3]uint8{
			// C64 colors :-)
			0x00, 0x00, 0x00,
			0xff, 0xff, 0xff,
			0x88, 0x20, 0x00,
			0x68, 0xd0, 0xa8,
			0xa8, 0x38, 0xa0,
			0x50, 0xb8, 0x18,
			0x18, 0x10, 0x90,
			0xf0, 0xe8, 0x58,
			0xa0, 0x48, 0x00,
			0x47, 0x2b, 0x1b,
			0xc8, 0x78, 0x70,
			0x48, 0x48, 0x48,
			0x80, 0x80, 0x80,
			0x98, 0xff, 0x98,
			0x50, 0x90, 0xd0,
			0xb8, 0xb8, 0xb8,
		},
		BackgroundColor: COLOR_LIGHT_BLUE,
		Font:            &Font8x8,
		Cursor: &Cursor{
			X:  0,
			Y:  0,
			Fg: COLOR_DARK_BLUE,
			Bg: COLOR_LIGHT_BLUE,
		},
	}
	gfx.Cursor.Gfx = gfx
	return gfx
}

func (gfx *Gfx) DrawCircle(x, y, r int, fg uint8) error {
	return gfx.circle(x, y, r, fg, false)
}

func (gfx *Gfx) FillCircle(x, y, r int, fg uint8) error {
	return gfx.circle(x, y, r, fg, true)
}

// 90 degrees in radians
const rad90 = 0.5 * math.Pi

// there is probably a more efficient way to do this
func (gfx *Gfx) circle(x, y, r int, fg uint8, filled bool) error {
	var px, py float64
	circleSteps := int(math.Min(float64(r*2), 100))
	for a := 0; a <= circleSteps; a++ {
		rad := (float64(a) / float64(circleSteps)) * rad90
		dx := float64(r) * math.Cos(rad)
		dy := float64(r) * math.Sin(rad)
		if filled {
			gfx.FillRect(int(float64(x)+dx), int(float64(y)+dy), int(float64(x)+px), int(float64(y)-dy), fg)
			gfx.FillRect(int(float64(x)-px), int(float64(y)+dy), int(float64(x)-dx), int(float64(y)-dy), fg)
		} else if !(px == 0 && py == 0) {
			gfx.DrawLine(int(float64(x)+dx), int(float64(y)+dy), int(float64(x)+px), int(float64(y)+py), fg)
			gfx.DrawLine(int(float64(x)-dx), int(float64(y)+dy), int(float64(x)-px), int(float64(y)+py), fg)
			gfx.DrawLine(int(float64(x)-dx), int(float64(y)-dy), int(float64(x)-px), int(float64(y)-py), fg)
			gfx.DrawLine(int(float64(x)+dx), int(float64(y)-dy), int(float64(x)+px), int(float64(y)-py), fg)
		}
		px = dx
		py = dy
	}
	return nil
}

func (gfx *Gfx) DrawRect(x, y, x2, y2 int, fg uint8) error {
	gfx.DrawLine(x, y, x2, y, fg)
	gfx.DrawLine(x, y2, x2, y2, fg)
	gfx.DrawLine(x, y, x, y2, fg)
	gfx.DrawLine(x2, y, x2, y2, fg)
	return nil
}

func (gfx *Gfx) FillRect(x, y, x2, y2 int, fg uint8) error {
	dx := 1
	if x > x2 {
		dx = -1
	}
	dy := 1
	if y > y2 {
		dy = -1
	}
	for xx := x; xx != x2; xx += dx {
		for yy := y; yy != y2; yy += dy {
			gfx.SetPixel(xx, yy, fg)
		}
	}
	return nil
}

func (gfx *Gfx) DrawLine(x, y, x2, y2 int, fg uint8) error {
	sx := float64(x)
	sy := float64(y)
	ex := float64(x2)
	ey := float64(y2)

	if math.Abs(float64(x)-float64(x2)) > math.Abs(float64(y)-float64(y2)) {
		// walk along x
		if x > x2 {
			sx, ex = ex, sx
			sy, ey = ey, sy
		}
		dy := (ey - sy) / (ex - sx)
		yy := sy
		for xx := sx; xx <= ex; xx++ {
			gfx.SetPixel(int(xx), int(yy), fg)
			yy += dy
		}
	} else {
		// walk along y
		if y > y2 {
			sy, ey = ey, sy
			sx, ex = ex, sx
		}
		dx := (ex - sx) / (ey - sy)
		xx := sx
		for yy := sy; yy <= ey; yy++ {
			gfx.SetPixel(int(xx), int(yy), fg)
			xx += dx
		}
	}

	return nil
}

func (gfx *Gfx) DrawText(x, y int, text string, fg, bg uint8) error {
	step := 8
	if gfx.VideoMode == GfxTextMode {
		step = 1
	}
	for index, ch := range text {
		gfx.DrawFont(x+index*step, y, ch, fg, bg)
	}
	return nil
}

func (gfx *Gfx) DrawFont(x, y int, ch rune, fg, bg uint8) error {
	if gfx.VideoMode == GfxTextMode {
		if x >= 0 && y >= 0 && x < Width/8 && y < Height/8 && ch >= 0 {
			gfx.TextMemory[y*40+x] = ch
		}
	}
	for row := 0; row < 8; row++ {
		symbolRow := (*gfx.Font)[ch][row]
		for bit := 0; bit < 8; bit++ {
			color := bg
			if (symbolRow>>bit)&1 == 1 {
				color = fg
			}
			if gfx.VideoMode == GfxTextMode {
				px := x*8 + bit
				py := y*8 + row
				if px >= 0 && py >= 0 && px < Width && py < Height {
					gfx.VideoMemory[py*Width+px] = color
				}
			} else {
				gfx.SetPixel(x+bit, y+row, color)
			}
		}
	}
	return nil
}

func (gfx *Gfx) SetPixel(x, y int, fg uint8) error {
	switch {
	case gfx.VideoMode == GfxTextMode:
		// do nothing
	case gfx.VideoMode == GfxHiresMode:
		if x >= 0 && y >= 0 && x < Width && y < Height {
			// set the pixel asked for
			gfx.VideoMemory[y*Width+x] = byte(fg)

			if fg != gfx.BackgroundColor {
				// set other pixels (if >0) in this 8x8 area
				bx := (x / 8) * 8
				by := (y / 8) * 8
				for xx := 0; xx < 8; xx++ {
					for yy := 0; yy < 8; yy++ {
						addr := (by+yy)*Width + (bx + xx)
						if gfx.VideoMemory[addr] != gfx.BackgroundColor {
							gfx.VideoMemory[addr] = byte(fg)
						}
					}
				}
			}
		}
	case gfx.VideoMode == GfxMultiColorMode:
		if x >= 0 && y >= 0 && x < Width/2 && y < Height {
			gfx.VideoMemory[y*Width+x*2] = byte(fg)
			gfx.VideoMemory[y*Width+x*2+1] = byte(fg)
		}
	}
	return nil
}

func (gfx *Gfx) Println(message string, printNewLine bool) error {
	for _, r := range message {
		err := gfx.DrawFont(gfx.Cursor.X, gfx.Cursor.Y, r, gfx.Cursor.Fg, gfx.Cursor.Bg)
		if err != nil {
			return err
		}
		gfx.Cursor.X++
		if gfx.Cursor.X > Width/8 {
			gfx.Cursor.NewLine()
		}
	}
	if printNewLine {
		gfx.Cursor.NewLine()
	}
	return gfx.Cursor.draw(true)
}

func (gfx *Gfx) Backspace() error {
	if gfx.Cursor.X > 0 {
		gfx.Cursor.draw(false)
		gfx.Cursor.X--
		gfx.Cursor.draw(true)
		return nil
	}
	return fmt.Errorf("can't backspace")
}

func (cursor *Cursor) draw(enabled bool) error {
	if enabled {
		cursor.Gfx.DrawFont(cursor.X, cursor.Y, CURSOR_FONT, cursor.Fg, cursor.Bg)
	} else {
		cursor.Gfx.DrawFont(cursor.X, cursor.Y, 0, cursor.Fg, cursor.Bg)
	}
	return nil
}

func (cursor *Cursor) NewLine() {
	// erase the cursor
	cursor.draw(false)

	// newline
	cursor.Y++
	cursor.X = 0

	// scroll screen if needed
	if cursor.Y == Height/8 {
		cursor.Y--
		cursor.Gfx.Scroll(0, -8)
	}
}

func (gfx *Gfx) GetImage(x, y, x2, y2 int) (map[string]interface{}, error) {
	w := x2 - x
	h := y2 - y
	data := make([]byte, w*h)
	img := map[string]interface{}{
		"width":  w,
		"height": h,
		"data":   data,
	}
	if gfx.VideoMode == GfxHiresMode {
		for yy := y; yy < y2; yy++ {
			copy(data[(yy-y)*w:], gfx.VideoMemory[yy*Width+x:yy*Width+x2])
		}
	} else if gfx.VideoMode == GfxMultiColorMode {
		index := 0
		for yy := y; yy < y2; yy++ {
			for xx := x * 2; xx < x2*2; xx += 2 {
				data[index] = gfx.VideoMemory[yy*Width+xx]
				index++
			}
		}
	} else {
		return nil, fmt.Errorf("Only use in pixel modes")
	}

	return img, nil
}

func (gfx *Gfx) DrawImage(x, y int, img map[string]interface{}) error {
	w := img["width"].(int)
	h := img["height"].(int)
	data := img["data"].([]byte)
	if gfx.VideoMode == GfxHiresMode {
		for yy := 0; yy < h; yy++ {
			copy(gfx.VideoMemory[(y+yy)*Width+x:], data[yy*w:(yy+1)*w])
		}
	} else if gfx.VideoMode == GfxMultiColorMode {
		index := 0
		for yy := 0; yy < h; yy++ {
			for xx := 0; xx < w; xx++ {
				gfx.SetPixel(x+xx, y+yy, data[index])
				index++
			}
		}
	} else {
		return fmt.Errorf("Only use in pixel modes")
	}
	return nil
}

func (gfx *Gfx) SetSprite(index int, imgs []map[string]interface{}) error {
	img := imgs[0]
	w := img["width"].(int)
	if gfx.VideoMode == GfxMultiColorMode {
		w *= 2
	}
	h := img["height"].(int)

	pixelList := make([][]byte, len(imgs))

	for i, img := range imgs {
		data := img["data"].([]byte)
		pixels := make([]byte, w*h*3)
		if gfx.VideoMode == GfxHiresMode {
			for i := 0; i < len(data); i++ {
				idx := i * 3
				pixels[idx] = gfx.Colors[data[i]*3]
				pixels[idx+1] = gfx.Colors[data[i]*3+1]
				pixels[idx+2] = gfx.Colors[data[i]*3+2]
			}
		} else if gfx.VideoMode == GfxMultiColorMode {
			for i := 0; i < len(data); i++ {
				idx := i * 2 * 3
				pixels[idx] = gfx.Colors[data[i]*3]
				pixels[idx+1] = gfx.Colors[data[i]*3+1]
				pixels[idx+2] = gfx.Colors[data[i]*3+2]
				idx = ((i * 2) + 1) * 3
				pixels[idx] = gfx.Colors[data[i]*3]
				pixels[idx+1] = gfx.Colors[data[i]*3+1]
				pixels[idx+2] = gfx.Colors[data[i]*3+2]
			}
		} else {
			return fmt.Errorf("Not available in text mode")
		}
		pixelList[i] = pixels
	}

	gfx.Render.SpriteChannel <- SpriteCommand{
		Command: "new",
		Index:   index,
		W:       w,
		H:       h,
		Pixels:  pixelList,
	}
	return nil
}

func (gfx *Gfx) DrawSprite(x, y, index, imgIndex int) error {
	gfx.Render.SpriteLock.Lock()
	if gfx.VideoMode == GfxMultiColorMode {
		x *= 2
	}
	gfx.Render.Sprites[index].X = int32(x)
	gfx.Render.Sprites[index].Y = int32(y)
	gfx.Render.Sprites[index].ImageIndex = int32(imgIndex)
	gfx.Render.SpriteLock.Unlock()
	return nil
}

func (gfx *Gfx) Scroll(dx, dy int) error {
	if dy > 0 {
		offset := dy * Width
		copy(gfx.VideoMemory[offset:], gfx.VideoMemory[0:Width*Height-offset])
		for y := 0; y < dy; y++ {
			for x := 0; x < Width; x++ {
				gfx.VideoMemory[y*Width+x] = gfx.BackgroundColor
			}
		}
	} else if dy < 0 {
		offset := -dy * Width
		copy(gfx.VideoMemory[:], gfx.VideoMemory[offset:Width*Height])
		offset = (Height + dy) * Width
		for y := 0; y < -dy; y++ {
			for x := 0; x < Width; x++ {
				gfx.VideoMemory[offset+y*Width+x] = gfx.BackgroundColor
			}
		}
	}
	if gfx.VideoMode == GfxMultiColorMode {
		dx *= 2
	}
	if dx > 0 {
		for y := 0; y < Height; y++ {
			offset := y * Width
			copy(gfx.VideoMemory[offset+dx:], gfx.VideoMemory[offset:offset+Width-dx])
		}
		for y := 0; y < Height; y++ {
			for x := 0; x < dx; x++ {
				gfx.VideoMemory[y*Width+x] = gfx.BackgroundColor
			}
		}
	} else if dx < 0 {
		for y := 0; y < Height; y++ {
			offset := y * Width
			copy(gfx.VideoMemory[offset:], gfx.VideoMemory[offset-dx:offset+Width])
		}
		for y := 0; y < Height; y++ {
			for x := 0; x < -dx; x++ {
				gfx.VideoMemory[y*Width+Width-1-x] = byte(gfx.BackgroundColor)
			}
		}
	}

	// todo: also move TextMemory around

	return nil
}

func (gfx *Gfx) ClearVideo() error {
	for i := range gfx.VideoMemory {
		gfx.VideoMemory[i] = byte(gfx.BackgroundColor)
	}
	for i := range gfx.TextMemory {
		gfx.TextMemory[i] = 0
	}
	return nil
}

func (gfx *Gfx) UpdateVideo() error {
	gfx.Render.Lock.Lock()
	for index, colorIndex := range gfx.VideoMemory {
		gfx.Render.PixelMemory[index*3] = gfx.Colors[colorIndex*3]
		gfx.Render.PixelMemory[index*3+1] = gfx.Colors[colorIndex*3+1]
		gfx.Render.PixelMemory[index*3+2] = gfx.Colors[colorIndex*3+2]
	}
	gfx.Render.Lock.Unlock()
	// runtime.Gosched()
	return nil
}
