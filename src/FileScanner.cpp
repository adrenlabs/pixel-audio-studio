#include "../include/FileScanner.hpp"

#include <filesystem>
#include <iostream>

namespace fs = std::filesystem;

std::vector<std::string> FileScanner::getSupportedExtensions() {
    return {
        ".mp3", ".wav", ".flac", ".aac", ".ogg",
        ".m4a", ".mp4", ".mkv", ".mov"
    };
}

void FileScanner::scanDirectory(const std::string& path) {
    auto exts = getSupportedExtensions();

    for (const auto& entry : fs::recursive_directory_iterator(path)) {
        if (!entry.is_regular_file()) continue;

        std::string ext = entry.path().extension().string();

        for (const auto& supported : exts) {
            if (ext == supported) {
                auto size = fs::file_size(entry.path());
                std::cout << "File: " << entry.path().filename().string() << "\n";
                std::cout << "Size: " << size << " bytes\n";
                std::cout << "Ext : " << ext << "\n\n";
                break;
            }
        }
    }
}
