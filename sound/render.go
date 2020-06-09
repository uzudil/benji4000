package sound

import (
	"math"
	"sync"
	"time"

	"github.com/faiface/beep"
	"github.com/faiface/beep/speaker"
)

const (
	sampleRate      = 44100
	channelNum      = 2
	bitDepthInBytes = 2
	playerCount     = 4
	bufferSize      = 1024
)

type Render struct {
	Channels []*AudioChannel
}

type AudioChannel struct {
	freq     []float64
	duration []int64
	index    int
	pos      int64
	err      error
	Lock     sync.Mutex
}

func (audio *AudioChannel) Stream(samples [][2]float64) (n int, ok bool) {
	audio.Lock.Lock()
	for sampleIndex := 0; sampleIndex < len(samples); sampleIndex++ {
		if audio.index >= len(audio.freq) {
			samples[sampleIndex][0] = 0
			samples[sampleIndex][1] = 0
		} else {
			f := audio.freq[audio.index]
			val := math.Sin(2*math.Pi*float64(audio.pos)*f/float64(sampleRate)) * 0.3
			samples[sampleIndex][0] = val
			samples[sampleIndex][1] = val
			audio.pos++
			if audio.pos >= audio.duration[audio.index] {
				audio.index++
				audio.pos = 0
			}
		}
	}
	audio.Lock.Unlock()
	return len(samples), true
}

func (audio *AudioChannel) Err() error {
	return audio.err
}

func NewRender() (*Render, error) {
	sr := beep.SampleRate(sampleRate)
	speaker.Init(sr, sr.N(time.Second/10))
	channels := make([]*AudioChannel, playerCount)
	for i := 0; i < len(channels); i++ {
		channels[i] = &AudioChannel{
			Lock: sync.Mutex{},
		}
		speaker.Play(channels[i])
	}
	return &Render{
		Channels: channels,
	}, nil
}

func (render *Render) Clear(playerIndex int) error {
	audio := render.Channels[playerIndex]
	audio.Lock.Lock()
	audio.freq = []float64{}
	audio.duration = []int64{}
	audio.Lock.Unlock()
	return nil
}

func (render *Render) Play(playerIndex int, freq float64, duration time.Duration) error {
	audio := render.Channels[playerIndex]
	audio.Lock.Lock()

	// clear out finished notes
	if audio.index > 0 {
		audio.freq = audio.freq[audio.index:]
		audio.duration = audio.duration[audio.index:]
		audio.index = 0
	}

	// add new notes
	audio.freq = append(audio.freq, freq)
	audio.duration = append(audio.duration, int64(duration*sampleRate)/int64(time.Second))

	audio.Lock.Unlock()
	return nil
}
