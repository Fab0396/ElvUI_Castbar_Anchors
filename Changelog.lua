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
        f.title:SetText("|cff00d4ffElvUI|r Castbar Anchors - v2.15.0")

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
|cffFFD100v2.15.0 - ESSENTIAL CD ICON FIX!|r
|cff00d4ffCRITICAL FIX|r

Fixed the icon sticking out when using
EssentialCooldownViewer with Match Anchor Width!

|cffFF0000The Problem:|r
When anchored to EssentialCooldownViewer with
"Match Anchor Width" enabled:
- Castbar width is LOCKED to match EssentialCD
- Can't adjust width manually
- Icon adds extra width
- Icon sticks out horizontally! ❌

User had to adjust X offset to compensate,
which defeats the purpose of centered anchoring.

|cff00FF00The Solution:|r
NEW: "Adjust Width for Icon (EssentialCD)"!

This checkbox works exactly like the unitframe
version, but for EssentialCooldownViewer:
- Automatically subtracts icon width from castbar
- Keeps total width = EssentialCD width
- Icon fits perfectly! ✅

|cffFFFF00Where To Find It:|r
ElvUI > Plugins > Castbar Anchors > Player

When anchored to EssentialCooldownViewer:

EssentialCooldownViewer Settings:
- Match Anchor Width: ✅
- EssentialCD Height: 27
- |cff00FF00Adjust Width for Icon: ✅|r ← NEW!
- Icon Size (EssentialCD): 31

|cffFFFF00How It Works:|r
Before (icon sticks out):
- EssentialCD width: 300px
- Match Anchor Width: ✅
- Castbar width: 300px
- Icon width: 31px
- Total width: 331px ❌ STICKS OUT!

After (perfect fit):
- EssentialCD width: 300px
- Match Anchor Width: ✅
- Adjust Width for Icon: ✅
- Castbar width: 269px (300 - 31)
- Icon width: 31px
- Total width: 300px ✅ PERFECT!

|cff00d4ffExample Setup:|r
Anchored to EssentialCooldownViewer:

Settings:
- Quick Select: EssentialCooldownViewer
- Match Anchor Width: ✅ Checked
- EssentialCD Height: 27
- Adjust Width for Icon (EssentialCD): ✅ Checked
- Icon Size (EssentialCD): 31

Result:
- Castbar + icon = EssentialCD width
- No horizontal overflow! ✅
- Perfectly centered! ✅
- No need to adjust X offset! ✅

|cffFFFF00When To Use It:|r
Enable "Adjust Width for Icon (EssentialCD)" when:
✅ Anchored to EssentialCooldownViewer
✅ Match Anchor Width is enabled
✅ Icon is visible (ElvUI castbar icon enabled)
✅ Icon sticks out horizontally

Leave it DISABLED when:
❌ Not using EssentialCooldownViewer
❌ Match Anchor Width is disabled
❌ Icon is hidden
❌ Icon already fits

|cffFFFF00Technical Details:|r
The checkbox is:
- Order: 16.5 (between Height and Icon Size)
- Only enabled for EssentialCooldownViewer anchor
- Database field: essentialCDAdjustForIcon

The width calculation:
```
finalWidth = essentialCDWidth - borderAdjust

if adjustForIcon and icon visible then
    finalWidth = finalWidth - iconWidth
end

castbar:SetWidth(finalWidth)
```

Works in BOTH modes:
✅ Plugin mode (Core_Plugin.lua)
✅ Standalone mode (Core.lua)

|cff00d4ffDatabase Changes:|r
New field: essentialCDAdjustForIcon = false

Default: Disabled (false)
You need to enable it manually if icon sticks out.

|cffFFFF00UI Organization:|r
When anchored to EssentialCooldownViewer:
- ✅ Match Anchor Width - BRIGHT
- ✅ EssentialCD X/Y Offset - BRIGHT
- ✅ EssentialCD Height - BRIGHT
- ✅ |cff00FF00Adjust Width for Icon|r - BRIGHT
- ✅ Icon Size (EssentialCD) - BRIGHT
- ❌ Unitframe settings - GREYED OUT

Perfect organization! Each anchor type shows
only its relevant settings.

---

|cffFFD100v2.14.0 - Previous Update|r
- Separate icon size sliders (Unitframes/Essential)
- Icon border adjustment for unitframes
- Better UI organization by anchor type
- Icon resize working for both modes! ✅

---

No more icon overflow on EssentialCooldownViewer!
Enable "Adjust Width for Icon (EssentialCD)" and
enjoy perfectly fitted castbars! 🎉
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
