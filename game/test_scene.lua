local bunny

function printTable(t, indent)
    if indent == nil then
        indent = ""
    end

    for k, v in pairs(t) do
        print(indent .. "[" .. tostring(k) .. "] = " .. tostring(v))

        if type(v) == "table" then
            printTable(v, indent .. "\t")
        end
    end
end

function new()
    
end

function free()
    -- free any assets you loaded that aren't tied to a gameobject (thus not automatically managed)
    -- maybe could have a refcounted or smth type thing though w/ metatables, idk
end

function load()
    bunny = cosmo.newSprite(640, 360, cosmo.getTexture("assets/bunny.jpg"))
    cosmo.pushObject(bunny)
    cosmo.pushObject(cosmo.newSprite(128, 128, cosmo.getTexture("assets/dog.png")))
    cosmo.playSound("assets/TestSong.ogg")
end

function update(delta)
    local time = cosmo.getTime()
    bunny.scale.x = math.sin(time * 2.0) * 0.5 + 1.0
    bunny.scale.y = math.cos(time) * 0.25 + 0.75
end

function draw()

end