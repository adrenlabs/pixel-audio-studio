#pragma once

#include <string>

class AudioPlayer {
public:
    bool play(const std::string& path);
    void stop();
};
