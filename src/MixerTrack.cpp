#include "../include/MixerTrack.hpp"

MixerTrack::MixerTrack()
    : volume(1.0f),
      muted(false)
{
}

void MixerTrack::setVolume(float value)
{
    volume = value;
}

float MixerTrack::getVolume() const
{
    return volume;
}

void MixerTrack::mute(bool enabled)
{
    muted = enabled;
}

bool MixerTrack::isMuted() const
{
    return muted;
}
