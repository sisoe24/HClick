local executeClick = dofile(hs.spoons.resourcePath("execute_click.lua"))

-- Create a chooser choices entry.
--
-- Parameters:
-- * clicksInfo: a table containing one or more clicks information
--
-- Returns:
-- * a table containing the choices extracted from the clicks table.
local function createChooserMenu(clicksInfo)
  local menu = {}

  for appIndex, app in pairs(clicksInfo) do
    for appName, appData in pairs(app) do
      for clickIndex, clickData in ipairs(appData.clicks) do
        table.insert(menu, {
          ['text'] = clickData.name,
          ['subText'] = appName,
          ['appIndex'] = appIndex,
          ['clickIndex'] = clickIndex
        })
      end
    end
  end

  return menu
end

-- Create a chooser with the clicks
--
-- Parameters:
-- * clicksInfo: a table containing one or more clicks information
--
-- Returns:
-- * None.
local function hClickChooser(clicksInfo)

  local chooser = hs.chooser.new(function(choice)
    if not choice then return end

    local app = clicksInfo[choice['appIndex']]
    local appData = app[choice['subText']]
    local clickData = appData.clicks[choice.clickIndex]

    executeClick(choice['subText'], clickData)

    if appData.menubar then
      appData.menubar:toggleClicks(choice['subText'], choice.clickIndex)
    end

  end)

  local chooserMenu = createChooserMenu(clicksInfo)

  chooser:rows(#chooserMenu)
  chooser:width(20)
  chooser:choices(chooserMenu)
  chooser:searchSubText(true)
  chooser:placeholderText("Select a click to execute")
  chooser:show()

end

return hClickChooser
