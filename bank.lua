JSON = require("json")
Utils = require("utils")
Drive = peripheral.find("drive")
Monitor = peripheral.find("monitor")

function SaveUsersList ()
    local data = JSON.encode(Users)
    local file = io.open("BankDB.json", "w")
    io.output(file)
    io.write(data)
    io.close(file)
    io.output(io.stdout)
end

function LoadUsersList ()
    local file, data
    file = io.open("BankDB.json", "r")
    io.input(file)
    data = JSON.decode(io.read())
    io.close(file)
    io.input(io.stdin)
    return data
end

function GetTargetScreen (targetScreen)
    -- 1 = terminal, 2 = monitor, 3 = both
    if targetScreen == nil then
        targetScreen = 1
    end
    local screens = {"terminal", "monitor", "both"}
    if type(targetScreen) == "number" then
        targetScreen = screens[targetScreen]
    end
    return targetScreen
end

function WriteToScreen (targetScreen, text, clear)
    -- targetScreen: terminal, monitor, both
    targetScreen = GetTargetScreen(targetScreen)
    if clear == true then
        ClearScreen(targetScreen)
    end
    if targetScreen == "terminal" or targetScreen == "both" then
        print(text)
    end
    if targetScreen == "monitor" or targetScreen == "both" then
        local lines = Utils.SplitString(text, "\n")
        local x, y = Monitor.getCursorPos()
        for _, line in ipairs(lines) do
            Monitor.write(line)
            y = y + 1
            Monitor.setCursorPos(x, y)
        end
    end
end

function ClearScreen(targetScreen)
    -- targetScreen: terminal, monitor, both
    targetScreen = GetTargetScreen(targetScreen)
    if targetScreen == "terminal" or targetScreen == "both" then
        term.clear()
        term.setCursorPos(1, 1)
    end
    if targetScreen == "monitor" or targetScreen == "both" then
        Monitor.clear()
        Monitor.setCursorPos(1, 1)
    end
end

function YesNoDialog (prompt)
    local input
    WriteToScreen(1, prompt, true)
    input = io.read()
    return string.sub(input, 1, 1) == "y"
end

function WaitForDiskInsert ()
    while not Drive.isDiskPresent() do
        WriteToScreen("both", "Please insert a disk!", true)
        sleep(0.1)
    end
end

function GetAccountFilePath()
    return Drive.getMountPath() .. "/bank/account.txt"
end

function GenerateAccountID()
    local length, chars, id, rand
    length = 16
    chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    id = ""
    for i = 1, length, 1 do
        rand = math.random(1, #chars)
        id = id .. string.sub(chars, rand, rand)
    end
    return id
end

function WriteAccountToDisk(accountID)
    local file = io.open(GetAccountFilePath(), "w")
    io.output(file)
    io.write(accountID)
    io.close(file)
    io.output(io.stdout)
end

function ReadAccountFromDisk ()
    local file, acccountID, username
    file = io.open(GetAccountFilePath(), "r")
    io.input(file)
    acccountID = io.read()
    io.close(file)
    io.input(io.stdin)
    username = Users[acccountID]
    return username
end

function CreateBankAccount()
    local username, accountID
    WriteToScreen(1, "Please choose a username:", true)
    username = io.read()
    accountID = GenerateAccountID()
    Users[accountID] = username -- {username, credits}
    SaveUsersList()
    WriteAccountToDisk(accountID)
    print("Account created successfully!")
    sleep(1)
    return username
end

function AccountCreationDialog ()
    -- This function is called if the player needs to create an account.
    local choice, username
    WriteToScreen("monitor", "Disk setup required. \nPlease use the computer below.", true)
    choice = YesNoDialog("Disk is not registered. \nDo you want to create an account (y/n)?")
    if choice then
        if Drive.isDiskPresent() then
            username = CreateBankAccount()
        else
            print("Disk in not connected!")
            sleep(1)
        end
    else
        Drive.ejectDisk()
    end
    return username
end

function ReadDisk ()
    -- This function reads the username of the connected disk.
    -- If the disk is not associated with the bank, it will suggest the user ti create an account.
    local username
    if not fs.exists(Drive.getMountPath() .. "/bank") then
        fs.makeDir(Drive.getMountPath() .. "/bank")
    end
    if not fs.exists(GetAccountFilePath()) then
        username = AccountCreationDialog()
    else
        username = ReadAccountFromDisk()
    end
    return username
end

function ShowAccountHub (username)
    WriteToScreen("both", string.format("Welcome back, %s \nPress enter to continue!", username), true)
    io.input()
end

function Mainloop ()
    local username
    WaitForDiskInsert()
    username = ReadDisk()
    if username == nil then
        username = AccountCreationDialog()
    end
    if username ~= nil then
        ShowAccountHub(username)
    end
end

function Run()
    io.output(io.stdout)
    io.input(io.stdin)
    Monitor.setTextScale(0.5)
    while true do
        Mainloop()
        sleep(0.1)
    end
end

Users = LoadUsersList()

Run()