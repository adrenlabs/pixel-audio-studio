#pragma once

#include <vector>
#include "TimelineClip.hpp"

class TimelineTrack {
public:
    void addClip(const TimelineClip& clip);
    void print() const;

private:
    std::vector<TimelineClip> clips;
};
