BH_VERSION = "1.2.9"

MAX_MODEL_ROTATION_RANDOMIZATION_STEPS = 359

--[[
    For installation, usage and implementation examples check the wiki:
        https://github.com/MNoya/BuildingHelper/wiki
]]

require('libraries/timers')
require('libraries/selection')
require('libraries/keyvalues')

if not BuildingHelper then
    BuildingHelper = class({})
end

-- Loads Key Values into the BuildingAbilities
function BuildingHelper:Init()
    -- building_settings nettable from buildings.kv
    BuildingHelper:LoadSettings()

    print("BuildingHelper Init")
    BuildingHelper.Players = {} -- Holds a table for each player ID
    BuildingHelper.Dummies = {} -- Holds up to one entity for each building name
    BuildingHelper.TreeDummies = {} -- Holds tree chopped dummies
    BuildingHelper.Grid = {}    -- Construction grid
    BuildingHelper.Terrain = {} -- Terrain grid, this only changes when a tree is cut
    BuildingHelper.Encoded = "" -- String containing the base terrain, networked to clients
    BuildingHelper.squareX = 0  -- Number of X grid points
    BuildingHelper.squareY = 0  -- Number of Y grid points

    -- Grid States
    BuildingHelper.GridTypes = {}
    BuildingHelper.NextGridValue = 1
    BuildingHelper:NewGridType("BLOCKED")
    BuildingHelper:NewGridType("BUILDABLE")

    -- Panorama Event Listeners
    CustomGameEventManager:RegisterListener("building_helper_build_command", Dynamic_Wrap(BuildingHelper, "BuildCommand"))
    CustomGameEventManager:RegisterListener("building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "CancelCommand"))
    CustomGameEventManager:RegisterListener("building_helper_repair_command", Dynamic_Wrap(BuildingHelper, "RepairCommand"))
    CustomGameEventManager:RegisterListener("selection_update", Dynamic_Wrap(BuildingHelper, 'OnSelectionUpdate')) --Hook selection library
    CustomGameEventManager:RegisterListener("gnv_request", Dynamic_Wrap(BuildingHelper, "SendGNV"))

     -- Game Event Listeners
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(BuildingHelper, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(BuildingHelper, 'OnNPCSpawned'), self)
    ListenToGameEvent('entity_killed', Dynamic_Wrap(BuildingHelper, 'OnEntityKilled'), self)
    if BuildingHelper.Settings["UPDATE_TREES"] then
        ListenToGameEvent('tree_cut', Dynamic_Wrap(BuildingHelper, 'OnTreeCut'), self)
    end

    -- Lua Modifiers
    LinkLuaModifier("modifier_building", "libraries/modifiers/modifier_building", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_out_of_world", "libraries/modifiers/modifier_out_of_world", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_builder_hidden", "libraries/modifiers/modifier_builder_hidden", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_repairing", "libraries/modifiers/repair_modifiers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_builder_repairing", "libraries/modifiers/repair_modifiers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_tree_cut", "libraries/modifiers/modifier_tree_cut", LUA_MODIFIER_MOTION_NONE)
    require("libraries/modifiers/grid_modifiers")

    -- Check KVs and set relevant construction_size nettable values
    self:ParseKV()

    -- Order Filter override
    self:HookBoilerplate()

    -- Some game function overrides
    self:HookFunctions()

    -- Reload settings file
    self:OnScriptReload()
end

function BuildingHelper:OnScriptReload()
    BuildingHelper:LoadSettings()
    if BuildingHelper.Settings["REPAIR_PATH"] then
        require(BuildingHelper.Settings["REPAIR_PATH"])
    end
    if BuildingHelper.Settings["BUILD_PATH"] then
        require(BuildingHelper.Settings["BUILD_PATH"])
    end
end

function BuildingHelper:HookBoilerplate()
    if not __ACTIVATE_HOOK then
        __ACTIVATE_HOOK = {funcs={}}
        setmetatable(__ACTIVATE_HOOK, {
          __call = function(t, func)
            table.insert(t.funcs, func)
          end
        })

        debug.sethook(function(...)
          local info = debug.getinfo(2)
          local src = tostring(info.short_src)
          local name = tostring(info.name)
          if name ~= "__index" then
            if string.find(src, "addon_game_mode") then
              if GameRules:GetGameModeEntity() then
                for _, func in ipairs(__ACTIVATE_HOOK.funcs) do
                  local status, err = pcall(func)
                  if not status then
                    print("__ACTIVATE_HOOK callback error: " .. err)
                  end
                end

                debug.sethook(nil, "c")
              end
            end
          end
        end, "c")
    end

    -- Hook the order filter
    __ACTIVATE_HOOK(function()
        local mode = GameRules:GetGameModeEntity()
        mode:SetExecuteOrderFilter(Dynamic_Wrap(BuildingHelper, 'OrderFilter'), BuildingHelper)
        self.oldFilter = mode.SetExecuteOrderFilter
        mode.SetExecuteOrderFilter = function(mode, fun, context)
            BuildingHelper.nextFilter = fun
            BuildingHelper.nextContext = context
        end
    end)
end

-- This requires that buildinghelper is required before the usage of these functions
function BuildingHelper:HookFunctions()
    local oldSetTreeRegrowTime = GameRules.SetTreeRegrowTime
    BuildingHelper.TreeRegrowTime = 300
    GameRules.SetTreeRegrowTime = function(gameRules, time)
        BuildingHelper.TreeRegrowTime = time
        oldSetTreeRegrowTime(gameRules, time)
    end

    local oldRegrowAllTrees = GridNav.RegrowAllTrees
    GridNav.RegrowAllTrees = function(gridNav)
        for _,dummy in pairs(BuildingHelper.TreeDummies) do
            UTIL_Remove(dummy)
        end
        BuildingHelper.TreeDummies = {}
        oldRegrowAllTrees(gridNav)
    end

    local oldCutDownRegrowAfter = CDOTA_MapTree.CutDownRegrowAfter
    CDOTA_MapTree.CutDownRegrowAfter = function(tree, time, team)
        oldCutDownRegrowAfter(tree, time, team)
        Timers:CreateTimer(time, function()
            BuildingHelper.TreeDummies[tree:GetEntityIndex()] = nil
            UTIL_Remove(tree.chopped_dummy)
        end)
    end

    local oldGrowBack = CDOTA_MapTree.GrowBack
    CDOTA_MapTree.GrowBack = function(tree)
        BuildingHelper.TreeDummies[tree:GetEntityIndex()] = nil
        UTIL_Remove(tree.chopped_dummy)
        oldGrowBack(tree)
    end
end

function BuildingHelper:LoadSettings()
    BuildingHelper.Settings = LoadKeyValues("scripts/kv/building_settings.kv")

    BuildingHelper.Settings["TESTING"] = tobool(BuildingHelper.Settings["TESTING"])
    BuildingHelper.Settings["RECOLOR_BUILDING_PLACED"] = tobool(BuildingHelper.Settings["RECOLOR_BUILDING_PLACED"])
    BuildingHelper.Settings["UPDATE_TREES"] = tobool(BuildingHelper.Settings["UPDATE_TREES"])
    BuildingHelper.Settings["MAGIC_IMMUNE_BUILDINGS"] = tobool(BuildingHelper.Settings["MAGIC_IMMUNE_BUILDINGS"])
    BuildingHelper.Settings["DENIABLE_BUILDINGS"] = tobool(BuildingHelper.Settings["DENIABLE_BUILDINGS"])
    BuildingHelper.Settings["DISABLE_BUILDING_TURNING"] = tobool(BuildingHelper.Settings["DISABLE_BUILDING_TURNING"])
    BuildingHelper.Settings["RIGHT_CLICK_REPAIR"] = tobool(BuildingHelper.Settings["RIGHT_CLICK_REPAIR"])

    CustomNetTables:SetTableValue("building_settings", "grid_alpha", { value = BuildingHelper.Settings["GRID_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "alt_grid_alpha", { value = BuildingHelper.Settings["ALT_GRID_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "alt_grid_squares", { value = BuildingHelper.Settings["ALT_GRID_SQUARES"] })
    CustomNetTables:SetTableValue("building_settings", "range_overlay_alpha", { value = BuildingHelper.Settings["RANGE_OVERLAY_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "model_alpha", { value = BuildingHelper.Settings["MODEL_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "recolor_ghost", { value = tobool(BuildingHelper.Settings["RECOLOR_GHOST_MODEL"]) })
    CustomNetTables:SetTableValue("building_settings", "turn_red", { value = tobool(BuildingHelper.Settings["RED_MODEL_WHEN_INVALID"]) })
    CustomNetTables:SetTableValue("building_settings", "permanent_alt_grid", { value = tobool(BuildingHelper.Settings["PERMANENT_ALT_GRID"]) })
    CustomNetTables:SetTableValue("building_settings", "update_trees", { value = BuildingHelper.Settings["UPDATE_TREES"] })
    CustomNetTables:SetTableValue("building_settings", "right_click_repair", { value = BuildingHelper.Settings["RIGHT_CLICK_REPAIR"] })

    if BuildingHelper.Settings["HEIGHT_RESTRICTION"] and BuildingHelper.Settings["HEIGHT_RESTRICTION"] ~= "" then
        CustomNetTables:SetTableValue("building_settings", "height_restriction", { value = BuildingHelper.Settings["HEIGHT_RESTRICTION"] })
    end
end

function BuildingHelper:ParseKV()
    for name,info in pairs(KeyValues.All) do
        if type(info) == "table" then
            local isBuilding = info["Building"] or info["ConstructionSize"]
            if isBuilding then
                -- Build NetTable with the building properties
                local values = {}
                if info['ConstructionSize'] then
                    values.size = info['ConstructionSize']
                end

                -- Add proximity restriction
                if info['RestrictGoldMineDistance'] then
                    values.distance_to_gold_mine = info['RestrictGoldMineDistance']
                end

                -- Add special grid types generated by this building
                if info['Grid'] then
                    values.grid = info['Grid']
                end

                -- Add required grid types
                if info['Requires'] then
                    values.requires = string.upper(info['Requires'])
                end

                -- Add denied grid types
                if info['Prevents'] then
                    values.requires = string.upper(info['Prevents'])
                end

                CustomNetTables:SetTableValue("construction_size", name, values)
            end
        end
    end
end

function BuildingHelper:OnGameRulesStateChange(keys)
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        -- The base terrain GridNav is obtained directly from the vmap
        BuildingHelper:InitGNV()
    end
end

function BuildingHelper:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)
    if IsBuilder(npc) then
        BuildingHelper:InitializeBuilder(npc)
    end
end

function BuildingHelper:OnEntityKilled(keys)
    local killed = EntIndexToHScript(keys.entindex_killed)
    local unitTable = killed:GetKeyValue()
    local gridTable = unitTable and unitTable["Grid"]

    if IsBuilder(killed) then
        BuildingHelper:ClearQueue(killed)
    elseif IsCustomBuilding(killed) or gridTable then
        -- Building Helper grid cleanup
        BuildingHelper:RemoveBuilding(killed, false)

        if gridTable then
            for grid_type,v in pairs(gridTable) do
                if tobool(v.RemoveOnDeath) then --Only use if there is no overlapping!
                    local location = killed:GetAbsOrigin()
                    print("Clearing special grid of "..grid_type)
                    if (v.Radius) then
                        BuildingHelper:RemoveGridType(v.Radius, location, grid_type, "radius")
                    elseif (v.Square) then
                        BuildingHelper:RemoveGridType(v.Square, location, grid_type)
                    end
                end
            end
        end
    end
end

function BuildingHelper:OnTreeCut(keys)
    local treePos = Vector(keys.tree_x,keys.tree_y,0)
    local tree -- Figure out which tree was cut
    for _,t in pairs(BuildingHelper.AllTrees) do
        local pos = t:GetAbsOrigin()
        if pos.x == treePos.x and pos.y == treePos.y then
            tree = t
            break
        end
    end

    if not tree then
       print("ERROR: OnTreeCut couldn't find a tree for pos "..treePos.x..","..treePos.y)
        return
    elseif tree.chopped_dummy then
        UTIL_Remove(tree.chopped_dummy)
    end

    -- Create a dummy for clients to be able to detect trees standing and block their grid
    tree.chopped_dummy = CreateUnitByName("npc_dota_units_base", treePos, false, nil, nil, 0)
    tree.chopped_dummy:AddNewModifier(tree.chopped_dummy,nil,"modifier_tree_cut",{})
    BuildingHelper.TreeDummies[tree:GetEntityIndex()] = tree.chopped_dummy

    -- Allow construction
    if not GridNav:IsBlocked(treePos) then
        BuildingHelper:FreeGridSquares(2, treePos)
    end

    -- Remove the dummy, allowing the tree to regrow
    Timers:CreateTimer(BuildingHelper.TreeRegrowTime, function()
        if IsValidEntity(tree.chopped_dummy) then
            BuildingHelper.TreeDummies[tree:GetEntityIndex()] = nil
            UTIL_Remove(tree.chopped_dummy)
        end
    end)
end

function BuildingHelper:InitGNV()
    local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
    local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)

    local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
    local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
    local boundY1 = GridNav:WorldToGridPosY(worldMin.y)
    local boundY2 = GridNav:WorldToGridPosY(worldMax.y)

    print("Max World Bounds: ")
    print(GetWorldMinX()..' '..GetWorldMaxX()..' '..GetWorldMinY()..' '..GetWorldMaxY())
    print(boundX1..' '..boundX2..' '..boundY1..' '..boundY2)

    local blockedCount = 0
    local unblockedCount = 0

    local gnv = {}
    local line = {}
    local ASCII_ART = false

    -- Trigger zones named "bh_blocked" will block the terrain for construction
    local blocked_map_zones = Entities:FindAllByName("*bh_blocked")

    for y=boundY1,boundY2 do
        local shift = 4
        local byte = 0
        BuildingHelper.Terrain[y] = {}
        for x=boundX1,boundX2 do
            local gridX = GridNav:GridPosToWorldCenterX(x)
            local gridY = GridNav:GridPosToWorldCenterY(y)
            local position = Vector(gridX, gridY, 0)
            local treeBlocked = GridNav:IsNearbyTree(position, 30, true)

            -- If tree updating is enabled, trees aren't networked but detected as ent_dota_tree entities on clients
            local terrainBlocked = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position)
            if BuildingHelper.Settings["UPDATE_TREES"] then
                terrainBlocked = terrainBlocked and not treeBlocked
            end

            if not terrainBlocked then
                -- Check if the position is inside any blocking trigger
                for _,ent in pairs(blocked_map_zones) do
                    local triggerBlocked = BuildingHelper:IsInsideEntityBounds(ent, position)
                    if triggerBlocked then
                        terrainBlocked = true
                        break
                    end
                end
            end

            if terrainBlocked then
                BuildingHelper.Terrain[y][x] = BuildingHelper.GridTypes["BLOCKED"]
                byte = byte + bit.lshift(2,shift)
                blockedCount = blockedCount+1
                if ASCII_ART then
                    line[#line+1] = '='
                end
            else
                BuildingHelper.Terrain[y][x] = BuildingHelper.GridTypes["BUILDABLE"]
                byte = byte + bit.lshift(1,shift)
                unblockedCount = unblockedCount+1
                if ASCII_ART then
                    line[#line+1] = '.'
                end
            end

            if treeBlocked then
                BuildingHelper.Terrain[y][x] = BuildingHelper.GridTypes["BLOCKED"]
            end

            shift = shift - 2

            if shift == -2 then
                gnv[#gnv+1] = string.char(byte+58) -- Use 58 to start after numbers
                shift = 4
                byte = 0
            end
        end

        if shift ~= 4 then
           gnv[#gnv+1] = string.char(byte+58)
        end

        if ASCII_ART then
            print(table.concat(line,''))
            line = {}
        end
    end

    local gnv_string = table.concat(gnv,'')

     -- Running-length encoding
    local last
    local count = 0
    local gnvRLE = {}
    for i=1,string.len(gnv_string) do
        local c = gnv_string:sub(i,i)
        if last then
            if last == c then
                count = count + 1
            else
                gnvRLE[#gnvRLE+1] = count .. last
                last = c
                count = 1
            end
        else
            last = c
            count = count + 1
        end
    end
    local gnvRLE_string = table.concat(gnvRLE,'')

    local squareX = boundX2 - boundX1 + 1
    local squareY = boundY2 - boundY1 + 1

    -- PrintTable(gnvRLE)
    print("Free: "..unblockedCount.." Blocked: "..blockedCount .. " gnvLen: " .. string.len(gnv_string) .. "/" .. string.len(gnvRLE_string))

    -- Initially, the construction grid equals the terrain grid
    -- Clients will have full knowledge of the terrain grid
    -- The construction grid is only known by the server
    BuildingHelper.Grid = BuildingHelper.Terrain

    BuildingHelper.Encoded = gnvRLE_string
    BuildingHelper.squareX = squareX
    BuildingHelper.squareY = squareY
    BuildingHelper.minBoundX = boundX1
    BuildingHelper.minBoundY = boundY1

    BuildingHelper.AllTrees = Entities:FindAllByClassname("ent_dota_tree")
end

function BuildingHelper:SendGNV(args)
    local playerID = args.PlayerID
    if playerID then
        local player = PlayerResource:GetPlayer(playerID)
        if player then
            print("Sending GNV to player "..playerID)
            CustomGameEventManager:Send_ServerToPlayer(player, "gnv_register", {gnv=BuildingHelper.Encoded, squareX = BuildingHelper.squareX, squareY = BuildingHelper.squareY, boundX = BuildingHelper.minBoundX, boundY = BuildingHelper.minBoundY })
        end
    end
end

-- Used to find the closest builder to a building location
local GetClosestToPosition = function(unitList, position)
    local distance = math.huge
    local closest
    for _,unit in pairs(unitList) do
        local thisDistance = (unit:GetAbsOrigin()-position):Length2D()
        if thisDistance < distance then
            closest = unit
            distance = thisDistance
        end
    end
    return closest
end

-- Detects a Left Click with a builder through Panorama
function BuildingHelper:BuildCommand(args)
    local playerID = args['PlayerID']
    local x = args['X']
    local y = args['Y']
    local z = args['Z']
    local location = Vector(x, y, z)
    local queue = args['Queue'] == 1
    local builder = EntIndexToHScript(args['builder']) --activeBuilder

    -- Cancel current action
    if not queue then
        builder:Stop()
    end

    BuildingHelper:AddToQueue(builder, location, queue)
end

-- Detects a Right Click/Tab with a builder through Panorama
function BuildingHelper:CancelCommand(args)
    local playerID = args.PlayerID
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    playerTable.activeBuilding = nil

    local selectedEntities = PlayerResource:GetSelectedEntities(playerID)
    for _,entityIndex in pairs(selectedEntities) do
        local unit = EntIndexToHScript(entityIndex)
        if IsBuilder(unit) then
            BuildingHelper:ClearQueue(unit)
        end
    end
end

-- Detects a RightClick on a building with health deficit
function BuildingHelper:RepairCommand(args)
    local playerID = args.PlayerID
    local building = EntIndexToHScript(args.targetIndex)
    local selectedEntities = PlayerResource:GetSelectedEntities(playerID)
    local queue = tobool(args.queue)

    for _,entityIndex in pairs(selectedEntities) do
        local unit = EntIndexToHScript(entityIndex)

        if IsBuilder(unit) then
            -- Cancel current action
            if not queue then
                ExecuteOrderFromTable({UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_STOP, Queue = false})
            end

            -- Repair added to the queue
            BuildingHelper:AddRepairToQueue(unit, building, queue)
        end
    end
end

function BuildingHelper:OnSelectionUpdate(event)
    local playerID = event.PlayerID
    if not playerID then return end

    -- This is for Building Helper to know which is the currently active builder
    local mainSelected = PlayerResource:GetMainSelectedEntity(playerID)
    if not mainSelected then return end
    mainSelected = EntIndexToHScript(mainSelected)
    local player = BuildingHelper:GetPlayerTable(playerID)

    if IsValidEntity(mainSelected) then
        if IsBuilder(mainSelected) then
            player.activeBuilder = mainSelected
        else
            if IsValidEntity(player.activeBuilder) then
                -- Clear ghost particles when swapping to a non-builder
                BuildingHelper:StopGhost(player.activeBuilder)
            end
        end
    end
end

function BuildingHelper:OrderFilter(order)
    local ret = true

    if BuildingHelper.nextFilter then
        ret = BuildingHelper.nextFilter(BuildingHelper.nextContext, order)
    end

    if not ret then
        return false
    end

    local issuerID = order.issuer_player_id_const

    if issuerID == -1 then return true end

    local queue = order.queue == 1
    local order_type = order.order_type
    local units = order.units
    local abilityIndex = order.entindex_ability
    local targetIndex = order.entindex_target
    local unit = nil
    if units["0"] then
        unit = EntIndexToHScript(units["0"])
    end

    -- Item is dropped
    if order_type == DOTA_UNIT_ORDER_DROP_ITEM and IsBuilder(unit) then
        BuildingHelper:ClearQueue(unit)
        return true

    -- Stop and Hold
    elseif order_type == DOTA_UNIT_ORDER_STOP or order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
        if unit and IsBuilder(unit) then --Hold Stops instead
            order.order_type = DOTA_UNIT_ORDER_STOP
        end
        for n, unit_index in pairs(units) do
            local unit = EntIndexToHScript(unit_index)
            if IsBuilder(unit) then
                BuildingHelper:ClearQueue(unit)
            end
        end
        return true

    -- Casting non building abilities
    elseif (abilityIndex and abilityIndex ~= 0) and unit and IsBuilder(unit) then
        local ability = EntIndexToHScript(abilityIndex)
        if not IsBuildingAbility(ability) then
            BuildingHelper:ClearQueue(unit)
        end

        -- Repair Multi Order
        if order_type == DOTA_UNIT_ORDER_CAST_TARGET and BuildingHelper:GetRepairAbility(unit) then
            local ability = EntIndexToHScript(abilityIndex)
            local abilityName = ability:GetAbilityName()
            local target_handle = EntIndexToHScript(targetIndex)
            local target_name = target_handle:GetUnitName()

            if self:OnPreRepair(target_handle, unit) then
                -- print("Order: Repair "..target_handle:GetUnitName())

                -- Get the currently selected units and send new orders
                local entityList = PlayerResource:GetSelectedEntities(unit:GetPlayerOwnerID())
                if not entityList or #entityList == 1 then return true end

                for k,entityIndex in pairs(entityList) do
                    local ent = EntIndexToHScript(entityIndex)
                    local repair_ability = BuildingHelper:GetRepairAbility(ent)
                    if ent ~= unit and repair_ability then
                        if repair_ability:IsHidden() and ent.ReturnAbility then -- Swap to the repair ability
                            ent:SwapAbilities(repair_ability:GetAbilityName(), ent.ReturnAbility:GetAbilityName(), true, false)
                        end

                        ent.skip = true
                        -- print("Repair Multi Order "..target_handle:GetUnitName())
                        ExecuteOrderFromTable({UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
                    end
                end
            end
        end
    end


    return ret
end

-- Manages each workers build queue. Will run once per builder
function BuildingHelper:InitializeBuilder(builder)
    print("InitializeBuilder "..builder:GetUnitName().." "..builder:GetEntityIndex())

    if not builder.buildingQueue then
        builder.buildingQueue = {}
    end

    -- Store the builder entity indexes on a net table
    CustomNetTables:SetTableValue("builders", tostring(builder:GetEntityIndex()), { IsBuilder = true })
end

function BuildingHelper:RemoveBuilder(builder)
    -- Store the builder entity indexes on a net table
    CustomNetTables:SetTableValue("builders", tostring(builder:GetEntityIndex()), { IsBuilder = false })
end

-- Makes a building dummy and starts panorama ghosting
-- Builder calls this and sets the callbacks with the required values
function BuildingHelper:AddBuilding(keys)
    -- Callbacks
    local callbacks = BuildingHelper:SetCallbacks(keys)
    local builder = keys.caster
    local ability = keys.ability
    local abilName = ability:GetAbilityName()
    local buildingTable = BuildingHelper:SetupBuildingTable(abilName, builder)

    buildingTable:SetVal("AbilityHandle", ability)

    -- Prepare the builder, if it hasn't already been done
    if not builder.buildingQueue then
        BuildingHelper:InitializeBuilder(builder)
    end

    local size = buildingTable:GetVal("ConstructionSize", "number")
    local unitName = buildingTable:GetVal("UnitName", "string")

    -- Handle self-ghosting
    if unitName == "self" then
        unitName = builder:GetUnitName()
    end

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if not fMaxScale then
        -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = GetUnitKV(unitName, "ModelScale")
        if fModelScale then
          fMaxScale = fModelScale
        else
            fMaxScale = 1
        end
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    local color = Vector(255,255,255)
    if RECOLOR_GHOST_MODEL then
        color = Vector(0,255,0)
    end

    -- Basic event table to send
    local event = { state = "active", size = size, scale = fMaxScale, builderIndex = builder:GetEntityIndex() }

    -- Set the active variables and callbacks
    local playerID = builder:_GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    playerTable.activeBuilder = builder
    playerTable.activeBuilding = unitName
    playerTable.activeBuildingTable = buildingTable
    playerTable.activeCallbacks = callbacks

    -- Offset Z on the model particle
    event.modelOffset = GetUnitKV(unitName, "ModelOffset") or 0

    -- npc_dota_creature doesn't render cosmetics on the particle ghost, use hero names instead
    unitName = GetUnitKV(unitName, "OverrideBuildingGhost") or unitName

    -- Get a model dummy to pass it to panorama
    local mgd = BuildingHelper:GetOrCreateDummy(unitName)
    event.entindex = mgd:GetEntityIndex()

    -- Range overlay
    -- [simona] added 'else' block for vizualization of auras
    -- based on radius precached in BuildingHelper:GetOrCreateDummy
    if mgd:HasAttackCapability() then
        event.range = buildingTable:GetVal("AttackRange", "number") + mgd:GetHullRadius()
    elseif mgd.auraRadius then
        event.range = mgd.auraRadius
    end

    -- Make a pedestal dummy if required
    local pedestal = buildingTable:GetVal("PedestalModel")
    if pedestal then
        local prop = BuildingHelper:GetOrCreateProp(pedestal)
        mgd.prop = prop

        -- Add values to the event table
        event.propIndex = prop:GetEntityIndex()
        event.propScale = buildingTable:GetVal("PedestalModelScale", "float") or mgd:GetModelScale()
        event.offsetZ = buildingTable:GetVal("PedestalOffset", "float") or 0
    end

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    mgd:SetAngles(0, -yaw, 0)

    CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", event)
end

-- Defines a series of callbacks to be returned in the builder module
function BuildingHelper:SetCallbacks(keys)
    local callbacks = {}

    function keys:OnPreConstruction(callback)
        callbacks.onPreConstruction = callback -- Return false to abort the build
    end

     function keys:OnBuildingPosChosen(callback)
        callbacks.onBuildingPosChosen = callback -- Spend resources here
    end

    function keys:OnConstructionFailed(callback) -- Called if there is a mechanical issue with the building (cant be placed)
        callbacks.onConstructionFailed = callback
    end

    function keys:OnConstructionCancelled(callback) -- Called when player right clicks to cancel a queue
        callbacks.onConstructionCancelled = callback
    end

    function keys:OnConstructionStarted(callback)
        callbacks.onConstructionStarted = callback
    end

    function keys:OnConstructionCompleted(callback)
        callbacks.onConstructionCompleted = callback
    end

    function keys:OnBelowHalfHealth(callback)
        callbacks.onBelowHalfHealth = callback
    end

    function keys:OnAboveHalfHealth(callback)
        callbacks.onAboveHalfHealth = callback
    end

    return callbacks
end

-- Setup building table, returns a constructed table.
function BuildingHelper:SetupBuildingTable(abilityName, builderHandle)

    local buildingTable = GetKeyValue(abilityName)

    function buildingTable:GetVal(key, expectedType)
        local val = buildingTable[key]

        -- Return value directly if no second parameter
        if not expectedType then
            return val
        end

        -- Handle missing values.
        if val == nil then
            if expectedType == "bool" then
                return false
            else
                return nil
            end
        end

        -- Handle empty values
        local sVal = tostring(val)
        if sVal == "" then
            return nil
        end

        if expectedType == "bool" then
            return sVal == "1"
        elseif expectedType == "number" or expectedType == "float" then
            return tonumber(val)
        end
        return sVal
    end

    function buildingTable:SetVal(key, value)
        buildingTable[key] = value
    end

    -- Extract data from the KV files, set is called to guarantee these have values later on in execution
    local unitName = buildingTable:GetVal("UnitName", "string")
    if not unitName then
        print('Error: ' .. abilName .. ' does not have a UnitName KeyValue')
        return
    end
    buildingTable:SetVal("UnitName", unitName)

    -- Self ghosting
    if unitName == "self" then
        unitName = builderHandle:GetUnitName()
    end

    -- Ensure that the unit actually exists
    local unitTable = GetUnitKV(unitName)
    if not unitTable then
        print('Error: Definition for Unit ' .. unitName .. ' could not be found in the KeyValue files.')
        return
    end

    local construction_size = unitTable["ConstructionSize"]
    if not construction_size then
        print('Error: Unit ' .. unitName .. ' does not have a ConstructionSize KeyValue.')
        return
    end
    buildingTable:SetVal("ConstructionSize", construction_size)

    -- OverrideBuildingGhost
    local override_ghost = GetUnitKV(unitName, "OverrideBuildingGhost")
    if override_ghost then
        buildingTable:SetVal("OverrideBuildingGhost", override_ghost)
    end

    local build_time = buildingTable["BuildTime"] or unitTable["BuildTime"]
    if not build_time then
        print('Error: No BuildTime for ' .. unitName .. '. Default to 0.1')
        build_time = 0.1
    end
    buildingTable:SetVal("BuildTime", build_time)

    local attack_range = unitTable["AttackRange"] or 0
    buildingTable:SetVal("AttackRange", attack_range)

    local pathing_size = unitTable["BlockPathingSize"]
    if not pathing_size then
        print('Warning: Unit ' .. unitName .. ' does not have a BlockPathingSize KeyValue. Defaulting to 0')
        pathing_size = 0
    end
    buildingTable:SetVal("BlockPathingSize", pathing_size)

    -- Pedestal Model
    local pedestal_model = GetUnitKV(unitName, "PedestalModel")
    if pedestal_model then
        buildingTable:SetVal("PedestalModel", pedestal_model)
    end

    -- Pedestal Scale
    local pedestal_scale = GetUnitKV(unitName, "PedestalModelScale")
    if pedestal_scale then
        buildingTable:SetVal("PedestalModelScale", pedestal_scale)
    end

    -- Pedestal Offset
    local pedestal_offset = GetUnitKV(unitName, "PedestalOffset")
    if pedestal_offset then
        buildingTable:SetVal("PedestalOffset", pedestal_offset)
    end

    -- If the construction requires certain grid type, store it
    local requires = unitTable["Requires"]
    if not requires then
        requires = "Buildable"
    end
    buildingTable:SetVal("Requires", string.upper(requires))

    local prevents = unitTable["Prevents"]
    if prevents then
        buildingTable:SetVal("Prevents", string.upper(prevents))
    end

    local castRange = buildingTable:GetVal("AbilityCastRange", "number")
    if not castRange then
        castRange = 200
    end
    buildingTable:SetVal("AbilityCastRange", castRange)

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if not fMaxScale then
        -- If no MaxScale is defined, check the Units "ModelScale" KeyValue. Otherwise just default to 1
        fMaxScale = GetUnitKV(unitName, "ModelScale") or 1
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    -- local fModelRotation = buildingTable:GetVal("ModelRotation", "float")
    -- if not fModelRotation then
    --     -- If no defined, check the Units KeyValue. Otherwise just default to 0
    --     fModelRotation = GetUnitKV(unitName, "ModelRotation") or 0
    -- end

    -- [simona] added "AdditionalRotationData" field to buildingTable
    -- Extracted query function from original code above
    local GetValFromTableOrUnit = function(valueName, valueType)
        local value = buildingTable:GetVal(valueName, valueType)
        if not value then
            -- If not defined, check the Units KeyValue
            value = GetUnitKV(unitName, valueName)
        end
        return value
    end

    local fModelRotation = GetValFromTableOrUnit("ModelRotation", "float") or 0
    buildingTable:SetVal("ModelRotation", fModelRotation)
    local modelRotationMode = GetValFromTableOrUnit("ModelRotationMode")
    if modelRotationMode == "FACE_ENEMY_BASE" then
        buildingTable:SetVal("AdditionalRotationData", modelRotationMode)
    elseif modelRotationMode == "RANDOM" then
        local additionalRotationData = GetValFromTableOrUnit("ModelRandomRotationStep") or 1
        -- Make sure value is big enough for a chance of doing a ~359-degrees leap
        if additionalRotationData < (360/(MAX_MODEL_ROTATION_RANDOMIZATION_STEPS + 1)) then
            additionalRotationData = 360/(MAX_MODEL_ROTATION_RANDOMIZATION_STEPS + 1)
        end
        buildingTable:SetVal("AdditionalRotationData", additionalRotationData)
    end
    -- [simona] end of new block

    return buildingTable
end

-- Sends a builder to start the construction of a building
function BuildingHelper:OrderBuildingConstruction(builder, ability, position)
    ExecuteOrderFromTable({UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false})
    Build({caster=builder, ability=ability})
    BuildingHelper:AddToQueue(builder, position, false)
end

-- Places a new building on full health and returns the handle. Places grid nav blockers
-- Skips the construction phase and doesn't require a builder, this is most important to place the "base" buildings for the players when the game starts.
-- Make sure the position is valid before calling this in code.
function BuildingHelper:PlaceBuilding(player, name, location, construction_size, pathing_size, angle, team)
    construction_size = construction_size or BuildingHelper:GetConstructionSize(name)
    pathing_size = pathing_size or BuildingHelper:GetBlockPathingSize(name)
    BuildingHelper:SnapToGrid(construction_size, location)

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)

     -- Adjust the model position z
    local model_offset = GetUnitKV(name, "ModelOffset") or 0
    local model_location = Vector(location.x, location.y, location.z + model_offset)

    local building

    if player then
        local playerID = type(player)=="number" and player or player:GetPlayerID() --accept pass player ID or player Handle
        local player = PlayerResource:GetPlayer(playerID)
        local playersHero = PlayerResource:GetSelectedHeroEntity(playerID)
        -- print("PlaceBuilding for playerID ".. playerID)

        -- Spawn the building
        building = CreateUnitByName(name, model_location, false, playersHero, player, playersHero:GetTeamNumber())
        building:SetControllableByPlayer(playerID, true)
        building:SetOwner(playersHero)

        BuildingHelper:AddBuildingToPlayerTable(playerID, building)
    else
        -- print("PlaceBuilding for team ".. team)
        -- Spawn the building
        building = CreateUnitByName(name, model_location, false, nil, nil, team)
    end

    building:SetNeverMoveToClearSpace(true)
    building:SetAbsOrigin(model_location)
    building.construction_size = construction_size
    building.blockers = gridNavBlockers

    -- Building Settings
    BuildingHelper:AddModifierBuilding(building)

    -- Create pedestal
    local pedestal = GetUnitKV(name, "PedestalModel")
    if pedestal then
        BuildingHelper:CreatePedestalForBuilding(building, name, GetGroundPosition(location, nil), pedestal)
    end

    if angle then
        building:SetAngles(0,-angle,0)
    end

    return building
end

-- Replaces a building by a new one by name, updating the necessary references and returning the new created unit
function BuildingHelper:UpgradeBuilding(building, newName)
    local oldBuildingName = building:GetUnitName()
    -- print("Upgrading Building: "..oldBuildingName.." -> "..newName)
    local playerID = building:GetPlayerOwnerID()
    local position = building:GetAbsOrigin()
    -- local angle = GetUnitKV(newName, "ModelRotation") or -building:GetAngles().y
    -- [simona] added initial control rotation
    local angle = 0
    local basicRotation = GetUnitKV(newName, "ModelRotation")
    if basicRotation then
        angle = basicRotation
        local modelRotationMode = GetUnitKV(newName, "ModelRotationMode")
        if modelRotationMode == "FACE_ENEMY_BASE" then
            -- GOODGUYS face enemy base by default
            if building:GetOwner():GetTeam() == DOTA_TEAM_BADGUYS then
                angle = angle + 180
            end
        elseif modelRotationMode == "RANDOM" then
            local rotationRandomizationStep = GetUnitKV(newName, "ModelRandomRotationStep") or 1
            if rotationRandomizationStep < (360/(MAX_MODEL_ROTATION_RANDOMIZATION_STEPS + 1)) then
                rotationRandomizationStep = 360/(MAX_MODEL_ROTATION_RANDOMIZATION_STEPS + 1)
            end
            angle = angle + (RandomInt(0, MAX_MODEL_ROTATION_RANDOMIZATION_STEPS) * rotationRandomizationStep)
        end
    else
        angle = -building:GetAngles().y
    end
    -- end of new block

    local old_offset = GetUnitKV(oldBuildingName, "ModelOffset") or 0
    position.z = position.z - old_offset

    -- Kill the old building
    building:AddEffects(EF_NODRAW) --Hide it, so that it's still accessible after this script
    building.upgraded = true --Skips visual effects
    ForceKill(building)

    -- Create the new building
    local new_building = BuildingHelper:PlaceBuilding(playerID, newName, position, BuildingHelper:GetConstructionSize(newName), BuildingHelper:GetBlockPathingSize(newName), angle)

    -- If there were units repairing the old building, redirect them to the new building
    if building.units_repairing then
        for _,builder in pairs(building.units_repairing) do
            builder.repair_target = new_building
        end
    end
    new_building.units_repairing = building.units_repairing
    building.upgraded_to = new_building

    return new_building
end

-- Removes a building, removing it from the gridnav, with an optional parameter to skip particle effects
function BuildingHelper:RemoveBuilding(building, bSkipEffects)
    local buildingName = building:GetUnitName()
    -- print("Removing Building: "..buildingName)

    -- Don't show the destruction effects when specified or killed to due UpgradeBuilding
    if not bSkipEffects and building.upgraded ~= true then
        local particleName = building:GetKeyValue("DestructionEffect")
        if particleName then
            local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, building)
            ParticleManager:SetParticleControlEnt(particle, 0, building, PATTACH_POINT_FOLLOW, "attach_origin", building:GetAbsOrigin(), true)
        end

        if building.fireEffectParticle then
            ParticleManager:DestroyParticle(building.fireEffectParticle, false)
        end
    end

    if building.prop then
        UTIL_Remove(building.prop)
    end

    BuildingHelper:FreeGridSquares(BuildingHelper:GetConstructionSize(building), building:GetAbsOrigin())

    -- Remove handle and decrement count tracking
    local playerID = building:GetPlayerOwnerID()
    local buidingList = BuildingHelper:GetBuildings(playerID)
    local index = getIndexTable(buidingList, building)
    if index then
        table.remove(buidingList, index)
        BuildingHelper:SetBuildingCount(playerID, buildingName, BuildingHelper:GetBuildingCount(playerID, buildingName)-1)
    else
        buildingList = BuildingHelper:GetBuildingsUnderConstruction(playerID)
        index = getIndexTable(buildingList, building)
        if index then
            table.remove(buildingList, index)
            local constructionCount = self:GetBuildingCount(playerID, buildingName, true)
            self:SetBuildingCount(playerID, buildingName, constructionCount-1, true)
        end
    end

    if not building.blockers then return end
    for k, v in pairs(building.blockers) do
        UTIL_Remove(v)
    end
end

-- Creates the building and starts the construction process
function BuildingHelper:StartBuilding(builder)
    -- VicFrank for controlling leavers, the constructed building should be owned by the hero
    -- local playerID = builder:_GetMainControllingPlayer()
    local playerID = builder:GetPlayerOwnerID()
    local work = builder.work
    local callbacks = work.callbacks
    local building = work.entity -- The building entity
    local unitName = work.name
    local location = work.location
    local player = PlayerResource:GetPlayer(playerID)
    local playersHero = PlayerResource:GetSelectedHeroEntity(playerID)
    local buildingTable = work.buildingTable
    local construction_size = buildingTable:GetVal("ConstructionSize", "number")
    local pathing_size = buildingTable:GetVal("BlockPathingSize", "number")

    -- Check gridnav and cancel if invalid
    if not BuildingHelper:ValidPosition(construction_size, location, builder, callbacks) then

        -- Remove the model particle and Advance Queue
        BuildingHelper:AdvanceQueue(builder)
        BuildingHelper:ClearWorkParticles(work)

        -- Remove pedestal
        BuildingHelper:RemoveEntity(work.entity.prop)

        -- Building canceled, refund resources
        work.refund = true
        callbacks.onConstructionCancelled(work)
        return
    end

    -- print("Initializing Building Entity: "..unitName.." at "..VectorString(location))

    -- Mark this work in progress, skip refund if cancelled as the building is already placed
    work.inProgress = true

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)

    -- For overriden ghosts we need to create another unit
    if building:GetUnitName() ~= unitName then
        -- [simona] Copy angles, set by AddToQueue, to new entity
        local angles = building:GetAnglesAsVector()
        building = CreateUnitByName(unitName, location, false, playersHero, player, builder:GetTeam())
        building:SetNeverMoveToClearSpace(false)
        building:SetAngles(angles.x, angles.y, angles.z)
    else
        building:RemoveModifierByName("modifier_out_of_world")
        building:RemoveEffects(EF_NODRAW)
    end

    -- Make pedestal
    local pedestal = GetUnitKV(unitName, "PedestalModel")
    if pedestal then
        BuildingHelper:CreatePedestalForBuilding(building, unitName, location, pedestal)
    end

    -- Initialize the building
    local model_offset = GetUnitKV(unitName, "ModelOffset") or 0
    location.z = location.z + model_offset
    building:SetAbsOrigin(location)
    building.blockers = gridNavBlockers
    building.construction_size = construction_size
    building.buildingTable = buildingTable
    self:AddBuildingToPlayerTable(playerID, building, true)

    -- [simona] model orientation allready set by AddToQueue
    -- Adjust the Model Orientation
    -- local yaw = buildingTable:GetVal("ModelRotation", "float")
    -- building:SetAngles(0, -yaw, 0)

    -- Building Settings
    BuildingHelper:AddModifierBuilding(building)

    -- Prevent regen messing with the building spawn hp gain
    local regen = building:GetBaseHealthRegen()
    building:SetBaseHealthRegen(0)

    ------------------------------------------------------------------
    -- Build Behaviours
    --  RequiresRepair: If set to 1 it will place the building and not update its health nor send the OnConstructionCompleted callback until its fully healed
    --  BuilderInside: Puts the builder unselectable/invulnerable/nohealthbar inside the building in construction
    --  ConsumesBuilder: Kills the builder after the construction is done
    local bRequiresRepair = buildingTable:GetVal("RequiresRepair", "bool")
    local bBuilderInside = buildingTable:GetVal("BuilderInside", "bool")
    local bConsumesBuilder = buildingTable:GetVal("ConsumesBuilder", "bool")
    -------------------------------------------------------------------

    -- whether the building is controllable or not
    local bPlayerCanControl = buildingTable:GetVal("PlayerCanControl", "bool")
    if bPlayerCanControl then
        building:SetControllableByPlayer(playerID, true)
        building:SetOwner(playersHero)
    end

    -- Start construction
    if callbacks.onConstructionStarted then
        callbacks.onConstructionStarted(building)
    end

    -- buildTime can be overriden in the construction start callback
    local buildTime = buildingTable:GetVal("BuildTime", "float")
    building.buildTime = buildTime
    if building.overrideBuildTime then buildTime = building.overrideBuildTime end

    local startTime = GameRules:GetGameTime()
    local fTimeBuildingCompleted = startTime+buildTime -- the gametime when the building should be completed

    -- Dota server updates at 30 frames per second
    local fserverFrameRate = 1/30

    -- Max and Initial Health factor
    local fMaxHealth = building:GetMaxHealth()
    local fInitialHealthFactor = BuildingHelper.Settings["INITIAL_HEALTH_FACTOR"]
    local nInitialHealth = math.floor(fInitialHealthFactor * (fMaxHealth))
    local fUpdateHealthInterval = math.max(fserverFrameRate, buildTime / math.floor(fMaxHealth-nInitialHealth)) -- health tick interval
    building:SetHealth(nInitialHealth)

    local bScale = buildingTable:GetVal("Scale", "bool") -- whether we should scale the building.
    local fInitialModelScale = 0.2 -- initial size
    local fMaxScale = building.overrideMaxScale or buildingTable:GetVal("MaxScale", "float") or 1 -- the amount to scale to
    local fScaleInterval = (fMaxScale-fInitialModelScale) / (buildTime / fserverFrameRate) -- scale to add every frame, distributed by build time
    local fCurrentScale = fInitialModelScale -- start the building at the initial model scale
    local bScaling = false -- Keep tracking if we're currently model scaling.

    -- Set initial scale
    if bScale then
        building:SetModelScale(fCurrentScale)
        bScaling = true
    end

    -- Put the builder invulnerable inside the building in construction
    if bBuilderInside then
        BuildingHelper:HideBuilder(builder, location, building)
    end

    -- Health Update Timer and Behaviors
    if not bRequiresRepair then

        if not bBuilderInside then
            -- Advance Queue
            BuildingHelper:AdvanceQueue(builder)
        end

        local fAddedHealth = 0
        -- VicFrank, added second added health to calculate how much damage it took while being built
        building.addedHealth = 0
        building.initialHealth = nInitialHealth
        local nHealthInterval = (fMaxHealth-nInitialHealth) / (buildTime / fserverFrameRate)
        local fSmallHealthInterval = nHealthInterval - math.floor(nHealthInterval) -- just the floating point component
        nHealthInterval = math.floor(nHealthInterval)
        local fHPAdjustment = 0

        building.updateHealthTimer = Timers:CreateTimer(function()
            if IsValidEntity(building) and building:IsAlive() then
                local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted or building:GetHealth() == building:GetMaxHealth()
                if not timesUp then
                    -- Use +1 every frame or float adjustment
                    local hpGain = 0
                    if fUpdateHealthInterval <= fserverFrameRate then
                        fHPAdjustment = fHPAdjustment + fSmallHealthInterval
                        if fHPAdjustment > 1 then
                            hpGain = nHealthInterval + 1
                            fHPAdjustment = fHPAdjustment - 1
                        else
                            hpGain = nHealthInterval
                        end
                    else
                        hpGain = 1
                    end

                    -- Fasten up
                    if GameRules.WarpTen then
                        hpGain = hpGain * 42
                    end

                    if hpGain > 0 then
                        fAddedHealth = fAddedHealth + hpGain
                        building.addedHealth = building.addedHealth + hpGain
                        building:SetHealth(building:GetHealth() + hpGain)
                    end
                else
                    local adjustment = fMaxHealth - fAddedHealth - nInitialHealth
                    if adjustment > 0 then
                        building:SetHealth(building:GetHealth() + fMaxHealth - fAddedHealth - nInitialHealth) -- round up the last little bit
                    end
                    -- print(string.format("Finished %s in %.2f seconds. HP was off by %.2f",building:GetUnitName(),GameRules:GetGameTime()-startTime,adjustment))

                    -- completion: timesUp is true
                    if callbacks.onConstructionCompleted then
                        building.constructionCompleted = true
                        building.builder = builder
                        BuildingHelper:AddBuildingToPlayerTable(playerID, building)
                        callbacks.onConstructionCompleted(building)
                    end

                    -- Eject Builder
                    if bBuilderInside then

                        -- Consume Builder
                        if bConsumesBuilder then
                            ForceKill(builder)
                        else
                            BuildingHelper:ShowBuilder(builder)
                        end

                        -- Advance Queue
                        BuildingHelper:AdvanceQueue(builder)
                    end

                    return
                end
            else
                -- Building destroyed

                -- Eject Builder
                if bBuilderInside then
                    builder:RemoveModifierByName("modifier_builder_hidden")
                    builder:RemoveNoDraw()
                end

                -- Advance Queue
                BuildingHelper:AdvanceQueue(builder)

                return nil
            end
            return fUpdateHealthInterval
        end)
    else
        -- The building will have to be assisted through a repair ability
        local repair_ability = BuildingHelper:GetRepairAbility(builder)
        if repair_ability then
            -- print("Building "..building:GetUnitName().." will be constructed using RepairAbility")
            building.repair_distance = (builder:GetAbsOrigin() - building:GetAbsOrigin()):Length2D() -- To instantly start repairing
            building.callbacks = callbacks
            BuildingHelper:StartRepair(builder, building)
        else
            print("Error, couldn't find \"RepairAbility\" of "..builder:GetUnitName())
        end
    end

    -- Scale Update Timer
    if bScale then
        building.updateScaleTimer = Timers:CreateTimer(function()
            if IsValidEntity(building) and building:IsAlive() then
                local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted
                if not timesUp then
                    if bScaling then
                        if fCurrentScale < fMaxScale then
                            fCurrentScale = fCurrentScale+fScaleInterval
                            building:SetModelScale(fCurrentScale)
                        else
                            building:SetModelScale(fMaxScale)
                            bScaling = false
                        end
                    end
                else

                    -- print("Scale was off by: "..(fMaxScale - fCurrentScale))
                    building:SetModelScale(fMaxScale)
                    return
                end
            else
                -- not valid ent
                return
            end

            return fserverFrameRate
        end)
    end

    -- OnBelowHalfHealth timer
    building.onBelowHalfHealthProc = false
    building.healthChecker = Timers:CreateTimer(.2, function()
        local fireEffect = GetUnitKV(unitName, "FireEffect")
        local attachPoint = GetUnitKV(unitName, "AttachPoint")

        if IsValidEntity(building) and building:IsAlive() then
            local health_percentage = building:GetHealthPercent() * 0.01
            local belowThreshold = health_percentage < BuildingHelper.Settings["FIRE_EFFECT_FACTOR"]
            if belowThreshold and not building.onBelowHalfHealthProc and building.state == "complete" then
                if fireEffect then
                    -- Fire particle
                    if attachPoint then
                        building.fireEffectParticle = ParticleManager:CreateParticle(fireEffect, PATTACH_CUSTOMORIGIN_FOLLOW, building)
                        ParticleManager:SetParticleControlEnt(building.fireEffectParticle, 0, building, PATTACH_POINT_FOLLOW, attachPoint, building:GetAbsOrigin(), true)
                    else
                        building.fireEffectParticle = ParticleManager:CreateParticle(fireEffect, PATTACH_ABSORIGIN_FOLLOW, building)
                    end
                end

                callbacks.onBelowHalfHealth(building)
                building.onBelowHalfHealthProc = true
            elseif not belowThreshold and building.onBelowHalfHealthProc and building.state == "complete" then
                if fireEffect then
                    ParticleManager:DestroyParticle(building.fireEffectParticle, false)
                end

                callbacks.onAboveHalfHealth(building)
                building.onBelowHalfHealthProc = false
            end
        else
            return nil
        end
        return .2
    end)

    -- Remove the work particles
    BuildingHelper:ClearWorkParticles(work)
end

-- Starts the repair process when the builder is on range of the target
function BuildingHelper:StartRepair(builder, target)
    local work = builder.work
    -- VicFrank castle doesn't have IsUnderConstruction()
    local underConstruction = IsCustomBuilding(target) and not target:GetUnitName() == "castle" and target:IsUnderConstruction() -- For RequiresRepair building behaviour
    -- Check target and cancel if invalid
    local repair_ability = BuildingHelper:GetRepairAbility(builder)
    if underConstruction and repair_ability and not repair_ability:GetKeyValue("CanAssistConstruction") then
        -- print("The Repair Ability "..repair_ability:GetAbilityName().." can't be used to assist construction! Cancelling")

        -- Advance Queue
        BuildingHelper:AdvanceQueue(builder)

        BuildingHelper:OnRepairCancelled(builder, target)
        return
    end

    -- External repair callback
    self:OnRepairStarted(builder, target)

    -- Initialize builder list
    target.units_repairing = target.units_repairing or {}
    table.insert(target.units_repairing, builder)
    builder.repair_target = target

    -- Look towards the building
    builder:Stop()
    builder:SetForwardVector((target:GetAbsOrigin() - builder:GetAbsOrigin()):Normalized())

    local buildTime = target.buildTime or target:GetKeyValue("BuildTime")
    local costRatio = repair_ability and repair_ability:GetKeyValue("RepairCostRatio") or BuildingHelper.Settings.REPAIR_SETTINGS["RepairCostRatio"]
    local timeRatio = repair_ability and repair_ability:GetKeyValue("RepairTimeRatio") or BuildingHelper.Settings.REPAIR_SETTINGS["RepairTimeRatio"]
    local powerBuildCost = repair_ability and repair_ability:GetKeyValue("PowerbuildCost") or BuildingHelper.Settings.REPAIR_SETTINGS["PowerbuildCost"]
    local powerBuildRate = repair_ability and repair_ability:GetKeyValue("PowerbuildRate") or BuildingHelper.Settings.REPAIR_SETTINGS["PowerbuildRate"]

    -- C++ -> Lua Double nonsense
    function correctFloat(f) return tonumber(string.format("%.4f", f)) end
    timeRatio = correctFloat(timeRatio)
    costRatio = correctFloat(costRatio)
    powerBuildCost = correctFloat(powerBuildCost)
    powerBuildRate = correctFloat(powerBuildRate)

    local fserverFrameRate = 1/30
    local fAddedHealth = 0
    local fHPAdjustment = 0

    local repairing = {}
    for k,v in pairs(target.units_repairing) do
        if IsValidEntity(v) and v:IsAlive() then
            table.insert(repairing, v)
        end
    end
    target.units_repairing = repairing

    builder.state = "repairing"
    builder.lastRepairPosition = builder:GetAbsOrigin()
    builder:AddNewModifier(builder, repair_ability, "modifier_builder_repairing", {})
    target:AddNewModifier(target, repair_ability, "modifier_repairing", {})
    target:SetModifierStackCount("modifier_repairing", target, getTableCount(target.units_repairing))

    -- If its an unfinished building, keep track of how much does it require to mark as finished
    if underConstruction and not target.missingHealthToComplete then
        target.missingHealthToComplete = target:GetHealthDeficit()
    end

    -- Repair Dynamic Tick
    if not target.repairTimer then
        target.repairTimer = Timers:CreateTimer(function()
            local builderCount = 0
            for k,v in pairs(target.units_repairing) do
                if IsValidEntity(v) and v:IsAlive() then builderCount = builderCount + 1 end
            end

            if not IsValidEntity(target) or not target:IsAlive() then
                if target and target.units_repairing and not target.upgraded then
                    self:CancelRepair(target)
                    return
                end

                -- Redirect in case of upgrade
                if target.upgraded and target.units_repairing then
                    target = target.upgraded_to
                    if not IsValidEntity(repair_ability) then
                        repair_ability = target.units_repairing[1]:GetRepairAbility()
                    end
                    if not IsValidEntity(repair_ability) then
                        print("Something went wrong, couldn't get a RepairAbility on the first repairing unit")
                    else
                        target:AddNewModifier(target, repair_ability, "modifier_repairing", {})
                    end
                end
            end

            target:SetModifierStackCount("modifier_repairing", target, builderCount)
            if builderCount == 0 then
                self:CancelRepair(target)
                return
            end

            -- Finished repairing?
            local health_deficit = target.missingHealthToComplete or target:GetHealthDeficit()
            if health_deficit <= 0 then
                target.missingHealthToComplete = nil
                self:CancelRepair(target)

                if target.callbacks and target.callbacks.onConstructionCompleted then
                    target.constructionCompleted = true
                    BuildingHelper:AddBuildingToPlayerTable(target:GetPlayerOwnerID(), target)
                    target.callbacks.onConstructionCompleted(target)
                end

                self:OnRepairFinished(builder, target)
                return
            end

            -- Builders must be stopped and close to the target to count and heal hitpoints
            builderCount = BuildingHelper:GetNumBuildersRepairing(target)
            if builderCount == 0 then return fserverFrameRate end

            local buildTimeFactor = timeRatio*(powerBuildRate^(builderCount-1))
            -- VicFrank
            -- local nextTick = (buildTime*buildTimeFactor)/target:GetMaxHealth()
            local nextTick = fserverFrameRate
            local hpGain = 0

            -- Calculate the HP to be gained on this tick
            if nextTick > fserverFrameRate then
                hpGain = 1
            else
                --VicFrank
                -- local nHealthInterval = target:GetMaxHealth() / (buildTime*buildTimeFactor / fserverFrameRate)
                local repairHealRate = REPAIR_HEAL_RATE * (builderCount-1) + REPAIR_HEAL_RATE / (2 ^ (builderCount-1))
                local nHealthInterval = repairHealRate * fserverFrameRate
                local fSmallHealthInterval = nHealthInterval - math.floor(nHealthInterval) --floating point component
                nHealthInterval = math.floor(nHealthInterval)

                -- How much HP do we add this frame?
                fHPAdjustment = fHPAdjustment + fSmallHealthInterval
                if fHPAdjustment > 1 then
                    fHPAdjustment = fHPAdjustment - 1
                    hpGain = nHealthInterval + 1
                elseif nHealthInterval > 0 then
                    hpGain = nHealthInterval
                end

                nextTick = fserverFrameRate
            end

            local buildCostFactor = costRatio + powerBuildCost*(builderCount-1)

            -- Don't expend resources for the first unit repairing a building if its a construction
            if underConstruction then
                if builderCount == 1 then
                    buildCostFactor = 0
                else
                    buildCostFactor = costRatio + powerBuildCost*(builderCount-2)
                end
            end

            -- Fasten up
            if GameRules.WarpTen then
                hpGain = hpGain * 42
                buildCostFactor = buildCostFactor * 42
            end

            if hpGain > 0 then
                if target.missingHealthToComplete then
                    target.missingHealthToComplete = target.missingHealthToComplete - hpGain
                end
                local bCanPayResource = true
                if buildCostFactor > 0 then
                    bCanPayResource = self:OnRepairTick(target, hpGain, buildCostFactor) ~= false
                end

                if bCanPayResource then
                    --print("Repaired "..target:GetUnitName().." with "..builderCount.." builders for "..hpGain.." | Time Factor: "..buildTimeFactor.." | Cost Factor: "..buildCostFactor)
                    target:SetHealth(target:GetHealth() + hpGain)
                else
                    print("Repair Ended, not enough resources!")
                    self:CancelRepair(target)
                    return
                end
            end

            return nextTick
        end)
    end
end

function BuildingHelper:GetNumBuildersRepairing(target)
    if not target.units_repairing then return 0 end

    local targetPos = target:GetAbsOrigin()
    local numReparing = 0
    for _,unit in pairs(target.units_repairing) do
        if IsValidEntity(unit) then
            local currentPos = unit:GetAbsOrigin()
            if not unit.lastRepairPosition then
                unit.lastRepairPosition = currentPos
                unit.state = "repairing"
                numReparing = numReparing + 1
            else
                local changedPosition = (unit.lastRepairPosition-currentPos):Length2D() > 1
                if changedPosition or (targetPos-currentPos):Length2D() > (unit.repairRange or unit:GetFollowRange(target)) then
                    unit.state = "moving_to_repair"
                    unit:MoveToNPC(target)
                else
                    unit.state = "repairing"
                    numReparing = numReparing + 1
                end
                unit.lastRepairPosition = currentPos
            end
        end
    end
    return numReparing
end

function BuildingHelper:CancelRepair(building)
    building.repairTimer = nil
    if building.units_repairing == nil then return end
    for k,v in pairs(building.units_repairing) do
        if IsValidEntity(v) and v:IsAlive() then
            v:RemoveModifierByName("modifier_builder_repairing")
            local repair_ability = BuildingHelper:GetRepairAbility(v)
            if repair_ability and repair_ability:GetToggleState() then
                repair_ability:ToggleAbility()
            end
            v.state = "idle"
            if IsValidEntity(building) then
                self:OnRepairCancelled(v, building)
            end
            BuildingHelper:AdvanceQueue(v)
        end
    end
    building.units_repairing = {}

    if IsValidEntity(building) then
        building:RemoveModifierByName("modifier_repairing")
        -- print("Repair of "..building:GetUnitName().." fully cancelled")
    else
        print("Building removed during the repair process")
    end
end

-- Blocks a square of certain construction and pathing size at a location on the server grid
-- construction_size: square of grid points to block from construction
-- pathing_size: square of pathing obstructions that will be spawned
function BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)
    BuildingHelper:RemoveGridType(construction_size, location, "BUILDABLE")
    BuildingHelper:AddGridType(construction_size, location, "BLOCKED")

    return BuildingHelper:BlockPSO(pathing_size, location)
end

-- Spawns a square of point_simple_obstruction entities at a location
function BuildingHelper:BlockPSO(size, location)
    if size == 0 then return end

    local pos = Vector(location.x, location.y, location.z)
    BuildingHelper:SnapToGrid(size, pos)

    local gridNavBlockers = {}
    if size % 2 == 1 then
        for x = pos.x - (size-2) * 32, pos.x + (size-2) * 32, 64 do
            for y = pos.y - (size-2) * 32, pos.y + (size-2) * 32, 64 do
                local blockerLocation = Vector(x, y, pos.z)
                local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                table.insert(gridNavBlockers, ent)
            end
        end
    else
        local len = size * 32 - 64
        if len == 0 then
            local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = pos})
            table.insert(gridNavBlockers, ent)
        else
            for x = pos.x - len, pos.x + len, 128 do
                for y = pos.y - len, pos.y + len, 128 do
                    local blockerLocation = Vector(x, y, pos.z)
                    local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                    table.insert(gridNavBlockers, ent)
                end
            end
        end
    end

    return gridNavBlockers
end

-- Clears out an area for construction
function BuildingHelper:FreeGridSquares(construction_size, location)
    BuildingHelper:RemoveGridType(construction_size, location, "BLOCKED")
    BuildingHelper:AddGridType(construction_size, location, "BUILDABLE")
end

function BuildingHelper:NewGridType(grid_type)
    grid_type = string.upper(grid_type)
    BuildingHelper.GridTypes[grid_type] = BuildingHelper.NextGridValue
    BuildingHelper.NextGridValue = BuildingHelper.NextGridValue * 2
    CustomNetTables:SetTableValue("building_settings", "grid_types", BuildingHelper.GridTypes)
end

-- Adds a grid_type to a square of size at centered at a location
function BuildingHelper:AddGridType(size, location, grid_type, shape)
    -- If it doesn't exist, add it
    grid_type = string.upper(grid_type)
    if not BuildingHelper.GridTypes[grid_type] then
        BuildingHelper:NewGridType(grid_type)
    end

    if shape == "radius" then
        BuildingHelper:SetGridTypeRadius(size, location, grid_type, "add")
    else
        BuildingHelper:SetGridType(size, location, grid_type, "add")
    end
end

-- Removes grid_type from every cell of a square around the location
function BuildingHelper:RemoveGridType(size, location, grid_type, shape)
    if shape == "radius" then
        BuildingHelper:SetGridTypeRadius(size, location, grid_type, "remove")
    else
        BuildingHelper:SetGridType(size, location, grid_type, "remove")
    end
end

-- Central function used to add, remove or override multiple grid squares at once
function BuildingHelper:SetGridType(size, location, grid_type, option)
    if not size or size == 0 then return end

    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- print('Pos x: ' .. originX .. ' y: ' .. originY)

    -- Adjust even size
    if (size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    -- Adjust to upper case
    grid_type = string.upper(grid_type)

    -- Default by omission is to override the old value
    if not option then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                BuildingHelper.Grid[y][x] = BuildingHelper.GridTypes[grid_type]
            end
        end

    elseif option == "add" then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                -- Only add if it doesn't have it yet
                local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_type)
                if not hasGridType then
                    BuildingHelper.Grid[y][x] = BuildingHelper.Grid[y][x] + BuildingHelper.GridTypes[grid_type]
                end
            end
        end

    elseif option == "remove" then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                -- Only remove if it has it
                local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_type)
                if hasGridType then
                    BuildingHelper.Grid[y][x] = BuildingHelper.Grid[y][x] - BuildingHelper.GridTypes[grid_type]
                end
            end
        end
    end
end

-- Alternative with radius
function BuildingHelper:SetGridTypeRadius(radius, location, grid_type, option)
    if not radius or radius == 0 then return end

    -- Adjust radius to size
    local size = (radius - (radius%32))/32

    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust to upper case
    grid_type = string.upper(grid_type)

    -- Default by omission is to override the old value
    if not option then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                local current_pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
                local distance = (current_pos - location):Length2D()
                if distance <= radius then
                    BuildingHelper.Grid[y][x] = BuildingHelper.GridTypes[grid_type]
                end
            end
        end

    elseif option == "add" then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                -- Only add if it doesn't have it yet
                local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_type)
                if not hasGridType then
                    local current_pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
                    local distance = (current_pos - location):Length2D()
                    if distance <= radius then
                        BuildingHelper.Grid[y][x] = BuildingHelper.Grid[y][x] + BuildingHelper.GridTypes[grid_type]
                    end
                end
            end
        end

    elseif option == "remove" then
         for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                -- Only remove if it has it
                local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_type)
                if hasGridType then
                    local current_pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
                    local distance = (current_pos - location):Length2D()
                    if distance <= radius then
                        BuildingHelper.Grid[y][x] = BuildingHelper.Grid[y][x] - BuildingHelper.GridTypes[grid_type]
                    end
                end
            end
        end
    end
end

-- Returns a string with each of the grid types of the cell, mostly to debug
function BuildingHelper:GetCellGridTypes(x,y)
    local s = ""
    for grid_string,value in pairs(BuildingHelper.GridTypes) do
        local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_string)
        if hasGridType then
            s = s..grid_string.." "
        end
    end
    return s
