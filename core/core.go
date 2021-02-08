package core

import (
	"os"

	"github.com/uzudil/benji4000/gfx"
	"github.com/uzudil/benji4000/sound"
	"github.com/uzudil/bscript/bscript"
)

func Run(source string, scale int, fullscreen, nosound, showAst *bool) {
	video := gfx.NewGfx(scale, *fullscreen)
	sound := sound.NewSound(*nosound)
	app := map[string]interface{}{
		"video": video,
		"sound": sound,
	}
	for k, v := range Builtins() {
		bscript.AddBuiltin(k, v)
	}
	for k, v := range Constants() {
		bscript.AddConstant(k, v)
	}
	if source != "" {
		go func() {
			bscript.Run(source, showAst, nil, app)
			os.Exit(0)
		}()
	} else {
		go func() {
			bscript.Repl(app)
			os.Exit(0)
		}()
	}

	video.Render.MainLoop()
}
