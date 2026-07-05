#pragma once

#include <string>
#include <vector>

class FileScanner {
public:
    std::vector<std::string> getSupportedExtensions();
    void scanDirectory(const std::string& path);
};