end

-- Checks if the cell has a certain grid type by name
function BuildingHelper:CellHasGridType(x, y, grid_type)
    if BuildingHelper.GridTypes[grid_type] then
        return bit.band(BuildingHelper.Grid[y][x], BuildingHelper.GridTypes[grid_type]) ~= 0
    end
end

-- Checks GridNav square of certain size at a location. Sends onConstructionFailed if invalid
function BuildingHelper:ValidPosition(size, location, unit, callbacks)
    local bBlocked

    -- Check for special requirement
    local playerTable = BuildingHelper:GetPlayerTable(unit:GetPlayerOwnerID())
    local buildingName = playerTable.activeBuilding
    if unit.work then buildingName = unit.work.name end
    local buildingTable = buildingName and GetUnitKV(buildingName)
    local requires = buildingTable and buildingTable["Requires"]
    local prevents = buildingTable and buildingTable["Prevents"]

    if requires then
        bBlocked = not BuildingHelper:AreaMeetsCriteria(size, location, requires, "all")
    else
        bBlocked = BuildingHelper:IsAreaBlocked(size, location)
    end

    if prevents then
        bBlocked = bBlocked or BuildingHelper:AreaMeetsCriteria(size, location, prevents, "one")
    end

    if bBlocked then
        if callbacks.onConstructionFailed then
            callbacks.onConstructionFailed()
        end
        return false
    end

    -- Check enemy units blocking the area
    local construction_radius = size * 64
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
    local enemies = FindUnitsInRadius(unit:GetTeamNumber(), location, nil, construction_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

    for _,enemy in pairs(enemies) do
        local origin = enemy:GetAbsOrigin()
        if not IsCustomBuilding(enemy) and BuildingHelper:EnemyIsInsideBuildingArea(enemy:GetAbsOrigin(), location, size) then
            if callbacks.onConstructionFailed then
                callbacks.onConstructionFailed()
            end
            return false
        end
    end

    return true
end

function BuildingHelper:GetBounds(point, len)
    local bounds = {}
    local X1 = point.x + len
    local X2 = point.x - len
    local Y1 = point.y + len
    local Y2 = point.y - len
    bounds.Min = {x=math.min(X1, X2),y=math.min(Y1, Y2)}
    bounds.Max = {x=math.max(X1, X2),y=math.max(Y1, Y2)}
    return bounds
end

function BuildingHelper:EnemyIsInsideBuildingArea(enemy_location, building_location, size)
    local bBounds = BuildingHelper:GetBounds(building_location, size * 32)

    -- Enemy covers 2x2 squares
    BuildingHelper:SnapToGrid(2, enemy_location)
    local eBounds = BuildingHelper:GetBounds(enemy_location, 64)

    local function between(num, lower, upper)
        return num < upper and num > lower
    end

    local betweenX = between(eBounds.Min.x, bBounds.Min.x, bBounds.Max.x) or between(eBounds.Max.x, bBounds.Min.x, bBounds.Max.x) or between(enemy_location.x,bBounds.Min.x,bBounds.Max.x)
    local betweenY = between(eBounds.Min.y, bBounds.Min.y, bBounds.Max.y) or between(eBounds.Max.y, bBounds.Min.y, bBounds.Max.y) or between(enemy_location.y,bBounds.Min.y,bBounds.Max.y)

    return betweenX and betweenY
end

-- If not all squares are buildable, the area is blocked
function BuildingHelper:IsAreaBlocked(size, location)
    return BuildingHelper:AreaMeetsCriteria(size, location, "BLOCKED", "one")
end

-- Checks that all squares meet each of the passed grid_type criteria (can be multiple, split by spaces)
function BuildingHelper:AreaMeetsCriteria(size, location, grid_type, option)
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    if (size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    -- Default by omission is to check if all the cells meet the criteria
    if not option or option == "all" then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                local grid_types = split(grid_type, " ")
                for k,v in pairs(grid_types) do
                    local t = string.upper(v)
                    local hasGridType = BuildingHelper:CellHasGridType(x,y,t)
                    if not hasGridType then
                        return false
                    end
                end
            end
        end
        return true -- all cells have the grid types

    -- When searching for one block, stop at the first grid point found with every type
    elseif option == "one" then
        for y = lowerBoundY, upperBoundY do
            for x = lowerBoundX, upperBoundX do
                local grid_types = split(grid_type, " ")
                local hasGridType = true
                for k,v in pairs(grid_types) do
                    local t = string.upper(v)
                    hasGridType = hasGridType and BuildingHelper:CellHasGridType(x,y,t)
                end

                if hasGridType then
                    return true
                end
            end
        end
        return false -- no cells meet the criteria
    end
end

-- Adds a location to the builders work queue
-- bQueued will be true if the command was done with shift pressed
-- If bQueued is false, the queue is cleared and this building is put on top
function BuildingHelper:AddToQueue(builder, location, bQueued)
    local playerID = builder:_GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    local buildingName = playerTable.activeBuilding
    local buildingTable = playerTable.activeBuildingTable
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    local size = buildingTable:GetVal("ConstructionSize", "number")
    local pathing_size = buildingTable:GetVal("BlockGridNavSize", "number")
    local callbacks = playerTable.activeCallbacks

    BuildingHelper:SnapToGrid(size, location)

    -- Check gridnav
    if not BuildingHelper:ValidPosition(size, location, builder, callbacks) then
        return
    end

    -- External pre construction checks
    if callbacks.onPreConstruction then
        local result = callbacks.onPreConstruction(location)
        if result == false then
            return
        end
    end

    -- print("AddToQueue "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> location "..VectorString(location))

    -- Make the new work entry
    local work = {["location"] = location, ["name"] = buildingName, ["buildingTable"] = buildingTable, ["callbacks"] = callbacks}

    -- Position chosen is initially valid, send callback to spend gold
    callbacks.onBuildingPosChosen(location)

    -- Self placement doesn't make ghost particles on the placement area
    if builder:GetUnitName() == buildingName then
        -- Never queued
        BuildingHelper:ClearQueue(builder)
        table.insert(builder.buildingQueue, work)

        BuildingHelper:AdvanceQueue(builder)
        -- print("Starting self placement of "..buildingName)

    else
        -- Adjust the model position z
        local model_offset = GetUnitKV(buildingName, "ModelOffset") or 0
        local model_location = Vector(location.x, location.y, location.z + model_offset)

        -- npc_dota_creature doesn't render cosmetics on the particle ghost, use hero names instead
        local overrideGhost = buildingTable:GetVal("OverrideBuildingGhost", "string")
        local unitName = overrideGhost or buildingName
        local entity

        -- VicFrank We don't use override ghost
        -- if overrideGhost then
        --     -- Use a hero dummy to project the queue particles
        --     entity = BuildingHelper:GetOrCreateDummy(unitName)
        -- else
        --     -- Create the building entity that will be used to start construction and project the queue particles
        --     entity = CreateUnitByName(unitName, model_location, false, nil, nil, builder:GetTeam())
        --     entity:SetNeverMoveToClearSpace(true)
        --     function entity:IsUnderConstruction() return true end
        -- end

        -- Create the building entity that will be used to start construction and project the queue particles
        entity = CreateUnitByName(unitName, model_location, false, nil, nil, builder:GetTeam())
        entity:SetNeverMoveToClearSpace(true)
        function entity:IsUnderConstruction() return true end

        entity:AddEffects(EF_NODRAW)
        entity:AddNewModifier(entity, nil, "modifier_out_of_world", {})
        work.entity = entity

        local modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_CUSTOMORIGIN, nil, player)
        ParticleManager:SetParticleControl(modelParticle, 0, model_location)
        ParticleManager:SetParticleControlEnt(modelParticle, 1, entity, 1, "attach_hitloc", entity:GetAbsOrigin(), true) -- Model attach
        ParticleManager:SetParticleControl(modelParticle, 3, Vector(BuildingHelper.Settings["MODEL_ALPHA"],0,0)) -- Alpha
        ParticleManager:SetParticleControl(modelParticle, 4, Vector(fMaxScale,0,0)) -- Scale
        work.particleIndex = modelParticle

        local color = BuildingHelper.Settings["RECOLOR_BUILDING_PLACED"] and Vector(0,255,0) or Vector(255,255,255)
        ParticleManager:SetParticleControl(modelParticle, 2, color) -- Color

        -- Create pedestal for particles
        local pedestal = buildingTable:GetVal("PedestalModel")
        if pedestal then
            local prop = BuildingHelper:GetOrCreateProp(pedestal)
            local scale = buildingTable:GetVal("PedestalModelScale", "float") or entity:GetModelScale()
            local offset = buildingTable:GetVal("PedestalOffset", "float") or 0
            local offset_location = Vector(location.x, location.y, location.z + offset)

            prop:AddEffects(EF_NODRAW)
            prop.pedestalParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_CUSTOMORIGIN, nil, player)
            ParticleManager:SetParticleControl(prop.pedestalParticle, 0, offset_location)
            ParticleManager:SetParticleControlEnt(prop.pedestalParticle, 1, prop, 1, "attach_hitloc", prop:GetAbsOrigin(), true) -- Model attach
            ParticleManager:SetParticleControl(prop.pedestalParticle, 2, color) -- Color
            ParticleManager:SetParticleControl(prop.pedestalParticle, 3, Vector(BuildingHelper.Settings["MODEL_ALPHA"],0,0)) -- Alpha
            ParticleManager:SetParticleControl(prop.pedestalParticle, 4, Vector(scale,0,0)) -- Scale
            work.propParticleIndex = prop.pedestalParticle
        end

        -- Adjust the Model Orientation
        -- [simona] added initial rotation control, based on table, passed from AddBuilding
        -- through playerTable.activeBuildingTable
        local yaw = buildingTable:GetVal("ModelRotation", "float")
        -- new block
        local additionalRotationData = buildingTable:GetVal("AdditionalRotationData")
        if additionalRotationData then
            if additionalRotationData == "FACE_ENEMY_BASE" then
                -- GOODGUYS face enemy base by default
                if player:GetTeam() == DOTA_TEAM_BADGUYS then
                    yaw = yaw + 180
                end
            else
                additionalRotationData = tonumber(additionalRotationData)
                yaw = yaw + (RandomInt(0, MAX_MODEL_ROTATION_RANDOMIZATION_STEPS) * additionalRotationData)
            end
        end
        -- new block ending
        entity:SetAngles(0, -yaw, 0)

        -- If the ability wasn't queued, override the building queue
        if not bQueued then
            BuildingHelper:ClearQueue(builder)
        end

        -- Add this to the builder queue
        table.insert(builder.buildingQueue, work)

        -- If the builder doesn't have a current work, start the queue
        -- Extra check for builder-inside behaviour, those abilities are always queued
        if builder.work == nil and not builder:HasModifier("modifier_builder_hidden") and not (builder.state == "repairing" or builder.state == "moving_to_repair") then
            builder.work = builder.buildingQueue[1]
            -- print("Builder doesn't have work to do, start right away")
            BuildingHelper:AdvanceQueue(builder)
        else
            -- print("Work was queued, builder already has work to do")
            -- printQueue(builder)
        end
    end
end

-- Adds a repair to the builders work queue
-- bQueued will be true if the command was done with shift pressed
-- If bQueued is false, the queue is cleared and this repair is put on top
function BuildingHelper:AddRepairToQueue(builder, building, bQueued)
    -- External pre repair checks
    local bResult = self:OnPreRepair(builder, building)
    if not bResult then return end

    local playerID = builder:_GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    local buildingName = building:GetUnitName()
    local buildingTable = playerTable.activeBuildingTable
    local callbacks = playerTable.activeCallbacks

    -- print("AddRepairToQueue "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> building "..building:GetUnitName())

    -- Make the new work entry
    local work = {["building"] = building, ["name"] = buildingName, ["buildingTable"] = buildingTable, ["callbacks"] = callbacks, isRepair = true}

    -- If the ability wasn't queued, override the building queue
    if not bQueued then
        BuildingHelper:ClearQueue(builder)
    end

    -- Add this to the builder queue
    table.insert(builder.buildingQueue, work)

    -- If the builder doesn't have a current work, start the queue
    -- Extra check for builder-inside behaviour, those abilities are always queued
    if builder.work == nil and not builder:HasModifier("modifier_builder_hidden") and not (builder.state == "repairing" or builder.state == "moving_to_repair") then
        builder.work = builder.buildingQueue[1]
        -- print("Builder doesn't have work to do, start moving to repair right away")
        BuildingHelper:AdvanceQueue(builder)
    else
        -- print("Repair Work was queued, builder already has work to do")
        -- printQueue(builder)
    end
end

-- Processes an item of the builders work queue
function BuildingHelper:AdvanceQueue(builder)
    if (builder.move_to_build_timer) then Timers:RemoveTimer(builder.move_to_build_timer) end

    if builder.buildingQueue and #builder.buildingQueue > 0 then
        -- printQueue(builder)

        local work = builder.buildingQueue[1]
        table.remove(builder.buildingQueue, 1) --Pop

        if work.building then
            -- Repair Queued
            if not IsValidEntity(work.building) or not work.building:IsAlive() then
                -- print("Queued Repair "..work.name.." but it was removed, continue with the queue")
                self:AdvanceQueue(builder)
            else
                local building = work.building
                local callbacks = work.callbacks
                local castRange = builder:GetFollowRange(building)
                if building.repair_distance then castRange = math.max(building.repair_distance, castRange) end
                builder.work = work
                builder.repair_target = building
                builder.state = "moving_to_repair"

                -- print("AdvanceQueue: Repair "..work.name.." "..work.building:GetEntityIndex())

                -- Move towards the building until close range
                ExecuteOrderFromTable({UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, TargetIndex = building:GetEntityIndex(), Queue = false})
                builder.move_to_build_timer = Timers:CreateTimer(function()
                    if not IsValidEntity(builder) or not builder:IsAlive() then return end -- End if killed
                    if not IsValidEntity(building) or not building:IsAlive() then return end -- End if killed

                    local distance = (building:GetAbsOrigin() - builder:GetAbsOrigin()):Length()
                    if distance > castRange then
                        return 0.03
                    else
                        -- print("Reached building, start the Repair process!")
                        --builder:Stop()

                        builder.repairRange = castRange
                        BuildingHelper:StartRepair(builder, building)
                        return
                    end
                end)
            end
        else
            -- Construction Queued
            local buildingTable = work.buildingTable
            local castRange = buildingTable:GetVal("AbilityCastRange", "number")
            local callbacks = work.callbacks
            local location = work.location
            builder.work = work

            -- Move towards the point at cast range
            builder:MoveToPosition(location)
            builder.move_to_build_timer = Timers:CreateTimer(0.03, function()
                builder:MoveToPosition(location)
                if not IsValidEntity(builder) or not builder:IsAlive() then return end
                builder.state = "moving_to_build"

                local distance = (location - builder:GetAbsOrigin()):Length2D()
                if distance > castRange then
                    return 0.03
                else
                    builder:Stop()

                    -- Self placement goes directly to the OnConstructionStarted callback
                    if work.name == builder:GetUnitName() then
                        local callbacks = work.callbacks
                        if callbacks.onConstructionStarted then
                            callbacks.onConstructionStarted(builder)
                        end

                    else
                        BuildingHelper:StartBuilding(builder)
                    end
                    return
                end
            end)
        end
    else
        -- Set the builder work to nil to accept next work directly
        -- print("Builder "..builder:GetUnitName().." "..builder:GetEntityIndex().." finished its building Queue")
        builder.state = "idle"
        builder.repair_target = nil
        builder.work = nil
    end
end

-- Clear the build queue, the player right clicked
function BuildingHelper:ClearQueue(builder)

    local work = builder.work
    builder.work = nil
    builder.state = "idle"

    BuildingHelper:StopGhost(builder)

    -- Clear movement
    if builder.move_to_build_timer then Timers:RemoveTimer(builder.move_to_build_timer) end

    -- Clear repair
    if builder.repair_target then
        local target = builder.repair_target
        local index = getIndexTable(target.units_repairing, builder)
        if index then
            table.remove(target.units_repairing, index)
            -- print("Builder stopped repairing, currently "..getTableCount(target.units_repairing).." left.")
        end
        builder.repair_target = nil
        self:OnRepairCancelled(builder, target)
    end

    local repair_ability = self:GetRepairAbility(builder)
    if repair_ability then
        if repair_ability:GetToggleState() then repair_ability:ToggleAbility() end
        builder:RemoveModifierByName("modifier_builder_repairing")
    end

    -- Skip if there's nothing to clear
    if not builder.buildingQueue or (not work and #builder.buildingQueue == 0) then
        return
    end

--    print("ClearQueue "..builder:GetUnitName().." "..builder:GetEntityIndex())

    -- Main work
    if work then
        BuildingHelper:ClearWorkParticles(work)
        if work.entity then BuildingHelper:RemoveEntity(work.entity.prop) end

        -- Only refund work that hasn't been placed yet
        -- VicFrank: Also classified work types as repair, so it won't refund when
        -- you cancel a repair
        if not work.inProgress and not work.isRepair then
            BuildingHelper:RemoveEntity(work.entity)
            work.refund = true
        end

        if work.name and work.callbacks and work.callbacks.onConstructionCancelled then
            work.callbacks.onConstructionCancelled(work)
        end
    end

    -- Queued work
    while #builder.buildingQueue > 0 do
        work = builder.buildingQueue[1]
        work.refund = true --Refund this
        BuildingHelper:ClearWorkParticles(work)
        if work.entity then
            BuildingHelper:RemoveEntity(work.entity.prop)
            BuildingHelper:RemoveEntity(work.entity)
        end
        table.remove(builder.buildingQueue, 1)

        if work.name and work.callbacks.onConstructionCancelled then
            work.callbacks.onConstructionCancelled(work)
        end
    end
end

-- Remove the entity if it was not marked as a bh dummy
function BuildingHelper:RemoveEntity(ent)
    if ent and not ent.BHDUMMY then
        UTIL_Remove(ent)
    end
end

function BuildingHelper:ClearWorkParticles(work)
    if work.particleIndex then ParticleManager:DestroyParticle(work.particleIndex, true) end
    if work.propParticleIndex then ParticleManager:DestroyParticle(work.propParticleIndex, true) end
end

-- Stop panorama ghost
function BuildingHelper:StopGhost(builder)
    local player = builder:GetPlayerOwner()

    CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_end", {})
end

-- Shows the current queued work for this builder
function printQueue(builder)
    print("Builder Queue of "..builder:GetUnitName().. " "..builder:GetEntityIndex())
    local buildingQueue = builder.buildingQueue
    for k,v in pairs(buildingQueue) do
        if buildingQueue[k]["location"] then
            print(" #"..k..": "..buildingQueue[k]["name"].." at "..VectorString(buildingQueue[k]["location"]))
        elseif buildingQueue[k]["building"] then
            print(" #"..k..": ".." repair "..buildingQueue[k]["name"])
        end
    end
end

-- Toggles fast building/repairing cheat
function BuildingHelper:WarpTen(bEnabled)
    if bEnabled == nil then -- Toggle
        GameRules.WarpTen = not GameRules.WarpTen
    else
        GameRules.WarpTen = bEnabled
    end
end

function BuildingHelper:SnapToGrid(size, location)
    if size % 2 ~= 0 then
        location.x = BuildingHelper:SnapToGrid32(location.x)
        location.y = BuildingHelper:SnapToGrid32(location.y)
    else
        location.x = BuildingHelper:SnapToGrid64(location.x)
        location.y = BuildingHelper:SnapToGrid64(location.y)
    end
end

function BuildingHelper:SnapToGrid64(coord)
    return 64*math.floor(0.5+coord/64)
end

function BuildingHelper:SnapToGrid32(coord)
    return 32+64*math.floor(coord/64)
end

function BuildingHelper:GetPlayerTable(playerID)
    if not BuildingHelper.Players[playerID] then
        BuildingHelper.Players[playerID] = {}
    end

    return BuildingHelper.Players[playerID]
end

-- Creates an out of world dummy at map origin and stores it, reducing load from creating units
function BuildingHelper:GetOrCreateDummy(unitName)
    if BuildingHelper.Dummies[unitName] then
        return BuildingHelper.Dummies[unitName]
    else
        -- print("AddBuilding "..unitName)
        local mgd = CreateUnitByName(unitName, Vector(0,0,0), false, nil, nil, 0)
        mgd:AddEffects(EF_NODRAW)
        mgd:AddNewModifier(mgd, nil, "modifier_out_of_world", {})
        BuildingHelper.Dummies[unitName] = mgd
        mgd.BHDUMMY = true -- Skip removing this entity
        for i=0,16 do
            local ability = mgd:GetAbilityByIndex(i)
            if ability then
                --simona added precachning of aura radius for ghost visualization
                -- precaching must be done before ability:SetLevel(0)
                -- as it resets all special values, retreived trough GetSpecialValueFor, to 0
                if ability:GetAbilityKeyValues()["BuildingHelperPreview"] == "1" then
                    mgd.auraRadius = ability:GetSpecialValueFor("radius")
                end
                ability:SetLevel(0)
            end
        end
        return mgd
    end
end

function BuildingHelper:GetOrCreateProp(propName)
    if BuildingHelper.Dummies[propName] then
        return BuildingHelper.Dummies[propName]
    else
        local prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = propName})
        prop:AddEffects(EF_NODRAW)
        BuildingHelper.Dummies[propName] = prop
        prop.BHDUMMY = true -- Skip removing this entity
        return prop
    end
end

function BuildingHelper:CreatePedestalForBuilding(entity, buildingName, location, pedestalName)
    local offset = GetUnitKV(buildingName, "PedestalOffset") or 0
    local prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = pedestalName})
    local scale = GetUnitKV(buildingName, "PedestalModelScale") or entity:GetModelScale()
    local offset_location = Vector(location.x, location.y, location.z + offset)
    prop:SetModelScale(scale)
    prop:SetAbsOrigin(offset_location)
    entity.prop = prop -- Store the pedestal prop
    return prop
