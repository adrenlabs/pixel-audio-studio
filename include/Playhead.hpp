#pragma once

class Playhead {
public:
    Playhead();

    void setPosition(double seconds);

    double getPosition() const;

    void move(double deltaSeconds);

private:
    double position;
};
