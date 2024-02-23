-- Zvbhrf

chatbubbles = chatbubbles or {}
chatbubbles.settings = chatbubbles.settings or {
	colors = {
		outline = Color(200, 200, 200),
		background = Color(255, 255, 255),
		text = Color(0, 0, 0)
	},
	drawsize = 0.045,
	maxtextsize = 512,
	maxdrawdistance = 1024*4,
	maxdraws = 20,
	outline_width = 4,
	text = { 
		space = 20,
		w = 20,
		h = 20
	}
}

chatbubbles.ACTIONS = chatbubbles.ACTIONS or {
	STARTCHAT = 1,
	ENDCHAT = 2,
	MESSAGE = 3, -- Bubble update on ChatTextChange
	SENDMESSAGE = 4, -- Bubble
}

chatbubbles.API = chatbubbles.API or {}

-- INCLUDES

local function includeCL(file)
	file = "chatbubbles/" .. file

	if SERVER then
		AddCSLuaFile(file)
	else
		include(file)
	end
end

local function includeSV(file)
	if SERVER then
		file = "chatbubbles/" .. file

		include(file)
	end
end

local function includeSH(file)
	includeSV(file)
	includeCL(file)
end

-- INITIALIZE --

local function init()
	hook.Remove("Initialize", "chatbubbles")

	includeSH"sh_functions.lua"
	
	includeSV"sv_init.lua"

	includeCL"cl_functions.lua"
	includeCL"cl_render.lua"
	includeCL"cl_init.lua"

	print "CHATBUBBLES: Loaded!"
end

hook.Add("Initialize", "chatbubbles", init)

concommand.Add("chatbubbles_reload", init)