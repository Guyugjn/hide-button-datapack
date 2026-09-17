# ybih:button/collect —— 按到别人的按钮：按场上剩余按钮数给分、通知物主、移除按钮
# 余量分：4 人局第 1 个被按下的按钮价值 4 分，最后一个是 1 分，所以要在 consume 之前取值

scoreboard players operation #gained ybih.config = #button_count ybih.config
scoreboard players operation @s ybih.score += #button_count ybih.config
scoreboard players add @s ybih.finds 1
execute if score @s ybih.finds matches 1 run scoreboard players operation @s ybih.t_first = #tick ybih.config
playsound minecraft:entity.player.levelup player @a ~ ~ ~ 1 1.5
tellraw @s [{{TXT_S}}+{{TXT_E}},{{SCORE_GAINED}},{{TXT_S}} 分{{TXT_M}}green{{TXT_E}}]
function ybih:button/notify_owner
function ybih:button/consume
execute if score #button_count ybih.config matches ..0 run function ybih:game/end_round
