# ybih:button/on_use_legacy —— 进度「对着按钮交互」的奖励函数（1.16.2–1.19.4 的那份进度）
# 与 button/on_use 是同一条链路，只差撤销的是旧格式那份进度：
# 1.20 起 location 被收成谓词数组，认不得旧格式的裸对象；
# 两份进度各自只在认得它的版本上加载成功，所以各撤自己那一份，不会撤到一份不存在的进度
execute if score #state ybih.config matches 3 if entity @s[tag=ybih_player] run function ybih:button/on_use_trace

advancement revoke @s only ybih:button_used_legacy
