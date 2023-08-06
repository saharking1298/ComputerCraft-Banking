local utils = { _version = "1.0.0" }

function utils.SplitString (text, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(text, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function utils.ToString (o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. utils.ToString(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

function utils.ReadFile(filePath)
	local file, content
	file = io.open(filePath, "r")
	io.input(file)
	content = io.read()
	io.close(file)
	io.input(io.stdin)
	return content
end

function utils.WriteFile(filePath, content)
	local file
	file = io.open(filePath, "w")
	io.output(file)
	io.write(content)
	io.close(file)
	io.output(io.stdout)
	return content
end

function utils.GenerateToken(tokenLen)
    local chars, id, rand
    chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    id = ""
    for i = 1, tokenLen, 1 do
        rand = math.random(1, #chars)
        id = id .. string.sub(chars, rand, rand)
    end
    return id
end

function utils.getRednetMessage(computerID)
	local id, message
	repeat
		id, message = rednet.receive()
	until id == computerID
	return message
end

function utils.GetTargetScreen (targetScreen)
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
    
function utils.WriteToScreen (targetScreen, text, clear)
	-- targetScreen: terminal, monitor, both
	targetScreen = utils.GetTargetScreen(targetScreen)
	if clear == true then
			utils.ClearScreen(targetScreen)
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

function utils.ClearScreen(targetScreen)
	-- targetScreen: terminal, monitor, both
	targetScreen = utils.GetTargetScreen(targetScreen)
	if targetScreen == "terminal" or targetScreen == "both" then
		term.clear()
		term.setCursorPos(1, 1)
	end
	if targetScreen == "monitor" or targetScreen == "both" then
		Monitor.clear()
		Monitor.setCursorPos(1, 1)
	end
end

function utils.YesNoDialog (prompt)
	local input
	utils.WriteToScreen("terminal", prompt, true)
	input = io.read()
	return string.sub(input, 1, 1) == "y"
end

return utils
