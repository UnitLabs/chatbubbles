local draw, surface, cam, render = draw, surface, cam, render
local math, string = math, string
local table = table

local FrameTime, RealTime = FrameTime, RealTime

local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetAlphaMultiplier = surface.SetAlphaMultiplier
local render_PushRenderTarget = render.PushRenderTarget
local render_PopRenderTarget = render.PopRenderTarget
local render_PushFilterMag = render.PushFilterMag
local render_PopFilterMag = render.PopFilterMag
local render_Clear = render.Clear
local math_sin = math.sin
local math_min = math.min
local math_max = math.max
local math_Clamp = math.Clamp
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort

surface.CreateFont("chatbubbles", {
	font = "Roboto",
	size = 40,
	weight = 450
})

chatbubbles.API.IsRendering = false
chatbubbles.API.ActiveBubbles = {
	Floating = {},
	Typing = {}
}

-- FUNCTIONS --

local dpos, dang = Vector(), Angle()
local vec_pos_up = Vector(0, 0, 85)
local function getPerfectBubblePosition(ply)
	if not IsValid(ply) then return dpos, dang end

	local ang = ply:EyeAngles()
	ang.p = math_Clamp(ang.p, -25, 25)
	
	local pos = ply:GetAttachment(ply:LookupAttachment "eyes")
	if not pos then return dpos, dang end
	pos = pos.Pos
	
	pos = pos + ang:Up() * 11
	pos = pos + ang:Right() * 2
	
	--[[
	pos = pos + ang:Forward() * 4
	pos = pos - ang:Right() * 12
	pos = pos + ang:Up() * 5
	]]

	--[[ -- buggy
	local pos = ply:GetPos() + vec_pos_up

	pos = pos + ang:Forward() * 12
	pos = pos - ang:Up() * 4
	]]

	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	
	return pos, ang
end

local function drawBubbleBackground(x, y, w, h, color, out, width)
	surface_SetDrawColor(out)
	surface_DrawRect(x, y, w, h)

	surface_SetDrawColor(color)
	surface_DrawRect(x + width, y + width, w - width * 2, h - width * 2)
end

local function calculateWrap(text, size)
	local maxsize = 32
	local wrap = chatbubbles.API.WordWrap(text, 512)
	
	for i, v in next, wrap do
		local size = chatbubbles.API.GetTextSize(v)
		
		if maxsize < size then
			maxsize = size
		end
	end
	maxsize = maxsize + chatbubbles.settings.text.space
	return wrap, maxsize
end

-- BUBBLES RENDER --

