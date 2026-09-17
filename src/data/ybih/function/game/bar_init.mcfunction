# ybih:game/bar_init —— 建立 Boss 栏并从零配好属性
# Boss 栏会随存档写进 level.dat 的 CustomBossEvents，/reload 冲不掉，所以先删后建
# name 里的分数在设置那一刻就定死了，之后不会自己刷新，标题由 bar_update 每秒重设

bossbar remove ybih:timer
bossbar add ybih:timer {{TXT_S}}你的按钮我来藏{{TXT_E}}
bossbar set ybih:timer color yellow
bossbar set ybih:timer style progress
bossbar set ybih:timer max 100
bossbar set ybih:timer value 100
bossbar set ybih:timer visible false
