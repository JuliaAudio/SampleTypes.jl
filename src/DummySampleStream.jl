type DummySampleSource{T <: Real} <: SampleSource{T}
    buf::Array{T, 2}
    samplerate::SampleRate
end

DummySampleSource(samplerate, buf) = DummySampleSource{eltype(buf)}(buf, samplerate)

samplerate(source::DummySampleSource) = source.samplerate
nchannels(source::DummySampleSource) = size(source.buf, 2)

type DummySampleSink{T <: Real} <: SampleSink{T}
    buf::Array{T, 2}
    samplerate::SampleRate
end

DummySampleSink(T, SR, N) = DummySampleSink{T}(Array(T, 0, N), SR)

samplerate(sink::DummySampleSink) = sink.samplerate
nchannels(sink::DummySampleSink) = size(sink.buf, 2)

# """
# Simulate receiving input on the dummy source This adds data to the internal
# buffer, so that when client code reads from the source they receive this data.
# """
# function simulate_input{N, SR, T}(src::DummySampleSource{N, SR, T}, data::Array{T})
#     if size(data, 2) != N
#         error("Simulated data channel count must match stream input count")
#     end
#     src.buf = vcat(src.buf, data)
# end

# stream interface methods

"""
Writes the sample buffer to the sample sink. If no other writes have been
queued the Sample will be played immediately. If a previously-written buffer is
in progress the signal will be queued. To mix multiple signal see the `play`
function. Currently we only implement the non-resampling, non-converting method.
"""
function unsafe_write(sink::DummySampleSink, buf::TimeSampleBuf)
    sink.buf = vcat(sink.buf, buf.data)

    nframes(buf)
end

"""
Fills the given buffer with the data from the stream. If there aren't enough
frames in the stream then it's considered to be at its end and will only
partally fill the buffer.
"""
function unsafe_read!(src::DummySampleSource, buf::TimeSampleBuf)
    n = min(nframes(buf), size(src.buf, 1))
    buf.data[1:n, :] = src.buf[1:n, :]
    src.buf = src.buf[(n+1):end, :]

    n
end
