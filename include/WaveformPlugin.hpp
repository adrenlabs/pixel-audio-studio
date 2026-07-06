#pragma once

#include "IPlugin.hpp"
#include <vector>

class WaveformPlugin : public IPlugin {
public:
    std::string getName() const override;
    bool initialize() override;
    void shutdown() override;

    std::vector<short> generate(const std::vector<short>& samples);
};
