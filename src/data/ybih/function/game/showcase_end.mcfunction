# ybih:game/showcase_end —— 围观结束：放开钉住的区块，收掉场上的按钮，恢复参与者的游戏模式
# 这一条同时收掉两类方块：本来就插在场上、分还没被拿完的，和围观期间按记录临时摆回去的。
# 被按掉的那些标记（ybih_ghost）连同记录一起在这里终结

# 释放本局申请过的区块强加载：凭 ybih_pinned 标记，标记被 kill 之前先放开
execute as @e[tag=ybih_pinned] at @s run forceload remove ~ ~
tag @e[tag=ybih_pinned] remove ybih_pinned
execute as @e[tag=ybih_showcase] at @s if block ~ ~ ~ #minecraft:buttons run setblock ~ ~ ~ air
kill @e[tag=ybih_showcase]
# 高亮与队伍要到下一局之前撤干净：标记已经 kill，光会随实体消失，
# 但玩家身上的发光和队伍身份留着，物主的标签也要撤
# 不限定 ybih_player：围观期间重连或中途进服的人也可能被 showcase_glow 上过色，
# 而那时他未必带着参与者标签
effect clear @a minecraft:glowing
team leave @a
tag @a remove ybih_show_owner
# 夜视只清「围观发过的那份」：ybih_show_nv 是 showcase_start 与 showcase_state 打上的，
# 没参与这局、也没被围观接管的人身上的夜视是他自己的，不该被顺手清掉。
# 观战夜视（凭据 ybih_spect_nv）不在这里回收：本节不动中途进服的围观者，
# 他依旧是旁观、依旧该看得见，player/buff_guard 会按凭据继续顶上。
# 真要回收的是整局结束的三个收尾点（cleanup_end / reload_cleanup / reset）
effect clear @a[tag=ybih_show_nv] minecraft:night_vision
tag @a remove ybih_show_nv
# 恢复游戏模式：按入队时记下的原模式还原，不是一律设成冒险 ——
# 原本是创造的参与者结束围观后应该还是创造
execute as @a[gamemode=spectator,tag=ybih_gm_creative] run gamemode creative @s
execute as @a[gamemode=spectator,tag=ybih_gm_survival] run gamemode survival @s
# 落到冒险的只能是「入队时本来就是冒险」的人：三条都带 gamemode=spectator 前置，
# 先命中的那条会把玩家切出旁观、后面的不再命中，所以「身上至多只有一个 ybih_gm_*」
# 是这里正确性的前提。够不到任何一条的人（服主自己设的旁观、或入队时没被记上的人）
# 保持旁观不动 —— 这里不猜他的模式，也不替他做决定
execute as @a[gamemode=spectator,tag=ybih_gm_adventure] run gamemode adventure @s
# 定格计时归零：围观收尾的那一 tick showcase_tick 还在递减它，
# 留着非零值会让下个阶段的 tick 继续拿它当判据
scoreboard players set #freeze ybih.config 0
tellraw @a {{TXT_S}}围观结束{{TXT_M}}gray{{TXT_E}}
function ybih:game/end_round_finish
