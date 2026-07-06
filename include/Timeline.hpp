#pragma once

#include <vector>
#include "TimelineTrack.hpp"

class Timeline {
public:
    void addTrack(const TimelineTrack& track);
    void print() const;

private:
    std::vector<TimelineTrack> tracks;
};
