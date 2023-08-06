Utils = require("utils")
Drive = peripheral.find("drive")
Monitor = peripheral.find("monitor")
HostID = -1

function ConnectToBank()
    local hostID, text, choice
    peripheral.find("modem", rednet.open)
    hostID = rednet.lookup("bank", "official-bank")
    if hostID ~= nil then
        text = string.format("Computer #%s is hosting a bank protocol. \nDo you want to proceed?", hostID)
        choice = Utils.YesNoDialog(text)
        if choice == true then
            HostID = hostID
        end
    end
end

function GetAccountFilePath()
    return Drive.getMountPath() .. "/bank/account.txt"
end

function WaitForDiskInsert ()
    while not Drive.isDiskPresent() do
        Utils.WriteToScreen("both", "Please insert a disk!", true)
        sleep(0.1)
    end
end

function WriteAccountToDisk(accountID)
    local file = io.open(GetAccountFilePath(), "w")
    io.output(file)
    io.write(accountID)
    io.close(file)
    io.output(io.stdout)
end

function BankAccountAuth(mode)
    local labels = {
        ["login"] = "Logged into account successfully!",
        ["register"] = "Account created successfully!"
    }
    local response, username, password, success, user
    if not (mode == "login" or mode == "register") then
        error("Invalid account auth mode")
    end
    Utils.WriteToScreen("terminal", "Please choose a username:", true)
    username = io.read()
    Utils.WriteToScreen("terminal", "Please choose a password:")
    password = io.read()
    rednet.send(HostID, {
        ["action"] = mode,
        ["username"] = username,
        ["password"] = password
    })
    response = Utils.getRednetMessage(HostID)
    success = response["success"]
    if not success then
        Utils.WriteToScreen("terminal", response["message"])
        sleep(2)
    else
        user = response["account"]
        Drive.setDiskLabel(username)
        WriteAccountToDisk(user["id"])
        Utils.WriteToScreen("terminal", labels[mode])
        sleep(1)
    end
    return user
end

function AccountLoginDialog ()
    -- This function is called if the player needs to create an account.
    local choice, user
    while user == nil do
        Utils.WriteToScreen("monitor", "Disk setup required. \nPlease use the computer below.", true)
        Utils.WriteToScreen("terminal", "Disk is not registered. \nWhat do you want to do now?", true)
        Utils.WriteToScreen("terminal", "1. Log into an existing account \n2. Create a new account \n3. Eject drive")
        choice = string.sub(io.read(), 1, 1)
    
        if not Drive.isDiskPresent() and (choice == "1" or choice == "2") then
            Utils.WriteToScreen("terminal", "Disk in not connected!")
            sleep(1)
            break
        elseif choice == "1" then
            user = BankAccountAuth("login")
        elseif choice == "2" then
            user = BankAccountAuth("register")
        else
            Drive.ejectDisk()
            break
        end
    end
    return user
end

function ReadDisk ()
    -- This function reads the accountID written on the connected disk.
    -- It will create all required files if they don't exist
    local accountID
    if not fs.exists(Drive.getMountPath() .. "/bank") then
        fs.makeDir(Drive.getMountPath() .. "/bank")
    end
    if not fs.exists(GetAccountFilePath()) then
        io.open(GetAccountFilePath(), "w")
        io.close()
    else
        accountID = Utils.ReadFile(GetAccountFilePath())
    end
    return accountID
end

function ShowAccountHub (user)
    local text = string.format("Welcome back, %s \nAccount balance: %d$", user["username"], user["funds"])
    Utils.WriteToScreen("both", text, true)
    io.input()
end

function Mainloop ()
    local accountID, user, response
    WaitForDiskInsert()
    accountID = ReadDisk()
    if accountID == nil then
        user = AccountLoginDialog()
    else
        rednet.send(HostID, {
            ["action"] = "login",
            ["accountID"] = accountID
        })
        response = Utils.getRednetMessage(HostID)
        if response["success"] == true then
            user = response["account"]
        else
            user = AccountLoginDialog()
        end
    end
    if user ~= nil then
        ShowAccountHub(user)
    end
end

function Run ()
    io.output(io.stdout)
    io.input(io.stdin)
    Monitor.setTextScale(0.5)
    ConnectToBank()
    if HostID == -1 then
        Utils.WriteToScreen("terminal", "Bank server not found, closing!")
    else
        while true do
            Mainloop()
            sleep(0.1)
        end
    end
end

Run()
