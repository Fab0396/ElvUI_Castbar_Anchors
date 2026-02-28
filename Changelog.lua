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
        f.title:SetText("|cff00d4ffElvUI|r Castbar Anchors - v2.16.2")

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
|cffFFD100v2.16.2 - OFFSET GREYING FIX!|r
|cff00d4ffQUICK FIX|r

Fixed X/Y Offset sliders not greying out!

|cffFF0000The Problem:|r
When main anchor = EssentialCooldownViewer,
the top X Offset and Y Offset sliders were
still BRIGHT (enabled).

This was confusing because those offsets
aren't used - EssentialCD uses its own
EssentialCD X/Y Offset sliders instead!

|cff00FF00The Fix:|r
X Offset and Y Offset now grey out when:
1. Main anchor = EssentialCooldownViewer, OR
2. Pet override = EssentialCooldownViewer

|cffFFFF00Visual Feedback:|r
When anchored to EssentialCooldownViewer:
❌ X Offset - GREYED (not used)
❌ Y Offset - GREYED (not used)
✅ EssentialCD X Offset - BRIGHT (use this!)
✅ EssentialCD Y Offset - BRIGHT (use this!)

Perfect! No more confusion about which
offset sliders to use!

|cff00d4ffCode Change:|r
Lines 517-527: Updated disabled functions
Added check: if db.anchorFrame == "EssentialCD"

---

|cffFFD100v2.16.1 - PET OVERRIDE FIX|r
|cff00d4ffCRITICAL FIXES|r

Fixed two major issues with pet override!

|cff00FF00FIX 1: Settings Now Shared!|r
Pet override now USES THE SAME EssentialCD
settings as the main anchor!

Before: Had to configure settings twice ❌
After: Configure once, works for both! ✅

|cff00FF00FIX 2: Smart UI Greying!|r
When pet override = EssentialCD, unitframe
settings are GREYED OUT!

Greyed when pet override is EssentialCD:
❌ X/Y Offset
❌ Castbar Width/Height (Unitframes)
❌ Adjust Width for Icon
❌ Icon Size (Unitframes)
❌ Icon Border Adjustment

✅ EssentialCD settings - BRIGHT

Perfect visual feedback!

---

|cffFFD100v2.16.0 - PET OVERRIDE + RANGE UPDATE|r
|cff00d4ffMAJOR UPDATE|r

Two important improvements!

|cff00FF00NEW: EssentialCD Pet Frame Override!|r

You can now use EssentialCooldownViewer as a
pet frame override anchor!

|cffFFFF00How To Use:|r
ElvUI > Plugins > Castbar Anchors > Player

Pet Frame Override:
- Use Pet Frame when Active: ✅ Checked
- Pet Frame Quick Select: Essential Cooldown Viewer

Result:
- When pet active → anchors to EssentialCD
- When pet inactive → anchors to normal frame
- ALL EssentialCD settings available! ✅

|cff00d4ffAvailable Settings:|r
✅ Match Anchor Width
✅ Border Adjustment
✅ EssentialCD X/Y Offset
✅ EssentialCD Height
✅ Adjust Width for Icon (EssentialCD)
✅ Icon Size (EssentialCD)

Perfect for classes with pets!

|cff00FF00NEW: Border Range 1-50!|r

Border Adjustment slider range increased!

Before: 0 - 10
After: 1 - 50 (step 0.5)

Now supports thick borders and complex layouts!

---

|cffFFD100v2.15.1 - FINE-TUNING UPDATE|r

|cff00FF00What Changed:|r
Both border adjustment sliders now use 0.5 steps:
- Icon Border Adjustment: 0, 0.5, 1, 1.5, 2, 2.5...
- Border Adjustment (EssentialCD): 0, 0.5, 1, 1.5, 2, 2.5...

|cffFFFF00Why This Matters:|r
Sometimes 1px adjustments are too much!
Now you can fine-tune with 0.5px precision:
- Border is 1.5px? Set to 1.5 ✅
- Need 2.5px adjustment? Set to 2.5 ✅

Perfect for those in-between border sizes!

---

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