end

function BuildingHelper:AddModifierBuilding(building)
    local magicImmune = BuildingHelper.Settings["MAGIC_IMMUNE_BUILDINGS"]
    local deniable = BuildingHelper.Settings["DENIABLE_BUILDINGS"]
    local disableTurning = GetUnitKV(name, "DisableTurning") == 1 or BuildingHelper.Settings["DISABLE_BUILDING_TURNING"]
    building:AddNewModifier(building, nil, "modifier_building", {disable_turning = disableTurning, magic_immune = magicImmune, deniable = deniable})
end

-- Retrieves the handle of the ability marked as "RepairAbility" on the unit key values
function BuildingHelper:GetRepairAbility(unit)
    local unitName = unit:GetUnitName()
    local abilityName = GetUnitKV(unitName, "RepairAbility")
    if abilityName then
        return unit:FindAbilityByName(abilityName)
    end
end

-- Retrieves a list of all the buildings built by a player
function BuildingHelper:GetBuildings(playerID)
    local playerTable = self:GetPlayerTable(playerID)
    playerTable.BuildingHandles = playerTable.BuildingHandles or {}
    return playerTable.BuildingHandles
end

function BuildingHelper:GetBuildingsUnderConstruction(playerID)
    local playerTable = self:GetPlayerTable(playerID)
    playerTable.BuildingConstructionHandles = playerTable.BuildingConstructionHandles or {}
    return playerTable.BuildingConstructionHandles
