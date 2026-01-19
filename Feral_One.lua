-- ==========================================================
-- GESTIÓN DE VARIABLES Y PERFILES (Persistencia)
-- ==========================================================
local function InitializeSettings()
    if not F1_Config then F1_Config = {} end
    if F1_Config.currentGear == nil then F1_Config.currentGear = "p2" end
    if F1_Config.showCrosshair == nil then F1_Config.showCrosshair = true end
    if F1_Config.alpha == nil then F1_Config.alpha = 1.0 end
    if F1_Config.latency == nil then F1_Config.latency = 0.5 end 
    
    if not F1_Config.p1 then F1_Config.p1 = {rake=10, claw=15} end 
    if not F1_Config.p2 then F1_Config.p2 = {rake=35, claw=40} end 
    if not F1_Config.turbo then F1_Config.turbo = {rake=32, claw=37} end 
    
    if F1_Config.offsetX == nil then F1_Config.offsetX = 0 end
    if F1_Config.offsetY == nil then F1_Config.offsetY = -7 end
    if F1_Config.grosor == nil then F1_Config.grosor = 2 end

    if not F1_Config.pos then F1_Config.pos = {} end
    if F1_Config.pos.sysX == nil then F1_Config.pos.sysX = 0 end
    if F1_Config.pos.sysY == nil then F1_Config.pos.sysY = 150 end
    if F1_Config.pos.helpX == nil then F1_Config.pos.helpX = 0 end
    if F1_Config.pos.helpY == nil then F1_Config.pos.helpY = 0 end
    if F1_Config.pos.monX == nil then F1_Config.pos.monX = 0 end
    if F1_Config.pos.monY == nil then F1_Config.pos.monY = -100 end
end

local lastEnergyError = false
local isImmuneToBleed = false
local rakePending = false
local rakeTimer = 0
local lastFinisherTime = 0
local ripAttempted = false      -- Ya se intentó Rip en este target
local ripPending = false        -- Rip lanzado, esperando confirmación
local ripTimer = 0              -- Timestamp del intento de Rip
local isTurboActive = false
local lastReshiftTime = 0
local lastTargetName = nil


 -- =========================
-- SUPERWOW: DETECCIÓN DE RIP EN TARGET
-- =========================
local function TargetHasRip()
    if not UnitExists("target") then return false end

    local i = 1
    while true do
        local name, _, icon = UnitDebuff("target", i)
        if not name then break end

        -- Icono estándar de Rip (Turtle / SuperWoW)
        if icon and string.find(icon, "Ability_GhoulFrenzy") then
            return true
        end

        i = i + 1
    end

    return false
end



-- ==========================================================
-- MONITOR DE MARCHAS (CON DETECCIÓN DE TURBO ACTIVO)
-- ==========================================================
local F1_StatusFrame = CreateFrame("Frame", "F1_GearMonitor", UIParent)
F1_StatusFrame:SetWidth(120) F1_StatusFrame:SetHeight(40)
F1_StatusFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 8, edgeSize = 12, 
    insets = {left = 3, right = 3, top = 3, bottom = 3}
})
F1_StatusFrame:SetBackdropColor(0, 0, 0, 0.8)
F1_StatusFrame:SetMovable(true)
F1_StatusFrame:SetClampedToScreen(true)

local gearTxt = F1_StatusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
gearTxt:SetPoint("TOP", 0, -8)

local energyTxt = F1_StatusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
energyTxt:SetPoint("TOP", gearTxt, "BOTTOM", 0, -2)

