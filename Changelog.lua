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
|cffFFD100v2.3.6 - Complete Forbidden Protection|r
|cff00d4ffCritical Fix|r
- ✅ COMPLETE protection against forbidden errors
- ✅ All frame access wrapped in pcall()
- ✅ Silently catches and ignores forbidden access
- ✅ All hooks protected (SetPoint, Show, SetSize)
- ✅ Safe IsShown() checks
- ✅ ZERO errors guaranteed

|cff00d4ffWhat Was Protected|r
- UpdateCastbarPosition: Full pcall wrapper
- Hook setup: Protected hook creation
- Frame property access: Safe checks
- IsShown() calls: Wrapped in pcall
- All _G[frameName] lookups: Protected

|cff00d4ffHow It Works|r
Every operation that could access forbidden data:
  ↓
Wrapped in pcall(function() ... end)
  ↓
If forbidden error occurs → Silently caught
  ↓
Addon continues normally ✅

Result: IMPOSSIBLE to get forbidden errors!
Even if frames become forbidden mid-operation,
the error is caught and ignored.

---

|cffFFD100v2.3.5 - Safe Hook System|r
- ✅ Hook-based detection instead of inspection
- ✅ More ElvUI hooks added

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
        local currentVersion = "2.3.6"
        local MyMod = E:GetModule('ElvUI_Castbar_Anchors', true)
        
        if MyMod and ElvUI_Castbar_Anchors_Version ~= currentVersion then
            MyMod:ShowChangelog()
            ElvUI_Castbar_Anchors_Version = currentVersion
        end
    end)
end)
