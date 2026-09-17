# ybih:game/action_hint —— 物品栏上方的操作提示
# 倒计时由 Boss 栏承担，这里只放「需要玩家动手」的短提示

execute if score #state ybih.config matches 2 if entity @e[tag=ybih_pending] run title @a[tag=ybih_current] actionbar [{{TXT_S}}已放下 · 聊天栏点【确认】生效{{TXT_E}}]