function UpdateGearMonitor()
    if not F1_Config then return end
    
    -- Si el Turbo está activo (Berserk), mostramos aviso especial
    if isTurboActive then
        local t = F1_Config.turbo or {rake="--", claw="--"}
        gearTxt:SetText("|cffff0000!!! TURBO !!!|r")
        energyTxt:SetText("R:|cff00ff00"..t.rake.."|r C:|cff00ff00"..t.claw.."|r")
        F1_StatusFrame:SetBackdropColor(0.5, 0, 0, 0.8) -- Fondo rojizo
    else
        -- Modo normal según la marcha seleccionada
        local gear = F1_Config.currentGear or "n"
        local p = F1_Config[gear] or {rake="--", claw="--"}
        local name = (gear == "p1") and "P1" or (gear == "p2" and "P2" or "N")
        
        F1_StatusFrame:SetBackdropColor(0, 0, 0, 0.8) -- Fondo negro normal
        gearTxt:SetText("MARCHA: |cffffffff"..name.."|r")
        
        if gear == "n" then 
            energyTxt:SetText("|cff00ff00TF MODO|r")
        else 
            energyTxt:SetText("R:|cff00ff00"..p.rake.."|r C:|cff00ff00"..p.claw.."|r") 
        end
    end
end

F1_StatusFrame:SetScript("OnDragStart", function() this:StartMoving() end)
F1_StatusFrame:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing()
    local _, _, _, x, y = this:GetPoint()
    F1_Config.pos.monX = x; F1_Config.pos.monY = y
end)




-- ==========================================================
-- SISTEMA DE ANUNCIOS (MOVIBLE CON /fo edit)
-- ==========================================================
local F1_MsgFrame = CreateFrame("MessageFrame", "F1_AnnounceFrame", UIParent)
F1_MsgFrame:SetWidth(600) F1_MsgFrame:SetHeight(100)
F1_MsgFrame:SetInsertMode("TOP") F1_MsgFrame:SetFrameStrata("HIGH")
F1_MsgFrame:SetTimeVisible(2.5) F1_MsgFrame:SetFont("Fonts\\FRIZQT__.TTF", 26, "OUTLINE") 
F1_MsgFrame:SetMovable(true)
F1_MsgFrame:SetClampedToScreen(true)

F1_MsgFrame.bg = F1_MsgFrame:CreateTexture(nil, "BACKGROUND")
F1_MsgFrame.bg:SetAllPoints()
F1_MsgFrame.bg:SetTexture(0, 1, 0, 0.3)
F1_MsgFrame.bg:Hide()

F1_MsgFrame:SetScript("OnDragStart", function() this:StartMoving() end)
F1_MsgFrame:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing()
    local _, _, _, x, y = this:GetPoint()
    F1_Config.pos.sysX = x; F1_Config.pos.sysY = y
end)

local function F1_Announce(text, r, g, b)
    F1_MsgFrame:AddMessage(text, r, g, b)
end

-- ==========================================================
-- PANEL DE AYUDA (ESTILO GUÍA RÁPIDA FERAL_ONE)
-- ==========================================================
local F1_HelpPanel = CreateFrame("Frame", "F1_HelpFrame", UIParent)
F1_HelpPanel:SetWidth(380) F1_HelpPanel:SetHeight(480)
F1_HelpPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 8, edgeSize = 16, 
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
F1_HelpPanel:SetBackdropColor(0, 0, 0, 0.95)
F1_HelpPanel:SetMovable(true)
F1_HelpPanel:EnableMouse(true)
F1_HelpPanel:SetClampedToScreen(true)
F1_HelpPanel:RegisterForDrag("LeftButton")
F1_HelpPanel:SetScript("OnDragStart", function() this:StartMoving() end)
F1_HelpPanel:SetScript("OnDragStop", function() 
    this:StopMovingOrSizing()
    local _, _, _, x, y = this:GetPoint()
    F1_Config.pos.helpX = x; F1_Config.pos.helpY = y
end)
F1_HelpPanel:Hide()

local closeBtn = CreateFrame("Button", nil, F1_HelpPanel)
closeBtn:SetWidth(24) closeBtn:SetHeight(24)
closeBtn:SetPoint("TOPRIGHT", -8, -8)
closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
closeBtn:SetScript("OnClick", function() F1_HelpPanel:Hide() end)

local helpTitle = F1_HelpPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
helpTitle:SetPoint("TOP", 0, -15) 
helpTitle:SetText("|cff00ff00=== GUÍA RÁPIDA FERAL_ONE ===|r")

local helpBody = F1_HelpPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
helpBody:SetPoint("TOPLEFT", 15, -45) 
helpBody:SetJustifyH("LEFT")

