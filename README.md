# BSPWM auto fullscreen
A simple Auto-fullscreen and EWW toggling script for the bspwm window manager

Just like the name says, this is a script i worked on 100% for myself (read carefully, "LIKE") to make nodes/windows in the BSPWM window manager automatically fullscreen and toggle Elkowars Wacky Widgets off
if it is in fullscreen and toggles it back on otherwise, it is a script mostly made for fun, lots of idiosyncratic logic happens here and assumptions that only make sense if you were me working on this.

You are free to inspire yourself and do the programmers best trick using my script and i would be more than happy to accept optimization/stylistic/philosophical notes ontop of my project, and thanks for checking it out!

Known "issues":
unused (but MAYBE to be used) read node state function near the bspc subscribe loop, suggest code to make it useful or remove it
foreign node type case path is pretty much useless since the subscribe command reads off an array of statically defined events, still defined it as if it was dynamic for good practice so suggest removal if needed
