local tArgs = { ... }

local connections = {}

local nshAPI = {
	connList = connections
}

nshAPI.getRemoteID = function()
	--check for connected clients with matching threads.
	for cNum, cInfo in pairs(nshAPI.connList) do
		if cInfo.thread == coroutine.running() then
			if cNum == "localShell" then
				--if we are a client running on the server, return the remote server ID.
				if nshAPI.serverNum then
					return nshAPI.serverNum
				else
					return nil
				end
			end
			return cNum
		end
	end
	--client running without local server, return remote server ID.
	if nshAPI.serverNum then return nshAPI.serverNum end
	return nil
end

nshAPI.send = function(msg)
	local id = nshAPI.getRemoteID()
	if id then
		return rednet.send(id, msg)
	end
	return nil
end

nshAPI.receive = function(timeout)
	if type(timeout) == number then timeout = os.startTimer(timeout) end
	while true do
		event = {os.pullEvent()}
		if event[1] == "rednet_message" and event[2] == nshAPI.getRemoteID() then
			return event[3]
		elseif event[1] == "timer" and event[2] == timeout then
			return nil
		end
	end
end

nshAPI.getClientCapabilities = function()
	if nshAPI.clientCapabilities then return nshAPI.clientCapabilities end
	nshAPI.send("SP:;clientCapabilities")
	return nshAPI.receive(1)
end

nshAPI.getRemoteConnections = function()
	local remotes = {}
	for cNum, cInfo in pairs(nshAPI.connList) do
		table.insert(remotes, cNum)
		if cInfo.outbound then
			table.insert(remotes, cInfo.outbound)
		end
	end
	return remotes
end

local packetConversion = {
	query = "SQ",
	response = "SR",
	data = "SP",
	close = "SC",
	fileQuery = "FQ",
	fileSend = "FS",
	fileResponse = "FR",
	fileHeader = "FH",
	fileData = "FD",
	fileEnd = "FE",
	textWrite = "TW",
	textCursorPos = "TC",
	textGetCursorPos = "TG",
	textGetSize = "TD",
	textInfo = "TI",
	textClear = "TE",
	textClearLine = "TL",
	textScroll = "TS",
	textBlink = "TB",
	textColor = "TF",
	textBackground = "TK",
	textIsColor = "TA",
	event = "EV",
	SQ = "query",
	SR = "response",
	SP = "data",
	SC = "close",
	FQ = "fileQuery",
	FS = "fileSend",
	FR = "fileResponse",
	FH = "fileHeader",
	FD = "fileData",
	FE = "fileEnd",
	TW = "textWrite",
	TC = "textCursorPos",
	TG = "textGetCursorPos",
	TD = "textGetSize",
	TI = "textInfo",
	TE = "textClear",
	TL = "textClearLine",
	TS = "textScroll",
	TB = "textBlink",
	TF = "textColor",
	TK = "textBackground",
	TA = "textIsColor",
	EV = "event",
}

local function openModem()
	local modemFound = false
	for _, side in ipairs(rs.getSides()) do
		if peripheral.getType(side) == "modem" then
			if not rednet.isOpen(side) then rednet.open(side) end
			modemFound = true
			break
		end
	end
	return modemFound
end

local function send(id, type, message)
	return rednet.send(id, packetConversion[type]..":;"..message)
end

local function awaitResponse(id, time)
	id = tonumber(id)
	local listenTimeOut = nil
	local messRecv = false
	if time then listenTimeOut = os.startTimer(time) end
	while not messRecv do
		local event, p1, p2 = os.pullEvent()
		if event == "timer" and p1 == listenTimeOut then
			return false
		elseif event == "rednet_message" then
			sender, message = p1, p2
			if id == sender and message then
				if packetConversion[string.sub(message, 1, 2)] then packetType = packetConversion[string.sub(message, 1, 2)] end
				message = string.match(message, ";(.*)")
				messRecv = true
			end
		end
	end
	return packetType, message
end

