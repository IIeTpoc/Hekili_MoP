-- PaladinRetribution.lua
-- Updated July 15, 2025 - Modern Structure
-- Mists of Pandaria module for Paladin: Retribution spec

-- MoP: Use UnitClass instead of UnitClassBase
local _, playerClass = UnitClass('player')
if playerClass ~= 'PALADIN' then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local spec = Hekili:NewSpecialization( 70 )

local function getReferences()
    -- Legacy function for compatibility
    return class, state
end

local strformat = string.format
local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
local function UA_GetPlayerAuraBySpellID(spellID)
    for i = 1, 40 do
        local name, _, count, _, duration, expires, caster, _, _, id = UnitBuff("player", i)
        if not name then break end
        if id == spellID then return name, _, count, _, duration, expires, caster end
    end
    for i = 1, 40 do
        local name, _, count, _, duration, expires, caster, _, _, id = UnitDebuff("player", i)
        if not name then break end
        if id == spellID then return name, _, count, _, duration, expires, caster end
    end
    return nil
end

-- Combat Log Event Frame for advanced tracking
local retri_combat_log_frame = CreateFrame("Frame")
retri_combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
retri_combat_log_frame:SetScript("OnEvent", function(self, event, ...)
    local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    if sourceGUID ~= UnitGUID("player") then return end
    
    -- Divine Purpose proc tracking
    if eventType == "SPELL_CAST_SUCCESS" then
        local spellID = select(12, CombatLogGetCurrentEventInfo())
        -- Track Holy Power spending abilities for Divine Purpose proc potential
        if spellID == 85256 or spellID == 53385 or spellID == 114165 then -- Templar's Verdict, Divine Storm, Holy Wrath
            -- Store last Holy Power ability for Divine Purpose checks
            ns.last_holy_power_ability = GetTime()
        end
    end
    
    -- Art of War proc tracking
    if eventType == "SPELL_CAST_SUCCESS" or eventType == "SPELL_DAMAGE" then
        local spellID = select(12, CombatLogGetCurrentEventInfo())
        -- Track auto attacks and certain abilities that can proc Art of War
        if spellID == 6603 or spellID == 35395 then -- Auto Attack, Crusader Strike
            -- Check for Art of War proc (instant Exorcism)
            if UA_GetPlayerAuraBySpellID(59578) then
                ns.art_of_war_proc_time = GetTime()
            end
        end
    end
    
    -- Zealotry stack tracking for Enhanced Crusader Strike
    if eventType == "SPELL_CAST_SUCCESS" then
        local spellID = select(12, CombatLogGetCurrentEventInfo())
        if spellID == 35395 then -- Crusader Strike
            ns.crusader_strike_stacks = (ns.crusader_strike_stacks or 0) + 1
            if ns.crusader_strike_stacks > 3 then
                ns.crusader_strike_stacks = 3
            end
        end
    end
end)

-- Enhanced resource systems
spec:RegisterResource( 0, { -- Mana = 0 in MoP
    -- divine_plea = {
    --     last = function ()
    --         return state.buff.divine_plea.applied
    --     end,

    --     interval = 3.0,
        
    --     stop = function ()
    --         return state.buff.divine_plea.down
    --     end,

    --     value = function ()
    --         return 0.12 * state.mana.max -- 12% mana per tick
    --     end,
    -- },
    
    -- guarded_by_the_light = {
    --     last = function ()
    --         return state.combat
    --     end,

    --     interval = 2.0,
        
    --     stop = function ()
    --         return false
    --     end,

    --     value = function ()
    --         local regen = 0.02 * state.mana.max -- 2% base
    --         -- Enhanced by Word of Glory usage
    --         if state.buff.guarded_by_the_light.up then
    --             regen = regen * 2
    --         end
    --         return regen
    --     end,
    -- },

    seal_of_insight = {
        last = function ()
            return state.swing.last_taken
        end,

        interval = function ()
            return state.swing.swing_time
        end,
        
        stop = function ()
            return state.buff.seal_of_insight.down or state.swing.last_taken == 0
        end,

        value = function ()
            return 0.04 * state.mana.max -- 4% mana on melee hit
        end,
    },
} )

spec:RegisterResource( 9, { -- HolyPower = 9 in MoP
    crusader_strike = {
        last = function ()
            return state.abilities.crusader_strike.lastCast
        end,

        interval = function ()
            return state.abilities.crusader_strike.cooldown
        end,
        
        stop = function ()
            return state.abilities.crusader_strike.lastCast == 0
        end,

        value = 1,
    },
    
    hammer_of_wrath = {
        last = function ()
            return state.abilities.hammer_of_wrath.lastCast
        end,

        interval = function ()
            return state.abilities.hammer_of_wrath.cooldown  
        end,
        
        stop = function ()
            return state.abilities.hammer_of_wrath.lastCast == 0 or state.target.health_pct > 20
        end,

        value = 1,
    },
    
    divine_purpose = {
        last = function ()
            return ns.last_holy_power_ability or 0
        end,

        interval = 1.0,
        
        stop = function ()
            return not state.talent.divine_purpose.enabled or not state.buff.divine_purpose.up
        end,

        value = function ()
            return state.talent.divine_purpose.enabled and state.buff.divine_purpose.up and 3 or 0
        end,
    },
} )

