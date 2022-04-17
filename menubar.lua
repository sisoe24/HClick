local obj = {}
obj.__index = obj

obj.menubarStatePath = hs.spoons.scriptPath() .. 'menubar_state.json'
obj.currentApps = {}

-- the menubar.json configuration data.
function obj:menubarStateFile() return hs.json.read(self.menubarStatePath) end

-- Menubar items style text
--
-- The style is changes slightly based on how many items are in the menubar (1 or 1+)
-- like increase font size and line spacing.
--
-- Parameters:
--  * title - string title to stylize
--  * numItems - number of menu items that goes into the menubar
--
-- Returns:
--  * style - styled text
local function styleText(title, numItems)

  local fontSize, lineSpacing = 10.0, 4.0

  -- only 1 title
  if numItems == 1 then fontSize, lineSpacing = 13.0, 10.0 end

  local style = hs.styledtext.new(string.upper(title), {
    font = {size = fontSize, name = 'Menlo'},
    -- kerning = 0.1,
    expansion = 0.1,
    paragraphStyle = {
      alignment = "natural",
      maximumLineHeight = 5.0,
      lineSpacing = lineSpacing
    }
  })
  return style
end

-- Re order menubar items.
--
-- Parameters:
--  * menubarItems - table of menu bar items to reorder
--  * splitAt - number that should be the half size of menubar items
--
-- Returns:
--  * table with the menubar items.
local function reorderMenubarItems(menuItems, splitAt)

  local firstRow = {}
  local secondRow = {}
  for itemIndex, item in ipairs(menuItems) do
    if itemIndex < splitAt then table.insert(firstRow, item) end
    if itemIndex >= splitAt then table.insert(secondRow, item) end
  end

  -- if first row has more elements then need dummy element to keep aligned
  if #firstRow > #secondRow then
    table.insert(secondRow, {name = "", state = ""})
  end

  hs.fnutils.concat(secondRow, firstRow)
  return secondRow
end

-- Format menubar title.
--
-- This will divide the names in more rows if necessary and align each name to
-- have equal space.
--
-- Parameters:
--  * menuItems - table of menubar items names to format
--
-- Returns:
--  * string: the styled title for the menubar.
local function formatTitle(menuItems)

  local splitAt = math.ceil(#menuItems / 2) + 1
  local reorderedItems = reorderMenubarItems(menuItems, splitAt)

  local title = ""
  for itemIndex, item in ipairs(menuItems) do

    local name, state = item.name, (item.state or "")

    local secondRowItem = reorderedItems[itemIndex].name
    local sizeDifference = math.max(#name, #secondRowItem) - #name

    local space = string.rep(' ', sizeDifference)
    name = space .. name .. " " .. state

    -- if state is `on` add 1 space so when toggling on/off name doesn't move
    if state == 'on' then name = name .. " " end

    if itemIndex == splitAt then title = title .. "\n" end

    -- if name is at end row, then put no space
    local endSpace = " "
    if itemIndex == splitAt - 1 or itemIndex == #menuItems then endSpace = "" end

    title = title .. name .. endSpace

  end

  -- HACK: insert new line at beginning to create more space above
  title = "\n" .. title

  return styleText(title, #menuItems)
end

-- Set the menubar title with the clicks names.
--
-- Parameters:
--  * clicks - table with click data information
--
-- Returns:
-- * None.
function obj:setTitle(clicks)

  local menuItems = {}

  for _, click in ipairs(clicks) do
    table.insert(menuItems, {name = click.name .. ":", state = click.state})
  end

  local title = formatTitle(menuItems)
  self.menubar:setTitle(title)
end

-- Changed click state inside menubar.json.
--
-- If state is `on` will be switched to `off` and vice versa.
--
-- Parameters:
--  * appName - click application name.
--  * clickIndex - click index.
--
-- Returns:
-- * None.
function obj:toggleClicks(appName, clickIndex)

  local menubarState = self:menubarStateFile()

  local clickData = menubarState[appName].clicks[clickIndex]
  if not clickData.state then clickData.state = 'off' end

  if clickData.state == "on" then
    clickData.state = 'off'
  elseif clickData.state == "off" then
    clickData.state = 'on'
  end

  hs.json.write(menubarState, self.menubarStatePath, false, true)

  self:setTitle(menubarState[appName].clicks)

end

-- Populate the menubar with menu entries.
--
-- Parameters:
--  * clicks - table containing the clicks from the menubar.json.
--
-- Returns:
-- * None.
function obj:addMenubarItems(clicks)

  -- base menubar layout
  local menuOptions = {
    {title = self.appName, disabled = true},
    {title = "-"},
    {title = 'Invert', menu = {}},
    {title = "-"}
  }

  -- invert clicks behavior
  local indexInvertSubmenu = 3
  for clickIndex, click in ipairs(clicks) do
    table.insert(menuOptions[indexInvertSubmenu].menu, {
      title = click.name,
      fn = function() self:toggleClicks(self.appName, clickIndex) end
    })
  end

  -- add user menu items if any
  if self.customMenuItems then
    for _, value in ipairs(self.customMenuItems) do
      table.insert(menuOptions, value)
    end
  end

  self.menubar:setMenu(menuOptions)
end

-- Update the menubar config state file by deleting old apps,
-- and update the clicks names.
--
-- Parameters:
--  * menubarFileConfig - menubar.json data.
--
-- Returns:
--  * None.
function obj:updateMenubarConfig(menubarFileConfig)

  local clickState = {}

  -- get current clicks data from configuration file
  if menubarFileConfig[self.appName] then
    for _, click in ipairs(menubarFileConfig[self.appName].clicks) do
      table.insert(clickState, click.state)
    end
  end

  -- update configuration file based on new clicksData information,
  -- which could update the click name but maintain the click state
  menubarFileConfig[self.appName] = {clicks = {}}
  for clickIndex, clickData in pairs(self.clicksData) do
    table.insert(menubarFileConfig[self.appName].clicks,
                 {name = clickData.name, state = clickState[clickIndex]})
  end

  -- delete apps that are not present in self.data anymore
  table.insert(self.currentApps, self.appName)
  for app, appTable in pairs(menubarFileConfig) do
    if not hs.fnutils.contains(self.currentApps, app) then
      menubarFileConfig[app] = nil
    end
  end

  table.sort(menubarFileConfig)
  hs.json.write(menubarFileConfig, self.menubarStatePath, false, true)
end

-- Create menubar
--
-- Returns:
-- * None.
function obj:createMenubar()
  local menubarFileConfig = self:menubarStateFile()
  self:updateMenubarConfig(menubarFileConfig)

  local clicks = menubarFileConfig[self.appName].clicks

  self.menubar = hs.menubar.new()
  self:setTitle(clicks)
  self:addMenubarItems(clicks)
end

-- Init a new object
function obj:new(object)
  object = object or {}
  setmetatable(object, self)
  self.__index = self
  return object
end

return obj
