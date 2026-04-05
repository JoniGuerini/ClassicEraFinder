-- Módulo: lógica de instâncias e formatação da coluna "Instância / níveis"
-- Mantém exatamente a mesma lógica do arquivo único, mas exposta em ClassicEraFinder.*

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

-- Instâncias: várias substrings por linha (busca case-insensitive, texto puro).
local INSTANCE_ROWS = {
  { key = "Naxxramas", needles = { "naxxramas", "naxx ", " naxx", "naxx." } },
  { key = "Ahn'Qiraj 40", needles = { "aq40", "aq 40", "ahn'qiraj", "ahn qiraj", " temple of ahn", "cthun", "ouro", "viscidus", "huhuran", "fankriss" } },
  { key = "Ahn'Qiraj 20", needles = { "aq20", "aq 20", "ruins of ahn", "ossirian", "moam", "rajaxx" } },
  { key = "Zul'Gurub", needles = { " zg ", " zg.", "zg run", "zul'gurub", "zul gurub", "hakkar", "jindo" } },
  { key = "Molten Core", needles = { "molten core", "ragnaros", "geddon", "golemagg", "magmadar", "lucifron", " mc ", " mc,", "full mc", "molten", "m mc", " gdkp mc", "mc gdkp" } },
  { key = "Blackwing Lair", needles = { "blackwing", "bwl ", " bwl", "nefarian", "razorgore", "vael" } },
  { key = "Onyxia", needles = { "onyxia", " ony ", " ony.", "ony run" } },
  {
    key = "Stratholme",
    needles = {
      "stratholme",
      "strat ",
      " strat",
      "strat(",
      "strat)",
      "strat,",
      "strat.",
      "strat-",
      "strat live",
      "strat ud",
      "rivendare",
      "baron run",
    },
  },
  { key = "Scholomance", needles = { "scholomance", "scholo", "gandling", "darkmaster" } },
  { key = "Dire Maul", needles = { "dire maul", "dm north", "dm east", "dm west", "dm tribute", "immol'thar", "alzzin" } },
  { key = "Blackrock Spire", needles = { "ubrs", "lbrs", "blackrock spire", "lower spire", "upper spire", "drakkisath", "rend " } },
  { key = "Blackrock Depths", needles = { "blackrock depths", "brd ", " brd", "angerforge", "emperor ", "lokhtos", "arena run" } },
  { key = "Sunken Temple", needles = { "sunken temple", "atal'hakkar", "atal hakkar", " jammalan", "eranikus" } },
  { key = "Maraudon", needles = { "maraudon", " mara ", "mara run", "princess ", "rotgrip", "landslide" } },
  { key = "Zul'Farrak", needles = { "zul'farrak", "zul farrak", "zf ", " zf", "sandfury", "chief sandscalp" } },
  { key = "Uldaman", needles = { "uldaman", "ulda ", "/ulda", "ulda/", "archaedas", "ironaya" } },
  -- Scarlet Monastery no Classic = 4 instâncias separadas (alas).
  { key = "SM Graveyard", needles = { "sm gy", "sm graveyard", "sm grave" } },
  { key = "SM Library", needles = { "sm lib", "sm librar", "sm library" } },
  { key = "SM Armory", needles = { "sm arm", "sm armory", "sm arms" } },
  { key = "SM Cathedral", needles = { "sm cath", "sm cathedral" } },
  { key = "Razorfen Downs", needles = { "razorfen downs", "rfd/", " rfd/", "/rfd", "rfd ", " rfd", "amnennar" } },
  { key = "Razorfen Kraul", needles = { "razorfen kraul", "rfk ", " rfk", "charlga" } },
  { key = "Gnomeregan", needles = { "gnomeregan", "gnomer", "thermaplugg", "pummeler" } },
  { key = "The Stockade", needles = { "stockade", "stocks", "stocks,", "stocks.", "stocks:", "stocks;", "stocks)", "stocks(", "stocks ", " the stocks" } },
  { key = "Blackfathom Deeps", needles = { "blackfathom", "bfd ", " bfd", "akumai" } },
  { key = "Shadowfang Keep", needles = { "shadowfang", "sfk ", " sfk", "arugal" } },
  { key = "Deadmines", needles = { "deadmines", "dead mines", "van cleef", "defias", "vc ", " vc" } },
  { key = "Wailing Caverns", needles = { "wailing caverns", "wc run", " mutanus", "cobrahn" } },
  { key = "Ragefire Chasm", needles = { "ragefire", "rfc ", " rfc", "bazzalan" } },
}

