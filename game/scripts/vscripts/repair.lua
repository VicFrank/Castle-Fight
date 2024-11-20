--------------------------------
--       Repair Scripts       --
--------------------------------

function Repair(event)
    local caster = event.caster
    local target = event.target

    BuildingHelper:AddRepairToQueue(caster, target, false)
end

-- Right before starting to move towards the target
function BuildingHelper:OnPreRepair(builder, target)
    -- Custom repair target rules
    local bValidRepair = target:GetClassname() == "npc_dota_creature" and (IsCustomBuilding(target) or target:IsMechanical()) and target:GetHealthPercent() < 100

    -- Return false to stop the repair process
    return bValidRepair
end

-- As soon as the builder reaches the building
function BuildingHelper:OnRepairStarted(builder, building)
    -- print("OnRepairStarted "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    local repair_ability = self:GetRepairAbility(builder)
    if repair_ability and repair_ability:GetToggleState() == false then
        repair_ability:ToggleAbility() -- Fake toggle the ability
    end

    -- Wisp Particle
    -- if not builder.gathering_particle then
    --     builder.gathering_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_overcharge.vpcf", PATTACH_ABSORIGIN_FOLLOW, builder)
    --     ParticleManager:SetParticleControlEnt(builder.gathering_particle, 0, builder, PATTACH_POINT_FOLLOW, "attach_hitloc", builder:GetAbsOrigin(), true)
    -- end

    if not building.construction_particle then
        building.construction_particle = ParticleManager:CreateParticle("particles/custom/construction_dust.vpcf", PATTACH_ABSORIGIN_FOLLOW, building)
    end

    builder:StartGesture(ACT_DOTA_ATTACK)
    builder.repair_animation_timer = Timers:CreateTimer(function()
        if builder.state == "repairing" then
            builder:StartGesture(ACT_DOTA_ATTACK)
        end
        return 1
    end)
end

function BuildingHelper:OnRepairTick(building, hpGain, costFactor)
    local playerID = building:GetPlayerOwnerID()
    local goldCost = building:GetKeyValue("GoldCost")
    local buildTime = building:GetKeyValue("BuildTime")
    building.GoldAdjustment = building.GoldAdjustment or 0
    building.gold_used = 0

    -- Keep adding the floating point values every tick
    local pct_healed = hpGain / building:GetMaxHealth()
    local gold_tick = pct_healed * goldCost * costFactor
    local gold_float = gold_tick - math.floor(gold_tick)
    gold_tick = math.floor(gold_tick)

    if PlayerResource:GetGold(playerID) >= gold_tick then
        building.GoldAdjustment = building.GoldAdjustment + gold_float
        if building.GoldAdjustment > 1 then
            PlayerResource:ModifyGold(playerID, -gold_tick, false, 0)
            building.GoldAdjustment = building.GoldAdjustment - 1
            building.gold_used = building.gold_used + gold_tick + 1
        else
            PlayerResource:ModifyGold(playerID, -gold_tick, false, 0)
            building.gold_used = building.gold_used + gold_tick
        end
    else
        building.gold_used = nil
        return false -- cancels the repair on all builders
    end
end

-- After an ongoing move-to-building or repair process is cancelled
function BuildingHelper:OnRepairCancelled(builder, building)
    -- print("OnRepairCancelled "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    builder:RemoveModifierByName("modifier_builder_repairing")

    if builder.repair_animation_timer then
        builder:RemoveGesture(ACT_DOTA_ATTACK)
        Timers:RemoveTimer(builder.repair_animation_timer)
    end

    if builder.gathering_particle then
        ParticleManager:DestroyParticle(builder.gathering_particle, false)
        builder.gathering_particle = nil
    end

     if building.construction_particle and BuildingHelper:GetNumBuildersRepairing(building) == 0 then 
        ParticleManager:DestroyParticle(building.construction_particle, false)
        building.construction_particle = nil
    end
end

-- After a building is fully constructed via repair ("RequiresRepair" buildings), or is fully repaired
function BuildingHelper:OnRepairFinished(builder, building)
    -- print("OnRepairFinished "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    if builder.repair_animation_timer then 
        builder:RemoveGesture(ACT_DOTA_ATTACK)
        Timers:RemoveTimer(builder.repair_animation_timer)
    end

    if builder.gathering_particle then
        ParticleManager:DestroyParticle(builder.gathering_particle, false)
        builder.gathering_particle = nil
    end

    if building.construction_particle and BuildingHelper:GetNumBuildersRepairing(building) == 0 then 
        ParticleManager:DestroyParticle(building.construction_particle, false)
        building.construction_particle = nil
    end
end