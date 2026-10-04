  -- ════════════════════════════════════════════════
  --   ██████╗██╗  ██╗██╗███████╗███████╗           
  --  ██╔════╝██║  ██║██║██╔════╝██╔════╝           
  --  ██║     ███████║██║█████╗  █████╗             
  --  ██║     ██╔══██║██║██╔══╝  ██╔══╝             
  --  ╚██████╗██║  ██║██║███████╗██║                
  --   ╚═════╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝                
  -- ════════════════════════════════════════════════
  --   ⚡ Hyprland Dots · Lua V1.3 ⚡               
  --   github.com/Chief-Github/Hypr_dots            
  -- ════════════════════════════════════════════════


-- https://wiki.hypr.land/Configuring/Start/

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")
-- unless you're like me and like everything in one place : ) - chief


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--hl.monitor({
--    output   = "eDP-1",
--    mode     = "preferred",
--    position = "0x0",
--    scale    = 1.25,
--})
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1.25,
    mirror   = "HDMI-A-1",
})
-- fractional scailing can mess up apps.. but its nice.
-- Also for some reason atm you "need" to put the monitor output name in for fractional
-- scaling to work.... idk why


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you want to use for defaults -- 
local terminal = "kitty"
local fileManager = "thunar" -- default = dolphin (thunar supports GTK)
local menu = "wofi --show drun" -- old menu (if needed)
local menu2 = "rofi -show drun" -- new menu 


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
  -------------
  -- DAEMONS --
  -------------
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("swayosd-server")
  hl.exec_cmd("eww daemon")
  hl.exec_cmd("hypridle")
--  hl.exec_cmd("swaync") Moving to quickshell.
  hl.exec_cmd("conky --daemonize")

  ------------
  --- APPS ---
  ------------
--  hl.exec_cmd("firefox -P AI-chatgpt --new-window https://chatgpt.com --name chatgpt") -- claude better...
-- moving to qshell  hl.exec_cmd("waybar")
  hl.exec_cmd("quickshell")
  hl.exec_cmd("[noinitialfocus] spotify-launcher")
  hl.exec_cmd("kitty --class neofetch-startup --title neofetch-startup --hold sh -lc 'neofetch'")
  hl.exec_cmd("kitty +kitten panel --edge=background --instance-group=cava-startup --config=/home/chief/.config/kitty/cava_kitty.conf --margin-top=238 --margin-right=1200 --margin-left=2 --margin-bottom=3 --name=cava-startup cava -p ~/.config/cava/config.conf &")
--  hl.exec_cmd("~/.config/hypr/autostart.sh")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("[workspace 2] firefox -P 'default-release'") 
--  hl.exec_cmd("[workspace 2] firefox -P 'fukads' --no-remote")
  hl.exec_cmd("eww open clock-window")
  hl.exec_cmd("hyprpm reload")
  hl.exec_cmd("[workspace special:magic silent] blueman-manager")
  hl.exec_cmd("[workspace special:magic silent] kitty --title water --hold sh -c 'while true; do notify-send \"Drink Water\" \"Time to hydrate!\"; sleep 420; done'")  
  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("[workspace special:claude; float; move 720 39; size 800 650] obsidian")
--  hl.exec_cmd("[workspace special:claude; float; move 1120 328; size 400 616] gnome-calculator")
  hl.exec_cmd("[workspace special:claude; float; move 16 72; size 687 835] kitty --class claude-startup --title claude-startup --hold sh -lc 'cd ~/scratch && claude'")



  -------------
  -- APPLETS --
  -------------
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("udiskie -A -t")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME","Nordic-darker-v40")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR","1")
hl.env("QT_ENABLE_HIGHDPI_SCALING","1")
hl.env("QT_SCALE_FACTOR_ROUNDING_POLICY","RoundPreferFloor")
hl.env("ELECTRON_OZONE_PLATFORM_HINT","auto")


