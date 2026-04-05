-- Módulo: persistência (SavedVariables) do addon.
-- Mantém exatamente a mesma estrutura do saved-variable.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.DB = CEF.DB or {}

function CEF.DB.init()
  _G.ClassicEraFinderDB = _G.ClassicEraFinderDB or {}
  local db = _G.ClassicEraFinderDB
  if type(db.entries) ~= "table" then
    db.entries = {}
  end
  if type(db.minimap) ~= "table" then
    db.minimap = {}
  end
  if db.minimap.angle == nil then
    db.minimap.angle = 218
  end
  db.version = db.version or 1
end

function CEF.DB.persistEntries(entries)
  entries = entries or {}
  CEF.DB.init()

  local db = _G.ClassicEraFinderDB
  local out = {}
  for i, e in ipairs(entries) do
    local instList = {}
    if type(e.instances) == "table" then
      for j, k in ipairs(e.instances) do
        instList[j] = tostring(k)
      end
    elseif e.instance and e.instance ~= "" and e.instance ~= "—" then
      instList[1] = tostring(e.instance)
    end

    out[i] = {
      sender = tostring(e.sender or ""),
      guid = tostring(e.guid or ""),
      text = tostring(e.text or ""),
      time = tonumber(e.time) or 0,
      instance = instList[1] or tostring(e.instance or ""),
      instances = instList,
      channel = tostring(e.channel or ""),
    }
  end
  db.entries = out
end

