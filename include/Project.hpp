#pragma once

#include <string>

class Project {
public:
    void setName(const std::string& name);
    std::string getName() const;

private:
    std::string projectName;
};
