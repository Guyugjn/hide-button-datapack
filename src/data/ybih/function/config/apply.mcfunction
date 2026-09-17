# ybih:config/apply —— 配置项
# 修改本文件后执行 /reload，再执行 /function ybih:config/apply

# 准备阶段时长（秒）
scoreboard players set #prep_time ybih.config 10

# 每人藏匿回合时长（秒）
scoreboard players set #hide_time ybih.config 60

# 搜寻期时长（秒，兜底）
scoreboard players set #search_time ybih.config 600

# 冷热提示间隔（秒）
scoreboard players set #hint_period ybih.config 60

# 冷热提示的探测半径（格）。可选档位在 book.mjs 的 HINT_RADII，
# hint_scan 按档位逐条分派，这里必须写成档位表里有的值
scoreboard players set #hint_range ybih.config 10

# 按钮保护检测间隔（tick）
scoreboard players set #protect_period ybih.config 5

# 总轮数：每轮为「藏匿 + 搜寻」一次完整流程，分数跨轮累计
# 轮流模式下这是周期数，一局总轮数 = 周期数 × 参与人数
scoreboard players set #rounds ybih.config 1

# 游戏模式：1 = 经典（各藏各找），2 = 轮流（一人藏众人找）
scoreboard players set #mode ybih.config 1

# 放错确认：1 = 开启（放下后要在聊天栏点【确认】），2 = 关闭（放下即生效）
scoreboard players set #confirm ybih.config 1

tellraw @a {{TXT_S}}[你的按钮我来藏] 配置已应用{{TXT_M}}green{{TXT_E}}