chatbubbles.API.RenderBubbles = function(d, s)
	if s then return end

	-- If there's no active typing or default bubbles, stop drawing
	if not chatbubbles.API.CheckRender() then return end

	local ft = FrameTime()
	local rt = RealTime()
	
	local drawsize = chatbubbles.settings.drawsize
	local space = chatbubbles.settings.text.space
	local tw, th = chatbubbles.settings.text.w, chatbubbles.settings.text.h
	local outw = chatbubbles.settings.outline_width

	local c_out, c_bg, c_t = chatbubbles.settings.colors.outline, chatbubbles.settings.colors.background, chatbubbles.settings.colors.text
	
	local TYPING, FLOATING = chatbubbles.API.ActiveBubbles.Typing, chatbubbles.API.ActiveBubbles.Floating
	-- TODO: Maybe merge tables in one?
	
	-- Sort (to draw correctly)
	
	local ep = EyePos()
	table_sort(chatbubbles.API.ActiveBubbles.Floating, function(a, b) 
		return a.pos:Distance(ep) > b.pos:Distance(ep)
	end)
	
	-- DRAW Floating BUBBLES
	for i, t in next, FLOATING do
		if i > 20 then continue end

		if t.anim == "appear" then
			if t.alpha < 1 then
				t.alpha = math_min(1, t.alpha + ft * 2)
			else
				t.anim = "idle"
			end
		elseif t.anim == "disappear" then
			t.alpha = t.alpha - ft * 1.2

			--t.mat:SetFloat("$alpha", t.alpha)

			if t.alpha <= 0 then
				table_remove(FLOATING, i)
			end
		elseif t.anim == "idle" then
			local gone = t.lifetime - rt

			if gone <= 0 then
				t.anim = "disappear"
			end
		end

		--t.pos = t.pos + t.ang:Up() * math_sin(rt) / 20
		t.pos = t.pos + (t.ang:Right() * (math_sin(rt))) / 160

		local text = t.text
		local textsize = (th * (#text > 0 and #text or 1))
		--t.pos.z = t.pos.z - textsize

		surface_SetAlphaMultiplier(t.alpha)
		cam_Start3D2D(t.pos, t.ang, drawsize)
			render_PushFilterMag(1)
				drawBubbleBackground(0, 0, t.w + space, textsize + space, c_bg, c_out, outw)
				for i, t in next, text do
					draw_SimpleText(t, "chatbubbles", space, (space / 2) + (th * i) - th, c_t, 0, 0)
				end
			render_PopFilterMag()
			
			--[[surface_SetDrawColor(255, 255, 255)
			surface_SetMaterial(t.mat)

			render_PushFilterMag(1)
				surface_DrawTexturedRect(0, 0, t.w + 2, t.h + space + 2)
			render_PopFilterMag()]]
		cam_End3D2D()
	end
	surface_SetAlphaMultiplier(1)

	-- DRAW Typing BUBBLES
	for ply, t in next, TYPING do
		if t.anim == "appear" then
			if t.alpha < 1 then
				t.alpha = math_min(1, t.alpha + ft * 2)
			else
				t.anim = "idle"
			end
		elseif t.anim == "disappear" then
			t.alpha = t.alpha - ft * 1.2

			if t.alpha <= 0 then
				TYPING[ply] = nil
			end
		elseif t.anim == "idle" then
			if not IsValid(ply) then
				t.anim = "disappear"
			end
		end
	
		if IsValid(ply) then
			t.pos, t.ang = getPerfectBubblePosition(ply)
		end

		--t.pos = t.pos + t.ang:Up() * math_sin(rt) / 20
		t.pos = t.pos + (t.ang:Right() * (math_sin(rt))) / 160

		local text = t.text
		local textsize = (th * (#text > 0 and #text or 1))
		
		surface_SetAlphaMultiplier(t.alpha)
		cam_Start3D2D(t.pos, t.ang, drawsize)
			render_PushFilterMag(1) -- "pixel" effect
				drawBubbleBackground(0, 0, t.size + space, textsize + space, c_bg, c_out, outw)
				for i, t in next, text do
					draw_SimpleText(t, "chatbubbles", space, (space / 2) + (th * i) - th, c_t, 0, 0)
				end
			render_PopFilterMag()
		cam_End3D2D()
	end
	surface_SetAlphaMultiplier(1)
end

chatbubbles.API.StartRender = function()
	if not chatbubbles.API.IsRendering then
		chatbubbles.API.IsRendering = true

		hook.Add("PostDrawTranslucentRenderables", "chatbubbles", chatbubbles.API.RenderBubbles)
	end
end

chatbubbles.API.CheckRender = function()
	if chatbubbles.API.ActiveBubblesCount() <= 0 then
		chatbubbles.API.DestroyRender()

		return false
	end

	return true
end

chatbubbles.API.DestroyRender = function()
	chatbubbles.API.IsRendering = false

	hook.Remove("PostDrawTranslucentRenderables", "chatbubbles")
end

-- TYPING BUBBLES --

chatbubbles.API.StartTyping = function(ply)
	local d = chatbubbles.API.ActiveBubbles.Typing[ply]
	local pos, ang = getPerfectBubblePosition(ply)
	
	local space = chatbubbles.settings.text.h
	
	for i, v in next, chatbubbles.API.ActiveBubbles.Floating do
		if pos:Distance(v.pos) < 16 then
			pos = pos - ang:Right() * 4
		end
	end
	
	if d then
		d.pos = pos
		d.ang = ang
		d.anim = "appear"
	else
		if not chatbubbles.API.IsTooFar(pos) then
			chatbubbles.API.ActiveBubbles.Typing[ply] = {
				text = {},
				size = 20,
				pos = pos,
				ang = ang,
				anim = "appear",
				alpha = 0,
			}
		end
	end
end

chatbubbles.API.EndTyping = function(ply)
	local d = chatbubbles.API.ActiveBubbles.Typing[ply]

	if d then
		d.anim = "disappear"
	end
end

chatbubbles.API.UpdateTyping = function(ply, text)
	local d = chatbubbles.API.ActiveBubbles.Typing[ply]
	
	if d then
		local wrap, size = calculateWrap(text, 512)

		d.text = wrap 
		d.size = size
	end
end

-- FLOATING BUBBLES --

local function createRT(name, w, h)
	local RT = GetRenderTarget(name, w, h)
	local MAT = CreateMaterial(name, "UnlitGeneric", {
		["$basetexture"] = RT:GetName(),
		["$translucent"] = 1,
		--["$vertexcolor"] = 1
	})

	return RT, MAT
end

chatbubbles.API.CreateBubble = function(ply, text)
	local typedata = chatbubbles.API.ActiveBubbles.Typing[ply]

	if not typedata then return end

	local pos, ang = typedata.pos, typedata.ang

	if typedata then -- remove Typing bubble after player send his message
		chatbubbles.API.ActiveBubbles.Typing[ply] = nil
	end

	local h = chatbubbles.settings.text.h
	local c_out, c_bg, c_t = chatbubbles.settings.colors.outline, chatbubbles.settings.colors.background, chatbubbles.settings.colors.text
	local outw = chatbubbles.settings.outline_width
	local space = chatbubbles.settings.text.space
	
	local wrap, size = calculateWrap(text, 512)

	--[[ -- This thing won't paint the back of the bubble, so i decided to replace material to paint
	local name = ("chatbubble:" .. ply:UserID() .. RealTime())

	--    owo
	local ow, oh = size + outw, h + space + outw
	local RT, MAT = createRT(name, ow, oh) -- Maybe there is another may to draw the back side of the material
	--local RT_B, MAT_B = createRT(name .. ":b", ow, oh) -- back side

	render_PushRenderTarget(RT)
		cam_Start2D()
			render_Clear(0, 0, 0, 0)

			drawBubbleBackground(0, 0, size, h + space, c_bg, c_out, outw)
			draw_SimpleText(text, "chatbubbles", (space / 2), (space / 2), c_t, 0, 0)
		cam_End2D()
	render_PopRenderTarget()

	table_insert(chatbubbles.API.ActiveBubbles.Floating, {
		w = size, h = h,
		mat = MAT,
		pos = pos, ang = ang,
		lifetime = RealTime() + 10,
		anim = "idle", -- set to "appear" to play appear animation, and set alpha to 1
		alpha = 1
	})
	]]

	table_insert(chatbubbles.API.ActiveBubbles.Floating, {
		id = #chatbubbles.API.ActiveBubbles.Floating + 1,
		w = size, h = h,
		text = wrap, -- mat = mat,
		pos = pos, ang = ang,
		lifetime = RealTime() + math_min(25, utf8.len(text:Trim()) / 2),
		anim = "idle", -- set to "appear" to play appear animation, and set alpha to 1
		alpha = 1,
		owner = ply
	})
end

hook.Remove("PostDrawTranslucentRenderables", "chatbubbles")