------------------
---HYPR PLUGINS---
------------------
if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.preset("glass", { chromatic_aberration = 0.2 })
    hg.preset("bar_glass_2", { inherits = "glass",refraction_strength  = 2.0 })
    hg.preset("bar_glass", {
        blur_strength        = 1.0,
        refraction_strength  = 2.6,
        chromatic_aberration = 0.2,
        fresnel_strength      = 0.3,
        specular_strength     = 0.4})

hg.config({
        default_theme  = "dark",
        default_preset = "glass",
        blur_strength  = 10,
        dark = {
            brightness   = 0.85,
            contrast     = 1.05,
            saturation   = 0.60,
            vibrancy     = 0.25,
            adaptive_dim = 0.40,
        },
        layers = { enabled = 1 },
    })

    
    hg.layer("rofi")
    hg.layer("logout_dialog")
    hg.layer("swaync-control-center")
    hg.layer("swaync-notification-window")
    hg.layer("swayosd", { preset = "bar_glass_2" })
    hg.layer("waybar",  { preset = "clear" })
    hg.layer("quickshell", { preset = "bar_glass_2" })
--    hg.layer("conky",  { preset = "clear" })
    hg.layer("eww",  { preset = "bar_glass_2" })

end
-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

local matugen_colors = {}
do
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/matugen_colors.txt")
    if f then
        for a, rgb in f:read("*a"):gmatch("0x(%x%x)(%x%x%x%x%x%x)") do
            matugen_colors[#matugen_colors + 1] = "rgba(" .. rgb .. a .. ")"
        end
        f:close()
    end
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            --active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            active_border = #matugen_colors > 0
                and { colors = matugen_colors, angle = 360 }
                or "rgb(138,43,226)",
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity = 1.0,
        inactive_opacity = 1, --0.8
        dim_special = 0.6,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 3,
            vibrancy  = 0.1696,
            xray = false, -- see wallpaper behind blurred popout window (even on top of another window)
            noise = 0,
            special = true,
            new_optimizations = true,
            popups = false, -- blurred border on popups
        },
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("expressiveFastSpatial", { type = "bezier", points = { {0.42, 1.67}, {0.21, 0.90}}})
hl.curve("expressiveSlowSpatial", { type = "bezier", points = { {0.39, 1.29}, {0.35, 0.98}}})
hl.curve("expressiveDefaultSpatial", { type = "bezier", points = { {0.38, 1.21}, {0.22, 1.00}}})
hl.curve("emphasizedDecel", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.2}}})
hl.curve("emphasizedAccel", { type = "bezier", points = { {0.3, 0}, {0.8, 0.15}}})
hl.curve("standardDecel", { type = "bezier", points = { {0, 0}, {0, 1}}})
hl.curve("menu_decel", { type = "bezier", points = { {0.1, 1}, {0, 1.02}}})
hl.curve("menu_accel", { type = "bezier", points = { {0.52, 0.03}, {0.72, 0.08}}})

hl.curve("bounce", { type = "bezier", points = { {0.4, 0.9}, {0.6, 1.0}}})
hl.curve("snappyReturn", { type = "bezier", points = { {0.4, 0.9}, {0.6, 1.0}}})
hl.curve("slideInFromRight", { type = "bezier", points = { {0.5, 0.0}, {0.5, 1.0}}})

hl.curve("winIn", { type = "bezier", points = { {0.07, 0.88}, {0.04, 0.99}}})
hl.curve("winOut", { type = "bezier", points = { {0.20, -0.15}, {0, 1}}})
hl.curve("easeOutCirc", { type = "bezier", points = { {0, 0.48}, {0.38, 1}}})

-- for border anim
hl.curve("liner", { type = "bezier", points = { {1, 1}, {1, 1} } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })


