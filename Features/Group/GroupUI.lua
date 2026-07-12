-- Módulo: UI da aba Grupo — quadro de blocos por subgrupo (estilo janela de raide da Blizzard).
-- Cada subgrupo é um bloco com 5 vagas; sem tabela nem scroll.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.GroupUI = CEF.GroupUI or {}
local GUI = CEF.GroupUI

local INFO_BAR_H = 30
local SLOTS_PER_GROUP = 5
local BLOCK_TITLE_H = 20
local BLOCK_PAD = 4
local BLOCK_GAP = 8
local SLOT_GAP = 2
local MIN_BLOCK_W = 150
local MAX_COLS = 4
local PARTY_BLOCK_MAX_W = 340

function GUI.refresh()
  GUI.layoutBoard()
  GUI.updateEmptyState()
  GUI.updateInfoBar()
end

function GUI.updateInfoBar()
  local ui = CEF.UI or {}
  local fs = ui.groupInfoLabel
  if fs then
    local text = CEF.Group.summaryRichText()
    if CEF.Group.canEditRaid and CEF.Group.canEditRaid() then
      text = text .. "  |cffaaaaaa·|r  |cff888888" .. CEF.L.GROUP_EDIT_HINT .. "|r"
    end
    fs:SetText(text)
  end
end

function GUI.updateEmptyState()
  local ui = CEF.UI or {}
  local empty = ui.groupEmptyLabel
  if not empty then
    return
  end
  if not CEF.Group.isInGroup() or #(CEF.Group.getMembers() or {}) == 0 then
    empty:SetText(CEF.L.GROUP_EMPTY_NOT_IN_GROUP)
    empty:Show()
  else
    empty:Hide()
  end
end

-- ===== Feedback de ações (erros de permissão/combate/grupo cheio) =====

local function notifyActionError(errKey, ...)
  if not errKey then
    return
  end
  local msg = CEF.L(errKey, ...)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66CEF:|r " .. msg)
  end
end

-- ===== Chrome partilhado (fundo escuro + borda dourada) =====

local function makeMenuChrome(frame)
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.05, 0.048, 0.06, 0.99)
  local br, bgc, bb, ba = 0.55, 0.45, 0.18, 0.85
  local function edge(isH, point1, point2)
    local t = frame:CreateTexture(nil, "BORDER")
    if isH then
      t:SetHeight(1)
    else
      t:SetWidth(1)
    end
    t:SetColorTexture(br, bgc, bb, ba)
    t:SetPoint(point1, frame, point1, 0, 0)
    t:SetPoint(point2, frame, point2, 0, 0)
  end
  edge(true, "TOPLEFT", "TOPRIGHT")
  edge(true, "BOTTOMLEFT", "BOTTOMRIGHT")
  edge(false, "TOPLEFT", "BOTTOMLEFT")
  edge(false, "TOPRIGHT", "BOTTOMRIGHT")
end

-- ===== Menu de contexto (sussurrar, liderança, assistente, remover) =====

local CTX_W = 190
local CTX_ROW_H = 22
local CTX_HEADER_H = 22
local CTX_PAD = 4

function GUI.hideMemberContextMenu()
  local f = CEF.UI and CEF.UI.mainFrame
  if f and f.groupMemberContextMenu then
    f.groupMemberContextMenu:Hide()
  end
  if f and f.cefGroupContextOutsideCloser then
    f.cefGroupContextOutsideCloser:Hide()
  end
  if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
    CEF.UIFilters.syncFilterDropBlocker(f)
  end
end

local function ensureGroupContextOutsideCloser(f)
  if f.cefGroupContextOutsideCloser then
    return f.cefGroupContextOutsideCloser
  end
  local closer = CreateFrame("Button", nil, f)
  closer:Hide()
  closer:SetAllPoints(f)
  closer:SetFrameLevel(500)
  closer:EnableMouse(true)
  closer:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local tex = closer:CreateTexture(nil, "BACKGROUND")
  tex:SetAllPoints()
  tex:SetColorTexture(0, 0, 0, 0.001)
  closer:SetScript("OnClick", function()
    GUI.hideMemberContextMenu()
  end)
  f.cefGroupContextOutsideCloser = closer
  return closer