end

-- This includes both buildings completed and under construction
function BuildingHelper:GetAllBuildings(playerID)
    local buildings = {}
    local finished = self:GetBuildings(playerID)
    local construction = self:GetBuildingsUnderConstruction(playerID)
    for k,v in pairs(finished) do
        table.insert(buildings, v)
    end
    for k,v in pairs(construction) do
        table.insert(buildings, v)
    end
    return buildings
end

-- Returns number of buildings by name of a player
function BuildingHelper:GetBuildingCount(playerID, buildingName, bIncludeUnderConstruction)
    local playerTable = self:GetPlayerTable(playerID)
    playerTable.BuildingCount = playerTable.BuildingCount or {}
    playerTable.BuildingCount[buildingName] = playerTable.BuildingCount[buildingName] or 0
    local count = playerTable.BuildingCount[buildingName]
    if bIncludeUnderConstruction then
        playerTable.BuildingConstructionCount = playerTable.BuildingConstructionCount or {}
        playerTable.BuildingConstructionCount[buildingName] = playerTable.BuildingConstructionCount[buildingName] or 0
        count = count + playerTable.BuildingConstructionCount[buildingName]
    end
    return count
end

-- Sets the number of buildings by name of a player
function BuildingHelper:SetBuildingCount(playerID, buildingName, number, bUnderConstruction)
    local playerTable = self:GetPlayerTable(playerID)
    if bUnderConstruction then
        playerTable.BuildingConstructionCount = playerTable.BuildingConstructionCount or {}
        playerTable.BuildingConstructionCount[buildingName] = number
    else
        playerTable.BuildingCount = playerTable.BuildingCount or {}
        playerTable.BuildingCount[buildingName] = number
    end
