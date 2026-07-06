#pragma once

class MixerTrack {
public:
    MixerTrack();

    void setVolume(float value);
    float getVolume() const;

    void mute(bool enabled);
    bool isMuted() const;

private:
    float volume;
    bool muted;
};
