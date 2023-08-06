Utils = require("utils")
JSON = require("json")
Monitor = peripheral.find("monitor")
Users = {}

function SaveUsersList ()
    Utils.WriteFile("BankDB.json", JSON.encode(Users))
end

function LoadUsersList ()
    return JSON.decode(Utils.ReadFile("BankDB.json"))
end

function ShowAllUsers (screen)
    for i, user in ipairs(Users) do
        Utils.WriteToScreen(screen, string.format("%d. %s", i, user["username"]))
    end
end

function UserMenu (userIndex)
    local user, username, funds, choice, index
    for i, item in ipairs(Users) do
        if i == userIndex then
            index = i
            user = item
            break
        end
    end
    username = user["username"]
    funds = user["funds"]
    Utils.WriteToScreen("terminal", string.format("---- [User Details - %s ] ----", username), true)
    Utils.WriteToScreen("terminal", string.format("Available funds: %d$", funds), true)
    Utils.WriteToScreen("terminal", "Actions \n1. Set funds \n2. Change password \n3. Delete account \n4. Back")
    choice = io.read()
    if choice == "1" then
        Utils.WriteToScreen("terminal", string.format("Enter amount of funds (was %d$)", funds))
        choice = tonumber(io.read())
        user["funds"] = choice
        SaveUsersList()
    elseif choice == "2" then
        Utils.WriteToScreen("terminal", "Enter a new password for the account:")
        choice = io.read()
        user["password"] = choice
        SaveUsersList()
    elseif choice == "3" then
        choice = Utils.YesNoDialog(string.format("Are you sure you want to delete account '%s' (y/n)?", username))
        if choice then
            table.remove(Users, index)
        end
    end
end

function Menu (screen)
    local choice
    Utils.ClearScreen(screen)
    Utils.WriteToScreen(screen, "Select a user to manipulate:")
    ShowAllUsers(screen)
    choice = io.read()
    if choice == "exit" then
        return false
    end
    choice = tonumber(choice)
    if type(choice) == "number" and choice >= 1 and choice <= #Users then
        UserMenu(choice)
    end
    return true
end

function Run()
    local run = true
    Users = LoadUsersList()
    while run do
        run = Menu()
    end
end

Run()