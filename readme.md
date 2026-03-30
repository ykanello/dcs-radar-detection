## How it behaves

### Case 1: Enemy appears briefly

* RED EWR detects an airborne BLUE player.
* **Flag 11** is set immediately.
* Detection disappears before the escalation threshold is reached.
* **Flag 12** is **not** set.
* Result: only the initial alert logic runs, such as waking up SAMs or enabling the air defense state.

### Case 2: Enemy remains detected

* RED EWR detects an airborne BLUE player.
* **Flag 11** is set immediately.
* Detection continues long enough to pass the escalation delay.
* **Flag 12** is then set.
* Result: escalation logic can run, such as launching QRA, CAP, or other follow-on reactions.

### Case 3: Radar group is destroyed or unavailable

* The script can no longer access the `RED EWR` group or its controller.
* Polling stops.
* No further detection checks are performed.

### What “continuous detection” means

The script checks for detection once every configured polling interval.

This means “continuous detection” does **not** mean a perfect real-time lock. It means:

> the target is still being detected on repeated polling checks, without detection dropping long enough to reset the timer.

For example:

* `CheckInterval = 60`
* `EscalationDelay = 180`

This means escalation will happen after roughly **three consecutive successful checks**.

### Summary

* **Flag 11** = initial air defense alert
* **Flag 12** = sustained detection escalation

This allows a two-stage reaction model:

1. **Short contact** triggers alert only.
2. **Persistent contact** triggers stronger responses.

