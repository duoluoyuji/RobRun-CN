# 《ROB RUN》汉化维护与资产安全白皮书

> **致后续协助的 AI 与协作者**：  
> 本文档是《ROB RUN》汉化项目的核心架构规范与文件安全清单。在清理文件、增量汉化或版本维护时，**请严格遵守以下规则，切勿误删核心资产与运行环境**。

---

## 一、目录安全分级（红绿灯法则）

### 🔴 绝对严禁删除（核心命脉，删了后续无法维护）

| 路径 | 作用说明 | 为什么不能删 |
| :--- | :--- | :--- |
| **`03_工具\venv\`** | 独立的 Python 运行环境 | 配置了 UnityPy、freetype、numpy、scipy 等底层库，删除后很难重新精确还原依赖。 |
| **`04_交付\pack_zh\`** | 简体中文全量构建载荷 | 包含烘焙好的专属矢量字库 `inbuild_assets_all.bundle`（覆盖全量简体汉字）。 |
| **`04_交付\pack_tw\`** | 繁体中文全量构建载荷 | 包含烘焙好的专属矢量字库 `inbuild_assets_all.bundle`（覆盖 1,987 个繁体汉字，0 缺字 0 模糊）。 |
| **`04_交付\files\`** | 基础母包模板 | `build_pack.py` 打包时强依赖此目录作为原始母包提取基准。 |
| **`02_译料\已译补丁.csv`** | 简体中文主译文词典 | 4,823 条全量主字典，所有更新与发布的基石。 |
| **`02_译料\已译补丁_繁體.csv`** | 繁体中文主译文词典 | 4,823 条全量繁体主字典（台灣慣用詞标准）。 |
| **`01_源文本\strings_en.csv`** | 官方英文原始基线 | 游戏后续更新时，必须与它进行 diff 比对找出新增条目。 |
| **`03_工具\suite\`** | 汉化工具开发套件 | 包含 C# 原生图形界面源码 `RobRunCNTool.cs`、PowerShell 执行逻辑及编译脚本。 |
| **`RobRun-CN\`** | GitHub 开源仓库根目录 | 与远程仓库 `https://github.com/duoluoyuji/RobRun-CN` 强绑定的 Git 工作区。 |

---

### 🟡 核心工作脚本（后续游戏更新时必须运行）

| 文件路径 | 作用 |
| :--- | :--- |
| **`03_工具\build_pack.py`** | 读取翻译字典，自动将译文打入 6 个语言 StringTable bundle。 |
| **`03_工具\patch_perfect_fonts.py`** | 简体字库烘焙核心（4x 超采样 Exact EDT 矢量 SDF 算法）。 |
| **`03_工具\patch_perfect_fonts_tw.py`** | 繁体字库烘焙核心（补齐繁体专用汉字到矢量字库）。 |
| **`03_工具\suite\build_suite.ps1`** | 一键调用系统 `csc.exe` 编译 EXE、组装载荷并压缩输出最终发布包。 |
| **`06_对照表\`** | 各模块（NPC 对话、装备、武器、载具、纹身等）的分类语义参考。 |

---

### 🟢 已清理的废弃垃圾（无需理会，已安全移除）

- ❌ `02\u8bd1\u6599\`：历史误建的乱码空目录（已彻底清理）。
- ❌ `04_交付\_backup_*`：历史早期全量测试大备份（已彻底清理，腾出 167 MB 空间）。
- ❌ `04_交付\` 根目录早期废弃的 `app.ps1`, `汉化工具.vbs` 等（已清理，统一由 `suite\` 管理）。
- 📁 `02_译料\_archive_slices\`：早期 80 多个翻译切片分段文件（已归档入子目录）。
- 📁 `02_译料\_archive_png\` & `03_工具\_debug_png\`：早期字体调试过程截图（已归档入子目录）。

---

## 二、后续游戏更新时的标准维护流程（仅需 3 步）

当 Steam 上的 《ROB RUN》 推送新版本更新时，维护流程如下：

### 第一步：提取新文本并对比差异（Diff）
1. 从更新后的游戏目录提取新版 `strings_en.csv`；
2. 与 `01_源文本\strings_en.csv` 做比对，提取出新增文本条目；
3. 将新增翻译分别追加写入 `02_译料\已译补丁.csv` 和 `02_译料\已译补丁_繁體.csv`。
*(注：若新增文本中含有目前字库未覆盖的生僻繁体汉字，运行一次 `patch_perfect_fonts_tw.py` 即可自动增量烘焙)*

### 第二步：生成简繁资源包（Rebuild Packs）
使用项目自带的独立 Python 环境执行打包命令：
```powershell
& "F:\RobRun_汉化接手\03_工具\venv\Scripts\python.exe" "F:\RobRun_汉化接手\03_工具\build_pack.py" "F:\RobRun_汉化接手\02_译料\已译补丁.csv" "F:\RobRun_汉化接手\04_交付\pack_zh"
& "F:\RobRun_汉化接手\03_工具\venv\Scripts\python.exe" "F:\RobRun_汉化接手\03_工具\build_pack.py" "F:\RobRun_汉化接手\02_译料\已译补丁_繁體.csv" "F:\RobRun_汉化接手\04_交付\pack_tw"
```

### 第三步：一键编译与打包发布（Build Suite）
运行套件编译打包脚本：
```powershell
powershell -ExecutionPolicy Bypass -File "F:\RobRun_汉化接手\03_工具\suite\build_suite.ps1"
```
完成后会自动在 `04_交付` 生成最新的 `ROB_RUN_汉化工具_v1.0.zip`，同步拷贝到桌面并推送到 GitHub Release 即可完成更新维护！
