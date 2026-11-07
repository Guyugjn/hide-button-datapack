# ybih:button/award_dec —— 递减下次奖励，最低为一分
# 按钮保留到本轮结束，以便离线的未领取者重连后仍可领取。

execute as @e[tag=ybih_active,limit=1] if score @s ybih.value matches 2.. run scoreboard players remove @s ybih.value 1
scoreboard players set #dyn_dirty ybih.config 1
