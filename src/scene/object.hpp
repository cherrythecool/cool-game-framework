#pragma once

#include <vector>

#include "core/input_event.hpp"

class Object {
    protected:
        bool hasAdded = false;
        std::vector<Object*> children = {};
        Object* parent = nullptr;
    
    public:
        Object();
        virtual ~Object();

        virtual void added(void);
        virtual void update(double deltaSeconds);
        virtual void draw(void);
        virtual void input(InputEvent event);

        Object* addChild(Object* object);
        Object* removeChild(Object* object);
        void reparent(Object* newParent);
        
        Object* getChild(size_t index);
        size_t getChildCount(void);
};