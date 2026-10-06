# ybih:button/on_use_trace —— 记下这次交互的 tick，再从眼位射线锁定是哪一个按钮
# 执行者是按下按钮的玩家。两条进度入口（on_use / on_use_legacy）共用这一份
#
# 最后一行必须以 execute 开头：at / anchored / positioned 这些只是 execute 的修饰子命令，
# 单独写出来会被当成一条名叫 at 的命令，整行解析失败 —— 而函数加载失败只写进日志、
# 不进聊天栏，表现成「按钮有动画有音效，但既不加分也没有任何提示」，
# 与「射线没锁到按钮」的表象完全一样。同类正确写法见 button/try_register 的最后一行
#
# 射线分两遍走，与放置侧 button/try_register 对称：第一遍只认射线正中的那一格，
# 第二遍补探邻格。第二遍是另一条独立的 6 格射线，必须把 #ray_step 归零后重新锚定眼位 ——
# 接着第一遍的步数往下走会只剩不到 6 格，够不到远处那个按钮
scoreboard players operation @s ybih.used = #tick ybih.config
scoreboard players set @s ybih.used_bid 0
scoreboard players set #ray_step ybih.config 0
tag @s remove ybih_ray_found
execute at @s anchored eyes run function ybih:button/use_ray
execute unless entity @s[tag=ybih_ray_found] run scoreboard players set #ray_step ybih.config 0
execute unless entity @s[tag=ybih_ray_found] at @s anchored eyes run function ybih:button/use_ray_nbr
