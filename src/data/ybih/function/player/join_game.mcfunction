# ybih:player/join_game —— 玩家入队：分配 id、记录原游戏模式

tag @s add ybih_player
scoreboard players operation @s ybih.id = #next_id ybih.config
scoreboard players add #next_id ybih.config 1
scoreboard players set @s ybih.score 0
scoreboard players set @s ybih.placed 0
scoreboard players set @s ybih.turn 0
scoreboard players set @s ybih.finds 0
scoreboard players set @s ybih.t_first 999999
scoreboard players set @s ybih.trigger 0
scoreboard players set @s ybih.used -1
scoreboard players set @s ybih.used_bid 0
# 入队的人不再下等待室的棋：把身上那一局清干净（ttt_abort 会连对手一起收），
# 名单位也交回去 —— 他这一局都在场上，不该再占着名单上的位子
function ybih:room/ttt_abort
scoreboard players set @s ybih.rseat 0

# 先无条件撤掉三个标签，保证身上至多只剩一个；这一步不能省 —— 恢复点的三条命令
# 都带 gamemode=spectator 前置，先命中的那条会把玩家切出旁观，后面的就再也不命中，
# 靠执行顺序盖不掉叠加
tag @s remove ybih_gm_survival
tag @s remove ybih_gm_creative
tag @s remove ybih_gm_adventure
execute if entity @s[gamemode=survival] run tag @s add ybih_gm_survival
execute if entity @s[gamemode=creative] run tag @s add ybih_gm_creative
execute if entity @s[gamemode=adventure] run tag @s add ybih_gm_adventure

# 入队就是参赛的一方，观战身份连同那份夜视在这里立刻作废：夜视是发给围观者的，
# 不能让人带着它下场。player/buff_guard 也会在「有凭据但不再是旁观」时兜一次，
# 但那是每秒一轮，这里收掉才不留空窗
execute if entity @s[tag=ybih_spect_nv] run effect clear @s minecraft:night_vision
tag @s remove ybih_spect_nv
# 入队就是参赛的一方，「已经按旁观接管过」这条一次性凭据一并作废：
# 留着它，他这一局就不再被当非参赛者处理，下一局也仍认得出他是参赛者
tag @s remove ybih_spec_once

gamemode adventure @s