local function processText(conn, pType, value)
	if not pType then return false end
	if pType == "textWrite" and value then
		term.write(value)
	elseif pType == "textClear" then
		term.clear()
	elseif pType == "textClearLine" then
		term.clearLine()
	elseif pType == "textGetCursorPos" then
		local x, y = term.getCursorPos()
		send(conn, "textInfo", math.floor(x)..","..math.floor(y))
	elseif pType == "textCursorPos" then
		local x, y = string.match(value, "(%d+),(%d+)")
		term.setCursorPos(tonumber(x), tonumber(y))
	elseif pType == "textBlink" then
		if value == "true" then
			term.setCursorBlink(true)
		else
			term.setCursorBlink(false)
		end
	elseif pType == "textGetSize" then
		x, y = term.getSize()
		send(conn, "textInfo", x..","..y)
	elseif pType == "textScroll" and value then
		term.scroll(tonumber(value))
	elseif pType == "textIsColor" then
		send(conn, "textInfo", tostring(term.isColor()))
	elseif pType == "textColor" and value then
		value = tonumber(value)
		if (value == 1 or value == 32768) or term.isColor() then
			term.setTextColor(value)
		end
	elseif pType == "textBackground" and value then
		value = tonumber(value)
		if (value == 1 or value == 32768) or term.isColor() then
			term.setBackgroundColor(value)
		end
	end
	return
end

local function textRedirect (id)
	local textTable = {}
	textTable.id = id
	textTable.write = function(text)
		return send(textTable.id, "textWrite", text)
	end
	textTable.clear = function()
		return send(textTable.id, "textClear", "nil")
	end
	textTable.clearLine = function()
		return send(textTable.id, "textClearLine", "nil")
	end
	textTable.getCursorPos = function()
		send(textTable.id, "textGetCursorPos", "nil")
		local pType, message = awaitResponse(textTable.id, 2)
		if pType and pType == "textInfo" then
			local x, y = string.match(message, "(%d+),(%d+)")
			return tonumber(x), tonumber(y)
		end
	end
	textTable.setCursorPos = function(x, y)
		return send(textTable.id, "textCursorPos", math.floor(x)..","..math.floor(y))
	end
	textTable.setCursorBlink = function(b)
		if b then
			return send(textTable.id, "textBlink", "true")
		else
			return send(textTable.id, "textBlink", "false")
		end
	end
	textTable.getSize = function()
		send(textTable.id, "textGetSize", "nil")
		local pType, message = awaitResponse(textTable.id, 2)
		if pType and pType == "textInfo" then
			local x, y = string.match(message, "(%d+),(%d+)")
			return tonumber(x), tonumber(y)
		end
	end
	textTable.scroll = function(lines)
		return send(textTable.id, "textScroll", lines)
	end
	textTable.isColor = function()
		send(textTable.id, "textIsColor", "nil")
		local pType, message = awaitResponse(textTable.id, 2)
		if pType and pType == "textInfo" then
			if message == "true" then
				return true
			end
		end
		return false
	end
	textTable.isColour = textTable.isColor
	textTable.setTextColor = function(color)
		return send(textTable.id, "textColor", tostring(color))
	end
	textTable.setTextColour = textTable.setTextColor
	textTable.setBackgroundColor = function(color)
		return send(textTable.id, "textBackground", tostring(color))
	end
	textTable.setBackgroundColour = textTable.setBackgroundColor
	return textTable
end

local eventFilter = {
	key = true,
	char = true,
	mouse_click = true,
	mouse_drag = true,
	mouse_scroll = true,
}

local function newSession()
	local path = "/rom/programs/shell"
	if #tArgs >= 2 and shell.resolveProgram(tArgs[2]) then path = shell.resolveProgram(tArgs[2]) end
	local sessionThread = coroutine.create(function() shell.run(path) end)
	return sessionThread
end

