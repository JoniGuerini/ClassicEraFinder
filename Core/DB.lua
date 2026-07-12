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
  if type(db.chat) ~= "table" then
    db.chat = {}
  end
  if type(db.chat.conversations) ~= "table" then
    db.chat.conversations = {}
  end
  if type(db.minimap) ~= "table" then
    db.minimap = {}
  end
  if db.minimap.angle == nil then
    db.minimap.angle = 218
  end
  -- nil = automático (idioma do cliente); "enUS" / "ptBR" / … = override manual.
  if db.localeOverride == false or db.localeOverride == "" then
    db.localeOverride = nil
  end
  db.version = db.version or 1
end

function CEF.DB.persistChat(conversations)
  CEF.DB.init()
  local db = _G.ClassicEraFinderDB
  local out = {}
  if type(conversations) == "table" then
    for id, conv in pairs(conversations) do
      if type(conv) == "table" and type(id) == "string" then
        local msgs = {}
        if type(conv.messages) == "table" then
          for i, m in ipairs(conv.messages) do
            if type(m) == "table" and type(m.text) == "string" and m.text ~= "" then
              local row = {
                id = m.id and tostring(m.id) or nil,
                t = tonumber(m.t) or 0,
                dir = (m.dir == "out" and "out") or (m.dir == "sys" and "sys") or "in",
                text = tostring(m.text),
              }
              if type(m.reply) == "table" and type(m.reply.text) == "string" and m.reply.text ~= "" then
                row.reply = {
                  id = m.reply.id and tostring(m.reply.id) or nil,
                  name = tostring(m.reply.name or ""),
                  text = tostring(m.reply.text),
                }
              end
              msgs[#msgs + 1] = row
            end
          end
        end
        out[id] = {
          id = tostring(conv.id or id),
          kind = (conv.kind == "bnet") and "bnet" or "whisper",
          name = tostring(conv.name or ""),
          bnetAccountID = tonumber(conv.bnetAccountID),
          lastActivity = tonumber(conv.lastActivity) or 0,
          unread = tonumber(conv.unread) or 0,
          messages = msgs,
        }
      end
    end
  end
  db.chat = db.chat or {}
  db.chat.conversations = out
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