local function UpdateHelpText()
    local gear = F1_Config.currentGear or "n"
    local a = F1_Config.alpha or 1
    local g = F1_Config.grosor or 2
    local lat = F1_Config.latency or 0.5
    local p = F1_Config[gear] or {rake="N/A", claw="N/A"}
    local gearName = (gear == "p1") and "PRIMERA" or (gear == "p2" and "SEGUNDA" or "NEUTRAL")

    helpBody:SetText(
        "|cffffff001. MODOS DE COMBATE:|r\n"..
        " - |cffffffffBoss:|r Maximizar daño (Rip/Bite).\n"..
        " - |cffffffffTrash:|r Limpieza rápida de pulls.\n"..
        " |cffff0000IMPORTANTE: CREAR ESTOS 2 MACROS:|r\n"..
        " |cff00ffff/run DoFeralRotation('boss')|r\n"..
        " |cff00ffff/run DoFeralRotation('trash')|r\n\n"..
        "|cffffff002. DETECCIÓN E INMUNIDAD:|r\n"..
        " - |cffffffff/fo latency ["..lat.."]:|r Ajusta espera de red.\n\n"..
        "|cffffff003. CONFIGURACIÓN Y MARCHAS:|r\n"..
        " - |cffffffffMarcha Actual:|r |cff00ff00"..gearName.."|r\n"..
        " - |cffffffffEnergía Reshift:|r Rake: "..p.rake.." / Claw: "..p.claw.."\n"..
        " - |cff00ffff/fo n, p1, p2|r / |cff00ffff/fo cycle|r (Tuerca)\n"..
        " - |cff00ffff/fo edit [p1/p2/turbo] [rake] [claw]|r\n\n"..
        "|cffffff004. CRUZ VISUAL:|r\n"..
        " - |cffffffffStatus:|r Alpha: "..a.." | Grosor: "..g.."\n"..
        " - |cff00ffff/fo cruz|r (ON/OFF) | |cff00ffff/fo alpha|r | |cff00ffff/fo grosor|r\n\n"..
        "|cffff0000AVISO: EN MODO TURBO NO SE HACE RESHIFT PARA TF.|r"
    )
end

-- ==========================================================
-- SECCIÓN: CRUZ DE OBJETIVO (Visual)
-- ==========================================================
local NPL_Frame = CreateFrame("Frame", nil, UIParent)
NPL_Frame:SetFrameStrata("BACKGROUND")
local HBar = NPL_Frame:CreateTexture(nil, "BACKGROUND")
HBar:SetTexture(1, 1, 1, 1)
local VBar = NPL_Frame:CreateTexture(nil, "BACKGROUND")
VBar:SetTexture(1, 1, 1, 1)

local function GetTargetPlate()
    if not UnitExists("target") then return nil end
    local children = {WorldFrame:GetChildren()}
    for _, child in ipairs(children) do
        if child:IsShown() and child:GetAlpha() == 1 then
            if child:GetObjectType() == "Button" or (pfUI and child.hp) then return child end
        end
    end
    return nil
end

NPL_Frame:SetScript("OnUpdate", function()
    if not F1_Config or not F1_Config.showCrosshair then HBar:Hide() VBar:Hide() return end
    local plate = GetTargetPlate()
    if plate then
        local a, g = F1_Config.alpha or 1.0, F1_Config.grosor or 2
        HBar:SetHeight(g) HBar:SetWidth(5000)
        VBar:SetWidth(g) VBar:SetHeight(5000)
        if UnitIsFriend("player", "target") then HBar:SetVertexColor(1,1,1, a) VBar:SetVertexColor(1,1,1, a)
        elseif UnitIsEnemy("player", "target") then HBar:SetVertexColor(1,0,0, a) VBar:SetVertexColor(1,0,0, a)
        else HBar:SetVertexColor(1,1,0, a) VBar:SetVertexColor(1,1,0, a) end
        HBar:ClearAllPoints() HBar:SetPoint("CENTER", plate, "CENTER", F1_Config.offsetX, F1_Config.offsetY)
        VBar:ClearAllPoints() VBar:SetPoint("CENTER", plate, "CENTER", F1_Config.offsetX, F1_Config.offsetY)
        HBar:Show() VBar:Show()
    else HBar:Hide() VBar:Hide() end
end)

