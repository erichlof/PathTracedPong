# PathTracedPong
A real-time path traced game for desktop and mobile using WebGL. <br>
Click to Play --> https://erichlof.github.io/PathTracedPong/Path_Traced_Pong.html
<br> <br>

<h3> March 14, 2025 NOTE: Workaround for Black Screen Bug (Mobile devices only) in latest Chromium Browsers (mobile Chrome, Edge, Brave, Opera) </h3>

* In latest Chrome 134.0 (and all Chromium-based browsers), there is a major bug that occurs on touch devices (happens on my Android phone - iPhone and iPad not tested yet)
* At demo startup, when you touch your screen for the first time, the entire screen suddenly turns black. There is no recovering - the webpage must be reloaded to see anything again.
* THE WORKAROUND: After starting up the demo, do a 'pinch' gesture with 2 fingers.  You can tell if you did it because the camera (FOV) will zoom in or out.
* Once you have done this simple 2-finger pinch gesture, you can interact with the demo as normal - the screen will not turn black on you for the duration of the webpage.
* I have no idea why this is happening.  I hooked my phone up to my PC's Chrome dev tools, and there are no warnings or errors in my phone's browser console output when the black screen occurs.
* I don't know why a 2-finger pinch gesture gets around this issue and prevents the black screen from occuring.
* I have done my own debug output on the demo webpage (inside an HTML element), and from what I can see, all the recorded touch events (like touchstart, touchmove, etc.) and camera variables appear valid and are working like they always do.
* The WebGL context isn't being lost and the webpage is not crashing, because the demo keeps running and the cameraInfo element (that is in the lower left-hand corner) on all demos, still outputs correct data - it's like the app is still running, taking user input, and doing path tracing calculations, but all that is displayed to the user is a black screen.
* I may open up a new issue on the Chromium bug tracker, but I can't even tell what error is occuring.  Plus my use case (path tracing fullscreen quad shader on top of three.js) is pretty rare, so I don't know how fast the Chromium team would get around to it, if at all.
* In my experience, these bugs have a way of working themselves out when the next update of Chromium comes out (which shouldn't be too long from now).  I love targeting the web platform because it is the only platform where you can truly "write the code once, run everywhere" - but one of the downsides of coding for this platform are the occasional bugs that are introduced into the browser itself, even though nothing has changed in your own code.  Hopefully this will be resolved soon, either by a targeted bug fix, or by happy accident with the next release of Chromium.  <br> <br>
<h4>Desktop Controls</h4>

* Click anywhere to capture mouse
* move Mouse to control paddle
* Mousewheel to dolly camera in or out
* Click the 'Gravity' button to simulate gravity!
* Click the 'Difficulty' button to cycle through the 3 difficulty levels
<br><br>

<h4>Mobile Controls</h4>

* Swipe to control paddle
* Pinch to dolly camera in or out
* Tap the 'Gravity' button to simulate gravity!
* Tap the 'Difficulty' button to cycle through the 3 difficulty levels

<h2>TODO</h2>

* Possibly add a small moving obstacle (mirror sphere or box) that randomly slides on the floor, changing the ball direction if it gets hit. ;-)<br>
* Network gameplay for 2 players using WebSockets would be a great addition (if I can ever find the time!) ;)

<h2>ABOUT</h2>

* Following my AntiGravity Pool [game](https://github.com/erichlof/AntiGravity-Pool), this is the second in a series of real-time fully path traced games for all devices with a browser, including mobile. The technology behind this simple game is a combination of my three.js path tracing [project](https://github.com/erichlof/THREE.js-PathTracing-Renderer) and the WebAudio API for sound effects.  The goal of this project and others like it is enabling path traced real-time games for all players, regardless of their system specs and GPU power. <br>
