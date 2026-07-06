#pragma once

class MasterBus {
public:
    MasterBus();

    void setVolume(float value);
    float getVolume() const;

private:
    float volume;
};
