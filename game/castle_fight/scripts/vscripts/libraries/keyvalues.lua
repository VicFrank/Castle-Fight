NPC_UNITS_CUSTOM = LoadKeyValues("scripts/npc/npc_units_custom.txt")
NPC_ABILITIES_CUSTOM = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
NPC_ITEMS_CUSTOM = LoadKeyValues("scripts/npc/npc_items_custom.txt")
NPC_HEROES_CUSTOM = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
ADDON_ENGLISH = LoadKeyValues("resource/addon_english.txt")

KEYVALUES_VERSION = "1.00"

 -- Change to false to skip loading the base files
LOAD_BASE_FILES = false

if not KeyValues then
    KeyValues = {}
end

local split = function(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

-- Load all the necessary key value files
function LoadGameKeyValues()
    local scriptPath ="scripts/npc/"
    local override = LoadKeyValues(scriptPath.."npc_abilities_override.txt")
    local files = { AbilityKV = {base="npc_abilities",custom="npc_abilities_custom"},
                    ItemKV = {base="items",custom="npc_items_custom"},
                    UnitKV = {base="npc_units",custom="npc_units_custom"},
                    HeroKV = {base="npc_heroes",custom="npc_heroes_custom"}
                  }

    -- Load and validate the files
    for k,v in pairs(files) do
        local file = {}
        if LOAD_BASE_FILES then
            file = LoadKeyValues(scriptPath..v.base..".txt")
        end

        -- Replace main game keys by any match on the override file
        for k,v in pairs(override) do
            if file[k] then
                file[k] = v
            end
        end

        local custom_file = LoadKeyValues(scriptPath..v.custom..".txt")
        if custom_file then
            for k,v in pairs(custom_file) do
                file[k] = v
            end
        else
            print("[KeyValues] Critical Error on "..v.custom..".txt")
            return
        end
        
        GameRules[k] = file --backwards compatibility
        KeyValues[k] = file
    end   

    -- Merge All KVs
    KeyValues.All = {}
    for name,path in pairs(files) do
        for key,value in pairs(KeyValues[name]) do
            if not KeyValues.All[key] then
                KeyValues.All[key] = value
            end
        end
    end

    -- Merge units and heroes (due to them sharing the same class CDOTA_BaseNPC)
    for key,value in pairs(KeyValues.HeroKV) do
        if not KeyValues.UnitKV[key] then
            KeyValues.UnitKV[key] = value
        else
            if type(KeyValues.All[key]) == "table" then
                print("[KeyValues] Warning: Duplicated unit/hero entry for "..key)
            end
        end
    end
end

-- Works for heroes and units on the same table due to merging both tables on game init
function CDOTA_BaseNPC:GetKeyValue(key, level)
    if level then return GetUnitKV(self:GetUnitName(), key, level)
    else return GetUnitKV(self:GetUnitName(), key) end
end

-- Dynamic version of CDOTABaseAbility:GetAbilityKeyValues()
function CDOTABaseAbility:GetKeyValue(key, level)
    if level then return GetAbilityKV(self:GetAbilityName(), key, level)
    else return GetAbilityKV(self:GetAbilityName(), key) end
end

-- Item version
function CDOTA_Item:GetKeyValue(key, level)
    if level then return GetItemKV(self:GetAbilityName(), key, level)
    else return GetItemKV(self:GetAbilityName(), key) end
end

function CDOTABaseAbility:GetAbilitySpecial(key)
    return GetAbilitySpecial(self:GetAbilityName(), key, self:GetLevel())
end

-- Global functions
-- Key is optional, returns the whole table by omission
-- Level is optional, returns the whole value by omission
function GetKeyValue(name, key, level, tbl)
    local t = tbl or KeyValues.All[name]
    if key and t then
        if t[key] and level then
            local s = split(t[key])
            if s[level] then return tonumber(s[level]) or s[level] -- Try to cast to number
            else return tonumber(s[#s]) or s[#s] end
        else return t[key] end
    else return t end
end

function GetUnitKV(unitName, key, level)
    return GetKeyValue(unitName, key, level, KeyValues.UnitKV[unitName])
end

function GetAbilityKV(abilityName, key, level)
    return GetKeyValue(abilityName, key, level, KeyValues.AbilityKV[abilityName])
end

function GetItemKV(itemName, key, level)
    return GetKeyValue(itemName, key, level, KeyValues.ItemKV[itemName])
end

function GetAbilitySpecial(name, key, level)
    local t = KeyValues.All[name]
    if key and t then
        local tspecial = t["AbilitySpecial"]
        if tspecial then
            -- Find the key we are looking for
            for _,values in pairs(tspecial) do
                if values[key] then
                    if not level then return values[key]
                    else
                        local s = split(values[key])
                        if s[level] then return tonumber(s[level]) -- If we match the level, return that one
                        else return tonumber(s[#s]) end -- Otherwise, return the max
                    end
                    break
                end
            end
        end
    else return t end
end

function GetUnitKeyValue(unitName, key)
    if NPC_UNITS_CUSTOM[unitName] then
        if not NPC_UNITS_CUSTOM[unitName][key] then
            --Log:warn("Key " .. key .. " does not exist for " .. unitName)
        end
        return NPC_UNITS_CUSTOM[unitName][key]
    else
        --Log:warn("Unknown unit type: " .. tostring(unitName) .. " [Key: " .. key .. "]")
        return nil
    end
end

if not KeyValues.All then LoadGameKeyValues() end