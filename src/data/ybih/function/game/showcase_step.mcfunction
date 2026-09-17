# ybih:game/showcase_step —— 停够时间就换下一个，全看完就收尾
# 判断要排在展示之前：展示完最后一个之后，本 tick 不能再判一次「没有下一个了」，
# 否则最后一个按钮会被 showcase_end 当场清掉，看起来就成了「只看了第一个就不动」
# 是否看完按编号比，不数 @e：队列万一没跟上，也不会被误判成空的

scoreboard players add #show_idx ybih.config 1

execute if score #show_idx ybih.config > #show_total ybih.config run function ybih:game/showcase_end
execute if score #show_idx ybih.config <= #show_total ybih.config run scoreboard players operation #show_timer ybih.config = #show_len ybih.config
execute if score #show_idx ybih.config <= #show_total ybih.config run function ybih:game/showcase_pick
