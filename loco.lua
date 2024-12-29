-- Locomotive library for cc

-- MIT License

-- Copyright (c) 2024 maelstrom071

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- north -z
-- south +z
-- east +x
-- west -x
local orient
local pos

function getPos() return pos end
function getOrient() return orient end

function turn(newOrient)
    local map = { north = 0, east = 1, south = 2, west = 3,
                 [0] = "north", [1] = "east", [2] = "south", [3] = "west" }
    local disp = map[newOrient] - map[orient]
    -- Edge case for turning by 3, optimize by moving the
    -- other way
    if disp == -3 then disp = 1 end
    if disp == 3 then disp = -1 end

    if disp > 0 then
        for i=1,disp do
            turtle.turnRight()
        end
    else
        for i=1,-disp do
            turtle.turnLeft()
        end
    end
    orient = newOrient
end

local function wrap(x, y)
    x = math.mod(x, y)
    if x < 0 then
        return y + x
    end
    return x
end

-- Turn relatively. + = right, - = left
function turnRel(offset)
    local map = { north = 0, east = 1, south = 2, west = 3,
                     [0] = "north", [1] = "east", [2] = "south", [3] = "west" }
    local orientId = map[orient]
    orientId = wrap(orientId + offset, 4)
    turn(map[orientId])
end

function moveRel(x, y, z)
    -- Move vertically
    if y > 0 then
        for i = 1, y do
            turtle.digUp()
            turtle.up()
        end
    else
        for i = 1, -y do
            turtle.digDown()
            turtle.down()
        end
    end

    -- Move along z
    if z > 0 then
        turn("south")
    elseif z < 0 then
        turn("north")
    end

    for i = 1, math.abs(z) do
        turtle.dig()
        turtle.forward()
    end

    -- Move along x
    if x > 0 then
        turn("east")
    elseif x < 0 then
        turn("west")
    end

    for i = 1, math.abs(x) do
        turtle.dig()
        turtle.forward()
    end

    pos.x, pos.y, pos.z = pos.x + x, pos.y + y, pos.z + z
end

-- function moveRel(x, y, z)
--     -- Orientation-local coordinates
--     -- +rz is forward, +rx is right
--     local rz, rx
--     if orient == "north" then rz = -z; rx = x end
--     if orient == "south" then rz = z; rx = -x end
--     if orient == "east" then rz = x; rx = z end
--     if orient == "west" then rz = -x; rx = -z end

--     -- Re-orient such that forward is aligned with rz
--     if rz < 0 then
--         turnRel(2)
--         rz = -rz; rx = -rx;
--     end

--     -- Move vertically
--     if y > 0 then
--         for i = 1, y do
--             turtle.digUp()
--             turtle.up()
--         end
--     else
--         for i = 1, -y do
--             turtle.digDown()
--             turtle.down()
--         end
--     end

--     -- Move along rz
--     for i = 1, rz do
--         if turtle.detect() then
--             turtle.dig()
--         end
--         turtle.forward()
--     end

--     -- -- Move along rx
--     -- if rx > 0 then turnRel(1) end
--     -- if rx < -1 then turnRel(-1) end
--     -- for i = 1, rx do
--     --     if turtle.detect() then
--     --         turtle.dig()
--     --     end
--     --     turtle.forward()
--     -- end
-- end

function move(x, y, z)
    moveRel(worldToRel(x, y, z))
end

-- Relative position to world position
function relToWorld(x, y, z)
    return pos.x + x, pos.y + y, pos.z + z
end

function worldToRel(x, y, z)
    return x - pos.x, y - pos.y, z - pos.z
end

function saveLocation()
    local f = fs.open("loc.dat","w")
    f.write(textutils.serialize({ orient = orient, pos = pos }))
    f.close()
end

function loadLocation()
    local f = fs.open("loc.dat","r")
    local c = textutils.unserialize(f.readAll())
    orient = c.orient
    pos = c.pos
    f.close()
end

loadLocation()

return {
    getPos = getPos,
    getOrient = getOrient,
    turn = turn,
    turnRel = turnRel,
    move = move,
    moveRel = moveRel,
    relToWorld = relToWorld,
    worldToRel = worldToRel,
    saveLocation = saveLocation,
    loadLocation = loadLocation
}