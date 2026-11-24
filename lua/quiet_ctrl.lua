-- quiet_ctrl.lua —— 按 Ctrl／Alt 時暫時關掉聯想，避免複製貼上時彈出候選窗
-- 2026-11-24 為主人寫。
--
-- 原理：librime-predict 的 predictor 只要 context 一更新（而且沒有輸入碼）就會重算預測，
-- 連按 Ctrl 都會觸發，於是候選窗彈出來。這裡在修飾鍵按下時把 prediction 選項暫時關掉，
-- 等到下一個「沒有修飾鍵」的按鍵才恢復，所以 Ctrl+C / Ctrl+V 期間不會打擾。
--
-- 停用：把 quick5.custom.yaml 的 lua_processor@*quiet_ctrl 一行刪掉即可。

local M = {}
local suspended = false

function M.init(env)
    M.env = env
end

function M.func(key, env)
    local ctx = env.engine.context
    local repr = key:repr() or ''

    -- 聯想窗出著的時候按 Backspace：先關窗，但按鍵照樣交返系統（正常刪字）
    -- 否則 librime-predict 會把第一下 Backspace 食掉（它設計成只關窗），感覺就係「冇反應」
    if (repr == 'BackSpace' or repr == 'Delete') and ctx.input == '' and ctx:is_composing() then
        pcall(function()
            ctx:clear()
        end)
        return 2
    end

    local is_modifier = repr:find('Control', 1, true) ~= nil
        or repr:find('Alt', 1, true) ~= nil

    if is_modifier then
        local on = ctx:get_option('prediction')
        if on then
            pcall(function()
                ctx:set_option('prediction', false)
            end)
            suspended = true
        end
    elseif suspended then
        pcall(function()
            ctx:set_option('prediction', true)
        end)
        suspended = false
    end

    return 2 -- kNoop：照樣把按鍵交返系統
end

return M
