local requirement_mult = settings.startup["tech-crafting-requirement-multiplier"].value or 1.0

function update_tech(name, prerequisites, trigger)
	local tech = data.raw.technology[name]
	if tech then
		if prerequisites ~= nil then
			tech.prerequisites = {}
			for _,prereq in pairs(prerequisites) do
				table.insert(tech.prerequisites, prereq)
			end
		elseif string.find(name, "science") == nil then
			local new_prerequisites = {}
			for _, prereq in ipairs(tech.prerequisites) do
				if string.find(prereq, "science") == nil then
					table.insert(new_prerequisites, prereq)
				end
			end
			tech.prerequisites = new_prerequisites
		end
		tech.unit = nil
		tech.research_trigger = trigger
		if trigger.type == "craft-item" then
			tech.research_trigger.count = math.ceil(math.max(tech.research_trigger.count * requirement_mult, 1))
		end
		if trigger.type == "craft-fluid" then
			tech.research_trigger.amount = math.ceil(math.max(tech.research_trigger.amount * requirement_mult, 1))
		end
	end
end

function update_tech_unit(name, prerequisites, unit)
	local tech = data.raw.technology[name]
	if tech then
		if prerequisites then tech.prerequisites = prerequisites end
		if unit.count then tech.unit.count = unit.count end
		if unit.count_formula then tech.unit.count_formula = unit.count_formula end
		if unit.time then tech.unit.time = unit.time end
		if unit.ingredients then tech.unit.ingredients = unit.ingredients end
	end
end

