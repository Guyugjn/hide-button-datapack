# ybih:config/notify —— 设置被修改后的统一反馈（音效 + 显示当前全部设置）

playsound minecraft:ui.button.click player @s ~ ~ ~ 1 1
tellraw @s {{TXT_S}}—— 当前设置 ——{{TXT_M}}gold{{TXT_E}}
execute if score #mode ybih.config matches 2 run tellraw @s [{{TXT_S}}模式 {{TXT_E}},{{TXT_S}}轮流 · 一人藏众人找{{TXT_M}}gold{{TXT_E}}]
execute unless score #mode ybih.config matches 2 run tellraw @s [{{TXT_S}}模式 {{TXT_E}},{{TXT_S}}经典 · 各藏各找{{TXT_M}}gold{{TXT_E}}]
execute if score #confirm ybih.config matches 1 run tellraw @s [{{TXT_S}}放错确认 {{TXT_E}},{{TXT_S}}开启{{TXT_M}}green{{TXT_E}}]
execute unless score #confirm ybih.config matches 1 run tellraw @s [{{TXT_S}}放错确认 {{TXT_E}},{{TXT_S}}关闭{{TXT_M}}gray{{TXT_E}}]
tellraw @s [{{TXT_S}}准备 {{TXT_E}},{{SCORE_PREP}},{{TXT_S}} 秒　藏匿 {{TXT_E}},{{SCORE_HIDETIME}},{{TXT_S}} 秒{{TXT_E}}]
execute if score #hint_period ybih.config matches 99999 run tellraw @s [{{TXT_S}}搜寻 {{TXT_E}},{{SCORE_SEARCH}},{{TXT_S}} 秒　提示 关闭{{TXT_M}}gray{{TXT_E}}]
execute unless score #hint_period ybih.config matches 99999 run tellraw @s [{{TXT_S}}搜寻 {{TXT_E}},{{SCORE_SEARCH}},{{TXT_S}} 秒　提示 {{TXT_E}},{{SCORE_HINT}},{{TXT_S}} 秒 · 半径 {{TXT_E}},{{SCORE_HINTRANGE}},{{TXT_S}} 格{{TXT_E}}]
tellraw @s [{{TXT_S}}轮数 {{TXT_E}},{{SCORE_ROUNDS}},{{TXT_S}} 轮{{TXT_E}}]
execute if score #showcase_on ybih.config matches 1 run tellraw @s [{{TXT_S}}轮末围观 {{TXT_E}},{{TXT_S}}开启{{TXT_M}}green{{TXT_E}}]
execute unless score #showcase_on ybih.config matches 1 run tellraw @s [{{TXT_S}}轮末围观 {{TXT_E}},{{TXT_S}}关闭{{TXT_M}}gray{{TXT_E}}]
execute if score #border_on ybih.config matches 1 if score #border_r ybih.config matches 1.. run tellraw @s [{{TXT_S}}活动边界 {{TXT_E}},{{TXT_S}}开启 · 半径 {{TXT_E}},{{SCORE_BORDER_R}},{{TXT_S}} 格 · 开局生效{{TXT_M}}gold{{TXT_E}}]
execute if score #border_on ybih.config matches 1 unless score #border_r ybih.config matches 1.. run tellraw @s [{{TXT_S}}活动边界 {{TXT_E}},{{TXT_S}}开启 · 跟随手动值 · 开局生效{{TXT_M}}gold{{TXT_E}}]
execute unless score #border_on ybih.config matches 1 run tellraw @s [{{TXT_S}}活动边界 {{TXT_E}},{{TXT_S}}关闭{{TXT_M}}gray{{TXT_E}}]
tellraw @s [{{TXT_S}}世界边界直径 {{TXT_E}},{{SCORE_BW}},{{TXT_S}} 格（初始值 59999968）{{TXT_M}}gray{{TXT_E}}]
