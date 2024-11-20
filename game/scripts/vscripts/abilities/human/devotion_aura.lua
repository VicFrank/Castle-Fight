crusader_armor_aura = class({})

LinkLuaModifier("modifier_devotion_aura", "abilities/human/devotion_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_devotion_aura_buff", "abilities/human/devotion_aura", LUA_MODIFIER_MOTION_NONE)

function crusader_armor_aura:GetIntrinsicModifierName()
    return "modifier_devotion_aura"
end

--------------------------------------------------------------------------------

modifier_devotion_aura = class({})

function modifier_devotion_aura:IsAura()
    return true
end

function modifier_devotion_aura:IsHidden()
    return true
end

function modifier_devotion_aura:IsPurgable()
    return false
end

function modifier_devotion_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_devotion_aura:GetModifierAura()
    return "modifier_devotion_aura_buff"
end

function modifier_devotion_aura:GetEffectName()
    return "particles/custom/aura_devotion.vpcf"
end

function modifier_devotion_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_devotion_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_devotion_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target)
end

function modifier_devotion_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_devotion_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_devotion_aura_buff = class({})

function modifier_devotion_aura_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_devotion_aura_buff:GetModifierPhysicalArmorBonus()
    if self:GetAbility() then
        return self:GetAbility():GetSpecialValueFor("armor_bonus")
    end
end

function modifier_devotion_aura_buff:IsPurgable()
    return false
end

function modifier_devotion_aura_buff:GetTexture()
    return "sven_warcry"
end