# ybih:game/hint_dir_cmp —— 由玩家与按钮的坐标差算出八向方位，报给玩家本人
# 执行者是那个按钮标记；玩家坐标由 game/hint_dir 写在 #hd_px / #hd_pz，#hd_pid 是玩家编号
#
# **文案不能直接 title @s**：这个函数跑在按钮标记身上，@s 是那个盔甲架，不是人。
# 所以照 button/notify_first_find 的既有手法，按编号把玩家选出来再发
#
# 坐标轴约定（与游戏一致，改这里之前先在游戏里四面各站一次核对）：
#   +X 东、-X 西、+Z 南、-Z 北。**Z 轴是反的**：Z 增大是往南，不是往北
#
# 八个方位靠两件事分：(1) 主轴是东西还是南北，(2) 两个轴各往哪个方向。
# 主轴用「一个轴的差值是否大于另一个轴差值的两倍」来定：
#   |dx| > 2|dz| → 东西向；|dz| > 2|dx| → 南北向；两者都不成立 → 对角。
# 这三条彼此不重叠、也不留空隙，合起来正好盖住整个平面，这是它唯一需要保证的性质。
# 系数取 2（比值 0.5）而不是精确的 tan(22.5°) ≈ 0.414，会让四个正方向稍宽一些、
# 对角稍窄：夹角 25° 时报「东」而不是「东南」。这是有意的 —— 报出一个略偏的正方向
# 比报一个精确但对玩家没用的斜向更好用，而且计算只需要一次乘法
#
# 上界核算：#hd_az 最大约 6×10⁷（世界边界），乘 2 得 1.2×10⁸，距 int32 上限
# 2147483647 余量充足。**加任何 ×100 都会让它回绕**，改这里时不要动这件事
#
# 差值为 0（玩家与按钮在同一格的某个轴上）时符号位落在「不正」一侧，
# 对角分支会盖住这种歧义；按钮贴在脸上时本来就看得见，不必为这一格较真

# 按钮坐标与差值
scoreboard players set #hd_bx ybih.config 0
scoreboard players set #hd_bz ybih.config 0
execute store result score #hd_bx ybih.config run data get entity @s Pos[0]
execute store result score #hd_bz ybih.config run data get entity @s Pos[2]

scoreboard players operation #hd_dx ybih.config = #hd_bx ybih.config
scoreboard players operation #hd_dx ybih.config -= #hd_px ybih.config
scoreboard players operation #hd_dz ybih.config = #hd_bz ybih.config
scoreboard players operation #hd_dz ybih.config -= #hd_pz ybih.config

# 取绝对值：#neg 是 -1（已有常量），照抄 border_edge_check 的写法
execute if score #hd_dx ybih.config matches ..-1 run scoreboard players operation #hd_dx ybih.config *= #neg ybih.config
execute if score #hd_dz ybih.config matches ..-1 run scoreboard players operation #hd_dz ybih.config *= #neg ybih.config
scoreboard players operation #hd_ax ybih.config = #hd_dx ybih.config
scoreboard players operation #hd_az ybih.config = #hd_dz ybih.config

# 主轴判定：1 = 东西，2 = 南北，3 = 对角（默认对角，两条覆盖性判定各自推翻它）
scoreboard players operation #hd_2z ybih.config = #hd_az ybih.config
scoreboard players operation #hd_2z ybih.config *= #c2 ybih.config
scoreboard players operation #hd_a2x ybih.config = #hd_ax ybih.config
scoreboard players operation #hd_a2x ybih.config *= #c2 ybih.config
scoreboard players set #hd_axis ybih.config 3
execute if score #hd_ax ybih.config > #hd_2z ybih.config run scoreboard players set #hd_axis ybih.config 1
execute if score #hd_az ybih.config > #hd_a2x ybih.config run scoreboard players set #hd_axis ybih.config 2

# 两个轴各自的正负：1 = 正方向（东 / 南）。差值为 0 时落在「不正」一侧
scoreboard players set #hd_sx ybih.config 0
scoreboard players set #hd_sz ybih.config 0
execute if score #hd_dx ybih.config matches 1.. run scoreboard players set #hd_sx ybih.config 1
execute if score #hd_dz ybih.config matches 1.. run scoreboard players set #hd_sz ybih.config 1

# 八个方位。四正各一条（主轴 + 单轴符号），四斜各一条（对角 + 两轴符号）。
# **正负号与坐标轴的对应是这张表最容易写反的地方**：
#   sx=1 → 东（+X）、sx=0 → 西（-X）；sz=1 → 南（+Z）、sz=0 → 北（-Z）
# 文案里带上档位（SCORE_HINTBAND），免得方位把上一条「N 格内」的信息顶掉后只剩方向
execute if score #hd_axis ybih.config matches 1 if score #hd_sx ybih.config matches 1 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 东 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 1 if score #hd_sx ybih.config matches 0 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 西 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 2 if score #hd_sz ybih.config matches 1 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 南 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 2 if score #hd_sz ybih.config matches 0 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 北 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 3 if score #hd_sx ybih.config matches 1 if score #hd_sz ybih.config matches 1 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 东南 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 3 if score #hd_sx ybih.config matches 1 if score #hd_sz ybih.config matches 0 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 东北 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 3 if score #hd_sx ybih.config matches 0 if score #hd_sz ybih.config matches 1 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 西南 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
execute if score #hd_axis ybih.config matches 3 if score #hd_sx ybih.config matches 0 if score #hd_sz ybih.config matches 0 as @a[tag=ybih_player] if score @s ybih.id = #hd_pid ybih.config run title @s actionbar [{{TXT_S}}别人的按钮在 西北 边 · {{TXT_E}},{{SCORE_HINTBAND}},{{TXT_S}} 格内{{TXT_M}}red{{TXT_E}}]