end

-- Store handle and increment count tracking
function BuildingHelper:AddBuildingToPlayerTable(playerID, building, bUnderConstruction)
    local buildingName = building:GetUnitName()
    if bUnderConstruction then
        building.state = "building"
        table.insert(self:GetBuildingsUnderConstruction(playerID), building)
        self:SetBuildingCount(playerID, buildingName, self:GetBuildingCount(playerID, buildingName, true)+1, true)
        function building:IsUnderConstruction() return true end
    else
        -- Remove from construction
        local buildingList = self:GetBuildingsUnderConstruction(playerID)
        local index = getIndexTable(buildingList, building)
        if index then
            table.remove(buildingList, index)
            local constructionCount = self:GetBuildingCount(playerID, buildingName, true)
            self:SetBuildingCount(playerID, buildingName, constructionCount-1, true)
        end

        building.state = "complete"
        table.insert(self:GetBuildings(playerID), building)
        self:SetBuildingCount(playerID, buildingName, self:GetBuildingCount(playerID, buildingName)+1)
        function building:IsUnderConstruction() return false end
    end
end

-- Returns "ConstructionSize" value of a unit handle or unit name
function BuildingHelper:GetConstructionSize(unit)
    local unitTable = (type(unit) == "table") and unit:GetKeyValue() or GetUnitKV(unit)
    return unitTable["ConstructionSize"]