if #tArgs >= 1 and tArgs[1] == "host" then
	_G.nsh = nshAPI
	if not openModem() then return end
	local connInfo = {}
	connInfo.target = term.native
	local path = "/rom/programs/shell"
	if #tArgs >= 3 and shell.resolveProgram(tArgs[3]) then path = shell.resolveProgram(tArgs[3]) end
	connInfo.thread = coroutine.create(function() shell.run(path) end)
	connections.localShell = connInfo
	term.clear()
	term.setCursorPos(1,1)
	coroutine.resume(connections.localShell.thread)

	while true do
		event = {os.pullEventRaw()}
		if event[1] == "rednet_message" then
			if packetConversion[string.sub(event[3], 1, 2)] then
				--this is a packet meant for us.
				conn = event[2]
				packetType = packetConversion[string.sub(event[3], 1, 2)]
				message = string.match(event[3], ";(.*)")
				if connections[conn] and connections[conn].status == "open" then
					if packetType == "event" or string.sub(packetType, 1, 4) == "text" then
						local eventTable = {}
						if packetType == "event" then
							eventTable = textutils.unserialize(message)
						else
							--we can pass the packet in raw, since this is not an event packet.
							eventTable = event
						end
						if not connections[conn].filter or eventTable[1] == connections[conn].filter then
							connections[conn].filter = nil
							term.redirect(connections[conn].target)
							passback = {coroutine.resume(connections[conn].thread, unpack(eventTable))}
							if passback[1] and passback[2] then
								connections[conn].filter = passback[2]
							end
							if coroutine.status(connections[conn].thread) == "dead" then
								send(conn, "close", "disconnect")
								table.remove(connections, conn)
							end
							term.restore()
						end
					elseif packetType == "query" then
						--reset connection
						connections[conn].status = "open"
						connections[conn].target = textRedirect(conn)
						connections[conn].thread = newSession()
						send(conn, "response", "OK")
						term.redirect(connections[conn].target)
						coroutine.resume(connections[conn].thread)
						term.restore()
					elseif packetType == "close" then
						table.remove(connections, conn)
						send(conn, "close", "disconnect")
						--close connection
					else
						--we got a packet, have an open connection, but despite it being in the conversion table, don't handle it ourselves. Send it onward.
						if not connections[conn].filter or eventTable[1] == connections[conn].filter then
							connections[conn].filter = nil
							term.redirect(connections[conn].target)
							passback = {coroutine.resume(connections[conn].thread, unpack(event))}
							if passback[2] then
								connections[conn].filter = passback[2]
							end
							if coroutine.status(connections[conn].thread) == "dead" then
								send(conn, "close", "disconnect")
								table.remove(connections, conn)
							end
							term.restore()
						end
					end
				elseif packetType ~= "query" then
					--usually, we would send a disconnect here, but this prevents one from hosting nsh and connecting to other computers.  Pass these to all shells as well.
					for cNum, cInfo in pairs(connections) do
						if not cInfo.filter or event[1] == cInfo.filter then
							cInfo.filter = nil
							term.redirect(cInfo.target)
							passback = {coroutine.resume(cInfo.thread, unpack(event))}
							if passback[2] then
								cInfo.filter = passback[2]
							end
							term.restore()
						end
					end
				else
					--open new connection
					local connInfo = {}
					connInfo.status = "open"
					connInfo.target = textRedirect(conn)
					connInfo.thread = newSession()
					send(conn, "response", "OK")
					connections[conn] = connInfo
					term.redirect(connInfo.target)
					coroutine.resume(connInfo.thread)
					term.restore()
				end
			else
				--rednet message, but not in the correct format, so pass to all shells.
				for cNum, cInfo in pairs(connections) do
					if not cInfo.filter or event[1] == cInfo.filter then
						cInfo.filter = nil
						term.redirect(cInfo.target)
						passback = {coroutine.resume(cInfo.thread, unpack(event))}
						if passback[2] then
							cInfo.filter = passback[2]
						end
						term.restore()
					end
				end
			end
		elseif event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_scroll" or event[1] == "key" or event[1] == "char" then
			--user interaction.
			coroutine.resume(connections.localShell.thread, unpack(event))
			if coroutine.status(connections.localShell.thread) == "dead" then
				for cNum, cInfo in pairs(connections) do
					if cNum ~= "localShell" then
						send(cNum, "close", "disconnect")
					end
				end
				return
			end
		elseif event[1] == "terminate" then
			_G.nsh = nil
			return
		else
			--dispatch all other events to all shells
			for cNum, cInfo in pairs(connections) do
				if not cInfo.filter or event[1] == cInfo.filter then
					cInfo.filter = nil
					term.redirect(cInfo.target)
					passback = {coroutine.resume(cInfo.thread, unpack(event))}
					if passback[2] then
						cInfo.filter = passback[2]
					end
					term.restore()
				end
			end
		end
	end

