#pragma once

#include "math/numbers.hpp"

class Platform {
    protected:
        Platform() {}
        
    public:
        virtual ~Platform() = default;

        virtual void pollEvents() = 0;
        virtual bool requestedClose() = 0;

        virtual float64_t getTimeSeconds() = 0;
        virtual uint64_t getTimeNS() = 0;
};