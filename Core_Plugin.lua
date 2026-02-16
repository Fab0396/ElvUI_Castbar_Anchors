-- Core_Plugin.lua - Only loads if ElvUI is present
local isElvUILoaded = (C_AddOns and C_AddOns.IsAddOnLoaded("ElvUI")) or select(2, IsAddOnLoaded("ElvUI"))
if not isElvUILoaded then return end

-- ======================================
-- ELVUI PLUGIN MODE
-- ======================================
local E, L, V, P, G = unpack(ElvUI)
local MyMod = E:NewModule('ElvUI_Castbar_Anchors', 'AceEvent-3.0', 'AceHook-3.0')
local EP = LibStub("LibElvUIPlugin-1.0")
local LibDBIcon = LibStub("LibDBIcon-1.0")

MyMod.version = "2.3.7"

local CASTBAR_FRAMES = {
    player = "ElvUF_Player_CastBar",
    target = "ElvUF_Target_CastBar",
    focus = "ElvUF_Focus_CastBar",
}

-- Default Settings (stored in ElvUI's profile database)
P['ElvUI_Castbar_Anchors'] = {
    ['minimap'] = { ['hide'] = false, ['minimapPos'] = 220 },
    ['castbars'] = {
        ['player'] = { ['enabled'] = false, ['anchorFrame'] = nil, ['anchorPoint'] = "CENTER", ['relativePoint'] = "CENTER", ['offsetX'] = 0, ['offsetY'] = 0, ['updateRate'] = 0.05, ['usePetFrame'] = false, ['petAnchorFrame'] = nil },
        ['target'] = { ['enabled'] = false, ['anchorFrame'] = nil, ['anchorPoint'] = "CENTER", ['relativePoint'] = "CENTER", ['offsetX'] = 0, ['offsetY'] = 0, ['updateRate'] = 0.05 },
        ['focus'] = { ['enabled'] = false, ['anchorFrame'] = nil, ['anchorPoint'] = "CENTER", ['relativePoint'] = "CENTER", ['offsetX'] = 0, ['offsetY'] = 0, ['updateRate'] = 0.05 },
    },
}

MyMod.updateTickers = {}
MyMod.hooked = {}

function MyMod:GetCastbar(castbarType)
    return _G[CASTBAR_FRAMES[castbarType]]
end

function MyMod:UpdateCastbarPosition(castbarType)
    -- Don't update during combat to avoid taint
    if InCombatLockdown() then return end
    
    local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
    if not db or not db.anchorFrame then return end
    
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

function MyMod:StartAnchoring(castbarType)
    local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
    if not db.anchorFrame then return end
    
    self:StopAnchoring(castbarType)
    
    local castbar = self:GetCastbar(castbarType)
    if not castbar then return end
    
    -- Hook the castbar's SetPoint to detect when ElvUI moves it (with protection)
    if not castbar.__CA_Hooked then
        local hookSuccess = pcall(function()
            self:SecureHook(castbar, "SetPoint", function(frame)
                -- If we're not in combat and this wasn't our anchor call, re-anchor
                if not InCombatLockdown() and not frame.__CA_SettingPoint then
                    C_Timer.After(0.05, function()
                        if db.enabled and not InCombatLockdown() then
                            MyMod:UpdateCastbarPosition(castbarType)
                        end
                    end)
                end
            end)
            
            self:SecureHook(castbar, "ClearAllPoints", function(frame)
                if not InCombatLockdown() and not frame.__CA_SettingPoint then
                    C_Timer.After(0.05, function()
                        if db.enabled and not InCombatLockdown() then
                            MyMod:UpdateCastbarPosition(castbarType)
                        end
                    end)
                end
            end)
        end)
        
        if hookSuccess then
            castbar.__CA_Hooked = true
        end
    end
    
    -- Simple ticker that just updates position periodically
    self.updateTickers[castbarType] = E:Delay(db.updateRate or 0.05, function()
        if not InCombatLockdown() then
            MyMod:UpdateCastbarPosition(castbarType)
        end
    end, true)
    
    self:UpdateCastbarPosition(castbarType)
    -- Silently anchor without chat spam
    
    -- Hook into frame updates to detect changes
    self:HookFrameUpdates(castbarType)
end

function MyMod:HookFrameUpdates(castbarType)
    local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
    local anchorFrame = _G[db.anchorFrame]
    
    if anchorFrame and not self.hooked[castbarType] then
        self.hooked[castbarType] = true
        
        -- Wrap hooks in pcall to protect against forbidden access
        pcall(function()
            -- Hook show/hide events (with combat protection)
            if not self:IsHooked(anchorFrame, "Show") then
                self:SecureHookScript(anchorFrame, "Show", function()
                    if not InCombatLockdown() then
                        C_Timer.After(0.1, function()
                            if db.enabled and not InCombatLockdown() then
                                MyMod:UpdateCastbarPosition(castbarType)
                            end
                        end)
                    end
                end)
            end
        end)
        
        pcall(function()
            -- Hook size changes (with combat protection)
            if anchorFrame.SetSize and not self:IsHooked(anchorFrame, "SetSize") then
                self:SecureHook(anchorFrame, "SetSize", function()
                    if not InCombatLockdown() then
                        C_Timer.After(0.1, function()
                            if db.enabled and not InCombatLockdown() then
                                MyMod:UpdateCastbarPosition(castbarType)
                            end
                        end)
                    end
                end)
            end
        end)
    end
    
    -- Also hook pet frame if using pet override (with combat protection)
    if castbarType == "player" and db.usePetFrame and db.petAnchorFrame then
        local petFrame = _G[db.petAnchorFrame]
        if petFrame and not self.hooked["pet_"..castbarType] then
            self.hooked["pet_"..castbarType] = true
            
            pcall(function()
                if not self:IsHooked(petFrame, "Show") then
                    self:SecureHookScript(petFrame, "Show", function()
                        if not InCombatLockdown() then
                            C_Timer.After(0.1, function()
                                if db.enabled and db.usePetFrame and not InCombatLockdown() then
                                    MyMod:UpdateCastbarPosition(castbarType)
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end
end

function MyMod:StopAnchoring(castbarType)
    if self.updateTickers[castbarType] then
        E:CancelTimer(self.updateTickers[castbarType])
        self.updateTickers[castbarType] = nil
    end
end

function MyMod:SetAnchorFrame(castbarType, frameName)
    local frame = _G[frameName]
    if not frame then print("|cffff0000ElvUI Castbar Anchors:|r Frame not found!") return end
    
    local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
    db.anchorFrame = frameName
    if db.enabled then self:StartAnchoring(castbarType) end
end

function MyMod:SetupMinimapIcon()
    local LDBObject = LibStub("LibDataBroker-1.1"):NewDataObject("ElvUI_Castbar_Anchors", {
        type = "launcher",
        icon = "Interface\\Icons\\spell_nature_astralrecal",
        OnClick = function() E:ToggleOptions("ElvUI_Castbar_Anchors") end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cff00d4ffElvUI Castbar Anchors|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cffffd700Click:|r Open Settings (ElvUI Plugin)")
        end,
    })
    LibDBIcon:Register("ElvUI_Castbar_Anchors", LDBObject, E.db.ElvUI_Castbar_Anchors.minimap)
end

function MyMod:ToggleMinimapIcon()
    E.db.ElvUI_Castbar_Anchors.minimap.hide = not E.db.ElvUI_Castbar_Anchors.minimap.hide
    if E.db.ElvUI_Castbar_Anchors.minimap.hide then LibDBIcon:Hide("ElvUI_Castbar_Anchors") else LibDBIcon:Show("ElvUI_Castbar_Anchors") end
end

function MyMod:SetupAddonCompartment()
    if AddonCompartmentFrame then
        AddonCompartmentFrame:RegisterAddon({
            text = "ElvUI Castbar Anchors",
            icon = "Interface\\Icons\\spell_nature_astralrecal",
            notCheckable = true,
            func = function() E:ToggleOptions("ElvUI_Castbar_Anchors") end,
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

function MyMod:InsertOptions()
    local anchorPoints = {
        ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right",
        ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right",
        ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right"
    }
    
    local function CreateCastbarOptions(castbarType, order)
        local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
        local castbarName = string.upper(castbarType:sub(1,1)) .. castbarType:sub(2)
        
        local options = {
            order = order, type = "group", name = castbarName,
            get = function(info) return db[info[#info]] end,
            set = function(info, value)
                db[info[#info]] = value
                if db.enabled and db.anchorFrame then
                    MyMod:StopAnchoring(castbarType)
                    MyMod:StartAnchoring(castbarType)
                end
            end,
            args = {
                header = { order = 1, type = "header", name = castbarName .. " Castbar" },
                enabled = {
                    order = 2, type = "toggle", name = "Enable",
                    set = function(info, value)
                        db.enabled = value
                        if value then MyMod:StartAnchoring(castbarType) else MyMod:StopAnchoring(castbarType) end
                    end,
                },
                spacer1 = { order = 3, type = "description", name = "" },
                anchorGroup = {
                    order = 4, type = "group", name = "Anchor Settings", guiInline = true,
                    disabled = function() return not db.enabled end,
                    args = {
                        suggestedFrames = {
                            order = 1, type = "select", name = "Quick Select",
                            desc = "Common ElvUI frames for this castbar",
                            values = function()
                                local suggestions = {}
                                if castbarType == "player" then
                                    suggestions["ElvUF_Player"] = "Player Frame"
                                    suggestions["ElvUF_Player_HealthBar"] = "Player Health Bar"
                                    suggestions["ElvUF_Player_PowerBar"] = "Player Power Bar"
                                    suggestions["ElvUF_Pet"] = "Pet Frame"
                                    suggestions["ElvUF_Pet_HealthBar"] = "Pet Health Bar"
                                    suggestions["ElvUF_Pet_PowerBar"] = "Pet Power Bar"
                                elseif castbarType == "target" then
                                    suggestions["ElvUF_Target"] = "Target Frame"
                                    suggestions["ElvUF_Target_HealthBar"] = "Target Health Bar"
                                    suggestions["ElvUF_Target_PowerBar"] = "Target Power Bar"
                                elseif castbarType == "focus" then
                                    suggestions["ElvUF_Focus"] = "Focus Frame"
                                    suggestions["ElvUF_Focus_HealthBar"] = "Focus Health Bar"
                                    suggestions["ElvUF_Focus_PowerBar"] = "Focus Power Bar"
                                end
                                suggestions["UIParent"] = "Screen Center"
                                return suggestions
                            end,
                            get = function() return db.anchorFrame end,
                            set = function(info, value)
                                if value and value ~= "" then
                                    MyMod:SetAnchorFrame(castbarType, value)
                                end
                            end,
                        },
                        spacer1 = { order = 2, type = "description", name = " " },
                        anchorFrame = {
                            order = 3, type = "input", name = "Custom Frame Name", width = "full",
                            desc = "Or enter any frame name (use /fstack to find)",
                            set = function(info, value) if value and value ~= "" then MyMod:SetAnchorFrame(castbarType, value) end end,
                        },
                        currentFrame = {
                            order = 4, type = "description",
                            name = function() return db.anchorFrame and ("|cff00ff00Current: " .. db.anchorFrame .. "|r") or "|cffff0000No anchor frame set|r" end,
                        },
                        spacer2 = { order = 5, type = "description", name = " " },
                        anchorPoint = { order = 6, type = "select", name = "Anchor Point", values = anchorPoints },
                        relativePoint = { order = 7, type = "select", name = "Relative Point", values = anchorPoints },
                        offsetX = { order = 8, type = "range", name = "X Offset", min = -500, max = 500, step = 1 },
                        offsetY = { order = 9, type = "range", name = "Y Offset", min = -500, max = 500, step = 1 },
                    },
                },
                spacer2 = { order = 5, type = "description", name = "" },
                updateGroup = {
                    order = 6, type = "group", name = "Update Settings", guiInline = true,
                    disabled = function() return not db.enabled end,
                    args = {
                        updateRate = {
                            order = 1, type = "range", name = "Update Rate", min = 0.01, max = 0.5, step = 0.01,
                            desc = "Lower = smoother, Higher = better performance",
                            set = function(info, value)
                                db.updateRate = value
                                if db.enabled and db.anchorFrame then
                                    MyMod:StopAnchoring(castbarType)
                                    MyMod:StartAnchoring(castbarType)
                                end
                            end,
                        },
                    },
                },
            },
        }
        
        if castbarType == "player" then
            options.args.spacer3 = { order = 7, type = "description", name = "" }
            options.args.petGroup = {
                order = 8, type = "group", name = "Pet Frame Override", guiInline = true,
                disabled = function() return not db.enabled end,
                args = {
                    usePetFrame = { 
                        order = 1, type = "toggle", name = "Use Pet Frame when Active", 
                        desc = "Switch to pet frame when pet is active" 
                    },
                    spacer1 = { order = 2, type = "description", name = " " },
                    petQuickSelect = {
                        order = 3, type = "select", name = "Pet Frame Quick Select",
                        desc = "Common pet frames",
                        disabled = function() return not db.usePetFrame end,
                        values = {
                            ["ElvUF_Pet"] = "Pet Frame",
                            ["ElvUF_Pet_HealthBar"] = "Pet Health Bar",
                            ["ElvUF_Pet_PowerBar"] = "Pet Power Bar",
                        },
                        get = function() return db.petAnchorFrame end,
                        set = function(info, value)
                            db.petAnchorFrame = value
                            if db.enabled and db.usePetFrame then
                                MyMod:StopAnchoring(castbarType)
                                MyMod:StartAnchoring(castbarType)
                            end
                        end,
                    },
                    petAnchorFrame = { 
                        order = 4, type = "input", name = "Or Custom Pet Frame Name", 
                        width = "full", desc = "e.g., ElvUF_Pet", 
                        disabled = function() return not db.usePetFrame end,
                        set = function(info, value)
                            db.petAnchorFrame = value
                            if db.enabled and db.usePetFrame then
                                MyMod:StopAnchoring(castbarType)
                                MyMod:StartAnchoring(castbarType)
                            end
                        end,
                    },
                },
            }
        end
        
        return options
    end
    
    E.Options.args.ElvUI_Castbar_Anchors = {
        type = "group", name = "Castbar Anchors", childGroups = "tab",
        args = {
            header = { order = 1, type = "header", name = "|cff00d4ffElvUI Castbar Anchors|r - v" .. MyMod.version },
            description = { order = 2, type = "description", name = "Anchor your ElvUI castbars to any frame.\nUse |cffffd700/fstack|r to find frame names.\n|cff00ff00ElvUI Plugin Mode|r" },
            changelog = { order = 3, type = "execute", name = "Show Changelog", func = function() MyMod:ShowChangelog() end },
            spacer1 = { order = 4, type = "description", name = "" },
            minimapGroup = {
                order = 5, type = "group", name = "Minimap Icon", guiInline = true,
                args = {
                    hide = { order = 1, type = "toggle", name = "Hide Minimap Icon", get = function() return E.db.ElvUI_Castbar_Anchors.minimap.hide end, set = function() MyMod:ToggleMinimapIcon() end },
                },
            },
            spacer2 = { order = 6, type = "description", name = " " },
            player = CreateCastbarOptions("player", 10),
            target = CreateCastbarOptions("target", 20),
            focus = CreateCastbarOptions("focus", 30),
        },
    }
end

function MyMod:Initialize()
    EP:RegisterPlugin('ElvUI_Castbar_Anchors', MyMod.InsertOptions)
    self:SetupMinimapIcon()
    self:SetupAddonCompartment()
    
    -- Listen for various update events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_REGEN_ENABLED") -- Exiting combat
    self:RegisterEvent("UNIT_PET") -- Pet changes
    self:RegisterEvent("PLAYER_TARGET_CHANGED") -- Target changes
    self:RegisterEvent("PLAYER_FOCUS_CHANGED") -- Focus changes
    
    -- Hook ElvUI's update functions
    if E.private.unitframe and E.private.unitframe.enable then
        local UF = E:GetModule('UnitFrames')
        if UF then
            -- Hook frame updates
            self:SecureHook(UF, 'Update_AllFrames', function()
                if not InCombatLockdown() then
                    C_Timer.After(0.5, function()
                        for castbarType, _ in pairs(CASTBAR_FRAMES) do
                            local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
                            if db.enabled and db.anchorFrame then
                                MyMod:UpdateCastbarPosition(castbarType)
                            end
                        end
                    end)
                end
            end)
            
            -- Hook Configure_CastBar which ElvUI calls when configuring castbars
            if UF.Configure_CastBar then
                self:SecureHook(UF, 'Configure_CastBar', function()
                    if not InCombatLockdown() then
                        C_Timer.After(0.1, function()
                            for castbarType, _ in pairs(CASTBAR_FRAMES) do
                                local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
                                if db.enabled and db.anchorFrame then
                                    MyMod:UpdateCastbarPosition(castbarType)
                                end
                            end
                        end)
                    end
                end)
            end
            
            -- Hook UpdateAllFrame which is called during layout changes
            if UF.UpdateAllFrames then
                self:SecureHook(UF, 'UpdateAllFrames', function()
                    if not InCombatLockdown() then
                        C_Timer.After(0.3, function()
                            for castbarType, _ in pairs(CASTBAR_FRAMES) do
                                local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
                                if db.enabled and db.anchorFrame then
                                    MyMod:UpdateCastbarPosition(castbarType)
                                end
                            end
                        end)
                    end
                end)
            end
            
            -- Hook individual unit frame updates
            for castbarType in pairs(CASTBAR_FRAMES) do
                local frameName = castbarType:gsub("^%l", string.upper)
                local frame = UF[frameName]
                
                if frame then
                    -- Hook the Configure function
                    if frame.Configure then
                        self:SecureHook(frame, 'Configure', function()
                            if not InCombatLockdown() then
                                C_Timer.After(0.1, function()
                                    local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
                                    if db.enabled and db.anchorFrame then
                                        MyMod:UpdateCastbarPosition(castbarType)
                                    end
                                end)
                            end
                        end)
                    end
                    
                    -- Hook the Update function
                    if frame.Update then
                        self:SecureHook(frame, 'Update', function()
                            if not InCombatLockdown() then
                                C_Timer.After(0.05, function()
                                    local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
                                    if db.enabled and db.anchorFrame then
                                        MyMod:UpdateCastbarPosition(castbarType)
                                    end
                                end)
                            end
                        end)
                    end
                end
            end
        end
    end
    
    E:Delay(2, function()
        for castbarType, _ in pairs(CASTBAR_FRAMES) do
            local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
            if db.enabled and db.anchorFrame then
                MyMod:StartAnchoring(castbarType)
            end
        end
    end)
    
    print("|cff00d4ffElvUI Castbar Anchors|r v" .. self.version .. " loaded. |cffffd700/ec|r to configure.")
end

function MyMod:PLAYER_ENTERING_WORLD()
    -- Restart all enabled anchors
    E:Delay(1, function()
        for castbarType, _ in pairs(CASTBAR_FRAMES) do
            local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
            if db.enabled and db.anchorFrame then
                MyMod:StartAnchoring(castbarType)
            end
        end
    end)
end

function MyMod:UNIT_PET(_, unit)
    if unit == "player" then
        local db = E.db.ElvUI_Castbar_Anchors.castbars.player
        if db.enabled and db.usePetFrame and not InCombatLockdown() then
            C_Timer.After(0.2, function()
                MyMod:UpdateCastbarPosition("player")
            end)
        end
    end
end

function MyMod:PLAYER_TARGET_CHANGED()
    local db = E.db.ElvUI_Castbar_Anchors.castbars.target
    if db.enabled and not InCombatLockdown() then
        C_Timer.After(0.1, function()
            MyMod:UpdateCastbarPosition("target")
        end)
    end
end

function MyMod:PLAYER_FOCUS_CHANGED()
    local db = E.db.ElvUI_Castbar_Anchors.castbars.focus
    if db.enabled and not InCombatLockdown() then
        C_Timer.After(0.1, function()
            MyMod:UpdateCastbarPosition("focus")
        end)
    end
end

function MyMod:PLAYER_REGEN_ENABLED()
    -- Update all positions after exiting combat
    for castbarType, _ in pairs(CASTBAR_FRAMES) do
        local db = E.db.ElvUI_Castbar_Anchors.castbars[castbarType]
        if db.enabled and db.anchorFrame then
            MyMod:UpdateCastbarPosition(castbarType)
        end
    end
end

E:RegisterModule(MyMod:GetName())
