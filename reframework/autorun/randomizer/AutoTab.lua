local AutoTab = {}

-- Push current zone to PopTracker.
-- Key (storage): "<slot>-re2r-currentMap"
--
-- Zone lookup uses Map.ID values from Ropey's spreadsheet (thank you):
-- https://docs.google.com/spreadsheets/d/1vR6SYsvzxeeGvaxygrf4_fJAaRiv_ZMe0nIYvV6O_kQ

AutoTab.lastZone = nil
AutoTab.lastPush = 0
AutoTab.pushSeq = 0
AutoTab.STORAGE_SUFFIX = "-re2r-currentMap"

local ZONE_BY_MAP_ID = {
    [112] = "rpd_1f",
    [118] = "rpd_1f",
    [119] = "rpd_1f",
    [120] = "rpd_1f",
    [122] = "rpd_1f",
    [123] = "rpd_1f",
    [125] = "rpd_1f",
    [126] = "lab_b1",
    [127] = "lab_b1",
    [128] = "lab_b1",
    [129] = "lab_b1",
    [130] = "lab_b1",
    [131] = "lab_b1",
    [133] = "lab_b3",
    [134] = "lab_b3",
    [135] = "lab_b3",
    [136] = "lab_b3",
    [219] = "rpd_1f",
    [220] = "rpd_1f",
    [222] = "rpd_1f",
    [224] = "rpd_1f",
    [225] = "rpd_1f",
    [226] = "rpd_1f",
    [227] = "rpd_1f",
    [229] = "rpd_1f",
    [230] = "rpd_1f",
    [231] = "rpd_1f",
    [232] = "rpd_1f",
    [234] = "rpd_1f",
    [235] = "rpd_1f",
    [237] = "rpd_1f",
    [238] = "rpd_1f",
    [239] = "rpd_1f",
    [240] = "rpd_1f",
    [243] = "rpd_2f",
    [244] = "rpd_2f",
    [245] = "rpd_2f",
    [248] = "rpd_2f",
    [249] = "rpd_2f",
    [250] = "rpd_2f",
    [252] = "rpd_2f",
    [253] = "rpd_2f",
    [254] = "rpd_2f",
    [255] = "rpd_2f",
    [256] = "rpd_2f",
    [260] = "rpd_2f",
    [261] = "rpd_1f",
    [263] = "rpd_3f",
    [264] = "rpd_3f",
    [265] = "rpd_3f",
    [268] = "rpd_3f",
    [269] = "rpd_3f",
    [270] = "rpd_3f",
    [271] = "rpd_3f",
    [272] = "rpd_basement",
    [273] = "rpd_basement",
    [274] = "rpd_basement",
    [275] = "rpd_basement",
    [277] = "rpd_basement",
    [279] = "rpd_basement",
    [282] = "rpd_basement",
    [310] = "sewers_upper",
    [313] = "sewers_upper",
    [315] = "sewers_middle",
    [316] = "sewers_upper",
    [317] = "sewers_lower",
    [318] = "sewers_upper",
    [319] = "sewers_upper",
	[320] = "sewers_middle",
    [321] = "sewers_lower",
    [323] = "sewers_lower",
    [325] = "sewers_lower",
    [326] = "sewers_lower",
    [327] = "sewers_lower",
    [329] = "sewers_lower",
    [330] = "sewers_middle",
    [332] = "sewers_middle",
    [335] = "sewers_middle",
    [338] = "sewers_middle",
    [350] = "uf_upper",
    [351] = "rpd_outside",
    [352] = "uf_middle",
    [353] = "uf_middle",
    [356] = "rpd_basement",
    [359] = "orphanage_1f",
	[360] = "orphanage_1f",
	[361] = "orphanage_1f",
	[364] = "orphanage_2f",
	[367] = "orphanage_2f",
    [370] = "lab_b1",
    [371] = "lab_b1",
    [372] = "lab_b1",
    [373] = "lab_b3",
    [377] = "sewers_entrance",
    [378] = "sewers_entrance",
    [379] = "sewers_entrance",
    [380] = "sewers_entrance",
    [381] = "orphanage_b1",
    [405] = "uf_upper",
    [406] = "rpd_outside",
    [407] = "rpd_outside",
	[408] = "rpd_outside",
    [409] = "rpd_basement",
    [410] = "lab_b1",
    [411] = "lab_b1",
    [412] = "lab_b1",
    [413] = "lab_b2_east",
    [414] = "lab_b2_east",
    [415] = "lab_b2_east",
    [416] = "lab_b2_east",
    [417] = "lab_b2_east",
    [418] = "lab_b1",
    [419] = "lab_b2_west",
    [420] = "lab_b1",
    [421] = "lab_b3",
    [422] = "lab_b3",
    [423] = "lab_b4",
    [429] = "sewers_middle",
    [430] = "sewers_middle",
    [431] = "rpd_1f",
    [432] = "lab_b1",
    [433] = "lab_b1",
}

