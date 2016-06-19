-------------------------------------------------------------------------------------------------------
---     _____     _                   ____															---
---    |  __ \   | |                 |  _  \	  H    H											---
---    | |  | |  | |                 | |  \ \	  H    H											---
---    | |__| |  | |                 | |   \ \	  H    H			       _________				---
---    |     /   | |                 | |    | |	  H    H			      |___   ___|				---
---    |     \   | |                 | |    | |	  HHHHHH			 _        | |		   _		---
---    |  ___ \  | |   ___     ___   | |    | |	  H    H   _     _	| |____   | |   ___	  | |___	---
---    | |   | | | |  / _ \   / _ \  | |    | |	  H    H  | |   | |	|  __  \  | |  / _ \  |   _  \	---
---    | |___| | | | | |_| | | |_| | | |___/ /	  H    H  | |___| |	| |  | |  | | |  __/  | |  |_|	---
---    |______/  |_|  \___/   \___/  |______/	  H    H   \_____/	|_|  |_|  |_|  \___|  |_|  		---
---    																								---
-------------------------------------------------------------------------------------------------------
-- Blood Hunter Bot V 1.25
-- Coded By: ModernSaint

--Basic Equations--
local _G = getfenv(0)
local object = _G.object
object.myName = object:GetName()
object.bRunLogic = true
object.bRunBehaviors	= true
object.bUpdates = true
object.bUseShop = true
object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false
object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random
local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading Blood Hunter...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 3, LongSolo = 1, ShortSupport = 2, LongSupport = 2, ShortCarry = 5, LongCarry = 4}

--Hero Declare
object.heroName = 'Hero_Hunter'

----------------------------------
-- Item Build
----------------------------------
behaviorLib.StartingItems =
	{"Item_RunesOfTheBlight", "Item_ManaPotion", "Item_IronBuckler", "Item_LoggersHatchet"}
behaviorLib.LaneItems =
	{"Item_Marchers", "Item_EnhancedMarchers", "Item_Nuke 5" }
behaviorLib.MidItems =
	{"Item_ManaBurn1", "Item_Lightbrand", "Item_BehemothsHeart" }
behaviorLib.LateItems =
	{"Item_GrimoireOfPower", "Item_Damage9"}

--------------------------------
-- Levelling Order | Skills
--------------------------------
-- 0 = Silence	3 = Haemorrhage
-- 1 = Feast	4 = Attribute boost
-- 2 = Blood Sense	
object.tSkills = {
	1, 0, 1, 2, 1,
	3, 1, 0, 2, 2, 
	3, 0, 2, 0, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4,
}

------------------------------
--	 skill Declaration  	--
------------------------------
local bSkillsValid = false
function object:SkillBuild()
-- takes care at load/reload, <name_#> to be replaced by some convenient name.
	local unitSelf = self.core.unitSelf
	
	if not bSkillsValid then
		skills.abilSilence 			= unitSelf:GetAbility(0)
		skills.abilFeast 			= unitSelf:GetAbility(1)
		skills.abilBloodSense		= unitSelf:GetAbility(2)
		skills.abilHemorrhage 		= unitSelf:GetAbility(3)
		skills.abilAttributeBoost	= unitSelf:GetAbility(4)
		
		if skills.abilSilence and skills.abilBloodSense and skills.abilFeast and skills.abilHemorrhage and skills.abilAttributeBoost then
			bSkillsValid = true
		else 
			return
		end
	end
	
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
    
	local nlev = unitSelf:GetLevel()
	local nlevpts = unitSelf:GetAbilityPointsAvailable()
	for i = nlev, nlev+nlevpts do
		unitSelf:GetAbility( object.tSkills[i] ):LevelUp()
	end
end
--core.WrapInTable(unitSelf:GetAbility(3))

----------------------------------
-- Harass Utility Calculations  --
----------------------------------
-- bonus aggression points if a skill/item is available for use
object.nSilenceUp		= 36
object.nFeastUp 		= 28
object.nHemorrhageUp	= 38
object.nManaBurn1Up		= 35

-- bonus aggression points that are applied to the bot upon successfully using a skill/item
object.nSilenceUse		= 38
object.nFeastUse 		= 24
object.nHemorrhageUse 	= 52
object.nManaBurn1Use 	= 40

-- thresholds of aggression the bot must reach to use these abilities
object.nSilenceThreshold	= 38
object.nFeastThreshold 		= 34
object.nHemorrhageThreshold	= 48
object.nManaBurn1Threshold	= 44

-- Additional Modifiers

--weight overrides
behaviorLib.nCreepPushbackMul		= 0.3
behaviorLib.nTargetPositioningMul	= 0.8

local function AbilitiesUpUtilityFn()
	local val = 0
	
	if skills.abilSilence:CanActivate() then
		val = val + object.nSilenceUpBonus
	end
	
	if skills.abilFeast:CanActivate() then
		val = val + object.nFeastUpBonus
	end
	
	if skills.abilHemorrhage:CanActivate() then
		val = val + object.nHemorrhageUpBonus
	end

	if object.itemManaBurn1 and object.itemManaBurn1:CanActivate() then
		nUtility = nUtility + object.nManaBurn1Up
	end
	
	return val
	
