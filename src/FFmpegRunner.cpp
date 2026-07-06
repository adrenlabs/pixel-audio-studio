#include "../include/FFmpegRunner.hpp"

#include <cstdlib>
#include <iostream>

bool FFmpegRunner::convertToWav(const std::string& input,
                                const std::string& output)
{
    std::string cmd =
        "ffmpeg -y -i \"" + input +
        "\" \"" + output + "\"";

    std::cout << "\nRunning:\n"
              << cmd << "\n\n";

    return system(cmd.c_str()) == 0;
}
