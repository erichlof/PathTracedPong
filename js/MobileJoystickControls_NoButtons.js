// exposed global variables/elements that your program can access
let joystickDeltaX = 0;
let joystickDeltaY = 0;
let pinchWidthX = 0;
let pinchWidthY = 0;
let stickElement = null;
let baseElement = null;
// create empty element containers for 'buttons' so that the onWindowResize() function inside 
// commonFunctions.js doesn't throw an error when trying to reference these null elements
let button1Element = document.createElement('div');
let button2Element = document.createElement('div');
let button3Element = document.createElement('div');
let button4Element = document.createElement('div');
let button5Element = document.createElement('div');
let button6Element = document.createElement('div');

// the following variables marked with an underscore ( _ ) are for internal use
let _touches = [];
let _eventTarget;
let _stickDistance;
let _stickNormalizedX;
let _stickNormalizedY;
let _showJoystick;
let _limitStickTravel;
let _stickRadius;
let _baseX;
let _baseY;
let _stickX;
let _stickY;
let _container;
let _pinchWasActive = false;



let MobileJoystickControls = function (opts)
{
        opts = opts || {};
        _container = document.body;

        //create joystick Base
        baseElement = document.createElement('canvas');
        baseElement.width = 126;
        baseElement.height = 126;
        _container.appendChild(baseElement);
        baseElement.style.position = "absolute";
        baseElement.style.display = "none";

        _Base_ctx = baseElement.getContext('2d');
        _Base_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
        _Base_ctx.lineWidth = 2;
        _Base_ctx.beginPath();
        _Base_ctx.arc(baseElement.width / 2, baseElement.width / 2, 40, 0, Math.PI * 2, true);
        _Base_ctx.stroke();

        //create joystick Stick
        stickElement = document.createElement('canvas');
        stickElement.width = 86;
        stickElement.height = 86;
        _container.appendChild(stickElement);
        stickElement.style.position = "absolute";
        stickElement.style.display = "none";

        _Stick_ctx = stickElement.getContext('2d');
        _Stick_ctx.strokeStyle = 'rgba(255,255,255,0.2)';
        _Stick_ctx.lineWidth = 3;
        _Stick_ctx.beginPath();
        _Stick_ctx.arc(stickElement.width / 2, stickElement.width / 2, 30, 0, Math.PI * 2, true);
        _Stick_ctx.stroke();


        // options
        _showJoystick = opts.showJoystick || false;

        _baseX = _stickX = opts.baseX || 100;
        _baseY = _stickY = opts.baseY || 200;

        _limitStickTravel = opts.limitStickTravel || false;
        if (_limitStickTravel) _showJoystick = true;
        _stickRadius = opts.stickRadius || 50;
        if (_stickRadius > 100) _stickRadius = 100;

        // the following listeners are for 1-finger touch detection to emulate mouse-click and mouse-drag operations
        _container.addEventListener('pointerdown', _onPointerDown, false);
        _container.addEventListener('pointermove', _onPointerMove, false);
        _container.addEventListener('pointerup', _onPointerUp, false);
        // the following listener is for 2-finger pinch gesture detection
        _container.addEventListener('touchmove', _onTouchMove, false);

}; // end let MobileJoystickControls = function (opts)


function _move(style, x, y)
{
        style.left = x + 'px';
        style.top = y + 'px';
}


function _onPointerDown(event)
{

        _eventTarget = event.target;

        if (_eventTarget != renderer.domElement) // target was the GUI menu
                return;

        // else target is the joystick area
        _stickX = event.clientX;
        _stickY = event.clientY;

        _baseX = _stickX;
        _baseY = _stickY;

        joystickDeltaX = joystickDeltaY = 0;

} // end function _onPointerDown(event)


function _onPointerMove(event)
{

        _eventTarget = event.target;

        if (_eventTarget != renderer.domElement) // target was the GUI menu
                return;

        _stickX = event.clientX;
        _stickY = event.clientY;

        joystickDeltaX = _stickX - _baseX;
        joystickDeltaY = _stickY - _baseY;

        if (_limitStickTravel)
        {
                _stickDistance = Math.sqrt((joystickDeltaX * joystickDeltaX) + (joystickDeltaY * joystickDeltaY));

                if (_stickDistance > _stickRadius)
                {
                        _stickNormalizedX = joystickDeltaX / _stickDistance;
                        _stickNormalizedY = joystickDeltaY / _stickDistance;

                        _stickX = _stickNormalizedX * _stickRadius + _baseX;
                        _stickY = _stickNormalizedY * _stickRadius + _baseY;

                        joystickDeltaX = _stickX - _baseX;
                        joystickDeltaY = _stickY - _baseY;
                }
        }

        if (_pinchWasActive)
        {
                _pinchWasActive = false;

                _baseX = event.clientX;
                _baseY = event.clientY;

                _stickX = _baseX;
                _stickY = _baseY;

                joystickDeltaX = joystickDeltaY = 0;
        }

        if (_showJoystick)
        {
                stickElement.style.display = "";
                _move(baseElement.style, (_baseX - baseElement.width / 2), (_baseY - baseElement.height / 2));

                baseElement.style.display = "";
                _move(stickElement.style, (_stickX - stickElement.width / 2), (_stickY - stickElement.height / 2));
        }

} // end function _onPointerMove(event)


function _onPointerUp(event)
{

        _eventTarget = event.target;

        if (_eventTarget != renderer.domElement) // target was the GUI menu
                return;

        joystickDeltaX = joystickDeltaY = 0;

        baseElement.style.display = "none";
        stickElement.style.display = "none";

} // end function _onPointerUp(event)


function _onTouchMove(event)
{
        // we only want to deal with a 2-finger pinch
        if (event.touches.length != 2)
                return;

        _touches = event.touches;

        pinchWidthX = Math.abs(_touches[1].pageX - _touches[0].pageX);
        pinchWidthY = Math.abs(_touches[1].pageY - _touches[0].pageY);

        _stickX = _baseX;
        _stickY = _baseY;

        joystickDeltaX = joystickDeltaY = 0;

        _pinchWasActive = true;

        baseElement.style.display = "none";
        stickElement.style.display = "none";
        
} // end function _onTouchMove(event)