-- Comprehensive Tier sets with MoP gear progression
spec:RegisterGear( "tier14", 85349, 85350, 85351, 85352, 85353 ) -- T14 Yaungol Slayer Battlegear
spec:RegisterGear( "tier14_lfr", 89084, 89083, 89082, 89081, 89080 ) -- LFR versions
spec:RegisterGear( "tier14_heroic", 90459, 90458, 90457, 90456, 90455 ) -- Heroic versions

spec:RegisterGear( "tier15", 95280, 95282, 95278, 95281, 95279 ) -- T15 Battleplate of Radiant Glory  
spec:RegisterGear( "tier15_lfr", 96677, 96678, 96679, 96680, 96681 ) -- LFR versions
spec:RegisterGear( "tier15_heroic", 97298, 97299, 97300, 97301, 97302 ) -- Heroic versions

spec:RegisterGear( "tier16", 99054, 99055, 99056, 99057, 99058 ) -- T16 Chrono-Lord Epochryion Regalia
spec:RegisterGear( "tier16_lfr", 100871, 100872, 100873, 100874, 100875 ) -- LFR versions  
spec:RegisterGear( "tier16_heroic", 101594, 101595, 101596, 101597, 101598 ) -- Heroic versions

-- Notable MoP Paladin items and legendary
spec:RegisterGear( "legendary_cloak", 102249 ) -- Qian-Ying, Fortitude of Niuzao
spec:RegisterGear( "kor_kron_dark_shaman_gear", 105369, 105370, 105371 ) -- SoO specific items
spec:RegisterGear( "prideful_gladiator", 103823, 103824, 103825, 103826, 103827 ) -- PvP gear

-- Tier set bonuses as auras
spec:RegisterAura( "ret_tier14_2pc", {
    id = 105515,
    duration = 3600,
    max_stack = 1,
} )

spec:RegisterAura( "ret_tier14_4pc", {
    id = 105516, 
    duration = 15,
    max_stack = 1,
} )

spec:RegisterAura( "ret_tier15_2pc", {
    id = 138170,
    duration = 3600, 
    max_stack = 1,
} )

spec:RegisterAura( "ret_tier15_4pc", {
    id = 138171,
    duration = 6,
    max_stack = 1,
} )

spec:RegisterAura( "ret_tier16_2pc", {
    id = 144959,
    duration = 3600,
    max_stack = 1,
} )

spec:RegisterAura( "ret_tier16_4pc", {
    id = 144960,
    duration = 30,
    max_stack = 1,
} )

-- Talents (MoP 6-tier talent system)
spec:RegisterTalents( {
    -- Tier 1 (Level 15) - Movement
    speed_of_light            = { 2199, 1, 85499  }, -- +70% movement speed for 8 sec
    long_arm_of_the_law       = { 2200, 1, 114158 }, -- Judgments increase movement speed by 45% for 3 sec
    pursuit_of_justice        = { 2201, 1, 26023  }, -- +15% movement speed per Holy Power charge

    -- Tier 2 (Level 30) - Control
    fist_of_justice           = { 2202, 1, 105593 }, -- Reduces Hammer of Justice cooldown by 50%
    repentance                = { 2203, 1, 20066  }, -- Puts the enemy target in a state of meditation, incapacitating them for up to 1 min.
    blinding_light            = { 2204, 1, 115750 }, -- Emits dazzling light in all directions, blinding enemies within 10 yards for 6 sec.

    -- Tier 3 (Level 45) - Healing
    selfless_healer           = { 2205, 1, 85804  }, -- Your Holy power spending abilities reduce the cast time and mana cost of your next Flash of Light.
    eternal_flame             = { 2206, 1, 114163 }, -- Consumes all Holy Power to place a protective Holy flame on a friendly target, which heals over 30 sec.
    sacred_shield             = { 2207, 1, 20925  }, -- Places a Sacred Shield on a friendly target, absorbing damage every 6 sec for 30 sec.

    -- Tier 4 (Level 60) - Utility/CC
    hand_of_purity            = { 2208, 1, 114039 }, -- Protects a party or raid member, reducing harmful periodic effects by 70% for 6 sec.
    unbreakable_spirit        = { 2209, 1, 114154 }, -- Reduces the cooldown of your Divine Shield, Divine Protection, and Lay on Hands by 50%.
    clemency                  = { 2210, 1, 105622 }, -- Increases the number of charges on your Hand spells by 1.

    -- Tier 5 (Level 75) - DPS
    divine_purpose            = { 2211, 1, 86172  }, -- Your Holy Power abilities have a 15% chance to make your next Holy Power ability free and more effective.
    holy_avenger              = { 2212, 1, 105809 }, -- Your Holy power generating abilities generate 3 charges of Holy Power for 18 sec.
    sanctified_wrath          = { 2213, 1, 53376  }, -- Increases the duration of Avenging Wrath by 5 sec and causes your Judgment to generate 1 additional Holy Power during Avenging Wrath.

    -- Tier 6 (Level 90) - DPS/Utility
    holy_prism                = { 2214, 1, 114165 }, -- Fires a beam of light that hits a target for Holy damage or healing.
    lights_hammer             = { 2215, 1, 114158 }, -- Hurls a Light-infused hammer to the ground, dealing Holy damage to enemies and healing allies.
    execution_sentence        = { 2216, 1, 114157 }  -- A hammer slowly falls from the sky, dealing Holy damage to an enemy or healing an ally.
} )

