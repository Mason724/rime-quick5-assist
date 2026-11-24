-- assist.lua —— 個人配詞學習 + 尾隨單字
-- 2026-11-24 為主人寫。
--
-- 做兩件事：
-- 1) 學習：每次主人上屏一個詞，就把它和前一個詞記一筆到 user_pairs.txt（純文字，可看可刪）。
--    下次打同一個詞，主人慣用的下一個詞會排在候選最前面（帶「慣用」註解）。
-- 2) 尾隨單字：打三碼以上時，把頭兩碼對應的單字排在候選最後（帶「單字」註解）。
--
-- 停用：把 quick5.custom.yaml 的 lua_translator@*assist 一行刪掉即可。

local M = {}

local PAIRS = nil      -- key = "上一個詞\t下一個詞" -> 次數
local CHARS = nil      -- 速成碼 -> { 單字, ... }
local LAST = nil       -- 剛剛上屏的詞

local function udir()
    local ok, d = pcall(function()
        return rime_api.get_user_data_dir()
    end)
    if ok and d and d ~= '' then
        return d
    end
    local appdata = os.getenv('APPDATA')
    if appdata then
        return appdata .. '/Rime'
    end
    return '.'
end

local function load_pairs()
    PAIRS = {}
    local f = io.open(udir() .. '/user_pairs.txt', 'r')
    if not f then
        return
    end
    for line in f:lines() do
        local a, b = line:match('^([^\t]+)\t([^\t]+)$')
        if a and b then
            local k = a .. '\t' .. b
            PAIRS[k] = (PAIRS[k] or 0) + 1
        end
    end
    f:close()
end

local function record(a, b)
    local f = io.open(udir() .. '/user_pairs.txt', 'a')
    if f then
        f:write(a .. '\t' .. b .. '\n')
        f:close()
    end
    local k = a .. '\t' .. b
    PAIRS[k] = (PAIRS[k] or 0) + 1
end

local function load_chars()
    CHARS = {}
    local f = io.open(udir() .. '/quick5.char.dict.yaml', 'r')
    if not f then
        return
    end
    for line in f:lines() do
        local ch, code = line:match('^([^\t]+)\t([a-z]+)\t')
        if ch and code then
            local lst = CHARS[code]
            if not lst then
                lst = {}
                CHARS[code] = lst
            end
            lst[#lst + 1] = ch
        end
    end
    f:close()
end

local function has_cjk(s)
    for _, cp in utf8.codes(s) do
        if cp >= 0x3400 and cp <= 0x9FFF then
            return true
        end
    end
    return false
end
local function debug_log(msg)
    local p = udir() .. '/learn_debug.log'
    local f = io.open(p, 'a')
    if f then
        local size = f:seek('end') or 0
        if size < 40000 then
            f:write(os.date('%H:%M ') .. msg .. '\n')
        end
        f:close()
    end
end

local function learned_next(word)
    if not PAIRS or not word then
        return {}
    end
    local prefix = word .. '\t'
    local out = {}
    for k, n in pairs(PAIRS) do
        if k:sub(1, #prefix) == prefix then
            out[#out + 1] = { w = k:sub(#prefix + 1), n = n }
        end
    end
    table.sort(out, function(x, y)
        return x.n > y.n
    end)
    return out
end

function M.init(env)
    load_pairs()
    load_chars()
    local ctx = env.engine.context
    M.conn = ctx.commit_notifier:connect(function(c)
        local ok, text = pcall(function()
            return c:get_commit_text()
        end)
        if not ok or not text or text == '' then
            return
        end
        -- 只記含中文的
        if not has_cjk(text) then
            return
        end
        if LAST and LAST ~= text and has_cjk(LAST) then
            record(LAST, text)
        end
        LAST = text
    end)
end

function M.func(input, seg, env)
    -- 情況一：空碼（聯想段）→ 出主人慣用的下一個詞
    if input == '' then
        debug_log('empty-input, last=' .. tostring(LAST))
        local list = learned_next(LAST)
        for i = 1, math.min(#list, 4) do
            local cand = Candidate('learned', seg.start, seg._end, list[i].w, '慣用')
            cand.quality = 30
            yield(cand)
        end
        return
    end

    -- 情況二：三碼以上 → 尾隨頭兩碼的單字
    if #input <= 2 then
        return
    end
    local code = input:sub(1, 2)
    local lst = CHARS and CHARS[code]
    if not lst then
        return
    end
    local n = 0
    for _, ch in ipairs(lst) do
        if n >= 6 then
            break
        end
        local cand = Candidate('char_hint', seg.start, seg._end, ch, '單字')
        cand.quality = 0.2
        yield(cand)
        n = n + 1
    end
end

return M
