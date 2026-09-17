# ybih:button/on_press —— 检测到按钮被按下（每种材质一条，由构建脚本分派）
# 同一个 powered 窗口只判定一次：判定过就挂上 ybih_pressed，等按钮弹起由 release 摘掉
# 这条闸门同时挡住了「箭、三叉戟、风弹把按钮打成 powered 后整段时间里反复判定」

execute if score #state ybih.config matches 3 if score #mode ybih.config matches 1 unless entity @s[tag=ybih_pressed] run function ybih:button/press_begin
execute if score #state ybih.config matches 3 if score #mode ybih.config matches 2 unless entity @s[tag=ybih_pressed] run function ybih:button/press_mode2