end

local function ensureGroupContextMenu(f)
  if f.groupMemberContextMenu then
    return f.groupMemberContextMenu
  end
  local menu = CreateFrame("Frame", nil, f)
  menu:SetSize(CTX_W, 100)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(560)
  menu:EnableMouse(true)
  menu:Hide()
  makeMenuChrome(menu)
  f.groupMemberContextMenu = menu

  local headerBg = menu:CreateTexture(nil, "BACKGROUND")
  headerBg:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1)
  headerBg:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1)
  headerBg:SetHeight(CTX_HEADER_H)
  headerBg:SetColorTexture(0.12, 0.1, 0.08, 1)

  local headerFs = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  headerFs:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -1)
  headerFs:SetPoint("BOTTOMRIGHT", menu, "TOPRIGHT", -10, -1 - CTX_HEADER_H)
  headerFs:SetJustifyH("LEFT")
  headerFs:SetJustifyV("MIDDLE")
  headerFs:SetText("")
  menu.headerFs = headerFs

  local sep = menu:CreateTexture(nil, "ARTWORK")
  sep:SetHeight(1)
  sep:SetColorTexture(0.55, 0.45, 0.18, 0.7)
  sep:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1 - CTX_HEADER_H)
  sep:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -1, -1 - CTX_HEADER_H)

  local function makeCtxRow()
    local row = CreateFrame("Button", nil, menu)
    row:SetHeight(CTX_ROW_H)
    row:RegisterForClicks("LeftButtonUp")
    row:EnableMouse(true)
    local rb = row:CreateTexture(nil, "BACKGROUND")
    rb:SetAllPoints()
    rb:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    row.bg = rb
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", row, "LEFT", 8, 0)
    fs:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(1, 0.92, 0.55)
    row.label = fs
    row:SetScript("OnEnter", function(self)
      self.bg:SetColorTexture(0.22, 0.18, 0.12, 1)
    end)
    row:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    end)
    row:Hide()
    return row
  end

  menu.whisperRow = makeCtxRow()
  menu.leaderRow = makeCtxRow()
  menu.assistRow = makeCtxRow()
  menu.kickRow = makeCtxRow()

  local function runAction(fn)
    local m = menu.cefMember
    GUI.hideMemberContextMenu()
    if not m then
      return
    end
    local ok, errKey = fn(m)
    if not ok and errKey then
      notifyActionError(errKey)
    end
  end

  menu.whisperRow:SetScript("OnClick", function()
    local m = menu.cefMember
    GUI.hideMemberContextMenu()
    if not m or not m.name or m.name == "" or m.isSelf then
      return
    end
    if CEF.UI and CEF.UI.openWhisperInHub then
      CEF.UI.openWhisperInHub(m.nameShort or m.name)
    end
  end)
  menu.leaderRow:SetScript("OnClick", function()
    runAction(CEF.Group.promoteToLeader)
  end)
  menu.assistRow:SetScript("OnClick", function()
    local m = menu.cefMember
    if m and m.isAssist then
      runAction(CEF.Group.demoteFromAssistant)
    else
      runAction(CEF.Group.promoteToAssistant)
    end
  end)
  menu.kickRow:SetScript("OnClick", function()
    runAction(CEF.Group.removeFromGroup)
  end)

  return menu
end

