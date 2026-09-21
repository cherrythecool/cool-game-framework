package game

EmptyObject :: struct {}

GameObjectData :: union {
    EmptyObject,
    Sprite,
}

GameObject :: struct {
    data: GameObjectData,

    ready: proc(^GameObject),
    update: proc(^GameObject, f64),
    draw: proc(^GameObject),
}