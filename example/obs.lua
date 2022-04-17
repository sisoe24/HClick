-- Personal preference: if app is not running I don't want to load this code
if not hs.application('OBS$') then return end

-- Resize current selected application to 1920x1080
--
-- Returns:
--  * None.
local function resizeApp()
  local focusedApp = hs.application.frontmostApplication()
  focusedApp:mainWindow():setSize(1920, 1080)
end

-- Load the Spoon
hclick = hs.loadSpoon('HClick')

-- Create shortcuts for spoon commands
hclick:bindHotKeys({
  copyCoordinatesLeft = {{'ctrl', 'alt'}, 'c', message = 'Left Coords copied'},
  copyCoordinatesRight = {{'ctrl', 'alt'}, 'v', message = 'Right Coords copied'},
  chooser = {{'ctrl', 'alt'}, '0'}
})

-- Create a spoon instance
obs = hclick:new({appName = 'OBS'})

-- Enable the menubar and add a custom menu item.
obs:menubar({
  isEnabled = true,
  customMenuItems = {{title = 'Resize App 1920x1080', fn = resizeApp}}
})

-- Add basic clicks
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
    delay = 0,
    clickMessage = 'pause'
  }
})
obs:enable()
