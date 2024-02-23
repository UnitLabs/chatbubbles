local surface = surface
local string, utf8 = string, utf8

local A_STARTCHAT = chatbubbles.ACTIONS.STARTCHAT
local A_ENDCHAT = chatbubbles.ACTIONS.ENDCHAT
local A_MESSAGE = chatbubbles.ACTIONS.MESSAGE
local A_SENDMESSAGE = chatbubbles.ACTIONS.SENDMESSAGE

-- ACTIONS --

chatbubbles.ACTIONS.cl = {
	[A_STARTCHAT] = function(ply)
		local can = hook.Run("ChatBubbles_CanCreateTypingBubble", ply)

		if can == nil or can then
			chatbubbles.API.StartRender() -- These functions are in cl_render.lua
			chatbubbles.API.StartTyping(ply)
		end

		hook.Run("ChatBubbles_StartChat", ply)
	end,
	[A_ENDCHAT] = function(ply)
		local can = hook.Run("ChatBubbles_CanDeleteTypingBubble", ply)

		if can == nil or can then
			chatbubbles.API.EndTyping(ply)
			chatbubbles.API.CheckRender()
		end

		hook.Run("ChatBubbles_FinishChat", ply)
	end,
	[A_MESSAGE] = function(ply)
		local text = net.ReadString()

		text = chatbubbles.API.NormalizeString(text)

		local canupdate, newtext = hook.Run("ChatBubbles_CanUpdateBubble", ply, text)
		--canupdate = (not canupdate and true or false)

		if canupdate == nil or canupdate then
			chatbubbles.API.UpdateTyping(ply, newtext or text)
		end

		hook.Run("ChatBubbles_TextChanged", ply, text)
	end,
	[A_SENDMESSAGE] = function(ply)
		local text = net.ReadString()

		local cancreate, newtext = hook.Run("ChatBubbles_CanCreateBubble", ply, text)
		--cancreate = (not cancreate and true or false)

		if cancreate == nil or cancreate then
			chatbubbles.API.CreateBubble(
				ply,
				newtext or chatbubbles.API.NormalizeString(text)
			)
		end

		hook.Run("ChatBubbles_OnMessage", ply, text)
	end,
}

net.Receive("chatbubbles", function()
	local t = net.ReadUInt(8)
	local ply = net.ReadEntity()
	local a = chatbubbles.ACTIONS.cl[t]

	if a then
		a(ply)
	end
end)

-- API FUNCTIONS --

chatbubbles.API.GetTextSize = function(text)
	surface.SetFont"chatbubbles"
	return surface.GetTextSize(text)
end

local table_Count = table.Count
chatbubbles.API.ActiveBubblesCount = function()
	return (table_Count(chatbubbles.API.ActiveBubbles.Floating) + table_Count(chatbubbles.API.ActiveBubbles.Typing))
end

chatbubbles.API.IsTooFar = function(dpos)
	local lp = LocalPlayer() -- sometimes this function is called when player is initializing
	if not IsValid(lp) then return true end

	local pos = lp:GetPos()

	local d = pos:Distance(dpos)
	if d >= chatbubbles.settings.maxdrawdistance then return true end

	return false
end

-- thx to xzlto

local chars = {}
chars[','] = true
chars[' '] = true

local sub = utf8.sub
local len = utf8.len

chatbubbles.API.WordWrap = function(text,size)

    local count = len(text)
    local result = {}
    local process_string  = ''

	surface.SetFont"Default"
    for i = 1 , count do
        local char = sub(text,i,i)
        process_string = process_string .. char

		local x , y = surface.GetTextSize( process_string )
        if x >= size and chars[char] or char == '\n' then
            table.insert(result,process_string)
            process_string = ''
        end
    end
    table.insert(result,process_string)
    process_string = nil
    count = nil
    return result
end

-- CHAT HOOKS --

chatbubbles.API.StartChat = function()
	net.Start"chatbubbles"
		net.WriteUInt(A_STARTCHAT, 8)
	net.SendToServer()
end

chatbubbles.API.FinishChat = function()
	net.Start"chatbubbles"
		net.WriteUInt(A_ENDCHAT, 8)
	net.SendToServer()
end

chatbubbles.API.ChatTextChanged = function(text)
	text = chatbubbles.API.NormalizeString(text)

	timer.Create("chatbubbles:send_message", 0.1, 1, function()
		net.Start"chatbubbles"
			net.WriteUInt(A_MESSAGE, 8)
			net.WriteString(text)
		net.SendToServer()
	end)
end
