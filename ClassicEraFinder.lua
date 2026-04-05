--[[
  Classic Era Finder — entrypoint: eventos, comandos e sincronização mínima com a UI.
  Lógica de dados → ClassicEraFinder.Entries / DB / Filters / Messages / Instances
  Construção da janela → ClassicEraFinder.UI
]]

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

local ADDON_NAME = "ClassicEraFinder"

CEF.state = CEF.state or {}
CEF.state.filterSearchText = CEF.state.filterSearchText or ""
CEF.state.filterInstanceKey = CEF.state.filterInstanceKey or false
CEF.state.filterIntentKey = CEF.state.filterIntentKey or false
CEF.state.filterRoleKey = CEF.state.filterRoleKey or false

local mainFrame
local scrollFrame
local scrollChild
local rowFrames = {}
CEF.UI = CEF.UI or {}
CEF.UI.rowFrames = rowFrames

local uiTicker

local function refreshRelativeTimesOnly()
  CEF.UIEngine.refreshRelativeTimesOnly()
end

local function refreshUI()
  CEF.UIEngine.layoutRows()
  CEF.UIEngine.applyColumnWidths()
end

CEF.UI.refreshRelativeTimesOnly = refreshRelativeTimesOnly
CEF.UI.refreshUI = refreshUI

local function hideAllFilterDropdowns()
  CEF.UIFilters.hideAllFilterDropdowns(mainFrame)
end

local function purgeStaleEntries()
  if CEF.Entries.purgeStaleEntries() and mainFrame then
    refreshUI()
  end
end

local function onChatChannel(...)
  local text, playerName, _, _, _, _, _, _, channelBaseName, _, _, playerGUID = ...
  if not text or not playerName then
    return
  end
  CEF.Entries.upsertEntry(playerName, playerGUID, text, channelBaseName or "")
  refreshUI()
end

local function createMainUI()
  local f = CEF.UI and CEF.UI.createMainUI and CEF.UI.createMainUI() or nil
  if not f then
    return mainFrame
  end
  mainFrame = f
  scrollFrame = CEF.UI.scrollFrame
  scrollChild = CEF.UI.scrollChild
  uiTicker = CEF.UI.uiTicker
  return f
end

local function toggleMainFrame()
  createMainUI()
  if not mainFrame then
    return
  end
  if mainFrame:IsShown() then
    CEF.UIUtils.cefTooltipHide()
    hideAllFilterDropdowns()
    mainFrame:Hide()
    if uiTicker then
      uiTicker:Hide()
    end
  else
    mainFrame:Show()
    if scrollFrame and scrollChild and mainFrame.header then
      scrollChild:SetWidth(scrollFrame:GetWidth())
      CEF.UILayout.layoutHeaderColumns(mainFrame.header)
    end
    refreshUI()
    if uiTicker then
      uiTicker:Show()
    end
  end
end

local function createMinimapButton()
  if CEF.Minimap and CEF.Minimap.create then
    CEF.Minimap.create(toggleMainFrame)
  end
end

local eventFrame = CreateFrame("Frame")
local staleAgeAcc = 0
eventFrame:SetScript("OnUpdate", function(_, elapsed)
  staleAgeAcc = staleAgeAcc + (elapsed or 0)
  if staleAgeAcc >= 1 then
    staleAgeAcc = 0
    purgeStaleEntries()
  end
end)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("MINIMAP_UPDATE_ZOOM")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if (...) == ADDON_NAME then
      CEF.DB.init()
      CEF.Entries.loadFromDB()
    end
  elseif event == "PLAYER_LOGIN" then
    createMainUI()
    createMinimapButton()
    refreshUI()
  elseif event == "PLAYER_LOGOUT" then
    CEF.Entries.persist()
  elseif event == "CHAT_MSG_CHANNEL" then
    onChatChannel(...)
  elseif event == "MINIMAP_UPDATE_ZOOM" then
    if CEF.Minimap and CEF.Minimap.place then
      CEF.Minimap.place()
    end
  end
end)

SLASH_CLASSICERAFINDER1 = "/cef"
SLASH_CLASSICERAFINDER2 = "/classicerafinder"
SlashCmdList["CLASSICERAFINDER"] = function()
  toggleMainFrame()
end
