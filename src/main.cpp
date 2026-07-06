#include <iostream>

#include "../include/FileScanner.hpp"
#include "../include/MetadataReader.hpp"
#include "../include/Logger.hpp"
#include "../include/FFmpegRunner.hpp"
#include "../include/WavReader.hpp"
#include "../include/AudioPlayer.hpp"
#include "../include/WaveformPlugin.hpp"
#include <algorithm>
#include "../include/TimelineTrack.hpp"
#include "../include/Timeline.hpp"
#include "../include/Playhead.hpp"
#include "../include/ClipEditor.hpp"

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
    
    Timeline timeline;

TimelineTrack music;
music.addClip({
"/data/data/com.termux/files/home/storage/shared/Download/Saved shares/CLFM Journey On.mp3",
0.0,
24.42
});

TimelineTrack voice;
voice.addClip({
"voice.wav",
2.5,
8.0
});

timeline.addTrack(music);
timeline.addTrack(voice);

timeline.print();

    Playhead playhead;

playhead.setPosition(5.0);

std::cout
    << "\nPlayhead Position: "
    << playhead.getPosition()
    << " sec\n";

playhead.move(3.5);

std::cout
    << "Playhead Moved To: "
    << playhead.getPosition()
    << " sec\n";
    
    TimelineClip clip;

clip.path = "voice.wav";
clip.startTime = 2.5;
clip.duration = 8.0;
clip.trimStart = 0.0;
clip.trimEnd = 8.0;

ClipEditor editor;

editor.move(clip, 10.0);
editor.trim(clip, 1.0, 6.0);

std::cout << "\n===== Clip Editor =====\n";

std::cout << "File       : " << clip.path << '\n';
std::cout << "Start Time : " << clip.startTime << " sec\n";
std::cout << "Duration   : " << clip.duration << " sec\n";
std::cout << "Trim Start : " << clip.trimStart << " sec\n";
std::cout << "Trim End   : " << clip.trimEnd << " sec\n";

    TimelineClip secondClip = editor.split(clip, 13.0);

std::cout << "\n===== Split Clip =====\n";

std::cout << "Original Start : " << clip.startTime << " sec\n";
std::cout << "New Clip Start : " << secondClip.startTime << " sec\n";
std::cout << "New Duration   : " << secondClip.duration << " sec\n";

    return 0;
}
