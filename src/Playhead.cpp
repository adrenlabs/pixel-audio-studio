#include "../include/Playhead.hpp"

Playhead::Playhead()
    : position(0.0)
{
}

void Playhead::setPosition(double seconds)
{
    position = seconds;
}

double Playhead::getPosition() const
{
    return position;
}

void Playhead::move(double deltaSeconds)
{
    position += deltaSeconds;

    if (position < 0)
        position = 0;
}
