-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --
-- Watertrailer fix script
--
-- Purpose: This script allows you to empty your watertrailers.
-- 
-- Authors: Timmiej93
--
-- Copyright (c) Timmiej93, 2017
-- For more information on copyright for this mod, please check the readme file on Github
--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --

WaterTrailerFix = {};

function WaterTrailerFix.prerequisitesPresent(specializations)
	return true;
end;

function WaterTrailerFix:load(savegame)
	self.setIsWaterTrailerDumping = SpecializationUtil.callSpecializationsFunction("setIsWaterTrailerDumping");
    self.isWaterTrailerDumping = false;
end

function WaterTrailerFix:draw()end;
function WaterTrailerFix:delete()end;
function WaterTrailerFix:mouseEvent(posX, posY, isDown, isUp, button)end;
function WaterTrailerFix:keyEvent(unicode, sym, modifier, isDown)end;

function WaterTrailerFix:readStream(streamId, connection)
    local isWaterTrailerDumping = streamReadBool(streamId);
    self:setIsWaterTrailerDumping(isWaterTrailerDumping, true);
end;

function WaterTrailerFix:writeStream(streamId, connection)
   streamWriteBool(streamId, self.isWaterTrailerDumping);
end;

function WaterTrailerFix:update(dt)
	if self:getIsActiveForInput() then
		for _,fillType in pairs(self:getCurrentFillTypes()) do
			if self:getFillLevel(fillType) > 0 then
				if not self.dumping then
				g_currentMission:addHelpButtonText(g_i18n:getText("T93_WTF_StartDump"), InputBinding.TOGGLE_TIPSTATE_GROUND)
				else
					g_currentMission:addHelpButtonText(g_i18n:getText("T93_WTF_StopDump"), InputBinding.TOGGLE_TIPSTATE_GROUND)
				end

				if InputBinding.hasEvent(InputBinding.TOGGLE_TIPSTATE_GROUND) then
					self.dumping = (not self.dumping);
					self:setIsWaterTrailerDumping(self.dumping)
				end

				if self.dumping then
					local newFillLevel = self:getFillLevel(fillType) - ((self:getUnitCapacity(self.waterTrailerFillUnitIndex)/100)*(dt/1000));

					self:setFillLevel(Utils.clamp(newFillLevel, 0, self:getCapacity(fillType)), fillType)

					if self:getFillLevel(fillType) <= 0 then
						self.dumping = false;
						self:setIsWaterTrailerDumping(self.dumping)
					end
				end
			end
		end
	end
end

function WaterTrailerFix:setIsWaterTrailerDumping(isDumping, noEventSend)
    WaterTrailerSetIsDumpingEvent.sendEvent(self, isDumping, noEventSend)
    self.isWaterTrailerDumping = isDumping;

    if self.isClient and self.sampleRefuel ~= nil then
        if isDumping then
            SoundUtil.play3DSample(self.sampleRefuel);
        else
            SoundUtil.stop3DSample(self.sampleRefuel);
        end;
    end;
end;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

WaterTrailerSetIsDumpingEvent = {}
local WaterTrailerSetIsDumpingEvent_mt = Class(WaterTrailerSetIsDumpingEvent, Event);

InitEventClass(WaterTrailerSetIsDumpingEvent, "WaterTrailerSetIsDumpingEvent");

function WaterTrailerSetIsDumpingEvent:emptyNew()
    local self = Event:new(WaterTrailerSetIsDumpingEvent_mt);
    return self;
end;

function WaterTrailerSetIsDumpingEvent:new(object, isDumping)
    local self = WaterTrailerSetIsDumpingEvent:emptyNew()
    self.object = object;
    self.isDumping = isDumping;
    return self;
end;

function WaterTrailerSetIsDumpingEvent:readStream(streamId, connection)
    self.object = readNetworkNodeObject(streamId);
    self.isDumping = streamReadBool(streamId);
    self:run(connection);
end;

function WaterTrailerSetIsDumpingEvent:writeStream(streamId, connection)
    writeNetworkNodeObject(streamId, self.object);
    streamWriteBool(streamId, self.isDumping);
end;

function WaterTrailerSetIsDumpingEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object);
    end;
    self.object:setIsWaterTrailerDumping(self.isDumping, true);
end;

function WaterTrailerSetIsDumpingEvent.sendEvent(object, isDumping, noEventSend)
    if isDumping ~= object.isWaterTrailerDumping then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(WaterTrailerSetIsDumpingEvent:new(object, isDumping), nil, nil, object);
            else
                g_client:getServerConnection():sendEvent(WaterTrailerSetIsDumpingEvent:new(object, isDumping));
            end;
        end;
    end;
end;