# ybih:button/on_use —— 进度「对着按钮交互」的奖励函数（1.20 起的那份进度）
# 进度带 location 谓词过滤（见 advancement/button_used.json），只有对着按钮的交互才会进来，
# 挖方块、开箱子、点门都不触发。
#
# 这里仍取不到「是哪一个按钮」：进度只说明交互目标是按钮方块，不给出实体。
# 所以由 on_use_trace 从眼位出发做一次射线，锁定正对着的那个按钮标记，把编号抄给玩家；
# press_scan 扫到 powered 时再用这个编号认领按下者 —— 按钮身份对得上才算数。
#
# 守卫用 if 包住整行，不用 execute ... run return：/return 是 1.20.2 才加入的，
# 写在包 1 里会让整个函数加载失败，而函数加载失败只写进日志、不进聊天栏，排查代价极高
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run function ybih:button/on_use_trace

# 自检：走到这里说明进度确实触发了（真有人对着按钮交互），上面那次调用就应当
# 把 ybih.used 写成当前 tick —— on_use_trace 第 8 行无条件写这个值。
# 没写成就只有一种可能：那个函数没加载成功（函数加载失败只写日志、不进聊天栏），
# 于是整条按下判定静默失效，玩家看到的是「按钮有动画有音效，但不加分、没有任何提示」。
# 条件里带上前面的守卫，所以只在「真的按了」时报，正常游玩一个字都不会多出来
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] unless score @s ybih.used = #tick ybih.config run tellraw @s {{TXT_S}}按下判定没有启动：数据包函数 ybih:button/on_use_trace 未能加载，请重新加载数据包并查看游戏日志{{TXT_M}}red{{TXT_E}}

# 进度触发一次就被标记为已完成，不撤销就再也进不来。
# 只撤自己这一份：包 1 同时放着旧格式的 button_used_legacy，
# 两份互撤对方时，总有一份在本版本上没加载成功，每次交互都会刷一条命令失败
advancement revoke @s only ybih:button_used
