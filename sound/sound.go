package sound

import (
	"fmt"
	"math"
)

const sampleRate = 44100.0

type Sound struct {
	Render *Render
}

func NewSound() *Sound {
	render, err := NewRender()
	if err != nil {
		fmt.Printf("Sound could not be initialized: %s\n", err)
	}
	return &Sound{
		Render: render,
	}
}

func (sound *Sound) MakeSample(freqs, durations []float64) (uint32, error) {
	if sound.Render == nil {
		// no sound, no problem
		return 0, nil
	}
	var seconds float64
	for _, d := range durations {
		seconds += d
	}
	fmt.Printf("Creating sample for %.2f seconds\n", seconds)

	// allocate PCM audio buffer
	samples := make([]byte, int(seconds*sampleRate))
	index := 0
	stepEnd := durations[0]
	for i := 0; i < len(samples); i++ {
		freq := freqs[index]
		samples[i] = byte(128.0 * math.Sin((2.0*math.Pi*freq)/float64(sampleRate)*float64(i)))
		if float64(i)/sampleRate > stepEnd {
			index++
			stepEnd += durations[index]
		}
	}

	// todo: should this happen via a channel?
	return sound.Render.BufferSample(samples, int32(sampleRate))
}

func (sound *Sound) PlaySample(channel int, sample uint32) error {
	if sound.Render == nil {
		// no sound, no problem
		return nil
	}

	// todo: should this happen via a channel?
	return sound.Render.RenderSample(channel, sample)
}
