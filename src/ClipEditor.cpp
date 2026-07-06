#include "../include/ClipEditor.hpp"

void ClipEditor::move(
    TimelineClip& clip,
    double newStart)
{
    clip.startTime = newStart;
}

void ClipEditor::trim(
    TimelineClip& clip,
    double start,
    double end)
{
    clip.trimStart = start;
    clip.trimEnd = end;
}

     TimelineClip ClipEditor::split(
    const TimelineClip& clip,
    double splitTime)
{
    TimelineClip second = clip;

    second.startTime = splitTime;
    second.duration = clip.duration - (splitTime - clip.startTime);

    return second;
}
