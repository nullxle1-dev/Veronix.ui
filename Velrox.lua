local Players, TS, UIS, RS = game:GetService("Players"), game:GetService("TweenService"), game:GetService("UserInputService"), game:GetService("RunService")
local V = { Flags = {}, Icons = {} }
local DefaultC = {
    BG = Color3.fromRGB(10, 10, 12), Surf = Color3.fromRGB(16, 16, 19), El = Color3.fromRGB(22, 22, 27),
    Hi = Color3.fromRGB(30, 30, 36), Line = Color3.fromRGB(40, 40, 47), Red = Color3.fromRGB(228, 30, 48),
    Dark = Color3.fromRGB(120, 12, 24), Text = Color3.fromRGB(240, 240, 242), Sub = Color3.fromRGB(150, 150, 160),
}
local C = {}
for k, v in pairs(DefaultC) do C[k] = v end
local WHITE, Q, B, S = Color3.new(1, 1, 1), Enum.EasingStyle.Quint, Enum.EasingStyle.Back, Enum.EasingStyle.Sine
local spin, provider = {}, nil
RS.Heartbeat:Connect(function(dt) for g, sp in pairs(spin) do if g.Parent then g.Rotation = (g.Rotation + dt * sp) % 360 else spin[g] = nil end end end)

function V:SetTheme(theme)
    if type(theme) ~= "table" then return end
    for k, v in pairs(theme) do if DefaultC[k] then C[k] = v end end
end

function V:ResetTheme()
    for k, v in pairs(DefaultC) do C[k] = v end
end

local function tw(o, t, p, s, d)
    local x = TS:Create(o, TweenInfo.new(t, s or Q, d or Enum.EasingDirection.Out), p)
    x:Play()
    return x
end

local function new(class, props, kids)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.BackgroundTransparency, o.Font, o.TextSize, o.TextColor3 = 1, Enum.Font.Gotham, 13, C.Text
    elseif o:IsA("ImageLabel") then o.BackgroundTransparency = 1 end
    local parent
    for k, v in pairs(props or {}) do if k == "Parent" then parent = v else o[k] = v end end
    for _, k in ipairs(kids or {}) do k.Parent = o end
    o.Parent = parent
    return o
end

