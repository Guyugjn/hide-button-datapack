# ybih:button/award_deny —— 本次按下没有计分，按 #deny 里的理由给提示

execute if score #deny ybih.config matches 1 run tellraw @s {{TXT_S}}参与人数超出记录上限，这次点击没有计分{{TXT_M}}red{{TXT_E}}
execute if score #deny ybih.config matches 2 run tellraw @s {{TXT_S}}你已经从这个按钮上拿过分了{{TXT_M}}red{{TXT_E}}
execute if score #deny ybih.config matches 3 run tellraw @s {{TXT_S}}这个按钮的分已经被拿完了{{TXT_M}}red{{TXT_E}}
execute if score #deny ybih.config matches 4 run tellraw @s {{TXT_S}}这个按钮已经不在了，本次不算{{TXT_M}}red{{TXT_E}}
