package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/uzudil/benji4000/bscript"
	"github.com/uzudil/benji4000/gfx"
	"github.com/uzudil/benji4000/sound"
)

func repl(video *gfx.Gfx, sound *sound.Sound) {
	bscript.Repl(video, sound)
}

func main() {
	var source string
	flag.StringVar(&source, "source", "", "the bscript file to run")

	showAst := flag.Bool("ast", false, "print AST and not execute?")

	fullscreen := flag.Bool("fullscreen", false, "Run at fullscreen")

	var scale int
	flag.IntVar(&scale, "scale", 2, "Image scale factor")

	flag.Parse()

	video := gfx.NewGfx(scale, *fullscreen)
	sound := sound.NewSound()

	if source != "" {
		go func() {
			_, err := bscript.Run(source, showAst, nil, video, sound)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
			}
			os.Exit(0)
		}()
	} else {
		go repl(video, sound)
	}

	video.Render.MainLoop()
}
