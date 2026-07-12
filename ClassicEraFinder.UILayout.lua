-- Módulo: helpers de layout/altura e colunas para a tabela virtualizada.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UILayout = CEF.UILayout or {}
local UI = CEF.UILayout

local function cfg()
  return CEF.CONST
end

function UI.columnWidths(totalW)
  local CC = cfg()
  local innerTotal = math.max(280 + CC.INSTANCE_LEVELS_TO_MSG_GAP, totalW - 2 * CC.TABLE_PAD)
  local inner = innerTotal - CC.INSTANCE_LEVELS_TO_MSG_GAP
  -- Coluna 1 = nome da instância + níveis na mesma linha; c2 fica 0 (compat.).
  -- Ação fica enxuta (só cabe o botão); o espaço sobra para instância/níveis.
  local c1 = inner * 0.29
  local c2 = 0
  local c3 = inner * 0.31
  local c4 = inner * 0.17
  local c5 = inner * 0.12
  local c6 = inner * 0.11
  local x1 = CC.TABLE_PAD
  local x3 = x1 + c1 + CC.INSTANCE_LEVELS_TO_MSG_GAP
  local x4 = x3 + c3
  local x5 = x4 + c4
  local x6 = x5 + c5
  return c1, c2, c3, c4, c5, c6, x1, x1, x3, x4, x5, x6
end

function UI.entryMessageDisplayLineBudget(e)
  local n = CEF.entryInstancesLineCount(e)
  if n <= 1 then
    return 1
  end
  return math.min(5, n)
end

function UI.entryRowTotalHeight(e)
  local CC = cfg()
  local ni = CEF.entryInstancesLineCount(e)
  local nm = UI.entryMessageDisplayLineBudget(e)

  local instBlock = CC.ROW_HEIGHT
  if ni > 1 then
    -- Como usamos "\n\n" entre instâncias, o texto vira "2*ni - 1" linhas.
    instBlock = (2 * ni - 1) * CC.ROW_INSTANCE_LINE
  end

  local msgBlock = CC.ROW_HEIGHT
  if nm > 1 then
    msgBlock = nm * CC.MSG_CELL_LINE_HEIGHT + (nm - 1) * CC.MSG_CELL_LINE_LEADING
  end

  local edge = 2 * CC.ROW_EDGE_INSET_SINGLE
  if ni > 1 or nm > 1 then
    edge = 2 * CC.ROW_EDGE_INSET_MULTI
  end

  return math.max(CC.ROW_HEIGHT, instBlock, msgBlock) + edge
end

function UI.layoutHeaderColumns(header)
  if not header then
    return
  end
  local CC = cfg()
  local w = header:GetWidth()
  local sf = CEF.UI and CEF.UI.scrollFrame
  if sf and sf.GetWidth then
    local sw = sf:GetWidth()
    if sw and sw > 80 then
      w = sw
    end
  end
  local c1, c2, c3, c4, c5, c6, x1, x2, x3, x4, x5, x6 = UI.columnWidths(w)
  local w1 = math.max(100, c1 - CC.COL_GAP)
  local w3 = math.max(50, c3 - CC.COL_GAP)
  local w4 = math.max(36, c4 - CC.COL_GAP)
  local w5 = math.max(40, c5 - CC.COL_GAP)
  local w6 = math.max(56, c6 - CC.COL_GAP)

  header.h1:ClearAllPoints()
  header.h2:ClearAllPoints()
  header.h3:ClearAllPoints()
  header.h4:ClearAllPoints()
  header.h5:ClearAllPoints()
  header.h6:ClearAllPoints()

  header.h1:SetPoint("LEFT", header, "LEFT", x1, 0)
  header.h1:SetWidth(w1)
  header.h2:ClearAllPoints()
  header.h2:Hide()
  header.h3:SetPoint("LEFT", header, "LEFT", x3, 0)
  header.h3:SetWidth(w3)
  header.h4:SetPoint("LEFT", header, "LEFT", x4, 0)
  header.h4:SetWidth(w4)
  header.h5:SetPoint("LEFT", header, "LEFT", x5, 0)
  header.h5:SetWidth(w5)
  header.h6:SetPoint("LEFT", header, "LEFT", x6, 0)
  header.h6:SetWidth(w6)
  header.h5:SetJustifyH("LEFT")
  header.h6:SetJustifyH("LEFT")
end

-- Colunas Guilda: Nome | Nível | Classe | Rank | Zona | Status | Nota | [Nota oficial]
function UI.guildColumnWidths(totalW, showOfficerNote)
  local CC = cfg()
  local inner = math.max(400, totalW - 2 * CC.TABLE_PAD)
  local fracs
  if showOfficerNote then
    fracs = { 0.14, 0.06, 0.10, 0.12, 0.14, 0.12, 0.16, 0.16 }
  else
    -- Sem nota oficial: reparte o espaço pelas colunas úteis (sem “buraco” à direita).
    fracs = { 0.18, 0.06, 0.10, 0.13, 0.18, 0.13, 0.22 }
  end
  local n = #fracs
  local widths = {}
  local xs = {}
  local x = CC.TABLE_PAD
  local used = 0
  for i = 1, n - 1 do
    widths[i] = inner * fracs[i]
    xs[i] = x
    x = x + widths[i]
    used = used + widths[i]
  end
  -- Última coluna visível absorve o resto → preenche até à borda.
  widths[n] = math.max(40, inner - used)
  xs[n] = x
  local endX = x + widths[n]
  for i = n + 1, 8 do
    widths[i] = 0
    xs[i] = endX
  end
  return widths, xs, n
end

function UI.layoutGuildHeaderColumns(header, scrollFrame)
  if not header then
    return
  end
  local CC = cfg()
  local w = header:GetWidth()
  if scrollFrame and scrollFrame.GetWidth then
    local sw = scrollFrame:GetWidth()
    if sw and sw > 80 then
      w = sw
    end
  end
  local showOfficer = CEF.Guild and CEF.Guild.canViewOfficerNote and CEF.Guild.canViewOfficerNote()
  local widths, xs, colCount = UI.guildColumnWidths(w, showOfficer)
  for i = 1, 8 do
    local btn = header["btn" .. i]
    local h = header["h" .. i]
    local target = btn or h
    if target then
      if i <= colCount then
        target:ClearAllPoints()
        target:SetPoint("LEFT", header, "LEFT", xs[i], 0)
        target:SetWidth(math.max(28, widths[i] - CC.COL_GAP))
        if btn then
          target:SetHeight(header:GetHeight() or 20)
          if h then
            h:ClearAllPoints()
            h:SetPoint("LEFT", btn, "LEFT", 0, 0)
            h:SetPoint("RIGHT", btn, "RIGHT", -13, 0)
            h:SetJustifyH("LEFT")
            h:SetJustifyV("MIDDLE")
            h:Show()
          end
          btn:Show()
        else
          target:SetJustifyH("LEFT")
        end
        target:Show()
      else
        target:Hide()
        if h and btn then
          h:Hide()
        end
        local icon = header["sortIcon" .. i]
        if icon then
          icon:Hide()
        end
      end
    end
  end
  if header.updateSortLabels then
    header.updateSortLabels()
  end
end
