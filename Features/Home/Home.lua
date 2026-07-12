-- Módulo: agregação da aba Home — demanda Chat + Premade (instâncias, funções).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Home = CEF.Home or {}
local Home = CEF.Home

local TOP_INSTANCES = 10

local function bump(map, key, n)
  if not key or key == "" then
    return
  end
  map[key] = (map[key] or 0) + (n or 1)
end

local function normalizeLabel(s)
  s = tostring(s or "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

local function lfgOpenRoles(result)
  local open = { tank = 0, heal = 0, dps = 0 }
  local slots = result and result.roleSlots
  if type(slots) == "table" and #slots > 0 then
    for _, slot in ipairs(slots) do
      if not slot.filled then
        local role = slot.role
        if role == "TANK" then
          open.tank = open.tank + 1
        elseif role == "HEALER" then
          open.heal = open.heal + 1
        elseif role == "DAMAGER" then
          open.dps = open.dps + 1
        end
      end
    end
    return open
  end
  -- Fallback RoleCount: marca função se o grupo ainda parece incompleto e a contagem é baixa.
  local c = result and result.counts
  local n = tonumber(result and result.numMembers) or 0
  if type(c) == "table" and n > 0 and n < 5 then
    if (tonumber(c.TANK) or 0) < 1 then
      open.tank = 1
    end
    if (tonumber(c.HEALER) or 0) < 1 then
      open.heal = 1
    end
    local dps = tonumber(c.DAMAGER) or 0
    if dps < 3 and (5 - n) > 0 then
      open.dps = math.min(3 - dps, 5 - n)
      if open.dps < 0 then
        open.dps = 0
      end
    end
  end
  return open
end

local function roleLabel(roleKey)
  if roleKey == "tank" then
    return (CEF.L and CEF.L.FILTER_ROLE_TANK) or "Tank"
  end
  if roleKey == "heal" then
    return (CEF.L and CEF.L.FILTER_ROLE_HEAL) or "Healer"
  end
  if roleKey == "dps" then
    return (CEF.L and CEF.L.FILTER_ROLE_DPS) or "DPS"
  end
  return roleKey
end

--- Snapshot ao vivo para a aba Home.
function Home.buildSnapshot()
  local instanceChat, instanceLfg = {}, {}
  local roleChat = { tank = 0, heal = 0, dps = 0 }
  local roleLfg = { tank = 0, heal = 0, dps = 0 }
  local intent = { invite = 0, whisper = 0 }
  local chatCount, lfgCount = 0, 0

  local entries = (CEF.Entries and CEF.Entries.getAll and CEF.Entries.getAll()) or {}
  for _, e in ipairs(entries) do
    chatCount = chatCount + 1
    local intentKey = CEF.classifyMessageIntent and CEF.classifyMessageIntent(e.text) or "whisper"
    if intentKey == "invite" then
      intent.invite = intent.invite + 1
    else
      intent.whisper = intent.whisper + 1
    end

    local instList = e.instances
    if type(instList) ~= "table" or #instList == 0 then
      if e.instance and e.instance ~= "" and e.instance ~= "—" then
        instList = { e.instance }
      else
        instList = {}
      end
    end
    for _, ik in ipairs(instList) do
      local label = (CEF.getInstanceDisplayName and CEF.getInstanceDisplayName(ik)) or ik
      label = normalizeLabel(label)
      if label ~= "" then
        bump(instanceChat, label)
      end
    end

    for _, rk in ipairs({ "tank", "heal", "dps" }) do
      if CEF.messageMatchesRoleFilter and CEF.messageMatchesRoleFilter(e.text, rk) then
        roleChat[rk] = roleChat[rk] + 1
      end
    end
  end

  local results = (CEF.LFG and CEF.LFG.getResults and CEF.LFG.getResults()) or {}
  for _, r in ipairs(results) do
    lfgCount = lfgCount + 1
    local label = normalizeLabel(r.activityName)
    if label ~= "" and label ~= "—" then
      bump(instanceLfg, label)
    end
    local open = lfgOpenRoles(r)
    roleLfg.tank = roleLfg.tank + open.tank
    roleLfg.heal = roleLfg.heal + open.heal
    roleLfg.dps = roleLfg.dps + open.dps
  end

  local mergedInstances = {}
  for label, n in pairs(instanceChat) do
    local row = mergedInstances[label] or { label = label, chat = 0, lfg = 0, total = 0 }
    row.chat = n
    row.total = row.chat + row.lfg
    mergedInstances[label] = row
  end
  for label, n in pairs(instanceLfg) do
    local row = mergedInstances[label] or { label = label, chat = 0, lfg = 0, total = 0 }
    row.lfg = n
    row.total = row.chat + row.lfg
    mergedInstances[label] = row
  end
  local instances = {}
  for _, row in pairs(mergedInstances) do
    instances[#instances + 1] = row
  end
  table.sort(instances, function(a, b)
    if a.total ~= b.total then
      return a.total > b.total
    end
    return a.label < b.label
  end)
  while #instances > TOP_INSTANCES do
    instances[#instances] = nil
  end

  local roles = {}
  for _, rk in ipairs({ "tank", "heal", "dps" }) do
    local chatN = roleChat[rk] or 0
    local lfgN = roleLfg[rk] or 0
    roles[#roles + 1] = {
      key = rk,
      label = roleLabel(rk),
      chat = chatN,
      lfg = lfgN,
      total = chatN + lfgN,
    }
  end
  table.sort(roles, function(a, b)
    return a.total > b.total
  end)

  return {
    chatCount = chatCount,
    lfgCount = lfgCount,
    intent = intent,
    instances = instances,
    roles = roles,
  }
end
