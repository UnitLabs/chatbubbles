hook.Add("StartChat", "chatbubbles", chatbubbles.API.StartChat)
hook.Add("FinishChat", "chatbubbles", chatbubbles.API.FinishChat)
hook.Add("ChatTextChanged", "chatbubbles", chatbubbles.API.ChatTextChanged)

local w, h = chatbubbles.API.GetTextSize"W"
chatbubbles.settings.text.w = w
chatbubbles.settings.text.h = h
