-- Módulo: UI da aba Home — distribuição Chat + Premade.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.HomeUI = CEF.HomeUI or {}
local GUI = CEF.HomeUI

local PAD = 12
local CARD_GAP = 10
local ROW_H = 22
local BAR_H = 8
local MAX_ROWS = 10

local function L(key, fallback)
  if CEF.L and CEF.L[key] then
    return CEF.L[key]
  end
  return fallback or key
end

local function makeCard(parent, title)
  local card = CreateFrame("Frame", nil, parent)
  local bg = card:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.09, 0.08, 0.07, 0.96)
  local edge = card:CreateTexture(nil, "BORDER")
  edge:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
  edge:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
  edge:SetHeight(1)
  edge:SetColorTexture(0.35, 0.28, 0.14, 0.9)

  local titleFs = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleFs:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
  titleFs:SetTextColor(1, 0.82, 0.35)
  titleFs:SetText(title or "")
  card.titleFs = titleFs

  local subFs = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  subFs:SetPoint("TOPLEFT", titleFs, "BOTTOMLEFT", 0, -2)
  subFs:SetPoint("RIGHT", card, "RIGHT", -10, 0)
  subFs:SetJustifyH("LEFT")
  subFs:SetText("")
  card.subFs = subFs

  local emptyFs = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  emptyFs:SetPoint("TOPLEFT", subFs, "BOTTOMLEFT", 0, -16)
  emptyFs:SetPoint("RIGHT", card, "RIGHT", -10, 0)
  emptyFs:SetJustifyH("LEFT")
  emptyFs:Hide()
  card.emptyFs = emptyFs

  card.rows = {}
  for i = 1, MAX_ROWS do
    local row = CreateFrame("Frame", nil, card)
    row:SetHeight(ROW_H)
    row:SetPoint("LEFT", card, "LEFT", 10, 0)
    row:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    if i == 1 then
      row:SetPoint("TOP", subFs, "BOTTOM", 0, -12)
    else
      row:SetPoint("TOP", card.rows[i - 1], "BOTTOM", 0, -4)
    end

    local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameFs:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    nameFs:SetPoint("RIGHT", row, "RIGHT", -36, 0)
    nameFs:SetJustifyH("LEFT")
    nameFs:SetWordWrap(false)
    row.nameFs = nameFs

    local countFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countFs:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    countFs:SetJustifyH("RIGHT")
    countFs:SetTextColor(0.85, 0.78, 0.55)
    row.countFs = countFs

    local track = row:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 1)
    track:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
    track:SetHeight(BAR_H)
    track:SetColorTexture(0.15, 0.13, 0.11, 1)
    row.track = track

    local fill = row:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetHeight(BAR_H)
    fill:SetWidth(1)
    fill:SetColorTexture(0.85, 0.65, 0.18, 0.95)
    row.fill = fill

    row:Hide()
    card.rows[i] = row
  end

  return card
end

local function paintBarRows(card, items, emptyText)
  local maxTotal = 1
  for _, it in ipairs(items or {}) do
    if (it.total or 0) > maxTotal then
      maxTotal = it.total
    end
  end

  local has = items and #items > 0
  if card.emptyFs then
    if has then
      card.emptyFs:Hide()
    else
      card.emptyFs:SetText(emptyText or "")
      card.emptyFs:Show()
    end
  end

  for i = 1, MAX_ROWS do
    local row = card.rows[i]
    local it = items and items[i]
    if it then
      row.nameFs:SetText(it.label or it.key or "")
      row.nameFs:SetTextColor(1, 1, 1)
      row.countFs:SetText(tostring(it.total or 0))
      local w = row.track:GetWidth() or 100
      if w < 8 then
        w = 100
      end
      local frac = (it.total or 0) / maxTotal
      row.fill:SetWidth(math.max(2, w * frac))
      row.fill:SetColorTexture(0.85, 0.65, 0.18, 0.95)
      row:Show()
    else
      row:Hide()
    end
  end
end

function GUI.refresh()
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not f.homeRoot then
    return
  end
  if not CEF.Home or not CEF.Home.buildSnapshot then
    return
  end
  local snap = CEF.Home.buildSnapshot()

  if f.homeSummaryFs then
    local seeking = (snap.intent and snap.intent.invite) or 0
    local recruiting = (snap.intent and snap.intent.whisper) or 0
    f.homeSummaryFs:SetText(CEF.L and CEF.L(
      "HOME_SUMMARY_FMT",
      snap.chatCount or 0,
      snap.lfgCount or 0,
      seeking,
      recruiting
    ) or string.format(
      "Chat %d · Premade %d · Looking for group %d · Recruiting %d",
      snap.chatCount or 0,
      snap.lfgCount or 0,
      seeking,
      recruiting
    ))
  end

  paintBarRows(f.homeInstCard, snap.instances, L("HOME_EMPTY_INSTANCES", "No instance activity yet."))
  paintBarRows(f.homeRoleCard, snap.roles, L("HOME_EMPTY_ROLES", "No role demand detected yet."))

  if f.homeInstCard and f.homeInstCard.subFs then
    f.homeInstCard.subFs:SetText(L("HOME_INSTANCES_SUB", "Mentions in chat + Premade listings"))
  end
  if f.homeRoleCard and f.homeRoleCard.subFs then
    f.homeRoleCard.subFs:SetText(L("HOME_ROLES_SUB", "Chat asks + open Premade slots"))
  end
