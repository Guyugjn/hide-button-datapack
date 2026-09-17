# ybih:player/buff_guard —— 每秒把对局保险顶回去
# 死亡会清空全部状态效果，喝牛奶、被外部 /effect clear 也一样，而这些都不会摘掉
# ybih_buffed 标签。所以「该不该有」只看标签，效果本身每秒无条件重发一次

scoreboard players set #buff_timer ybih.config 20
execute as @a[tag=ybih_buffed] run function ybih:player/apply_buff
