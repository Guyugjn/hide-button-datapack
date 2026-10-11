# ybih:game/hint_dir —— 残局补报「别人的按钮在哪个方向」（执行者是玩家本人）
#
# 由 game/hint_one 在「已进残局、且 #hint_band 确实探到了别人的按钮」时调用。
# 方向话术只在残局出现：前半场保持「只知道远近、得自己走位」，才有搜寻的过程感；
# 残局收尾给方向，是为了让最后那段不至于变成纯粹的瞎转
#
# 分两步：这里挑出「最近的那个别人的按钮」，方位判定交给 hint_dir_cmp。
# 拆开是因为方位判定要读按钮坐标，而按钮坐标只在 as @e 的上下文里取得对 ——
# 一个是玩家、一个是标记，混在一个文件里很容易写错原点
#
# **坐标一律不乘 100**：border_edge_check 那套 ×100 定标是为了比较「格 × 100」的
# 两位小数，代价是坐标接近 ±3×10⁷ 时会撞 int32 回绕（那里专门写了注释）。
# 方位判定只需要符号与量级，整数部分完全够用，不缩放就直接绕开这个风险

# 玩家坐标（整数部分够用）与编号。编号要传下去：hint_dir_cmp 跑在按钮标记身上，
# 发文案时得靠它把玩家选回来（@s 在那个上下文里是盔甲架）
scoreboard players set #hd_px ybih.config 0
scoreboard players set #hd_pz ybih.config 0
scoreboard players operation #hd_pid ybih.config = @s ybih.id
execute store result score #hd_px ybih.config run data get entity @s Pos[0]
execute store result score #hd_pz ybih.config run data get entity @s Pos[2]

# 先把上一次的候选清掉，再按 #hint_band 这一档把候选挑出来。
# 判据写成**精确等于**而不是 `r..`：#hint_band 是「包围最近那个按钮的最小档位」，
# 所以那一个必定落在 distance=..r 之内，用不着放宽；写放宽只会让语义含糊
# （band=15 时也去试 ..10 与 ..20 两档，读的人得自己推「其实不会命中」）
#
# 清理的选择器按**标签本身**选，不能写成 tag=ybih_button：这个标记会在两次提示之间
# 被按到分光，button/consume 随即把它从 ybih_button 摘出来换成 ybih_ghost（方块也已设成空气），
# 而 ybih_near 会留在它身上 —— 按 ybih_button 清就够不到它，成了一个再也无人认领的残留。
# 它随后会被末尾那行当成候选：那一位按钮已经不存在了，方位却照报不误
tag @e[tag=ybih_near] remove ybih_near
execute if score #hint_band ybih.config matches 5 as @e[tag=ybih_button,distance=..5] if score @s ybih.era = #era ybih.config run function ybih:game/hint_dir_pick
execute if score #hint_band ybih.config matches 10 as @e[tag=ybih_button,distance=..10] if score @s ybih.era = #era ybih.config run function ybih:game/hint_dir_pick
execute if score #hint_band ybih.config matches 15 as @e[tag=ybih_button,distance=..15] if score @s ybih.era = #era ybih.config run function ybih:game/hint_dir_pick
execute if score #hint_band ybih.config matches 20 as @e[tag=ybih_button,distance=..20] if score @s ybih.era = #era ybih.config run function ybih:game/hint_dir_pick
execute if score #hint_band ybih.config matches 30 as @e[tag=ybih_button,distance=..30] if score @s ybih.era = #era ybih.config run function ybih:game/hint_dir_pick
execute if score #hint_band ybih.config matches 50 as @e[tag=ybih_button,distance=..50] if score @s ybih.era = #era ybih.config run function ybih:game/hint_dir_pick

# 挑最近的那个算方位。sort=nearest 的参考点是执行位置 —— 此刻还停在玩家身上，正是我们要的
execute as @e[tag=ybih_near,limit=1,sort=nearest] run function ybih:game/hint_dir_cmp
