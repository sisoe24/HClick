--- === HClick ===
---
--- Simulate a mouse click at specific point in some Application.
---
--- Download:
local obj = {}
obj.__index = obj

-- Metadata
obj.name = "HClick"
obj.version = "0.1.0"
obj.author = "Virgil Sisoe <virgilsisoe@gmail.com>"
obj.homepage = ""
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.spoonPath = hs.spoons.scriptPath()
obj.menubarStateFile = obj.spoonPath .. 'menubar_state.json'

-- object attributes
obj.clicksData = {}
obj.showMenubar = nil
obj.customMenuItems = nil

local appMenubar = dofile(hs.spoons.resourcePath("menubar.lua"))
local chooser = dofile(hs.spoons.resourcePath("chooser.lua"))
local executeClick = dofile(hs.spoons.resourcePath("execute_click.lua"))

local logger = hs.logger.new('HClick', 'debug')

-- needed to pass click data to the chooser
local clicksInfo = {}

-- Copy coordinate from front most application.
--
-- Coordinates can be copied from left top or right bottom.
--
-- Parameters:
--  * origin - string value (left, right) indicating if coordinates should be copied from the
-- top left or bottom right
--
-- Returns:
-- * None.
local function copyCoords(origin)
  local appFrame = hs.application.frontmostApplication():mainWindow():frame()
  local x
  local y

  if origin == 'left' then
    x = hs.mouse.absolutePosition().x - appFrame.x
    y = hs.mouse.absolutePosition().y - appFrame.y
  elseif origin == 'right' then
    x = appFrame.w - hs.mouse.absolutePosition().x
    y = appFrame.h - hs.mouse.absolutePosition().y
  end

  hs.pasteboard.setContents(x .. " " .. y)
end

--- HClick:bindHotKeys(mapping)
--- Method
--- Bind hotkeys for HClick.
---
--- Parameters:
---  * mapping - A `table` containing hotkey modifier/key details for the following items:
---    * copyCoordinatesLeft - Copy to the clipboard, the coordinates of the mouse position relative left origin focused app.
---    * copyCoordinatesRight - Copy to the clipboard, the coordinates of the mouse position relative right origin focused app.
---    * chooser - Alternative way of executing the clicks by a `hs.chooser` object.
---
--- Returns:
---  * None
---
--- Notes:
---  * After getting the coordinates, the entire function can be commented out if shortcuts are not needed.
---  * Usage example:
---     ```lua
---     hclick = hs.loadSpoon('HClick')
---     hclick:bindHotKeys({
---       copyCoordinatesLeft = {{'ctrl', 'alt'}, 'c', message = 'Left Coords copied'},
---       copyCoordinatesRight = {{'ctrl', 'alt'}, 'v', message = 'Right Coords copied'},
---       chooser = {{'ctrl', 'alt'}, '0'}
---     })
--- ```
function obj:bindHotKeys(mapping)
  local actions = {
    copyCoordinatesLeft = hs.fnutils.partial(copyCoords, 'left'),
    copyCoordinatesRight = hs.fnutils.partial(copyCoords, 'right'),
    chooser = hs.fnutils.partial(chooser, clicksInfo)
  }
  hs.spoons.bindHotkeysToSpec(actions, mapping)
end

-- Bind the application clicks.
--
-- Returns:
-- * None.
--
-- Notes:
-- * If `self.showMenuBar` is `true`, each click is going to be assigned to the
-- `menubar:toggleClicks` function.
function obj:bindClicks()
  for clickIndex, clickData in pairs(self.clicksData) do

    -- extract shortcut from clicks
    local modifiers, shortcut = string.match(clickData.shortcut, "(.+)%s(%w+)")

    hs.hotkey.bind({modifiers}, shortcut, clickData.clickMessage, function()
      executeClick(self.appName, clickData)

      if self.showMenubar == true then
        self._menu:toggleClicks(self.appName, clickIndex)
      end

    end)

  end
end

--- HClick:addClicks(clicks)
--- Method
--- Add clicks to hclick object instance.
---
--- Parameters:
---  * clicks - table containing the followings keys
---   * name - A string with the name of the click.
---   * shortcut - A string with the shortcut for click.
---   * coordinates - A string with the coordinates gotten by using the one of the command provided: `copyCoordinatesLeft`, `copyCoordinatesRight`.
---   * appOrigin - An optional string that indicates the side of the application from where the coordinates should be calculated.
---   * predicateFn - An optional function which determines if the click should be executed. If it returns false, then the click will not be executed.
---   * executeBeforeFn - An optional function to call before the click is going to be executed.
---   * executeAfterFn - An optional function to call after the click was executed.
---   * clickMessage - An optional string with a message to shown when the click is executed.
---   * delay - An optional delay (in microseconds) between mouse down and up event. Defaults to 200000 (i.e. 200ms)
---   * focusBack - An optional boolean indicating if after the click, the initial application should take back the focus.
---
--- Returns:
---  * None.
---
--- Notes:
---  * Example:
---     ```lua
---     code:addClicks({
---       {
---         name = 'todo',
---         shortcut = 'alt l',
---         coordinates = '12.8125 479.09375',
---         delay = 0,
---         clickMessage = 'todo click',
---       },
---       {
---         name = 'ext',
---         shortcut = 'alt k',
---         coordinates = '43.703125 407.234375',
---         delay = 0,
---         focusBack = false,
---       }
---     })
---    ```
function obj:addClicks(clicks) self.clicksData = clicks end

--- HClick:menubar(options)
--- Method
--- Configuration options for the menubar.
---
--- Parameters:
---  * options - A table containing the following items:
---    * `isEnable` - a boolean to indicate if menubar should be visible.
---    * `customMenuItems` - a menu table, with custom menu entries.
---
--- Returns:
---  * None.
---
--- Notes:
--- * `customMenuItems` format is the same used to create a regular menu
---     ```lua
---     {
---       {title = "one", fn = function() print("click") end},
---       {title = "-"},
---       {title = "two item", checked = true}
---     }
---     ```
function obj:menubar(options)
  self.showMenubar = options['isEnabled']
  self.customMenuItems = options['customMenuItems']
end

--- HClick:enable()
--- Method
--- Enables the `hclick` object.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * None.
---
--- Notes:
--- * If menubar option `isEnabled` is `true`, then will also initialize the menubar.
function obj:enable()
  logger:i('-- Enable clicks for:', self.appName)
  self:bindClicks()

  self._menu = nil
  if self.showMenubar == true then
    self._menu = appMenubar:new({
      appName = self.appName,
      clicksData = self.clicksData,
      customMenuItems = self.customMenuItems
    })
    self._menu:createMenubar()
  end

  table.insert(clicksInfo, {
    [self.appName] = {
      clicks = self.clicksData,
      isEnabled = self.showMenubar,
      menubar = self._menu
    }
  })

end

-- Grab the menubar.json state file. If menubar json config is not present, create one.
--
-- Notes:
-- * This functions gets called automatically when hammerspoon is loading.
function obj:init()
  self.menubarState = hs.json.read(self.menubarStateFile)
  if not self.menubarState then
    hs.json.write({}, self.menubarStateFile, false, true)
  end
end

--- HClick:new(object)
--- Constructor
--- Creates a new hclick object.
---
--- Parameters:
---  * object - A table with the key `appName` as the target application for the clicks.
---
--- Returns:
--- * An `hclick` object.
function obj:new(object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end

return obj
