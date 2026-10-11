# ybih:game/hint_all —— 冷热提示（每 hint_period 秒一次，残局减半）
#
# 残局（搜寻剩余时间 ≤ #late_from）把间隔缩一半：提示变密是「搜寻像瞎逛」的主要解药，
# 而只在前半场保持稀疏，是为了不让藏匿方在开局就被迅速定位 —— 那样「藏得好」又不值钱了。
# 除法用 #c2（已有常量），#late_from 的判据在 hint_one 里读，两处口径同源
#
# 藏匿者本人（ybih_current）不参与：轮流模式他在旁观，给他提示等于泄题

execute if score #timer ybih.config <= #late_from ybih.config run scoreboard players operation #hint_timer ybih.config = #hint_period ybih.config
execute if score #timer ybih.config <= #late_from ybih.config run scoreboard players operation #hint_timer ybih.config /= #c2 ybih.config
execute if score #timer ybih.config > #late_from ybih.config run scoreboard players operation #hint_timer ybih.config = #hint_period ybih.config
execute as @a[tag=ybih_player,tag=!ybih_current] at @s run function ybih:game/hint_one