end

-- Returns "BlockPathingSize" kv of a unit handle or unit name
function BuildingHelper:GetBlockPathingSize(unit)
    local unitTable = (type(unit) == "table") and unit:GetKeyValue() or GetUnitKV(unit)
    return unitTable["BlockPathingSize"]
end

function BuildingHelper:HideBuilder(unit, location, building)
    unit:AddNewModifier(unit, nil, "modifier_builder_hidden", {})
    unit.entrance_to_build = unit:GetAbsOrigin()

    local location_builder = Vector(location.x, location.y, location.z - 200)
    building.builder_inside = unit
    unit:AddNoDraw()

    Timers:CreateTimer(function()
        unit:SetAbsOrigin(location_builder)
    end)
end

function BuildingHelper:ShowBuilder(unit)
    unit:RemoveModifierByName("modifier_builder_hidden")
    FindClearSpaceForUnit(unit, unit.entrance_to_build, true)
    unit:RemoveNoDraw()
end

-- Find the closest position of construction_size, within maxDistance
function BuildingHelper:FindClosestEmptyPositionNearby(location, construction_size, maxDistance, avoidUnits)
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)

    local boundX1 = originX + math.floor(maxDistance/64)
    local boundX2 = originX - math.floor(maxDistance/64)
    local boundY1 = originY + math.floor(maxDistance/64)
    local boundY2 = originY - math.floor(maxDistance/64)

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Restrict to the map edges
    lowerBoundX = math.max(lowerBoundX, -BuildingHelper.squareX/2+1)
    upperBoundX = math.min(upperBoundX, BuildingHelper.squareX/2-1)
    lowerBoundY = math.max(lowerBoundY, -BuildingHelper.squareY/2+1)
    upperBoundY = math.min(upperBoundY, BuildingHelper.squareY/2-1)

    -- Adjust even size
    if (construction_size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    local towerPos = nil
    local closestDistance = maxDistance

    for x = lowerBoundX, upperBoundX do
        for y = lowerBoundY, upperBoundY do
            if BuildingHelper:CellHasGridType(x,y,"BUILDABLE") then
                local pos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0), nil)
                BuildingHelper:SnapToGrid(construction_size, pos)
                if BuildingHelper:MeetsHeightCondition(pos) and not BuildingHelper:IsAreaBlocked(construction_size, pos) then
                    local distance = (pos - location):Length2D()
                    if distance < closestDistance then
                        if avoidUnits then
                            local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, pos, nil, 64, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
                            if #units == 0 then
                                towerPos = pos
                                closestDistance = distance
                            end
                        else
                            towerPos = pos
                            closestDistance = distance
                        end
                    end
                end
            end
        end
    end
    if towerPos then
        BuildingHelper:SnapToGrid(construction_size, towerPos)
    end
    return towerPos