function GUI.showMemberContextMenu(member)
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not member then
    return
  end
  if CEF.UIFilters and CEF.UIFilters.hideAllFilterDropdowns then
    CEF.UIFilters.hideAllFilterDropdowns(f)
  end
  local menu = ensureGroupContextMenu(f)
  menu.cefMember = member

  local colorTag = "|cffffffff"
  if CEF.Guild and CEF.Guild.classColorPrefix then
    colorTag = CEF.Guild.classColorPrefix(member.classFile)
  end
  menu.headerFs:SetText(colorTag .. (member.nameShort or member.name or "") .. "|r")

  local isLeader = CEF.Group.playerIsLeader()
  local isAssist = CEF.Group.playerIsAssist()
  local inRaid = CEF.Group.isRaid()

  menu.whisperRow.label:SetText(CEF.L.WHISPER)
  menu.leaderRow.label:SetText(CEF.L.GROUP_CTX_PROMOTE_LEADER)
  menu.assistRow.label:SetText(member.isAssist and CEF.L.GROUP_CTX_DEMOTE_ASSIST or CEF.L.GROUP_CTX_PROMOTE_ASSIST)
  menu.kickRow.label:SetText(CEF.L.GROUP_CTX_KICK)

  -- Só mostra o que o jogador realmente pode fazer com este alvo.
  local rows = {}
  if not member.isSelf then
    rows[#rows + 1] = menu.whisperRow
  end
  if isLeader and not member.isSelf then
    rows[#rows + 1] = menu.leaderRow
  end
  if isLeader and inRaid and not member.isSelf and not member.isLeader then
    rows[#rows + 1] = menu.assistRow
  end
  if (isLeader or isAssist) and not member.isSelf and not member.isLeader then
    rows[#rows + 1] = menu.kickRow
  end
  if #rows == 0 then
    return
  end

  menu.whisperRow:Hide()
  menu.leaderRow:Hide()
  menu.assistRow:Hide()
  menu.kickRow:Hide()
  local y = -1 - CTX_HEADER_H - 1 - CTX_PAD
  for _, row in ipairs(rows) do
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, y)
    row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, y)
    row.bg:SetColorTexture(0.13, 0.11, 0.09, 0.96)
    row:Show()
    y = y - CTX_ROW_H
  end
  local menuH = CTX_PAD * 2 + CTX_HEADER_H + 1 + CTX_ROW_H * #rows
  menu:SetSize(CTX_W, menuH)

  menu:ClearAllPoints()
  local scale = UIParent:GetEffectiveScale() or 1
  if scale < 0.01 then
    scale = 1
  end
  local cx, cy = GetCursorPosition()
  local x, yy = cx / scale, cy / scale
  local uiW = UIParent:GetWidth() or 1024
  if x + CTX_W > uiW then
    x = uiW - CTX_W - 4
  end
  if yy - menuH < 0 then
    yy = menuH + 4
  end
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, yy)

  local closer = ensureGroupContextOutsideCloser(f)
  closer:SetFrameLevel(500)
  closer:Show()
  menu:SetFrameLevel(560)
  menu:Show()
  if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
    CEF.UIFilters.syncFilterDropBlocker(f)
  end
end

-- ===== Vagas: pintura e tooltip =====

local function paintSlotBg(slot)
  if not slot or not slot.bg then
    return
  end
  if slot.cefMember then
    slot.bg:SetColorTexture(0.1, 0.1, 0.12, 0.9)
  else
    slot.bg:SetColorTexture(0.07, 0.07, 0.085, 0.55)
  end
end

local function paintSlot(slot, m, subgroup)
  slot.cefMember = m
  slot.cefSubgroup = subgroup
  if m then
    slot.nameFs:SetText(CEF.Group.nameRichText(m))
    slot.nameFs:SetAlpha(m.online and 1 or 0.45)
    if CEF.Guild and CEF.Guild.levelColorRichText then
      slot.rightFs:SetText(CEF.Guild.levelColorRichText(m.level))
    else
      slot.rightFs:SetText(tostring(m.level or ""))
    end
    slot.rightFs:SetAlpha(m.online and 1 or 0.45)
    -- Ponto de estado: verde vivo, vermelho morto, cinza offline (texto no tooltip).
    if not m.online then
      slot.statusDot:SetColorTexture(0.45, 0.45, 0.45, 1)
    elseif m.isDead then
      slot.statusDot:SetColorTexture(0.95, 0.25, 0.2, 1)
    else
      slot.statusDot:SetColorTexture(0.3, 0.9, 0.3, 1)
    end
    slot.statusDot:Show()
  else
    slot.nameFs:SetText("|cff4a4a4a—|r")
    slot.nameFs:SetAlpha(1)
    slot.rightFs:SetText("")
    slot.statusDot:Hide()
  end
  paintSlotBg(slot)
end

local function showSlotTooltip(slot)
  local m = slot.cefMember
  if not m or not GameTooltip then
    return
  end
  GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(CEF.Group.nameRichText(m))
  local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[m.classFile]) or m.classFile or ""
  GameTooltip:AddLine(CEF.L.COL_LEVEL .. " " .. tostring(m.level or "?") .. "  ·  " .. className, 0.9, 0.9, 0.9)
  GameTooltip:AddLine(CEF.Group.roleRichText(m))
  local zone = m.zone or ""
  if zone ~= "" then
    GameTooltip:AddLine((CEF.getZoneDisplayName and CEF.getZoneDisplayName(zone)) or zone, 0.7, 0.7, 0.7)
  end
  GameTooltip:AddLine(CEF.Group.statusRichText(m))
  GameTooltip:Show()
