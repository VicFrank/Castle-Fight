-- A build ability is used (not yet confirmed)
function Build( event )
    local caster = event.caster
    local ability = event.ability
    local ability_name = ability:GetAbilityName()
    local building_name = ability:GetAbilityKeyValues()['UnitName']
    local gold_cost = ability:GetGoldCost(1) 
    local lumber_cost = tonumber(ability:GetAbilityKeyValues()['LumberCost']) or 0
    local cheese_cost = tonumber(ability:GetAbilityKeyValues()['IsLegendary']) or 0
    local hero = caster:IsRealHero() and caster or caster:GetOwner()
    local playerID = hero:GetPlayerID()

    -- If the ability has an AbilityGoldCost, it's impossible to not have enough gold the first time it's cast
    -- Always refund the gold here, as the building hasn't been placed yet

    hero:ModifyGold(gold_cost, false, 0)

    -- Makes a building dummy and starts panorama ghosting
    BuildingHelper:AddBuilding(event)

    -- Additional checks to confirm a valid building position can be performed here
    event:OnPreConstruction(function(vPos)
        -- Check for minimum height if defined
        if not BuildingHelper:MeetsHeightCondition(vPos) then
            print("Failed placement of " .. building_name .." - Placement is below the min height required")
            SendErrorMessage(playerID, "#error_invalid_build_position")
            return false
        end

        -- If not enough resources to queue, stop
        if PlayerResource:GetGold(playerID) < gold_cost then
            print("Failed placement of " .. building_name .." - Not enough gold!")
            SendErrorMessage(playerID, "#error_not_enough_gold")
            return false
        end

        -- If not enough resources to queue, stop
        if hero:GetLumber() < lumber_cost then
            print("Failed placement of " .. building_name .." - Not enough lumber!")
            SendErrorMessage(playerID, "#error_not_enough_lumber")
            return false
        end

        -- If not enough resources to queue, stop
        if hero:GetCheese() < cheese_cost then
            print("Failed placement of " .. building_name .." - Not enough cheese!")
            SendErrorMessage(playerID, "#error_not_enough_cheese")
            return false
        end

        return true
    end)

    -- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos)
        -- Spend resources
        hero:ModifyGold(-gold_cost, false, 0)
        hero:ModifyLumber(-lumber_cost)
        hero:ModifyCheese(-cheese_cost)

        -- Play a sound
        EmitSoundOnClient("DOTA_Item.ObserverWard.Activate", PlayerResource:GetPlayer(playerID))
    end)

    -- The construction failed and was never confirmed due to the gridnav being blocked in the attempted area
    event:OnConstructionFailed(function()
        local playerTable = BuildingHelper:GetPlayerTable(playerID)
        local building_name = playerTable.activeBuilding

        print("Failed placement of " .. building_name)
    end)

    -- Cancelled due to ClearQueue
    event:OnConstructionCancelled(function(work)
        local building_name = work.name
        print("Cancelled construction of " .. building_name)

        -- work.building is not nil if this was a repair action
        if work.building then
            return
        end

        -- Refund resources for this cancelled work
        if work.refund then
            hero:ModifyGold(gold_cost, false, 0)
            hero:ModifyLumber(lumber_cost)
            hero:ModifyCheese(cheese_cost)
        end
    end)

    -- A building unit was created
    event:OnConstructionStarted(function(unit)
        print("Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        -- Play construction sound

        -- If it's an item-ability and has charges, remove a charge or remove the item if no charges left
        if ability.GetCurrentCharges and not ability:IsPermanent() then
            local charges = ability:GetCurrentCharges()
            charges = charges-1
            if charges == 0 then
                ability:RemoveSelf()
            else
                ability:SetCurrentCharges(charges)
            end
        end

        -- Units can't attack while building
        unit.original_attack = unit:GetAttackCapability()
        unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

        -- Give item to cancel
        unit.item_building_cancel = CreateItem("item_building_cancel", hero, hero)
        if unit.item_building_cancel then 
            unit:AddItem(unit.item_building_cancel)
            unit.gold_cost = gold_cost
            unit.lumber_cost = lumber_cost
            unit.cheese_cost = cheese_cost
        end

        -- Add the dust construction particle
        if not unit.construction_particle then
            unit.construction_particle = ParticleManager:CreateParticle("particles/custom/construction_dust.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
        end

        -- FindClearSpace for the builder
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
        caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})

        -- Silence the building while it is being constructed
        unit:AddNewModifier(caster, nil, "modifier_under_construction", {duration=-1})

        -- Mark the building as legendary if it is
        if cheese_cost == 1 then
            unit.isLegendary = true
        end

        -- Remove invulnerability on npc_dota_building baseclass
        unit:RemoveModifierByName("modifier_invulnerable")
    end)

    -- A building finished construction
    event:OnConstructionCompleted(function(unit)
        print("Completed construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        
        -- Play construction complete sound
        
        -- Remove the item
        if unit.item_building_cancel then
            UTIL_Remove(unit.item_building_cancel)
        end

        -- Remove the dust construction particle
        if unit.construction_particle and BuildingHelper:GetNumBuildersRepairing(unit) == 0 then 
            ParticleManager:DestroyParticle(unit.construction_particle, false)
            unit.construction_particle = nil
        end

        -- Give the unit their original attack capability
        unit:SetAttackCapability(unit.original_attack)

        -- Unsilence the unit
        unit:RemoveModifierByName("modifier_under_construction")

        GameMode:OnConstructionCompleted(unit, ability)
    end)

    -- These callbacks will only fire when the state between below half health/above half health changes.
    -- i.e. it won't fire multiple times unnecessarily.
    event:OnBelowHalfHealth(function(unit)
        print(unit:GetUnitName() .. " is below half health.")
        ApplyModifier(unit, "modifier_onfire")
    end)

    event:OnAboveHalfHealth(function(unit)
        print(unit:GetUnitName().. " is above half health.")   
        unit:RemoveModifierByName("modifier_onfire")
    end)
end

-- Called when the Cancel ability-item is used
function CancelBuilding( keys )
    local building = keys.unit
    local hero = building:GetOwner()
    local playerID = building:GetPlayerOwnerID()

    print("CancelBuilding "..building:GetUnitName().." "..building:GetEntityIndex())

    -- Discount the refund based on how much damage the tower took when cancelled
    local refundPercent = (building:GetHealth() - building.initialHealth) / building.addedHealth
    refundPercent = math.min(1, refundPercent)

    -- Refund here
    if building.gold_cost then
        hero:ModifyGold(building.gold_cost * refundPercent, false, 0)
        hero:ModifyLumber(building.lumber_cost * refundPercent)
        hero:ModifyCheese(building.cheese_cost)
    end

    -- Eject builder
    local builder = building.builder_inside
    if builder then
        BuildingHelper:ShowBuilder(builder)
    end

    building:ForceKill(true) --This will call RemoveBuilding
end

-- Requires notifications library from bmddota/barebones
function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end