-- Guesstimate IDs missing from the spreadsheet (mostly orphanage).
local function zoneFromSceneName(sceneName)
    if not sceneName or sceneName == "" or sceneName == "Invalid" then
        return nil
    end
    local area, room = string.match(string.lower(sceneName), "st(%d+)_(%d+)")
    area = tonumber(area)
    room = tonumber(room)
    if not area or not room then
        return nil
    end
    local block = math.floor(room / 100)

    if area == 1 then
        if room >= 600 then
            return "sewers_entrance"
        end
        return "rpd_outside"
    end
    if area == 2 then
        if block >= 3 then
            return "orphanage_b1"
        elseif block == 2 then
            return "orphanage_2f"
        end
        return "orphanage_1f"
    end
    if area == 3 then
        if room < 600 then
            return "sewers_entrance"
        elseif room < 620 then
            return "sewers_upper"
        elseif room < 630 then
            return "sewers_lower"
        elseif room < 650 then
            return "sewers_middle"
        end
        return "sewers_lower"
    end
    return nil
end

local ZONE_BY_FLOOR = {
    ["RPD_A"] = "rpd_1f",
    ["RPD_B"] = "rpd_2f",
    ["RPD_C"] = "rpd_3f",
    ["RPD_D"] = "rpd_basement",
    ["RPD_E"] = "rpd_outside",
    -- Underground Facility (in-game "WaterPlant") shares Map.IDs across floors
    ["WaterPlant_A"] = "uf_upper",
    ["WaterPlant_B"] = "uf_middle",
    ["WaterPlant_C"] = "uf_lower",
}

local FLOOR_OVERRIDE_ZONES = {
    rpd_1f = true,
    rpd_2f = true,
    rpd_3f = true,
    uf_upper = true,
    uf_middle = true,
    uf_lower = true,
}

local function resolveEnumName(enumValue, typeRelativeName)
    if enumValue == nil then
        return nil
    end
    local asString = tostring(enumValue)
    local named = asString:match("^([%a_][%w_]*)%s*%(")
    if named then
        return named
    end
    -- REFramework Lua often stringifies enums as a bare int ("2").
    local numeric = tonumber(asString)
    if numeric == nil then
        return asString:match("^([%a_][%w_]*)")
    end
    local resolved = nil
    pcall(function()
        local typedef = sdk.find_type_definition(sdk.game_namespace(typeRelativeName))
        if not typedef then
            return
        end
        for _, field in ipairs(typedef:get_fields()) do
            if field:is_static() then
                local ok, val = pcall(function()
                    return field:get_data(nil)
                end)
                if ok and tonumber(val) == numeric then
                    resolved = field:get_name()
                    break
                end
            end
        end
    end)
    return resolved
end

local function getDispFloorName()
    local floorName = nil
    pcall(function()
        local mm = sdk.get_managed_singleton(sdk.game_namespace("gamemastering.UIMapManager"))
        if not mm then
            return
        end
        floorName = resolveEnumName(mm:call("get_DispFloorId"), "gamemastering.Floor.ID")
    end)
    return floorName