-- Raids (Classic Era); o restante em INSTANCE_ROWS conta como masmorra no filtro.
local INSTANCE_RAIDS = {
  ["Naxxramas"] = true,
  ["Ahn'Qiraj 40"] = true,
  ["Ahn'Qiraj 20"] = true,
  ["Zul'Gurub"] = true,
  ["Molten Core"] = true,
  ["Blackwing Lair"] = true,
  ["Onyxia"] = true,
}

-- Faixa de níveis recomendada (Classic Era / vanilla); só para referência na UI.
local INSTANCE_LEVEL_RANGE = {
  ["Ragefire Chasm"] = "13-18",
  ["Wailing Caverns"] = "17-24",
  ["Deadmines"] = "17-26",
  ["Shadowfang Keep"] = "22-30",
  ["Blackfathom Deeps"] = "24-32",
  ["The Stockade"] = "24-32",
  ["Gnomeregan"] = "29-38",
  ["Razorfen Kraul"] = "30-40",
  ["SM Graveyard"] = "34-45",
  ["SM Library"] = "34-45",
  ["SM Armory"] = "34-45",
  ["SM Cathedral"] = "34-45",
  ["Razorfen Downs"] = "35-45",
  ["Uldaman"] = "41-51",
  ["Zul'Farrak"] = "44-54",
  ["Maraudon"] = "46-55",
  ["Sunken Temple"] = "50-60",
  ["Blackrock Depths"] = "52-60",
  ["Dire Maul"] = "56-60",
  ["Scholomance"] = "58-60",
  ["Stratholme"] = "58-60",
  ["Blackrock Spire"] = "55-60",
  ["Zul'Gurub"] = "60",
  ["Molten Core"] = "60",
  ["Onyxia"] = "60",
  ["Blackwing Lair"] = "60",
  ["Ahn'Qiraj 20"] = "60",
  ["Ahn'Qiraj 40"] = "60",
  ["Naxxramas"] = "60",
}

local function instanceMinLevelForSort(instanceKey)
  local plain = INSTANCE_LEVEL_RANGE[instanceKey]
  if not plain then
    return 999
  end
  local minV = plain:match("^(%d+)%-(%d+)$")
  if minV then
    return tonumber(minV) or 999
  end
  local solo = plain:match("^(%d+)$")
  if solo then
    return tonumber(solo) or 999
  end
  return 999
end