end

-- ===== Drag & drop de membros entre blocos (só raid, líder/assistente) =====

local drag = {
  pending = false, -- botão pressionado, aguardando ultrapassar o limiar
  active = false, -- ghost visível, a arrastar de facto
  memberName = nil,
  startX = 0,
  startY = 0,
  hoverBlock = nil,
  hoverSlot = nil,
}

local DRAG_THRESHOLD = 6

local function cursorUiXY()
  local scale = UIParent:GetEffectiveScale() or 1
  if scale < 0.01 then
    scale = 1
  end
  local cx, cy = GetCursorPosition()
  return cx / scale, cy / scale
end

local function findMemberByName(name)
  if not name then
    return nil
  end
  for _, m in ipairs(CEF.Group.getMembers() or {}) do
    if m.name == name then
      return m
    end
  end
  return nil
end

local function ensureDragGhost()
  local ui = CEF.UI or {}
  if ui.groupDragGhost then
    return ui.groupDragGhost
  end
  local ghost = CreateFrame("Frame", nil, UIParent)
  ghost:SetSize(180, 24)
  ghost:SetFrameStrata("TOOLTIP")
  ghost:SetFrameLevel(600)
  ghost:EnableMouse(false)
  ghost:Hide()
  makeMenuChrome(ghost)
  local fs = ghost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", ghost, "LEFT", 8, 0)
  fs:SetPoint("RIGHT", ghost, "RIGHT", -8, 0)
  fs:SetJustifyH("LEFT")
  ghost.label = fs
  CEF.UI.groupDragGhost = ghost
  return ghost
end

local function clearDragHover()
  if drag.hoverBlock and drag.hoverBlock.dropHl then
    drag.hoverBlock.dropHl:Hide()
  end
  if drag.hoverSlot then
    paintSlotBg(drag.hoverSlot)
  end
  drag.hoverBlock = nil
  drag.hoverSlot = nil
end

-- Bloco (e vaga, se houver) sob o cursor — alvo do drop.
local function dropTargetUnderCursor()
  local ui = CEF.UI or {}
  local board = ui.groupBoard
  if not board or not board:IsShown() or not board:IsMouseOver() then
    return nil, nil
  end
  for g = 1, 8 do
    local b = board.blocks and board.blocks[g]
    if b and b:IsShown() and b:IsMouseOver() then
      for _, slot in ipairs(b.slots) do
        if slot:IsMouseOver() then
          return b, slot
        end
      end
      return b, nil
    end
  end
  return nil, nil
end

-- Semântica do drop (igual à janela de raide da Blizzard):
-- grupo com vaga → move; em cima de um membro (grupo cheio ou o próprio) → troca os dois.
local function performDrop(block, slotHit)
  local src = findMemberByName(drag.memberName)
  if not src or not block or not CEF.Group.isRaid() then
    return
  end
  local targetSubgroup = block.cefSubgroup
  if not targetSubgroup then
    return
  end
  if targetSubgroup == src.subgroup then
    -- Reordenar dentro do próprio grupo: soltar num membro troca as posições.
    if slotHit and slotHit.cefMember and slotHit.cefMember.name ~= src.name then
      local ok, errKey = CEF.Group.swapMembers(src, slotHit.cefMember)
      if not ok and errKey then
        notifyActionError(errKey)
      end
    end
    return
  end
  if CEF.Group.subgroupCount(targetSubgroup) < 5 then
    local ok, errKey = CEF.Group.moveToSubgroup(src, targetSubgroup)
    if not ok and errKey then
      notifyActionError(errKey, targetSubgroup)
    end
  elseif slotHit and slotHit.cefMember then
    local ok, errKey = CEF.Group.swapMembers(src, slotHit.cefMember)
    if not ok and errKey then
      notifyActionError(errKey)
    end
  else
    notifyActionError("GROUP_ERR_FULL", targetSubgroup)
  end
