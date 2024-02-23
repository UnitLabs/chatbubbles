local surface = surface
local string, utf8 = string, utf8

chatbubbles.API.NormalizeString = function(text)
	local mts = chatbubbles.settings.maxtextsize

	if string.len(text:Trim()) > mts then
		return string.sub(text, 1, mts) .. "..."
	end

	return text
end

if SERVER then
	chatbubbles.API.StartChat = function(ply)
		chatbubbles.ACTIONS.sv[chatbubbles.ACTIONS.STARTCHAT](ply)
	end

	chatbubbles.API.FinishChat = function(ply)
		chatbubbles.ACTIONS.sv[chatbubbles.ACTIONS.ENDCHAT](ply)
	end
	chatbubbles.API.EndChat = chatbubbles.API.FinishChat

	chatbubbles.API.UpdateTyping = function(ply, text)
		chatbubbles.ACTIONS.sv[chatbubbles.ACTIONS.MESSAGE](ply, text)
	end

	chatbubbles.API.Say = function(ply, text)
		text = string.sub(text, 1, 1024)

		net.Start"chatbubbles"
			net.WriteUInt(chatbubbles.ACTIONS.SENDMESSAGE, 8)
			net.WriteEntity(ply)
			net.WriteString(text)
		net.Broadcast()
	end
end