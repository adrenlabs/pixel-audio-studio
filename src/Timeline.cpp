#include "../include/Timeline.hpp"

#include <iostream>

void Timeline::addTrack(const TimelineTrack& track) {
    tracks.push_back(track);
}

void Timeline::print() const {
    std::cout << "\n========== PROJECT TIMELINE ==========\n";

    int index = 1;

    for (const auto& track : tracks) {
        std::cout << "\nTrack " << index++ << "\n";
        track.print();
    }
}
