

local _SafeCrackingStates = "Setup"
local _onSpot             = false
local _try                = 0
local isMinigame          = false


local function EndMiniGame(safeUnlocked)
    if safeUnlocked then
        PlaySoundFrontend(0, "SAFE_DOOR_OPEN", "SAFE_CRACK_SOUNDSET", true )
    else
        PlaySoundFrontend(0, "SAFE_DOOR_CLOSE", "SAFE_CRACK_SOUNDSET", true )
    end
    isMinigame = false
    SafeCrackingStates = "Setup"
    FreezeEntityPosition(PlayerPedId(),false)
    ClearPedTasks(PlayerPedId())
end

local function ReleaseCurrentPin()
    _safeLockStatus[_currentLockNum] = false
    _currentLockNum = _currentLockNum + 1

    if _requiredDialRotationDirection == "Anticlockwise" then
        _requiredDialRotationDirection = "Clockwise"
    else
        _requiredDialRotationDirection = "Anticlockwise"
    end
    
    PlaySoundFrontend(0, "TUMBLER_PIN_FALL_FINAL", "SAFE_CRACK_SOUNDSET", true )
end

local function GetCurrentSafeDialNumber(currentDialAngle)
    local number = math.floor(100 * (currentDialAngle / 360))
    if number > 0 then number = 100 - number end

    return math.abs(number)
end

local function InitSafeLocks() -- Load the locks
    if not _safeCombination then
        return
    end
    
    local locks = {}
    for i=1, #_safeCombination do
        table.insert(locks, true)
    end

    return locks
end

local function RelockSafe()
    if not _safeCombination then return end
    
    _safeLockStatus = InitSafeLocks()
    _currentLockNum = 1
    _try = 0
    _requiredDialRotationDirection = _initDialRotationDirection
    _onSpot = false

    for i=1, #_safeCombination do
        _safeLockStatus[i] = true
    end
end

local function RotateSafeDial(rotationDirection)
    
    if (rotationDirection == "Anticlockwise" or rotationDirection == "Clockwise") and _requiredDialRotationDirection == rotationDirection then
        local rotationPerNumber = 1
        local multiplier
        if rotationDirection == "Anticlockwise" then
            multiplier = 1
        elseif rotationDirection == "Clockwise" then
            multiplier = -1
        end
        local rotationChange = multiplier * rotationPerNumber
        SafeDialRotation = SafeDialRotation + rotationChange
        PlaySoundFrontend( 0, "TUMBLER_TURN", "SAFE_CRACK_SOUNDSET", true )
    end

    _currentDialRotationDirection = rotationDirection
    _lastDialRotationDirection = rotationDirection
end

local function RunMiniGame()
    if _SafeCrackingStates == "Setup" then
        

        _SafeCrackingStates = "Cracking"
    elseif _SafeCrackingStates == "Cracking" then
        local isDead = GetEntityHealth(PlayerPedId() ) <= 100
        if isDead then
            EndMiniGame(false)
            return false
        end

        if IsControlJustPressed( 0, 33 ) then
            EndMiniGame(false)
            return false
        end

        if IsControlJustPressed( 0, 32 ) then
            if _onSpot then
                ReleaseCurrentPin()
                _onSpot = false
                if _safeLockStatus[_currentLockNum] == nil then
                    EndMiniGame( true, false )
                    return true
                end
            else
                if _try >= 3 then
                    EndMiniGame(false)
                    return false
                else
                    _try = _try + 1
                    PlaySoundFrontend(0, "TUMBLER_RESET", "SAFE_CRACK_SOUNDSET", true )
                end
            end
        end

        if IsControlPressed( 0, 34 ) then
	        RotateSafeDial("Anticlockwise")
	    elseif IsControlPressed( 0, 35 ) then
	        RotateSafeDial("Clockwise")
	    else
	        RotateSafeDial("Idle")
	    end

        local incorrectMovement = _currentLockNum ~= 0 and
            _requiredDialRotationDirection ~= "Idle" and
            _currentDialRotationDirection ~= "Idle" and
            _currentDialRotationDirection ~= _requiredDialRotationDirection

        if  _currentDialRotationDirection ~= "Idle" then
            local currentDialNumber = GetCurrentSafeDialNumber(SafeDialRotation)
            local correctMovement = _requiredDialRotationDirection ~= "Idle" and
                                  (_currentDialRotationDirection == _requiredDialRotationDirection or
                                   _lastDialRotationDirection == _requiredDialRotationDirection)
            
            if correctMovement then
                local pinUnlocked = _safeLockStatus[_currentLockNum] and currentDialNumber == _safeCombination[_currentLockNum]
                if pinUnlocked then
                    PlaySoundFrontend(0, "TUMBLER_PIN_FALL", "SAFE_CRACK_SOUNDSET", false )
                    _onSpot = true
                end
            end
        end
    end
