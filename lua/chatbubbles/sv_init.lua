util.AddNetworkString"chatbubbles"

local A_STARTCHAT = chatbubbles.ACTIONS.STARTCHAT
local A_ENDCHAT = chatbubbles.ACTIONS.ENDCHAT
local A_MESSAGE = chatbubbles.ACTIONS.MESSAGE
local A_SENDMESSAGE = chatbubbles.ACTIONS.SENDMESSAGE

local ANTISPAM = {}

chatbubbles.ACTIONS.sv = {
	[A_STARTCHAT] = function(ply)
		if ANTISPAM[ply] then return end
		ANTISPAM[ply] = RealTime()

		local can = hook.Run("ChatBubbles_CanCreateTypingBubble", ply)

		if can == nil or can then
			net.Start"chatbubbles"
				net.WriteUInt(A_STARTCHAT, 8)
				net.WriteEntity(ply)
			net.Broadcast()
		end
	end,
	[A_ENDCHAT] = function(ply)
		if not ANTISPAM[ply] then return end
		ANTISPAM[ply] = nil

		local can = hook.Run("ChatBubbles_CanDeleteTypingBubble", ply)

		if can == nil or can then
			net.Start"chatbubbles"
				net.WriteUInt(A_ENDCHAT, 8)
				net.WriteEntity(ply)
			net.Broadcast()
		end
	end,
	[A_MESSAGE] = function(ply, text)
		local text = text or net.ReadString() -- Always read the string

		local as = ANTISPAM[ply]
		if not as then return end

		if as <= RealTime() then
			ANTISPAM[ply] = RealTime() + 0.1 -- Stop huge network spam

			text = text:sub(1, chatbubbles.settings.maxtextsize)

			local canupdate, newtext = hook.Run("ChatBubbles_CanUpdateBubble", ply, text)
			--canupdate = (canupdate and true or false)

			if canupdate == nil or canupdate then
				net.Start"chatbubbles"
					net.WriteUInt(A_MESSAGE, 8)
					net.WriteEntity(ply)
					net.WriteString(newtext or text)
				net.Broadcast()
			end
		end
	end,
}

net.Receive("chatbubbles", function(len, ply)
	local t = net.ReadUInt(8)
	local a = chatbubbles.ACTIONS.sv[t]

	if a then
		a(ply)
	end
end)

-- CHAT HOOKING

-- Why not OnPlayerChat on client side? -> Sometimes it dont work, because somewhere someone return "true" in it
-- Also why don't I add some hooks like ChatBubbles_OnMessage, ChatBubbles_TextChanged etc. ?
hook.Add("PlayerSay", "chatbubbles", function(ply, text)
	local cancreate, newtext = hook.Run("ChatBubbles_CanCreateBubble", ply, text)
	--cancreate = (cancreate and true or false)

	if cancreate == nil or cancreate then
		--text = utf8.sub(newtext or text, 1, 2048) -- English, Russian and other utf8 symbols support

		text = string.sub(newtext or text, 1, 2048) -- utf8 sucks

		net.Start"chatbubbles"
			net.WriteUInt(A_SENDMESSAGE, 8)
			net.WriteEntity(ply)
			net.WriteString(text)
		net.Broadcast()
	end
end)

-- uuuh fix?
--[[
hook.Add("ChatBubbles_CanCreateTypingBubble", "chatbubbles", function()
	return true
end)

hook.Add("ChatBubbles_CanDeleteTypingBubble", "chatbubbles", function()
	return true
end)

hook.Add("ChatBubbles_CanUpdateBubble", "chatbubbles", function()
	return true
end)

hook.Add("ChatBubbles_CanCreateBubble", "chatbubbles", function()
	return true
end)
]]

hook.Add("ChatBubbles_CanUpdateBubble", "123", print)