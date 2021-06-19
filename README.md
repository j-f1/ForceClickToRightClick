#  ForceClickToRightClick

ForceClickToRightClick converts Force Clicks into right/secondary clicks.

## The algorithm

(See `EventHandler.swift` for the code, which is ordered slightly differently from this explanation)

- When the app detect a left mouse down, it tells the system to ignore it and starts a 200ms countdown.
- If the app has detected a left mouse down, it takes over handling of all mouse events:
  - When the mouse is released, the app:
    1. Replays the left mouse down at its original location
    2. Replays the mouse moves in order, sending them as left mouse drag events
    3. Cancels the countdown and waits until another left mouse down before observing further events
  - When the mouse is dragged:
    - If the cursor has moved more than 8px from its starting location, the app:
      1. Replays the left mouse down at its original location
      2. Replays the mouse moves in order, sending them as left mouse drag events
      3. Cancels the countdown and waits until another left mouse down before observing further events
    - Otherwise, the app:
      1. Adds the new cursor location to the list of mouse moves to replay later
      2. Dispatches a mouse move event to continue to give the user feedback
  - When pressure change is detected on the trackpad:
    - If the pressure change goes over the system’s threshold for a force click, the app:
      1. Replays the mouse down event and mouse motion as right mouse down/drag events
      2. Cancels the countdown and transitions into right-click mode (see below)
    - Otherwise, the app discards the pressure event
  - When the mouse is released, the app:
    1. Replays the left mouse down at its original location
    2. Replays the mouse moves in order, sending them as left mouse drag events
    3. Cancels the countdown and waits until another left mouse down before observing further events
- If the app is in right-click mode, it takes over handling of all mouse events:
  - When the mouse is released, the app:
    1. Dispatches a right mouse up event 
    2. Waits until another left mouse down before observing further events
  - When the mouse is dragged, the app changes the event to a right-mouse-drag event.

All events not specified above are passed through as-is.

<!--
- We record all mouse events (down, up, pressure, move)
- When we detect a left mouse down, we suppress the event and set a timer for 500ms (???).
- If we detect a left mouse up before the timer expires, we fire both the mouse down and the mouse up together.
- If the mouse moves more than a set distance (10px?), trigger a mouse down and replay all the move events.
- If the force click event is detected (i.e. a transition to stage 2), dispatch a right mouse down. 
- After the timer has expired, begin checking the stored pressure events. If they show a decreasing or negative velocity, trigger a mouse down and replay. 
-->