function merge_tech(source, destination)
	local src_tech = data.raw.technology[source]
	local dst_tech = data.raw.technology[destination]
	if src_tech == nil or dst_tech == nil then return end
	
	for _name, _tech in pairs(data.raw.technology) do
		if _tech.prerequisites then
			local already_in_list = false
			for i = 1, #_tech.prerequisites do
				if _tech.prerequisites[i] == destination then
					already_in_list = true
					break
				end
			end
			if not already_in_list then
				for i = 1, #_tech.prerequisites do
					if _tech.prerequisites[i] == source then
						_tech.prerequisites[i] = destination
					end
				end
			end
		end
	end
	-- Not part of the lua version factorio is using.
	-- table.move(src_tech.effects, 1, #src_tech.effects, #dst_tech.effects + 1, dst_tech.effects)
	if src_tech.effects ~= nil then
		if dst_tech.effects == nil then dst_tech.effects = {} end
		local start = #dst_tech.effects
		local skipped = 0
		for i = 1, #src_tech.effects do
			for _, effect in pairs(dst_tech.effects) do
				if effect.type == "unlock-recipe" then
					if src_tech.effects[i + skipped] and (effect.recipe == src_tech.effects[i + skipped].recipe) then
						skipped = skipped + 1
					end
				end
			end
			dst_tech.effects[start + i] = src_tech.effects[i + skipped]
		end
	end
	src_tech.enabled = false
	src_tech.visible_when_disabled = false
end

function add_prerequisite(name, prereq)
	local tech = data.raw.technology[name]
	if tech and data.raw.technology[prereq] then
		for _, req in pairs(tech.prerequisites) do
			if req == prereq then
				return
			end
		end
		if tech.prerequisites then
			table.insert(tech.prerequisites, prereq)
		else
			tech.prerequisites = {prereq}
		end
	end
end

function remove_prerequisite(name, prereq)
	local tech = data.raw.technology[name]
	if tech and data.raw.technology[prereq] then
		local new_prerequisites = {}
		for _, req in pairs(tech.prerequisites) do
			if req ~= prereq then
				table.insert(new_prerequisites, req)
			end
		end
		tech.prerequisites = new_prerequisites
	end
end

function mark_as_essential(name)
	local tech = data.raw.technology[name]
	if tech then
		tech.essential = true
	end
end

function replace_science_packs(src, dst)
	for _name, _tech in pairs(data.raw.technology) do
		if _tech.unit and _tech.unit.ingredients and #_tech.unit.ingredients == #src then
			local matching_ingredients = 0
			for i = 1, #src do
				if _tech.unit.ingredients[i][1] == src[i] then
					matching_ingredients = matching_ingredients + 1
				end
			end
			if matching_ingredients == #src then
				_tech.unit.ingredients = table.deepcopy(dst)
			end
		end
	end
end

function remove_base_science_packs(src)
	for _name, _tech in pairs(data.raw.technology) do
		if _tech.unit and _tech.unit.ingredients then
			local matching_ingredients = 0
			for i = 1, #_tech.unit.ingredients do
				if _tech.unit.ingredients[i][1] == src[i] then
					matching_ingredients = matching_ingredients + 1
				else
					break
				end
			end
			matching_ingredients = math.min(matching_ingredients, #_tech.unit.ingredients - 1)
			for i = 1, #_tech.unit.ingredients do
				_tech.unit.ingredients[i] = _tech.unit.ingredients[matching_ingredients + i]
			end
		end
	end
end

remove_base_science_packs({"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "production-science-pack", "utility-science-pack", "space-science-pack"})
--replace_science_packs({"military-science-pack", "space-science-pack", "agricultural-science-pack"}, {{"military-science-pack", 1}, {"agricultural-science-pack", 1}})

update_tech("steam-power", {}, {type="craft-item", item="iron-plate", count=500})
update_tech("electronics", {}, {type="craft-item", item="copper-plate", count=500})

update_tech("logistics-basic", {"electronics"}, {type="craft-item", item="basic-transport-belt", count=500})
update_tech("logistics", {"automation","logistics-basic"}, {type="craft-item", item="basic-transport-belt", count=5000})
update_tech("logistics-2", {"automation-2","logistics"}, {type="craft-item", item="transport-belt", count=5000})
update_tech("logistics-3", {"logistics-2","advanced-circuit"}, {type="craft-item", item="fast-transport-belt", count=5000})
update_tech("logistics-4", {"logistics-3"}, {type="craft-item", item="express-transport-belt", count=5000})
update_tech("logistics-5", {"logistics-4","processing-unit"}, {type="craft-item", item="turbo-transport-belt", count=5000})

update_tech("loaders-basic", {"logistics-basic"}, {type="craft-item", item="basic-transport-belt", count=1000})
update_tech("loaders", {"loaders-basic"}, {type="craft-item", item="transport-belt", count=1000})
update_tech("loaders-2", {"loaders"}, {type="craft-item", item="fast-transport-belt", count=1000})
update_tech("loaders-3", {"loaders-2"}, {type="craft-item", item="express-transport-belt", count=1000})
update_tech("loaders-4", {"loaders-3"}, {type="craft-item", item="turbo-transport-belt", count=1000})
update_tech("loaders-5", {"loaders-4"}, {type="craft-item", item="supersonic-transport-belt", count=1000})

update_tech("automation", {"steam-power"}, {type="craft-item", item="iron-gear-wheel", count=500})
update_tech("automation-2", {"automation"}, {type="craft-item", item="assembling-machine-1", count=500})
update_tech("automation-3", {"speed-module","automation-2"}, {type="craft-item", item="assembling-machine-2", count=500})

update_tech("fast-inserter", {"automation","electronics"}, {type="craft-item", item="inserter", count=1000})
update_tech("bulk-inserter", {"fast-inserter"}, {type="craft-item", item="fast-inserter", count=1000})

update_tech("repair-pack", {"automation"}, {type="craft-item", item="iron-gear-wheel", count=1000})

update_tech("electric-mining-drill", {"automation"}, {type="craft-item", item="burner-mining-drill", count=100})

update_tech("stone-wall", {}, {type="craft-item", item="stone-brick", count=1000})
update_tech("gate", {"stone-wall"}, {type="craft-item", item="stone-wall", count=1000})

update_tech("sawmills", {"electronics"}, {type="craft-item", item="small-electric-pole", count=100})

update_tech("basic-electric-energy-distribution", {"electronics"}, {type="craft-item", item="small-electric-pole", count=200})
update_tech("electric-energy-distribution-1", {"basic-electric-energy-distribution"}, {type="craft-item", item="medium-wooden-electric-pole", count=200})
update_tech("electric-energy-distribution-2", {"electric-energy-distribution-1"}, {type="craft-item", item="medium-electric-pole", count=500})
update_tech("electric-energy-distribution-3", {"electric-energy-distribution-2"}, {type="craft-item", item="substation", count=500})

update_tech("lamp", {"glass-processing","electronics"}, {type="craft-item", item="glass-plate", count=500})
update_tech("lighting", {"lamp","steel-processing"}, {type="craft-item", item="small-lamp", count=500})
update_tech("floor-lamp", {"lighting","landfill"}, {type="craft-item", item="small-lamp", count=1000})

update_tech("steel-processing", {"steam-power"}, {type="craft-item", item="iron-plate", count=5000})

update_tech("military", {"steam-power"}, {type="craft-item", item="firearm-magazine", count=200})
update_tech("military-2", {"military","steel-processing"}, {type="craft-item", item="firearm-magazine", count=2000})
update_tech("military-3", {"military-2","stone-wall"}, {type="craft-item", item="piercing-rounds-magazine", count=2000})
update_tech("military-4", {"military-3","explosives"}, {type="craft-item", item="longrange-rounds-magazine", count=2000})
update_tech("military-5", {"military-4","low-density-structure"}, {type="craft-item", item="sniper-shell", count=2000})
update_tech("military-6", {"military-5"}, {type="craft-item", item="rocket", count=2000})

update_tech("gun-turret", {"military"}, {type="craft-item", item="firearm-magazine", count=500})
update_tech("heavy-gun-turrets", {"military-3"}, {type="craft-item", item="longrange-rounds-magazine", count=500})
update_tech("flamethrower", {"flammables"}, {type="craft-fluid", fluid="crude-oil", amount=100000})
update_tech("refined-flammables-1", {"flamethrower"}, {type="craft-item", item="flamethrower-turret", count=200})
update_tech("refined-flammables-2", {"refined-flammables-1"}, {type="craft-fluid", fluid="crude-oil", amount=200000})
update_tech("refined-flammables-3", {"refined-flammables-2"}, {type="craft-fluid", fluid="crude-oil", amount=400000})
update_tech("refined-flammables-4", {"refined-flammables-3"}, {type="craft-fluid", fluid="crude-oil", amount=800000})
update_tech("refined-flammables-5", {"refined-flammables-4"}, {type="craft-fluid", fluid="crude-oil", amount=1600000})
update_tech("refined-flammables-6", {"refined-flammables-5"}, {type="craft-fluid", fluid="crude-oil", amount=3200000})
update_tech("refined-flammables-7", {"refined-flammables-6"}, {type="craft-fluid", fluid="crude-oil", amount=6400000})
update_tech("rocket-turret", {"rocketry"}, {type="craft-item", item="rocket", count=500})
update_tech("sniper-turrets", {"military-4"}, {type="craft-item", item="sniper-shell", count=500})
update_tech("mortar-turret", {"military-4"}, {type="craft-item", item="grenade-rounds", count=500})
update_tech("cannons", {"military-4"}, {type="craft-item", item="explosives", count=2000})
update_tech("laser-turret", {"laser"}, {type="craft-item", item="laser", count=500})
update_tech("chaingun-turrets", {"military-5"}, {type="craft-item", item="chaingun-ammo", count=500})
update_tech("artillery", {"explosive-ammo-3","concrete","radar"}, {type="craft-item", item="explosive-cannon-shell", count=2000})

update_tech("heavy-armor", {"steel-processing","military"}, {type="craft-item", item="firearm-magazine", count=1000})
update_tech("modular-armor", {"heavy-armor","military-2"}, {type="craft-item", item="piercing-rounds-magazine", count=1000})
update_tech("power-armor", {"modular-armor","military-3"}, {type="craft-item", item="longrange-rounds-magazine", count=1000})
update_tech("power-armor-mk2", {"power-armor","military-4"}, {type="craft-item", item="sniper-shell", count=1000})

update_tech("physical-projectile-damage-1", {"military"}, {type="craft-item", item="firearm-magazine", count=10000})
update_tech("physical-projectile-damage-2", {"military","physical-projectile-damage-1"}, {type="craft-item", item="firearm-magazine", count=20000})
update_tech("physical-projectile-damage-3", {"military-2","physical-projectile-damage-2"}, {type="craft-item", item="piercing-rounds-magazine", count=10000})
update_tech("physical-projectile-damage-4", {"military-2","physical-projectile-damage-3"}, {type="craft-item", item="piercing-rounds-magazine", count=20000})
update_tech("physical-projectile-damage-5", {"military-3","physical-projectile-damage-4"}, {type="craft-item", item="longrange-rounds-magazine", count=10000})
update_tech("physical-projectile-damage-6", {"military-3","physical-projectile-damage-5"}, {type="craft-item", item="longrange-rounds-magazine", count=20000})
update_tech("physical-projectile-damage-7", {"military-4","physical-projectile-damage-6"}, {type="craft-item", item="sniper-shell", count=10000})


update_tech("weapon-shooting-speed-1", {"military"}, {type="craft-item", item="firearm-magazine", count=2500})
update_tech("weapon-shooting-speed-2", {"military","weapon-shooting-speed-1"}, {type="craft-item", item="firearm-magazine", count=5000})
update_tech("weapon-shooting-speed-3", {"military-2","weapon-shooting-speed-2"}, {type="craft-item", item="piercing-rounds-magazine", count=2500})
update_tech("weapon-shooting-speed-4", {"military-2","weapon-shooting-speed-3"}, {type="craft-item", item="piercing-rounds-magazine", count=5000})
update_tech("weapon-shooting-speed-5", {"military-3","weapon-shooting-speed-4"}, {type="craft-item", item="longrange-rounds-magazine", count=2500})
update_tech("weapon-shooting-speed-6", {"military-3","weapon-shooting-speed-5"}, {type="craft-item", item="longrange-rounds-magazine", count=5000})
update_tech("weapon-shooting-speed-7", {"military-4","weapon-shooting-speed-6"}, {type="craft-item", item="sniper-shell", count=2500})

update_tech("engine", {"logistics","steel-processing"}, {type="craft-item", item="iron-gear-wheel", count=5000})
update_tech("fluid-handling", {"engine","automation-2"}, {type="craft-item", item="pipe", count=5000})
update_tech("oil-gathering", {"fluid-handling"}, {type="craft-item", item="pump", count=500})
update_tech("gas-extraction", {"fluid-handling"}, {type="craft-item", item="pump", count=200})
update_tech("steam-turbines", {"gas-extraction","lubricant"}, {type="craft-item", item="steam-engine", count=500})
update_tech("steam-powered-mining", {"steam-turbines","mining-productivity-2"}, {type="craft-item", item="steam-turbine", count=500})
update_tech("flammables", {"oil-processing"}, {type="craft-fluid", fluid="petroleum-gas", amount=100000})
update_tech("plastics", {"oil-processing"}, {type="craft-fluid", fluid="petroleum-gas", amount=25000})
update_tech("sulfur-processing", {"oil-processing"}, {type="craft-fluid", fluid="petroleum-gas", amount=50000})
update_tech("explosives", {"sulfur-processing"}, {type="craft-item", item="sulfur", count=1000})
update_tech("solar-energy", {"glass-processing","steel-processing"}, {type="craft-item", item="glass-plate", count=5000})
update_tech("solar-energy-2", {"solar-energy","advanced-circuit"}, {type="craft-item", item="solar-panel", count=1000})
update_tech("solar-energy-3", {"solar-energy-2","processing-unit"}, {type="craft-item", item="solar-array", count=1000})
update_tech("solar-train", {"solar-energy","electric-energy-accumulators","railway"}, {type="craft-item", item="solar-panel", count=200})
update_tech("radar", {"military","electronics"}, {type="craft-item", item="listening-post", count=100})
update_tech("advanced-radar-tech", {"robotics","military-4","radar"}, {type="craft-item", item="radar", count=200})
update_tech("landfill", {}, {type="craft-item", item="stone", count=10000})

update_tech("advanced-circuit", {"electronics","plastics"}, {type="craft-item", item="electronic-circuit", count=50000})
update_tech("processing-unit", {"advanced-circuit","sulfur-processing"}, {type="craft-item", item="advanced-circuit", count=25000})
update_tech("computing-units", {"productivity-module","advanced-material-processing-2","processing-unit"}, {type="craft-item", item="processing-unit", count=10000})

update_tech("modules", {"advanced-circuit"}, {type="craft-item", item="advanced-circuit", count=500})
update_tech("efficiency-module", {"modules"}, {type="craft-item", item="advanced-circuit", count=1000})
update_tech("efficiency-module-2", {"efficiency-module","processing-unit"}, {type="craft-item", item="efficiency-module", count=2000})
update_tech("efficiency-module-3", {"efficiency-module-2"}, {type="craft-item", item="efficiency-module-2", count=1000})
update_tech("efficiency-module-4", {"efficiency-module-3","computing-units"}, {type="craft-item", item="efficiency-module-3", count=500})

update_tech("productivity-module", {"modules"}, {type="craft-item", item="advanced-circuit", count=1000})
update_tech("productivity-module-2", {"productivity-module","processing-unit"}, {type="craft-item", item="productivity-module", count=2000})
update_tech("productivity-module-3", {"productivity-module-2"}, {type="craft-item", item="productivity-module-2", count=1000})
update_tech("productivity-module-4", {"productivity-module-3","computing-units"}, {type="craft-item", item="productivity-module-3", count=500})

update_tech("speed-module", {"modules"}, {type="craft-item", item="advanced-circuit", count=1000})
update_tech("speed-module-2", {"speed-module","processing-unit"}, {type="craft-item", item="speed-module", count=2000})
update_tech("speed-module-3", {"speed-module-2"}, {type="craft-item", item="speed-module-2", count=1000})
update_tech("speed-module-4", {"speed-module-3","computing-units"}, {type="craft-item", item="speed-module-3", count=500})

update_tech("circuit-network", {"automation-2"}, {type="craft-item", item="electronic-circuit", count=2000})
update_tech("selector-combinator", {"circuit-network","advanced-circuit"}, {type="craft-item", item="decider-combinator", count=500})
update_tech("advanced-combinators", {"circuit-network","advanced-circuit"}, {type="craft-item", item="decider-combinator", count=500})

update_tech("advanced-material-processing", {"steel-processing","automation-2"}, {type="craft-item", item="steel-plate", count=2000})
update_tech("advanced-material-processing-2", {"advanced-material-processing","automation-3"}, {type="craft-item", item="steel-furnace", count=500})
update_tech("mass-smelting-1", {"flammables"}, {type="craft-item", item="stone-furnace", count=500})
update_tech("mass-smelting-2", {"advanced-material-processing","automation-2"}, {type="craft-item", item="steel-furnace", count=1000})
update_tech("mass-smelting-3", {"advanced-material-processing-2","concrete","speed-module-2","productivity-module-2"}, {type="craft-item", item="electric-furnace", count=1000})
update_tech("basic-electric-furnace", {"advanced-material-processing","electric-energy-distribution-1"}, {type="craft-item", item="steel-furnace", count=200})

update_tech("concrete", {"advanced-material-processing"}, {type="craft-item", item="stone-brick", count=5000})
update_tech("tarmac", {"concrete","advanced-oil-processing"}, {type="craft-item", item="concrete", count=5000})
update_tech("low-density-structure", {"advanced-material-processing","advanced-circuit"}, {type="craft-item", item="aluminium-plate", count=5000})

update_tech("storage-1", {"advanced-material-processing"}, {type="craft-item", item="steel-chest", count=500})
update_tech("storage-2", {"storage-1","concrete"}, {type="craft-item", item="storage-hut", count=200})
update_tech("storage-3", {"storage-1","logistic-robotics"}, {type="craft-item", item="logistic-robot", count=500})
update_tech("storage-4", {"storage-2","logistic-robotics"}, {type="craft-item", item="logistic-robot", count=1000})
update_tech("storage-5", {"storage-3","logistic-system"}, {type="craft-item", item="logistic-robot", count=2000})
update_tech("storage-6", {"storage-4","logistic-system"}, {type="craft-item", item="logistic-robot", count=4000})

update_tech("toolbelt", {"logistics"}, {type="craft-item", item="steel-chest", count=100})
update_tech("toolbelt-2", {"toolbelt","advanced-circuit"}, {type="craft-item", item="steel-chest", count=500})
update_tech("toolbelt-3", {"toolbelt-2","productivity-module"}, {type="craft-item", item="steel-chest", count=1000})
update_tech("toolbelt-4", {"toolbelt-3","processing-unit"}, {type="craft-item", item="steel-chest", count=2000})

update_tech("backpack-storage", {"toolbelt"}, {type="craft-item", item="steel-chest", count=200})

update_tech("upgraded-tools", {"toolbelt"}, {type="craft-item", item="steel-chest", count=250})
update_tech("advanced-repair-kits", {"upgraded-tools","advanced-circuit"}, {type="craft-item", item="repair-pack", count=1000})
update_tech("portable-drill", {"advanced-repair-kits","processing-unit"}, {type="craft-item", item="repair-pack", count=2000})
update_tech("power-tools-upgrade", {"portable-drill","automation-3"}, {type="craft-item", item="repair-pack", count=4000})
update_tech("super-power-tools-upgrade", {"power-tools-upgrade","rocket-silo"}, {type="craft-item", item="repair-pack", count=8000})

update_tech("automobilism-basic", {"steel-processing","logistics"}, {type="craft-item", item="steel-plate", count=200})
update_tech("automobilism", {"automobilism-basic","engine"}, {type="craft-item", item="engine-unit", count=500})
update_tech("automobilism-2", {"automobilism"}, {type="craft-item", item="engine-unit", count=1000})
update_tech("automobilism-3", {"automobilism-2","electric-engine","speed-module"}, {type="craft-item", item="engine-unit", count=2000})
update_tech("automobilism-military-1", {"automobilism","military-2"}, {type="craft-item", item="piercing-rounds-magazine", count=1000})
update_tech("automobilism-military-2", {"automobilism-2","military-3"}, {type="craft-item", item="longrange-rounds-magazine", count=1000})
update_tech("tank", {"automobilism","cannons"}, {type="craft-item", item="cannon-shell", count=500})
update_tech("railway", {"engine","logistics-2"}, {type="craft-item", item="engine-unit", count=1000})
update_tech("automated-rail-transportation", {"railway"}, {type="craft-item", item="rail", count=5000})
update_tech("fluid-wagon", {"fluid-handling","railway"}, {type="craft-item", item="storage-tank", count=100})
update_tech("equipment-wagon", {"railway","modular-armor"}, {type="craft-item", item="cargo-wagon", count=100})
update_tech("braking-force-1", {"railway"}, {type="craft-item", item="locomotive", count=50})
update_tech("braking-force-2", {"braking-force-1"}, {type="craft-item", item="locomotive", count=100})
update_tech("braking-force-3", {"braking-force-2","productivity-module"}, {type="craft-item", item="locomotive", count=150})
update_tech("braking-force-4", {"braking-force-3"}, {type="craft-item", item="locomotive", count=200})
update_tech("braking-force-5", {"braking-force-4"}, {type="craft-item", item="locomotive", count=250})
update_tech("braking-force-6", {"braking-force-5","processing-unit"}, {type="craft-item", item="locomotive", count=300})
update_tech("braking-force-7", {"braking-force-6"}, {type="craft-item", item="locomotive", count=400})


update_tech("explosive-ammo-1", {"explosives","military-2"}, {type="craft-item", item="explosives", count=1000})
update_tech("explosive-ammo-2", {"explosive-ammo-1"}, {type="craft-item", item="explosives", count=2000})
update_tech("explosive-ammo-3", {"explosive-ammo-2","tank"}, {type="craft-item", item="explosives", count=4000})

update_tech("uranium-ammo", {"tank","military-5","uranium-processing"}, {type="craft-item", item="uranium-238", count=1000})
update_tech("nuclear-ammo", {"uranium-ammo","kovarex-enrichment-process"}, {type="craft-item", item="uranium-235", count=1000})

update_tech("fish-processing", {"automation-2"}, {type="craft-item", item="cooked-fish", count=500})
update_tech("battery", {"sulfur-processing"}, {type="craft-item", item="sulfur", count=2000})
update_tech("electric-energy-accumulators", {"battery","electric-energy-distribution-1"}, {type="craft-item", item="battery", count=1000})
update_tech("electric-energy-accumulators-2", {"advanced-circuit","electric-energy-accumulators"}, {type="craft-item", item="accumulator", count=1000})
update_tech("electric-energy-accumulators-3", {"processing-unit","electric-energy-accumulators-2"}, {type="craft-item", item="accumulator-battery", count=500})

update_tech("laser", {"battery","advanced-circuit"}, {type="craft-item", item="battery", count=2000})
update_tech("laser-turret", {"laser"}, {type="craft-item", item="laser", count=200})
update_tech("large-laser-turrets", {"laser-turret","electric-energy-accumulators-2","military-5"}, {type="craft-item", item="laser", count=1000})

update_tech("laser-shooting-speed-1", {"laser"}, {type="craft-item", item="laser", count=1000})
update_tech("laser-shooting-speed-2", {"laser-shooting-speed-1"}, {type="craft-item", item="laser", count=2000})
update_tech("laser-shooting-speed-3", {"laser-shooting-speed-2"}, {type="craft-item", item="laser", count=3000})
update_tech("laser-shooting-speed-4", {"laser-shooting-speed-3"}, {type="craft-item", item="laser", count=4000})
update_tech("laser-shooting-speed-5", {"laser-shooting-speed-4","military-5"}, {type="craft-item", item="laser", count=5000})
update_tech("laser-shooting-speed-6", {"laser-shooting-speed-5"}, {type="craft-item", item="laser", count=6000})
update_tech("laser-shooting-speed-7", {"laser-shooting-speed-6"}, {type="craft-item", item="laser", count=7000})

update_tech("laser-weapons-damage-1", {"laser"}, {type="craft-item", item="laser", count=1500})
update_tech("laser-weapons-damage-2", {"laser-weapons-damage-1"}, {type="craft-item", item="laser", count=2500})
update_tech("laser-weapons-damage-3", {"laser-weapons-damage-2"}, {type="craft-item", item="laser", count=3500})
update_tech("laser-weapons-damage-4", {"laser-weapons-damage-3"}, {type="craft-item", item="laser", count=4500})
update_tech("laser-weapons-damage-5", {"laser-weapons-damage-4","military-5"}, {type="craft-item", item="laser", count=5500})
update_tech("laser-weapons-damage-6", {"laser-weapons-damage-5"}, {type="craft-item", item="laser", count=6500})
update_tech("laser-weapons-damage-7", {"laser-weapons-damage-6"}, {type="craft-item", item="laser", count=7500})

update_tech("cliff-explosives", {"explosives","military-2"}, {type="craft-item", item="explosives", count=10000})
update_tech("landfill-2", {"landfill","logistics-2","cliff-explosives"}, {type="craft-item", item="cliff-explosives", count=1000})

update_tech("miniturization", {"efficiency-module"}, {type="craft-item", item="assembling-machine-2", count=250})
update_tech("miniturization-2", {"miniturization","construction-robotics","advanced-material-processing"}, {type="craft-item", item="advanced-circuit", count=2000})
update_tech("fuel-generator-equipment", {"miniturization","advanced-oil-processing"}, {type="craft-item", item="assembling-machine-2", count=250})
update_tech("metal-pressing", {"efficiency-module-2","productivity-module-2","miniturization"}, {type="craft-item", item="stone", count=10000})
update_tech("compression-tech", {"metal-pressing","advanced-material-processing-2"}, {type="craft-item", item="stone", count=20000})

update_tech("lab", {"advanced-circuit","research-speed-2"}, {type="craft-item", item="basic-lab", count=100})
update_tech("advanced-lab", {"processing-unit","lab"}, {type="craft-item", item="lab", count=100})

update_tech("research-speed-1", {"automation-2"}, {type="craft-item", item="basic-lab", count=50})
update_tech("research-speed-2", {"research-speed-1"}, {type="craft-item", item="basic-lab", count=100})
update_tech("research-speed-3", {"research-speed-2","advanced-circuit"}, {type="craft-item", item="lab", count=100})
update_tech("research-speed-4", {"research-speed-3"}, {type="craft-item", item="lab", count=150})
update_tech("research-speed-5", {"research-speed-4","productivity-module"}, {type="craft-item", item="lab", count=200})
update_tech("research-speed-6", {"research-speed-5","processing-unit"}, {type="craft-item", item="lab-large", count=200})

update_tech("inserter-capacity-bonus-1", {"bulk-inserter"}, {type="craft-item", item="bulk-inserter", count=500})
update_tech("inserter-capacity-bonus-2", {"inserter-capacity-bonus-1"}, {type="craft-item", item="bulk-inserter", count=1000})
update_tech("inserter-capacity-bonus-3", {"inserter-capacity-bonus-2","advanced-circuit"}, {type="craft-item", item="bulk-inserter", count=1500})
update_tech("inserter-capacity-bonus-4", {"inserter-capacity-bonus-3","productivity-module"}, {type="craft-item", item="bulk-inserter", count=2000})
update_tech("inserter-capacity-bonus-5", {"inserter-capacity-bonus-4"}, {type="craft-item", item="bulk-inserter", count=2500})
update_tech("inserter-capacity-bonus-6", {"inserter-capacity-bonus-5"}, {type="craft-item", item="bulk-inserter", count=3000})
update_tech("inserter-capacity-bonus-7", {"inserter-capacity-bonus-6","processing-unit"}, {type="craft-item", item="bulk-inserter", count=4000})

update_tech("mining-productivity-1", {"advanced-circuit"}, {type="craft-item", item="iron-ore", count=1000000})
update_tech("mining-productivity-2", {"mining-productivity-1"}, {type="craft-item", item="copper-ore", count=1000000})
update_tech("mining-productivity-3", {"mining-productivity-2","productivity-module"}, {type="craft-item", item="stone", count=1000000})
update_tech("mining-productivity-4", {"mining-productivity-3","rocket-silo"}, {type="craft-item", item="uranium-ore", count=1000000})

update_tech("mining-grinders", {"mining-productivity-1","lubricant","productivity-module","speed-module"}, {type="craft-item", item="electric-mining-drill", count=1000})

update_tech("solar-panel-equipment", {"solar-energy","modular-armor"}, {type="craft-item", item="solar-panel", count=500})
update_tech("solar-panel-equipment-mk2", {"solar-energy-2","solar-panel-equipment","efficiency-module"}, {type="craft-item", item="solar-panel-equipment", count=500})

update_tech("battery-equipment", {"solar-panel-equipment","battery"}, {type="craft-item", item="battery", count=500})
update_tech("battery-mk2-equipment", {"battery-equipment","power-armor"}, {type="craft-item", item="battery-equipment", count=500})
update_tech("belt-immunity-equipment", {"solar-panel-equipment"}, {type="craft-item", item="express-transport-belt", count=500})
update_tech("discharge-defense-equipment", {"solar-panel-equipment","power-armor","laser-turret"}, {type="craft-item", item="laser-turret", count=500})
update_tech("energy-shield-equipment", {"solar-panel-equipment","military-3"}, {type="craft-item", item="solar-panel-equipment", count=200})
update_tech("energy-shield-mk2-equipment", {"energy-shield-equipment","power-armor","low-density-structure"}, {type="craft-item", item="energy-shield-equipment", count=200})
update_tech("exoskeleton-equipment", {"solar-panel-equipment","processing-unit","electric-engine"}, {type="craft-item", item="electric-engine-unit", count=500})
update_tech("night-vision-equipment", {"solar-panel-equipment"}, {type="craft-item", item="solar-panel-equipment", count=100})
update_tech("personal-laser-defense-equipment", {"solar-panel-equipment","power-armor","laser-turret","low-density-structure"}, {type="craft-item", item="laser", count=1000})
update_tech("personal-roboport-equipment", {"solar-panel-equipment","construction-robotics"}, {type="craft-item", item="construction-robot", count=500})
update_tech("personal-roboport-mk2-equipment", {"personal-roboport-equipment","processing-unit"}, {type="craft-item", item="personal-roboport-equipment", count=100})
update_tech("personal-roboport-mk3-equipment", {"personal-roboport-mk2-equipment","productivity-module"}, {type="craft-item", item="personal-roboport-mk2-equipment", count=100})


update_tech("advanced-oil-processing", {"advanced-circuit","sulfur-processing"}, {type="craft-fluid", fluid="petroleum-gas", amount=500000})
update_tech("coal-liquefaction", {"advanced-oil-processing","productivity-module"}, {type="craft-item", item="coal", count=1000000})
update_tech("lubricant", {"advanced-oil-processing"}, {type="craft-fluid", fluid="heavy-oil", amount=200000})
update_tech("electric-engine", {"lubricant"}, {type="craft-fluid", fluid="lubricant", amount=50000})
update_tech("advanced-pumping", {"electric-engine"}, {type="craft-item", item="offshore-pump", count=200})
update_tech("robotics", {"electric-engine","battery"}, {type="craft-item", item="electric-engine-unit", count=500})
update_tech("construction-robotics", {"robotics"}, {type="craft-item", item="flying-robot-frame", count=100})
update_tech("construction-robotics-2", {"construction-robotics","processing-unit","electric-energy-accumulators-2"}, {type="craft-item", item="roboport", count=500})
update_tech("logistic-robotics", {"robotics"}, {type="craft-item", item="flying-robot-frame", count=500})
update_tech("logistic-system", {"logistic-robotics","processing-unit","low-density-structure"}, {type="craft-item", item="logistic-robot", count=2000})
update_tech("worker-robots-speed-1", {"robotics"}, {type="craft-item", item="logistic-robot", count=1000})
update_tech("worker-robots-speed-2", {"worker-robots-speed-1"}, {type="craft-item", item="logistic-robot", count=1500})
update_tech("worker-robots-speed-3", {"worker-robots-speed-2","processing-unit"}, {type="craft-item", item="logistic-robot", count=2000})
update_tech("worker-robots-speed-4", {"worker-robots-speed-3"}, {type="craft-item", item="logistic-robot", count=2500})
update_tech("worker-robots-speed-5", {"worker-robots-speed-4","productivity-module"}, {type="craft-item", item="logistic-robot", count=3000})
update_tech("worker-robots-speed-6", {"worker-robots-speed-5","rocket-silo"}, {type="craft-item", item="logistic-robot", count=4000})
update_tech("worker-robots-storage-1", {"robotics"}, {type="craft-item", item="logistic-robot", count=1000})
update_tech("worker-robots-storage-2", {"worker-robots-storage-1","productivity-module"}, {type="craft-item", item="logistic-robot", count=2000})
update_tech("worker-robots-storage-3", {"worker-robots-storage-2","processing-unit"}, {type="craft-item", item="logistic-robot", count=4000})

update_tech("rocket-fuel", {"advanced-oil-processing","flammables"}, {type="craft-fluid", fluid="light-oil", amount=50000})
update_tech("true-rocket-fuel", {"rocket-fuel","explosives","processing-unit"}, {type="craft-item", item="rocket-fuel", count=1000})
update_tech("uranium-mining", {"sulfur-processing","concrete"}, {type="craft-fluid", fluid="sulfuric-acid", amount=50000})
update_tech("nuclear-power", {"steam-turbines","uranium-processing"}, {type="craft-item", item="uranium-ore", count=5000})
update_tech("heatpipe-furnace", {"nuclear-power","advanced-material-processing-2"}, {type="craft-item", item="electric-furnace", count=500})
update_tech("nuclear-fuel-reprocessing", {"nuclear-power","productivity-module"}, {type="craft-item", item="uranium-fuel-cell", count=500})
update_tech("fission-reactor-equipment", {"nuclear-power","power-armor","processing-unit"}, {type="craft-item", item="uranium-fuel-cell", count=1000})
update_tech("kovarex-enrichment-process", {"uranium-processing","rocket-fuel","productivity-module"}, {type="craft-item", item="uranium-235", count=100})
update_tech("atomic-bomb", {"kovarex-enrichment-process","military-4","rocketry"}, {type="craft-item", item="uranium-235", count=50000})

update_tech("rocketry", {"military-3","explosives","flammables"}, {type="craft-item", item="explosives", count=5000})
update_tech("land-mine", {"military-2","explosives"}, {type="craft-item", item="explosives", count=1000})
update_tech("stronger-explosives-1", {"military-2"}, {type="craft-item", item="grenade", count=500})
update_tech("stronger-explosives-2", {"stronger-explosives-1"}, {type="craft-item", item="land-mine", count=1000})
update_tech("stronger-explosives-3", {"stronger-explosives-2","advanced-circuit"}, {type="craft-item", item="rocket", count=1000})
update_tech("stronger-explosives-4", {"stronger-explosives-3","processing-unit"}, {type="craft-item", item="explosive-rocket", count=1000})
update_tech("stronger-explosives-5", {"stronger-explosives-4"}, {type="craft-item", item="cannon-shell", count=1000})
update_tech("stronger-explosives-6", {"stronger-explosives-5"}, {type="craft-item", item="explosive-cannon-shell", count=1000})
update_tech("stronger-explosives-7", {"stronger-explosives-6","rocket-silo"}, {type="craft-item", item="explosive-uranium-cannon-shell", count=1000})

update_tech("defender", {"military-2"}, {type="craft-item", item="piercing-rounds-magazine", count=500})
update_tech("distractor", {"laser","military-3","defender"}, {type="craft-item", item="defender-capsule", count=500})
update_tech("destroyer", {"distractor","military-4","speed-module"}, {type="craft-item", item="distractor-capsule", count=500})
update_tech("follower-robot-count-1", {"defender"}, {type="craft-item", item="defender-capsule", count=500})
update_tech("follower-robot-count-2", {"follower-robot-count-1"}, {type="craft-item", item="defender-capsule", count=1000})
update_tech("follower-robot-count-3", {"follower-robot-count-2","distractor"}, {type="craft-item", item="distractor-capsule", count=500})
update_tech("follower-robot-count-4", {"follower-robot-count-3"}, {type="craft-item", item="distractor-capsule", count=1000})
update_tech("follower-robot-count-5", {"follower-robot-count-4","destroyer"}, {type="craft-item", item="destroyer-capsule", count=500})
update_tech("follower-robot-count-6", {"follower-robot-count-5"}, {type="craft-item", item="destroyer-capsule", count=1000})
update_tech("follower-robot-count-7", {"follower-robot-count-6","rocket-silo"}, {type="craft-item", item="destroyer-capsule", count=2000})

update_tech("molotov", {"glass-processing","flammables"}, {type="craft-item", item="petroleum-fuel", count=2000})
update_tech("bio-science", {"fish-processing","military"}, {type="craft-item", item="cooked-fish", count=1000})
update_tech("bio-weaponry-1", {"advanced-oil-processing","military-2","bio-science"}, {type="craft-item", item="bio-science-pack", count=500})
update_tech("bio-weaponry-2", {"bio-weaponry-1","military-4"}, {type="craft-item", item="bio-science-pack", count=2000})
update_tech("bio-fuel", {"low-density-structure","bio-science"}, {type="craft-item", item="nat-gas-fuel", count=5000})
update_tech("air-purification", {"low-density-structure","bio-science"}, {type="craft-item", item="wood", count=5000})
update_tech("air-purification-2", {"air-purification","productivity-module"}, {type="craft-item", item="air-scrubber", count=300})
update_tech("chunky-meat-processing", {"bio-science"}, {type="craft-item", item="bio-science-pack", count=1000})

update_tech("effect-tranmission", {"productivity-module","advanced-material-processing-2","processing-unit"}, {type="craft-item", item="processing-unit", count=500})
update_tech("mass-production", {"productivity-module-3","advanced-material-processing-2","logistics-3"}, {type="craft-item", item="productivity-module-3", count=500})
update_tech("compression-tech", {"metal-pressing","adv-material-processing-2"}, {type="craft-item", item="metal-press-machine", count=100})

update_tech("rocket-silo", {"rocket-fuel","solar-energy","electric-energy-accumulators","productivity-module-3","speed-module-3","concrete","radar"}, {type="craft-item", item="processing-unit", count=5000})
update_tech("spidertron", {"radar","rocketry","military-4","fission-reactor-equipment","exoskeleton-equipment","efficiency-module-3"}, {type="craft-item", item="exoskeleton-equipment", count=100})

update_tech("artillery-shell-range-1", {"artillery","space-science-pack"}, {type="craft-item", item="artillery-shell", count=5000})
update_tech("artillery-shell-speed-1", {"artillery"}, {type="craft-item", item="artillery-shell", count=500})






















