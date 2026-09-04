#pragma once

#include "core/keycode.hpp"

enum class InputEventType {
    UNKNOWN = 0,
    KEYBOARD,
};

struct KeyboardEvent {
    Keycode key = Keycode::UNKNOWN;
    bool echo = false;
};

struct InputEvent {
    bool pressed = false;
    InputEventType type = InputEventType::UNKNOWN;

    union {
        KeyboardEvent keyboard;
    } data;
};