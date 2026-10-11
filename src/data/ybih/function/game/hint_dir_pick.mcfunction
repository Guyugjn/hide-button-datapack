# ybih:game/hint_dir_pick —— 把「本档内、属于别人的」按钮打上 ybih_near（执行者是按钮标记）
# 由 game/hint_dir 按档位逐个调进来，档位与执行者的筛选都在调用方做完
#
# 必须排除自己的按钮，与 game/hint_probe 同一口径：
# #hint_band 只保证「档内至少有一个别人的按钮」，并不保证档内没有自己的 ——
# 而下面的选择器用 sort=nearest 取最近的一个。自己的按钮常常就放在身边，
# 少了这道判断，方位就会指向自己刚放下的那个方块，把人带偏

execute unless score @s ybih.owner_id = #hint_self ybih.config run tag @s add ybih_near
