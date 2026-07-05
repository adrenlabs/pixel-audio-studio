#include <iostream>
#include "../include/FileScanner.hpp"

int main() {

    std::cout << "=====================================\n";
    std::cout << "      Pixel Audio Studio Engine\n";
    std::cout << "=====================================\n\n";

    FileScanner scanner;

    std::cout << "Scanning current folder...\n\n";

    scanner.scanDirectory(".");

    return 0;
}
