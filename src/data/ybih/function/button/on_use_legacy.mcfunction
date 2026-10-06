# ybih:button/on_use_legacy —— 进度「对着按钮交互」的奖励函数（1.16.2–1.19.4 的那份进度）
# 与 button/on_use 是同一条链路，只差撤销的是旧格式那份进度：
# 1.20 起 location 被收成谓词数组，认不得旧格式的裸对象；
# 两份进度各自只在认得它的版本上加载成功，所以各撤自己那一份，不会撤到一份不存在的进度
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run function ybih:button/on_use_trace

# 自检：与 button/on_use 末尾那条同理 —— 进度触发了却没写下当前 tick，
# 就说明 on_use_trace 没加载成功，这次按下会静默失效
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] unless score @s ybih.used = #tick ybih.config run tellraw @s {{TXT_S}}按下判定没有启动：数据包函数 ybih:button/on_use_trace 未能加载，请重新加载数据包并查看游戏日志{{TXT_M}}red{{TXT_E}}

advancement revoke @s only ybih:button_used_legacy
