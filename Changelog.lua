-- Check if ElvUI is loaded
local isElvUILoaded = (C_AddOns and C_AddOns.IsAddOnLoaded("ElvUI")) or select(2, IsAddOnLoaded("ElvUI"))
if not isElvUILoaded then return end

local E, L, V, P, G = unpack(ElvUI)

-- This will be called after the module is registered
local function SetupChangelog()
    local S = E:GetModule('Skins')
    local MyMod = E:GetModule('ElvUI_Castbar_Anchors', true)
    if not MyMod then return end

    function MyMod:ShowChangelog()
        -- Create the Main Window
        local f = CreateFrame("Frame", "ElvUI_Castbar_Anchors_Changelog", E.UIParent)
        f:SetSize(500, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:CreateBackdrop("Transparent")

        -- Title
        f.title = f:CreateFontString(nil, "OVERLAY")
        f.title:FontTemplate(nil, 20, "OUTLINE")
        f.title:SetPoint("TOP", 0, -10)
        f.title:SetText("|cff00d4ffElvUI|r Castbar Anchors - Changelog")

        -- Content Scroll Frame
        local sf = CreateFrame("ScrollFrame", "ElvUI_Castbar_Anchors_ChangelogScrollFrame", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 15, -45)
        sf:SetPoint("BOTTOMRIGHT", -35, 45)
        
        local scrollbar = _G["ElvUI_Castbar_Anchors_ChangelogScrollFrameScrollBar"]
        if S and S.HandleScrollBar then
            S:HandleScrollBar(scrollbar)
        end
        
        -- Logic to only show scrollbar if content is larger than view
        scrollbar:SetAlpha(0) 
        sf:SetScript("OnUpdate", function(self)
            local _, max = scrollbar:GetMinMaxValues()
            if max > 0 then
                scrollbar:SetAlpha(1)
            else
                scrollbar:SetAlpha(0)
            end
        end)
        
        local content = CreateFrame("Frame")
        sf:SetScrollChild(content)
        content:SetWidth(430)

        -- Content Text
        f.text = content:CreateFontString(nil, "OVERLAY")
        f.text:FontTemplate(nil, 12)
        f.text:SetPoint("TOPLEFT", 0, 0)
        f.text:SetJustifyH("LEFT")
        f.text:SetWidth(430)
        f.text:SetText([[
|cffFFD100v2.9.0 - FINALLY IN THE RIGHT FILE!|r
|cff00d4ffTHE REAL FIX!|r

|cffFF0000The Problem (v2.8.0-2.8.8):|r
I was adding sliders to Settings.lua, which is
ONLY for standalone mode!

You're using ElvUI Plugin Mode, so Settings.lua
never loads! That's why there was no debug output
and no sliders!

|cff00FF00The Solution (v2.9.0):|r
Added the sliders to Core_Plugin.lua where the
plugin mode settings actually live!

|cffFFFF00NEW: Width & Height Sliders!|r
Now in the CORRECT file for plugin mode:

✅ "Castbar Width (Unitframes only)" slider
   - Min: 50, Max: 500
   - Only enabled when anchored to Health/Power bars
   - Auto-reads from ElvUI on first load
   - Shows your actual ElvUI width (e.g., 274)

✅ "Castbar Height (Unitframes only)" slider
   - Min: 5, Max: 100
   - Only enabled when anchored to Health/Power bars
   - Auto-reads from ElvUI on first load
   - Shows your actual ElvUI height (e.g., 36)

|cff00d4ffWhere To Find Them:|r
ElvUI > Plugins > Castbar Anchors > Player

Under "Anchor Settings" group:
- Anchor Point
- Relative Point
- X Offset
- Y Offset
- |cff00FF00Castbar Width (Unitframes only)|r ← NEW!
- |cff00FF00Castbar Height (Unitframes only)|r ← NEW!
- Match Anchor Width
- (EssentialCD settings...)

|cffFFFF00How They Work:|r
Anchored to "Player Power Bar":
✅ Width slider ENABLED (bright)
✅ Height slider ENABLED (bright)
✅ Shows values from ElvUI (274 × 36)

Anchored to "Essential Cooldown Viewer":
❌ Width slider DISABLED (greyed out)
❌ Height slider DISABLED (greyed out)
✅ EssentialCD sliders enabled instead

Anchored to "Screen Center":
❌ Width slider DISABLED (greyed out)
❌ Height slider DISABLED (greyed out)

|cffFFFF00Why It Works Now:|r
Before: Added to Settings.lua (standalone mode)
→ Plugin mode never loaded Settings.lua
→ Sliders never appeared ❌

After: Added to Core_Plugin.lua (plugin mode)
→ Plugin mode loads Core_Plugin.lua
→ Sliders appear in ElvUI settings! ✅

|cff00d4ffHow To Use:|r
1. Open ElvUI > Plugins > Castbar Anchors
2. Click "Player" tab
3. Enable the player castbar
4. Select "Player Power Bar" from Quick Select
5. Scroll down to "Anchor Settings"
6. YOU SHOULD SEE:
   - "Castbar Width (Unitframes only)" slider
   - "Castbar Height (Unitframes only)" slider
7. Adjust to match your setup!

The sliders will:
- Start with your current ElvUI values
- Only work for Health/Power bar anchors
- Grey out for other anchor types
- Update the castbar size in real-time

|cffFFFF00Technical Note:|r
ElvUI Plugin Mode vs Standalone Mode:
- Plugin Mode: Uses Core_Plugin.lua (InsertOptions)
- Standalone Mode: Uses Settings.lua (ShowSettingsUI)

You're in Plugin Mode, so the sliders needed to
be in Core_Plugin.lua, not Settings.lua!

---

|cffFFD100v2.8.0-2.8.8 - Wrong File!|r
- Added sliders to Settings.lua (standalone)
- You're using plugin mode
- Settings.lua never loaded
- That's why nothing worked!
]])

        content:SetHeight(f.text:GetStringHeight() + 20)

        -- Close Button
        local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        close:SetSize(100, 25)
        close:SetPoint("BOTTOM", 0, 10)
        close:SetText("Close")
        close:SetScript("OnClick", function() f:Hide() end)
        if S and S.HandleButton then
            S:HandleButton(close)
        end

        f:Show()
    end
end

E:Delay(1, SetupChangelog)
