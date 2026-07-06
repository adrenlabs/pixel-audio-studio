#include "../include/MasterBus.hpp"

MasterBus::MasterBus()
    : volume(1.0f)
{
}

void MasterBus::setVolume(float value)
{
    volume = value;
}

float MasterBus::getVolume() const
{
    return volume;
}