-- ==========================================================
-- LÓGICA DE EVENTOS (CON ACTUALIZACIÓN DE MONITOR)
-- ==========================================================
local FeralEvents = CreateFrame("Frame")
FeralEvents:RegisterEvent("ADDON_LOADED")
FeralEvents:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
FeralEvents:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
FeralEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
FeralEvents:RegisterEvent("UI_ERROR_MESSAGE")
FeralEvents:RegisterEvent("PLAYER_AURAS_CHANGED")

FeralEvents:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "Feral_One" then
        InitializeSettings()
        F1_MsgFrame:SetPoint("CENTER", F1_Config.pos.sysX, F1_Config.pos.sysY)
        F1_HelpPanel:SetPoint("CENTER", F1_Config.pos.helpX, F1_Config.pos.helpY)
        F1_StatusFrame:SetPoint("CENTER", F1_Config.pos.monX, F1_Config.pos.monY)
        UpdateGearMonitor()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Feral_One v11.6 Blindado. (/fo help)|r")
        
elseif event == "PLAYER_TARGET_CHANGED" then
    -- Reset general por cambio de objetivo
    isImmuneToBleed = false
    lastEnergyError = false

    -- Reset RAKE
    rakePending = false
    rakeTimer = 0

    -- Reset RIP
    ripAttempted = false
    ripPending = false
    ripTimer = 0

    -- Reset FINISHER LOCK (MUY IMPORTANTE)
    lastFinisherTime = 0


        
 elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then

    -- =========================
    -- === DETECCIÓN DE RAKE ===
    -- =========================
    if (string.find(arg1, "Rake") or string.find(arg1, "Arañazo")) then
        if string.find(arg1, "hits") or string.find(arg1, "crits") or string.find(arg1, "golpea") then
            rakePending = true
            rakeTimer = GetTime()

        elseif string.find(arg1, "immune") or string.find(arg1, "inmune") then
            isImmuneToBleed = true
            rakePending = false
            F1_Announce("TARGET INMUNE", 1, 0, 0)

        elseif string.find(arg1, "miss") or string.find(arg1, "dodge")
            or string.find(arg1, "parry")
            or string.find(arg1, "esquiva")
            or string.find(arg1, "para") then
            rakePending = false
        end
    end

    -- ========================
    -- === DETECCIÓN DE RIP ===
    -- ========================
    if string.find(arg1, "Rip") or string.find(arg1, "Destripar") then

        -- Aplicación del debuff (confirmación primaria)
        if string.find(arg1, "afflicted") or string.find(arg1, "afligido") then
            ripPending = false
            ripAttempted = true
            isImmuneToBleed = false

        -- Primer tick de daño (confirmación secundaria)
        elseif string.find(arg1, "suffers") or string.find(arg1, "sufre") then
            ripPending = false
            ripAttempted = true
            isImmuneToBleed = false

        -- Rip falló / fue inmune
        elseif string.find(arg1, "immune") or string.find(arg1, "inmune") then
            ripPending = false
            ripAttempted = true
            isImmuneToBleed = true
            F1_Announce("RIP INMUNE", 1, 0, 0)
        end
    end

        
elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then

    -- =========================
    -- RAKE (ticks o aplicación)
    -- =========================
    if rakePending then
        if string.find(arg1, "Rake") or string.find(arg1, "Arañazo") then
            isImmuneToBleed = false
            rakePending = false
        elseif string.find(arg1, "immune") or string.find(arg1, "inmune") then
            isImmuneToBleed = true
            rakePending = false
        end
    end

-- =========================
-- RIP: CONFIRMACIÓN / FAILSAFE (ESTABLE EN VANILLA)
-- =========================
elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS"
   or event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS" then

    if ripPending then
        -- Confirmación REAL del debuff (no ticks)
        if string.find(arg1, "is afflicted by Rip")
           or string.find(arg1, "is afflicted by Destripar") then

            ripPending = false
            ripAttempted = true
        end
    end

