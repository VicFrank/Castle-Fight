-- From Dota Imba
--     yahnich, 09.06.2017
--     naowin, 28.05.2018

mountain_giant_grab_tree = mountain_giant_grab_tree or class({})
LinkLuaModifier("imba_tiny_tree_modifier", "abilities/nature/grab_tree", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("imba_tiny_tree_building_modifier", "abilities/nature/grab_tree", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("imba_tiny_tree_animation_modifier", "abilities/nature/grab_tree", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("imba_tiny_tree_damage_modifier", "abilities/nature/grab_tree", LUA_MODIFIER_MOTION_NONE)

function mountain_giant_grab_tree:OnSpellStart()
  if IsServer() then 
    local caster = self:GetCaster()

    local damage_modifier = caster:AddNewModifier(caster, self, "imba_tiny_tree_damage_modifier", {})
    damage_modifier:SetStackCount(self:GetSpecialValueFor("bonus_damage"))
    local tree_modifier = caster:AddNewModifier(caster, self, "imba_tiny_tree_modifier", {})
    tree_modifier:SetStackCount(self:GetSpecialValueFor("num_attacks"))

    -- Change damage type to siege
    caster:RemoveModifierByName("modifier_attack_normal")
    ApplyModifier(caster, "modifier_attack_siege")

    -- Can hit flying
    caster.aiState.canHitFlying = true
    
    -- Add tree model + animation
    caster:AddNewModifier(caster, self, "imba_tiny_tree_animation_modifier", {})
  end
end

----------------------------------------------
--     Tree Model and Animation modifier  --
----------------------------------------------
imba_tiny_tree_animation_modifier = class({})
function imba_tiny_tree_animation_modifier:IsHidden() return true end
function imba_tiny_tree_animation_modifier:IsPurgable() return false end
function imba_tiny_tree_animation_modifier:OnCreated()
  if IsServer() then
    local caster = self:GetCaster()
    local grow_lvl = 3

    -- If we already have a tree... destroy it and create new. 
    if caster.tree ~= nil then
      caster.tree:AddEffects(EF_NODRAW)
      UTIL_Remove(caster.tree)
      caster.tree = nil
    end
    
    -- Create the tree model
    self.tree = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_01/tiny_01_tree.vmdl"})
    -- Bind it to caster bone 
    self.tree:FollowEntity(self:GetCaster(), true)
    -- Find the Coordinates for model position on left hand
    local origin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack2"))
    -- Forward Vector!
    local fv = caster:GetForwardVector()
    
    -- Apply diffrent positions of the tree depending on growth model...
    if grow_lvl == 3 then
      --Adjust poition to match grow lvl 3
      local pos = origin + (fv * 50)
      self.tree:SetAbsOrigin(Vector(pos.x + 10, pos.y, (origin.z + 25)))    
    elseif grow_lvl == 2 then
      -- Adjust poition to match grow lvl 2
      local pos = origin + (fv * 35)
      self.tree:SetAbsOrigin(Vector(pos.x, pos.y, (origin.z + 25)))

    elseif grow_lvl == 1 then
      -- Adjust poition to match grow lvl 1
      local pos = origin + (fv * 35) 
      self.tree:SetAbsOrigin(Vector(pos.x, pos.y + 20, (origin.z + 25)))

    elseif grow_lvl == 0 then
      -- Adjust poition to match original no grow model
      local pos = origin - (fv * 25) 
      self.tree:SetAbsOrigin(Vector(pos.x - 20, pos.y - 30 , origin.z))
      self.tree:SetAngles(60, 60, -60)
    end

    -- Save model to caster
    caster.tree = self.tree

    -- Change animation now that we have a huge ass tree in our hand.
    StartAnimation(caster, { duration = -1, activity = ACT_DOTA_ATTACK_EVENT , rate = 2, translate = "tree" })
  end
end

function imba_tiny_tree_animation_modifier:OnRemoved()
  if IsServer() then
    local caster = self:GetCaster()
    -- stop tree animation
    EndAnimation(caster)
    caster.tree:AddEffects(EF_NODRAW)
  end
end

---------------------------------------
--        Tree Grabb modifier        --
---------------------------------------
imba_tiny_tree_modifier = imba_tiny_tree_modifier or class({})
function imba_tiny_tree_modifier:IsHidden() return false end
function imba_tiny_tree_modifier:IsBuff() return true end
function imba_tiny_tree_modifier:IsPurgable() return false end
function imba_tiny_tree_modifier:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, 
  }
  return funcs
end

function imba_tiny_tree_modifier:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK,
  }
  return funcs
end

function imba_tiny_tree_modifier:GetModifierAttackRangeBonus()
  return self.attack_range
end

function imba_tiny_tree_modifier:OnCreated()
  local caster = self:GetCaster()
  if caster ~= nil then 
    local attack_range = self:GetAbility():GetSpecialValueFor("attack_range");
    local caster_range = caster:Script_GetAttackRange()
    -- Override cast_range. it should be fixed when holding a tree
    if caster_range > attack_range then
      self.attack_range = (caster_range - attack_range)
    else
      self.attack_range = (attack_range - caster_range)
    end   
  end
end

function imba_tiny_tree_modifier:OnAttackLanded(keys)
  if not IsServer() then return end

  local attacker = keys.attacker
  local target = keys.target

  if attacker == self.caster and IsCustomBuilding(target) then
    local damage = keys.damage
    damage = damage * 0.25

    ApplyDamage({
      victim = target,
      damage = damage,
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
      attacker = self.caster,
      ability = self.ability
    })
  end
end


function imba_tiny_tree_modifier:OnAttack(keys)
  local caster = self:GetCaster()
  if IsServer() then 
    if caster == keys.attacker then
      if caster:HasModifier("imba_tiny_tree_building_modifier") then
        caster:RemoveModifierByName("imba_tiny_tree_building_modifier")
      end
      -- Check if we ran out of stacks...
      if caster:HasModifier("imba_tiny_tree_modifier") then
        local modifier = caster:FindModifierByName("imba_tiny_tree_modifier")
        local stacks = modifier:GetStackCount() -1 
        if stacks > 0 then
          modifier:SetStackCount(stacks)
        else
          caster:RemoveModifierByName("imba_tiny_tree_modifier")
        end
      end
    end
  end
end

function imba_tiny_tree_modifier:OnRemoved()
  if IsServer() then
    local caster = self:GetCaster()

    if self:GetAbility().tree ~= nil then
      self:GetAbility().tree:Destroy()
    end

    if caster:HasModifier("imba_tiny_tree_damage_modifier") then
      caster:RemoveModifierByName("imba_tiny_tree_damage_modifier")
    end

    caster:RemoveModifierByName("imba_tiny_tree_animation_modifier")

    caster:RemoveModifierByName("modifier_attack_siege")
    ApplyModifier(caster, "modifier_attack_normal")

    caster.aiState.canHitFlying = false
  end
end

---------------------------------------
--       Tree Damage modifier        --
---------------------------------------
imba_tiny_tree_damage_modifier = imba_tiny_tree_damage_modifier or class({})
function imba_tiny_tree_damage_modifier:IsHidden() return true end
function imba_tiny_tree_damage_modifier:IsBuff() return true end
function imba_tiny_tree_damage_modifier:IsPurgable() return false end
function imba_tiny_tree_damage_modifier:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
  return funcs
end

function imba_tiny_tree_damage_modifier:GetModifierPreAttack_BonusDamage()
  return self:GetStackCount()
end