elseif #tArgs == 1 and nsh and nsh.getRemoteID() then
	print(nsh.getRemoteID())
	--forwarding mode
	local conns = nsh.getRemoteConnections()
	for i = 1, #conns do
		if conns[i] == serverNum then
			print("Cyclic connection refused.")
			return
		end
	end
	local fileTransferState = nil
	local fileData = nil
	local serverNum = tonumber(tArgs[1])
	send(serverNum, "query", "connect")
	local pType, message = awaitResponse(serverNum, 2)
	if pType ~= "response" then
		print("Connection Failed")
		return
	else
		nsh.connList[nsh.getRemoteID()].outbound = serverNum
		term.clear()
		term.setCursorPos(1,1)
	end
	local clientID = nsh.getRemoteID()
	local serverID = tonumber(tArgs[1])
	while true do
		event = {os.pullEvent()}
		if event[1] == "rednet_message" then
			if event[2] == clientID or event[2] == serverID then
				if event[2] == serverID and string.sub(event[3], 1, 2) == "SC" then break end
				rednet.send((event[2] == clientID and serverID or clientID), event[3])
			end
		elseif eventFilter[event[1]] then
			rednet.send(serverID, "EV:;"..textutils.serialize(event))
		end
	end
	nsh.connList[nsh.getRemoteID()].outbound = nil
	term.clear()
	term.setCursorPos(1, 1)
	print("Connection closed by server")

elseif #tArgs == 1 then --either no server running or we are the local shell on the server.
	local serverNum = tonumber(tArgs[1])
	if nsh then
		local conns = nsh.getRemoteConnections()
		for i = 1, #conns do
			if conns[i] == serverNum then
				print("Connection refused.")
				return
			end
		end
	end
	local fileTransferState = nil
	local fileData = nil
	if not openModem() then return end
	send(serverNum, "query", "connect")
	local pType, message = awaitResponse(serverNum, 2)
	if pType ~= "response" then
		print("Connection failed.")
		return
	else
		if nsh then nshAPI = nsh end
		if nshAPI.connList and nshAPI.connList.localShell then nshAPI.connList.localShell.outbound = serverNum end
		nshAPI.serverNum = serverNum
		nshAPI.clientCapabilities = "-fileTransfer-extensions-"
		term.clear()
		term.setCursorPos(1,1)
	end

	while true do
		event = {os.pullEventRaw()}
		if event[1] == "rednet_message" and event[2] == serverNum then
			if packetConversion[string.sub(event[3], 1, 2)] then
				packetType = packetConversion[string.sub(event[3], 1, 2)]
				message = string.match(event[3], ";(.*)")
				if string.sub(packetType, 1, 4) == "text" then
					processText(serverNum, packetType, message)
				elseif packetType == "data" then
					if message == "clientCapabilities" then
						rednet.send(serverNum, nshAPI.clientCapabilities)
					end
				elseif packetType == "fileQuery" then
					--send a file to the server
					if fs.exists(message) then
						send(serverNum, "fileHeader", message)
						local file = io.open(message, "r")
						if file then
							send(serverNum, "fileData", file:read("*a"))
							file:close()
						end
					else
						send(serverNum, "fileHeader", "fileNotFound")
					end
					send(serverNum, "fileEnd", "end")
				elseif packetType == "fileSend" then
					--receive a file from the server, but don't overwrite existing files.
					if not fs.exists(message) then
						fileTransferState = "receive_wait:"..message
						send(serverNum, "fileResponse", "ok")
						fileData = ""
					else
						send(serverNum, "fileResponse", "reject")
					end
				elseif packetType == "fileHeader" then
					if message == "fileNotFound" then
						fileTransferState = nil
					end
				elseif packetType == "fileData" then
					if fileTransferState and string.match(fileTransferState, "(.-):") == "receive_wait" then
						fileData = fileData..message
					end
				elseif packetType == "fileEnd" then
					if fileTransferState and string.match(fileTransferState, "(.-):") == "receive_wait" then
						local file = io.open(string.match(fileTransferState, ":(.*)"), "w")
						if file then
							file:write(fileData)
							file:close()
						end
						fileTransferState = nil
					end
				elseif packetType == "close" then
					if term.isColor() then
						term.setBackgroundColor(colors.black)
						term.setTextColor(colors.white)
					end
					term.clear()
					term.setCursorPos(1, 1)
					print("Connection closed by server.")
					nshAPI.serverNum = nil
					if nshAPI.connList and nshAPI.connList.localShell then nshAPI.connList.localShell.outbound = nil end
					return
				end
			end
		elseif event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_scroll" or event[1] == "key" or event[1] == "char" then
			--pack up event
			send(serverNum, "event", textutils.serialize(event))
		elseif event[1] == "terminate" then
			nshAPI.serverNum = nil
			if nshAPI.localShell then nshAPI.localShell.outbound = nil end
			return
		end
	end
else
	print("Usage: nsh <serverID>")
	print("       nsh host [remote [local]]")
end