-- =========================
-- RIP: FALLO / INMUNIDAD (GENÉRICO)
-- =========================
elseif event == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" then
    if ripPending then
        ripPending = false
        ripAttempted = true

        -- Solo marcamos inmunidad si el mensaje lo indica
        if string.find(arg1, "immune") or string.find(arg1, "inmune") then
            isImmuneToBleed = true
        end
    end


        
    elseif event == "UI_ERROR_MESSAGE" then
        if (arg1 == "Not enough energy" or arg1 == "Falta energía") then lastEnergyError = true end
        
    elseif event == "PLAYER_AURAS_CHANGED" then
        local found, i = false, 1
        while true do
            local b = GetPlayerBuffTexture(GetPlayerBuff(i, "HELPFUL"))
            if not b then break end
            if string.find(b, "Ability_Druid_Berserk") then found = true break end
            i = i + 1
        end
        
        if found and not isTurboActive then
            isTurboActive = true; 
            F1_Announce(">>> MODO TURBO: ACTIVADO <<<", 1, 0, 0)
            UpdateGearMonitor() -- Actualiza el visor a modo Turbo
        elseif not found and isTurboActive then
            isTurboActive = false; 
            F1_Announce("Turbo finalizado", 1, 1, 1)
            UpdateGearMonitor() -- Vuelve el visor a modo normal
        end
    end
end)

