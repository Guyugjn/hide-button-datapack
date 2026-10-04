# ybih:game/reload_cleanup —— /reload 时清空对局数据，集合点与设置保留

function ybih:util/cleanup_all
# 围观展示可能正卡在半途，留在世界里的按钮要一并收掉。
# 区块强加载已在上面 cleanup_all 里按 ybih_pinned 释放过，这里不重复
execute as @e[tag=ybih_showcase] at @s if block ~ ~ ~ #minecraft:buttons run setblock ~ ~ ~ air
kill @e[tag=ybih_showcase]
# 全员回集合点，必须排在拆等待室之前：可能还有人被关在里面
execute if entity @e[tag=ybih_center] as @a run tp @s @e[tag=ybih_center,limit=1]
function ybih:util/remove_wait_room
function ybih:util/border_reset
# 围观会把全员切成旁观，高亮则是队伍与发光效果。标记已被 kill、光会随实体消失，
# 但玩家身上的发光、队伍身份、物主标签都留在存档里，这三条要在清标签之前撤
effect clear @a minecraft:glowing
team leave @a
tag @a remove ybih_show_owner
# 恢复游戏模式：只处理「当前是旁观」的人 —— 围观把参与者切成了旁观，
# 只有这类人才需要还原。无脑按标签恢复会误伤：一个入队时是创造的人，
# 局中自己切回了冒险，标签却还留着，reload 就会把他莫名拽回创造。
# 三条按固定的先后执行，身上若同时留着两个旧标签，靠后的那条生效
execute as @a[gamemode=spectator,tag=ybih_gm_creative] run gamemode creative @s
execute as @a[gamemode=spectator,tag=ybih_gm_survival] run gamemode survival @s
# 没参与这局的人（中途进服、没经过 join_game）身上没有 ybih_gm_* 标签，
# 却也可能是被围观顺手切成的旁观，兜底给他们冒险模式
execute as @a[gamemode=spectator,tag=!ybih_gm_creative,tag=!ybih_gm_survival] run gamemode adventure @s
effect clear @a[tag=ybih_current] minecraft:night_vision
# 围观发出去的夜视也要一并撤：它挂了很久，留着会跨局带到下一局
effect clear @a[tag=ybih_show_nv] minecraft:night_vision
tag @a remove ybih_show_nv
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
scoreboard players set @a ybih.score 0
scoreboard players reset * ybih.board
execute as @a[tag=ybih_buffed] run function ybih:player/clear_buff
scoreboard players set @a ybih.placed 0
scoreboard players set @a ybih.turn 0
scoreboard players set @a ybih.id 0
scoreboard players set @a ybih.owner_id 0
scoreboard players set @a ybih.finds 0
scoreboard players set @a ybih.t_first 999999
scoreboard players set @a ybih.trigger 0
scoreboard players set @a ybih.used -1
scoreboard players set @a ybih.used_bid 0
scoreboard players set #state ybih.config 0
scoreboard players set #timer ybih.config 0
scoreboard players set #round ybih.config 0
scoreboard players set #cycle ybih.config 0
scoreboard players set #next_id ybih.config 1
scoreboard players set #tick ybih.config 0
scoreboard players set #gained ybih.config 0
scoreboard players set #ranked ybih.config 0
scoreboard players set #seekers_total ybih.config 0
