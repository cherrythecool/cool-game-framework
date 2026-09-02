#include "object.hpp"

#include <algorithm>

Object::Object() {}

Object::~Object() {
    parent = nullptr;

    for (Object* child : children) {
        delete child;
    }

    children.clear();
}

void Object::added(void) {}

void Object::update(double deltaSeconds) {
    for (Object* child : children) {
        child->update(deltaSeconds);
    }
}

void Object::draw(void) {
    for (Object* child : children) {
        child->draw();
    }
}

Object* Object::addChild(Object* object) {
    if (object->parent) {
        return nullptr;
    }

    children.push_back(object);
    object->parent = this;

    if (!hasAdded) {
        hasAdded = true;
        object->added();
    }
}

Object* Object::removeChild(Object* object) {
    std::vector<Object*>::iterator found = std::find(children.begin(), children.end(), object);
    
    if (found != children.end()) {
        children.erase(found);
        return object;
    } else {
        return nullptr;
    }
}

void Object::reparent(Object* newParent) {
    if (parent == newParent) {
        return;
    }

    if (parent) {
        parent->removeChild(this);
    }

    if (newParent) {
        newParent->addChild(this);
    }
}

Object* Object::getChild(size_t index) {
    if (index < children.size()) {
        return children[index];
    } else {
        return nullptr;
    }
}

size_t Object::getChildCount(void) {
    return children.size();
}