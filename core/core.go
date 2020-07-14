package core

import (
	"os"

	"github.com/uzudil/benji4000/bscript"
	"github.com/uzudil/benji4000/gfx"
	"github.com/uzudil/benji4000/sound"
)

func repl(video *gfx.Gfx, sound *sound.Sound) {
	bscript.Repl(video, sound)
}

func Run(source string, scale int, fullscreen, nosound, showAst *bool) {
	video := gfx.NewGfx(scale, *fullscreen)
	sound := sound.NewSound(*nosound)
	if source != "" {
		go func() {
			bscript.Run(source, showAst, nil, video, sound)
			os.Exit(0)
		}()
	} else {
		go repl(video, sound)
	}

	video.Render.MainLoop()
}
