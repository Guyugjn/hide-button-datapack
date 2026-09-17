# ybih:game/bar_hide —— 收起 Boss 栏并断开与玩家的关联
# 只隐藏不删除：Boss 栏本身由 bar_init 在加载时重建

bossbar set ybih:timer visible false
bossbar set ybih:timer players
