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

# 进度触发一次就被标记为已完成，不撤销就再也进不来。
# 只撤自己这一份：包 1 同时放着旧格式的 button_used_legacy，
# 两份互撤对方时，总有一份在本版本上没加载成功，每次交互都会刷一条命令失败
advancement revoke @s only ybih:button_used