local function deco(o, r, sc, st)
    new("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 6), Parent = o })
    if sc then return new("UIStroke", { Color = sc, Thickness = st or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o }) end
end

local function icon(img, n)
    local d = n
    if type(n) == "number" then
        d = "rbxassetid://" .. n
    elseif type(n) == "string" then
        if n:find("rbxasset") or n:find("http") then
            d = n
        else
            d = V.Icons[n]
            if not d and provider then local ok, r = pcall(provider, n) d = ok and r or nil end
        end
    end
    local id, m
    if type(d) == "string" then id = d elseif type(d) == "table" then id = d.Image or d[1]; m = d.ImageRectSize and d or d[2] end
    if not id then img.Visible = false return false end
    img.Image, img.Visible = id, true
    if type(m) == "table" then
        img.ImageRectSize = m.ImageRectSize or Vector2.zero
        img.ImageRectOffset = m.ImageRectOffset or m.ImageRectPosition or Vector2.zero
    end
    return true
end

local function press(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function move(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function mouse() return UIS:GetMouseLocation() end

local function ripple(b)
    local m, p, s = mouse(), b.AbsolutePosition, b.AbsoluteSize
    local c = new("Frame", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(math.clamp(m.X - p.X, 0, s.X), math.clamp(m.Y - p.Y, 0, s.Y)),
        Size = UDim2.new(), BackgroundColor3 = C.Red, BackgroundTransparency = .6, Parent = b,
    })
    deco(c, UDim.new(1, 0))
    local z = math.max(s.X, s.Y) * 2.2
    tw(c, .6, { Size = UDim2.fromOffset(z, z), BackgroundTransparency = 1 })
    task.delay(.65, function() c:Destroy() end)
end

local function drag(h, t, click)
    local st, sp, mv
    h.InputBegan:Connect(function(i) if press(i) then st, sp, mv = mouse(), t.Position, false end end)
    UIS.InputChanged:Connect(function(i)
        if st and move(i) then
            local d = mouse() - st
            if d.Magnitude > 5 then mv = true end
            if mv then tw(t, .08, { Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) }, S) end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if st and press(i) then st = nil if not mv and click then click() end end
    end)
end

local function hold(area, fn, on, off)
    local act = false
    area.InputBegan:Connect(function(i) if press(i) then act = true if on then on() end fn(mouse()) end end)
    UIS.InputChanged:Connect(function(i) if act and move(i) then fn(mouse()) end end)
    UIS.InputEnded:Connect(function(i) if act and press(i) then act = false if off then off() end end end)
end

function V:SetIconProvider(fn) provider = fn end

function V:Notify(o)
    if not V.holder then return end
    local dur = o.Duration or 4
    local w = new("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Parent = V.holder })
    local c = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), Position = UDim2.new(1, 60, 0, 0), BackgroundColor3 = C.Surf, GroupTransparency = 1, Parent = w })
    deco(c, 8, C.Line)
    new("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = C.Red, Parent = c })
    new("TextLabel", { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -24, 0, 18), Text = o.Title or "Velrox", Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = c })
    new("TextLabel", {
        Position = UDim2.fromOffset(14, 27), Size = UDim2.new(1, -24, 0, 28), Text = o.Content or "", TextSize = 12, TextColor3 = C.Sub,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = c,
    })
    local bar = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = C.Red, Parent = c })
    tw(c, .5, { Position = UDim2.new(), GroupTransparency = 0 }, B)
    tw(bar, dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(dur, function()
        tw(c, .4, { Position = UDim2.new(1, 60, 0, 0), GroupTransparency = 1 }, Q, Enum.EasingDirection.In)
        task.wait(.4)
        tw(w, .25, { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(.3)
        w:Destroy()
    end)
end

function V:CreateWindow(cfg)
    cfg = cfg or {}
    if cfg.Theme then V:SetTheme(cfg.Theme) end
    if V.gui then V.gui:Destroy() end
    local W, open, cur, count = {}, false, nil, 0
    local gui = new("ScreenGui", { Name = "Velrox", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
    if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) or not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    V.gui = gui
    V.holder = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 280, 1, -32), BackgroundTransparency = 1, Parent = gui })
    new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = V.holder })
    function W:Notify(o) V:Notify(o) end
    function W:SetTheme(theme) V:SetTheme(theme) end
    function W:ResetTheme() V:ResetTheme() end

    -- loading screen
    local ld
    if cfg.LoadingScreen ~= false then
        local f = new("CanvasGroup", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(290, 170), BackgroundColor3 = C.BG, GroupTransparency = 1, Parent = gui })
        deco(f, 12, C.Red, 1.5)
        local sc = new("UIScale", { Scale = .8, Parent = f })
        local ring = new("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 18), Size = UDim2.fromOffset(54, 54), BackgroundTransparency = 1, Parent = f })
        local rs = deco(ring, UDim.new(1, 0), WHITE, 3)
        spin[new("UIGradient", {
            Color = ColorSequence.new(C.Red),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.5, 1), NumberSequenceKeypoint.new(1, 1) }),
            Parent = rs,
        })] = 360
        local lt = new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "V", Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = C.Red, TextTransparency = 1, Parent = ring })
        local lg = new("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(24, 24), ImageColor3 = C.Red, Visible = false, Parent = ring })
        new("TextLabel", { Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 22), Text = cfg.LoadingTitle or "V E L R O X", Font = Enum.Font.GothamBlack, TextSize = 18, Parent = f })
        local st = new("TextLabel", { Position = UDim2.fromOffset(0, 108), Size = UDim2.new(1, 0, 0, 16), Text = "Starting", TextSize = 12, TextColor3 = C.Sub, Parent = f })
        local track = new("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 140), Size = UDim2.fromOffset(220, 5), BackgroundColor3 = C.El, Parent = f })
        deco(track, UDim.new(1, 0))
        local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, Parent = track })
        deco(fill, UDim.new(1, 0))
        new("UIGradient", { Color = ColorSequence.new(C.Dark, C.Red), Parent = fill })
        tw(f, .5, { GroupTransparency = 0 })
        tw(sc, .6, { Scale = 1 }, B)
        ld = {}
        function ld.step(text, p)
            st.Text, st.TextTransparency = text, 1
            tw(st, .3, { TextTransparency = 0 })
            tw(fill, .5, { Size = UDim2.fromScale(p, 1) }, Enum.EasingStyle.Quart)
            task.wait(.5)
        end
        function ld.logo()
            if icon(lg, cfg.Icon or "flame") then lg.Visible = true else tw(lt, .4, { TextTransparency = 0 }) end
        end
        function ld.close()
            task.wait(.2)
            tw(sc, .5, { Scale = 1.15 }, Q, Enum.EasingDirection.In)
            tw(f, .45, { GroupTransparency = 1 }, Q, Enum.EasingDirection.In)
            task.wait(.5)
            f:Destroy()
        end
        ld.step("Loading icons", .25)
    end
    if not provider then
        pcall(function()
            local L = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/main/Main.lua"))()
            pcall(L.SetIconsType, "lucide")
            provider = function(n) return L.Icon(n) end
        end)
    end
    if ld then ld.logo() ld.step("Building interface", .65) end

    -- window
    local SB, TB = 140, 40
    local main = new("CanvasGroup", {
        AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = cfg.Size or UDim2.fromOffset(540, 340),
        BackgroundColor3 = C.BG, GroupTransparency = 1, Visible = false, Parent = gui,
    })
    local ms = new("UIScale", { Scale = .88, Parent = main })
    local mstroke = deco(main, 10, WHITE, 1.5)
    spin[new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Red), ColorSequenceKeypoint.new(.5, C.Dark), ColorSequenceKeypoint.new(1, C.Red) }), Parent = mstroke })] = 45

    local top = new("Frame", { Size = UDim2.new(1, 0, 0, TB), BackgroundColor3 = C.Surf, Parent = main })
    new("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Line, Parent = top })
    local ti = new("ImageLabel", { Position = UDim2.fromOffset(14, 11), Size = UDim2.fromOffset(18, 18), ImageColor3 = C.Red, Parent = top })
    local tx = icon(ti, cfg.Icon or "flame") and 40 or 16
    local title = new("TextLabel", {
        Position = UDim2.fromOffset(tx, 0), Size = UDim2.new(0, 80, 1, 0), Text = string.upper(cfg.Name or "Velrox"),
        Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Parent = top,
    })
    local tg = new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Red), ColorSequenceKeypoint.new(.5, WHITE), ColorSequenceKeypoint.new(1, C.Red) }), Offset = Vector2.new(-1, 0), Parent = title })
    TS:Create(tg, TweenInfo.new(2.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Offset = Vector2.new(1, 0) }):Play()
    new("TextLabel", { Position = UDim2.fromOffset(tx + 80, 0), Size = UDim2.new(0, 80, 1, 0), Text = cfg.Subtitle or "v1.0", TextSize = 11, TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Left, Parent = top })

    local hb = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(26, 26), Text = "×", TextSize = 20, TextColor3 = C.Sub, AutoButtonColor = false, BackgroundTransparency = 0, BackgroundColor3 = C.El, Parent = top })
    deco(hb, 6)
    hb.MouseEnter:Connect(function() tw(hb, .2, { BackgroundColor3 = C.Red, TextColor3 = WHITE }) end)
    hb.MouseLeave:Connect(function() tw(hb, .25, { BackgroundColor3 = C.El, TextColor3 = C.Sub }) end)

    local side = new("Frame", { Position = UDim2.fromOffset(0, TB), Size = UDim2.new(0, SB, 1, -TB), BackgroundColor3 = C.Surf, Parent = main })
    new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.Line, Parent = side })
    local list = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -44), BackgroundTransparency = 1, Parent = side })
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    local ind = new("Frame", { Size = UDim2.fromOffset(3, 18), BackgroundColor3 = C.Red, Visible = false, ZIndex = 3, Parent = side })
    deco(ind, UDim.new(1, 0))
    new("TextLabel", { Position = UDim2.new(0, 14, 1, -30), Size = UDim2.new(1, -20, 0, 24), Text = Players.LocalPlayer.DisplayName, TextSize = 11, TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = side })
    local content = new("Frame", { Position = UDim2.fromOffset(SB, TB), Size = UDim2.new(1, -SB, 1, -TB), BackgroundTransparency = 1, ClipsDescendants = true, Parent = main })
    drag(top, main)

    -- floating toggle
    local fl = new("TextButton", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 46, .5, 0), Size = UDim2.fromOffset(46, 46), Text = "", AutoButtonColor = false, BackgroundTransparency = 0, BackgroundColor3 = C.BG, Parent = gui })
    local fs = new("UIScale", { Scale = 0, Parent = fl })
    local fstroke = deco(fl, UDim.new(1, 0), WHITE, 2)
    spin[new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C.Red), ColorSequenceKeypoint.new(.5, C.Dark), ColorSequenceKeypoint.new(1, C.Red) }), Parent = fstroke })] = 120
    local fi = new("ImageLabel", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(22, 22), ImageColor3 = C.Red, Parent = fl })
    if not icon(fi, cfg.ToggleIcon or cfg.Icon or "flame") then
        new("TextLabel", { Size = UDim2.fromScale(1, 1), Text = "V", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = C.Red, Parent = fl })
    end
    TS:Create(fstroke, TweenInfo.new(1.3, S, Enum.EasingDirection.InOut, -1, true), { Transparency = .65 }):Play()
    tw(fs, .7, { Scale = 1 }, B)
    fl.MouseEnter:Connect(function() tw(fs, .25, { Scale = 1.12 }, B) end)
    fl.MouseLeave:Connect(function() tw(fs, .3, { Scale = 1 }) end)

    function W:Show()
        if open then return end
        open, main.Visible = true, true
        tw(main, .45, { GroupTransparency = 0 })
        tw(ms, .55, { Scale = 1 }, B)
        fi.Rotation = 0
        tw(fi, .5, { Rotation = 360 }, B)
    end
    function W:Hide()
        if not open then return end
        open = false
        tw(main, .3, { GroupTransparency = 1 }, Q, Enum.EasingDirection.In)
        tw(ms, .3, { Scale = .9 }, Q, Enum.EasingDirection.In)
        task.delay(.32, function() if not open then main.Visible = false end end)
    end
    function W:Toggle() if open then W:Hide() else W:Show() end end
    function W:Destroy() gui:Destroy() end
    hb.MouseButton1Click:Connect(function() W:Hide() end)
    drag(fl, fl, function() W:Toggle() end)
    local key = cfg.ToggleKey or Enum.KeyCode.RightShift
    UIS.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == key then W:Toggle() end end)

    -- tabs
    function W:CreateTab(name, ic)
        count = count + 1
        local idx, T = count, {}
        local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BackgroundColor3 = C.Red, LayoutOrder = idx, ClipsDescendants = true, Parent = list })
        deco(btn, 6)
        local im = new("ImageLabel", { Position = UDim2.fromOffset(12, 9), Size = UDim2.fromOffset(16, 16), ImageColor3 = C.Sub, Parent = btn })
        local lb = new("TextLabel", { Position = UDim2.fromOffset(icon(im, ic) and 36 or 14, 0), Size = UDim2.new(1, -40, 1, 0), Text = name, TextColor3 = C.Sub, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })
        local page = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, Parent = content })
        local scroll = new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = C.Red, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, Parent = page })
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
        new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10), Parent = scroll })

        local function select()
            if cur == T then return end
            local o = cur
            cur = T
            if o then
                tw(o.btn, .25, { BackgroundTransparency = 1 }) tw(o.lb, .25, { TextColor3 = C.Sub }) tw(o.im, .25, { ImageColor3 = C.Sub })
                o.page.Visible, o.page.GroupTransparency = false, 1
            end
            ind.Visible = true
            tw(ind, .45, { Position = UDim2.fromOffset(0, 16 + (idx - 1) * 38) }, B)
            tw(btn, .3, { BackgroundTransparency = .88 }) tw(lb, .3, { TextColor3 = C.Text }) tw(im, .3, { ImageColor3 = C.Red })
            page.Position, page.Visible = UDim2.fromOffset(0, 18), true
            tw(page, .45, { GroupTransparency = 0, Position = UDim2.new() })
        end
        T.btn, T.lb, T.im, T.page = btn, lb, im, page
        btn.MouseButton1Click:Connect(function() ripple(btn) select() end)
        btn.MouseEnter:Connect(function() if cur ~= T then tw(lb, .2, { TextColor3 = C.Text }) end end)
        btn.MouseLeave:Connect(function() if cur ~= T then tw(lb, .2, { TextColor3 = C.Sub }) end end)
        if idx == 1 then select() end

        local n = 0
        local function row(h)
            n = n + 1
            local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.El, ClipsDescendants = true, LayoutOrder = n, Parent = scroll })
            deco(f, 6, C.Line)
            f.MouseEnter:Connect(function() tw(f, .2, { BackgroundColor3 = C.Hi }) end)
            f.MouseLeave:Connect(function() tw(f, .25, { BackgroundColor3 = C.El }) end)
            return f
        end
        local function label(p, t, w, h)
            return new("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(w or 1, -24, 0, h or 36), Text = t, TextXAlignment = Enum.TextXAlignment.Left, Parent = p })
        end
        local function flag(o, v) if o.Flag then V.Flags[o.Flag] = v end end
        local function call(o, ...) if o.Callback then task.spawn(o.Callback, ...) end end

        function T:AddSection(t)
            n = n + 1
            new("TextLabel", { Size = UDim2.new(1, 0, 0, 22), Text = string.upper(t), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Red, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = n, Parent = scroll })
        end

        function T:AddLabel(t)
            local l = label(row(30), t, 1, 30)
            l.TextColor3 = C.Sub
            return { Set = function(_, x) l.Text = x end }
        end

        function T:AddButton(o)
            local f = row(36)
            local b = new("TextButton", { Size = UDim2.fromScale(1, 1), Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = f })
            label(b, o.Name or "Button")
            new("TextLabel", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(16, 16), Text = "›", TextSize = 22, TextColor3 = C.Red, Font = Enum.Font.GothamBold, Parent = b })
            b.MouseButton1Click:Connect(function()
                ripple(b)
                tw(f, .1, { Size = UDim2.new(1, -8, 0, 34) }, S)
                task.delay(.1, function() tw(f, .35, { Size = UDim2.new(1, 0, 0, 36) }, B) end)
                call(o)
            end)
        end

        function T:AddToggle(o)
            local f, X = row(36), { Value = o.Default and true or false }
            label(f, o.Name or "Toggle")
            local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), Text = "", Parent = f })
            local tr = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -12, .5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = C.Line, Parent = f })
            deco(tr, UDim.new(1, 0))
            local kn = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 3, .5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.Sub, Parent = tr })
            deco(kn, UDim.new(1, 0))
            local function render(a)
                local on, t = X.Value, a and .35 or 0
                tw(tr, t, { BackgroundColor3 = on and C.Red or C.Line })
                tw(kn, t, { Position = on and UDim2.new(1, -17, .5, 0) or UDim2.new(0, 3, .5, 0), BackgroundColor3 = on and WHITE or C.Sub }, B)
                if a then
                    tw(kn, .12, { Size = UDim2.fromOffset(18, 14) }, S)
                    task.delay(.12, function() tw(kn, .25, { Size = UDim2.fromOffset(14, 14) }, B) end)
                end
            end
            function X:Set(v, silent) X.Value = v and true or false render(true) flag(o, X.Value) if not silent then call(o, X.Value) end end
            function X:Get() return X.Value end
            hit.MouseButton1Click:Connect(function() X:Set(not X.Value) end)
            render(false) flag(o, X.Value)
            if X.Value then call(o, true) end
            return X
        end

        function T:AddSlider(o)
            local mn, mx, inc = o.Min or 0, o.Max or 100, o.Increment or 1
            local f, X = row(48), { Value = mn }
            label(f, o.Name or "Slider", .6, 30)
            local vl = new("TextLabel", { Position = UDim2.new(.6, 0, 0, 0), Size = UDim2.new(.4, -12, 0, 30), TextColor3 = C.Red, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Right, Parent = f })
            local hit = new("TextButton", { Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 16), Text = "", Parent = f })
            local tr = new("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = C.Line, Parent = hit })
            deco(tr, UDim.new(1, 0))
            local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, Parent = tr })
            deco(fill, UDim.new(1, 0))
            new("UIGradient", { Color = ColorSequence.new(C.Dark, C.Red), Parent = fill })
            local kn = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(1, .5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, ZIndex = 2, Parent = fill })
            deco(kn, UDim.new(1, 0))
            local ks, down = new("UIScale", { Scale = 0, Parent = kn }), false
            function X:Set(v, silent)
                v = math.clamp(tonumber(string.format("%.4f", math.floor(v / inc + .5) * inc)), mn, mx)
                X.Value = v
                tw(fill, .15, { Size = UDim2.fromScale((v - mn) / (mx - mn), 1) })
                vl.Text = tostring(v) .. (o.Suffix or "")
                flag(o, v)
                if not silent then call(o, v) end
            end
            function X:Get() return X.Value end
            hold(hit, function(m)
                local v = mn + (mx - mn) * math.clamp((m.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
                if math.abs(v - X.Value) >= inc / 2 then X:Set(v) end
            end, function() down = true tw(ks, .25, { Scale = 1 }, B) end, function() down = false tw(ks, .25, { Scale = 0 }) end)
            hit.MouseEnter:Connect(function() tw(ks, .2, { Scale = 1 }, B) end)
            hit.MouseLeave:Connect(function() if not down then tw(ks, .2, { Scale = 0 }) end end)
            X:Set(o.Default or mn, true)
            return X
        end

        function T:AddInput(o)
            local f = row(36)
            label(f, o.Name or "Input", .5)
            local bf = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.new(.5, -8, 0, 24), BackgroundColor3 = C.BG, Parent = f })
            local st = deco(bf, 5, C.Line)
            local box = new("TextBox", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), PlaceholderText = o.Placeholder or "Type here...", PlaceholderColor3 = C.Sub, Text = o.Default or "", ClearTextOnFocus = false, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, Parent = bf })
            box.Focused:Connect(function() tw(st, .25, { Color = C.Red }) end)
            box.FocusLost:Connect(function(enter) tw(st, .3, { Color = C.Line }) flag(o, box.Text) call(o, box.Text, enter) end)
            flag(o, box.Text)
            return { Set = function(_, t) box.Text = t end, Get = function() return box.Text end }
        end

        function T:AddDropdown(o)
            local opts, multi = o.Options or {}, o.Multi == true
            local f, X, btns = row(36), { Value = multi and {} or nil, Open = false }, {}
            local hit = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), Text = "", Parent = f })
            label(hit, o.Name or "Dropdown", .5)
            local vl = new("TextLabel", { Position = UDim2.new(.5, 0, 0, 0), Size = UDim2.new(.5, -32, 0, 36), Text = "None", TextSize = 12, TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = hit })
            local ar = new("TextLabel", { Position = UDim2.new(1, -26, 0, 0), Size = UDim2.fromOffset(16, 36), Text = "▼", TextSize = 9, TextColor3 = C.Red, Parent = hit })
            local ls = new("ScrollingFrame", { Position = UDim2.fromOffset(8, 40), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = C.Red, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, Parent = f })
            new("UIListLayout", { Padding = UDim.new(0, 2), Parent = ls })
            local function lh() return math.min(#opts, 5) * 28 end
            local function paint()
                local t = {}
                for k, b in pairs(btns) do
                    local sel = multi and X.Value[k] or X.Value == k
                    if sel and multi then table.insert(t, k) end
                    tw(b, .25, { TextColor3 = sel and C.Red or C.Sub, BackgroundTransparency = sel and .85 or 1 })
                end
                vl.Text = multi and (#t > 0 and table.concat(t, ", ") or "None") or tostring(X.Value or "None")
            end
            local function fire() flag(o, X.Value) call(o, X.Value) end
            local function build()
                for _, b in pairs(btns) do b:Destroy() end
                btns = {}
                for i, k in ipairs(opts) do
                    local b = new("TextButton", { Size = UDim2.new(1, -4, 0, 26), Text = tostring(k), TextSize = 12, TextColor3 = C.Sub, AutoButtonColor = false, BackgroundColor3 = C.Red, BackgroundTransparency = 1, LayoutOrder = i, Parent = ls })
                    deco(b, 5)
                    b.MouseButton1Click:Connect(function()
                        if multi then X.Value[k] = not X.Value[k] or nil else X.Value = k end
                        paint() fire()
                    end)
                    btns[k] = b
                end
                paint()
            end
            local function setOpen(v)
                X.Open = v
                tw(f, .4, { Size = UDim2.new(1, 0, 0, v and 44 + lh() or 36) })
                tw(ls, .4, { Size = UDim2.new(1, -16, 0, v and lh() or 0) })
                tw(ar, .4, { Rotation = v and 180 or 0 }, B)
            end
            hit.MouseButton1Click:Connect(function() setOpen(not X.Open) end)
            function X:Set(v, silent)
                if multi then X.Value = {} for _, k in ipairs(v) do X.Value[k] = true end else X.Value = v end
                paint() if not silent then fire() end
            end
            function X:Get() return X.Value end
            function X:Refresh(l) opts, X.Value = l, multi and {} or nil build() if X.Open then setOpen(true) end end
            build()
            if o.Default then X:Set(o.Default, true) end
            flag(o, X.Value)
            return X
        end

        function T:AddKeybind(o)
            local f, k, listening, X = row(36), o.Default, false, {}
            label(f, o.Name or "Keybind", .6)
            local b = new("TextButton", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.fromOffset(70, 24), Text = k and k.Name or "None", TextSize = 12, TextColor3 = C.Red, AutoButtonColor = false, BackgroundTransparency = 0, BackgroundColor3 = C.BG, Parent = f })
            local st = deco(b, 5, C.Line)
            function X:Set(v) k = v b.Text = v and v.Name or "None" flag(o, k) end
            function X:Get() return k end
            b.MouseButton1Click:Connect(function()
                if listening then return end
                listening, b.Text = true, "..."
                tw(st, .2, { Color = C.Red })
                local c
                c = UIS.InputBegan:Connect(function(i)
                    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    c:Disconnect()
                    if i.KeyCode == Enum.KeyCode.Escape then X:Set(k) elseif i.KeyCode == Enum.KeyCode.Backspace then X:Set(nil) else X:Set(i.KeyCode) end
                    tw(st, .3, { Color = C.Line })
                    task.delay(.1, function() listening = false end)
                end)
            end)
            UIS.InputBegan:Connect(function(i, gp) if not gp and not listening and k and i.KeyCode == k then call(o, k) end end)
            flag(o, k)
            return X
        end

        function T:AddColorPicker(o)
            local f, X = row(36), { Value = o.Default or C.Red, Open = false }
            local h, s, v = X.Value:ToHSV()
            local hit = new("TextButton", { Size = UDim2.new(1, 0, 0, 36), Text = "", Parent = f })
            label(hit, o.Name or "Color", .7)
            local sw = new("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(34, 18), BackgroundColor3 = X.Value, Parent = hit })
            deco(sw, 5, C.Line)
            local sv = new("Frame", { Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -52, 0, 90), ClipsDescendants = true, Parent = f })
            deco(sv, 5)
            new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Parent = sv }) })
            new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), Parent = sv }) })
            local sc = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 3, Parent = sv })
            deco(sc, UDim.new(1, 0), WHITE, 2)
            local hu = new("Frame", { Position = UDim2.new(1, -28, 0, 44), Size = UDim2.fromOffset(16, 90), BackgroundColor3 = WHITE, ClipsDescendants = true, Parent = f })
            deco(hu, 5)
            local ks = {}
            for i = 0, 6 do table.insert(ks, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))) end
            new("UIGradient", { Rotation = 90, Color = ColorSequence.new(ks), Parent = hu })
            local hc = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = WHITE, ZIndex = 3, Parent = hu })
            deco(hc, 2)
            local function apply(silent)
                X.Value = Color3.fromHSV(h, s, v)
                sw.BackgroundColor3, sv.BackgroundColor3 = X.Value, Color3.fromHSV(h, 1, 1)
                tw(sc, .08, { Position = UDim2.fromScale(s, 1 - v) }, S)
                tw(hc, .08, { Position = UDim2.fromScale(.5, h) }, S)
                flag(o, X.Value)
                if not silent then call(o, X.Value) end
            end
            hold(sv, function(m)
                s = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
                apply()
            end)
            hold(hu, function(m) h = math.clamp((m.Y - hu.AbsolutePosition.Y) / hu.AbsoluteSize.Y, 0, 1) apply() end)
            hit.MouseButton1Click:Connect(function() X.Open = not X.Open tw(f, .45, { Size = UDim2.new(1, 0, 0, X.Open and 146 or 36) }) end)
            function X:Set(c) h, s, v = c:ToHSV() apply() end
            function X:Get() return X.Value end
            apply(true)
            return X
        end

        return T
    end

    if ld then ld.step("Ready", 1) ld.close() end
    W:Show()
    return W
end

return V
