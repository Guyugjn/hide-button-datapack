# ybih:game/hint_all —— 冷热提示（每 hint_period 秒一次）

scoreboard players operation #hint_timer ybih.config = #hint_period ybih.config
execute as @a[tag=ybih_player,tag=!ybih_current] at @s run function ybih:game/hint_one