-- Comprehensive Retribution Paladin Glyphs for MoP
spec:RegisterGlyphs( {
    -- Major Glyphs
    [56414] = "double_jeopardy",   -- Your Judgment deals 20% additional damage when striking a target already affected by your Judgment.
    [56420] = "mass_exorcism",     -- Your Exorcism is now instant and hits all targets within 8 yards of your target, but has a 20 sec cooldown.
    [56416] = "inquisition",       -- Increases the duration of your Inquisition by 30 sec.
    [63219] = "final_wrath",       -- Avenging Wrath increases the damage of Hammer of Wrath by 50%.
    [54935] = "templars_verdict",  -- Your Templar's Verdict automatically hits an additional nearby enemy for 50% damage.
    [57937] = "divine_storm",      -- Increases the damage of Divine Storm by 20%, but removes the healing component of the ability.
    [56417] = "zealotry",          -- Your Zealotry ability lasts 10 additional seconds.
    [56421] = "consecration",      -- Increases the radius and damage of your Consecration by 20%.
    [63220] = "word_of_glory",     -- Your Word of Glory can be used on any target, not just injured ones.
    [56422] = "hammer_of_justice", -- Your Hammer of Justice is replaced by Hammer of the Righteous.
    [56415] = "divine_protection", -- Reduces the cooldown of Divine Protection by 60 sec, but its damage reduction is reduced to 20%.
    [54934] = "seal_of_light",     -- Your Seal of Light now affects up to 3 targets instead of 1.
    [56419] = "turn_evil",         -- Your Turn Evil spell is now instant cast.
    [63218] = "divine_favor",      -- Your Divine Favor now increases your spell critical strike chance by 25% for the next 3 spells.
    [56418] = "cleanse",           -- Your Cleanse spell can be cast on hostile targets to remove beneficial magic effects.
    [57955] = "devotion_aura",     -- Your Devotion Aura also reduces magical damage taken by party and raid members by 20%.
    [57958] = "divine_storm_heal", -- Your Divine Storm heals you for 25% of total damage done.
    [57956] = "blessing_of_kings", -- Your Blessing of Kings increases stats by an additional 5%.
    [57957] = "blessing_of_might", -- Your Blessing of Might increases attack power by an additional 10%.
    [63217] = "holy_light",        -- Reduces the cast time of your Holy Light by 0.5 sec.
    [54936] = "lay_on_hands",      -- Your Lay on Hands grants forbearance for 30 sec less.
    [56413] = "flash_of_light",    -- Your Flash of Light heals for 50% more, but costs 50% more mana.
    [57959] = "retribution_aura",  -- Your Retribution Aura reflects 50% more damage.
    [57960] = "concentration_aura", -- Your Concentration Aura also provides 15% resistance to interrupt effects.
    [54937] = "divine_shield",     -- Reduces the cooldown of your Divine Shield by 60 sec, but also reduces its duration by 4 sec.
    [63221] = "avenging_wrath",    -- Your Avenging Wrath increases movement speed by 20%.
    [56423] = "guardian_spirit",   -- Your Guardian Spirit prevents the target from dying below 10% health.
    [57961] = "shadow_resistance_aura", -- Your Shadow Resistance Aura also reduces shadow damage taken by 20%.
    [57962] = "fire_resistance_aura",   -- Your Fire Resistance Aura also reduces fire damage taken by 20%.
    [57963] = "frost_resistance_aura",  -- Your Frost Resistance Aura also reduces frost damage taken by 20%.
    
    -- Minor Glyphs  
    [57954] = "righteous_retreat", -- When you use Divine Shield, you also become immune to disarm effects, but the cooldown of Divine Shield is increased by 50%.
    [57947] = "blessed_life",      -- You have a 50% chance to generate 1 charge of Holy Power when you take damage.
    [43367] = "fire_from_heaven",  -- Your Holy Wrath is channeled, dealing 40% damage per second for 3 sec, and has a 15 sec cooldown.
    [57948] = "insight",           -- Your spells and abilities reduce the remaining cooldown on your Lay on Hands by 5 sec when they critically hit.
    [57949] = "justice",           -- Increases the range of your Hammer of Justice by 5 yards.
    [57950] = "seal_of_blood",     -- Your melee attacks heal you for 2% of the damage dealt.
    [57951] = "sense_undead",      -- Your Sense Undead ability also increases movement speed by 30% for 15 sec.
    [57952] = "the_wise",          -- Reduces the mana cost of your Blessing spells by 50%.
    [57953] = "truth",             -- Reduces the cooldown of your Hand of Reckoning by 2 sec.
    [43340] = "blessing_of_wisdom", -- Your Blessing of Wisdom increases mana regeneration by an additional 50%.
    [43355] = "blessing_of_sanctuary", -- Your Blessing of Sanctuary reduces damage taken by an additional 5%.
    [43356] = "crusader_strike",   -- Your Crusader Strike heals a nearby injured ally for 30% of the damage dealt.
    [43357] = "divine_storm_visual", -- Your Divine Storm creates a more dramatic visual effect.
    [43358] = "hammer_of_wrath_range", -- Increases the range of your Hammer of Wrath by 5 yards.
    [43359] = "seal_of_command",   -- Your Seal of Command has a 25% chance to not trigger its cooldown.
} )

-- Helper function for consistent aura detection
-- GetPlayerAuraBySpellID equivalent for older clients
local function GetPlayerAuraBySpellID(spellID)
    if UA_GetPlayerAuraBySpellID then
        return UA_GetPlayerAuraBySpellID(spellID)
    end
    return FindUnitBuffByID("player", spellID)
