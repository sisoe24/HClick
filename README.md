# HClick README

> NOTE: Readme is still work in progress

Simulate a mouse click at a specific point in some application.

## Features

- Click in a specific point of an application
- Automatically unhide/hide application when clicking.
- Application can be on different monitor.
- Quick menubar that indicates the toggle state of the click

## Caveats

If the click position is dynamic, i.e., moving around when you resize the application, it will not work.

## Usage

The most basic usage:

```lua
hclick = hs.loadSpoon('HClick')
hclick:bindHotKeys({
  copyCoordinatesLeft = {{'ctrl', 'alt'}, 'c', message = 'Left Coords copied'},
})

obs = hclick:new({appName = 'OBS'})
obs:menubar({
  isEnabled = true,
  customMenuItems = {{
    title = 'Resize App 1920x1080',
    fn = function()
      hs.application.frontmostApplication():mainWindow():setSize(1920, 1080)
    end
    }}
})

obs:addClicks({
  {
    name = 'record',
    shortcut = 'alt p',
    coordinates = '101.98828125 82.72265625',
    delay = 0
  },
  {
    name = 'pause',
    shortcut = 'alt o',
    coordinates = '156.0546875 84.32421875',
    delay = 0
  }
})
obs:enable()
```

This example will:

1. Create a shortcut `ctrl alt c` that you can use to copy the coordinates for the click. The application must be in focus when doing so.
2. Create an HClick object for the application OBS.
3. Enable the menubar and a custom item (a function which will resize a focused window).
4. Add two clicks.
5. Enable the object.

> You can find a more advanced case in the example directory.

## Known Issues