end

local function DrawSprites(drawLocks)
    local textureDict = "MPSafeCracking"
    local _aspectRatio = GetAspectRatio( true )
    
    DrawSprite( textureDict, "Dial_BG", 0.48, 0.3, 0.3, _aspectRatio * 0.3, 0, 255, 255, 255, 255 )
    DrawSprite( textureDict, "Dial", 0.48, 0.3, 0.3 * 0.5, _aspectRatio * 0.3 * 0.5, SafeDialRotation, 255, 255, 255, 255 )

    if not drawLocks then
        return
    end

    local xPos = 0.6
    local yPos = (0.3 * 0.5) + 0.035
    for _,lockActive in pairs(_safeLockStatus) do
        local lockString
        if lockActive then
            lockString = "lock_closed"
        else
            lockString = "lock_open"
        end
            
        DrawSprite( textureDict, lockString, xPos, yPos, 0.025, _aspectRatio * 0.015, 0, 231, 194, 81, 255 )
        yPos = yPos + 0.05
    end
end

local function InitializeSafe(safeCombination)
    _initDialRotationDirection = "Clockwise"
    _safeCombination = safeCombination

    RelockSafe()

    local dialStartNumber = math.random(0, 100)
    SafeDialRotation = 3.6 * dialStartNumber
end

local function createSafe(combination) 
    RequestStreamedTextureDict( "MPSafeCracking", false )
    RequestAmbientAudioBank( "SAFE_CRACK", false )
    local res
    isMinigame = not isMinigame
    if isMinigame then 
        InitializeSafe(combination)
		
        while isMinigame do

            RequestAnimDict("mini@safe_cracking")
		    while not HasAnimDictLoaded("mini@safe_cracking") do Wait(10) end
		    TaskPlayAnim(PlayerPedId(), "mini@safe_cracking", "idle_base", 1.5, 1.5, -1, 16, 0, 0, 0, 0)

            FreezeEntityPosition(PlayerPedId(), true)
            DrawSprites(true)
            res = RunMiniGame()
            
            if res == true then
                return res
            elseif res == false then
                return res
            end
        
            Citizen.Wait(1)
        end
        
    else
        FreezeEntityPosition(PlayerPedId(), false)
    end
end


local storeAlerts = {}
local storeBlips = {}

local inSafe = false
local runningAllert = false

local storesPos = {}

local function alertText(secconds)
	if not runningAllert then
		runningAllert = true
		Citizen.CreateThread(function()
			while secconds > 0 do
				Citizen.Wait(1000)
				secconds = secconds - 1
			end
		end)
		Citizen.CreateThread(function()
			while secconds > 0 or inSafe do
				SetTextFont(2)
				SetTextCentre(1)
				SetTextProportional(0)
				SetTextScale(0.55, 0.55)
				SetTextDropShadow(30, 5, 5, 5, 255)
				SetTextEntry("STRING")
				if secconds == 0 then
					SetTextColour(230, 0, 0, 255)
					AddTextComponentString("POLITIA ESTE ALERTATA")
				else
					SetTextColour(255, 255, 255, 255)
					AddTextComponentString(string.format("POLITIA ESTE ALERTATA IN ~r~%02d ~s~SECUNDE", secconds))
				end
				DrawText(0.5, 0.94)

				Citizen.Wait(1)
			end
			if not inSafe then
				local untilTimer = GetGameTimer() + 3000
				while untilTimer >= GetGameTimer() do
					SetTextFont(2)
					SetTextCentre(1)
					SetTextProportional(0)
					SetTextScale(0.55, 0.55)
					SetTextDropShadow(30, 5, 5, 5, 255)
					SetTextEntry("STRING")
					SetTextColour(230, 0, 0, 255)
					AddTextComponentString("POLITIA ESTE ALERTATA")
					DrawText(0.5, 0.94)

					Citizen.Wait(1)
				end
			end

			runningAllert = false
		end)
	end
end

RegisterNetEvent("startSR")
AddEventHandler("startSR", function(storeId, combination, secconds)
	if type(combination) == "table" and type(storeId) == "number" then
		if not inSafe then

			if Config.requireMask and not (GetPedDrawableVariation(PlayerPedId() , 1) > 0) then 
				TriggerServerEvent("cancelSR", storeId)
				TriggerEvent("chatMessage", "^1Eroare^0: Ai nevoie de o masca pentru a da jaf !")
				return 
			end

				inSafe = true
				Citizen.CreateThread(function()
					alertText(secconds)
					while inSafe do
						SetTextFont(2)
						SetTextCentre(1)
						SetTextProportional(0)
						SetTextScale(0.6, 0.6)
						SetTextColour(255, 255, 255, 255)
						SetTextDropShadow(30, 5, 5, 5, 255)
						SetTextEntry("STRING")
						AddTextComponentString("~b~W~s~ Incearca   ~b~A~s~ Stanga   ~b~D~s~ Dreapta   ~b~S~s~ Opreste")
						DrawText(0.5, 0.9)

						Citizen.Wait(1)
					end
				end)
				local res = createSafe(combination)
				inSafe = false
				TriggerServerEvent("checkSR", storeId, res)
			
		end
	end
end)

