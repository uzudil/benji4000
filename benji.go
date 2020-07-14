package main

import (
	"flag"
	"os"

	"github.com/uzudil/benji4000/bscript"
	"github.com/uzudil/benji4000/gfx"
	"github.com/uzudil/benji4000/sound"
)

func repl(video *gfx.Gfx, sound *sound.Sound) {
	bscript.Repl(video, sound)
}

func run(source string, scale int, fullscreen, nosound, showAst *bool) {
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

func main() {
	var source string
	flag.StringVar(&source, "source", "", "the bscript file to run")
	showAst := flag.Bool("ast", false, "print AST and not execute?")
	fullscreen := flag.Bool("fullscreen", false, "Run at fullscreen")
	nosound := flag.Bool("nosound", false, "Run without sound")

	var scale int
	flag.IntVar(&scale, "scale", 2, "Image scale factor")
	flag.Parse()

	run(source, scale, fullscreen, nosound, showAst)
}
