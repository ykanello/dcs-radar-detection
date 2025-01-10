local DetectingUnit = Unit.getByName('EWR P19')
local TargetUnit = Unit.getByName('Viper-1')
local Radar = 1 -- Assuming radar 1, adjust if needed
local scheduler = nil

local function launchQRA()
  trigger.action.outText('Detected by Flat Face', 10)
  trigger.action.setUserFlag("11", true)
  mist.grouptoRandomZone('RU QRA', {'QRA Zone1', 'QRA Zone2', 'QRA Zone3'})

  -- Stop the scheduled detection check now that we've launched
  if scheduler then
      timer.scheduleFunction(scheduler, nil) -- clear the scheduler
      scheduler = nil 
  end
end

local function checkDetection()
  if Controller.isTargetDetected(DetectingUnit, TargetUnit, Radar) then
    launchQRA()  -- Launch QRA only if detected
  else
    trigger.action.outText('Not detected, checking again in 60 seconds...', 10)
    -- Reschedule the check after 60 seconds
    scheduler = timer.scheduleFunction(checkDetection, {}, timer.getTime() + 60)  -- reschedule the check
  end
end

-- Initial check
checkDetection()
