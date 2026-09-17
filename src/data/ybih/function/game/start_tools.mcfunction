# ybih:game/start_tools —— 集合点没设置时发放设置书并提示

function ybih:admin/book
tellraw @s {{TXT_S}}集合点还没设置{{TXT_M}}gold{{TXT_E}}
tellraw @s {{TXT_S}}站到想让大家集合的位置，点书里的「集合点设在我脚下」{{TXT_E}}
tellraw @s {{TXT_S}}设好后再次执行 /function ybih:start{{TXT_E}}