end

-- Enhanced target debuff detection
local function GetTargetDebuffByID(spellID, caster)
    caster = caster or "player"
    local name, icon, count, debuffType, duration, expirationTime, unitCaster = FindUnitDebuffByID("target", spellID)
    if name and (unitCaster == caster or caster == "any") then
        return name, icon, count, debuffType, duration, expirationTime, unitCaster
    end
    return nil
end

-- Advanced Retribution Paladin Auras with Enhanced Generate Functions
spec:RegisterAuras( {
    
    -- Inquisition: Key damage buff with enhanced tracking
    inquisition = {
        id = 84963,
        duration = function() 
            local duration = 20 + (10 * state.holy_power.current) -- Base + per Holy Power
            if state.glyph.inquisition.enabled then
                duration = duration + 30
            end
            return duration
        end,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(84963)
            
            if name then
                t.name = name
                t.count = count > 0 and count or 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.stacks = count
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.stacks = 0
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Divine Purpose: Free and enhanced Holy Power ability
    divine_purpose = {
        id = 86172,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(86172)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Art of War: Instant Exorcism proc
    art_of_war = {
        id = 59578,
        duration = 15,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(59578)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Zealotry: Enhanced Crusader Strike damage
    zealotry = {
        id = 85696,
        duration = 20,
        max_stack = 3,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(85696)
            
            if name then
                t.name = name
                t.count = count > 0 and count or 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.stacks = count
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.stacks = 0
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Avenging Wrath: Wings!
    avenging_wrath = {
        id = 31884,
        duration = function()
            local duration = 20
            if state.talent.sanctified_wrath.enabled then
                duration = duration + 5
            end
            if state.glyph.avenging_wrath.enabled then
                -- Glyph effect
            end
            return duration
        end,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(31884)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Guardian of Ancient Kings
    guardian_of_ancient_kings = {
        id = 86659,
        duration = 12,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(86659)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Divine Protection
    divine_protection = {
        id = 498,
        duration = function()
            local duration = 10
            if state.glyph.divine_protection.enabled then
                duration = 20 -- Glyph increases duration but reduces effectiveness
            end
            return duration
        end,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(498)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Divine Shield
    divine_shield = {
        id = 642,
        duration = function()
            local duration = 8
            if state.glyph.divine_shield.enabled then
                duration = duration - 4 -- Glyph reduces duration but also cooldown
            end
            return duration
        end,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(642)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Seals
    seal_of_truth = {
        id = 31801,
        duration = 1800,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(31801)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    seal_of_justice = {
        id = 20164,
        duration = 1800,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(20164)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    seal_of_insight = {
        id = 20165,
        duration = 1800,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(20165)
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Target debuffs
    censure = {
        id = 31803,
        duration = 15,
        max_stack = 5,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetTargetDebuffByID(31803, "player")
            
            if name then
                t.name = name
                t.count = count > 0 and count or 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.stacks = count
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.stacks = 0
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Judgment debuffs
    judgment_of_justice = {
        id = 20170,
        duration = 20,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetTargetDebuffByID(20170, "player")
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    judgment_of_truth = {
        id = 31804,
        duration = 20,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetTargetDebuffByID(31804, "player")
            
            if name then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },

    holy_avenger = {
        id = 105809,
        duration = 18,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(105809)

            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end

            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },

    divine_crusader = {
        id = 144595,
        duration = 12,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(144595)

            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Tier set bonuses
    ret_tier14_2pc = {
        id = 105515,
        duration = 3600,
        max_stack = 1,
        generate = function( t )
            if state.set_bonus.tier14_2pc > 0 then
                t.name = "Retribution T14 2-Piece Bonus"
                t.count = 1
                t.expires = query_time + 3600
                t.applied = query_time
                t.caster = "player"
                t.up = true
                t.down = false
                t.remains = 3600
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    ret_tier14_4pc = {
        id = 105516,
        duration = 15,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(105516)
            
            if name and state.set_bonus.tier14_4pc > 0 then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    ret_tier15_2pc = {
        id = 138170,
        duration = 3600,
        max_stack = 1,
        generate = function( t )
            if state.set_bonus.tier15_2pc > 0 then
                t.name = "Retribution T15 2-Piece Bonus"
                t.count = 1
                t.expires = query_time + 3600
                t.applied = query_time
                t.caster = "player"
                t.up = true
                t.down = false
                t.remains = 3600
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    ret_tier15_4pc = {
        id = 138171,
        duration = 6,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(138171)
            
            if name and state.set_bonus.tier15_4pc > 0 then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    ret_tier16_2pc = {
        id = 144959,
        duration = 3600,
        max_stack = 1,
        generate = function( t )
            if state.set_bonus.tier16_2pc > 0 then
                t.name = "Retribution T16 2-Piece Bonus"
                t.count = 1
                t.expires = query_time + 3600
                t.applied = query_time
                t.caster = "player"
                t.up = true
                t.down = false
                t.remains = 3600
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    ret_tier16_4pc = {
        id = 144960,
        duration = 30,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = GetPlayerAuraBySpellID(144960)
            
            if name and state.set_bonus.tier16_4pc > 0 then
                t.name = name
                t.count = 1
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
              t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
} )

-- Abilities
spec:RegisterAbilities( {
    -- Guardian of Ancient Kings (Ret version): Major damage cooldown
    guardian_of_ancient_kings = {
        id = 86698,
        duration = 30,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 86698 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Holy Avenger: Holy Power abilities more effective
    holy_avenger = {
        id = 105809,
        duration = 18,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 105809 )

            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                t.up = true
                t.down = false
                t.remains = expirationTime - GetTime()
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
            t.up = false
            t.down = true
            t.remains = 0
        end
    },
    
    -- Divine Protection: Reduces damage taken
    divine_protection = {
        id = 498,
        duration = 10,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 498 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Divine Shield: Complete immunity
    divine_shield = {
        id = 642,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 642 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Forbearance: Cannot receive certain immunities again
    forbearance = {
        id = 25771,
        duration = 60,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitDebuffByID( "player", 25771 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Speed of Light: Increased movement speed
    speed_of_light = {
        id = 85499,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 85499 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Long Arm of the Law: Increased movement speed after Judgment
    long_arm_of_the_law = {
        id = 114158,
        duration = 3,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 114158 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Pursuit of Justice: Increased movement speed from Holy Power
    pursuit_of_justice = {
        id = 26023,
        duration = 3600,
        max_stack = 3,
        generate = function( t )
            t.count = state.holy_power.current
            t.expires = 3600
            t.applied = 0
            t.caster = "player"
        end
    },
    
    -- Hand of Freedom: Immunity to movement impairing effects
    hand_of_freedom = {
        id = 1044,
        duration = 6,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 1044, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Hand of Protection: Immunity to physical damage
    hand_of_protection = {
        id = 1022,
        duration = 10,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 1022, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Hand of Sacrifice: Redirects damage to Paladin
    hand_of_sacrifice = {
        id = 6940,
        duration = 12,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "target", 6940, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Sacred Shield: Absorbs damage periodically
    sacred_shield = {
        id = 65148,
        duration = 30,
        tick_time = 6,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 65148 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Eternal Flame: HoT from talent
    eternal_flame = {
        id = 114163,
        duration = function() return 30 + (3 * state.holy_power.current) end,
        tick_time = 3,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 114163, "PLAYER" )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
    
    -- Art of War: Proc for instant and free Exorcism
    art_of_war = {
        id = 87138,
        duration = 15,
        max_stack = 1,
        generate = function( t )
            local name, icon, count, debuffType, duration, expirationTime, caster = FindUnitBuffByID( "player", 87138 )
            
            if name then
                t.name = name
                t.count = count
                t.expires = expirationTime
                t.applied = expirationTime - duration
                t.caster = caster
                return
            end
            
            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end
    },
} )

-- Retribution Paladin abilities
spec:RegisterAbilities( {
    -- Core Retribution abilities
    templars_verdict = {
        id = 85256,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        spend = function() 
            if state.buff.divine_purpose.up then return 0 end
            return 3 
        end,
        spendType = "holy_power",
        
        startsCombat = true,
        texture = 461860,
        
        handler = function()
            -- Templar's Verdict mechanic
            if state.buff.divine_purpose.up then
                removeBuff("divine_purpose")
            end
            
            -- Divine Purpose talent proc chance
            if state.talent.divine_purpose.enabled and not state.buff.divine_purpose.up and math.random() < 0.15 then
                applyBuff("divine_purpose")
            end
        end
    },
    
    divine_storm = {
        id = 53385,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        spend = function() 
            if state.buff.divine_purpose.up then return 0 end
            return 3 
        end,
        spendType = "holy_power",
        
        startsCombat = true,
        texture = 236250,
        
        handler = function()
            -- Divine Storm mechanic
            if state.buff.divine_purpose.up then
                removeBuff("divine_purpose")
            end
            
            -- Divine Purpose talent proc chance
            if state.talent.divine_purpose.enabled and not state.buff.divine_purpose.up and math.random() < 0.15 then
                applyBuff("divine_purpose")
            end
        end
    },
    
    exorcism = {
        id = 879,
        cast = function() 
            if state.buff.art_of_war.up then return 0 end
            if state.glyph.mass_exorcism.enabled then return 0 end
            return 1.5 
        end,
        cooldown = function() 
            if state.glyph.mass_exorcism.enabled then return 20 end
            return 15 
        end,
        gcd = "spell",
        
        spend = function() 
            if state.buff.art_of_war.up then return 0 end
            return 0.18 
        end,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135903,
        
        handler = function()
            -- Exorcism mechanic
            if state.buff.art_of_war.up then
                removeBuff("art_of_war")
            end
            
            gain(1, "holy_power")
        end
    },
    
    inquisition = {
        id = 84963,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        spend = function() 
            if state.buff.divine_purpose.up then return 0 end
            return 3 
        end,
        spendType = "holy_power",
        
        startsCombat = false,
        texture = 135975,
        
        handler = function()
            -- Inquisition mechanic - consumes all Holy Power for duration
            local duration = 30 * state.holy_power.current
            
            if state.buff.divine_purpose.up then
                -- If Divine Purpose, treat as 3 Holy Power
                removeBuff("divine_purpose")
                duration = 90
            end
            
            -- Glyph of Inquisition increases duration by 30 sec
            if state.glyph.inquisition.enabled then
                duration = duration + 30
            end
            
            applyBuff("inquisition", duration)
            
            -- Divine Purpose talent proc chance
            if state.talent.divine_purpose.enabled and not state.buff.divine_purpose.up and math.random() < 0.15 then
                applyBuff("divine_purpose")
            end
        end
    },
    
    guardian_of_ancient_kings = {
        id = 86698,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "cooldowns",
        
        startsCombat = false,
        texture = 409594,
        
        handler = function()
            applyBuff("guardian_of_ancient_kings")
        end
    },
    
    avenging_wrath = {
        id = 31884,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "cooldowns",
        
        startsCombat = false,
        texture = 135875,
        
        handler = function()
            applyBuff("avenging_wrath")
        end
    },
    
    holy_avenger = {
        id = 105809,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        
        toggle = "cooldowns",
        
        talent = "holy_avenger",
        
        startsCombat = false,
        texture = 571555,
        
        handler = function()
            applyBuff("holy_avenger")
        end
    },
    
    holy_prism = {
        id = 114165,
        cast = 0,
        cooldown = 20,
        gcd = "spell",
        
        spend = 0.35,
        spendType = "mana",
        
        talent = "holy_prism",
        
        startsCombat = function() return not state.option.holy_prism_heal end,
        texture = 613407,
        
        handler = function()
            -- Holy Prism mechanic
            -- If cast on enemy, damages target and heals 5 nearby friendlies
            -- If cast on friendly, heals target and damages 5 nearby enemies
        end
    },
    
    lights_hammer = {
        id = 114158,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        
        spend = 0.38,
        spendType = "mana",
        
        talent = "lights_hammer",
        
        startsCombat = true,
        texture = 613952,
        
        handler = function()
            -- Light's Hammer mechanic - ground target AoE that heals allies and damages enemies
        end
    },
    
    execution_sentence = {
        id = 114157,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        
        spend = 0.38,
        spendType = "mana",
        
        talent = "execution_sentence",
        
        startsCombat = function() return not state.option.execution_sentence_heal end,
        texture = 613954,
        
        handler = function()
            -- Execution Sentence mechanic
            -- If cast on enemy, damages after 10 seconds
            -- If cast on friendly, heals after 10 seconds
        end
    },
    
    divine_shield = {
        id = 642,
        cast = 0,
        cooldown = function()
            return state.talent.unbreakable_spirit.enabled and 150 or 300
        end,
        gcd = "spell",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 524354,
        
        handler = function()
            applyBuff("divine_shield")
            applyDebuff("player", "forbearance")
        end
    },
    
    divine_protection = {
        id = 498,
        cast = 0,
        cooldown = function()
            return state.talent.unbreakable_spirit.enabled and 30 or 60
        end,
        gcd = "off",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 524353,
        
        handler = function()
            applyBuff("divine_protection")
        end
    },
    
    lay_on_hands = {
        id = 633,
        cast = 0,
        cooldown = function() 
            return state.talent.unbreakable_spirit.enabled and 360 or 600
        end,
        gcd = "spell",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135928,
        
        handler = function()
            -- Heals target for Paladin's maximum health
            -- Applies Forbearance
            applyDebuff("target", "forbearance")
        end
    },
    
    hand_of_freedom = {
        id = 1044,
        cast = 0,
        cooldown = function() 
            if state.talent.clemency.enabled then
                return { charges = 2, execRate = 25 }
            end
            return 25
        end,
        gcd = "spell",
        
        startsCombat = false,
        texture = 135968,
        
        handler = function()
            applyBuff("hand_of_freedom")
        end
    },
    
    hand_of_protection = {
        id = 1022,
        cast = 0,
        cooldown = function() 
            if state.talent.clemency.enabled then
                return { charges = 2, execRate = 300 }
            end
            return 300
        end,
        gcd = "spell",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135964,
        
        handler = function()
            applyBuff("hand_of_protection")
            applyDebuff("player", "forbearance")
        end
    },
    
    hand_of_sacrifice = {
        id = 6940,
        cast = 0,
        cooldown = function() 
            if state.talent.clemency.enabled then
                return { charges = 2, execRate = 120 }
            end
            return 120
        end,
        gcd = "off",
        
        toggle = "defensives",
        
        startsCombat = false,
        texture = 135966,
        
        handler = function()
            applyBuff("hand_of_sacrifice", "target")
        end
    },
    
    hand_of_purity = {
        id = 114039,
        cast = 0,
        cooldown = 30,
        gcd = "off",
        
        talent = "hand_of_purity",
        
        startsCombat = false,
        texture = 458726,
        
        handler = function()
            -- Applies Hand of Purity effect
        end
    },
    
    -- Shared Paladin abilities
    crusader_strike = {
        id = 35395,
        cast = 0,
        cooldown = 4.5,
        gcd = "spell",
        
        spend = 0.06,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135891,
        
        handler = function()
            gain(1, "holy_power")
        end
    },

    hammer_of_the_righteous = {
        id = 53595,
        cast = 0,
        cooldown = 4.5,
        gcd = "spell",
        
        spend = 0.03,
        spendType = "mana",
        
        startsCombat = true,
        texture = 236253,

        handler = function()
            gain(1, "holy_power")
        end
    },
    
    judgment = {
        id = 20271,
        cast = 0,
        cooldown = 6,
        gcd = "spell",
        
        spend = 0.05,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135959,
        
        handler = function()
            -- Sanctified Wrath talent interaction - Judgment generates 1 additional Holy Power during Avenging Wrath
            if state.buff.avenging_wrath.up and state.talent.sanctified_wrath.enabled then
                gain(2, "holy_power")
            else
                gain(1, "holy_power")
            end
            
            -- Long Arm of the Law movement speed
            if state.talent.long_arm_of_the_law.enabled then
                applyBuff("long_arm_of_the_law")
            end
        end
    },
    
    cleanse = {
        id = 4987,
        cast = 0,
        cooldown = 8,
        gcd = "spell",
        
        spend = 0.14,
        spendType = "mana",
        
        startsCombat = false,
        texture = 135949,
        
        handler = function()
            -- Removes 1 Poison effect, 1 Disease effect, and 1 Magic effect from a friendly target
        end
    },
    
    hammer_of_justice = {
        id = 853,
        cast = 0,
        cooldown = function() 
            if state.talent.fist_of_justice.enabled then
                return 30
            end
            return 60
        end,
        gcd = "spell",
        
        startsCombat = true,
        texture = 135963,
        
        handler = function()
            -- Stuns target for 6 seconds
        end
    },
    
    hammer_of_wrath = {
        id = 24275,
        cast = 0,
        cooldown = 6,
        gcd = "spell",
        
        spend = 0.12,
        spendType = "mana",
        
        usable = function()
            -- Usable when target below 20% health or during Avenging Wrath
            return target.health_pct < 20 or state.buff.avenging_wrath.up
        end,
        
        startsCombat = true,
        texture = 138168,
        
        handler = function()
            gain(1, "holy_power")
        end
    },
    
    consecration = {
        id = 26573,
        cast = 0,
        cooldown = 9,
        gcd = "spell",
        
        spend = 0.24,
        spendType = "mana",
        
        startsCombat = true,
        texture = 135926,
        
        handler = function()
            -- Creates consecrated ground that deals Holy damage over time
        end
    },
    
    word_of_glory = {
        id = 85673,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        spend = function() 
            if state.buff.divine_purpose.up then return 0 end
            return 3 
        end,
        spendType = "holy_power",
        
        startsCombat = false,
        texture = 646176,
        
        handler = function()
            -- Word of Glory mechanic - consumes all Holy Power
            if state.buff.divine_purpose.up then
                removeBuff("divine_purpose")
            else
                -- Modify healing based on Holy Power consumed
                -- Word of Glory's base healing amount is multiplied per Holy Power
            end
            
            -- Selfless Healer reductions for next Flash of Light if talented
            if state.talent.selfless_healer.enabled then
                applyBuff("selfless_healer", nil, 3)
            end
            
            -- Eternal Flame talent application instead of direct heal
            if state.talent.eternal_flame.enabled then
                applyBuff("eternal_flame")
            end
            
            -- Divine Purpose talent proc chance
            if state.talent.divine_purpose.enabled and not state.buff.divine_purpose.up and math.random() < 0.15 then
                applyBuff("divine_purpose")
            end
        end
    },
    
    repentance = {
        id = 20066,
        cast = 1.5,
        cooldown = 15,
        gcd = "spell",
        
        talent = "repentance",
        
        spend = 0.09,
        spendType = "mana",
        
        startsCombat = false,
        texture = 135942,
        
        handler = function()
            -- Incapacitates target for up to 1 minute
        end
    },
    
    blinding_light = {
        id = 115750,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        
        talent = "blinding_light",
        
        spend = 0.18,
        spendType = "mana",
        
        startsCombat = true,
        texture = 571553,
        
        handler = function()
            -- Disorients all nearby enemies
        end
    },
    
    speed_of_light = {
        id = 85499,
        cast = 0,
        cooldown = 45,
        gcd = "off",
        
        talent = "speed_of_light",
        
        startsCombat = false,
        texture = 538056,
        
        handler = function()
            applyBuff("speed_of_light")
        end
    },
    
    sacred_shield = {
        id = 20925,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        
        talent = "sacred_shield",
        
        spend = 0.23,
        spendType = "mana",
        
        startsCombat = false,
        texture = 612316,
        
        handler = function()
            applyBuff("sacred_shield")
        end
    },

    blessing_of_kings = {
        id = 20217,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        spend = 0.05,
        spendType = "mana",

        startsCombat = false,
        texture = 135993,

        handler = function()
            applyBuff("blessing_of_kings")
        end
    },

    blessing_of_might = {
        id = 19740,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        spend = 0.05,
        spendType = "mana",

        startsCombat = false,
        texture = 135908,

        handler = function()
            applyBuff("blessing_of_might")
        end
    },

    seal_of_truth = {
        id = 31801,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        startsCombat = false,
        texture = 135969,

        handler = function()
            applyBuff("seal_of_truth")
        end
    },

    seal_of_righteousness = {
        id = 20154,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        startsCombat = false,
        texture = 135960,

        handler = function()
            applyBuff("seal_of_righteousness")
        end
    },

    seal_of_justice = {
        id = 20164,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        startsCombat = false,
        texture = 135971,

        handler = function()
            applyBuff("seal_of_justice")
        end
    },

    seal_of_insight = {
        id = 20165,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        startsCombat = false,
        texture = 135917,

        handler = function()
            applyBuff("seal_of_insight")
        end
    }
} )

-- States and calculations for Retribution specific mechanics
-- local function checkArtOfWar()
--     -- 20% chance to proc Art of War on Crusader Strike
--     return buff.art_of_war.up
-- end

-- state.RegisterExpressions( {
--     ['artOfWarActive'] = function()
--         return checkArtOfWar()
--     end
-- } )

-- Range
spec:RegisterRanges( "judgment", "hammer_of_justice", "rebuke", "crusader_strike" )

-- Options
spec:RegisterOptions( {
    enabled = true,
    
    aoe = 2,
    
    nameplates = true,
    nameplateRange = 8,
    
    damage = true,
    damageExpiration = 8,
    
    potion = "jade_serpent_potion",
    
    package = "Retribution",
    
    holy_prism_heal = false,
    execution_sentence_heal = false,
} )

-- Register default pack for MoP Retribution Paladin
spec:RegisterPack( "Retribution", 20250715, [[Hekili:9M1wVTTnu4FlfdWOPRtZw2EjDikp09YAFOyyQpljAzABUOBJKkPgWq)23HuwwKuKsozB9H26sEU8DUYZbkAr0xJc3I44OV4p3F98BxS2ZF(6vl8Jc5hRWrHvO0hr7HFuGYH)(pXCkztnNuw0K87KCmQj5Jyosq4XSs0wHazL10uG4qs(Vrr74njRxD3pDxu4MAsg)tfrBSRuGZkCA0xUDEu4bY2T4wkXS0OWVEGWAse)b04zq1KuUd()PTOjJW4W17kPaYWpsYiEaQOL7izaw(HMK)aLH2sk(1MevR4ZT8Z8QO40Y8ni(pg8ZBYWmgPyFC5U4hH)L9EYUG3SPE3opghXzE1vtZyoz)bEpJ5ightp6KvggLjyJtR5heSji6jCmUaNtWS7xnoBuH2WL1Scabdz)Hah8xv26gUC7LZec5TsOVjRSCBwnJ7rXavNozECD1m5jONWf7fM)Zue)aC8nNoXr09yUhhswI5LXBj47dwn)gv9rk(7AcJORuLd92w(CXPtdoMIZrKc29b(3m7ThkZogxv(mM(qWsRQTNI35p)S42sEIuGJRQPvLmCR9PHnDtsaVbWqjIcmSVgr3sqfIGcQiLGl495qtWReHsnIPcY5OmGDp1J9WfiilB7SHEjik0BIcNIQORz4ychN)ErHCaK)x8iMVqOKNquIqKENpmMDSinMLvYdwmZMsmJ(krN(dH6K0hdwCfGWFcq4)FmiKxhVRMEu7umLHPIaLw0NMIkejqukeiuVb)nCQSdsmdUbxKIvcydVC8W2lZy0SMmrDpl(akpxlNr78)30(5Yhg4GYT10XxTUmy9ifDDnv0Y11YOHY6XvUQStP1m0wqesHptfeQIaYfRYquw8tyOOnv2U2cGhfutjpNM8m7302tBLwFbzuu0rr2fs9QNre(7z40G0YYmrKZZG4ojkGYu08W8ztrY9bZ98FLrb7VrCv(Vr5QhQ8d4(xch)vqGVo4bGNsEepUB1GyRUvh0O6wDqYa3k(BL0ucZrvL(jWdQZyqpZnLf1mqI8yobtxSo2VkD2(SJvhetFWI7Kzx7av99x1B3NB0JBOtOJkRwV5LQMT5D)lsJUQ8fB1B2CVJBUxCy2mxZlvnxZ7gyUobUs0BvvQOzJrSE1lR)RRHMEy1vbNj5STvi9CMQ6alYd7s1IcFgrleJbff(P8Qskhs)s8ngF3R5ZrHYFjxmbVdvNXHF(f5IkDI6JrHPuymcyIHOW32Ky8svBSo50PMKHxcnosMD(0H9usUPLVHdp2KCFqtYQ5ajrHTyg2UqoNCehwKzs8zooBRIC5JBvNVeqZK2r)tonjpa3TCeKQt97abnxrDwlnunlf8iSTLoTnldt0lfDVRqqREDcY5a1czU2Pmhz25oFQf1kVs171fh6XJQefq4xmGqhDDZyRck3J52KakArFYPfynmB2irYyATwr2c(213Vaja23ooS9FbW2)7dS9fW(obS7WA)O8QMcq1h0O6YO9guTyUkz6Z6BsQ7oqtoZ)uPBVEhKwE5qaibU7wtJTPW3jmRPBjCD3Tr)TT2UG(2ApcNVEY(DQppymE)GEaN73QdD1NELiFI2B2NLXuvcSpIoC3UBehWvzEknamMfqQyZMC2nodF8mxrGU34GxuNqV3QwHASsIzj6DgyegLda6e7Z0lDX4FQg2uCcoUMK5sRCAsfpJaJakX5hUkFPLef7tT4oDXF(4AAerzly47UhOTAZv2cCAlOjfQVAe2y7iJiSVzZb9iSJvRUIiSdoTfHDsQse23DRa3nXmVroVP8gxR2jVCK17uFAO9gj4wR6W72lZ0tBwVR7Pn3M7kCXMSyZ3oKgvNQ5alxtzZi1gMDlUIoAtuEOn0XfxUUJDPzjPUJ1CVXRWXAYInh7qAuCSlDxwl9ed2i1E66K9Yx6Ese3vfUxq6bnfAgEx(c2AXHiTAdURShz13lTbVCxKqAHx(omrwwXTJPnMFlQ2pjgLu1EV1pRLkWEZzVy3xUsMR60m6OU)ZvzhkYVUL0LC1rv9ueTV3LqqVSMMwKK2NatirToDNxwxRCugfqG(lPrHYpNP8OO)5p]] )