end

local function layoutHome(f)
  local root = f.homeRoot
  if not root then
    return
  end
  local w = root:GetWidth() or 900
  local h = root:GetHeight() or 480
  if w < 100 or h < 100 then
    return
  end

  local summaryH = 36
  if f.homeSummaryBar then
    f.homeSummaryBar:ClearAllPoints()
    f.homeSummaryBar:SetPoint("TOPLEFT", root, "TOPLEFT", PAD, -PAD)
    f.homeSummaryBar:SetPoint("TOPRIGHT", root, "TOPRIGHT", -PAD, -PAD)
    f.homeSummaryBar:SetHeight(summaryH)
  end

  local top = PAD + summaryH + CARD_GAP
  local cardH = math.max(180, h - top - PAD)
  local innerW = w - 2 * PAD
  local cardW = math.floor((innerW - CARD_GAP) / 2)

  local cards = { f.homeInstCard, f.homeRoleCard }
  for i, card in ipairs(cards) do
    if card then
      card:ClearAllPoints()
      card:SetSize(cardW, cardH)
      card:SetPoint("TOPLEFT", root, "TOPLEFT", PAD + (i - 1) * (cardW + CARD_GAP), -top)
    end
  end
end

function GUI.createPanels(f, navBar)
  local root = CreateFrame("Frame", nil, f)
  root:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  root:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 4)
  root:Hide()
  f.homeRoot = root

  local bg = root:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.045, 0.05, 0.92)

  local summaryBar = CreateFrame("Frame", nil, root)
  summaryBar:SetHeight(36)
  local sbg = summaryBar:CreateTexture(nil, "BACKGROUND")
  sbg:SetAllPoints()
  sbg:SetColorTexture(0.1, 0.09, 0.08, 0.95)
  f.homeSummaryBar = summaryBar

  local summaryFs = summaryBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summaryFs:SetPoint("LEFT", summaryBar, "LEFT", 12, 0)
  summaryFs:SetPoint("RIGHT", summaryBar, "RIGHT", -12, 0)
  summaryFs:SetJustifyH("LEFT")
  f.homeSummaryFs = summaryFs

  local refreshBtn = CreateFrame("Button", nil, summaryBar)
  refreshBtn:SetSize(88, 22)
  refreshBtn:SetPoint("RIGHT", summaryBar, "RIGHT", -8, 0)
  local rbg = refreshBtn:CreateTexture(nil, "BACKGROUND")
  rbg:SetAllPoints()
  rbg:SetColorTexture(0.18, 0.15, 0.1, 1)
  local rfs = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  rfs:SetAllPoints()
  rfs:SetText(L("LFG_REFRESH", "Refresh"))
  refreshBtn.fs = rfs
  refreshBtn:SetScript("OnClick", function()
    if CEF.LFG and CEF.LFG.search then
      CEF.LFG.search()
    end
    GUI.refresh()
  end)
  f.homeRefreshBtn = refreshBtn

  summaryFs:ClearAllPoints()
  summaryFs:SetPoint("LEFT", summaryBar, "LEFT", 12, 0)
  summaryFs:SetPoint("RIGHT", refreshBtn, "LEFT", -8, 0)

  f.homeInstCard = makeCard(root, L("HOME_INSTANCES_TITLE", "Top instances"))
  f.homeRoleCard = makeCard(root, L("HOME_ROLES_TITLE", "Roles in demand"))

  root:SetScript("OnSizeChanged", function()
    layoutHome(f)
    GUI.refresh()
  end)
  root:SetScript("OnShow", function()
    layoutHome(f)
    GUI.refresh()
  end)

  f.cefApplyHomeLocale = function()
    if f.homeInstCard and f.homeInstCard.titleFs then
      f.homeInstCard.titleFs:SetText(L("HOME_INSTANCES_TITLE", "Top instances"))
    end
    if f.homeRoleCard and f.homeRoleCard.titleFs then
      f.homeRoleCard.titleFs:SetText(L("HOME_ROLES_TITLE", "Roles in demand"))
    end
    if f.homeRefreshBtn and f.homeRefreshBtn.fs then
      f.homeRefreshBtn.fs:SetText(L("LFG_REFRESH", "Refresh"))
    end
    GUI.refresh()
  end

  layoutHome(f)

  if CEF.LFG and CEF.LFG.onChanged then
    CEF.LFG.onChanged(function()
      local mf = CEF.UI and CEF.UI.mainFrame
      if mf and mf:IsShown() and mf.cefNavTab == "home" then
        GUI.refresh()
      end
    end)
  end
end
