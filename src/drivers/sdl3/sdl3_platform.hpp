#pragma once

#include "platform.hpp"

class SDL3Platform final : Platform {
    protected:
        bool hasRequestedClose = false;

    public:
        SDL3Platform();
        ~SDL3Platform();

        void pollEvents() override;
        bool requestedClose() override;
};