local DetectingUnit = Unit.getByName('EWR P19')
local TargetUnit = Unit.getByName('Viper-1')
if Controller.isTargetDetected(DetectingUnit , TargetUnit , Radar) == true then
   trigger.action.outText('detected by Flat Face', 10)
   trigger.action.setUserFlag( "11", true )
   mist.grouptoRandomZone('RU QRA',{'QRA Zone1', 'QRA Zone2', 'QRA Zone3'})
end
