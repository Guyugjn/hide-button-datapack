# ybih:player/on_death —— 重生后补回冒险模式与对局保险
# 死亡会清空全部状态效果，这里是唯一能立刻补回来的时机；buff_guard 最多晚一秒
#
# 围观阶段（#state = 4）全员是旁观，matches 1..3 天然把它排除在外，
# 正在观战的人不会因为死亡被拽出旁观

scoreboard players set @s ybih.death 0
execute if entity @s[tag=ybih_buffed] run function ybih:player/apply_buff
execute if score #state ybih.config matches 1..3 run gamemode adventure @s
execute if score #state ybih.config matches 1..3 run tellraw @s {{TXT_S}}你死了，但仍在局中{{TXT_M}}yellow{{TXT_E}}