end

local function stopDrag(doDrop)
  local ui = CEF.UI or {}
  local targetBlock, targetSlot
  if doDrop and drag.active then
    targetBlock, targetSlot = dropTargetUnderCursor()
  end
  clearDragHover()
  if ui.groupDragGhost then
    ui.groupDragGhost:Hide()
  end
  if ui.groupDragDriver then
    ui.groupDragDriver:SetScript("OnUpdate", nil)
    ui.groupDragDriver:Hide()
  end
  local wasActive = drag.active
  drag.pending = false
  drag.active = false
  if wasActive and targetBlock then
    performDrop(targetBlock, targetSlot)
  end
  drag.memberName = nil
end

local function dragOnUpdate()
  if not IsMouseButtonDown("LeftButton") then
    stopDrag(true)
    return
  end
  local ui = CEF.UI or {}
  if not (ui.groupBoard and ui.groupBoard:IsShown()) then
    stopDrag(false)
    return
  end
  local x, y = cursorUiXY()
  if drag.pending and not drag.active then
    local dx = x - drag.startX
    local dy = y - drag.startY
    if (dx * dx + dy * dy) < (DRAG_THRESHOLD * DRAG_THRESHOLD) then
      return
    end
    drag.active = true
    if GameTooltip then
      GameTooltip:Hide()
    end
    local ghost = ensureDragGhost()
    local m = findMemberByName(drag.memberName)
    ghost.label:SetText(m and CEF.Group.nameRichText(m) or drag.memberName or "")
    ghost:Show()
  end
  if not drag.active then
    return
  end
  local ghost = ensureDragGhost()
  ghost:ClearAllPoints()
  ghost:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + 14, y - 10)

  -- Realce do alvo: bloco inteiro para outro grupo (+ vaga se cheio);
  -- só a vaga quando é reordenação dentro do próprio grupo.
  local block, slot = dropTargetUnderCursor()
  local src = findMemberByName(drag.memberName)
  if block ~= drag.hoverBlock or slot ~= drag.hoverSlot then
    clearDragHover()
    if block and src then
      if block.cefSubgroup ~= src.subgroup then
        drag.hoverBlock = block
        if slot and slot.cefMember and CEF.Group.subgroupCount(block.cefSubgroup) >= 5 then
          drag.hoverSlot = slot
        end
      elseif slot and slot.cefMember and slot.cefMember.name ~= src.name then
        drag.hoverSlot = slot
      end
    end
  end
  -- Reaplica a cada frame: um refresh do roster no meio do arrasto reseta os fundos.
  if drag.hoverBlock and drag.hoverBlock.dropHl then
    drag.hoverBlock.dropHl:Show()
  end
  if drag.hoverSlot and drag.hoverSlot.bg then
    drag.hoverSlot.bg:SetColorTexture(0.38, 0.28, 0.1, 1)
  end
end

local function startDragTracking(member)
  local ui = CEF.UI or {}
  if not ui.groupDragDriver then
    local driver = CreateFrame("Frame", nil, UIParent)
    driver:Hide()
    CEF.UI.groupDragDriver = driver
  end
  drag.pending = true
  drag.active = false
  drag.memberName = member.name
  drag.startX, drag.startY = cursorUiXY()
  drag.hoverBlock = nil
  drag.hoverSlot = nil
  local driver = CEF.UI.groupDragDriver
  driver:Show()
  driver:SetScript("OnUpdate", dragOnUpdate)
end

