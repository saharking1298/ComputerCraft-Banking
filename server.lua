Utils = require("utils")
JSON = require("json")
Users = {}

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

function HostBankProtocol()
    peripheral.find("modem", rednet.open)
    rednet.host("bank", "official-bank")
end

function BankAccountExists (username)
    for _, account in ipairs(Users) do
        if account["username"] == username then
            return true
        end
    end
    return false
end

function FindAccount (identifier, value)
    if identifier == "username" or identifier == "id" then
        for _, account in ipairs(Users) do
            if account[identifier] == value then
                return account
            end
        end
    end
end

function RegisterBankAccount (username, password)
    local startingFunds = 100
    local accountData
    if FindAccount("username", username) == nil then
        accountData = {
            ["id"] = Utils.GenerateToken(16),
            ["username"] = username,
            ["password"] = password,
            ["funds"] = startingFunds
        }
        table.insert(Users, accountData)
    end
    SaveUsersList()
    return accountData
end

function MessageHandler(id, message)
    -- Debugging message information
    print(("Computer %d sent a message:"):format(id))
    print(Utils.ToString(message))

    local username, password, account
    if type(message) == "table" then
        if message["action"] == "register" then
            if message["username"] and message["password"] then
                local username = message["username"] 
                local password = message["password"]
                local account = RegisterBankAccount(username, password)
                return {
                    ["success"] = account ~= nil,
                    ["account"] = account,
                    ["message"] = "User already exists"
                }
            else
                return {
                    ["success"] = false,
                    ["account"] = nil
                }
            end
        end
        if message["action"] == "login" then
            if message["username"] and message["password"] then
                username = message["username"] 
                password = message["password"]
                account = FindAccount("username", username)
                if account and account["password"] ~= password then
                    account = nil
                end
            elseif message["accountID"] then
                account = FindAccount("id", message["accountID"])
            else
                return {
                    ["success"] = false,
                    ["account"] = nil,
                    ["message"] = "Invalid server request"
                }
            end
            if account == nil then
                return {
                    ["success"] = false,
                    ["account"] = nil,
                    ["message"] = "Credentials don't match"
                }
            else
                return {
                    ["success"] = true,
                    ["account"] = account,
                }
            end
        end
    end
end

function Run ()
    local id, message, response
    Users = LoadUsersList()
    HostBankProtocol()
    Utils.WriteToScreen("terminal", "Waiting for connections!")
    while true do
        id, message = rednet.receive()
        response = MessageHandler(id, message)
        if response then
            rednet.send(id, response)
        end
    end
end

Run()