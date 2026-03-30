-- =========================================================
-- RED EWR airborne enemy detection logic
-- =========================================================
--
-- Logic:
-- 1. Every 60 sec, check all BLUE player-occupied units
-- 2. Keep only units that are airborne
-- 3. If RED EWR radar detects any of them:
--      - set alert flag 11 immediately (SAMs / IADS / whatever)
--      - start counting sustained detection time
-- 4. If detection remains active long enough:
--      - set escalation flag 12 (QRA launch, CAP scramble, etc.)
-- 5. If contact is lost before escalation threshold:
--      - keep alert flag 11 on
--      - do NOT escalate
--
-- =========================================================

local RadarGroupName        = 'RED EWR'
local TargetCoalition       = coalition.side.BLUE
local AlertFlag             = 11     -- immediate alert
local EscalationFlag        = 12     -- sustained detection / QRA
local CheckInterval         = 60     -- seconds
local EscalationDelay       = 180    -- seconds of continuous detection before QRA
local ShowMessages          = true   -- false = silent

-- =========================================================
-- Internal state
-- =========================================================

local firstDetectionTime    = nil
local alertTriggered        = false
local escalationTriggered   = false

-- =========================================================
-- Helpers
-- =========================================================

local function msg(text, duration)
    if ShowMessages then
        trigger.action.outText(text, duration or 10)
    end
end

local function getRadarController()
    local radarGroup = Group.getByName(RadarGroupName)

    if not radarGroup or not radarGroup:isExist() then
        msg('Radar group "' .. RadarGroupName .. '" not found or destroyed. Stopping checks.', 10)
        return nil
    end

    local controller = radarGroup:getController()
    if not controller then
        msg('Radar group "' .. RadarGroupName .. '" has no controller. Stopping checks.', 10)
        return nil
    end

    return controller
end

local function getDetectedAirbornePlayer()
    local controller = getRadarController()
    if not controller then
        return nil, "NO_RADAR"
    end

    local players = coalition.getPlayers(TargetCoalition) or {}

    for _, unit in ipairs(players) do
        if unit and unit:isExist() and unit:inAir() then
            local detected = controller:isTargetDetected(unit, Controller.Detection.RADAR)
            if detected then
                return unit, nil
            end
        end
    end

    return nil, nil
end

-- =========================================================
-- Main polling loop
-- =========================================================

local function pollEWR(_, now)
    local detectedUnit, errorCode = getDetectedAirbornePlayer()

    if errorCode == "NO_RADAR" then
        return nil
    end

    if detectedUnit then
        -- First valid detection: raise alert state
        if not alertTriggered then
            trigger.action.setUserFlag(AlertFlag, 1)
            alertTriggered = true
            firstDetectionTime = now
            msg('RED EWR ALERT: airborne BLUE player detected: ' .. detectedUnit:getName(), 10)
        else
            msg('RED EWR still tracking airborne BLUE player: ' .. detectedUnit:getName(), 5)
        end

        -- Sustained detection long enough? escalate
        if not escalationTriggered and firstDetectionTime then
            local elapsed = now - firstDetectionTime

            if elapsed >= EscalationDelay then
                trigger.action.setUserFlag(EscalationFlag, 1)
                escalationTriggered = true
                msg('RED EWR ESCALATION: detection sustained for ' .. math.floor(elapsed) .. ' sec. Escalation flag set.', 10)

                -- Optional:
                -- Group.activate(Group.getByName('RU QRA'))
                -- trigger.action.setUserFlag(13, 1)
                -- etc.
            end
        end

    else
        -- No target currently detected
        if firstDetectionTime and not escalationTriggered then
            msg('RED EWR lost contact before escalation threshold. Alert remains active, no QRA launched.', 5)
        end

        -- Reset continuous-detection timer only if escalation has not happened yet
        if not escalationTriggered then
            firstDetectionTime = nil
        end
    end

    return now + CheckInterval
end

-- =========================================================
-- Start scheduler
-- =========================================================

timer.scheduleFunction(pollEWR, nil, timer.getTime() + CheckInterval)
