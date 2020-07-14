package sound

import (
	"fmt"
	"time"
)

type Sound struct {
	Render *Render
}

func NewSound(nosound bool) *Sound {
	var render *Render
	var err error
	if nosound == false {
		render, err = NewRender()
		if err != nil {
			fmt.Printf("Sound could not be initialized: %s\n", err)
		}
	}
	return &Sound{
		Render: render,
	}
}

func (sound *Sound) Clear(playerIndex int) error {
	if sound.Render == nil {
		return nil
	}
	return sound.Render.Clear(playerIndex)
}

func (sound *Sound) Pause(playerIndex int, enabled bool) error {
	if sound.Render == nil {
		return nil
	}
	return sound.Render.Pause(playerIndex, enabled)
}

func (sound *Sound) Loop(playerIndex int, enabled bool) error {
	if sound.Render == nil {
		return nil
	}
	return sound.Render.Loop(playerIndex, enabled)
}

func (sound *Sound) Play(playerIndex int, freq, duration float64) error {
	if sound.Render == nil {
		return nil
	}
	// todo: send this via a channel?
	return sound.Render.Play(playerIndex, freq, time.Duration(1000.0*duration)*time.Millisecond)
}
