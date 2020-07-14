package main

import (
	"flag"

	"github.com/uzudil/benji4000/core"
)

func main() {
	var source string
	flag.StringVar(&source, "source", "", "the bscript file to run")
	showAst := flag.Bool("ast", false, "print AST and not execute?")
	fullscreen := flag.Bool("fullscreen", false, "Run at fullscreen")
	nosound := flag.Bool("nosound", false, "Run without sound")

	var scale int
	flag.IntVar(&scale, "scale", 2, "Image scale factor")
	flag.Parse()

	core.Run(source, scale, fullscreen, nosound, showAst)
}