-- Entradas do menu do filtro: opção (key false = todas) ou cabeçalho de secção.
CEF.INSTANCE_FILTER_MENU_OPTS = {}
do
  local dungeons, raids = {}, {}
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      if INSTANCE_RAIDS[k] then
        raids[#raids + 1] = k
      else
        dungeons[#dungeons + 1] = k
      end
    end
  end

  table.sort(dungeons, function(a, b)
    local ka, kb = instanceMinLevelForSort(a), instanceMinLevelForSort(b)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a) < strlower(b)
  end)

  table.sort(raids, function(a, b)
    local ka, kb = instanceMinLevelForSort(a), instanceMinLevelForSort(b)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a) < strlower(b)
  end)

  local opts = {}
  opts[#opts + 1] = { kind = "opt", key = false }
  opts[#opts + 1] = { kind = "hdr", text = "Masmorras" }
  for _, k in ipairs(dungeons) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end
  opts[#opts + 1] = { kind = "hdr", text = "Raids" }
  for _, k in ipairs(raids) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end

  CEF.INSTANCE_FILTER_MENU_OPTS = opts
end

-- Laranja = nível mínimo do range, verde = nível máximo (|c … |r como no chat).
local COLOR_LVL_ORANGE_MIN = "|cffff9933"
local COLOR_LVL_GREEN_MAX = "|cff33cc33"

-- Nome da instância: masmorra (azul-claro) vs raid (âmbar), alinhado a INSTANCE_RAIDS.
local COLOR_INSTANCE_DUNGEON_NAME = "|cff9fd3ff"
local COLOR_INSTANCE_RAID_NAME = "|cffffb74d"

local function instanceNameRichOpenTag(instanceKey)
  if instanceKey and INSTANCE_RAIDS[instanceKey] then
    return COLOR_INSTANCE_RAID_NAME
  end
  return COLOR_INSTANCE_DUNGEON_NAME
end

function CEF.instanceKeyIsRaid(instanceKey)
  return instanceKey ~= nil and instanceKey ~= false and INSTANCE_RAIDS[instanceKey] == true
end

local function formatLevelRangeColored(plain)
  if not plain or plain == "—" then
    return "—"
  end
  local minV, maxV = plain:match("^(%d+)%-(%d+)$")
  if minV and maxV then
    return COLOR_LVL_ORANGE_MIN .. minV .. "|r-" .. COLOR_LVL_GREEN_MAX .. maxV .. "|r"
  end
  local solo = plain:match("^(%d+)$")
  if solo then
    return COLOR_LVL_ORANGE_MIN .. solo .. "|r-" .. COLOR_LVL_GREEN_MAX .. solo .. "|r"
  end
  return plain
end

local function recommendedLevelRichText(instanceKey)
  if not instanceKey or instanceKey == "—" then
    return "—"
  end
  local plain = INSTANCE_LEVEL_RANGE[instanceKey]
  if not plain then
    return "—"
  end
  return formatLevelRangeColored(plain)
end

function CEF.instanceLevelRangeRichText(instanceKey)
  return recommendedLevelRichText(instanceKey)
end

-- Linhas de deteção agrupadas (mesma ordem que o menu de filtro).
function CEF.getInstanceDetectionRowsGroupedSorted()
  local d, r = {}, {}
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      if INSTANCE_RAIDS[k] then
        r[#r + 1] = row
      else
        d[#d + 1] = row
      end
    end
  end
  local function sortFn(a, b)
    local ka, kb = instanceMinLevelForSort(a.key), instanceMinLevelForSort(b.key)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a.key) < strlower(b.key)
  end
  table.sort(d, sortFn)
  table.sort(r, sortFn)
  return { dungeons = d, raids = r }
end

function CEF.instanceFilterOptionRichText(instKey)
  if instKey == false or instKey == nil then
    return "|cffffffffTodas as instâncias|r"
  end
  return instanceNameRichOpenTag(instKey) .. instKey .. "|r  " .. recommendedLevelRichText(instKey)
end

-- Scarlet Monastery: 4 alas. Mensagem genérica (sem gy/lib/arm/cath) → assume full clear nas 4.
local SCARLET_WING_KEYS = { "SM Graveyard", "SM Library", "SM Armory", "SM Cathedral" }

local SCARLET_GENERIC_NEEDLES = {
  "full sm",
  "full-sm",
  "clear sm",
  "all sm",
  "sm full",
  "run sm",
  "sm run",
  "full clear sm",
  "full monastery",
  "clear monastery",
  " scarlet monastery",
  "scarlet monastery",
  "/sm",
  " sm/",
}

local function listContainsAnyKey(list, keys)
  for _, k in ipairs(list) do
    for _, w in ipairs(keys) do
      if k == w then
        return true
      end
    end
  end
  return false
end

-- «sm» como palavra (ex.: «lfg sm», «dps sm») sem apanhar «small», «asm», etc.
local function scarletSmAsIsolatedWord(lower)
  local pos = 1
  while true do
    local a, b = lower:find("sm", pos, true)
    if not a then
      break
    end
    local beforeLetter = (a > 1) and lower:sub(a - 1, a - 1):match("%a")
    local afterCh = lower:sub(b + 1, b + 1)
    local afterLetter = afterCh ~= "" and afterCh:match("%a")
    if not beforeLetter and not afterLetter then
      return true
    end
    pos = b + 1
  end
  return false
end

local function scarletGenericInText(lower)
  for _, n in ipairs(SCARLET_GENERIC_NEEDLES) do
    if lower:find(n, 1, true) then
      return true
    end
  end
  if scarletSmAsIsolatedWord(lower) then
    return true
  end
  return false
end

-- Todas as instâncias reconhecidas na mensagem; ordem = primeira ocorrência no texto.
function CEF.detectInstances(text)
  if not text or text == "" then
    return {}
  end
  local lower = text:lower()
  local hits = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local bestPos
    for _, n in ipairs(row.needles) do
      local pos = lower:find(n, 1, true)
      if pos and (not bestPos or pos < bestPos) then
        bestPos = pos
      end
    end
    if bestPos then
      hits[row.key] = bestPos
    end
  end

  local tmp = {}
  for k, pos in pairs(hits) do
    tmp[#tmp + 1] = { key = k, pos = pos }
  end
  table.sort(tmp, function(a, b)
    if a.pos ~= b.pos then
      return a.pos < b.pos
    end
    return strlower(a.key) < strlower(b.key)
  end)

  local out = {}
  for _, item in ipairs(tmp) do
    out[#out + 1] = item.key
  end

  if scarletGenericInText(lower) and not listContainsAnyKey(out, SCARLET_WING_KEYS) then
    for _, w in ipairs(SCARLET_WING_KEYS) do
      out[#out + 1] = w
    end
  end

  return out
end

function CEF.detectInstance(text)
  local list = CEF.detectInstances(text)
  return list[1] or "—"
end

local function entryInstancesList(e)
  if not e then
    return {}
  end
  if type(e.instances) == "table" and #e.instances > 0 then
    return e.instances
  end
  if e.instance and e.instance ~= "" and e.instance ~= "—" then
    return { e.instance }
  end
  return {}
end

function CEF.entryHasInstance(e, key)
  if not key or key == false then
    return true
  end
  for _, k in ipairs(entryInstancesList(e)) do
    if k == key then
      return true
    end
  end
  return false
end

-- Coluna: nome + intervalo de níveis na mesma linha por instância.
function CEF.entryInstancesComboRichText(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return "—"
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = instanceNameRichOpenTag(k) .. k .. "|r  " .. recommendedLevelRichText(k)
  end
  -- Quebra extra (linha em branco) para separar visualmente instâncias.
  return table.concat(parts, "\n\n")
end

-- Tooltip inline (uma linha) para não “quebrar” após o prefixo “Instância:”
function CEF.entryInstancesComboRichTextInline(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return "—"
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = instanceNameRichOpenTag(k) .. k .. "|r  " .. recommendedLevelRichText(k)
  end
  return table.concat(parts, ", ")
end

function CEF.entryInstancesLineCount(e)
  local list = entryInstancesList(e)
  local c = #list
  if c < 1 then
    return 1
  end
  return c
end

function CEF.entryInstancesSearchBlob(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return strlower(e.instance or "")
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = strlower(k)
  end
  return table.concat(parts, " ")
end

-- Leitura para a UI “Termos” (somente referência; listas são as mesmas usadas na deteção).
function CEF.getInstanceDetectionCatalog()
  return {
    rows = INSTANCE_ROWS,
    scarletGeneric = SCARLET_GENERIC_NEEDLES,
    scarletGenericUiHints = {
      "(regra automática) «sm» como palavra isolada — ex.: lfg sm, dps sm, tank sm (não colado a outras letras; não conta se já nomeares GY/Lib/Arm/Cath)",
    },
  }
end

