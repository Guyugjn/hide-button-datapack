# ybih:button/confirm_place —— 确认藏匿：材质属于本包清单才计入
# 认不出的材质（多半是地图自带的按钮）不计入 #button_count，否则本轮会因为
# 那个按钮永远按不掉而跑满搜寻时间

execute if entity @e[tag=ybih_pending,tag=ybih_unknown] run function ybih:button/reject_unknown
execute unless entity @e[tag=ybih_pending,tag=ybih_unknown] run function ybih:button/confirm_place_ok
