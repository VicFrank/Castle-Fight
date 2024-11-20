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

function dragon_death_fx:IsDebuff()
    return false
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
    local deltaScale = 0.05

    local particleName = "particles/econ/items/nyx_assassin/nyx_ti9_immortal/nyx_ti9_carapace_hit_blood.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, dragon)
    ParticleManager:SetParticleControlEnt(particle, 1, dragon, PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)


    Timers:CreateTimer(function()
        local newScale = dragon:GetModelScale() - deltaScale
        if newScale <=0 then
            -- Adjust and prevent further flapping sound
            dragon:SetModelScale(0)
            dragon:StopAnimation()
        else
            dragon:SetModelScale(newScale)
            return tickInterval
        end
    end)
end