local blacklistStores = {}

RegisterNetEvent("blipSR")
AddEventHandler("blipSR", function(storeId, pos,timer)

	storeAlerts[storeId] = AddBlipForCoord(pos[1], pos[2], pos[3])
    SetBlipSprite(storeAlerts[storeId], 161)
    SetBlipScale(storeAlerts[storeId], 0.7)
    SetBlipColour(storeAlerts[storeId], 1)
    PulseBlip(storeAlerts[storeId])
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Jaf")
    EndTextCommandSetBlipName(storeAlerts[storeId])

    SetBlipAsShortRange(storeBlips[storeId], false)
    SetBlipColour(storeBlips[storeId], 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Jaf")
    EndTextCommandSetBlipName(storeBlips[storeId])

    blacklistStores[storeId] = true

    Citizen.CreateThread(function()
		if timer then 
			Citizen.Wait(timer)
			if DoesBlipExist(storeAlerts[storeId]) then
					RemoveBlip(storeAlerts[storeId])
					storeAlerts[storeId] = nil
				    SetBlipAsShortRange(storeBlips[storeId], true)
					SetBlipColour(storeBlips[storeId], 47)
					BeginTextCommandSetBlipName("STRING")
					AddTextComponentString("Jaf Magazin")
					EndTextCommandSetBlipName(storeBlips[storeId])
					blacklistStores[storeId] = nil
			end
		else
			Citizen.Wait(120000)
			if DoesBlipExist(storeAlerts[storeId]) then
				RemoveBlip(storeAlerts[storeId])
				storeAlerts[storeId] = nil
			end
			SetBlipAsShortRange(storeBlips[storeId], true)
			SetBlipColour(storeBlips[storeId], 47)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString("Jaf Magazin")
			EndTextCommandSetBlipName(storeBlips[storeId])
			blacklistStores[storeId] = nil
		end
    end)
end)


local stores = Config.stores

RegisterNetEvent("initblipsSR")
AddEventHandler("initblipsSR", function(storesNum)

	if storesNum == #stores then

		for storeId, pos in pairs(stores) do

			storesPos[storeId] = pos

			storeBlips[storeId] = AddBlipForCoord(pos[1], pos[2], pos[3])
		    SetBlipSprite(storeBlips[storeId], 271)
		    SetBlipAsShortRange(storeBlips[storeId], true)
		    SetBlipScale(storeBlips[storeId], 0.5)
		    SetBlipColour(storeBlips[storeId], 47)

		    BeginTextCommandSetBlipName("STRING")
		    AddTextComponentString("Jaf Magazin")
		    EndTextCommandSetBlipName(storeBlips[storeId])
		end

	else
		print("^1Error^7: StoreRobbery client locations does not match with server-side locations")
	end
end)


Citizen.CreateThread(function()
	local nearStores = {}
	local closeStores = {}
	local ped = PlayerPedId()

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(1)
			if inSafe then
				Citizen.Wait(5000)
			else
				for i, v in pairs(nearStores) do
					if v then
						DrawMarker(1, v[1], v[2], v[3], 0, 0, 0, 0, 0, 0, 0.4, 0.4, 0.5, 255, 154, 24, 130, 0, 0, 2, 0, 0, 0, 0)
						if closeStores[i] then
							SetTextEntry_2("STRING")
							AddTextComponentString("Apasa ~r~E~s~ pentru a jefuii magazinul")
							DrawSubtitleTimed(1, 1)
							if IsControlJustPressed(0, 38) then
								TriggerServerEvent("trySR", i)
							end
						end
					end
				end
			end
		end
	end)

	while true do
		Citizen.Wait(1500)
		nearStores = {}
		closeStores = {}
		if inSafe then
			Citizen.Wait(5000)
		else
			ped = PlayerPedId()
			if not IsPedSittingInAnyVehicle(ped) then 
				local pedCoords = GetEntityCoords(ped)
				for storeId, pos in pairs(storesPos) do
					if not blacklistStores[storeId] then

						local dst = #(pedCoords - vec3(pos[1], pos[2], pos[3]))

						
						if dst < 3 then
							nearStores[storeId] = pos
							if dst < 1 then
								closeStores[storeId] = true
							end
						end
					end
				end
			end
		end
	end

end)