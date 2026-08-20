#pragma once

class Platform {
    protected:
        Platform() {}
        virtual ~Platform() = default;
    
    public:
        virtual void pollEvents() = 0;
        virtual bool requestedClose() = 0;
};