end

local function getSceneInfo()
    local mapEnum = nil
    pcall(function()
        local em = sdk.get_managed_singleton(sdk.game_namespace("EnemyManager"))
        if em then
            mapEnum = em:call("get_LastPlayerStaySceneID")
        end
    end)
    if mapEnum == nil then
        pcall(function()
            local mm = sdk.get_managed_singleton(sdk.game_namespace("gamemastering.UIMapManager"))
            if mm then
                mapEnum = mm:call("get_SceneMapId")
            end
        end)
    end
    if mapEnum == nil then
        return nil, nil, nil
    end

    local asString = tostring(mapEnum)
    local sceneName = asString:match("^([%w_]+)%s*%(") or asString:match("^([%w_]+)")
    local mapId = tonumber(asString:match("%((%d+)%)%s*$")) or tonumber(asString)
    return sceneName, mapId, getDispFloorName()
end

local function zoneFromScene(sceneName, mapId, floorName)
    local zone = nil
    if mapId ~= nil then
        zone = ZONE_BY_MAP_ID[mapId]
    end
    if zone == nil then
        zone = zoneFromSceneName(sceneName)
    end

    -- Main Hall / UF Machinery Room share one Map.ID across floors
    -- so we trust DispFloorId to tell us the truth instead
    local floorZone = floorName and ZONE_BY_FLOOR[floorName] or nil
    if floorZone and (zone == nil or FLOOR_OVERRIDE_ZONES[zone]) then
        return floorZone
    end

    return zone
end

local function getPlayerNumber()
    local playerNumber = nil
    pcall(function()
        if AP_REF and AP_REF.APClient then
            playerNumber = AP_REF.APClient:get_player_number()
        end
    end)
    if playerNumber == nil or tonumber(playerNumber) < 0 then
        return nil
    end
    return tonumber(playerNumber)
end

local function pushZone(zone)
    if not Archipelago or not Archipelago.IsConnected or not Archipelago.IsConnected() then
        return false
    end
    if AP_REF == nil or AP_REF.APClient == nil then
        return false
    end

    local playerNumber = getPlayerNumber()
    if playerNumber == nil then
        return false
    end

    AutoTab.pushSeq = AutoTab.pushSeq + 1

    local bounced = pcall(function()
        AP_REF.APClient:Bounce({
            re2r_map = zone,
            seq = AutoTab.pushSeq,
        }, nil, { playerNumber }, nil)
    end)
    if not bounced then
        bounced = pcall(function()
            AP_REF.APClient:Bounce({
                re2r_map = zone,
                seq = AutoTab.pushSeq,
            }, nil, nil, nil)
        end)
    end

    local payload = tostring(zone) .. "#" .. tostring(AutoTab.pushSeq)
    local key = tostring(playerNumber) .. AutoTab.STORAGE_SUFFIX
    local ok, queued = pcall(function()
        return AP_REF.APClient:Set(key, payload, false, { { "replace", payload } })
    end)
    if not ok or not queued then
        ok, queued = pcall(function()
            return AP_REF.APClient:Set(key, payload, false, {
                { operation = "replace", value = payload }
            })
        end)
    end

    return bounced or (ok and queued)
end

function AutoTab.Init()
    local sceneName, mapId, floorName = getSceneInfo()
    local zone = zoneFromScene(sceneName, mapId, floorName)
    if zone == nil then
        return
    end

    local now = os.clock()
    local zoneChanged = zone ~= AutoTab.lastZone
    local dueRefresh = (now - AutoTab.lastPush) >= 2.0
    if not zoneChanged and not dueRefresh then
        return
    end
    if (now - AutoTab.lastPush) < 0.4 then
        return
    end

    AutoTab.lastPush = now
    if pushZone(zone) then
        AutoTab.lastZone = zone
    end
end

function AutoTab.Reset()
    AutoTab.lastZone = nil
end

return AutoTab
