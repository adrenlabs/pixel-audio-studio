#pragma once

#include "IPlugin.hpp"
#include <memory>
#include <vector>

class PluginManager {
public:
    void registerPlugin(std::shared_ptr<IPlugin> plugin);

    void initializeAll();

    void shutdownAll();

private:
    std::vector<std::shared_ptr<IPlugin>> plugins;
};
