#include "../include/WavReader.hpp"

#include <fstream>
#include <iostream>

bool WavReader::load(const std::string& path)
{
    std::ifstream file(path, std::ios::binary);

    if (!file) {
        std::cout << "Cannot open WAV file\n";
        return false;
    }

    file.seekg(44);

    short sample;

    while (file.read(reinterpret_cast<char*>(&sample), sizeof(sample))) {
        samples.push_back(sample);
    }

    return true;
}

const std::vector<short>& WavReader::getSamples() const
{
    return samples;
}
