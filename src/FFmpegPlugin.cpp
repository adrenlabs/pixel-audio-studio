#include "../include/FFmpegPlugin.hpp"

#include <iostream>

std::string FFmpegPlugin::getName() const {
    return "FFmpeg Plugin";
}

bool FFmpegPlugin::initialize() {
    std::cout << "[FFmpeg] Initialized" << std::endl;
    return true;
}

void FFmpegPlugin::shutdown() {
    std::cout << "[FFmpeg] Shutdown" << std::endl;
}
