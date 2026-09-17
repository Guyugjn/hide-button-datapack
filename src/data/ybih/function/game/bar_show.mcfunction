# ybih:game/bar_show —— 开局把 Boss 栏交给参赛者并立刻刷出正确内容

bossbar set ybih:timer players @a[tag=ybih_player]
bossbar set ybih:timer visible true
function ybih:game/bar_update