end

-- Used to find if a position is insde the trigger entity bounds
function BuildingHelper:IsInsideEntityBounds(entity, location)
    local origin = entity:GetAbsOrigin()
    local bounds = entity:GetBounds()
    local min = bounds.Mins
    local max = bounds.Maxs
    local X = location.x
    local Y = location.y
    local minX = min.x + origin.x
    local minY = min.y + origin.y
    local maxX = max.x + origin.x
    local maxY = max.y + origin.y
    local betweenX = X >= minX and X <= maxX
    local betweenY = Y >= minY and Y <= maxY

    return betweenX and betweenY
end

-- In case a height restriction was defined, checks if the location passes the height test
function BuildingHelper:MeetsHeightCondition(location)
    if BuildingHelper.Settings["HEIGHT_RESTRICTION"] and BuildingHelper.Settings["HEIGHT_RESTRICTION"] ~= "" then
        return location.z >= BuildingHelper.Settings["HEIGHT_RESTRICTION"]
    else
        return true
    end
end

-- A BuildingHelper ability is identified by the "Building" key.
function IsBuildingAbility(ability)
    if not IsValidEntity(ability) then
        return
    end

    local ability_name = ability:GetAbilityName()
    return GetKeyValue(ability_name, "Building")
end

-- Builders are stored in a nettable in addition to the builder label
function IsBuilder(unit)
    local table = CustomNetTables:GetTableValue("builders", tostring(unit:GetEntityIndex()))
    return unit:GetUnitLabel() == "builder" or (table and (table["IsBuilder"] == 1)) or false
