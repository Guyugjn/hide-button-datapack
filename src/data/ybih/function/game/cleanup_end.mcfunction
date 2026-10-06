# ybih:game/cleanup_end —— 整局结束：清场并还原玩家状态

function ybih:game/cleanup_buttons
# 全员回集合点集合。这一步必须排在拆等待室之前：按中止时可能还有人被关在里面，
# 先抽掉地板再传送就成了自由落体
execute if entity @e[tag=ybih_center] as @a run tp @s @e[tag=ybih_center,limit=1]
# 围观展示是临时把按钮留在世界里的，方块由上面 cleanup_buttons → cleanup_all 兜底收掉：
# 那条清扫先扫方块、再释放 ybih_pinned、最后才 kill 标记，顺序在这里重放不出来，
# 也不再重复 —— 同一个区块被 add 两次而只 remove 一次会留下泄漏
# 高亮与队伍要到下一局之前撤干净：标记已经 kill，光会随实体消失，
# 但玩家身上的发光、队伍身份、物主标签都留着，要在清标签之前撤
effect clear @a minecraft:glowing
team leave @a
tag @a remove ybih_show_owner
# 围观发出去的夜视与它的标记一起收掉，免得跨局残留
effect clear @a[tag=ybih_show_nv] minecraft:night_vision
tag @a remove ybih_show_nv
# 观战夜视（player/spectate 发的，凭据 ybih_spect_nv）也在整局结束时回收：
# player/buff_guard 会按凭据一直续期，不在这里收就跨局跨存档一直亮着。
# 它只由 player/spectate 发出、入队时（player/join_game）会失效，不会落到参赛者身上
effect clear @a[tag=ybih_spect_nv] minecraft:night_vision
tag @a remove ybih_spect_nv
# 恢复游戏模式：只处理「当前是旁观」的人 —— 围观把参与者切成了旁观，
# 只有这类人才需要还原。无脑按标签恢复会误伤：一个入队时是创造的人，
# 局中自己切回了冒险，标签却还留着，就会被莫名拽回创造
execute as @a[gamemode=spectator,tag=ybih_gm_creative] run gamemode creative @s
execute as @a[gamemode=spectator,tag=ybih_gm_survival] run gamemode survival @s
# 落到冒险的只能是「入队时本来就是冒险」的人。三条都带 gamemode=spectator 前置，
# 先命中的那条会把玩家切出旁观、后面的不再命中，所以「身上至多只有一个 ybih_gm_*」
# 是这里正确性的前提。够不到任何一条的人是旁观者，保持旁观不动
execute as @a[gamemode=spectator,tag=ybih_gm_adventure] run gamemode adventure @s
tag @a remove ybih_player
tag @a remove ybih_current
tag @a remove ybih_top
tag @a remove ybih_ranked
tag @a remove ybih_pressed
tag @a remove ybih_presser
tag @a remove ybih_user
tag @a remove ybih_ray_found
tag @a remove ybih_gm_survival
tag @a remove ybih_gm_creative
tag @a remove ybih_gm_adventure
scoreboard players set @a ybih.trigger 0
scoreboard players set @a ybih.id 0
scoreboard players set @a ybih.used -1
scoreboard players set @a ybih.used_bid 0
scoreboard players set #state ybih.config 0
scoreboard players set #timer ybih.config 0
scoreboard players set #round ybih.config 0
scoreboard players set #cycle ybih.config 0
scoreboard players set #seekers_total ybih.config 0
scoreboard players set #ranked ybih.config 0
function ybih:game/bar_hide
function ybih:util/remove_wait_room
function ybih:util/border_reset
