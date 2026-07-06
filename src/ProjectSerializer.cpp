#include "../include/ProjectSerializer.hpp"

#include <fstream>

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
