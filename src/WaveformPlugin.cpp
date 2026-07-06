#include "../include/WaveformPlugin.hpp"

#include <iostream>

std::string WaveformPlugin::getName() const {
    return "Waveform Plugin";
}

bool WaveformPlugin::initialize() {
    std::cout << "[Waveform] Initialized\n";
    return true;
}

void WaveformPlugin::shutdown() {
    std::cout << "[Waveform] Shutdown\n";
}

std::vector<short> WaveformPlugin::generate(const std::vector<short>& samples)
{
    std::vector<short> waveform;

    const size_t step = 512;

    for (size_t i = 0; i < samples.size(); i += step)
    {
        waveform.push_back(samples[i]);
    }

    return waveform;
}
