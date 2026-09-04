#pragma once

#include "core/math/numbers.hpp"

#include <optional>
#include "core/input_event.hpp"

class Platform {
    protected:
        Platform() {}
        
    public:
        virtual ~Platform() = default;

        virtual std::optional<InputEvent> pollEvent() = 0;
        virtual bool requestedClose() = 0;

        virtual float64_t getTimeSeconds() = 0;
        virtual uint64_t getTimeNS() = 0;
};