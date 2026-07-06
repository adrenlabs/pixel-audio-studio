#include "../include/PluginManager.hpp"

#include <iostream>

void PluginManager::registerPlugin(std::shared_ptr<IPlugin> plugin)
{
    plugins.push_back(plugin);
}

void PluginManager::initializeAll()
{
    for (auto& plugin : plugins)
    {
        std::cout << "[PLUGIN] Loading: "
                  << plugin->getName()
                  << std::endl;

        plugin->initialize();
    }
}

void PluginManager::shutdownAll()
{
    for (auto& plugin : plugins)
    {
        plugin->shutdown();
    }
}
