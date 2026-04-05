-- Módulo: filtros da lista (entryMatchesFilters) — função pura.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

-- nil e false = “mostrar tudo” neste eixo (nil ~= false em Lua; tratar os dois).
local function noFilter(v)
  return v == nil or v == false
end

function CEF.entryMatchesFilters(entry, filterInstanceKey, filterIntentKey, filterRoleKey, filterSearchText)
  if not entry then
    return false
  end

  if not noFilter(filterInstanceKey) and not CEF.entryHasInstance(entry, filterInstanceKey) then
    return false
  end

  if not noFilter(filterIntentKey) and CEF.classifyMessageIntent(entry.text or "") ~= filterIntentKey then
    return false
  end

  if not noFilter(filterRoleKey) and not CEF.messageMatchesRoleFilter(entry.text or "", filterRoleKey) then
    return false
  end

  local q = filterSearchText
  if q == nil then
    q = ""
  end
  if q ~= "" then
    local blob = CEF.entryInstancesSearchBlob(entry)
    local name = strlower(CEF.stripRealm(entry.sender or ""))
    if not blob:find(q, 1, true) and not name:find(q, 1, true) then
      return false
    end
  end

  return true
end

