#include "../include/TimelineTrack.hpp"

#include <iostream>

void TimelineTrack::addClip(const TimelineClip& clip) {
    clips.push_back(clip);
}

void TimelineTrack::print() const {
    std::cout << "\n===== Timeline =====\n";

    for (const auto& clip : clips) {
        std::cout
            << clip.path
            << " | Start: " << clip.startTime
            << "s | Duration: " << clip.duration
            << "s\n";
    }
}
