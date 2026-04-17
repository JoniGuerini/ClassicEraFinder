-- Módulo: helpers de UI para filtros (esconder dropdowns e atualizar resumos)

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UIFilters = CEF.UIFilters or {}
local UI = CEF.UIFilters

local function anyFilterMenuShown(mainFrame)
  if not mainFrame then
    return false
  end
  local a = mainFrame.filterInstanceMenu and mainFrame.filterInstanceMenu:IsShown()
  local b = mainFrame.filterIntentMenu and mainFrame.filterIntentMenu:IsShown()
  local c = mainFrame.filterRoleMenu and mainFrame.filterRoleMenu:IsShown()
  return a or b or c
end

function UI.syncFilterDropBlocker(mainFrame)
  local blocker = mainFrame and mainFrame.cefFilterDropBlocker
  if not blocker then
    return
  end
  if anyFilterMenuShown(mainFrame) then
    blocker:Show()
  else
    blocker:Hide()
  end
end

function UI.hideFilterInstanceMenu(mainFrame)
  if mainFrame and mainFrame.filterInstanceMenu then
    mainFrame.filterInstanceMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.hideFilterIntentMenu(mainFrame)
  if mainFrame and mainFrame.filterIntentMenu then
    mainFrame.filterIntentMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.hideFilterRoleMenu(mainFrame)
  if mainFrame and mainFrame.filterRoleMenu then
    mainFrame.filterRoleMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.hideAllFilterDropdowns(mainFrame)
  if mainFrame and mainFrame.filterInstanceMenu then
    mainFrame.filterInstanceMenu:Hide()
  end
  if mainFrame and mainFrame.filterIntentMenu then
    mainFrame.filterIntentMenu:Hide()
  end
  if mainFrame and mainFrame.filterRoleMenu then
    mainFrame.filterRoleMenu:Hide()
  end
  UI.syncFilterDropBlocker(mainFrame)
end

function UI.updateFilterDropSummary(filterDropSummaryFS, filterInstanceKey)
  if filterDropSummaryFS then
    filterDropSummaryFS:SetText(CEF.instanceFilterSummaryRichText(filterInstanceKey))
  end
end

function UI.updateIntentFilterDropSummary(filterIntentDropSummaryFS, filterIntentKey)
  if filterIntentDropSummaryFS then
    filterIntentDropSummaryFS:SetText(CEF.intentFilterOptionRichText(filterIntentKey))
  end
end

function UI.updateRoleFilterDropSummary(filterRoleDropSummaryFS, filterRoleKey)
  if filterRoleDropSummaryFS then
    filterRoleDropSummaryFS:SetText(CEF.roleFilterOptionRichText(filterRoleKey))
  end
end

