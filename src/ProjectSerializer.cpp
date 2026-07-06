#include "../include/ProjectSerializer.hpp"

#include <fstream>

#include <iostream>
bool ProjectSerializer::save(
    const Project& project,
    const std::string& filename)
{
    std::ofstream file(filename);

    if (!file.is_open())
        return false;

    file << "PIXEL_AUDIO_PROJECT\n";
    file << "Name=" << project.getName() << "\n";

    file.close();

    return true;
}

bool ProjectSerializer::load(
    Project& project,
    const std::string& filename)
{
    std::ifstream file(filename);

    if (!file.is_open())
        return false;

    std::string line;

    while (std::getline(file, line))
    {
        if (line.rfind("Name=", 0) == 0)
        {
            project.setName(line.substr(5));
        }
    }

    file.close();

    return true;
}
