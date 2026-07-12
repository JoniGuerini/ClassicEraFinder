-- Módulo: gerenciamento de entries (dados + filtragem + dedupe + persistência)
-- Exposto em ClassicEraFinder.Entries.*

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Entries = CEF.Entries or {}
local Entries = CEF.Entries

local MAX_STORED = (CEF.CONST and CEF.CONST.MAX_STORED) or 250
local ENTRY_MAX_LISTING_AGE_SEC = (CEF.CONST and CEF.CONST.ENTRY_MAX_LISTING_AGE_SEC) or 3600

local entries = {}
local filteredView = {}
local indexByKey = {}

local function sortEntries()
  table.sort(entries, function(a, b)
    return (a.time or 0) > (b.time or 0)
  end)
end

local function dedupeKey(sender, normalizedMsg)
  return strlower(CEF.stripRealm(sender)) .. "\0" .. normalizedMsg
end

local function removeEntryObject(e)
  if not e then
    return
  end
  local k = dedupeKey(e.sender, CEF.normalizeMessage(e.text))
  indexByKey[k] = nil
  for j, ev in ipairs(entries) do
    if ev == e then
      table.remove(entries, j)
      break
    end
  end
end

function Entries.loadFromDB()
  CEF.DB.init()
  wipe(entries)
  wipe(indexByKey)
  wipe(filteredView)

  local raw = CEF.DB.getListingEntries and select(1, CEF.DB.getListingEntries()) or nil
  if type(raw) ~= "table" then
    return
  end

  local now = time()
  local temp = {}
  for _, row in ipairs(raw) do
    if type(row) == "table" and row.sender and row.text then
      local txt = tostring(row.text)
      local rowTime = tonumber(row.time) or 0
      if CEF.passesInstanceFinderFilter(txt) and now - rowTime < ENTRY_MAX_LISTING_AGE_SEC then
        local instList = CEF.detectInstances(txt)
        if #instList == 0 then
          if type(row.instances) == "table" then
            for _, k in ipairs(row.instances) do
              local ks = tostring(k or "")
              if ks ~= "" and ks ~= "—" then
                instList[#instList + 1] = ks
              end
            end
          end
          if #instList == 0 and row.instance and tostring(row.instance) ~= "" and tostring(row.instance) ~= "—" then
            instList[1] = tostring(row.instance)
          end
        end

        if #instList > 0 then
          temp[#temp + 1] = {
            sender = tostring(row.sender),
            guid = tostring(row.guid or ""),
            text = txt,
            time = rowTime,
            instance = instList[1],
            instances = instList,
            channel = tostring(row.channel or ""),
          }
        end
      end
    end
  end

  table.sort(temp, function(a, b)
    return (a.time or 0) > (b.time or 0)
  end)

  local seen = {}
  for _, e in ipairs(temp) do
    local k = dedupeKey(e.sender, CEF.normalizeMessage(e.text))
    if not seen[k] then
      seen[k] = true
      if #entries < MAX_STORED then
        entries[#entries + 1] = e
        indexByKey[k] = e
      end
    end
  end

  sortEntries()
  CEF.DB.persistEntries(entries)
end

function Entries.getFilteredView()
  return filteredView
end

--- Todas as entries em memória (janela rolling), sem filtro de UI.
function Entries.getAll()
  return entries
end

function Entries.rebuildFilteredView()
  wipe(filteredView)
  local s = CEF.state or {}
  local fi = s.filterInstanceKeys
  local fint = s.filterIntentKeys
  local fr = s.filterRoleKeys
  local ft = s.filterSearchText
  if ft == nil then
    ft = ""
  end
  for _, e in ipairs(entries) do
    if CEF.entryMatchesFilters(e, fi, fint, fr, ft) then
      filteredView[#filteredView + 1] = e
    end
  end
end

function Entries.upsertEntry(sender, guid, text, channelLabel)
  if not CEF.messageLooksLFG(text) then
    return
  end

  local norm = CEF.normalizeMessage(text)
  if norm == "" then return end

  local key = dedupeKey(sender, norm)
  local now = time()
  local instList = CEF.detectInstances(text)
  local inst = instList[1] or "—"

  local existing = indexByKey[key]
  if existing then
    if not CEF.passesInstanceFinderFilter(text) then
      removeEntryObject(existing)
      sortEntries()
      CEF.DB.persistEntries(entries)
      return
    end

    existing.time = now
    existing.channel = channelLabel or existing.channel
    existing.instances = instList
    existing.instance = inst
    existing.text = text
    sortEntries()
    CEF.DB.persistEntries(entries)
    return
  end

  if not CEF.passesInstanceFinderFilter(text) then
    return
  end

  local e = {
    sender = sender,
    guid = guid,
    text = text,
    time = now,
    instance = inst,
    instances = instList,
    channel = channelLabel or "",
  }

  indexByKey[key] = e
  entries[#entries + 1] = e

  while #entries > MAX_STORED do
    local oldestI
    local oldestT = math.huge
    for i, v in ipairs(entries) do
      if v.time < oldestT then
        oldestT = v.time
        oldestI = i
      end
    end
    if oldestI then
      local old = entries[oldestI]
      indexByKey[dedupeKey(old.sender, CEF.normalizeMessage(old.text))] = nil
      table.remove(entries, oldestI)
    else
      break
    end
  end

  sortEntries()
  CEF.DB.persistEntries(entries)
end

function Entries.purgeStaleEntries()
  if #entries == 0 then
    return false
  end

  local now = time()
  local removed = false
  local i = 1
  while i <= #entries do
    local e = entries[i]
    local ts = tonumber(e.time) or 0
    if now - ts >= ENTRY_MAX_LISTING_AGE_SEC then
      removeEntryObject(e)
      removed = true
    else
      i = i + 1
    end
  end

  if removed then
    sortEntries()
    CEF.DB.persistEntries(entries)
  end

  return removed
end

function Entries.persist()
  CEF.DB.persistEntries(entries)
end

