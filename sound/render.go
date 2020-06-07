package sound

import (
	"golang.org/x/mobile/exp/audio/al"
)

type Render struct {
	Sources []al.Source
}

func NewRender() (*Render, error) {
	err := al.OpenDevice()
	if err != nil {
		return nil, err
	}

	sources := al.GenSources(4)
	for _, source := range sources {
		source.SetGain(1)
		pos := al.Vector{0, 0, 0}
		source.SetPosition(pos)
		source.SetVelocity(pos)
	}

	return &Render{
		Sources: sources,
	}, nil
}

func (render *Render) BufferSample(sample []byte, sampleRate int32) (uint32, error) {
	buffers := al.GenBuffers(1)
	buffer := buffers[0]
	buffer.BufferData(al.FormatMono8, sample, sampleRate)
	return uint32(buffer), nil
}

func (render *Render) RenderSample(sourceIndex int, buffer uint32) error {
	render.Sources[sourceIndex].QueueBuffers(al.Buffer(buffer))
	al.PlaySources(render.Sources...)
	return nil
}
