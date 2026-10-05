# ybih:game/showcase_glow_clear —— 撤掉「当前按钮物主」的高亮与凭据
# 执行者是那位玩家
#
# 三样要一起撤，少一样都会留残留：
# - 效果：高亮轮廓本身
# - 队伍身份：轮廓颜色取自队伍的 color，只清效果的话描边还会带着红/绿
# - 凭据：game/showcase_bar 靠它认人，留着会让 Boss 栏继续写他的名字
#
# 由 player/buff_guard 在凭据不成立时每秒调用一次（见那里的两条判据），
# 也用于「他重连时已经不是当前物主」的场合

effect clear @s minecraft:glowing
team leave @s
tag @s remove ybih_show_owner
