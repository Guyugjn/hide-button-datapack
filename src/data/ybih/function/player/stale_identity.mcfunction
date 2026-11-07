# ybih:player/stale_identity —— 收回不属于当前局的参赛身份
# 不按旧编号调用棋局退出：新局里同编号可能已经属于其他人。
# 先撤效果凭据，再还原旧模式；后续由当前阶段按非参赛者接管。
execute if entity @s[tag=ybih_show_owner] run function ybih:game/showcase_glow_clear
execute if entity @s[tag=ybih_current] run function ybih:game/current_clear
execute if entity @s[tag=ybih_show_nv] run effect clear @s minecraft:night_vision
execute if entity @s[tag=ybih_spect_nv] run effect clear @s minecraft:night_vision
tag @s remove ybih_show_nv
tag @s remove ybih_spect_nv
function ybih:player/restore_gamemode

tag @s remove ybih_player
tag @s remove ybih_current
tag @s remove ybih_spec_once
tag @s remove ybih_top
tag @s remove ybih_ranked
tag @s remove ybih_pressed
tag @s remove ybih_user
tag @s remove ybih_ray_found
tag @s remove ybih_presser
scoreboard players set @s ybih.id 0
scoreboard players set @s ybih.score 0
scoreboard players set @s ybih.placed 0
scoreboard players set @s ybih.turn 0
scoreboard players set @s ybih.finds 0
scoreboard players set @s ybih.t_first 999999
scoreboard players set @s ybih.trigger 0
scoreboard players set @s ybih.used -1
scoreboard players set @s ybih.used_bid 0
scoreboard players reset @s ybih.era
scoreboard players reset @s ybih.t_epoch
