#pragma once

#include <string>

class FFmpegRunner {
public:
    static bool convertToWav(const std::string& input,
                             const std::string& output);
};
