--[[ =========== Start:: Rusty's Car Wash:: Main Script ========== --]]

local mod_name = "Rusty_Wash"
local steamID = "1785246205"
-- local authors = "RustyDios, Choggi" --~ model by Silva
-- local version ="18"

local ModDir = CurrentModPath

--[[
	Just a common curtesy.. this code was stolen and heavily adapted from original code written by ChoGGi, alot of the credit and idea and code is his
	I made this mod for personal use to include Silva's Forest Dome model as a "better building" for a car wash than the flat disc of the standard farm also to include pipe joints etc
	Therefore the main entity is stolen from Silva as well.. yehah I'm a pirate robbing treasures... 
	All credits given to the original owners for inspiring me to make this.. will likely never see the workshop...
	IF it has made it to the workshop, ensure I sought permissions from both original owners before posting, if your ever reading this
]]

--[[ =========== Start:: Rusty's Car Wash:: Define Locals ========== --]]

local RustyPrint = false

local CreateGameTimeThread = CreateGameTimeThread
local DeleteThread = DeleteThread
local IsValid = IsValid
local IsValidThread = IsValidThread
local NearestObject = NearestObject
local Sleep = Sleep
local Wakeup = Wakeup
local DustMaterialExterior = const.DustMaterialExterior

--[[ =========== Finish:: Rusty's Car Wash:: Define Locals ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: Add Building Template ========== --]]

-- add building to building template list
function OnMsg.ClassesPostprocess()
	if not BuildingTemplates.RustyWash then
		PlaceObj("ModItemBuildingTemplate", {
			"Id", "RustyWash",
			"template_class", "RustyWash",
			"dome_forbidden", true,
			"display_name", T("Rusty's Martian Carwash"),
			"display_name_pl", T("Rusty's Martian Carwashes"),
			"description", T("Working at the car wash,<newline>Working at the car wash, yeah,<newline>Come on and sing it with me, car wash,<newline>Sing it with the feeling now, car wash, yeah...<newline><newline>Automatically cleans units within the dome, park a unit on the blue Hex to place it within the dome. Eject a unit using the button. <newline><color red>DOES NOT</color> function during dust storms - too much dust.<newline> Will automatically stop using water if no unit is inside.<newline><newline> Whilst working you can optionally <color em>spray paint units</color>."),
			"build_category", "Infrastructure",
			"encyclopedia_id", "RustyWash",
			"encyclopedia_text", T("Working at the car wash,<newline>Working at the car wash, yeah,<newline>Come on and sing it with me, car wash,<newline>Sing it with the feeling now, car wash, yeah..."),
			"encyclopedia_image", ModDir .. "UI/RustyWash_Encylopedia.tga",
			"Group", "Infrastructure",
			"build_pos",12,
			"display_icon", ModDir .. "UI/RustyWash.png",
			"entity", "sBuilding_CarWash",
			"electricity_consumption", 2000,
			"water_consumption", 3000,
			"air_consumption", 0,
			"construction_cost_Concrete", 20000,
			"construction_cost_Metals", 15000,
			"construction_cost_Electronics", 1000,
			"construction_cost_Polymers", 1000,
			"maintenance_resource_type", "Metals",
			"maintenance_resource_amount", 1000,
			"palette_color1", "inside_metal",
			"palette_color2", "outside_dark",
			"palette_color3", "outside_base",
			"suspend_on_dust_storm", true,
			"demolish_sinking", range(1, 5),
			"demolish_tilt_angle", range(900, 1500),
			"demolish_debris", 85,
		})--end bt

		XTemplates.ipBuilding[1][#XTemplates.ipBuilding[1]+1] = PlaceObj("XTemplateTemplate",{
			"RustyWashPaintJobs", true,
			"__context_of_kind", "RustyWash",
			"__condition", function (parent, context) return not context.destroyed and not context.demolishing end,
			"__template", "InfopanelButton",
			"Icon", ModDir .. "UI/RustyWashSpray.dds",
			"Title", "Paint Units",
			"RolloverText", "Clicking this will randomly paint the unit with the current 3 colours.<newline>You can change the 3 paint cans by switching the building off/on.",
			"RolloverTitle", "New Paint Job",
			"RolloverHint",	 T("<left_click> Spray Paint  <right_click> Clean Paint"),
			"OnContextUpdate", function (self, context, ...)
				---
				self:SetEnabled(context.working)
				---
			end,
			"OnPress", function(self, context)
				---
				self.context:SprayObjects()
				if RustyPrint then print ("You left clicked a Spray button") end
				---
			end,
			"AltPress", true,
			"OnAltPress", function (self, context)
				---
				self.context:CleanPaint()
				if RustyPrint then print ("You right clicked a Spray button")end
				---
			end,
		})--end ip button add

		XTemplates.ipBuilding[1][#XTemplates.ipBuilding[1]+1] = PlaceObj("XTemplateTemplate",{
			"RustyWashEject", true,
			"__context_of_kind", "RustyWash",
			"__condition", function (parent, context) return not context.destroyed and not context.demolishing end,
			"__template", "InfopanelButton",
			"Icon", "UI/Icons/IPButtons/tunnel.tga",
			"Title", "Eject Unit",
			"RolloverText", "Clicking this will eject the current unit",
			"RolloverTitle", "Eject Unit",
			"RolloverHint",	 T("<left_click> Eject Unit <right_click> Eject and Select Unit"),
			"OnContextUpdate", function (self, context, ...)
				---
				self:SetEnabled(context.working)
				---
			end,
			"OnPress", function(self, context)
				---
				self.context:EjectUnit()
				if RustyPrint then print ("You left clicked the Eject button") end
				---
			end,
			"AltPress", true,
			"OnAltPress", function (self, context)
				---
				self.context:EjectandSelect()
				if RustyPrint then print ("You right clicked the Eject button")end
				---
			end,

		})--end ip button add

	end
end --ClassesPostprocess

--[[ =========== Finish:: Rusty's Car Wash:: Add Building Template ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: Define Class Template ========== --]]
DefineClass.RustyWash = {
	__parents = {
		"Building",
		"ElectricityConsumer",
		"LifeSupportConsumer",
		"OutsideBuildingWithShifts",
		"ColdSensitive",
	},

	-- stuff from water tanks
	building_update_time = 10000,

	-- stuff from farm
	properties = {
		{ template = true, id = "water_consumption", name = T(656, "Water consumption"),	category = "Consumption", editor = "number", default = 0, scale = const.ResourceScale, read_only = true, modifiable = true },
		{ template = true, id = "air_consumption",	 name = T(657, "Oxygen Consumption"), category = "Consumption", editor = "number", default = 0, scale = const.ResourceScale, read_only = true, modifiable = true },
	},

	-- initialise our threads
	anim_thread = false,
	nearby_thread = false,

	-- tell the class it behaves like a Farm for anim/parsystems visuals
	fx_actor_class = "Farm"
}
--[[ =========== Finish:: Rusty's Car Wash:: Define Class Template ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: Game Init ========== --]]

function RustyWash:GameInit()
	self.FarmBase = self:GetAttach("InvisibleObject")--attaching like this else auto attach actually adds a full working farm!
	local FarmBase = self.FarmBase

	-- scale it, flip it, colour it, clip it
	FarmBase:ChangeEntity("Farm")
	FarmBase:SetScale(80)
	FarmBase:SetColorModifier(1459598) -- big blue pool of water :)

	self.sprinkler = self:GetAttach("FarmSprinkler")
	local sprinkler = self.sprinkler

	-- start the animimations
	self:StartAnimThread(sprinkler)

	-- give a visual UI indication of where to enter/exit
	self.tarmac = self:GetAttach("RangeNonActive_01")
	local tarmac = self.tarmac
	tarmac:SetColorModifier(1459598) -- same blue colour as the pool
	tarmac:Detach() -- this will stop it from changing illumination states depending on if building is active or not

	self.tarmac_eject = self:GetAttach("RangeNonActive_02")
	local tarmac_eject = self.tarmac_eject
	tarmac_eject:Detach()
	
	-- start the cleaning and hunting thread
	self.nearby_thread = CreateGameTimeThread(function()
		while IsValid(self) and not self.destroyed do

			local obj = nil -- reset any found search, new loop

			-- check for anything on the "tarmac", nearby "Units" within 1/2 Hex ~~ ON the pad
			obj = NearestObject(tarmac, UICity.labels.Unit or {}, 500)
			self.obj_on_tarmac = obj

			-- we have a valid unit 
			if obj then
				--is it the same/sat here... switch on and pull water if it's new
				if self.obj_on_tarmac_prev ~= obj then
					--swap units over in case we were working on something else
					self:EjectUnit() 
					self.obj_on_tarmac_prev = obj 
					self:LoadUnit(obj) 
					--switch ourselves to consume water.. we're always drawing power unless switched off by player
					self.water_consumption = 3000
					self:UpdateConsumption()
					self:SetWorking(true)
					if RustyPrint then print ("Found a NEW unit nearby:",obj.class) end
				end

				--smoothly rotate the dummy
				self.obj_on_display:SetAngle(self.obj_on_display:GetVisualAngle()+120)

				-- get dust amount, and convert to percentage, magic code by ChoGGi
				local dust_amt = (obj:GetDust() + 0.0) / 100
				if dust_amt ~= 0.0 then
					local value = 100

					while true do
						if value == 0 then
							break
						end
						value = value - 1
						obj:SetDust(dust_amt * value, DustMaterialExterior)
						Sleep(100)
					end-- end while dust true loop

				end-- end dust amt >0
			else
				-- no unit nearby so we'll switch off the water and go into 'hibernation'... :) 
				self.water_consumption = 0
				self:UpdateConsumption()
				self:SetWorking(false)
				if self.obj_on_tarmac_prev then -- in case we we were working on something and it moved away... ffs:DRONES..!!
					self:EjectUnit()
					self.obj_on_tarmac_prev = obj
				end
				self:ShouldShowNotWorkingNotification()
			end -- end if obj is unit

		Sleep(2000) -- 2 sec pause between search loops, too short? too long?
		end -- while we exist loop
	end)-- end CGTT hunt and clean function

	--initiate this to store the sprinkler colours for later
	self.sprinkler_colours = {}

end

--[[ =========== Finish:: Rusty's Car Wash:: Game Init ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: Animation Thread ========== --]]

function RustyWash:StartAnimThread(sprinkler)
	sprinkler = sprinkler or self.sprinkler
	if not sprinkler then return end

	-- FarmConventional:StartAnimThread -- nope replaced with this on start instead
	self.anim_thread = CreateGameTimeThread(function()
		while IsValid(self) and not self.destroyed do
			local working = self.working

			-- we're working but not set up, raise the water sprinkler, ChoGGi magic
			if working and not self.is_up then
				sprinkler:SetAnim(1, "workingStart")
				Sleep(sprinkler:TimeToAnimEnd())
				PlayFX("FarmWater", "start", sprinkler)

				self.is_up = true

				--make the spray fit the dome and assign random colours, store the values for later use...
				self.sprinkler:ForEachAttach("ParSystem", function(a)
					if a:GetParticlesName() == "HydroponicFarm_Shower" then
						local color = AsyncRand(16777217) + -16777216
						self.sprinkler_colours [#self.sprinkler_colours+ 1] = color
						a:SetColorModifier(color)
						a:SetScale(142)
					end
				end
				)
				if RustyPrint then print("Car Wash Spraying with the following colours:",self.sprinkler_colours) end

			-- we're not working but set up, lower the sprinkler, ChoGGi magic
			elseif not working and self.is_up then
				PlayFX("FarmWater", "end", sprinkler)

				sprinkler:SetAnim(1, "workingEnd")
				Sleep(sprinkler:TimeToAnimEnd())
				self.is_up = false
			end

			-- if working state changed start over, otherwise set appropritate idle state, fire fx and wait, MORE ChoGGi magic
			if working == self.working then
				sprinkler:SetAnim(1, working and "workingIdle" or "idle")
				WaitWakeup()
			end
		end -- end while alive
	end) -- end CGTT anim.thread

end
--[[ =========== Finish:: Rusty's Car Wash:: Animation Thread ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: Working Functions ========== --]]

function RustyWash:OnSetWorking(working)

	-- tie the building into shiftwork and electricity "supplies"
	OutsideBuildingWithShifts.OnSetWorking(self, working)
	ElectricityConsumer.OnSetWorking(self, working)

	-- reset/clear the colours, we give new ones on switch on, stops the table being bloated
	self.sprinkler_colours = {}

	-- changed magic from ChoGGi, we should have a thread, it's created on init, but we sleep wake up on state change
	if IsValidThread(self.anim_thread) then
		Wakeup(self.anim_thread)
	end
	
end

--correctly suspend on DustStorms, powers down, disables on/off button
function RustyWash:BuildingUpdate(dt, day, hour)
	if self.working and g_DustStorm then
		self:SetSuspended(true,const.DustStormSuspendReason)
	end
end

-- function lifted from ECM, skipped checks we've already done them from the carwash
local function SaveOldPalette(obj)
	if obj then
		-- using Choggi's names from his library here so it still works with his cheat pane
		if not obj.ChoGGi_origcolors then
			obj.ChoGGi_origcolors = {
				{obj:GetColorizationMaterial(1)},
				{obj:GetColorizationMaterial(2)},
				{obj:GetColorizationMaterial(3)},
				{obj:GetColorizationMaterial(4)},
			}
			obj.ChoGGi_origcolors[-1] = obj:GetColorModifier()
		end
	end
end

-- function lifted from ECM, mashed it a bit
function RustyWash:SprayObjects()
	local obj = self.obj_on_display -- self.obj_on_tarmac 
	local colours = self.sprinkler_colours 
	
	if obj then
		SaveOldPalette(obj)
		for i = 1, 4 do
			local pick_one = table.rand{colours[1],colours[2],colours[3],}
			obj:SetColorizationMaterial(i,pick_one,pick_one,pick_one)
		end
		local pick_one = table.rand{colours[1],colours[2],colours[3],}
		obj:SetColorModifier(pick_one)
	end
end

-- function lifted from ECM, skipped checks we've already done them from the carwash
function RustyWash:CleanPaint()
	local obj = self.obj_on_display -- self.obj_on_tarmac

	if obj then
		if obj.ChoGGi_origcolors then
			local c = obj.ChoGGi_origcolors
			obj:SetColorModifier(c[-1])
			obj:SetColorizationMaterial(1, c[1][1], c[1][2], c[1][3])
			obj:SetColorizationMaterial(2, c[2][1], c[2][2], c[2][3])
			obj:SetColorizationMaterial(3, c[3][1], c[3][2], c[3][3])
			obj:SetColorizationMaterial(4, c[4][1], c[4][2], c[4][3])
			obj.ChoGGi_origcolors = nil
		end
	end
end

local function ColourCopy(from_this, to_this)

	-- ensure we store original colours
	SaveOldPalette(from_this)
	if from_this.ChoGGi_origcolors then
		to_this.ChoGGi_origcolors = from_this.ChoGGi_origcolors
	end

	-- create a table of the current colours
	if not from_this.color_transfer then
		from_this.color_transfer = {
			{from_this:GetColorizationMaterial(1)},
			{from_this:GetColorizationMaterial(2)},
			{from_this:GetColorizationMaterial(3)},
			{from_this:GetColorizationMaterial(4)},
		}
		from_this.color_transfer[-1] = from_this:GetColorModifier()
	end

	-- paint the destination in the current colours
	local c = from_this.color_transfer
		to_this:SetColorModifier(c[-1])
		to_this:SetColorizationMaterial(1, c[1][1], c[1][2],c[1][3])
		to_this:SetColorizationMaterial(2, c[2][1], c[2][2],c[2][3])
		to_this:SetColorizationMaterial(3, c[3][1], c[3][2],c[3][3])
		to_this:SetColorizationMaterial(4, c[4][1], c[4][2],c[4][3])
end

--function to load a unit into the carwash
function RustyWash:LoadUnit(obj)
	local obj = obj
	local obj_on_display = PlaceObject("InvisibleObject")
	obj_on_display:ChangeEntity(obj.entity)

	--create a dummy to play with, in the center (which co-incidently is the position the farm base is in...)
	local pos = self.FarmBase:GetPos()
	obj_on_display:SetPos(pos)

	self.obj_on_display = obj_on_display

	if obj:IsKindOf("BaseRover") then
		obj_on_display:SetScale(100) -- it's a rover so we shrink it to fit, not actually needed but keeping the code just in case
	else
		obj_on_display:SetScale(275) -- it's a drone so we enlarge it
	end

	-- hide the original object, show our dummy
	obj:SetVisible(false)
	obj:ClearEnumFlags(const.efSelectable)
	obj_on_display:SetVisible(true)

	--copy the current colours
	ColourCopy(obj,obj_on_display)

	-- swap selection to the carwash, if still selected object
	if SelectedObj == obj then
		SelectObj(self)
	end
end

--function to eject the current unit back onto the map
function RustyWash:EjectUnit()
	local obj = self.obj_on_tarmac
	local obj_prev = self.obj_on_tarmac_prev
	local obj_on_display = self.obj_on_display
	 
	if obj_prev then
		-- swap the original objects colours, ensures we save default colours too
		ColourCopy(obj_on_display,obj_prev)
		obj_prev.RustyWash_Painted = true -- tell the unit its been painted, see overide file, stops drone reverting colour
		obj_prev.color_transfer = nil

		-- remember to 'bring back' the original object
		local EjectPos = self.tarmac_eject:GetPos()
		if RustyPrint then print ("Ejecting to",EjectPos) end
		obj_prev:SetPos(EjectPos) -- get them off the tarmac... :)

		obj_prev:SetEnumFlags(const.efSelectable)
		obj_prev:SetVisible(true)
		
		-- remove our dummy
		DoneObject(obj_on_display)
	end
end 

function RustyWash:EjectandSelect()
	self:EjectUnit()
	SelectObj(self.obj_on_tarmac_prev)
end

--[[ =========== Finish:: Rusty's Car Wash:: Working Function ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: Done/destroyed Function ========== --]]

function RustyWash:Done()
	if IsValidThread(self.nearby_thread) then
		DeleteThread(self.nearby_thread)
	end

	if IsValidThread(self.anim_thread) then
		DeleteThread(self.anim_thread)
	end
end

function RustyWash:OnDestroyed()
	-- delete the threads
	self:Done()

	-- eject any units we might have
	self:EjectUnit()

	-- destroy our "tarmac patches"
	DoneObject(self.tarmac)
	DoneObject(self.tarmac_eject)

	-- make sure sprinkler VFX is stopped
	if self.sprinkler then
		PlayFX("FarmWater", "end", self.sprinkler)
		self.sprinkler:SetAnim(1, "workingEnd")
	end
end

--[[ =========== Finish:: Rusty's Car Wash:: Done/destroyed Function ========== --]]

--[[ =========== Start:: Rusty's Car Wash:: UI/infopanel Functions ========== --]]

-- add new buttons -- moved into OnMsg.ClassesPostprocess ~ waaayyy at the top

function RustyWash:UpdateAttachedSigns()
	ElectricityConsumer.UpdateAttachedSigns(self)

	LifeSupportConsumer.UpdateAttachedSigns(self)
end

-- don't work too much dust buildup during storms
function RustyWash:GetUIWarning()
	return Building.GetUIWarning(self) or g_DustStorm and NotWorkingWarning.SuspendedDustStorm
end

--this ensures they're not silent on selection
function OnMsg.SelectionAdded(obj, ...)
	local obj = obj
	if obj:IsKindOf("RustyWash") then
		obj.force_fx_work_target = obj
		obj.fx_actor_class = "WasteRockProcessor"
		
		if RustyPrint then print ("RustyWash :: Forced a Wash to Cycle at Selection") end 
	end
end
--[[ =========== Finish:: Rusty's Car Wash:: UI/infopanel Functions ========== --]]

--[[ =========== Finish:: Rusty's Car Wash:: Main Script ========== --]]
