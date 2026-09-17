# ybih:button/on_use —— 进度「对着按钮交互」的奖励函数
# 进度带 location 谓词过滤（见 advancement/button_used.json），
# 只有对着按钮的交互才会进来，挖方块、开箱子、点门都不触发
#
# 这里仍取不到「是哪一个按钮」：进度只说明交互目标是按钮方块，不给出实体。
# 所以从眼位出发做一次射线，锁定他正对着的那个按钮标记，把它的编号抄给玩家。
# press_scan 扫到 powered 时再用这个编号认领按下者 —— 按钮身份对得上才算数
#
# 射线只在玩家真的点了按钮时跑一次

# 阶段与身份的守卫用 if 包住整段，不用 execute ... run return ——
# /return 是 1.20.2 才加入的，写在这里会让包 1 的整个函数加载失败，
# 而函数加载失败只写进日志、不进聊天栏，排查代价极高
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run scoreboard players operation @s ybih.used = #tick ybih.config
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run scoreboard players set @s ybih.used_bid 0
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run scoreboard players set #ray_step ybih.config 0
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run tag @s remove ybih_ray_found
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] at @s anchored eyes run function ybih:button/use_ray
advancement revoke @s only ybih:button_used