-- ===== Rato nas vagas: hover/tooltip, clique direito (menu) e arrasto (esquerdo) =====

local function bindSlotMouse(slot)
  slot:EnableMouse(true)
  slot:SetScript("OnEnter", function(self)
    if drag.active or not self.cefMember then
      return
    end
    if self.bg then
      self.bg:SetColorTexture(0.15, 0.13, 0.1, 0.95)
    end
    showSlotTooltip(self)
  end)
  slot:SetScript("OnLeave", function(self)
    if GameTooltip then
      GameTooltip:Hide()
    end
    if drag.active then
      return
    end
    paintSlotBg(self)
  end)
  slot:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" or not self.cefMember then
      return
    end
    if not (CEF.Group.canEditRaid and CEF.Group.canEditRaid()) then
      return
    end
    startDragTracking(self.cefMember)
  end)
  slot:SetScript("OnMouseUp", function(self, button)
    if button ~= "RightButton" then
      return
    end
    if drag.pending or drag.active then
      stopDrag(false)
      return
    end
    if self.cefMember then
      GUI.showMemberContextMenu(self.cefMember)
    end
  end)
end

-- ===== Blocos de subgrupo =====

local function makeSlot(block)
  local slot = CreateFrame("Frame", nil, block)
  slot:SetHeight(20)
  local bg = slot:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  slot.bg = bg
  local dot = slot:CreateTexture(nil, "OVERLAY")
  dot:SetSize(7, 7)
  dot:SetPoint("RIGHT", slot, "RIGHT", -6, 0)
  dot:Hide()
  slot.statusDot = dot
  local rightFs = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  rightFs:SetPoint("RIGHT", slot, "RIGHT", -18, 0)
  rightFs:SetJustifyH("RIGHT")
  rightFs:SetWordWrap(false)
  slot.rightFs = rightFs
  local nameFs = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  nameFs:SetPoint("LEFT", slot, "LEFT", 6, 0)
  nameFs:SetPoint("RIGHT", slot, "RIGHT", -44, 0)
  nameFs:SetJustifyH("LEFT")
  nameFs:SetWordWrap(false)
  slot.nameFs = nameFs
  bindSlotMouse(slot)
  return slot
end

local function ensureBlocks(board)
  if board.blocks then
    return
  end
  board.blocks = {}
  for g = 1, 8 do
    local b = CreateFrame("Frame", nil, board)
    b.cefSubgroup = g
    makeMenuChrome(b)

    local titleBg = b:CreateTexture(nil, "BORDER")
    titleBg:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    titleBg:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
    titleBg:SetHeight(BLOCK_TITLE_H)
    titleBg:SetColorTexture(0.14, 0.12, 0.08, 1)

    local titleFs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleFs:SetPoint("TOPLEFT", b, "TOPLEFT", 7, -1)
    titleFs:SetHeight(BLOCK_TITLE_H)
    titleFs:SetJustifyH("LEFT")
    titleFs:SetJustifyV("MIDDLE")
    b.titleFs = titleFs

    local countFs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    countFs:SetPoint("TOPRIGHT", b, "TOPRIGHT", -7, -1)
    countFs:SetHeight(BLOCK_TITLE_H)
    countFs:SetJustifyH("RIGHT")
    countFs:SetJustifyV("MIDDLE")
    b.countFs = countFs

    -- Realce de alvo durante o drag (véu âmbar acima das vagas; não captura o rato).
    local hlFrame = CreateFrame("Frame", nil, b)
    hlFrame:SetAllPoints()
    hlFrame:SetFrameLevel((b:GetFrameLevel() or 0) + 10)
    hlFrame:EnableMouse(false)
    local hlTex = hlFrame:CreateTexture(nil, "OVERLAY")
    hlTex:SetAllPoints()
    hlTex:SetColorTexture(1, 0.82, 0.2, 0.1)
    hlFrame:Hide()
    b.dropHl = hlFrame

    b.slots = {}
    for s = 1, SLOTS_PER_GROUP do
      b.slots[s] = makeSlot(b)
    end
    b:Hide()
    board.blocks[g] = b
  end
