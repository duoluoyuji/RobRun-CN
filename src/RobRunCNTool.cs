using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("ROB RUN 简繁双语一键汉化工具")]
[assembly: AssemblyDescription("ROB RUN 简繁中文一键汉化与还原工具")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("B站@吃素的佩奇")]
[assembly: AssemblyProduct("RobRunCNTool")]
[assembly: AssemblyCopyright("Copyright © 2026 B站@吃素的佩奇")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion("1.3.0.0")]
[assembly: AssemblyFileVersion("1.3.0.0")]

namespace RobRunCN {
    public class ClientTarget {
        public string ClientType { get; set; }
        public string Path { get; set; }
        public string State { get; set; }

        public override string ToString() {
            string st = string.IsNullOrEmpty(State) ? "" : "   [" + State + "]";
            return "[" + ClientType + "] " + Path + st;
        }
    }

    public class MainForm : Form {
        private Panel topPanel;
        private Label lblTitle;
        private Label lblSubTitle;
        private Button btnBili;
        private Label lblUpdate;

        private GroupBox grpClients;
        private CheckedListBox chkListClients;
        private Button btnRescan;
        private Button btnBrowse;

        private GroupBox grpActions;
        private Label lblDiscText;
        private CheckBox chkAgree;
        private Button btnInstallZh;
        private Button btnInstallTw;
        private Button btnRestore;

        private GroupBox grpLog;
        private TextBox txtLog;

        private List<ClientTarget> detectedRoots;
        private string toolDir;
        private string zhDir;
        private string zhTwDir;
        private string currentVersion = "1.3";

        private static readonly string[] Zh0Names = new string[] {
            "inbuild_assets_all.bundle",
            "localization-locales_assets_all.bundle",
            "localization-string-tables-english(unitedstates)(en-us)_assets_all.bundle",
            "localization-string-tables-french(fr)_assets_all.bundle",
            "localization-string-tables-german(de)_assets_all.bundle",
            "localization-string-tables-portuguese(pt)_assets_all.bundle",
            "localization-string-tables-russian(russia)(ru-ru)_assets_all.bundle",
            "localization-string-tables-spanish(es)_assets_all.bundle"
        };

        public MainForm() {
            detectedRoots = new List<ClientTarget>();
            toolDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');
            zhDir = Path.Combine(toolDir, "zh");
            zhTwDir = Path.Combine(toolDir, "zh-TW");

            InitializeComponent();
        }

        private void InitializeComponent() {
            this.Text = "ROB RUN 简繁双语一键汉化工具 v" + currentVersion + " - 制作: B站@吃素的佩奇";
            this.ClientSize = new Size(745, 725);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;
            this.AutoScaleMode = AutoScaleMode.None;
            this.BackColor = Color.FromArgb(243, 244, 246);
            this.ForeColor = Color.FromArgb(31, 41, 55);
            this.Font = new Font("Microsoft YaHei UI", 9.5f);

            // ================= 顶部横幅 =================
            topPanel = new Panel();
            topPanel.Dock = DockStyle.Top;
            topPanel.Height = 75;
            topPanel.BackColor = Color.FromArgb(255, 255, 255);

            lblTitle = new Label();
            lblTitle.Text = "ROB RUN 简繁双语一键汉化工具";
            lblTitle.Font = new Font("Microsoft YaHei UI", 16f, FontStyle.Bold);
            lblTitle.ForeColor = Color.FromArgb(17, 24, 39);
            lblTitle.Location = new Point(20, 12);
            lblTitle.AutoSize = true;

            lblSubTitle = new Label();
            lblSubTitle.Text = "制作: B站@吃素的佩奇";
            lblSubTitle.Font = new Font("Microsoft YaHei UI", 9.5f);
            lblSubTitle.ForeColor = Color.FromArgb(107, 114, 128);
            lblSubTitle.Location = new Point(22, 45);
            lblSubTitle.AutoSize = true;

            lblUpdate = new Label();
            lblUpdate.Text = "";
            lblUpdate.Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);
            lblUpdate.ForeColor = Color.FromArgb(220, 120, 0);
            lblUpdate.Location = new Point(300, 22);
            lblUpdate.Size = new Size(285, 32);
            lblUpdate.TextAlign = ContentAlignment.MiddleLeft;
            lblUpdate.Cursor = Cursors.Hand;
            lblUpdate.Visible = false;
            lblUpdate.Click += (s, e) => {
                try { Process.Start("https://github.com/duoluoyuji/RobRun-CN/releases/latest"); } catch {}
            };

