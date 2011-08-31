function shaman_resto_pvp(self)
	local mana = UnitMana("player")/UnitManaMax("player")
	local lotsOfMana = mana > 0.7
	local hostileTarget = UnitIsEnemy("player","target")
	local focus = "focus"
	local me = "player"
	local friendlies = {}
	local desperateFunction = function(unit) return jps.hp(unit) < 0.2 end

	-- Populate friendlies
	for name, _ in pairs(jps.RaidStatus) do table.insert( friendlies, name ) end

	-- Totems
	local _, fireName, _, _, _ = GetTotemInfo(1)
	local _, earthName, _, _, _ = GetTotemInfo(2)
	local _, waterName, _, _, _ = GetTotemInfo(3)
	local _, airName, _, _, _ = GetTotemInfo(4)

	local haveFireTotem = fireName ~= ""
	local haveEarthTotem = earthName ~= ""
	local haveWaterTotem = waterName ~= ""
	local haveAirTotem = airName ~= ""

	-- Miscellaneous
	local feared = jps.debuff("fear","player") or jps.debuff("intimidating shout","player") or jps.debuff("howl of terror","player") or jps.debuff("psychic scream","player")
	local enemyPurgeSpells = {"predator's swiftness","avenging wrath","innervate"}
	local friendlyDispels = {"frost nova","fear","psychic scream","freeze","deep freeze","howl of terror","counterspell","hex","entangling roots"}
	local dontDispel = not hostileTarget and jps.debuff("unstable affliction") or jps.debuff("vampiric touch")
	local buffToPurge = false
	local focusBuffToPurge = false
	local debuffToDispel = false

	-- Check to purge target/focus
	for _, buff in pairs(enemyPurgeSpells) do 
		if jps.buff(buff,"target") then buffToPurge = true end
		if jps.buff(buff,"focus") then focusBuffToPurge = true end
	end
	
	-- dispelFunction
	local function dispelFunction(unit) 
		for _,debuff in pairs(friendlyDispels) do 
			if jps.debuff(debuff,unit) then
				return true
			else
				return false end
		end
	end 

	-- Priority Table
	local spellTable = {
			-- If I'm ghost-wolfing around I'm probably running around, so don't pop out to heal till I say.
			{ nil,						jps.buff("ghost wolf") },

			-- Break fear.
			{ "tremor totem",			feared },

			-- Some defensive CDs.
			{ "stoneclaw totem",		jps.hp() < 0.55 },
			{ jps.defRacial,			jps.hp() < 0.6 or (jps.defRacial == "stoneform" and jps.debuff("rip","player")) },

			-- Heal anyone really desperate.
			{ "nature's swiftness",		desperateFunction, friendlies },
			{ "greater healing wave",	desperateFunction, friendlies, jps.LastCast == "nature's swiftness" },
			{ "riptide",				desperateFunction, friendlies },
			{ "unleash elements",		desperateFunction, friendlies },
			{ "greater healing wave",	desperateFunction, friendlies, jps.buff("tidal waves") },

			-- Earth shield (I manually put it on other people)
			{ "earth shield",			jps.hp() < 0.5 and not jps.buff("earth shield"), me },

			-- Heals (prioritize myself)
			{ "riptide",				jps.hp() < 0.8, me },
			{ "riptide",				function (unit) return jps.hp(unit) < 0.8 end, friendlies },

			{ "unleash elements",		jps.hp() < 0.8, me },
			{ "unleash elements",		function (unit) return jps.hp(unit) < 0.8 end, friendlies },

			{ "greater healing wave",	jps.hp() < 0.5 and jps.buff("tidal waves"), me },
			{ "healing surge",			jps.hp() < 0.5, me },

			{ "greater healing wave",	function (unit) return jps.hp(unit) < 0.5 end, friendlies, jps.buff("tidal waves") },
			{ "healing surge",			function (unit) return jps.hp(unit) < 0.5 end, friendlies },

			{ "healing wave",			jps.hp() < 0.75 and jps.buff("tidal waves") and mana < 0.6, me },
			{ "greater healing wave",	jps.hp() < 0.75 and jps.buff("tidal waves"), me },

			{ "greater healing wave",	function (unit) return jps.hp(unit) < 0.85 end, friendlies, jps.buff("tidal waves") },

			{ "healing wave",			jps.hp() < 0.97 and jps.buff("tidal waves"), me },
			{ "healing wave",			function (unit) return jps.hp(unit) < 0.97 end, friendlies },

			-- Kick.
			{ "wind shear",				jps.shouldKick(focus), focus },
			{ "wind shear",				hostileTarget and jps.shouldKick(target) },

			-- Dispels.
			{ "purge",					hostileTarget and buffToPurge and lotsOfMana },
			{ "purge",					focusBuffToPurge and lotsOfMana, focus },
			{ "cleanse spirit",			dispelFunction, friendlies, lotsOfMana },

			-- Hex.
			{ "hex",					"onCD", focus },

			-- Totems.
			{ "call of the elements",	not haveWaterTotem and not haveFireTotem and not haveEarthTotem and not haveAirTotem },
			{ "healing stream totem",	not haveWaterTotem and mana > 0.5 },
			{ "mana spring totem",		mana < 0.5 and (not haveWaterTotem or waterName == "healing stream totem") },
			{ "water shield",			not jps.buff("water shield") and not jps.buff("earth shield") },
			{ "wrath of air totem",		not haveAirTotem },
			{ "stoneskin totem",		not haveEarthTotem },
	}

	local spell,target = parseSpellTable(spellTable)
	jps.Target = target
	return spell
end