-- STILL MOSTLY DEFAULT --
hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 1, bezier = "linear" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4,  bezier = "snappyReturn", style = "slidevert right" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 4, bezier = "easeOutCirc"})
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "bounce", style = "slidevert right" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 6,  bezier = "bounce",       style = "slidevert right" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
--hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
--hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
--hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 7,    bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 7,    bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 7,    bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })
hl.animation({ leaf = "specialWorkspaceIn",    enabled = true,  speed = 2.8,    bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut",    enabled = true,  speed = 1,    bezier = "emphasizedAccel", style = "slidevert" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 30, bezier = "liner", style = "loop" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "gb",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
            disable_while_typing = false,
        },
    },
})


hl.config({ xwayland  = { enabled = true, force_zero_scaling = true } })
hl.config({ ecosystem = { no_update_news = false, no_donation_nag = false } })
hl.config({ debug     = { overlay = false, vfr = true } })

hl.gesture({
    fingers = 3,
    direction = "pinch",
    action = "float"
})

hl.gesture({
    fingers = 3,
    direction = "swipe",
    action = "move"
})

hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- DEFAULTS & execs --
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu2))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd("rofi -modi emoji -show emoji -kb-secondary-copy \"\" -kb-custom-1 Ctrl+c"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("pkill rofi"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("cool-retro-term"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("kitty --title yazi -e yazi"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call sidebar toggle"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("nwg-look"))
hl.bind(mainMod .. "+ SHIFT + P", hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/hyprquickpaper"))

hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("rofi -show theme"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("wlogout"))


-- SCRIPTS --
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("~/scripts/flashing_keyboard.sh"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd("~/scripts/flashing_keyboard_FAST.sh"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("~/.config/hypr/edit_screenshot.sh"))
hl.bind(mainMod .. " + minus",     hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh decrease 0.5"), { repeating = true })
hl.bind(mainMod .. " + equal",     hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh increase 0.5"), { repeating = true })
hl.bind(mainMod .. " + Backspace", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh reset"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd ("~/.config/hypr/scripts/Panic_lol.sh"))


hl.bind(mainMod .. " + SHIFT + minus",     hl.dsp.exec_cmd("~/.config/hypr/scripts/blur_change.sh decrease 1"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + equal",     hl.dsp.exec_cmd("~/.config/hypr/scripts/blur_change.sh increase 1"), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Backspace", hl.dsp.exec_cmd("~/.config/hypr/scripts/blur_change.sh reset"))


hl.bind(mainMod .. " + SHIFT + " .. "S", hl.dsp.exec_cmd("hyprshot -m region --freeze -o ~/screenshots"))


-- EXIT WINDOW -- 
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))



-- WINDOW CHANGES --
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + K", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
-- possible breakages --
--hl.bind(mainMod .. " + G",            hl.dsp.window.togglegroup())
--hl.bind(mainMod .. " + bracketleft",  hl.dsp.group.change_active({ direction = "back" }))
--hl.bind(mainMod .. " + bracketright", hl.dsp.group.change_active({ direction = "forward" }))


-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Fully move windows with arrow keys --
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))


-- Shift windows with alt and shift" --
--hl.bind("ALT + SHIFT + left",  hl.dsp.window.resizeactive(-30, 0))
--hl.bind("ALT + SHIFT + right", hl.dsp.window.resizeactive(30,  0))
--hl.bind("ALT + SHIFT + up",    hl.dsp.window.resizeactive(0,  -30))
--hl.bind("ALT + SHIFT + down",  hl.dsp.window.resizeactive(0,   30))
hl.bind("ALT + SHIFT + left",  hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind("ALT + SHIFT + right", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind("ALT + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind("ALT + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })
--PROPPER--

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- EXTRA WORK SPACES - ALT + [0-9] --
for i = 11, 20 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + ALT + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + ALT + " .. key,     hl.dsp.window.move({ workspace = i }))
end


-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + D",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness raise"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness lower --min-brightness 1"),                  { locked = true, repeating = true })
hl.bind(mainMod .. " + ALT + up", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
hl.bind(mainMod .. " + ALT + down", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprlock --config ~/.config/hypr/hyprlock-current.conf"), { locked = true })

-- Requires playerctl
hl.bind(mainMod .. " + ALT + right", hl.dsp.exec_cmd("playerctl next"))
hl.bind(mainMod .. " + ALT + left", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(mainMod .. " + ALT + space", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("~/.config/hypr/scripts/spotify_like.sh"))
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/spotify_add_to_playlist.sh"))

-----------------
-- LAYER RULES --
-----------------
hl.layer_rule({ name = "blur-rofi",match = { namespace = "^(rofi)$" },                             blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-conky",match = { namespace = "^(conky)$" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-swayosd",match = { namespace = "^(swayosd)$" },                       blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-gtk",match = { namespace = "^(gtk-layer-shell)$" },                   blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-waybar",match = { namespace = "^(waybar)$" },                         blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-logout",match = { namespace = "^(logout_dialog)$" },                  blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-hyprlock",match = { namespace = "^(hyprlock)$" },                     blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-swaync-cc", match = { namespace = "^(swaync-control-center)$" },      blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "blur-swaync-nw", match = { namespace = "^(swaync-notification-window)$" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "no-anim-hyprpicker",match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ name = "no-anim-selection",match = { namespace = "selection" },  no_anim = true })
hl.layer_rule({ name = "quickshell-waybar",match = { namespace = "^(quickshell)$" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "Boot_anim",match = { namespace = "^(boot)$" }, no_anim = true, ignore_alpha = 0, blur = true })
hl.layer_rule({ name = "quickshell-popup",match = { namespace = "^(popup)$" }, blur = true, ignore_alpha = 0 })


------------------
-- WINDOW RULES --
------------------
hl.window_rule({ name = "wr-thunar",match = { class = "^(thunar)$" },float = true, size = "800 600", center = true })
hl.window_rule({ name = "wr-conky",match = { class = "^(Conky)$" },rounding = 12 })
hl.window_rule({ name = "wr-yazi",match = { title = "^(yazi)$" },float = true, size = "800 600", center = true })
hl.window_rule({ name = "wr-dolphin",match = { class = "^(org.kde.dolphin)$" }, float = true, size = "870 614"})
hl.window_rule({ name = "wr-ark",match = { class = "^(org.kde.ark)$" }, float = true, size = "870 614"})
hl.window_rule({ name = "wr-QDiskInfo",match = { class = "^(QDiskInfo)$" }, float = true, size = "868 724"})
hl.window_rule({ name = "wr-obsidian",match = { class = "^(obsidian)$" }, float = true, size = "800 650", center = true})
hl.window_rule({ name = "wr-pulse",match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = "800 600", center = true})
-- hl.window_rule({ name = "wr-spotify",match = { title = "^(org.aaudio.pavucontrol)$", float = true, size = "859 734"}, center = true, move "661 116", workspace = "special:magic silent"})
hl.window_rule({ name = "wr-waypaper",match = { class = "^(waypaper)$" },float = true, size = "500 500", center = true })
hl.window_rule({ name = "wr-obs",match = { class = "^(com.obsproject.Studio)$" },float = true, size = "985 714", center = true })
hl.window_rule({ name = "wr-nwg-look",match = { class = "^(nwg-look)$" },float = true, size = "667 494", center = true })
hl.window_rule({ name = "wr-timeshift",match = { class = "^(timeshift-gtk)$" },float = true, size = "667 494", center = true })
hl.window_rule({ name = "wr-nm-editor",match = { class = "^(nm-connection-editor)$" },float = true, size = "500 500", center = true })
hl.window_rule({ name = "wr-gnome-clocks",match = { class = "^(org.gnome.clocks)$" },float = true })
hl.window_rule({ name = "wr-gnome-weather",match = { class = "^(org.gnome.Weather)$" },float = true, size = "500 500", center = true })
hl.window_rule({ name = "wr-mpv",match = { class = "^(mpv)$" },float = true })
hl.window_rule({ name = "wr-steam-browser",match = { title = "Steam - Browser" },float = true })
hl.window_rule({ name = "wr-waydroid",match = { class = "^(Waydroid)$" },fullscreen = true })
hl.window_rule({ name = "wr-calc",match = { class = "^(org.gnome.Calculator)$" },float = true })
hl.window_rule({ name = "wr-xgps",match = { class = "^(xgps)$" },float = true, size = "500 500", center = true })


-- Spotify
hl.window_rule({ name = "wr-spotify-lower",  match = { class = "^(spotify)$" }, float = true, size = "859 734", move = "661 116", workspace = "special:magic" })
hl.window_rule({ name = "wr-spotify-upper",  match = { class = "^(Spotify)$" }, float = true, size = "859 734", move = "661 116", workspace = "special:magic" })

-- Special workspace positioned windows
hl.window_rule({ name = "wr-water",match = { title = "^(water)$" },float = true, size = "615 422", move = "27 127",  workspace = "special:magic" })
hl.window_rule({ name = "wr-blueman",match = { class = "^(blueman-manager)$" },float = true, size = "667 494", center = true })
hl.window_rule({ name = "wr-blueman-magicmatch", match = { class = "^(blueman-manager)$" },float = true, size = "615 342", move = "23 568",  workspace = "special:magic" })
-- special claude window - replacing chatgpt
-- hl.window_rule({ name = "wr-claude-startup", match = { title = "^(claude-startup)"}, float = true, size = "666 346", move = "489 64", workspace = "special:claude"})
hl.bind(mainMod .. " + A", hl.dsp.workspace.toggle_special("claude"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.window.move({ workspace = "special:claude" }))

--------------------------------
---- Universal Window rules ----
--------------------------------
-- I found this out while looking through various dot files
-- These window rules basically make it so any app trying to
-- open files, folders etc will open in a popout window.
-- 
hl.window_rule({ name = "wr-universal_1", match = { title = "^(Open File)(.*)$" }, float = true, center = true})
hl.window_rule({ name = "wr-universal_2", match = { title = "^(Select a File)(.*)$" }, float = true, center = true})
hl.window_rule({ name = "wr-universal_3", match = { title = "^(Open Directory)(.*)$" }, float = true, center = true})
hl.window_rule({ name = "wr-universal_4", match = { title = "^(Open Folder)(.*)$" }, float = true, center = true})
hl.window_rule({ name = "wr-universal_5", match = { title = "^(.*)(wants to save)$" }, float = true, center = true})
hl.window_rule({ name = "wr-universal_6", match = { title = "^(Save As)(.*)$" }, float = true, center = true})
hl.window_rule({ name = "wr-universal_7", match = { title = "^(.*)(wants to open)$" }, float = true, center = true})

--------------------
--- STARTUP APPS ---
--------------------
-- moveing this to fast fetch at some point --
hl.window_rule({ name = "wr-startup-neofetch", match = { title = "^(neofetch-startup)"}, float = true, size = "666 346", move = "489 64", workspace = "1"})

---------------------------------------------
-- CHATGPT --
-- imma leave this here as an archive tbh, claude is just better for my usecase --

--windowrule = match:class ^(chatgpt)$, float on, size 467 903, move 12 43, workspace special:chatgpt silent
--bind = $mainMod, a, togglespecialworkspace, chatgpt
--bind = $mainMod SHIFT, A, movetoworkspace, special:chatgpt
-----------------------------------------------

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)


-- DIM colour over the day :)
local hour = tonumber(os.date("%H"))
local color = hour < 6 and "rgb(20,20,60)" or
              hour < 12 and "rgb(138,43,226)" or
              hour < 15 and "rgb(104, 30, 173)" or
              hour < 18 and "rgb(60,0,120)"
--hl.config({ general = { col = { active_border = color }}})


--local bat = io.popen("cat /sys/class/power_supply/BAT0/capacity"):read()
--  if tonumber(bat) < 10 then
--    
--  end

  
hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

dofile(os.getenv("HOME") .. "/.config/hypr/scripts/event-ws-gaps.lua")


-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
