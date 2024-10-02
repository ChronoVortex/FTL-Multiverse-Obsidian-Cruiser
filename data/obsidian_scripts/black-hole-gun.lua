local vter = mods.multiverse.vter
local time_increment = mods.multiverse.time_increment
local userdata_table = mods.multiverse.userdata_table
local get_room_at_location = mods.multiverse.get_room_at_location
local get_adjacent_rooms = mods.multiverse.get_adjacent_rooms

--------------------
-- BLACK HOLE GUN --
--------------------

-- Apply time dilation on impact
local dilationDuration = 15
local dilationIntensity = -2
local function temp_dilation(ship, pos, intensity, seconds)
    local room = ship.ship.vRoomList[get_room_at_location(ship, pos, true)]
    if room.extend.timeDilation == 0 then
        room.extend.timeDilation = intensity
        userdata_table(room, "mods.cvxObby.dilation").dilationTimer = seconds
    end
end
script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(ship, projectile, location, damage, shipFriendlyFire)
    if projectile and projectile.extend and projectile.extend.name == "CVX_SINGULARITY_CANNON" then
        temp_dilation(ship, location, dilationIntensity, dilationDuration)
        for roomId, roomPos in pairs(get_adjacent_rooms(ship.iShipId, get_room_at_location(ship, location, true), false)) do
            temp_dilation(ship, roomPos, dilationIntensity/2, dilationDuration)
        end
    end
end)

-- Handle time dilation
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    for room in vter(ship.ship.vRoomList) do
        local roomData = userdata_table(room, "mods.cvxObby.dilation")
        if roomData.dilationTimer then
            roomData.dilationTimer = roomData.dilationTimer - time_increment()
            if roomData.dilationTimer <= 0 then
                roomData.dilationTimer = nil
                room.extend.timeDilation = 0
            end
        end
    end
end)

-- Pierce zoltan shields
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION_PRE, function(ship, projectile, damage, response)
    if projectile and projectile.extend and projectile.extend.name == "CVX_SINGULARITY_CANNON" then
        damage.iDamage = 0
        damage.iIonDamage = 0
    end
end)

-------------------------
-- OBSIDIAN FIRE REGEN --
-------------------------
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    if ship:HasEquipment("CVX_OBSIDIAN_ARMOR") > 0 then
        local shipData = userdata_table(ship, "mods.cvxObby.fireRegen")
        if ship.fireSpreader.count <= 0 and shipData.fireLastFrame and (not Hyperspace.App.world.space.sunLevel or math.random() > 0.5) then
            ship.ship.hullIntegrity.first = math.min(ship.ship.hullIntegrity.first + 1, ship.ship.hullIntegrity.second)
        end
        shipData.fireLastFrame = ship.fireSpreader.count > 0
    end
end)
