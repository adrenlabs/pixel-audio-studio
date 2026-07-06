#pragma once

#include <string>

class IPlugin {
public:
    virtual ~IPlugin() = default;

    virtual std::string getName() const = 0;

    virtual bool initialize() = 0;

    virtual void shutdown() = 0;
};
