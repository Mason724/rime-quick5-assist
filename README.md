# 速成聯想（Rime 小狼毫）：打完字自動猜下一個詞

給 **Windows 小狼毫（Weasel）速成** 用的三件小玩意：

1. **自動聯想**：打完一個詞，候選列自動出下一個詞（`的、不、要、是`），用的是 Rime 官方 `librime-predict` 插件的繁體詞對詞資料庫。
2. **個人配詞學習**：主人每上屏兩個相鄰的詞，就記一筆到本機 `user_pairs.txt`；下次打同一個詞，慣用搭配排最前，並標「慣用」。
3. **尾隨單字**：打三碼以上（例如 `mukg` = 現在）時，候選最後會補上頭兩碼的單字（電、現、元…），標「單字」，方便只要一個字時直接選。

另外附一個排版設定：候選視窗改成**一行五、六個、最多兩行**。

---

## 需求

- Windows + [小狼毫 Weasel](https://github.com/rime/weasel) 0.17 以上
- **`rime.dll` 必須內建 `librime-predict` 插件**（這是關鍵，沒有它就沒有聯想）。
  實測可用：官方 0.17.4（librime 1.13.1）與 [Wisdom-Weasel](https://github.com/scukeqi/Wisdom-Weasel)（librime 1.15.0）。
  檢查方法：`rime.dll` 裡有 `predict_translator` 這個字串就多數有。
- 已有一個速成方案，`schema_id` 為 `quick5`（本補丁按這個 id 寫；若不同，改 `quick5.custom.yaml` 的檔名即可）

## 開／關聯想

**預設是開的。** 想關掉（例如覺得彈窗打擾、或者打字時不想被搶焦點），有兩個方法：

1. **改設定（最可靠）**：打開 `quick5.custom.yaml`，把這一行

   ```yaml
   'switches/@after last': {name: prediction, states: [聯想關, 聯想開], reset: 1}
   ```

   的 `reset: 1` 改成 `reset: 0`，存檔，然後重新部署。
2. **用方案選單**：在小狼毫圖示按右鍵 →「輸入法設定」／按 `F4` 開方案選單，找「聯想」開關切換（不同版本界面略有差異）。

關掉聯想之後，其餘功能照樣運作：改善過的詞庫、尾隨單字、兩行排版，以及**背景仍然會記錄你的慣用配詞**（`user_pairs.txt`），將來開回聯想即刻有用，不必重新學。

## 已知問題與解法（本專案已附）

| 症狀 | 原因 | 解法 |
|---|---|---|
| 按 `Ctrl`／複製貼上時，突然彈出候選窗 | 插件每次 context 更新都會重算預測，修飾鍵也算 | 附 `lua/quiet_ctrl.lua`：按 Ctrl／Alt 時暫停預測，放手後自動恢復 |
| 聯想窗出著時，第一下 `Backspace` 好像沒反應（字沒刪到）| 插件把第一下 Backspace 當成「關窗」，不讓它刪字 | 同上：`quiet_ctrl` 會先關窗，再把按鍵交回系統，正常刪字 |

如果不想用這兩個補丁，就把 `quick5.custom.yaml` 裡 `lua_processor@*quiet_ctrl` 那一行刪掉，然後把聯想關掉。

## 安裝

1. 把 `quick5.custom.yaml`、`quick5_phrase.schema.yaml`、`quick5.schema.yaml`、`lua/assist.lua` 複製到 Rime 用戶目錄
   （通常係 `%APPDATA%\Rime`，即 `C:\Users\<你>\AppData\Roaming\Rime`）。
2. 下載官方預測資料庫：

   ```powershell
   curl -L -o "$env:APPDATA\Rime\predict.db" `
     https://github.com/rime/librime-predict/releases/download/data-1.0/predict.db
   ```

3. 重新部署（托盤圖示 →「重新部署」）。
4. 打一個詞上屏，停手，看看候選列有沒有自動出下一個詞。

> 小提示：`quick5.schema.yaml` 是參考用的完整方案（它依賴 `cn_dicts/` 裡 rime-ice 的詞庫）。
> 如果主人本身已經有一套在用的速成方案，**只需要 `quick5.custom.yaml` + `lua/assist.lua` + `predict.db`**，
> 把 `quick5.custom.yaml` 改名成自己方案 id 的 `.custom.yaml` 即可。

## 排版：一行五、六個、最多兩行

在 `weasel.yaml` 的 `style:` 底下：

```yaml
style:
  layout:
    max_width: 700    # 候選框最大寬度，超過就換行（想要 5 個一行就 600–700，想闊一點就 800）
```

再在 `default.yaml` 把一頁候選數設成 10：

```yaml
menu:
  page_size: 10
```

## 個人配詞學習

- 檔案：`%APPDATA%\Rime\user_pairs.txt`，一行一筆，格式 `上一個詞<TAB>下一個詞`（Tab 分隔）。
- 純本機、純文字、不會上傳；想清空就直接刪掉這個檔（或刪掉不想留的幾行），重新部署即生效。
- 只記含中文字的配詞，標點與英文會被自動略過。

## 除錯

- `%APPDATA%\Rime\learn_debug.log`：空碼時有沒有被叫到（每次上屏一行）。
- Rime 日誌：`%LOCALAPPDATA%\Temp\rime.weasel\*.log`。

## 已知限制

- 聯想只看**上一個詞**（librime-predict 的設計），看不懂整句上下文。
- `predict.db` 來自 essay + octagram 語料，偏書面語，偶爾會出文言味的搭配。
- 打兩碼時單字本來就會出，所以「尾隨單字」只加在三碼以上。

## 致謝

- **DeepSeek（AI 助理）**：本專案的方案補丁、`lua/assist.lua`、安裝腳本、README 與大部分除錯，均由 **DeepSeek** 於 2026-11-24 協助撰寫；主人在真實輸入環境反覆試用、指正與拍板。
- [RIME 專案](https://github.com/rime)、[rime-ice](https://github.com/iDvel/rime-ice)、[Wisdom-Weasel](https://github.com/scukeqi/Wisdom-Weasel) 的作者。

## 授權與出處

- 本專案的腳本與補丁：MIT。
- `predict.db`：來自 [rime/librime-predict](https://github.com/rime/librime-predict)（RIME 專案，BSD 授權），請依原專案授權使用。
- 詞庫與方案結構源自 [rime-ice](https://github.com/iDvel/rime-ice) 與 [rime/librime](https://github.com/rime/librime)。
