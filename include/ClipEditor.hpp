#pragma once

#include "TimelineClip.hpp"

     class ClipEditor {
public:
    void move(TimelineClip& clip, double newStart);

    void trim(
        TimelineClip& clip,
        double trimStart,
        double trimEnd
    );

    TimelineClip split(const TimelineClip& clip, double splitTime);
};
