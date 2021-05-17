#  RightForce

RightForce converts Force Clicks into right/secondary clicks.

## The algorithm

- We record all mouse events (down, up, pressure, move)
- When we detect a left mouse down, we suppress the event and set a timer for 500ms (???).
- If we detect a left mouse up before the timer expires, we fire both the mouse down and the mouse up together.
- If the mouse moves more than a set distance (10px?), trigger a mouse down and replay all the move events.
- If the force click event is detected (i.e. a transition to stage 2), dispatch a right mouse down. 
- After the timer has expired, begin checking the stored pressure events. If they show a decreasing or negative velocity, trigger a mouse down and replay. 
