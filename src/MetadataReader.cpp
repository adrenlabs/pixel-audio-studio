#include "../include/MetadataReader.hpp"

#include <iostream>

#include <taglib/fileref.h>
#include <taglib/tag.h>

void MetadataReader::read(const std::string& filePath) {

    TagLib::FileRef file(filePath.c_str());

    if (file.isNull() || !file.tag()) {
        std::cout << "Failed to read metadata.\n";
        return;
    }

    TagLib::Tag *tag = file.tag();

    std::cout << "\nMetadata\n";
    std::cout << "-----------------\n";

    std::cout << "Title : " << tag->title() << '\n';
    std::cout << "Artist: " << tag->artist() << '\n';
    std::cout << "Album : " << tag->album() << '\n';
    std::cout << "Genre : " << tag->genre() << '\n';
    std::cout << "Year  : " << tag->year() << '\n';
}
