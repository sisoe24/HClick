-- Check if app is invisible and raise it if it is.
--
-- Parameters:
--  * appName - A string representing the application name to inspect.
--
-- Returns:
--  * boolean - `true` if was invisible,`false` otherwise
local function appIsInvisible(appName)

  for _, window in pairs(hs.window.invisibleWindows()) do
    if window:application():name() == appName then
      window:raise()
      return true
    end
  end

  return false
end

-- Helper function
local function assertMsg(msg) return string.format('\n\n-> %s <-\n', msg) end

-- Get a hs.application object
--
-- If argument is a string, create a the `hs.application` object before checking
-- if is running. If app is not running, will raise an error.
--
-- Parameters:
--  * app - A string representing the application name or the hs.application object.
--
-- Returns:
--   * a `hs.application` object if application is running.
local function getApp(app)
  local appName

  if type(app) == "string" then
    appName = app
    app = hs.application(app)
  end

  if not app then
    local report = string.format(
                       'Check if app: "%s" is running or the name is valid',
                       appName)
    hs.notify.show('HClick', string.format('Could not find: %s', appName),
                   report)
    error(assertMsg(report), 2)
  end
  return app
end

-- Get app position in the screen.
--
-- Parameters:
--   * app - A string representing the application name or the hs.application object.
--
-- Returns:
--   * An hs.geometry rect containing the co-ordinates of the top left corner of the window and its width and height
local function getAppFrame(app) return getApp(app):mainWindow():frame() end

-- Execute callback after/before clicks.
--
-- Parameters:
--  * func - function object to be executed
--
-- Returns:
--  * The called function return.
local function callback(func) if type(func) == 'function' then return func() end end

-- Get screen position where to execute the click
--
-- Parameters:
--  * app: hs.application object
--  * coordinates: `string` coordinates values from the clicks.
--
-- Returns:
--  * table with the `x` and `y` coordinates points to click.
--
-- Notes:
--  * coordinates needs to be inside a string: "x, y".
--  * if coordinates will changed based on the click origin point.
local function getClickMousePosition(app, coordinates, origin)
  local clickX, clickY = string.match(coordinates, "(%g+)%s(%g+)")
  local appFrame = getAppFrame(app)

  if origin == 'right' then
    return {x = appFrame.w - clickX, y = appFrame.h - clickY}
  end

  return {x = appFrame.x + clickX, y = appFrame.y + clickY}
end

-- Execute click.
--
-- Parameters:
--  * appName - A string representing the application name whose the click belong.
--  * clickData - `table` containing the clicks information.
--
-- Returns:
--  * None.
--
-- Notes:
--  * If `clickData.predicateFn` is `false` will not get executed.
local function executeClick(appName, clickData)
  if callback(clickData.predicateFn) == false then return end
  callback(clickData.executeBeforeFn)

  -- save mouse initial position
  local mouseInitialPosition = hs.mouse.absolutePosition()

  -- save front most app before clicking
  local frontApp = hs.application.frontmostApplication()

  -- save target app visibility before activating
  local appWasInvisible = appIsInvisible(appName)

  local targetApp = getApp(appName)
  targetApp:activate()

  local clickMousePos = getClickMousePosition(targetApp, clickData.coordinates,
                                              clickData.appOrigin)
  hs.eventtap.leftClick({x = clickMousePos.x, y = clickMousePos.y},
                        clickData.delay)
  hs.mouse.absolutePosition(mouseInitialPosition)

  -- focus and hide back if conditions are valid
  if clickData.focusBack ~= false then frontApp:activate() end
  if appWasInvisible then targetApp:hide() end

  callback(clickData.executeAfterFn)
end

return executeClick
