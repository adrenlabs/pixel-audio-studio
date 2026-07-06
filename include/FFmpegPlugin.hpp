#pragma once

#include "IPlugin.hpp"

class FFmpegPlugin : public IPlugin {
public:
    std::string getName() const override;
    bool initialize() override;
    void shutdown() override;
};
