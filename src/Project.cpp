#include "../include/Project.hpp"

void Project::setName(const std::string& name)
{
    projectName = name;
}

std::string Project::getName() const
{
    return projectName;
}
