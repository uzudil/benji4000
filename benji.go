package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/uzudil/benji4000/bscript"
	"github.com/uzudil/benji4000/gfx"
)

func repl(video *gfx.Gfx) {
	bscript.Repl(video)
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

	if source != "" {
		go func() {
			_, err := bscript.Run(source, showAst, nil, video)
			if err != nil {
				fmt.Printf("Error: %v\n", err)
			}
			os.Exit(0)
		}()
	} else {
		go repl(video)
	}

	video.Render.MainLoop()
}
