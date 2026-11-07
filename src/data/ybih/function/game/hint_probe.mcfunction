# ybih:game/hint_probe —— 检查按钮是否仍可取分，并记录距离档位
# 执行者是按钮标记，#band_r 是当前扫描半径。

function ybih:game/hint_eligible
execute if score #hint_ok ybih.config matches 1 run scoreboard players operation #hint_band ybih.config = #band_r ybih.config
