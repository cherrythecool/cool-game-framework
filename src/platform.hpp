#pragma once

#include "number_types.hpp"

class Platform {
    protected:
        Platform() {}
        virtual ~Platform() = default;
    
    public:
        virtual void pollEvents() = 0;
        virtual bool requestedClose() = 0;

        virtual float64_t getTimeSeconds() = 0;
        virtual uint64_t getTimeNS() = 0;
};