end

function CDOTA_BaseNPC:GetFollowRange(target)
    return self:GetHullRadius() + target:GetHullRadius() + 100
end

function IsCustomBuilding(unit)
    return unit:HasModifier("modifier_building")
end

function PrintGridCoords(pos)
    print('('..string.format("%.1f", pos.x)..','..string.format("%.1f", pos.y)..') = ['.. GridNav:WorldToGridPosX(pos.x)..','..GridNav:WorldToGridPosY(pos.y)..']')
end

function VectorString(v)
    return '[' .. math.floor(v.x) .. ', ' .. math.floor(v.y) .. ', ' .. math.floor(v.z) .. ']'
end

function StringStartsWith(fullstring, substring)
    local strlen = string.len(substring)
    local first_characters = string.sub(fullstring, 1 , strlen)
    return (first_characters == substring)
end

function tobool(s)
    return s==true or s=="true" or s=="1" or s==1
end

function split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function getTableCount(t)
    local n = 0
    for _ in pairs( t ) do
        n = n + 1
    end
    return n
end

function getIndexTable(list, element)
    if list == nil then return false end
    for k,v in pairs(list) do if v == element then return k end end
end

function DrawGridSquare(x, y, color, duration)
    local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
    duration = duration or 10
    BuildingHelper:SnapToGrid(1, pos)
    pos = GetGroundPosition(pos, nil)

    local particle = ParticleManager:CreateParticle("particles/buildinghelper/square_overlay.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, pos)
    ParticleManager:SetParticleControl(particle, 1, Vector(32,0,0))
    ParticleManager:SetParticleControl(particle, 2, color)
    ParticleManager:SetParticleControl(particle, 3, Vector(90,0,0))

    Timers:CreateTimer(duration, function()
        ParticleManager:DestroyParticle(particle, true)
    end)
end

if not BuildingHelper.Players then BuildingHelper:Init() else BuildingHelper:OnScriptReload() end