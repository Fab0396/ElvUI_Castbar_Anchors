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

        local content = CreateFrame("Frame", nil, sf)
        content:SetSize(440, 1000)
        sf:SetScrollChild(content)

        f.text = content:CreateFontString(nil, "OVERLAY")
        f.text:FontTemplate(nil, 14)
        f.text:SetPoint("TOPLEFT", 5, -5)
        f.text:SetJustifyH("LEFT")
        f.text:SetWidth(430)
        f.text:SetText([[
|cffFFD100v2.3.7 - No More Chat Spam!|r
|cff00d4ffQuality of Life|r
- ✅ Removed repetitive anchor messages
- ✅ No more chat spam on reload/UI changes
- ✅ Silent re-anchoring (still works perfectly!)
- ✅ Only shows initial load message

|cff00d4ffBefore v2.3.7|r
Every reload/UI change spammed:
"ElvUI Castbar Anchors: TARGET castbar anchoring to..."
"ElvUI Castbar Anchors: PLAYER castbar anchoring to..."
"ElvUI Castbar Anchors: FOCUS castbar anchoring to..."
(6+ messages every time!) ❌

|cff00d4ffAfter v2.3.7|r
On /reload you see:
"ElvUI Castbar Anchors v2.3.7 loaded. /ec to configure."

That's it! Clean and quiet! ✅

---

|cffFFD100v2.3.6 - Complete Forbidden Protection|r
- ✅ ZERO forbidden errors possible
- ✅ All frame access protected with pcall()

---

|cffFFD100v2.3.5 - Safe Hook System|r
- ✅ Hook-based detection
- ✅ More ElvUI hooks

---

|cffFFD100v2.3.4 - LibDBIcon Fix|r
- ✅ Fixed minimap icon errors
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
    end
end

-- Version Check logic - delay until module is loaded
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    
    -- Setup changelog function
    SetupChangelog()
    
    -- Check version
    E:Delay(5, function()
        local currentVersion = "2.3.7"
        local MyMod = E:GetModule('ElvUI_Castbar_Anchors', true)
        
        if MyMod and ElvUI_Castbar_Anchors_Version ~= currentVersion then
            MyMod:ShowChangelog()
            ElvUI_Castbar_Anchors_Version = currentVersion
        end
    end)
end)
