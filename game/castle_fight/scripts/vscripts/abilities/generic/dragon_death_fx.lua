LinkLuaModifier("dragon_death_fx", "abilities/generic/dragon_death_fx.lua", LUA_MODIFIER_MOTION_NONE)

dragon_death_fx = class({})

function dragon_death_fx:GetIntrinsicModifierName() return "dragon_death_fx" end

function dragon_death_fx:OnCreated(table)
end

function dragon_death_fx:DeclareFunctions()
    local funcs = {
      MODIFIER_EVENT_ON_DEATH,
    }
    return funcs
end

function dragon_death_fx:IsPurgable()
    return false
end

function dragon_death_fx:IsHidden()
    return true
end

function dragon_death_fx:OnDeath(params)
    if not IsServer() then return end

    local dragon = self:GetParent()

    if params.unit ~= dragon then return end

    -- Initial model size depends on unit properties and various modifiers
    -- And can change upon death when modifiers expire
    -- Those changes are usually a reset to normal size
    -- They take time anyway, and we can't controll them
    -- Thus, we don't try to create some smooth animation
    -- Just collapse with given frequency and speed

    local tickInterval = 0.1
    local deltaScale = 0.1

    print("Dragon died")
    -- print("Dragon died, death animation will take " .. numUpdates .. " ticks per " .. collapseTime .. " seconds")

    -- local particleName = "particles/econ/items/nyx_assassin/nyx_ti9_immortal/nyx_ti9_carapace_hit_blood.vpcf"
    local particleName = "particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance_explosion.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, dragon)
    ParticleManager:SetParticleControl(particle, 0, dragon:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    Timers:CreateTimer(function()
        local newScale = dragon:GetModelScale() - deltaScale
        print("Setting dragon scale to " .. newScale)
        if newScale <=0 then
            -- Adjust
            dragon:SetModelScale(0)
            print("Dragon death animation ended, timer is destoyed now")
        else
            dragon:SetModelScale(newScale)
            return tickInterval
        end
    end)
end