 --[[ =========== Start:: RustyWash:: Drone Colour Override ========== --]]

local mod_name = "Rusty_Wash"
local steamID = "1785246205"
-- local author = "RustyDios"
-- local version ="1"

local RustyPrint = false

--[[ =========== Start:: RustyWash:: Function Overrides for Color ========== --]]

function OnMsg.ClassesBuilt()

	if RustyPrint then print  ("RustyWash detected:: Updating Drone Color commands with code from RustyDios") end
	ModLog ("RustyWash detected:: Updating Drone Color commands with code from RustyDios")

	local RDOverride_Drone_Idle = Drone.Idle
	local RDOverride_Drone_WaitingCommand = Drone.WaitingCommand
	local RDOverride_Drone_Fixed = Drone.Fixed

	function Drone:Idle(...)
		if self.RustyWash_Painted then
			if self:GetParent() then
				assert(false)
				self:SetCommand("Embark")
			end
			self:ResetUnitControlInteractionState() --if we made it to idle any interaction we may have had is over.
			Sleep(10)
			local force_go_home = self.force_go_home
			self.force_go_home = false
			
			--self:SetColorModifier(RGB(100, 100, 100))
			self:SetState("idle")
			
			Sleep(self.idle_wait or -1) -- -1 means immediate return
			
			if self.rogue then
				self:SetCommand("RogueAttack")
			end
			
			local command_center = self.command_center
			if not IsValid(command_center) then
				self:SetCommand("WaitingCommand")
			end
			--
			if self.resource then --we are carrying something.
				self:SetCommand("Deliver")
			else
				self.picked_up_from_req = false
			end
			-- repair command_center
			if command_center:IsMalfunctioned() and not IsKindOf(command_center, "RCRover") then
				if command_center.maintenance_phase == "demand" and command_center.maintenance_resource_request:CanAssignUnit() then
					--resource needs to be delivered.
					local req = command_center.maintenance_resource_request
					local supply_request, r_amount = command_center:FindSupplyRequest(self, req:GetResource(), req:GetTargetAmount())
					if supply_request then
						self:SetCommand("PickUp", supply_request, req, req:GetResource(), r_amount)
					end
				elseif command_center.maintenance_phase == "work" and command_center.maintenance_work_request:CanAssignUnit() then
					--work remains 2 be done
					self:SetCommand("Work", command_center.maintenance_work_request, "repair", Min(DroneResourceUnits.repair, command_center.maintenance_work_request:GetTargetAmount()))
				end
			end
			-- recharge if close to emergency power
			if self.battery <= g_Consts.DroneEmergencyPower * 2 then
				self:SetCommand("EmergencyPower")
			end
			
			if command_center.working then
				-- repair broken drones
				local nearest_broken = self:FindDroneToRepair()
				if nearest_broken then
					nearest_broken.repair_drone = self --so the next query returns a different drone
					self:SetCommand("RepairDrone", nearest_broken, g_Consts.DroneEmergencyPower) --returns
				end
				-- find work
				if GameTime() - command_center.no_requests_time > 1000 then
					local request, pair_request, resource, amount = command_center:FindTask(self)
					assert(not pair_request or request, "pair request without request")
					if request then
						assert(IsValid(request:GetBuilding(), "Request from destroyed obj!"))
						if request:IsAnyFlagSet(const.rfWork) then
							self:SetCommand("Work", request, resource, amount)
						else
							self:SetCommand("PickUp", request, pair_request, resource, amount)
						end
					elseif self.unreachable_buildings_count <= 0 then
						command_center.no_requests_time = GameTime()
					end
				end
			end
			-- stay close to the command_center
			if force_go_home or not self:IsCloser2D(command_center, command_center.distance_to_provoke_go_home_cmd) then
				self:SetCommand("GoHome", nil, nil, nil, "ReturningToController")
			end
			Sleep(2000)
			self:CleanUnreachables()
		else
			return RDOverride_Drone_Idle(self,...)
		end
	end

	function Drone:WaitingCommand(...) --orphanned drone command, not broken drones without command center should have this command.
		if self.RustyWash_Painted then
			assert(self.command_center == false or not IsValid(self.command_center))
			local new_dcc = self:TryFindNewCommandCenter()
			if new_dcc then
				self:SetCommandCenter(new_dcc)
				return
			end
			self:OnStartWaitingCommand()
			self:StartFX("WaitingCommand")
			self:PushDestructor(function(self)
				if IsValid(self) and not self:IsDead() then
					--self:SetColorModifier(RGB(100, 100, 100))
				end
			end)
			--self:SetColorModifier(RGB(60, 60, 60))
			self:SetState("idle")
			assert(self.is_orphan)
			Halt()
		else
			return RDOverride_Drone_WaitingCommand(self,...)
		end
	end

	function Drone:Fixed(...)
		if self.RustyWash_Painted then
			--self:SetColorModifier(RGB(100, 100, 100))
			self:UseBattery(0)
			self:PlayState(anim)
		else
			return RDOverride_Drone_Fixed(self,...)
		end
	end

--[[ =========== Finish:: RustyWash:: Function Overrides for Color ========== --]]

end -- end OnClassesBuilt  for overrides

--[[ =========== Finish:: RustyWash:: Function Overrides ========== --]]
