-- Módulo: localização (deteção automática + override manual).
-- Novos idiomas: CEF.Locale.register("xxXX", { KEY = "…" }) em Locale/xxXX.lua.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Locale = CEF.Locale or {}
local Loc = CEF.Locale

local packs = {}
local FALLBACK = "enUS"
local activeCode = FALLBACK
local listeners = {}

-- Mapeia GetLocale() do cliente → pack suportado.
local CLIENT_MAP = {
  enUS = "enUS",
  enGB = "enUS",
  ptBR = "ptBR",
  ptPT = "ptBR",
  esES = "esES",
  esMX = "esMX",
  frFR = "frFR",
  deDE = "deDE",
  itIT = "itIT",
  ruRU = "ruRU",
  koKR = "koKR",
  zhCN = "zhCN",
  zhTW = "zhTW",
}

local LOCALE_META = {
  enUS = { nativeName = "English", short = "EN" },
  ptBR = { nativeName = "Português", short = "PT" },
  esES = { nativeName = "Español (España)", short = "ES" },
  esMX = { nativeName = "Español (México)", short = "MX" },
  frFR = { nativeName = "Français", short = "FR" },
  deDE = { nativeName = "Deutsch", short = "DE" },
  itIT = { nativeName = "Italiano", short = "IT" },
  ruRU = { nativeName = "Русский", short = "RU" },
  koKR = { nativeName = "한국어", short = "KO" },
  zhCN = { nativeName = "简体中文", short = "CN" },
  zhTW = { nativeName = "繁體中文", short = "TW" },
}

function Loc.register(code, strings)
  if type(code) ~= "string" or type(strings) ~= "table" then
    return
  end
  packs[code] = strings
  if not LOCALE_META[code] then
    LOCALE_META[code] = { nativeName = code, short = code }
  end
end

function Loc.getRegisteredCodes()
  local out = {}
  for code in pairs(packs) do
    out[#out + 1] = code
  end
  table.sort(out)
  return out
end

function Loc.getMeta(code)
  return LOCALE_META[code]
end

function Loc.getClientLocale()
  local raw = (GetLocale and GetLocale()) or "enUS"
  return CLIENT_MAP[raw] or FALLBACK
end

function Loc.getOverride()
  CEF.DB.init()
  local v = _G.ClassicEraFinderDB and _G.ClassicEraFinderDB.localeOverride
  if v == nil or v == false or v == "" or v == "auto" then
    return nil
  end
  if packs[v] then
    return v
  end
  return nil
end

function Loc.getActiveCode()
  return activeCode
end

function Loc.Get(key)
  if not key then
    return ""
  end
  local pack = packs[activeCode]
  local fb = packs[FALLBACK]
  if pack and pack[key] ~= nil then
    return pack[key]
  end
  if fb and fb[key] ~= nil then
    return fb[key]
  end
  return tostring(key)
end

-- CEF.L.KEY  ou  CEF.L("KEY")  ou  CEF.L("KEY_FMT", a, b)
CEF.L = setmetatable({}, {
  __index = function(_, key)
    return Loc.Get(key)
  end,
  __call = function(_, key, ...)
    local s = Loc.Get(key)
    local n = select("#", ...)
    if n > 0 then
      return s:format(...)
    end
    return s
  end,
})

function Loc.onChanged(fn)
  if type(fn) == "function" then
    listeners[#listeners + 1] = fn
  end
end

local function notify()
  for i = 1, #listeners do
    local ok, err = pcall(listeners[i], activeCode)
    if not ok and DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage("|cffff6666ClassicEraFinder locale:|r " .. tostring(err))
    end
  end
end

function Loc.apply(code)
  if not code or not packs[code] then
    code = FALLBACK
  end
  if not packs[code] and packs.enUS then
    code = "enUS"
  end
  activeCode = code
  notify()
end

function Loc.resolveAndApply()
  local override = Loc.getOverride()
  local code = override or Loc.getClientLocale()
  if not packs[code] then
    code = FALLBACK
  end
  Loc.apply(code)
end

--- @param code string|nil nil/"auto" = seguir o cliente
function Loc.setOverride(code)
  CEF.DB.init()
  local db = _G.ClassicEraFinderDB
  if code == nil or code == false or code == "" or code == "auto" then
    db.localeOverride = nil
  elseif packs[code] then
    db.localeOverride = code
  else
    return false
  end
  Loc.resolveAndApply()
  return true
end

function Loc.isAuto()
  return Loc.getOverride() == nil
end

-- Opções do dropdown de idioma (auto + packs registados).
function Loc.getChooserOptions()
  local opts = {
    { key = "auto", label = Loc.Get("LOCALE_AUTO") },
  }
  local codes = Loc.getRegisteredCodes()
  for _, code in ipairs(codes) do
    local meta = LOCALE_META[code]
    local name = (meta and meta.nativeName) or code
    opts[#opts + 1] = { key = code, label = name }
  end
  return opts
end

function Loc.chooserSummaryText()
  local ov = Loc.getOverride()
  if not ov then
    local meta = LOCALE_META[Loc.getClientLocale()]
    local name = (meta and meta.nativeName) or Loc.getClientLocale()
    return Loc.Get("LOCALE_AUTO_SUMMARY"):format(name)
  end
  local meta = LOCALE_META[ov]
  return "|cffffffff" .. ((meta and meta.nativeName) or ov) .. "|r"
end