end

function object:oncombateventOverride(EventData)
self:oncombateventOld(EventData)

	local addBonus = 0
	if EventData.Type == "Ability" then	
	
		if EventData.InflictorName == "Ability_Hunter1" then
			addBonus = addBonus + object.nSilenceUse
		end
	
		if EventData.InflictorName == "Ability_Hunter2" then
			addBonus = addBonus + object.nFeastUse
		end

		if EventData.InflictorName == "Ability_Hunter4" then
			addBonus = addBonus + object.nHemorrhageUse
		end	
	
	elseif EventData.Type == "Item" then
		if core.itemManaBurn1 ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemManaBurn1:GetName() then
			nAddBonus = nAddBonus + object.nManaBurn1Use
		end
	end

	if addBonus > 0 then
	
	--decay before we add
	core.DecayBonus(self)
	core.nHarassBonus = core.nHarassBonus + addBonus
	
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

----------------------------------
-- harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = false
	
	local unitTarget = behaviorLib.heroTarget --All hero-class enemies (either player or bots)
	
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behaviour
	end

	local unitSelf = core.unitSelf 
	
	local vecMyPosition = unitSelf:GetPosition()
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	
	local bActionTaken = false
	
	local abilSilence = skills.abilSilence
	local abilHemorrhage = skills.abilHemorrhage
	local SilenceLvl = abilSilence:GetLevel()	
	
	--Item Declares--
	local itemCodex = core.GetItem ("Item_Nuke")
	local itemNullBlade = core.GetItem ("Item_ManaBurn1")
	
	local nIsSighted = core.CanSeeUnit(botBrain, unitTarget)
	
	--Effective Hit Point Calculation--
	local GetHealthE = unitTarget:GetHealth()
	local MagicResist = unitTarget:GetMagicResistance()
	local nEffectiveHP = 0
	if nIsSighted then
		nEffectiveHP = ((MagicResist + 1) * GetHealthE)
	end
	
	-- Silence B -Hostile-
	if abilSilence:CanActivate() and nIsSighted then --Cast Silence if
		local nRange = abilSilence:GetRange()
		if nTargetDistanceSq < (nRange * nRange) then -- target is in range and
			if (nLastHarassUtility > botBrain.nSilenceThreshold) then -- ability passes threshold
				bActionTaken = core.OrderAbilityEntity(botBrain, abilSilence, unitTarget)
			elseif nEffectiveHP < 300 then -- or there is a hero near death
				bActionTaken = core.OrderAbilityEntity(botBrain, abilSilence, unitTarget)
			elseif (unitSelf:GetManaPercent() > .80) and (SilenceLvl < 3) then --If BH has mana and the ability will not give a large attack bonus
				bActionTaken = core.OrderAbilityEntity(botBrain, abilSilence, unitTarget)
			end
		end
	end
	
	--Hemorrhage
	if not bActionTaken and abilHemorrhage:CanActivate() and nIsSighted then -- Cast Hermorrhage if
		local nRange = abilHemorrhage:GetRange()
		if nTargetDistanceSq < (nRange * nRange) then
			if (nLastHarassUtility > botBrain.nHemorrhageThreshold) then -- target is in close range and ability threshold
				bActionTaken = core.OrderAbilityEntity(botBrain, abilHemorrhage, unitTarget)
			elseif (nEffectiveHP < 350) then -- or ability would kill a hero
				bActionTaken = core.OrderAbilityEntity(botBrain, abilHemorrhage, unitTarget)
			end
		end
	end

	--codex
	if not bActionTaken and itemCodex and core.nDifficulty ~= core.nEASY_DIFFICULTY then --Difficulty modifier taken from Parasite Bot made by Mellow_Ink and Kairus101
		if nIsSighted and itemCodex:CanActivate() then -- Cast Codex if
			local nRange = itemCodex:GetRange()
			local nCodexDamage = ((itemCodex:GetLevel() * 100) + 300)
			if nTargetDistanceSq < (nRange * nRange) then --Codex selected and Target is in range and 
				if (core.NumberElements(tLocalEnemyHeroes) > 2) and (core.NumberElements(tLocalAllyHeroes) > 2) then -- Cast in a team fight (more than 2 enemy and 2 ally heroes)
					bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemCodex, unitTarget)
				elseif (nEffectiveHP < nCodexDamage * 1.75) and (nEffectiveHP > nCodexDamage) then -- Casting will wound the target, but not kill it
					bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemCodex, unitTarget)
				end
			end
		end
	end
	
	-- Silence A -Helpful-
	if  not bActionTaken and itemNullBlade then --If BH has Nullfire blade
		local nRange = itemNullBlade:GetRange()
		local nInRange = nTargetDistanceSq < (nRange * nRange)
		if abilSilence:CanActivate() and (SilenceLvl > 2) and itemNullBlade:CanActivate() then --  Silence can activate and has Nullfire to remove debuff and will provide a decent buff
			if (unitSelf:GetHealthPercent() > .25) then -- Or BH is in fighting order with more damage then 
				bActionTaken = core.OrderAbilityEntity(botBrain, abilSilence, unitSelf) -- Cast Silence on self 
			end
		elseif itemNullBlade:CanActivate() then
			if unitSelf:HasState(State_Hunter_Ability1_Buff) then -- Verifies there is a debuff on BH
				bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemNullBlade, unitSelf) -- Purges the silence debuff
			end
		elseif nInRange and (nLastHarassUtility > botBrain.nManaBurn1Threshold) then --Enemy is in range and nullfire passes threshold check
				bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemNullBlade, unitTarget) --Casts Nullfire blade on enemy.
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

