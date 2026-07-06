#include <iostream>

#include "../include/FileScanner.hpp"
#include "../include/MetadataReader.hpp"
#include "../include/Logger.hpp"
#include "../include/FFmpegRunner.hpp"
#include "../include/WavReader.hpp"
#include "../include/AudioPlayer.hpp"
#include "../include/WaveformPlugin.hpp"
#include <algorithm>

int main() {

    Logger::info("Pixel Audio Studio Engine Started");

    std::cout << "=====================================\n";
    std::cout << "      Pixel Audio Studio Engine\n";
    std::cout << "=====================================\n\n";

    FileScanner scanner;

    std::cout << "Scanning current folder...\n\n";

    scanner.scanDirectory(
        "/data/data/com.termux/files/home/storage/shared/Download/Saved shares"
    );

    MetadataReader reader;

    reader.read(
        "/data/data/com.termux/files/home/storage/shared/Download/Saved shares/CLFM Journey On.mp3"
    );

    FFmpegRunner::convertToWav(
        "/data/data/com.termux/files/home/storage/shared/Download/Saved shares/CLFM Journey On.mp3",
        "/data/data/com.termux/files/home/storage/shared/Download/Saved shares/output.wav"
    );
    
    AudioPlayer player;

        player.play(
       "/data/data/com.termux/files/home/storage/shared/Download/Saved shares/CLFM Journey On.mp3"
    );

    WavReader wav;

    if (wav.load(
            "/data/data/com.termux/files/home/storage/shared/Download/Saved shares/output.wav")) {
        std::cout << "\nLoaded Samples: "
                  << wav.getSamples().size()
                  << std::endl;
    }

    WaveformPlugin waveform;

waveform.initialize();

auto points = waveform.generate(wav.getSamples());

std::cout << "\nWaveform Points: "
          << points.size()
          << std::endl;

std::cout << "First 20 Points:\n";

for (size_t i = 0; i < std::min<size_t>(20, points.size()); i++)
{
    std::cout << points[i] << " ";
}

std::cout << "\n";

waveform.shutdown();

    Logger::info("Engine Finished Successfully");

    return 0;
}
