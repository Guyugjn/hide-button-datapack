# ybih:game/showcase_bar —— 围观阶段的 Boss 栏：看的是第几个、这个的分有没有被拿完、还剩几秒
# 标题每秒重写一次，剩余秒数才看得出在走；两种状态各写一套，靠 #show_found 分派

scoreboard players set #show_refresh ybih.config 20
scoreboard players operation #show_sec ybih.config = #show_timer ybih.config
scoreboard players operation #show_sec ybih.config /= #c20 ybih.config
execute if score #show_sec ybih.config matches ..0 run scoreboard players set #show_sec ybih.config 0
# 标题正文带上物主名字，所以要借物主的身份发命令（选择器只能在自己的执行实体上渲染出名字）。
# 物主不在线就退回不带名字的那一版，秒数照常走
execute if entity @a[tag=ybih_show_owner] as @a[tag=ybih_show_owner,limit=1] run function ybih:game/showcase_bar_owner
execute unless entity @a[tag=ybih_show_owner] if score #show_found ybih.config matches 0 run bossbar set ybih:timer name [{{TXT_S}}还有分的按钮 {{TXT_E}},{{SCORE_SHOWIDX}},{{TXT_S}} / {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} · 还剩 {{TXT_E}},{{SCORE_SHOWSEC}},{{TXT_S}} 秒{{TXT_E}}]
execute unless entity @a[tag=ybih_show_owner] if score #show_found ybih.config matches 1 run bossbar set ybih:timer name [{{TXT_S}}分被拿完的按钮 {{TXT_E}},{{SCORE_SHOWIDX}},{{TXT_S}} / {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} · 还剩 {{TXT_E}},{{SCORE_SHOWSEC}},{{TXT_S}} 秒{{TXT_E}}]
execute if score #show_found ybih.config matches 0 run title @a actionbar [{{TXT_S}}还有分的按钮 {{TXT_E}},{{SCORE_SHOWIDX}},{{TXT_S}} / {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} · 还剩 {{TXT_E}},{{SCORE_SHOWSEC}},{{TXT_S}} 秒{{TXT_E}}]
execute if score #show_found ybih.config matches 1 run title @a actionbar [{{TXT_S}}分被拿完的按钮 {{TXT_E}},{{SCORE_SHOWIDX}},{{TXT_S}} / {{TXT_E}},{{SCORE_SHOWTOTAL}},{{TXT_S}} · 还剩 {{TXT_E}},{{SCORE_SHOWSEC}},{{TXT_S}} 秒{{TXT_E}}]