--------------------------
--Feast Function Pieces --
--------------------------

local function feastingActionsUtility(botBrain)

	local abilFeast = skills.abilFeast	
	local unitSelf = core.unitSelf 	
	
	--If blood hunter is severely wounded, or has access mana and is mildly wounded...
	if abilFeast:CanActivate() and ((unitSelf:GetHealthPercent() < .35) or (unitSelf:GetManaPercent() > .75  and unitSelf:GetHealthPercent() < .85)) and unitSelf:IsAlive() then
		return 25 --Run feastingActionsExecute
	end
	
	return 0
end

local function feastingActionsExecute(botBrain)

	local unitSelf = core.unitSelf
	local unitFeastTarget = nil --Setting up target for feasting
	local unitECreep = core.localUnits["EnemyCreeps"]
	
	local abilFeast = skills.abilFeast	
	
	local bActionTaken = false
	
	if unitECreep then --If there are local enemy creeps,
	
		local nBestTargetHealth = unitSelf:GetHealth()/5
	
		for _, unitTarget in pairs(unitECreep) do --looks for the highest health creep to feast on!
			local targetHealth = unitTarget:GetMaxHealth() 
			if targetHealth > nBestTargetHealth and unitTarget:IsAlive() then 
				unitFeastTarget = unitTarget
				nBestTargetHealth = targetHealth
			end
		end
		
		-- Our good ol' "27 B-Stroke 6"
		if unitFeastTarget then --If the unit is a feast target has been chosen
		
			local vecMyPosition = unitSelf:GetPosition() --BH's position
			local vecTargetPosition = unitFeastTarget:GetPosition() --FeastTarget's position
			local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition) --Distance between BH and FeastTarget
			local nRange = abilFeast:GetRange()
			
			if nTargetDistanceSq < (nRange * nRange) then --If the target creep is in range |Error = function arguments expected 
			
				bActionTaken = core.OrderAbilityEntity(botBrain, abilFeast, unitFeastTarget, false) --consume the best creep
				
			elseif nTargetDistanceSq > (nRange * nRange) then --If the creep is not in range, get in range
			
				bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, vecTargetPosition, false) --Command to move towards the targeted creep
				
			end
		end
	end
	
	return bActionTaken
	
end
	
--Setting up behaviour
behaviorLib.feastingBehavior = {} --creation of 'feast' behaviour library
behaviorLib.feastingBehavior["Utility"] = feastingActionsUtility --connecting the utility function to the behaviour (when it will act)
behaviorLib.feastingBehavior["Execute"] = feastingActionsExecute --connecting the execute function to the behaviour (what to do when acting)
behaviorLib.feastingBehavior["Name"] = "feast" --dictating the name of the behaviour
tinsert(behaviorLib.tBehaviors, behaviorLib.feastingBehavior) --instantiation of the behaviour/letting it roam

----------------------------------------------------
--  	   Heal At Well Override		  --
----------------------------------------------------
--2000 gold adds 6 to return utility, slightly reduced need to return.
--Modified from kairus101's BalphBot!
local function HealAtWellUtilityOverride(botBrain)
	local vecBackupPos = core.allyWell and core.allyWell:GetPosition() or behaviorLib.PositionSelfBackUp()

	local nGoldSpendingDesire = 6 / 2000
	
	if (Vector3.Distance2DSq(core.unitSelf:GetPosition(), vecBackupPos) < 400 * 400 and core.unitSelf:GetManaPercent() * 100 < 95) then
		return 80
	end
	return object.HealAtWellUtilityOld(botBrain) + (botBrain:GetGold() * nGoldSpendingDesire) --courageously flee back to base.
end
object.HealAtWellUtilityOld = behaviorLib.HealAtWellBehavior["Utility"]
behaviorLib.HealAtWellBehavior["Utility"] = HealAtWellUtilityOverride

----------------------------------------
--- Extras
----------------------------------------
--[[ colors:
red
aqua == cyan
gray
navy
teal
blue
lime
black
brown
green
olive
orange
white
silver
purple
grape
maroon
yellow
orange
fuchsia == magenta
invisible
--]]

BotEcho('Finished loading Blood Hunter...')
