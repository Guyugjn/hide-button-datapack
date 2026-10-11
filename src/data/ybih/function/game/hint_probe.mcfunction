# ybih:game/hint_probe —— 判断这个按钮是否属于别人，是就把当前档位记下来
# 执行者是按钮标记，由生成的 game/hint_scan 按档位逐个调进来；
# #band_r 是调用方写入的「当前正在试的那一档半径」
#
# 只记第一个命中的：hint_scan 每档都带 `#hint_band matches 0` 前置，
# 内层先试，所以留下的永远是包围最近的别人按钮的那个最小档位。
# 这里不写「取更小的值」那种比较 —— 升序 + 前置闸门已经把这件事做完了
#
# 自己的按钮不算：报出来的档位与残局方位都该指向别人藏的按钮。
# 少了这道判断，玩家站在自己的按钮旁边就会收到「就在 5 格内」，
# 而那个方向指回自己刚放下的方块，白白把人带偏

execute unless score @s ybih.owner_id = #hint_self ybih.config run scoreboard players operation #hint_band ybih.config = #band_r ybih.config