end

-- Membros agrupados por subgrupo (party → tudo no bucket 1).
-- Em raid respeita a ordem do roster (raidIndex), igual à janela da Blizzard —
-- é ela que o líder reordena com o drag dentro do próprio grupo.
local function membersBySubgroup()
  local buckets = {}
  for g = 1, 8 do
    buckets[g] = {}
  end
  local isRaid = CEF.Group.isRaid()
  for _, m in ipairs(CEF.Group.getMembers() or {}) do
    local g = 1
    if isRaid then
      g = math.max(1, math.min(8, tonumber(m.subgroup) or 1))
    end
    local bucket = buckets[g]
    bucket[#bucket + 1] = m
  end
  for g = 1, 8 do
    if isRaid then
      table.sort(buckets[g], function(a, b)
        return (a.raidIndex or 0) < (b.raidIndex or 0)
      end)
    else
      table.sort(buckets[g], function(a, b)
        if a.isLeader ~= b.isLeader then
          return a.isLeader
        end
        return strlower(a.nameShort or "") < strlower(b.nameShort or "")
      end)
    end
  end
  return buckets
end

function GUI.layoutBoard()
  local ui = CEF.UI or {}
  local board = ui.groupBoard
  if not board or not board.blocks then
    return
  end
  local w = board:GetWidth() or 0
  local h = board:GetHeight() or 0
  if w < 60 or h < 40 then
    return
  end

  local inGroup = CEF.Group.isInGroup() and #(CEF.Group.getMembers() or {}) > 0
  if not inGroup then
    for g = 1, 8 do
      board.blocks[g]:Hide()
    end
    return
  end

  local isRaid = CEF.Group.isRaid()
  local blocksN = isRaid and 8 or 1
  local buckets = membersBySubgroup()

  local cols, rows
  if blocksN == 1 then
    cols, rows = 1, 1
  else
    local colsByWidth = math.max(1, math.floor((w + BLOCK_GAP) / (MIN_BLOCK_W + BLOCK_GAP)))
    cols = math.min(MAX_COLS, colsByWidth)
    rows = math.ceil(blocksN / cols)
    -- Janela baixa: mais colunas (blocos mais estreitos) para não estourar na vertical.
    local minBlockH = BLOCK_TITLE_H + 2 * BLOCK_PAD + SLOTS_PER_GROUP * 14 + (SLOTS_PER_GROUP - 1) * SLOT_GAP
    local maxRows = math.max(1, math.floor((h + BLOCK_GAP) / (minBlockH + BLOCK_GAP)))
    if rows > maxRows then
      cols = math.max(cols, math.min(colsByWidth, math.ceil(blocksN / maxRows)))
      rows = math.ceil(blocksN / cols)
    end
  end

  local blockW = (w - (cols - 1) * BLOCK_GAP) / cols
  if blocksN == 1 then
    blockW = math.min(blockW, PARTY_BLOCK_MAX_W)
  end
  -- Altura da vaga adapta-se ao espaço; o bloco encolhe/estica com a janela.
  local blockHAvail = (h - (rows - 1) * BLOCK_GAP) / rows
  local slotH = (blockHAvail - BLOCK_TITLE_H - 2 * BLOCK_PAD - (SLOTS_PER_GROUP - 1) * SLOT_GAP) / SLOTS_PER_GROUP
  slotH = math.max(14, math.min(26, math.floor(slotH)))
  local blockH = BLOCK_TITLE_H + 2 * BLOCK_PAD + SLOTS_PER_GROUP * slotH + (SLOTS_PER_GROUP - 1) * SLOT_GAP

  local xOff = 0
  if blocksN == 1 then
    xOff = math.max(0, (w - blockW) / 2)
  end

  for g = 1, 8 do
    local b = board.blocks[g]
    if g > blocksN then
      b:Hide()
    else
      local col = (g - 1) % cols
      local row = math.floor((g - 1) / cols)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", board, "TOPLEFT", xOff + col * (blockW + BLOCK_GAP), -(row * (blockH + BLOCK_GAP)))
      b:SetSize(blockW, blockH)

      if isRaid then
        b.titleFs:SetText("|cffffcc66" .. CEF.L("GROUP_SUBGROUP_FMT", g) .. "|r")
      else
        b.titleFs:SetText("|cffffcc66" .. CEF.L.GROUP_TYPE_PARTY .. "|r")
      end
      local list = buckets[g]
      b.countFs:SetText("|cff777777" .. #list .. "/" .. SLOTS_PER_GROUP .. "|r")

      for s = 1, SLOTS_PER_GROUP do
        local slot = b.slots[s]
        local yTop = BLOCK_TITLE_H + BLOCK_PAD + (s - 1) * (slotH + SLOT_GAP)
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", b, "TOPLEFT", BLOCK_PAD + 1, -yTop)
        slot:SetPoint("TOPRIGHT", b, "TOPRIGHT", -(BLOCK_PAD + 1), -yTop)
        slot:SetHeight(slotH)
        paintSlot(slot, list[s], g)
      end
      b:Show()
    end
  end
end

-- ===== Criação dos painéis =====

function GUI.createPanels(f, navBar)
  CEF.UI = CEF.UI or {}

  -- Barra de resumo (tipo · membros · líder · dica de edição).
  local infoBar = CreateFrame("Frame", nil, f)
  infoBar:SetHeight(INFO_BAR_H)
  infoBar:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -4)
  infoBar:SetPoint("TOPRIGHT", navBar, "BOTTOMRIGHT", 0, -4)
  infoBar:EnableMouse(true)
  infoBar:Hide()
  local ibBg = infoBar:CreateTexture(nil, "BACKGROUND")
  ibBg:SetAllPoints()
  ibBg:SetColorTexture(0.07, 0.065, 0.08, 0.97)

  local infoLabel = infoBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  infoLabel:SetPoint("LEFT", infoBar, "LEFT", 12, 0)
  infoLabel:SetPoint("RIGHT", infoBar, "RIGHT", -12, 0)
  infoLabel:SetJustifyH("LEFT")
  infoLabel:SetText("")

  -- Quadro com os blocos de subgrupo (sem scroll: tudo visível de uma vez).
  local board = CreateFrame("Frame", nil, f)
  board:SetPoint("TOPLEFT", infoBar, "BOTTOMLEFT", 0, -8)
  board:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
  board:EnableMouse(false)
  board:Hide()
  ensureBlocks(board)

  local emptyLabel = board:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyLabel:SetPoint("CENTER", board, "CENTER", 0, 0)
  emptyLabel:SetText("")
  emptyLabel:Hide()

  CEF.UI.groupInfoBar = infoBar
  CEF.UI.groupInfoLabel = infoLabel
  CEF.UI.groupBoard = board
  CEF.UI.groupEmptyLabel = emptyLabel
  f.groupInfoBar = infoBar
  f.groupBoard = board

  -- Reagenda o layout no próximo frame (tamanho só estabiliza depois do resize).
  local layoutBoot = CreateFrame("Frame", nil, f)
  layoutBoot:Hide()
  local function scheduleGroupLayoutSync()
    layoutBoot:Show()
    layoutBoot:SetScript("OnUpdate", function(s)
      s:SetScript("OnUpdate", nil)
      s:Hide()
      if f.cefNavTab == "group" and f.cefSyncGroupLayout then
        f.cefSyncGroupLayout()
      end
    end)
  end
  f.cefScheduleGroupLayoutSync = scheduleGroupLayoutSync

  f.cefSyncGroupLayout = function()
    local bw = board:GetWidth() or 0
    local bh = board:GetHeight() or 0
    if bw < 60 or bh < 40 then
      scheduleGroupLayoutSync()
      return
    end
    GUI.refresh()
  end

  board:SetScript("OnSizeChanged", function()
    if f.cefNavTab == "group" then
      scheduleGroupLayoutSync()
    end
  end)

  board:SetScript("OnShow", function()
    scheduleGroupLayoutSync()
  end)

  f.cefApplyGroupLocale = function()
    GUI.refresh()
  end

  return {
    infoBar = infoBar,
    board = board,
  }
end
