# ybih:button/press_claim —— 合资格者认领这次按下：自己的按钮只提示，别人的按钮计分
# 物主也走这条路径，所以自己按自己的按钮不会再被算到别人头上

execute if score @s ybih.id = #press_owner ybih.config run function ybih:button/own_press
execute unless score @s ybih.id = #press_owner ybih.config run function ybih:button/collect
