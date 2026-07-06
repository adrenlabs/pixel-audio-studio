#include "../include/AudioPlayer.hpp"

#include <cstdlib>
#include <iostream>

bool AudioPlayer::play(const std::string& path)
{
    std::string cmd = "termux-media-player play \"" + path + "\"";

    std::cout << "\nPlaying:\n"
              << path << "\n\n";

    return system(cmd.c_str()) == 0;
}

void AudioPlayer::stop()
{
    system("termux-media-player stop");
}
