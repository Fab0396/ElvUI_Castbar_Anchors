-- Detect if ElvUI is loaded
local isElvUILoaded = (C_AddOns and C_AddOns.IsAddOnLoaded("ElvUI")) or select(2, IsAddOnLoaded("ElvUI"))

if isElvUILoaded then
    -- Load ElvUI plugin version (in Core_Plugin.lua)
    -- This is handled by the TOC loading Core_Plugin.lua
else
    -- ======================================
    -- STANDALONE MODE (without ElvUI)
    -- ======================================
    ElvUI_Castbar_Anchors = {}
    local CA = ElvUI_Castbar_Anchors
    local LibDBIcon = LibStub("LibDBIcon-1.0")

    CA.version = "2.3.6"
    CA.updateTickers = {}
    CA.selectedCastbar = "player"
    CA.useCharacterSettings = false
    CA.hooked = {}

    -- Castbar frame names
    CA.castbarFrames = {
        player = "ElvUF_Player_CastBar",
        target = "ElvUF_Target_CastBar",
        focus = "ElvUF_Focus_CastBar",
    }

    -- Initialize
    function CA:Initialize()
        if not ElvUI_Castbar_Anchors_GlobalDB then
            ElvUI_Castbar_Anchors_GlobalDB = {
                minimap = { hide = false, minimapPos = 220 },
                castbars = {
                    player = { enabled = false, anchorFrame = nil, anchorPoint = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 0, updateRate = 0.05, usePetFrame = false, petAnchorFrame = nil },
                    target = { enabled = false, anchorFrame = nil, anchorPoint = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 0, updateRate = 0.05 },
                    focus = { enabled = false, anchorFrame = nil, anchorPoint = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 0, updateRate = 0.05 },
                },
            }
        end
        
        if not ElvUI_Castbar_Anchors_CharDB then
            ElvUI_Castbar_Anchors_CharDB = {
                castbars = {
                    player = { enabled = false, anchorFrame = nil, anchorPoint = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 0, updateRate = 0.05, usePetFrame = false, petAnchorFrame = nil },
                    target = { enabled = false, anchorFrame = nil, anchorPoint = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 0, updateRate = 0.05 },
                    focus = { enabled = false, anchorFrame = nil, anchorPoint = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 0, updateRate = 0.05 },
                },
            }
        end
        
        CA.db = ElvUI_Castbar_Anchors_GlobalDB
        CA.charDB = ElvUI_Castbar_Anchors_CharDB
        
        CA:SetupMinimapIcon()
        CA:SetupAddonCompartment()
        
        C_Timer.After(2, function()
            for castbarType, _ in pairs(CA.castbarFrames) do
                local db = CA:GetActiveDB(castbarType)
                if db.enabled and db.anchorFrame then
                    CA:StartAnchoring(castbarType)
                end
            end
        end)
        
        -- Register event handlers
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Combat exit
        eventFrame:RegisterEvent("UNIT_PET") -- Pet changes
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED") -- Target changes
        eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED") -- Focus changes
        
        eventFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_REGEN_ENABLED" then
                -- Update all positions after exiting combat
                for castbarType, _ in pairs(CA.castbarFrames) do
                    local db = CA:GetActiveDB(castbarType)
                    if db.enabled and db.anchorFrame then
                        CA:UpdateCastbarPosition(castbarType)
                    end
                end
            elseif event == "UNIT_PET" then
                local unit = select(1, ...)
                if unit == "player" then
                    local db = CA:GetActiveDB("player")
                    if db.enabled and db.usePetFrame and not InCombatLockdown() then
                        C_Timer.After(0.2, function()
                            CA:UpdateCastbarPosition("player")
                        end)
                    end
                end
            elseif event == "PLAYER_TARGET_CHANGED" then
                local db = CA:GetActiveDB("target")
                if db.enabled and not InCombatLockdown() then
                    C_Timer.After(0.1, function()
                        CA:UpdateCastbarPosition("target")
                    end)
                end
            elseif event == "PLAYER_FOCUS_CHANGED" then
                local db = CA:GetActiveDB("focus")
                if db.enabled and not InCombatLockdown() then
                    C_Timer.After(0.1, function()
                        CA:UpdateCastbarPosition("focus")
                    end)
                end
            end
        end)
        
        print("|cff00d4ffElvUI Castbar Anchors|r v" .. CA.version .. " loaded (Standalone). Type |cffffd700/ca|r for settings.")
    end

    function CA:GetActiveDB(castbarType)
        castbarType = castbarType or self.selectedCastbar
        return self.useCharacterSettings and self.charDB.castbars[castbarType] or self.db.castbars[castbarType]
    end

    function CA:GetCastbar(castbarType)
        castbarType = castbarType or self.selectedCastbar
        return _G[self.castbarFrames[castbarType]]
    end

    function CA:UpdateCastbarPosition(castbarType)
        -- Don't update during combat to avoid taint
        if InCombatLockdown() then return end
        
        castbarType = castbarType or self.selectedCastbar
        local db = self:GetActiveDB(castbarType)
        if not db.anchorFrame then return end
        
        -- Wrap everything in pcall to catch forbidden errors
        local success, err = pcall(function()
            local targetAnchorFrameName = db.anchorFrame
            if castbarType == "player" and db.usePetFrame and db.petAnchorFrame then
                if UnitExists("pet") then
                    local petFrame = _G[db.petAnchorFrame]
                    if petFrame and petFrame:IsShown() then
                        targetAnchorFrameName = db.petAnchorFrame
                    end
                end
            end
            
            local anchorFrame = _G[targetAnchorFrameName]
            if not anchorFrame then return end
            
            -- Safe check if frame is shown
            local isShown = false
            pcall(function() isShown = anchorFrame:IsShown() end)
            if not isShown then return end
            
            local castbar = self:GetCastbar(castbarType)
            if not castbar then return end
            
            -- Set flag to prevent our SetPoint hook from triggering
            castbar.__CA_SettingPoint = true
            
            -- FORCE re-anchor by clearing ALL points first
            castbar:ClearAllPoints()
            castbar:SetPoint(db.anchorPoint or "CENTER", anchorFrame, db.relativePoint or "CENTER", db.offsetX or 0, db.offsetY or 0)
            
            -- Clear the flag after a brief delay
            C_Timer.After(0.01, function()
                if castbar then
                    castbar.__CA_SettingPoint = nil
                end
            end)
        end)
        
        -- Silently ignore forbidden errors
        if not success and err and not err:find("forbidden") then
            -- Only print non-forbidden errors
            print("|cffff0000Castbar Anchors Error:|r", err)
        end
    end

    function CA:StartAnchoring(castbarType)
        castbarType = castbarType or self.selectedCastbar
        local db = self:GetActiveDB(castbarType)
        if not db.anchorFrame then return end
        
        self:StopAnchoring(castbarType)
        
        local castbar = self:GetCastbar(castbarType)
        if not castbar then return end
        
        -- Hook the castbar's SetPoint to detect when ElvUI moves it
        if not castbar.__CA_Hooked then
            hooksecurefunc(castbar, "SetPoint", function(frame)
                -- If we're not in combat and this wasn't our anchor call, re-anchor
                if not InCombatLockdown() and not frame.__CA_SettingPoint then
                    C_Timer.After(0.05, function()
                        if db.enabled and not InCombatLockdown() then
                            CA:UpdateCastbarPosition(castbarType)
                        end
                    end)
                end
            end)
            
            hooksecurefunc(castbar, "ClearAllPoints", function(frame)
                if not InCombatLockdown() and not frame.__CA_SettingPoint then
                    C_Timer.After(0.05, function()
                        if db.enabled and not InCombatLockdown() then
                            CA:UpdateCastbarPosition(castbarType)
                        end
                    end)
                end
            end)
            
            castbar.__CA_Hooked = true
        end
        
        -- Simple ticker that just updates position periodically
        self.updateTickers[castbarType] = C_Timer.NewTicker(db.updateRate or 0.05, function()
            if not InCombatLockdown() then
                CA:UpdateCastbarPosition(castbarType)
            end
        end)
        
        self:UpdateCastbarPosition(castbarType)
        print("|cff00d4ffElvUI Castbar Anchors:|r " .. string.upper(castbarType) .. " castbar anchoring to " .. db.anchorFrame)
        
        -- Hook frame updates (with combat protection)
        local anchorFrame = _G[db.anchorFrame]
        if anchorFrame and not self.hooked[castbarType] then
            self.hooked[castbarType] = true
            
            -- Hook show event
            if anchorFrame.Show and not anchorFrame.__CA_ShowHooked then
                hooksecurefunc(anchorFrame, "Show", function()
                    if not InCombatLockdown() then
                        C_Timer.After(0.1, function()
                            if db.enabled and not InCombatLockdown() then
                                CA:UpdateCastbarPosition(castbarType)
                            end
                        end)
                    end
                end)
                anchorFrame.__CA_ShowHooked = true
            end
            
            -- Hook SetSize
            if anchorFrame.SetSize and not anchorFrame.__CA_SetSizeHooked then
                hooksecurefunc(anchorFrame, "SetSize", function()
                    if not InCombatLockdown() then
                        C_Timer.After(0.1, function()
                            if db.enabled and not InCombatLockdown() then
                                CA:UpdateCastbarPosition(castbarType)
                            end
                        end)
                    end
                end)
                anchorFrame.__CA_SetSizeHooked = true
            end
        end
        
        -- Hook pet frame if using pet override (with combat protection)
        if castbarType == "player" and db.usePetFrame and db.petAnchorFrame then
            local petFrame = _G[db.petAnchorFrame]
            if petFrame and not self.hooked["pet_"..castbarType] then
                self.hooked["pet_"..castbarType] = true
                
                if petFrame.Show and not petFrame.__CA_ShowHooked then
                    hooksecurefunc(petFrame, "Show", function()
                        if not InCombatLockdown() then
                            C_Timer.After(0.1, function()
                                if db.enabled and db.usePetFrame and not InCombatLockdown() then
                                    CA:UpdateCastbarPosition(castbarType)
                                end
                            end)
                        end
                    end)
                    petFrame.__CA_ShowHooked = true
                end
            end
        end
    end

    function CA:StopAnchoring(castbarType)
        castbarType = castbarType or self.selectedCastbar
        if self.updateTickers[castbarType] then
            self.updateTickers[castbarType]:Cancel()
            self.updateTickers[castbarType] = nil
        end
    end

    function CA:SetAnchorFrame(frameName)
        local frame = _G[frameName]
        if not frame then print("|cffff0000ElvUI Castbar Anchors:|r Frame not found!") return end
        
        local db = self:GetActiveDB()
        db.anchorFrame = frameName
        if db.enabled then self:StartAnchoring(self.selectedCastbar) end
        if CA_SettingsFrame and CA_SettingsFrame:IsShown() then CA:UpdateSettingsUI() end
    end

    function CA:SetupMinimapIcon()
        local LDBObject = LibStub("LibDataBroker-1.1"):NewDataObject("ElvUI_Castbar_Anchors", {
            type = "launcher",
            icon = "Interface\\Icons\\spell_nature_astralrecal",
            OnClick = function() CA:ToggleSettingsUI() end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("|cff00d4ffElvUI Castbar Anchors|r")
                tooltip:AddLine(" ")
                tooltip:AddLine("|cffffd700Click:|r Open Settings")
            end,
        })
        LibDBIcon:Register("ElvUI_Castbar_Anchors", LDBObject, CA.db.minimap)
    end

    function CA:ToggleMinimapIcon()
        CA.db.minimap.hide = not CA.db.minimap.hide
        if CA.db.minimap.hide then LibDBIcon:Hide("ElvUI_Castbar_Anchors") else LibDBIcon:Show("ElvUI_Castbar_Anchors") end
    end

    function CA:SetupAddonCompartment()
        if AddonCompartmentFrame then
            AddonCompartmentFrame:RegisterAddon({
                text = "ElvUI Castbar Anchors",
                icon = "Interface\\Icons\\spell_nature_astralrecal",
                notCheckable = true,
                func = function() CA:ToggleSettingsUI() end,
                funcOnEnter = function(button)
                    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
                    GameTooltip:AddLine("|cff00d4ffElvUI Castbar Anchors|r")
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cffffd700Click:|r Open Settings")
                    GameTooltip:Show()
                end,
                funcOnLeave = function() GameTooltip:Hide() end,
            })
        end
    end

    function CA:ToggleSettingsUI()
        if CA_SettingsFrame and CA_SettingsFrame:IsShown() then CA_SettingsFrame:Hide() else CA:ShowSettingsUI() end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == "ElvUI_Castbar_Anchors" then
            -- Settings.lua will call CA:Initialize()
        end
    end)
end
