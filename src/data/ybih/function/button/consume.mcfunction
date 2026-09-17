# ybih:button/consume —— 把按下的按钮移出对局管理，并更新剩余计数
# 只动本次按下对应的那一个标记，避免场上同时有两个按下的按钮时删错格
#
# 标记不杀：位置、材质与朝向标签、物主编号都记在它身上，而非玩家实体一旦死亡，
# 它名下的分数会被一并清空。轮末围观要靠这些信息把按钮临时摆回原位，
# 所以这里只是把它从 ybih_button 摘出来换成 ybih_ghost —— 摘掉之后
# 清场、保护、按下检测、冷热提示都不再管它，方块则早在下面就被设成空气了
#
# 计数只减到 0 为止：地图自带按钮的标记也在 ybih_button 里，它从没被加过计数，
# 一旦被回收就会把数字带成负数，搜寻阶段开局即判定「已按完」
execute if score #button_count ybih.config matches 1.. run scoreboard players remove #button_count ybih.config 1
execute at @e[tag=ybih_active,limit=1] if block ~ ~ ~ #minecraft:buttons run setblock ~ ~ ~ minecraft:air
tag @e[tag=ybih_active] remove ybih_button
# ybih_pressed 是「同一个 powered 窗口只判定一次」的闸门，弹起时才由 release 摘。
# 这个标记已经不会再被 press_scan 遍历到，留着就是永久的残留
tag @e[tag=ybih_active] remove ybih_pressed
# 此刻区块必然是加载的（就有人站在旁边按），顺手钉住它 —— 按掉的按钮多半在轮末
# 已经超出模拟距离，@e 看不到它，轮末展示就会静默漏掉这一个。
# 打上 ybih_pinned 作为凭据，四条清理路径都靠它 forceload remove
execute at @e[tag=ybih_active,limit=1] run forceload add ~ ~
tag @e[tag=ybih_active] add ybih_pinned
tag @e[tag=ybih_active] add ybih_ghost
tag @e[tag=ybih_active] remove ybih_active
