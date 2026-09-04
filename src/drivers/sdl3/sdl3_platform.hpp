#pragma once

#include "core/platform.hpp"

class SDL3Platform final : public Platform {
    protected:
        bool hasRequestedClose = false;

    public:
        SDL3Platform();
        ~SDL3Platform();

        std::optional<InputEvent> pollEvent() override;
        bool requestedClose() override;

        float64_t getTimeSeconds() override;
        uint64_t getTimeNS() override;
};