            btnBili = new Button();
            btnBili.Text = "关注作者B站";
            btnBili.Location = new Point(595, 18);
            btnBili.Size = new Size(125, 38);
            btnBili.BackColor = Color.FromArgb(251, 114, 153);
            btnBili.ForeColor = Color.White;
            btnBili.FlatStyle = FlatStyle.Flat;
            btnBili.FlatAppearance.BorderSize = 0;
            btnBili.Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);
            btnBili.Cursor = Cursors.Hand;
            btnBili.Click += (s, e) => {
                try { Process.Start("https://space.bilibili.com/3379443"); } catch {}
            };

            topPanel.Controls.Add(lblTitle);
            topPanel.Controls.Add(lblSubTitle);
            topPanel.Controls.Add(lblUpdate);
            topPanel.Controls.Add(btnBili);
            this.Controls.Add(topPanel);

            // ================= 客户端列表区域 =================
            grpClients = new GroupBox();
            grpClients.Text = " 游戏安装路径检测 ";
            grpClients.Location = new Point(20, 90);
            grpClients.Size = new Size(705, 140);
            grpClients.ForeColor = Color.FromArgb(31, 41, 55);
            grpClients.Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);

            chkListClients = new CheckedListBox();
            chkListClients.Location = new Point(15, 25);
            chkListClients.Size = new Size(540, 100);
            chkListClients.CheckOnClick = true;
            chkListClients.Font = new Font("Microsoft YaHei UI", 9f, FontStyle.Regular);

            btnRescan = new Button();
            btnRescan.Text = "重新扫描";
            btnRescan.Location = new Point(570, 25);
            btnRescan.Size = new Size(120, 42);
            btnRescan.BackColor = Color.FromArgb(255, 255, 255);
            btnRescan.FlatStyle = FlatStyle.Flat;
            btnRescan.FlatAppearance.BorderColor = Color.FromArgb(209, 213, 219);
            btnRescan.Cursor = Cursors.Hand;
            btnRescan.Font = new Font("Microsoft YaHei UI", 9.5f);
            btnRescan.Click += (s, e) => { RunScan(); };

            btnBrowse = new Button();
            btnBrowse.Text = "手动选择路径";
            btnBrowse.Location = new Point(570, 77);
            btnBrowse.Size = new Size(120, 42);
            btnBrowse.BackColor = Color.FromArgb(255, 255, 255);
            btnBrowse.FlatStyle = FlatStyle.Flat;
            btnBrowse.FlatAppearance.BorderColor = Color.FromArgb(209, 213, 219);
            btnBrowse.Cursor = Cursors.Hand;
            btnBrowse.Font = new Font("Microsoft YaHei UI", 9.5f);
            btnBrowse.Click += (s, e) => { OnBrowse(); };

            grpClients.Controls.Add(chkListClients);
            grpClients.Controls.Add(btnRescan);
            grpClients.Controls.Add(btnBrowse);
            this.Controls.Add(grpClients);

            // ================= 操作按钮与免责面板 =================
            grpActions = new GroupBox();
            grpActions.Text = " 免责声明与操作面板 ";
            grpActions.Location = new Point(20, 240);
            grpActions.Size = new Size(705, 218);
            grpActions.ForeColor = Color.FromArgb(31, 41, 55);
            grpActions.Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);

            lblDiscText = new Label();
            lblDiscText.Text = "【免责声明】本汉化补丁仅供技术交流与学习参考。任何对游戏客户端的修改行为均可能存在不可预知的风险（包括但不限于游戏运行异常、版本更新后失效或账号封禁风险）。请使用者自行评估，使用本工具产生的一切后果及风险均由使用者本人自担。\r\n【操作须知】执行汉化安装或还原前，请务必确保已完全退出 ROB RUN 游戏进程。";
            lblDiscText.Font = new Font("Microsoft YaHei UI", 9.0f);
            lblDiscText.ForeColor = Color.FromArgb(120, 53, 15);
            lblDiscText.BackColor = Color.FromArgb(254, 243, 199);
            lblDiscText.Location = new Point(15, 24);
            lblDiscText.Size = new Size(675, 78);
            lblDiscText.Padding = new Padding(8, 6, 8, 6);

            chkAgree = new CheckBox();
            chkAgree.Text = "我已知晓并自愿承担汉化修改可能带来的一切风险";
            chkAgree.Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);
            chkAgree.ForeColor = Color.FromArgb(185, 28, 28);
            chkAgree.Location = new Point(15, 108);
            chkAgree.Size = new Size(675, 28);
            chkAgree.AutoSize = false;
            chkAgree.CheckedChanged += (s, e) => {
                bool ok = chkAgree.Checked;
                btnInstallZh.Enabled = ok;
                btnInstallZh.BackColor = ok ? Color.FromArgb(22, 163, 74) : Color.FromArgb(229, 231, 235);
                btnInstallZh.ForeColor = ok ? Color.White : Color.FromArgb(156, 163, 175);

                btnInstallTw.Enabled = ok;
                btnInstallTw.BackColor = ok ? Color.FromArgb(2, 132, 199) : Color.FromArgb(229, 231, 235);
                btnInstallTw.ForeColor = ok ? Color.White : Color.FromArgb(156, 163, 175);
            };

            // 简体安装按钮
            btnInstallZh = new Button();
            btnInstallZh.Text = "一键应用【简体中文】";
            btnInstallZh.Location = new Point(15, 144);
            btnInstallZh.Size = new Size(215, 56);
            btnInstallZh.BackColor = Color.FromArgb(229, 231, 235);
            btnInstallZh.ForeColor = Color.FromArgb(156, 163, 175);
            btnInstallZh.FlatStyle = FlatStyle.Flat;
            btnInstallZh.FlatAppearance.BorderSize = 0;
            btnInstallZh.Font = new Font("Microsoft YaHei UI", 11f, FontStyle.Bold);
            btnInstallZh.Cursor = Cursors.Hand;
            btnInstallZh.Enabled = false;
            btnInstallZh.Click += (s, e) => { ExecuteInstall("zh", "简体中文", zhDir); };

            // 繁体安装按钮
            btnInstallTw = new Button();
            btnInstallTw.Text = "一键应用【繁体中文】";
            btnInstallTw.Location = new Point(245, 144);
            btnInstallTw.Size = new Size(215, 56);
            btnInstallTw.BackColor = Color.FromArgb(229, 231, 235);
            btnInstallTw.ForeColor = Color.FromArgb(156, 163, 175);
            btnInstallTw.FlatStyle = FlatStyle.Flat;
            btnInstallTw.FlatAppearance.BorderSize = 0;
            btnInstallTw.Font = new Font("Microsoft YaHei UI", 11f, FontStyle.Bold);
            btnInstallTw.Cursor = Cursors.Hand;
            btnInstallTw.Enabled = false;
            btnInstallTw.Click += (s, e) => { ExecuteInstall("zh-TW", "繁体中文", zhTwDir); };

            // 还原按钮（随时可用，无需勾选协议）
            btnRestore = new Button();
            btnRestore.Text = "一键还原官方英文";
            btnRestore.Location = new Point(475, 144);
            btnRestore.Size = new Size(215, 56);
            btnRestore.BackColor = Color.FromArgb(220, 38, 38);
            btnRestore.ForeColor = Color.White;
            btnRestore.FlatStyle = FlatStyle.Flat;
            btnRestore.FlatAppearance.BorderSize = 0;
            btnRestore.Font = new Font("Microsoft YaHei UI", 11f, FontStyle.Bold);
            btnRestore.Cursor = Cursors.Hand;
            btnRestore.Enabled = true;
            btnRestore.Click += (s, e) => { ExecuteRestore(); };

            grpActions.Controls.Add(lblDiscText);
            grpActions.Controls.Add(chkAgree);
            grpActions.Controls.Add(btnInstallZh);
            grpActions.Controls.Add(btnInstallTw);
            grpActions.Controls.Add(btnRestore);
            this.Controls.Add(grpActions);

            // ================= 实时日志区域 =================
            grpLog = new GroupBox();
            grpLog.Text = " 实时日志与状态显示 ";
            grpLog.Location = new Point(20, 468);
            grpLog.Size = new Size(705, 235);
            grpLog.ForeColor = Color.FromArgb(31, 41, 55);
            grpLog.Font = new Font("Microsoft YaHei UI", 9.5f, FontStyle.Bold);

            txtLog = new TextBox();
            txtLog.Location = new Point(15, 25);
            txtLog.Size = new Size(675, 195);
            txtLog.Multiline = true;
            txtLog.ReadOnly = true;
            txtLog.ScrollBars = ScrollBars.Vertical;
            txtLog.BackColor = Color.FromArgb(17, 24, 39);
            txtLog.ForeColor = Color.FromArgb(52, 211, 153);
            txtLog.Font = new Font("Consolas", 9f);

            grpLog.Controls.Add(txtLog);
            this.Controls.Add(grpLog);

            this.Load += (s, e) => {
                AppendLog("==========================================================");
                AppendLog("  ROB RUN 简繁双语一键汉化工具 v" + currentVersion + " 已就绪");
                AppendLog("==========================================================");
                RunScan();
                CheckUpdateAsync();
            };
        }

        // ================= 更新检查（v1.3 新增）=================
        private const string UpdateCheckUrl = "https://raw.githubusercontent.com/duoluoyuji/RobRun-CN/main/version.json";

        private static int[] ParseVersion(string v) {
            if (string.IsNullOrEmpty(v)) return new int[0];
            string[] parts = v.Trim().TrimStart('v', 'V').Split('.');
            int[] nums = new int[parts.Length];
            for (int i = 0; i < parts.Length; i++) {
                int n;
                if (!int.TryParse(parts[i], out n)) n = 0;
                nums[i] = n;
            }
            return nums;
        }

        private static bool IsNewer(string remote, string local) {
            int[] r = ParseVersion(remote), l = ParseVersion(local);
            int len = Math.Max(r.Length, l.Length);
            for (int i = 0; i < len; i++) {
                int a = i < r.Length ? r[i] : 0;
                int b = i < l.Length ? l[i] : 0;
                if (a != b) return a > b;
            }
            return false;
        }

        private void CheckUpdateAsync() {
            ThreadPool.QueueUserWorkItem(delegate {
                try {
                    using (WebClient wc = new WebClient()) {
                        wc.Encoding = System.Text.Encoding.UTF8;
                        wc.Headers.Add("User-Agent", "RobRunCNTool/" + currentVersion);
                        Task<string> t = wc.DownloadStringTaskAsync(new Uri(UpdateCheckUrl));
                        if (!t.Wait(4000)) return;
                        string body = t.Result;
                        Match m = Regex.Match(body, "\"version\"\\s*:\\s*\"([^\"]+)\"");
                        if (!m.Success) return;
                        string remote = m.Groups[1].Value;
                        if (IsNewer(remote, currentVersion)) {
                            this.BeginInvoke(new Action(delegate {
                                lblUpdate.Text = "发现新版本 v" + remote + "，点此下载";
                                lblUpdate.Visible = true;
                                AppendLog("发现新版本 v" + remote + "（当前 v" + currentVersion + "），可点击窗口右上角提示前往下载");
                            }));
                        }
                    }
                } catch { /* 网络不可用时静默忽略 */ }
            });
        }

        private void AppendLog(string msg) {
            if (txtLog.InvokeRequired) {
                txtLog.Invoke(new Action<string>(AppendLog), msg);
                return;
            }
            string timeStr = DateTime.Now.ToString("HH:mm:ss");
            txtLog.AppendText("[" + timeStr + "] " + msg + Environment.NewLine);
        }

        private void RunScan() {
            chkListClients.Items.Clear();
            AppendLog("正在扫描本地 ROB RUN 游戏安装路径...");

            detectedRoots = ScanAllGameRoots();

            if (detectedRoots.Count == 0) {
                AppendLog("【提示】未自动扫描到 ROB RUN 游戏目录。请点击右侧「手动选择路径」指定。");
            } else {
                foreach (var t in detectedRoots) {
                    t.State = GetClientState(t.Path);
                    chkListClients.Items.Add(t.ToString(), true);
                    AppendLog("-> 发现游戏路径: " + t.Path + "  当前状态: " + t.State);
                }
                AppendLog("扫描完成！成功识别到 " + detectedRoots.Count + " 个有效游戏路径。");
            }
        }

        private void OnBrowse() {
            using (var fbd = new FolderBrowserDialog()) {
                fbd.Description = "请选择 ROB RUN 游戏安装根目录（包含 ROB RUN.exe 的文件夹）";
                fbd.ShowNewFolderButton = false;
                if (fbd.ShowDialog(this) == DialogResult.OK) {
                    string resolved = ResolveGameRoot(fbd.SelectedPath);
                    if (resolved != null) {
                        AddTargetIfNotExists(detectedRoots, "自定义选择", resolved);
                        chkListClients.Items.Clear();
                        foreach (var t in detectedRoots) {
                            t.State = GetClientState(t.Path);
                            chkListClients.Items.Add(t.ToString(), true);
                        }
                        AppendLog("成功手动指定游戏路径: " + resolved);
                    } else {
                        MessageBox.Show("所选目录未找到 ROB RUN.exe 或游戏核心资源！\n\n请确认选择了正确的 Rob Run 游戏目录。",
                            "目录无效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                }
            }
        }

        private bool IsGameRoot(string p) {
            if (string.IsNullOrEmpty(p)) return false;
            if (File.Exists(Path.Combine(p, "ROB RUN.exe"))) return true;
            if (Directory.Exists(Path.Combine(p, @"ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64"))) return true;
            return false;
        }

        private string ResolveGameRoot(string sel) {
            if (string.IsNullOrEmpty(sel)) return null;
            if (IsGameRoot(sel)) return sel;
            string sub = Path.Combine(sel, "Rob Run");
            if (IsGameRoot(sub)) return sub;
            string parent = Path.GetDirectoryName(sel);
            if (parent != null && IsGameRoot(parent)) return parent;
            return null;
        }

        private void AddTargetIfNotExists(List<ClientTarget> list, string clientType, string path) {
            if (string.IsNullOrEmpty(path)) return;
            string cleanPath = path.TrimEnd('\\', '/');
            foreach (var cur in list) {
                if (string.Equals(cur.Path.TrimEnd('\\', '/'), cleanPath, StringComparison.OrdinalIgnoreCase)) return;
            }
            list.Add(new ClientTarget { ClientType = clientType, Path = cleanPath });
        }

        private List<ClientTarget> ScanAllGameRoots() {
            var result = new List<ClientTarget>();
            var steamAppsCandidates = new List<string>();

            // 1. Steam 注册表扫描
            try {
                using (var steamKey = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam")) {
                    if (steamKey != null) {
                        object sp = steamKey.GetValue("SteamPath");
                        if (sp != null) {
                            string sa = Path.Combine(sp.ToString().Replace('/', '\\'), "steamapps");
                            if (Directory.Exists(sa)) steamAppsCandidates.Add(sa);
                        }
                    }
                }
            } catch {}

            // 2. libraryfolders.vdf 扫描所有库
            var vdfFiles = new List<string>();
            foreach (var sa in steamAppsCandidates.ToArray()) {
                vdfFiles.Add(Path.Combine(sa, "libraryfolders.vdf"));
                string parent = Path.GetDirectoryName(sa);
                if (!string.IsNullOrEmpty(parent)) vdfFiles.Add(Path.Combine(parent, @"config\libraryfolders.vdf"));
            }

            foreach (var vdf in vdfFiles) {
                if (!File.Exists(vdf)) continue;
                try {
                    string vt = File.ReadAllText(vdf);
                    var matches = Regex.Matches(vt, "\"path\"\\s+\"([^\"]+)\"");
                    foreach (Match m in matches) {
                        string p = m.Groups[1].Value.Replace(@"\\", @"\");
                        string sa = Path.Combine(p, "steamapps");
                        if (Directory.Exists(sa) && !steamAppsCandidates.Contains(sa)) {
                            steamAppsCandidates.Add(sa);
                        }
                    }
                } catch {}
            }

            // 3. 在所有候选 steamapps 目录下寻找 Rob Run
            foreach (var sa in steamAppsCandidates) {
                string cand = Path.Combine(sa, @"common\Rob Run");
                if (IsGameRoot(cand)) {
                    AddTargetIfNotExists(result, "Steam库", cand);
                }
            }

            // 4. 当前工具目录及上级目录识别（防玩家直接解压在游戏根目录）
            if (IsGameRoot(toolDir)) {
                AddTargetIfNotExists(result, "当前目录", toolDir);
            }
            string parentOfTool = Path.GetDirectoryName(toolDir);
            if (!string.IsNullOrEmpty(parentOfTool) && IsGameRoot(parentOfTool)) {
                AddTargetIfNotExists(result, "上级目录", parentOfTool);
            }

            // 5. 遍历全盘所有可用驱动器深度扫描兜底
            try {
                foreach (var d in DriveInfo.GetDrives()) {
                    if (d.IsReady) {
                        string root = d.RootDirectory.FullName;
                        string p1 = Path.Combine(root, @"SteamLibrary\steamapps\common\Rob Run");
                        string p2 = Path.Combine(root, @"steamapps\common\Rob Run");
                        string p3 = Path.Combine(root, @"Program Files (x86)\Steam\steamapps\common\Rob Run");
                        string p4 = Path.Combine(root, @"Steam\steamapps\common\Rob Run");
                        if (IsGameRoot(p1)) AddTargetIfNotExists(result, "磁盘(" + d.Name.TrimEnd('\\') + ")", p1);
                        if (IsGameRoot(p2)) AddTargetIfNotExists(result, "磁盘(" + d.Name.TrimEnd('\\') + ")", p2);
                        if (IsGameRoot(p3)) AddTargetIfNotExists(result, "磁盘(" + d.Name.TrimEnd('\\') + ")", p3);
                        if (IsGameRoot(p4)) AddTargetIfNotExists(result, "磁盘(" + d.Name.TrimEnd('\\') + ")", p4);
                    }
                }
            } catch {}

            return result;
        }

        private string GetClientState(string root) {
            string aa = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64");
            string inbuildZh = Path.Combine(aa, "inbuild_assets_zh0.bundle");
            if (!File.Exists(inbuildZh)) {
                return "未安装 (官方原版)";
            }

            string localesZh = Path.Combine(aa, "localization-locales_assets_zh0.bundle");
            if (File.Exists(localesZh)) {
                try {
                    byte[] data = File.ReadAllBytes(localesZh);
                    string str = Encoding.UTF8.GetString(data);
                    if (str.Contains("zh-TW") || str.Contains("繁體中文")) {
                        return "已安装【繁体中文】";
                    }
                } catch {}
            }
            return "已安装【简体中文】";
        }

        private List<string> GetSelectedTargets() {
            var list = new List<string>();
            for (int i = 0; i < chkListClients.Items.Count; i++) {
                if (chkListClients.GetItemChecked(i) && i < detectedRoots.Count) {
                    list.Add(detectedRoots[i].Path);
                }
            }
            return list;
        }

        private bool EnsureGameClosed() {
            var procs = Process.GetProcessesByName("ROB RUN");
            if (procs.Length > 0) {
                var res = MessageBox.Show(
                    "检测到 ROB RUN 游戏正在运行！\n\n为保证文件正确写入，请先退出游戏，然后点击「确定」继续。\n（若点击「取消」将中止当前操作）",
                    "游戏正在运行", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning);
                if (res != DialogResult.OK) return false;

                for (int i = 0; i < 10; i++) {
                    Thread.Sleep(500);
                    if (Process.GetProcessesByName("ROB RUN").Length == 0) return true;
                }
                MessageBox.Show("游戏进程仍在运行，请手动退出后重试！", "提示", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return false;
            }
            return true;
        }

        private byte[] ReplaceBytes(byte[] src, byte[] search, byte[] repl) {
            var dst = new List<byte>(src.Length);
            int n = src.Length;
            int m = search.Length;
            int i = 0;
            while (i < n) {
                bool match = false;
                if (m > 0 && i + m <= n) {
                    match = true;
                    for (int j = 0; j < m; j++) {
                        if (src[i + j] != search[j]) { match = false; break; }
                    }
                }
                if (match) {
                    dst.AddRange(repl);
                    i += m;
                } else {
                    dst.Add(src[i]);
                    i++;
                }
            }
            return dst.ToArray();
        }

        private string GetCacheDir() {
            string localLow = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData) + "Low";
            return Path.Combine(localLow, @"Kefir\ROB RUN\com.unity.addressables");
        }

        private string GetCatalogName(string root) {
            try {
                string settings = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\settings.json");
                if (File.Exists(settings)) {
                    string txt = File.ReadAllText(settings, Encoding.UTF8);
                    var ms = Regex.Matches(txt, "catalog_[0-9][0-9\\.]+");
                    var cands = new List<string>();
                    foreach (Match m in ms) {
                        string v = m.Value.TrimEnd('.');
                        if (v.Split('.').Length - 1 >= 3) cands.Add(v);
                    }
                    if (cands.Count > 0) {
                        cands.Sort((a, b) => b.Length.CompareTo(a.Length));
                        return cands[0];
                    }
                }
            } catch {}
            try {
                string cache = GetCacheDir();
                if (Directory.Exists(cache)) {
                    var f = Directory.GetFiles(cache, "catalog_*.bin");
                    if (f.Length > 0) return Path.GetFileNameWithoutExtension(f[0]);
                }
            } catch {}
            return "catalog";
        }

        // 只改写【用户缓存】catalog；安装目录的 catalog.bin / catalog.hash 一律不动（动了会触发反作弊“未知的文件版本”）
        private void ApplyCatalogRedirect(string root) {
            string masterBin = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\catalog.bin");
            string masterHash = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\catalog.hash");
            if (!File.Exists(masterBin)) throw new FileNotFoundException("找不到主 catalog.bin: " + masterBin);

            string cache = GetCacheDir();
            if (!Directory.Exists(cache)) Directory.CreateDirectory(cache);
            string catName = GetCatalogName(root);
            string cacheBin = Path.Combine(cache, catName + ".bin");
            string cacheHash = Path.Combine(cache, catName + ".hash");

            byte[] data = File.ReadAllBytes(masterBin);
            Encoding ascii = Encoding.ASCII;
            int hits = 0;
            foreach (var n in Zh0Names) {
                string z = n.Replace("_all.bundle", "_zh0.bundle");
                byte[] find = ascii.GetBytes(n), repl = ascii.GetBytes(z);
                if (find.Length != repl.Length) continue;
                if (ascii.GetString(data).Contains(n)) { data = ReplaceBytes(data, find, repl); hits++; }
            }
            File.WriteAllBytes(cacheBin, data);
            if (File.Exists(masterHash)) File.Copy(masterHash, cacheHash, true);
            AppendLog("-> 已改写用户缓存 catalog (" + catName + ")，重定向 " + hits + "/8 个资源包；安装目录文件未改动");
        }

        private void ExecuteInstall(string langCode, string langTitle, string sourceDir) {
            var targets = GetSelectedTargets();
            if (targets.Count == 0) {
                MessageBox.Show("请至少勾选一个目标游戏路径！", "未选择路径", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!chkAgree.Checked) {
                MessageBox.Show("请先勾选免责声明，确认自愿承担修改风险！", "未确认免责声明", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!EnsureGameClosed()) return;

            AppendLog("==========================================================");
            AppendLog(">>> 开始执行【" + langTitle + "】汉化安装流程...");

            int success = 0;
            foreach (string root in targets) {
                try {
                    AppendLog("正在安装至: " + root);
                    string aa = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64");
                    if (!Directory.Exists(aa)) Directory.CreateDirectory(aa);

                    foreach (var n in Zh0Names) {
                        string src = Path.Combine(sourceDir, n);
                        if (!File.Exists(src)) {
                            throw new FileNotFoundException("汉化资源包缺失: " + src);
                        }
                        string dst = Path.Combine(aa, n.Replace("_all.bundle", "_zh0.bundle"));
                        File.Copy(src, dst, true);
                        AppendLog("  已写入: " + Path.GetFileName(dst) + " (" + new FileInfo(dst).Length + " 字节)");
                    }

                    ApplyCatalogRedirect(root);
                    success++;
                    AppendLog("【成功】" + langTitle + " 已成功部署至: " + root);
                } catch (Exception ex) {
                    AppendLog("【错误】安装失败: " + ex.Message);
                    MessageBox.Show("安装失败：\n" + ex.Message, "错误", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }

            RunScan();
            if (success > 0) {
                MessageBox.Show("【" + langTitle + "】安装完成！\n\n现在可直接启动游戏体验汉化。",
                    "汉化安装完成", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void ExecuteRestore() {
            var targets = GetSelectedTargets();
            if (targets.Count == 0) {
                MessageBox.Show("请至少勾选一个目标游戏路径！", "未选择路径", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!EnsureGameClosed()) return;

            AppendLog("==========================================================");
            AppendLog(">>> 正在执行一键还原官方原版英文...");

            int success = 0;
            foreach (string root in targets) {
                try {
                    string aa = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64");
                    foreach (var n in Zh0Names) {
                        string z = Path.Combine(aa, n.Replace("_all.bundle", "_zh0.bundle"));
                        if (File.Exists(z)) {
                            File.Delete(z);
                            AppendLog("  已清理汉化载荷: " + Path.GetFileName(z));
                        }
                    }

                    string masterBin = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\catalog.bin");
                    string masterHash = Path.Combine(root, @"ROB RUN_Data\StreamingAssets\aa\catalog.hash");
                    string cache = GetCacheDir();
                    if (Directory.Exists(cache)) {
                        try {
                            string catName = GetCatalogName(root);
                            string cacheBin = Path.Combine(cache, catName + ".bin");
                            if (File.Exists(masterBin) && File.Exists(cacheBin)) {
                                File.Copy(masterBin, cacheBin, true);
                                AppendLog("  已把用户缓存 catalog 还原为官方版本");
                            }
                            string cacheHash = Path.Combine(cache, catName + ".hash");
                            if (File.Exists(masterHash) && File.Exists(cacheHash)) {
                                File.Copy(masterHash, cacheHash, true);
                            }
                        } catch {}
                    }

                    success++;
                    AppendLog("【成功】已完全还原官方原版英文: " + root);
                } catch (Exception ex) {
                    AppendLog("【错误】还原失败: " + ex.Message);
                    MessageBox.Show("还原失败：\n" + ex.Message, "错误", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }

            RunScan();
            if (success > 0) {
                MessageBox.Show("已成功还原官方原版英文！\n\n游戏已回落至官方纯净状态。",
                    "还原成功", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        [STAThread]
        public static void Main() {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
