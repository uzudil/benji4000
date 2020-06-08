package sound

import (
	"fmt"
	"io"
	"math"
	"time"

	"github.com/hajimehoshi/oto"
)

const (
	sampleRate      = 44100
	channelNum      = 2
	bitDepthInBytes = 2
)

type SineWave struct {
	freq   float64
	length int64
	pos    int64

	remaining []byte
}

const playerCount = 4

type Render struct {
	Context *oto.Context
	Sounds  []chan *SineWave
}

func NewRender() (*Render, error) {
	context, err := oto.NewContext(sampleRate, channelNum, bitDepthInBytes, 4096)
	if err != nil {
		return nil, err
	}
	c := make([]chan *SineWave, playerCount)
	for i := 0; i < len(c); i++ {
		c[i] = make(chan *SineWave, 100)
		go playSounds(context, c[i])
	}
	return &Render{
		Context: context,
		Sounds:  c,
	}, nil
}

func playSounds(context *oto.Context, c chan *SineWave) error {
	for {
		s := <-c
		p := context.NewPlayer()
		if _, err := io.Copy(p, s); err != nil {
			fmt.Printf("Error copying: %v\n", err)
			return err
		}
		if err := p.Close(); err != nil {
			fmt.Printf("Error closing: %v\n", err)
			return err
		}
	}
	return nil
}

func (render *Render) Play(playerIndex int, freq float64, duration time.Duration) error {
	render.Sounds[playerIndex] <- newSineWave(freq, duration)
	return nil
}

func newSineWave(freq float64, duration time.Duration) *SineWave {
	l := int64(channelNum) * int64(bitDepthInBytes) * int64(sampleRate) * int64(duration) / int64(time.Second)
	l = l / 4 * 4
	return &SineWave{
		freq:   freq,
		length: l,
	}
}

func (s *SineWave) Read(buf []byte) (int, error) {
	if len(s.remaining) > 0 {
		n := copy(buf, s.remaining)
		s.remaining = s.remaining[n:]
		return n, nil
	}

	if s.pos == s.length {
		return 0, io.EOF
	}

	eof := false
	if s.pos+int64(len(buf)) > s.length {
		buf = buf[:s.length-s.pos]
		eof = true
	}

	var origBuf []byte
	if len(buf)%4 > 0 {
		origBuf = buf
		buf = make([]byte, len(origBuf)+4-len(origBuf)%4)
	}

	length := float64(sampleRate) / float64(s.freq)

	num := (bitDepthInBytes) * (channelNum)
	p := s.pos / int64(num)
	switch bitDepthInBytes {
	case 1:
		for i := 0; i < len(buf)/num; i++ {
			const max = 127
			b := int(math.Sin(2*math.Pi*float64(p)/length) * 0.3 * max)
			for ch := 0; ch < channelNum; ch++ {
				buf[num*i+ch] = byte(b + 128)
			}
			p++
		}
	case 2:
		for i := 0; i < len(buf)/num; i++ {
			const max = 32767
			b := int16(math.Sin(2*math.Pi*float64(p)/length) * 0.3 * max)
			for ch := 0; ch < channelNum; ch++ {
				buf[num*i+2*ch] = byte(b)
				buf[num*i+1+2*ch] = byte(b >> 8)
			}
			p++
		}
	}

	s.pos += int64(len(buf))

	n := len(buf)
	if origBuf != nil {
		n = copy(origBuf, buf)
		s.remaining = buf[n:]
	}

	if eof {
		return n, io.EOF
	}
	return n, nil
}

// func run() error {
// 	const (
// 		freqC = 523.3
// 		freqE = 659.3
// 		freqG = 784.0
// 	)

// 	c, err := oto.NewContext(sampleRate, channelNum, bitDepthInBytes, 4096)
// 	if err != nil {
// 		return err
// 	}

// 	var wg sync.WaitGroup

// 	wg.Add(1)
// 	go func() {
// 		defer wg.Done()
// 		if err := play(c, freqC, 3*time.Second); err != nil {
// 			panic(err)
// 		}
// 	}()

// 	wg.Add(1)
// 	go func() {
// 		defer wg.Done()
// 		time.Sleep(1 * time.Second)
// 		if err := play(c, freqE, 3*time.Second); err != nil {
// 			panic(err)
// 		}
// 	}()

// 	wg.Add(1)
// 	go func() {
// 		defer wg.Done()
// 		time.Sleep(2 * time.Second)
// 		if err := play(c, freqG, 3*time.Second); err != nil {
// 			panic(err)
// 		}
// 	}()

// 	wg.Wait()
// 	c.Close()
// 	return nil
// }
