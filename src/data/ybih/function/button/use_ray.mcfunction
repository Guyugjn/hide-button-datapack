# ybih:button/use_ray —— 按下定位射线的第一遍：每步前进 0.1 格、最多 60 步（6 格），只认当前格
# 长度与放置射线一致：按钮最远能在 5 格附近被点到，射线短于交互距离就会漏判，那次按下白按
#
# 第一遍**只探射线正中的那一格，绝不探邻格**。每步探邻格会扫进大量不在射线上的格子，
# 那儿的本局按钮会被抢先锁走 —— 表现成「点的是这个按钮，加分却算在那个上」，
# 与放置侧「盔甲架跑到别的按钮上」是同一个坑，理由详见 button/ray_loop 的头部。
#
# 只认本局登记的按钮（ybih_era 对得上）、且不是待确认的：
# 地图自带的按钮、往局残留、玩家刚放还没确认的都不参与按下判定
# 命中后把该标记的编号抄进玩家的 ybih.used_bid，press_scan 靠它认领
#
# 采样点整格跳过按钮格的那一小部分（复现里 3.1%）交给第二遍 button/use_ray_nbr 补，
# 它只在第一遍走满之后才跑，由 button/on_use_trace 归零 #ray_step 后重新锚定眼位

scoreboard players add #ray_step ybih.config 1
execute unless entity @s[tag=ybih_ray_found] run function ybih:button/use_probe
execute if score #ray_step ybih.config matches ..59 unless entity @s[tag=ybih_ray_found] positioned ^ ^ ^0.1 run function ybih:button/use_ray
