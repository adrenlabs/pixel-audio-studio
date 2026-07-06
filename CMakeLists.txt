cmake_minimum_required(VERSION 3.16)

project(PixelAudioStudioEngine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

add_executable(pixel-engine
    src/main.cpp
    src/FileScanner.cpp
    src/MetadataReader.cpp
    src/Logger.cpp
    src/FFmpegRunner.cpp
    src/WavReader.cpp
    src/AudioPlayer.cpp
    src/PluginManager.cpp
    src/FFmpegPlugin.cpp
    src/WaveformPlugin.cpp
    src/TimelineTrack.cpp
    src/Timeline.cpp
    src/Playhead.cpp
    src/ClipEditor.cpp
)

find_package(PkgConfig REQUIRED)

pkg_check_modules(TAGLIB REQUIRED taglib)

target_include_directories(pixel-engine PRIVATE
    ${TAGLIB_INCLUDE_DIRS}
)

target_link_libraries(pixel-engine
    ${TAGLIB_LIBRARIES}
)
