#include <iostream>
#include "../include/FileScanner.hpp"
#include "../include/MetadataReader.hpp"

int main() {
    std::cout << "=====================================\n";
    std::cout << "      Pixel Audio Studio Engine\n";
    std::cout << "=====================================\n\n";

    FileScanner scanner;
    std::cout << "Scanning current folder...\n\n";

    scanner.scanDirectory("/data/data/com.termux/files/home/storage/shared/Download/Saved shares");
    
    MetadataReader reader;

reader.read("/data/data/com.termux/files/home/storage/shared/Download/Saved shares/CLFM Journey On.mp3");

    return 0;
}
