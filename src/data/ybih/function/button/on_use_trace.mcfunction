# ybih:button/on_use_trace —— 记下这次交互的 tick，再从眼位射线锁定是哪一个按钮
# 执行者是按下按钮的玩家。两条进度入口（on_use / on_use_legacy）共用这一份
scoreboard players operation @s ybih.used = #tick ybih.config
scoreboard players set @s ybih.used_bid 0
scoreboard players set #ray_step ybih.config 0
tag @s remove ybih_ray_found
at @s anchored eyes run function ybih:button/use_ray
