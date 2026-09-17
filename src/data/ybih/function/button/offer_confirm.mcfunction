# ybih:button/offer_confirm —— 给刚放下按钮的玩家一个聊天栏确认入口

scoreboard players set @s ybih.trigger 0
scoreboard players enable @s ybih.trigger
tellraw @s {{TXT_S}}按钮已放下，请选择{{TXT_M}}yellow{{TXT_E}}
tellraw @s [{{BTN_CONFIRM}},{{TXT_S}}  {{TXT_E}},{{BTN_REDO}}]
tellraw @s {{TXT_S}}再放一个按钮会自动收回上一个，等于换位置{{TXT_M}}gray{{TXT_E}}
