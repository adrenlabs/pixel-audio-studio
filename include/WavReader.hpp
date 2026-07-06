#pragma once

#include <string>
#include <vector>

class WavReader {
public:
    bool load(const std::string& path);

    const std::vector<short>& getSamples() const;

private:
    std::vector<short> samples;
};
