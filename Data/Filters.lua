-- Módulo: filtros da lista (entryMatchesFilters) — função pura.
-- Cada eixo (instância / intenção / função) aceita um conjunto: vazio = sem filtro;
-- com chaves = OR (basta bater numa das opções).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

-- Converte valor legado (false/nil/chave única) ou tabela numérica para set { [key]=true }.
function CEF.normalizeFilterSet(v)
  if v == nil or v == false then
    return {}
  end
  if type(v) == "table" then
    if v[1] ~= nil then
      local s = {}
      for _, k in ipairs(v) do
        if k ~= nil and k ~= false then
          s[k] = true
        end
      end
      return s
    end
    return v
  end
  return { [v] = true }
end

function CEF.filterSetIsActive(v)
  return next(CEF.normalizeFilterSet(v)) ~= nil
end

function CEF.filterSetContains(v, key)
  if key == nil or key == false then
    return not CEF.filterSetIsActive(v)
  end
  return CEF.normalizeFilterSet(v)[key] == true
end

-- Alterna uma chave no set. key false/nil limpa (modo “todas”).
-- Devolve o set mutado (ou tabela nova se o estado ainda não era set).
function CEF.filterSetToggle(v, key)
  if key == nil or key == false then
    return {}
  end
  local s = CEF.normalizeFilterSet(v)
  -- Se o estado original não era tabela-set, trabalhamos numa cópia.
  if type(v) ~= "table" or v[1] ~= nil then
    local copy = {}
    for k in pairs(s) do
      copy[k] = true
    end
    s = copy
  end
  if s[key] then
    s[key] = nil
  else
    s[key] = true
  end
  return s
end

function CEF.filterSetClear()
  return {}
end

function CEF.filterSetCount(v)
  local n = 0
  for _ in pairs(CEF.normalizeFilterSet(v)) do
    n = n + 1
  end
  return n
end

function CEF.filterSetSortedKeys(v)
  local keys = {}
  for k in pairs(CEF.normalizeFilterSet(v)) do
    keys[#keys + 1] = k
  end
  table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
  end)
  return keys
end

local function matchesAnyInstance(entry, filterSet)
  for k in pairs(filterSet) do
    if k == CEF.FILTER_INSTANCE_MY_LEVEL then
      if CEF.entryMatchesPlayerLevelInstances(entry) then
        return true
      end
    elseif CEF.entryHasInstance(entry, k) then
      return true
    end
  end
  return false
end

local function matchesAnyRole(text, filterSet)
  for k in pairs(filterSet) do
    if CEF.messageMatchesRoleFilter(text, k) then
      return true
    end
  end
  return false
end

function CEF.entryMatchesFilters(entry, filterInstanceKeys, filterIntentKeys, filterRoleKeys, filterSearchText)
  if not entry then
    return false
  end

  local instSet = CEF.normalizeFilterSet(filterInstanceKeys)
  if next(instSet) and not matchesAnyInstance(entry, instSet) then
    return false
  end

  local intentSet = CEF.normalizeFilterSet(filterIntentKeys)
  if next(intentSet) then
    local intent = CEF.classifyMessageIntent(entry.text or "")
    if not intentSet[intent] then
      return false
    end
  end

  local roleSet = CEF.normalizeFilterSet(filterRoleKeys)
  if next(roleSet) and not matchesAnyRole(entry.text or "", roleSet) then
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
