-- =========================================================
-- RED EWR group checks every 60 sec for airborne players
-- If any airborne player in the target coalition is detected
-- by RADAR, user flag 11 is set and polling stops.
-- =========================================================

local RadarGroupName   = 'RED EWR'
local TargetCoalition  = coalition.side.BLUE   -- change to RED if needed
local FlagNumber       = 11
local CheckInterval    = 60                    -- seconds
local ShowMessages     = true                  -- false = silent

local function msg(text, duration)
    if ShowMessages then
        trigger.action.outText(text, duration or 10)
    end
end

local function stopWithMessage(text)
    msg(text, 10)
    return nil
end

local function pollRadarDetection()
    local radarGroup = Group.getByName(RadarGroupName)

    if not radarGroup or not radarGroup:isExist() then
        return stopWithMessage('Radar group "' .. RadarGroupName .. '" not found or destroyed. Stopping checks.')
    end

    local controller = radarGroup:getController()
    if not controller then
        return stopWithMessage('Radar group "' .. RadarGroupName .. '" has no controller. Stopping checks.')
    end

    local players = coalition.getPlayers(TargetCoalition) or {}
    local airborneCount = 0

    for _, unit in ipairs(players) do
        if unit and unit:isExist() and unit:inAir() then
            airborneCount = airborneCount + 1

            local detected = controller:isTargetDetected(unit, Controller.Detection.RADAR)

            if detected then
                trigger.action.setUserFlag(FlagNumber, 1)
                msg('RED EWR detected airborne player: ' .. unit:getName(), 10)
                return nil   -- stop scheduler
            end
        end
    end

    msg('RED EWR: no airborne player detected. Airborne checked: ' .. airborneCount .. '. Rechecking in ' .. CheckInterval .. ' sec.', 5)
    return timer.getTime() + CheckInterval
end

timer.scheduleFunction(
    function()
        return pollRadarDetection()
    end,
    nil,
    timer.getTime() + CheckInterval
)
