-- Pull in the wezterm API
local wezterm = require("wezterm")

local function is_windows()
	return wezterm.target_triple and wezterm.target_triple:find("windows") ~= nil
end

local function url_decode(s)
	return (s:gsub("%%(%x%x)", function(h)
		return string.char(tonumber(h, 16))
	end))
end

-- 必要ならホスト名のエイリアス変換
local HOST_ALIAS = {
	-- ["winter"] = "winter",  -- ~/.ssh/config の Host 名に合わせたい時に設定
}

local function open_in_vscode(window, pane)
	local cwd_uri = pane:get_current_working_dir()
	if not cwd_uri then
		wezterm.log_error("CWDが取得できません")
		return
	end
	local uri = tostring(cwd_uri)
	-- wezterm.log_info("uri: " .. uri) -- デバッグ用

	-- 1) 標準的な SSH 形式: ssh://user@host/path
	do
		local user_host, rpath = uri:match("^ssh://([^/]+)(/.+)$")
		if user_host and rpath then
			local host = user_host:match("@([^:]+)") or user_host
			host = HOST_ALIAS[host] or host
			rpath = url_decode(rpath)
			if is_windows() then
				wezterm.run_child_process({ "cmd.exe", "/c", "code", "--remote", "ssh-remote+" .. host, rpath })
			else
				wezterm.run_child_process({ "code", "--remote", "ssh-remote+" .. host, rpath })
			end
			return
		end
	end

	-- 2) wezterm ssh の形式: file://<host>/<path> を SSH として扱う
	do
		local host, rpath = uri:match("^file://([^/]+)(/.+)$")
		-- Windows ローカルは file:///C:/... なので host は空。SSH のときは host が入る
		if host and rpath and #host > 0 then
			host = HOST_ALIAS[host] or host
			rpath = url_decode(rpath)
			if is_windows() then
				wezterm.run_child_process({ "cmd.exe", "/c", "code", "--remote", "ssh-remote+" .. host, rpath })
			else
				wezterm.run_child_process({ "code", "--remote", "ssh-remote+" .. host, rpath })
			end
			return
		end
	end

	-- 3) ローカル（Windows）: file:///C:/...
	if is_windows() then
		local drive_path = uri:match("^file:///(%a:%/.+)$")
		if drive_path then
			local lpath = url_decode(drive_path):gsub("/", "\\")
			wezterm.run_child_process({ "cmd.exe", "/c", "code", lpath })
			return
		end
	end

	-- 4) ローカル（POSIX）: file:///home/... or file:///<abs>
	do
		local posix_path = uri:match("^file://(.+)$")
		if posix_path then
			local lpath = url_decode(posix_path)
			if is_windows() then
				lpath = lpath:gsub("^/", ""):gsub("/", "\\")
				wezterm.run_child_process({ "cmd.exe", "/c", "code", lpath })
			else
				wezterm.run_child_process({ "code", lpath })
			end
			return
		end
	end

	wezterm.log_error("未知のURI形式: " .. uri)
end

local is_mac = (wezterm.target_triple or ""):match("darwin") or (wezterm.target_triple or ""):match("apple")
wezterm.log_info("is_mac: " .. tostring(is_mac))
local config = {

	-- KeyBindings
	--

	MOD = is_mac and "CMD" or "CTRL",
	MOD_S = is_mac and "CMD|SHIFT" or "CTRL|SHIFT",

	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 },

	-- Split pane
	keys = {
		{ key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal },
		{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical },
		-- Enable copy mod
		{
			key = "w",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentPane({ confirm = true }),
		},
		{ key = "v", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
		-- Move pane
		{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
		{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
		{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
		{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
		{ key = "1", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(0) },
		{ key = "2", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(1) },
		{ key = "3", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(2) },
		{ key = "4", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(3) },
		{ key = "5", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(4) },
		{ key = "6", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(5) },
		{ key = "7", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(6) },
		{ key = "8", mods = "LEADER", action = wezterm.action.ActivatePaneByIndex(7) },
		-- Others
		{ key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },

		-- MultiPane
		{
			key = "q",
			mods = "LEADER",
			action = wezterm.action.Multiple({
				wezterm.action.SplitPane({ direction = "Up", size = { Percent = 50 } }),
				wezterm.action.SplitPane({ direction = "Down", size = { Percent = 50 } }),
			}),
		},
		{
			key = "O",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(open_in_vscode),
		},
		{ key = "L", mods = "CTRL|SHIFT", action = wezterm.action.ShowDebugOverlay },
	},
}

config.automatically_reload_config = true

local hosts = require("ssh_hosts")
config.ssh_domains = hosts
-- 新規タブでPowerShell 7を開く
wezterm.on("SpawnNewTabOnPwsh", function(window, pane)
	window:perform_action(
		wezterm.action({ SpawnCommandInNewTab = {
			args = { "pwsh.exe" },
		} }),
		pane
	)
end)

local is_windows = wezterm.target_triple:find("windows")
if is_windows then
	config.default_prog = { "pwsh.exe" }
else
	config.default_prog = { "/bin/bash", "-l" }
end

config.font_size = 12.0
config.use_ime = true
config.window_background_opacity = 0.85
config.font = wezterm.font("JetBrains Mono")
config.macos_window_background_blur = 20
config.scrollback_lines = 10000
enable_scrollbar = true

config.enable_kitty_graphics = true

config.hide_tab_bar_if_only_one_tab = true
config.window_frame = {
	inactive_titlebar_bg = "none",
	active_titlebar_bg = "none",
}
config.window_background_gradient = {
	colors = { "#000000" },
}
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local background = "#5c6d74"
	local foreground = "#FFFFFF"
	local edge_background = "none"
	if tab.is_active then
		background = "#ae8b2d"
		foreground = "#FFFFFF"
	end
	local edge_foreground = background
	local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "
	return {
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_LEFT_ARROW },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Background = { Color = edge_background } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = SOLID_RIGHT_ARROW },
	}
end)

-- and finally, return the configuration to wezterm
return config
