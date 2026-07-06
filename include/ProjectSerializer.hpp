#pragma once

#include <string>
#include "Project.hpp"

class ProjectSerializer {
public:
    static bool save(const Project& project,
                     const std::string& filename);
};
