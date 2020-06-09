package sound

import (
	"math"
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

type SineWave struct {
	freq   float64
	length int64
	pos    int64

	remaining []byte
}

type Render struct {
	Channels []*AudioChannel
}

type AudioChannel struct {
	freq     []float64
	duration []int64
	index    int
	pos      int64
	err      error
}

func (audio *AudioChannel) Stream(samples [][2]float64) (n int, ok bool) {
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
		channels[i] = &AudioChannel{}
		speaker.Play(channels[i])
	}
	return &Render{
		Channels: channels,
	}, nil
}

func (render *Render) Play(playerIndex int, freq float64, duration time.Duration) error {
	audio := render.Channels[playerIndex]
	audio.freq = append(audio.freq, freq)
	audio.duration = append(audio.duration, int64(duration*sampleRate)/int64(time.Second))
	return nil
}
