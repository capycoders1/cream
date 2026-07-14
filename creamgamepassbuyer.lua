-- ============================================================================
-- 1. CONFIGURATION & CREDITS (Modify these safely!)
-- ============================================================================
_G.Version = "1.0.0"
local OpenSoundId = "rbxassetid://112888594194482"
local ClickSoundId = "rbxassetid://134390474890852"

-- Create global sound emitters safely
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local openSound = Instance.new("Sound")
openSound.SoundId = OpenSoundId
openSound.Volume = 1
openSound.PlayOnRemove = false
openSound.Parent = SoundService

local clickSound = Instance.new("Sound")
clickSound.SoundId = ClickSoundId
clickSound.Volume = 1
clickSound.PlayOnRemove = false
clickSound.Parent = SoundService

local function playSound(soundInstance)
    pcall(function()
        soundInstance:Play()
    end)
end

-- Play startup sound immediately
playSound(openSound)

-- Load UI Library safely
local Mercury = loadstring(game:HttpGet("https://raw.githubusercontent.com/capycoders1/cream/main/creamgamepassbuyer-lib/master/src.lua"))()
local GUI = Mercury:Create{
    Name = "Universal Bypass Suite",
    Size = UDim2.fromOffset(600, 400),
    Theme = Mercury.Themes.Legacy,
    Link = ""
}

-- Edit your credits here! Make sure to keep the commas and quotes.
GUI:Credit{
    Name = "cream",
    Description = "Creator",
    Discord = ""
}

GUI:Credit{
    Name = "capylord",
    Description = "Partner",
    Discord = ""
}

-- ============================================================================
-- 2. BACKEND SIGNAL SPOOFER
-- ============================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local suppressCounter = 0
local selectedAssetId = nil
local selectedSignalType = "Gamepass"

-- Welcome Notification
GUI:Notification{
    Title = "Welcome",
    Text = "welcome " .. player.Name .. " made by cream",
    Duration = 6
}

-- Safe execution trigger wrapped in pcall to prevent executor crashes
local function fireFakeSignal(signalType, id)
    if not id then return end
    suppressCounter = suppressCounter + 1
    pcall(function()
        if signalType == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Gamepass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, id, true)
        elseif signalType == "Bulk" then
            MarketplaceService:SignalPromptBulkPurchaseFinished(player.UserId, id, true)
        elseif signalType == "Purchase" then
            MarketplaceService:SignalPromptPurchaseFinished(player.UserId, id, true)
        end
    end)
    suppressCounter = suppressCounter - 1
end

-- ============================================================================
-- 3. CRASH-PROOF FRAME CLICK DETECTOR (No scanning/hooking)
-- ============================================================================
local clickConnection

local function stopGlobalSounds()
    if clickConnection then
        clickConnection:Disconnect()
        clickConnection = nil
    end
end

task.spawn(function()
    local playerGui = player:WaitForChild("PlayerGui")
    local mercuryGui = playerGui:WaitForChild("Mercury")
    
    mercuryGui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            stopGlobalSounds()
        end
    end)
    
    clickConnection = UserInputService.InputBegan:Connect(function(input)
        if not mercuryGui or not mercuryGui.Parent then 
            stopGlobalSounds()
            return 
        end
        
        -- Play sound only on valid left clicks/taps
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mainFrame = mercuryGui:FindFirstChild("Main", true) or mercuryGui:FindFirstChildOfClass("Frame")
            if mainFrame and mainFrame.Visible then
                local mousePos = UserInputService:GetMouseLocation()
                local inset = GuiService:GetGuiInset()
                
                -- Adjust mouse coordinates for Roblox topbar offset
                local clickX = mousePos.X - inset.X
                local clickY = mousePos.Y - inset.Y
                
                local pos = mainFrame.AbsolutePosition
                local size = mainFrame.AbsoluteSize
                
                -- Strictly boundary check the main window to play sound
                if clickX >= pos.X and clickX <= (pos.X + size.X) and
                   clickY >= pos.Y and clickY <= (pos.Y + size.Y) then
                    playSound(clickSound)
                end
            end
        end
    end)
end)

-- ============================================================================
-- 4. SECURITY VERIFICATION TAB (Initial Page)
-- ============================================================================
local AuthTab = GUI:Tab{
    Name = "Security Verification",
    Icon = "rbxassetid://3173271667"
}

local AccessGranted = false
local BuyerTab

-- Safe UI Instantiation Sequence
local function InitialiseMainSystem()
    if AccessGranted then return end
    AccessGranted = true
    
    -- Icon set to clean, white, universal "$" asset (10723343321)
    BuyerTab = GUI:Tab{
        Name = "Interactive Buyer",
        Icon = "rbxassetid://10723343321"
    }

    BuyerTab:Label{
        Title = "Prompt any in-game gamepass, close the window, then click Purchase."
    }

    local StatusLabel = BuyerTab:Label{
        Title = "ID here automatically"
    }

    BuyerTab:Textbox{
        Name = "Manual ID Override",
        Callback = function(text)
            local idNum = tonumber(text)
            if idNum then
                selectedAssetId = idNum
                StatusLabel:SetText(tostring(selectedAssetId))
            end
        end
    }

    BuyerTab:Button{
        Name = "Purchase",
        Description = "Sends a mock successful purchase execution to the game client.",
        Callback = function()
            if not selectedAssetId then
                GUI:Notification{Title = "Execution Error", Text = "Please click/prompt a gamepass or type an ID first!", Duration = 3}
                return
            end
            fireFakeSignal(selectedSignalType, selectedAssetId)
            GUI:Notification{Title = "Purchased", Text = "Purchase signal simulated successfully!", Duration = 3}
        end
    }

    -- Passive prompt listeners (The ID Reader backend)
    local function hookIncomingSignals(ctxType, incomingId)
        if suppressCounter > 0 then return end
        selectedAssetId = incomingId
        selectedSignalType = ctxType
        
        StatusLabel:SetText(tostring(incomingId))
        
        GUI:Notification{
            Title = "ID Target Captured!",
            Text = "ID: " .. tostring(incomingId) .. " [" .. ctxType .. "]",
            Duration = 3
        }
    end

    MarketplaceService.PromptProductPurchaseFinished:Connect(function(p, id) hookIncomingSignals("Product", id) end)
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, id) hookIncomingSignals("Gamepass", id) end)
    MarketplaceService.PromptBulkPurchaseFinished:Connect(function(uid, id) hookIncomingSignals("Bulk", id) end)
    MarketplaceService.PromptPurchaseFinished:Connect(function(uid, id) hookIncomingSignals("Purchase", id) end)
end

-- ============================================================================
-- 5. VERIFICATION SYSTEM (Single Button Setup)
-- ============================================================================
AuthTab:Button{
    Name = "Unlock System (Created by cream)",
    Description = "Click to instantly open the buyer panel.",
    Callback = function()
        InitialiseMainSystem()
        
        -- Safely drop verification layout
        pcall(function()
            AuthTab:Destroy()
        end)
        
        GUI:Notification{
            Title = "Unlocked",
            Text = "Verification closed. Buyer tab unlocked!",
            Duration = 3
        }
    end
}