-- ==========================================================
-- SISTEMA DE COMANDOS /fo (ACTUALIZADO CON ANUNCIOS)
-- ==========================================================
SLASH_FERALONE1 = "/fo"
SlashCmdList["FERALONE"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do table.insert(args, word) end
    
    if args[1] == "help" or args[1] == "status" or args[1] == nil then
        UpdateHelpText(); F1_HelpPanel:Show()

    elseif args[1] == "cruz" then
        F1_Config.showCrosshair = not F1_Config.showCrosshair
        F1_Announce("CRUZ: "..(F1_Config.showCrosshair and "ON" or "OFF"), 0, 1, 1)

    elseif args[1] == "alpha" then
        F1_Config.alpha = tonumber(args[2]) or F1_Config.alpha; UpdateHelpText()

    elseif args[1] == "grosor" then
        F1_Config.grosor = tonumber(args[2]) or F1_Config.grosor; UpdateHelpText()

    elseif args[1] == "latency" then
        F1_Config.latency = tonumber(args[2]) or F1_Config.latency; F1_Announce("LATENCIA: "..F1_Config.latency, 1, 1, 0)

    elseif args[1] == "edit" and args[2] and args[3] and args[4] then
        local p = args[2]
        if F1_Config[p] then 
            F1_Config[p].rake = tonumber(args[3])
            F1_Config[p].claw = tonumber(args[4])
            UpdateHelpText(); UpdateGearMonitor()
            F1_Announce("EDITADO "..string.upper(p), 0, 1, 0)
        end

    elseif args[1] == "edit" then
        if F1_MsgFrame.bg:IsShown() then
            F1_MsgFrame.bg:Hide(); F1_MsgFrame:EnableMouse(false)
            F1_StatusFrame:EnableMouse(false)
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[F1]: Posiciones fijadas.|r")
        else
            F1_MsgFrame.bg:Show(); F1_MsgFrame:EnableMouse(true); F1_MsgFrame:RegisterForDrag("LeftButton")
            F1_StatusFrame:EnableMouse(true); F1_StatusFrame:RegisterForDrag("LeftButton")
            F1_Announce("MODO EDICIÓN: MUEVE LOS PANELES", 0, 1, 0)
        end

    elseif args[1] == "n" or args[1] == "p1" or args[1] == "p2" or args[1] == "cycle" then
        if args[1] == "cycle" then
            local curr = F1_Config.currentGear or "n"
            F1_Config.currentGear = (curr == "n" and "p1") or (curr == "p1" and "p2") or "n"
        else 
            F1_Config.currentGear = args[1] 
        end
        
        -- Volvemos a activar el mensaje en el System Box
        local gearName = (F1_Config.currentGear == "p1") and "Gear 1" or (F1_Config.currentGear == "p2" and "Gear 2" or "Neutral")
        F1_Announce("MODO: "..gearName, 0, 1, 1)
        
        UpdateHelpText()    -- Actualiza el panel de ayuda
        UpdateGearMonitor() -- Actualiza el visor pequeño
    end
end




-- ==========================================================
-- MOTOR DE ROTACIÓN F1 (OPTIMIZADO: SOLO FEROCIOUS BITE)
-- ==========================================================
function DoFeralRotation(mode)
    if not F1_Config then return end
    local gear = F1_Config.currentGear or "n"
    local hasTF, hasCC, isProwl, tfTime = false, false, false, 0
    local i = 1
    
    -- Escaneo de Buffs del Jugador
    while true do
        local bIdx = GetPlayerBuff(i, "HELPFUL")
        if bIdx == -1 then break end
        local tex = GetPlayerBuffTexture(bIdx)
        if string.find(tex, "TigerFury") or string.find(tex, "JungleTiger") then 
            hasTF = true; tfTime = GetPlayerBuffTimeLeft(bIdx)
        end
        if string.find(tex, "ManaBurn") or string.find(tex, "Clearcasting") then hasCC = true end
        if string.find(tex, "Ambush") or string.find(tex, "Prowl") then isProwl = true end
        i = i + 1
    end
    
    if isProwl then 
        rakePending = false; isImmuneToBleed = false
        CastSpellByName("Ravage") return 
    end

    local energy = UnitMana("player")
    local now = GetTime()
    local limit = F1_Config.latency or 0.5

    -- 1. PRIORIDAD TF (SOLO EN N Y P1)
    if (gear == "n" or gear == "p1") and not isTurboActive then
        if not hasTF then
            if energy < 30 then
                if (now - lastReshiftTime > 1.2) then CastSpellByName("Reshift"); lastReshiftTime = now end
            else CastSpellByName("Tiger's Fury") end
            return
        end
    end

    -- 2. VERIFICACIÓN DE INMUNIDAD POR RAKE
    if rakePending and (now - rakeTimer > limit) then
        isImmuneToBleed = true; rakePending = false
        F1_Announce("TARGET POSIBLE INMUNE", 1, 0.5, 0)
    end

    -- 3. REMATE (SIEMPRE BITE)
    if GetComboPoints() >= 5 then
        CastSpellByName("Ferocious Bite") 
        return 
    end
    
    -- 4. ATAQUE (RAKE/CLAW)
    local spell = "Rake"
    if isImmuneToBleed or IsShiftKeyDown() then
        spell = "Claw"
    else
        local hasB = false; local j = 1
        while true do
            local d = UnitDebuff("target", j)
            if not d then break end
            if string.find(string.lower(d), "rake") or string.find(string.lower(d), "arañazo") or string.find(string.lower(d), "embowel") then hasB = true break end
            j = j + 1
        end
        if hasB then spell = "Claw" 
        elseif (now - rakeTimer < limit) then spell = "Claw" 
        else spell = "Rake" end
    end

    -- 5. CLEARCASTING
    if hasCC then
        if mode == "boss" then CastSpellByName("Shred") else CastSpellByName(spell) end
        return
    end

    -- 6. RESHIFT DINÁMICO
    local prf = isTurboActive and "turbo" or gear
    if prf ~= "n" and lastEnergyError then
        local p = F1_Config[prf]
        local th = (spell == "Claw") and (p.claw - 1) or (p.rake - 1)
        if energy < 11 or energy <= th then
            if (now - lastReshiftTime > 1.2) then
                if not isTurboActive then
                    if (gear == "n" or gear == "p1") then
                        if (not hasTF) or (tfTime <= 4) then CastSpellByName("Reshift"); lastReshiftTime = now end
                    else
                        CastSpellByName("Reshift"); lastReshiftTime = now
                    end
                else
                    CastSpellByName("Reshift"); lastReshiftTime = now
                end
            end
        end
        lastEnergyError = false
    end
    CastSpellByName(spell)
end