// 等待室九宫格棋：全部生成器
//
// 动手改之前，先读这四条设计前提。
//
// 一、**棋盘跟着人走**。一局棋的全部状态记在两位玩家自己的记分板上，不占任何「桌子」槽位，
//     所以同一份函数代码同时服务任意多局 —— 能同时开几局只看房里有多少人（两人一局），
//     固定桌数上限就不存在了。
//
// 二、**聊天栏里点不出运行时数据**。tellraw 要显示玩家真名，只能用 text 组件的
//     {"selector":...}，而选择器必须写死在命令里。于是「名单位」成了唯一可行的办法：
//     名单位是 1..12 的常量，每位配一条写死了选择器的聊天行，记在 ybih.rseat 上，
//     进等待室时分一个最小的空位。**书页同理**：书页内容在构建期就定死了，
//     所以书里塞不进玩家名 —— 选人这一步只能在聊天栏完成。
//
// 三、**邀请要双方对等登记**。发起方记 INVITED(1)、受邀方记 INVITING(2)，两边各存一份
//     「对手编号 topp」与「对手名单位 topps」。每秒核对一次两边说法是否一致，对不上就作废 ——
//     掉线、被拎去藏、走出房间都不会留下卡住的局面。
//
// 四、**棋盘三格必须等宽**。聊天栏没有制表位，对齐全靠每格占一样宽；这条由
//     tools/build.mjs 的 validateBoardCells 把守，把某个记号改窄了会构建失败。

const TTT_CELLS = 9;
const TTT_ROSTER = 12;
const ROOM = '@e[tag=ybih_room,limit=1]';
// 把执行位置摆到房间标记上。调用处用它 + as，避免写出 @@e 这种拼错的选择器
const AT_ROOM = `at ${ROOM}`;

// 棋子角色
const ROLE_X = 1;
const ROLE_O = 2;

// 对局状态
const ST_FREE = 0; // 空闲，可以邀请别人
const ST_INVITED = 1; // 我已发出邀请，等他点头
const ST_INVITING = 2; // 有人邀请我，等我点头
const ST_PLAYING = 3; // 对局中
const ST_DONE = 4; // 这一局刚下完，对手还在

// 点击通道取值。1 / 2 被按钮的确认与取消重放占着，不动
const TR_REFRESH = 11;
const TR_LEAVE = 12;
const TR_BOARD = 13;
const TR_CELL_BASE = 19; // 第 n 格 → 20..28
const TR_ACCEPT = 29;
const TR_DECLINE = 30;
const TR_CANCEL = 31;
const TR_AGAIN = 32;
const TR_INVITE_BASE = 40; // 名单位 i → 41..52

// 记分项
const cell = (n) => `ybih.t${n}`;
const T_STATE = 'ybih.tstate';
const T_ROLE = 'ybih.trole';
const T_OPP = 'ybih.topp';
const T_OPPS = 'ybih.topps';
const T_TURN = 'ybih.tturn';
const T_RES = 'ybih.tres';
// 名字里的 ttt 不能省：ybih.t_first 是藏匿顺序（原有序号），与这里只差一个下划线，
// 两个记分项语义完全不同，少写一个 t 就会改到另一个上
const T_FIRST = 'ybih.ttt_first';
const T_TOLD = 'ybih.told';
const T_SEAT = 'ybih.rseat';

// 连成三子的 8 条线，元素是格号
const TTT_LINES = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9],
  [1, 4, 7],
  [2, 5, 8],
  [3, 6, 9],
  [1, 5, 9],
  [3, 5, 7],
];

// 按名单位取真名的选择器。必须写死 —— 这是聊天栏能显示玩家名的唯一办法
const nameSel = (i) => `{"selector":"@a[scores={${T_SEAT}=${i}},limit=1]"}`;
// 房里某个名单位上的人。带 distance 是为了挡住「人已经走了、名单位还没来得及收回」
// 的那一秒空窗；调用处必须先把执行位置摆在房间标记上
const seatIn = (i, st, extra = '') =>
  `@a[tag=ybih_player,scores={${T_SEAT}=${i},${T_STATE}=${st}}${extra},distance=..12]`;

const TXT = (t) => `{{TXT_S}}${t}{{TXT_E}}`;
const file = (...lines) => lines.join('\n') + '\n';

// 清掉某人的一整局数据。wrap 把一条命令body包成完整的一行 ——
// 「清我自己」直接就是命令，「清对手」得先 execute as 找回他，所以这里要能换外壳。
// T_FIRST 一起清 —— 先手轮换属于「这一对」，两人散了就该从 ✕ 重新开始
function clearPair(lines, wrap) {
  const emit = (body) => lines.push(wrap(body));
  for (const obj of [T_STATE, T_ROLE, T_OPPS, T_TURN, T_RES, T_TOLD, T_FIRST]) {
    emit(`scoreboard players set @s ${obj} 0`);
  }
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    emit(`scoreboard players set @s ${cell(n)} 0`);
  }
}

// ── 棋盘 ─────────────────────────────────────────────────────────

function genTttBoard() {
  const lines = [
    '# ybih:room/ttt_board —— 把执行者本人的棋盘贴到他自己聊天栏',
    '# 全部按 @s 取数：棋盘就在各人自己身上，所以这一份代码同时服务所有对局',
    '# 格子取值 0 空 / 1 叉 / 2 圈；三格等宽由构建期的 validateBoardCells 把守',
    '',
    'tellraw @s {{TXT_S}}你的棋盘{{TXT_M}}gold{{TXT_E}}',
    '',
    '# 结果：tres 记的是「哪一方连成的」，跟自己的 trole 一比就知道这局谁赢',
  ];
  for (const [res, role, text, color] of [
    [1, ROLE_X, '你执 ✕ 连成三子，赢下这局', 'green'],
    [1, ROLE_O, '对手执 ✕ 连成三子，这局你输了', 'red'],
    [2, ROLE_O, '你执 ◯ 连成三子，赢下这局', 'green'],
    [2, ROLE_X, '对手执 ◯ 连成三子，这局你输了', 'red'],
  ]) {
    lines.push(
      `execute if score @s ${T_RES} matches ${res} if score @s ${T_ROLE} matches ${role} run tellraw @s {{TXT_S}}${text}{{TXT_M}}${color}{{TXT_E}}`,
    );
  }
  lines.push(
    `execute if score @s ${T_RES} matches 3 run tellraw @s {{TXT_S}}九个格子都满了，这局平手{{TXT_M}}yellow{{TXT_E}}`,
  );
  lines.push('');
  lines.push('# 轮到谁：tturn 存的是玩家编号，和自己的比一下就知道');
  lines.push(
    `execute if score @s ${T_RES} matches 0 if score @s ybih.id = @s ${T_TURN} if score @s ${T_ROLE} matches ${ROLE_X} run tellraw @s {{TXT_S}}轮到你落子（✕）{{TXT_M}}gold{{TXT_E}}`,
  );
  lines.push(
    `execute if score @s ${T_RES} matches 0 if score @s ybih.id = @s ${T_TURN} if score @s ${T_ROLE} matches ${ROLE_O} run tellraw @s {{TXT_S}}轮到你落子（◯）{{TXT_M}}gold{{TXT_E}}`,
  );
  lines.push(
    `execute if score @s ${T_RES} matches 0 unless score @s ybih.id = @s ${T_TURN} run tellraw @s {{TXT_S}}等对手落子…{{TXT_M}}gray{{TXT_E}}`,
  );
  lines.push('');
  // 三行 × 每行 27 种取值组合：tellraw 读不到记分板，只能把组合在构建期摊开
  for (let row = 0; row < 3; row += 1) {
    const ns = [row * 3 + 1, row * 3 + 2, row * 3 + 3];
    for (let pattern = 0; pattern < 27; pattern += 1) {
      const vals = [Math.floor(pattern / 9) % 3, Math.floor(pattern / 3) % 3, pattern % 3];
      const guard = ns.map((n, i) => `if score @s ${cell(n)} matches ${vals[i]}`).join(' ');
      const cells = ns.map((n, i) =>
        vals[i] === 0 ? `{{BTN_TTT_${n}}}` : vals[i] === ROLE_X ? '{{TTT_X}}' : '{{TTT_O}}',
      );
      lines.push(`execute ${guard} run tellraw @s [${cells.join(',')}]`);
    }
  }
  lines.push('');
  lines.push('# 结果行下面这一排按钮：下完了才给【再来一局】，对局中只给【离座】。');
  lines.push('# 对局中不给【再来一局】是因为它认的是「刚下完」，此刻点了毫无反应；');
  lines.push('# 而【离座】无论下没下完都该有 —— 只在下完时贴出来，中途想走的人就只剩');
  lines.push('# 【刷新名单】那条路，棋盘上明明写着「轮到你落子」却没有出口');
  lines.push(
    `execute if score @s ${T_RES} matches 1..3 run tellraw @s [{{BTN_TTT_AGAIN}},{{TXT_S}}  {{TXT_E}},{{BTN_TTT_LEAVE}}]`,
  );
  lines.push(
    `execute unless score @s ${T_RES} matches 1..3 run tellraw @s [{{BTN_TTT_LEAVE}}]`,
  );
  return file(...lines);
}

// ── 落子 ─────────────────────────────────────────────────────────

function genTttClick() {
  const lines = [
    '# ybih:room/ttt_click —— 落子：只有「对局中 + 这局还没下完 + 轮到我 + 这格空着」才落得下',
    '# 不合法的点击什么都不改，只回一句说明 —— 这就是「落过的格子点不动」的实现方式：',
    '# 点不动是因为条件不成立，不是因为有谁给格子做了标记',
    '',
    'scoreboard players set #t_pick ybih.ttt 0',
  ];
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(
      `execute if score @s ${T_STATE} matches ${ST_PLAYING} if score @s ${T_RES} matches 0 if score @s ybih.id = @s ${T_TURN} if score @s ybih.trigger matches ${TR_CELL_BASE + n} if score @s ${cell(n)} matches 0 run scoreboard players set #t_pick ybih.ttt ${n}`,
    );
  }
  lines.push('');
  lines.push('# 落子：棋子号就是我的角色（1 叉 / 2 圈）');
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(
      `execute if score #t_pick ybih.ttt matches ${n} run scoreboard players operation @s ${cell(n)} = @s ${T_ROLE}`,
    );
  }
  lines.push('');
  lines.push('# 判胜：8 条线里任一线的三格同值且非空，那个值就是胜方的角色');
  lines.push('# tres 上的 0 守卫保证只认第一条连成的线；一步棋替两方同时连成是不可能的，');
  lines.push('# 加上它只是为了让「后算的线不会盖掉先算出来的胜方」这件事一目了然');
  for (const line of TTT_LINES) {
    const [a, b, c] = line.map(cell);
    lines.push(
      `execute if score #t_pick ybih.ttt matches 1..9 if score @s ${T_RES} matches 0 if score @s ${a} = @s ${b} if score @s ${b} = @s ${c} unless score @s ${a} matches 0 run scoreboard players operation @s ${T_RES} = @s ${a}`,
    );
  }
  const allFilled = Array.from(
    { length: TTT_CELLS },
    (_, i) => `unless score @s ${cell(i + 1)} matches 0`,
  ).join(' ');
  lines.push(
    `execute if score #t_pick ybih.ttt matches 1..9 if score @s ${T_RES} matches 0 ${allFilled} run scoreboard players set @s ${T_RES} 3`,
  );
  lines.push('');
  lines.push('# 换手：还没下完才换。对手编号只有一个，把轮次直接指过去就行');
  lines.push(
    `execute if score #t_pick ybih.ttt matches 1..9 if score @s ${T_RES} matches 0 run scoreboard players operation @s ${T_TURN} = @s ${T_OPP}`,
  );
  lines.push('');
  lines.push('# 落不下的时候说清楚是为什么');
  lines.push(
    `execute if score #t_pick ybih.ttt matches 0 if score @s ${T_RES} matches 1..3 run tellraw @s {{TXT_S}}这局已经下完了，点【再来一局】或【离座】{{TXT_M}}gray{{TXT_E}}`,
  );
  lines.push(
    `execute if score #t_pick ybih.ttt matches 0 if score @s ${T_RES} matches 0 if score @s ${T_STATE} matches ${ST_PLAYING} run tellraw @s {{TXT_S}}这一格现在落不下：要么没轮到你，要么已经落过了{{TXT_M}}gray{{TXT_E}}`,
  );
  lines.push('');
  lines.push('# 先把对手编号存进 #topp —— 下面几条都要按它找人');
  lines.push(
    'execute if score #t_pick ybih.ttt matches 1..9 run scoreboard players operation #topp ybih.ttt = @s ybih.topp',
  );
  lines.push('');
  lines.push('# 这一局下完了就把双方切到「刚下完」。不切的话状态一直停在「对局中」，');
  lines.push('# 而【再来一局】认的是「刚下完」—— 那个按钮就永远点不动，只能离座重来');
  lines.push(
    `execute if score #t_pick ybih.ttt matches 1..9 if score @s ${T_RES} matches 1..3 run scoreboard players set @s ${T_STATE} ${ST_DONE}`,
  );
  lines.push(
    `execute if score #t_pick ybih.ttt matches 1..9 if score @s ${T_RES} matches 1..3 as @a if score @s ybih.id = #topp ybih.ttt run scoreboard players set @s ${T_STATE} ${ST_DONE}`,
  );
  lines.push('');
  lines.push('# 真的落了子才同步给对手、重贴两份棋盘、出声');
  lines.push('execute if score #t_pick ybih.ttt matches 1..9 run function ybih:room/ttt_sync');
  lines.push('execute if score #t_pick ybih.ttt matches 1..9 run function ybih:room/ttt_board');
  lines.push(
    'execute if score #t_pick ybih.ttt matches 1..9 as @a if score @s ybih.id = #topp ybih.ttt run function ybih:room/ttt_board',
  );
  lines.push(
    'execute if score #t_pick ybih.ttt matches 1..9 run playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 1.2',
  );
  lines.push(
    'execute if score #t_pick ybih.ttt matches 1..9 as @a if score @s ybih.id = #topp ybih.ttt run playsound minecraft:block.note_block.bass player @s ~ ~ ~ 1 1.2',
  );
  lines.push(
    `execute if score #t_pick ybih.ttt matches 1..9 if score @s ${T_RES} matches 1..3 run playsound minecraft:entity.player.levelup player @s ~ ~ ~ 1 1.5`,
  );
  lines.push(
    `execute if score #t_pick ybih.ttt matches 1..9 as @a if score @s ybih.id = #topp ybih.ttt if score @s ${T_RES} matches 1..3 run playsound minecraft:entity.player.levelup player @s ~ ~ ~ 1 1.5`,
  );
  return file(...lines);
}

// ── 同步 ─────────────────────────────────────────────────────────

function genTttSync() {
  const lines = [
    '# ybih:room/ttt_sync —— 把执行者自己的棋盘镜像到对手身上',
    '# 先把九格、轮次、结果搬进假名，再按编号找回对手写过去。',
    '# 「按编号找人」是本项目既有写法：as @a if score @s ybih.id = #x ybih.ttt',
    '# 角色（trole）不镜像 —— 两人正好相反，各自留着自己的那份',
    '',
    `scoreboard players operation #topp ybih.ttt = @s ${T_OPP}`,
    `scoreboard players operation #mturn ybih.ttt = @s ${T_TURN}`,
    `scoreboard players operation #mres ybih.ttt = @s ${T_RES}`,
  ];
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(`scoreboard players operation #m${n} ybih.ttt = @s ${cell(n)}`);
  }
  lines.push('');
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(
      `execute as @a if score @s ybih.id = #topp ybih.ttt run scoreboard players operation @s ${cell(n)} = #m${n} ybih.ttt`,
    );
  }
  lines.push(
    `execute as @a if score @s ybih.id = #topp ybih.ttt run scoreboard players operation @s ${T_TURN} = #mturn ybih.ttt`,
  );
  lines.push(
    `execute as @a if score @s ybih.id = #topp ybih.ttt run scoreboard players operation @s ${T_RES} = #mres ybih.ttt`,
  );
  return file(...lines);
}

// ── 开局 ─────────────────────────────────────────────────────────

function genTttStart() {
  const lines = [
    '# ybih:room/ttt_start —— 开局：清两张棋盘、定先手、把棋盘贴给两个人',
    '# 由 ttt_accept（同意邀请）或 ttt_again（再来一局）调用，两边登记在调用前已经对齐。',
    '# 这一份代码是对称的：@s 是一方、@s ybih.topp 指着另一方，所以谁调用都等价',
    '',
    'scoreboard players operation #me ybih.ttt = @s ybih.id',
    `scoreboard players operation #topp ybih.ttt = @s ${T_OPP}`,
    '',
    '# 我这边：清盘、进对局、复位提示标记（下一局的邀请要能再提示一次）',
    `scoreboard players set @s ${T_RES} 0`,
    `scoreboard players set @s ${T_STATE} ${ST_PLAYING}`,
    `scoreboard players set @s ${T_TOLD} 0`,
  ];
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(`scoreboard players set @s ${cell(n)} 0`);
  }
  lines.push('');
  lines.push('# 对手那边同样清盘、进对局');
  const toOther = 'execute as @a if score @s ybih.id = #topp ybih.ttt';
  for (const cmd of [
    `scoreboard players set @s ${T_RES} 0`,
    `scoreboard players set @s ${T_STATE} ${ST_PLAYING}`,
    `scoreboard players set @s ${T_TOLD} 0`,
  ]) {
    lines.push(`${toOther} run ${cmd}`);
  }
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(`${toOther} run scoreboard players set @s ${cell(n)} 0`);
  }
  lines.push('');
  lines.push('# 先手：ybih.ttt_first 记「这一局由执什么棋子的人先走」，两边保持同一个值。');
  lines.push('# 谁的角色等于它谁就先走 —— 两人角色互补，所以算出来必定是同一个人。');
  lines.push('# 对手的角色 = 3 − 我的角色（1 叉 / 2 圈互补）');
  lines.push('scoreboard players set #t_move ybih.ttt 0');
  lines.push(
    `execute if score @s ${T_ROLE} = @s ${T_FIRST} run scoreboard players operation #t_move ybih.ttt = @s ybih.id`,
  );
  lines.push(`scoreboard players set #opprole ybih.ttt ${ROLE_O}`);
  lines.push(
    `execute if score @s ${T_ROLE} matches ${ROLE_O} run scoreboard players set #opprole ybih.ttt ${ROLE_X}`,
  );
  lines.push(
    `execute if score #opprole ybih.ttt = @s ${T_FIRST} run scoreboard players operation #t_move ybih.ttt = @s ${T_OPP}`,
  );
  lines.push(`scoreboard players operation @s ${T_TURN} = #t_move ybih.ttt`);
  lines.push(`${toOther} run scoreboard players operation @s ${T_TURN} = #t_move ybih.ttt`);
  lines.push('');
  lines.push('# 翻转留给下一局。必须排在「读先手」之后，否则这一局用到的是下一局的值');
  lines.push(`scoreboard players set #t_tmp ybih.ttt ${ROLE_O}`);
  lines.push(
    `execute if score @s ${T_FIRST} matches ${ROLE_O} run scoreboard players set #t_tmp ybih.ttt ${ROLE_X}`,
  );
  lines.push(`scoreboard players operation @s ${T_FIRST} = #t_tmp ybih.ttt`);
  lines.push(`${toOther} run scoreboard players operation @s ${T_FIRST} = #t_tmp ybih.ttt`);
  lines.push('');
  lines.push('# 两边各报一句自己执什么，再各贴一份棋盘');
  lines.push(
    `execute if score @s ${T_ROLE} matches ${ROLE_X} run tellraw @s {{TXT_S}}开局！你执 ✕{{TXT_M}}red{{TXT_E}}`,
  );
  lines.push(
    `execute if score @s ${T_ROLE} matches ${ROLE_O} run tellraw @s {{TXT_S}}开局！你执 ◯{{TXT_M}}aqua{{TXT_E}}`,
  );
  lines.push('function ybih:room/ttt_board');
  lines.push('playsound minecraft:entity.player.levelup player @s ~ ~ ~ 1 1.4');
  lines.push(
    `${toOther} if score @s ${T_ROLE} matches ${ROLE_X} run tellraw @s {{TXT_S}}开局！你执 ✕{{TXT_M}}red{{TXT_E}}`,
  );
  lines.push(
    `${toOther} if score @s ${T_ROLE} matches ${ROLE_O} run tellraw @s {{TXT_S}}开局！你执 ◯{{TXT_M}}aqua{{TXT_E}}`,
  );
  lines.push(`${toOther} run function ybih:room/ttt_board`);
  lines.push(`${toOther} run playsound minecraft:entity.player.levelup player @s ~ ~ ~ 1 1.4`);
  return file(...lines);
}

// ── 解散一局 ─────────────────────────────────────────────────────

function genTttAbort() {
  const lines = [
    '# ybih:room/ttt_abort —— 让执行者退出当前这一局（邀请中、对局中、刚下完都算），',
    '# 并顺手把对手那边的残局收干净',
    '# 双方谁先被检查到都能收干净：按编号找回对手，确认他指的也是我，才动他的数据。',
    '#',
    '# 那句通知的收件人是**对手**，不是执行者：调用方（离座 / 拒绝 / 取消）已经用自己的',
    '# 措辞跟执行者交代过了，两边收件人不同、不会重复。所以这里没有任何抑制开关 ——',
    '# 加上抑制就只压掉对手唯一的那条通知：他的棋盘还停在「对局中」，',
    '# 点格子却毫无反应，只能自己想起来点【刷新名单】。',
    '',
    'scoreboard players operation #me ybih.ttt = @s ybih.id',
    `scoreboard players operation #topp ybih.ttt = @s ${T_OPP}`,
    '',
    '# 「#topp 从 1 起」这道守卫是给下面每一条兜底的：编号为 0 的人（没入队的、',
    '# 被 cleanup_end 清过的）不止一个，少了它，一场「双方编号都是 0」的巧合就会',
    '# 让这些命令一次选中所有 id=0 的人，把无关玩家的棋盘清掉',
    'scoreboard players set #has_opp ybih.ttt 0',
    'execute if score #topp ybih.ttt matches 1.. run scoreboard players set #has_opp ybih.ttt 1',
    `execute if score #has_opp ybih.ttt matches 1 as @a if score @s ybih.id = #topp ybih.ttt if score @s ${T_OPP} = #me ybih.ttt run tellraw @s {{TXT_S}}对手不在了，这一局作废，可以重新挑人{{TXT_M}}yellow{{TXT_E}}`,
    '',
    '# 清我自己。topp 要留到最后 —— 下面找对手全靠它',
  ];
  clearPair(lines, (body) => body);
  lines.push(`scoreboard players set @s ${T_OPP} 0`);
  lines.push('');
  lines.push('# 清对手（如果他还在，而且他指的正是我）。他的 topp 同样最后清 ——');
  lines.push('# 上面每一句都要靠「他的 topp 等于我」来确认动的是对的人；');
  lines.push('# 这一段同样只在 #has_opp 成立时才展开，理由与上面那条通知一样');
  const other = `execute if score #has_opp ybih.ttt matches 1 as @a if score @s ybih.id = #topp ybih.ttt if score @s ${T_OPP} = #me ybih.ttt run`;
  clearPair(lines, (body) => `${other} ${body}`);
  lines.push(`${other} scoreboard players set @s ${T_OPP} 0`);
  return file(...lines);
}

// ── 每秒核对 ─────────────────────────────────────────────────────

function genTttVerify() {
  const lines = [
    '# ybih:room/ttt_verify —— 每秒核对一个在房里的人：对手还在不在、两边说法一致不一致',
    '# 先算出「我的对手占了名单第几位」—— 只给聊天栏取真名用',
    '# （tellraw 的选择器必须写死，所以只能按名单位一位位问）',
    '',
    'scoreboard players operation #me ybih.ttt = @s ybih.id',
    `scoreboard players operation #topp ybih.ttt = @s ${T_OPP}`,
    'scoreboard players set #tslot ybih.ttt 0',
  ];
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    lines.push(
      `execute ${AT_ROOM} as @a[tag=ybih_player,scores={${T_SEAT}=${i}},distance=..12] if score @s ybih.id = #topp ybih.ttt run scoreboard players set #tslot ybih.ttt ${i}`,
    );
  }
  lines.push(`scoreboard players operation @s ${T_OPPS} = #tslot ybih.ttt`);
  lines.push('');
  lines.push('# 对手该是什么状态：邀请期两边互补（1 对 2），开局后同为 3，下完同为 4');
  lines.push(`scoreboard players operation #need ybih.ttt = @s ${T_STATE}`);
  lines.push(
    `execute if score @s ${T_STATE} matches ${ST_INVITED} run scoreboard players set #need ybih.ttt ${ST_INVITING}`,
  );
  lines.push(
    `execute if score @s ${T_STATE} matches ${ST_INVITING} run scoreboard players set #need ybih.ttt ${ST_INVITED}`,
  );
  lines.push('scoreboard players set #tok ybih.ttt 0');
  lines.push(
    `execute ${AT_ROOM} as @a[tag=ybih_player,distance=..12] if score @s ybih.id = #topp ybih.ttt if score @s ${T_STATE} = #need ybih.ttt if score @s ${T_OPP} = #me ybih.ttt run scoreboard players set #tok ybih.ttt 1`,
  );
  lines.push('# 对不上就作废。');
  lines.push('# 「正在被核对的人自己不在房里」那种情况由 ttt_tick 的另一条独立管（那条按距离判，');
  lines.push('# 与本函数无调用关系）—— 写在这里只是提醒读者别把这句当成漏了兜底');
  lines.push('execute if score #tok ybih.ttt matches 0 run function ybih:room/ttt_abort');
  return file(...lines);
}

// ── 状态行 ───────────────────────────────────────────────────────

// 「我现在是什么处境、这一步能按什么」。每种状态一行，名字按名单位写死选择器。
// 每行都是独立的一条命令，谁命中谁就收到那一条，所以一个人只会拿到自己那份
function stateLines() {
  const out = [];
  const say = (guard, parts) => out.push(`execute ${guard} run tellraw @s [${parts.join(',')}]`);
  say(`if score @s ${T_STATE} matches ${ST_FREE}`, [
    TXT('你现在空闲：点名单里某个人的【邀请】挑对手　'),
    '{{BTN_TTT_REFRESH}}',
  ]);
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    const nm = nameSel(i);
    const seat = `if score @s ${T_OPPS} matches ${i}`;
    say(`if score @s ${T_STATE} matches ${ST_INVITED} ${seat}`, [
      TXT('已邀请 '),
      nm,
      TXT('，等他点【同意】　'),
      '{{BTN_TTT_CANCEL}}',
    ]);
    say(`if score @s ${T_STATE} matches ${ST_INVITING} ${seat}`, [
      nm,
      TXT(' 想和你下一局　'),
      '{{BTN_TTT_ACCEPT}}',
      TXT(' '),
      '{{BTN_TTT_DECLINE}}',
    ]);
    say(`if score @s ${T_STATE} matches ${ST_PLAYING} ${seat}`, [
      TXT('正和 '),
      nm,
      TXT(' 对局中　'),
      '{{BTN_TTT_BOARD}}',
      TXT(' '),
      '{{BTN_TTT_LEAVE}}',
    ]);
    say(`if score @s ${T_STATE} matches ${ST_DONE} ${seat}`, [
      TXT('刚和 '),
      nm,
      TXT(' 下完一局　'),
      '{{BTN_TTT_AGAIN}}',
      TXT(' '),
      '{{BTN_TTT_LEAVE}}',
    ]);
  }
  // 对手不在名单上（或自己没分到名单位）时的退化说法，免得这种时候一句提示都没有
  say(`if score @s ${T_STATE} matches ${ST_INVITED} if score @s ${T_OPPS} matches 0`, [
    TXT('已发出邀请，等对方点头　'),
    '{{BTN_TTT_CANCEL}}',
  ]);
  say(`if score @s ${T_STATE} matches ${ST_INVITING} if score @s ${T_OPPS} matches 0`, [
    TXT('有人想和你下一局　'),
    '{{BTN_TTT_ACCEPT}}',
    TXT(' '),
    '{{BTN_TTT_DECLINE}}',
  ]);
  say(`if score @s ${T_STATE} matches ${ST_PLAYING} if score @s ${T_OPPS} matches 0`, [
    TXT('对局中　'),
    '{{BTN_TTT_BOARD}}',
    TXT(' '),
    '{{BTN_TTT_LEAVE}}',
  ]);
  say(`if score @s ${T_STATE} matches ${ST_DONE} if score @s ${T_OPPS} matches 0`, [
    TXT('这局下完了，对手已经不在名单上　'),
    '{{BTN_TTT_LEAVE}}',
  ]);
  return out;
}

function genTttStatus() {
  return file(
    '# ybih:room/ttt_status —— 重贴「我现在什么处境」那一行',
    '# 点【刷新名单】、点【看棋盘】、每个动作做完都会走到这里，随时能把状态找回来',
    '',
    ...stateLines(),
  );
}

function genTttNotice() {
  // 组件列表一律用数组 join(',') 拼 —— 手写字符串拼接时漏一个逗号（`{...}{...}`）
  // 是 SNBT 解析错误，会让**整个函数文件不加载**，只往日志留一行 Whilst parsing command。
  // 这个坑真的踩过：邀请提示整条哑掉，而紧随其后的 told 标记照常置位，
  // 于是提示再也不发 —— 表现为「只有点刷新才看得到被邀请」。
  // 用 join 之后，漏逗号在结构上就不可能发生
  const lines = [
    '# ybih:room/ttt_notice —— 邀请状态刚变化时提示一次',
    '# told 标记防重发：提示过就置 1，回到空闲或开新局时由 abort / start 复位。',
    '# 提示里要写对方的真名，而名字只能用写死的名单位选择器取，所以每位一条',
    '',
  ];
  const compose = (st, name) => {
    if (st === ST_INVITED) {
      return [TXT('已向 '), name, TXT(' 发出邀请，等他点【同意】　'), '{{BTN_TTT_CANCEL}}'];
    }
    return [name, TXT(' 想和你下一局　'), '{{BTN_TTT_ACCEPT}}', TXT(' '), '{{BTN_TTT_DECLINE}}'];
  };
  for (const st of [ST_INVITED, ST_INVITING]) {
    for (let i = 1; i <= TTT_ROSTER; i += 1) {
      const guard = `if score @s ${T_STATE} matches ${st} if score @s ${T_TOLD} matches 0 if score @s ${T_OPPS} matches ${i}`;
      lines.push(`execute ${guard} run tellraw @s [${compose(st, nameSel(i)).join(',')}]`);
    }
  }
  lines.push('');
  // 对手还没分到名单位（或者他已经离开了名单）时的退化说法，
  // 免得出现「状态是邀请中、却一句提示都没有」这种哑火
  for (const st of [ST_INVITED, ST_INVITING]) {
    const guard = `if score @s ${T_STATE} matches ${st} if score @s ${T_TOLD} matches 0 if score @s ${T_OPPS} matches 0`;
    lines.push(`execute ${guard} run tellraw @s [${compose(st, TXT('对方')).join(',')}]`);
  }
  lines.push('');
  lines.push(
    `execute if score @s ${T_STATE} matches ${ST_INVITED} if score @s ${T_TOLD} matches 0 run scoreboard players set @s ${T_TOLD} 1`,
  );
  lines.push(
    `execute if score @s ${T_STATE} matches ${ST_INVITING} if score @s ${T_TOLD} matches 0 run scoreboard players set @s ${T_TOLD} 1`,
  );
  return file(...lines);
}

// ── 名单 ─────────────────────────────────────────────────────────

function genTttRoster() {
  const lines = [
    '# ybih:room/ttt_roster —— 等待室名单：真名 + 每行一个可以点的【邀请】',
    '# 名字靠写死的选择器 @a[scores={ybih.rseat=i}] 取，1..12 每位一条 ——',
    '# 这是聊天栏能显示真名的唯一办法（书页在构建期就写死了，塞不进运行时数据）',
    '# 守卫带 distance=..12：名单位在离开房间时会被收回，这里再加一道保险。',
    '# 还要用 unless entity @s[scores={ybih.rseat=i}] 排掉自己 ——',
    '# 名单是拿来挑对手的，把自己列上去只会让人点到一行「这个人现在没空」',
    '',
    'tellraw @s {{TXT_S}}等待室 · 九宫格棋{{TXT_M}}gold{{TXT_E}}',
    'tellraw @s {{TXT_S}}想和谁下，就点他后面那个【邀请】；他点【同意】就开局{{TXT_M}}gray{{TXT_E}}',
    'tellraw @s {{TXT_S}}名单不会自己更新：有人进出就点【刷新名单】或翻开书按一下{{TXT_M}}gray{{TXT_E}}',
    '',
  ];
  const row = (i, st, tail) =>
    lines.push(
      `execute ${AT_ROOM} if entity ${seatIn(i, st)} unless entity @s[scores={${T_SEAT}=${i}}] run tellraw @s [${[TXT(`${i}. `), nameSel(i), tail].join(',')}]`,
    );
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    row(i, ST_FREE, `${TXT('　空闲　')},{{BTN_TTT_INV_${i}}}`);
    row(i, ST_DONE, `${TXT('　刚下完，可以邀请　')},{{BTN_TTT_INV_${i}}}`);
    row(i, ST_INVITED, TXT('　他已经向别人发出邀请'));
    row(i, ST_INVITING, TXT('　有人正在邀请他'));
    row(i, ST_PLAYING, TXT('　对局中'));
  }
  lines.push('');
  lines.push('tellraw @s {{TXT_S}}上面就是现在房里可以挑的人{{TXT_M}}dark_gray{{TXT_E}}');
  return file(...lines);
}

function genTttSeat() {
  const lines = [
    '# ybih:room/ttt_seat —— 给刚进等待室的人分一个名单位（1..12 里最小的空位）',
    '# 名单位是聊天栏显示真名的唯一抓手：选择器必须写死，所以「第 i 位是谁」',
    '# 只能靠 @a[scores={ybih.rseat=i}] 一位位去问',
    '# 已经有位子的人不动 —— 每轮换人都可能重走进房流程，重排会让名单乱跳',
    '',
    '# 占用靠 #rs1..#rs12 这组假玩家维持，而且**只增不减**：',
    '# @a 选不中离线玩家，掉线的人照样占着 5 号位，可是按「房里现在谁坐着 5 号」',
    '# 现算出来的表里他是空的 —— 新进来的人于是也坐上 5 号，等他重连就两人同号，',
    '# 名单上的显示名选择器带 limit=1，其中一人就此从名单上消失、别人再也点不到他。',
    '# 所以这里只补记「在线且坐着 i 号」的人，绝不清零：',
    '# 真要放掉一个位子，只能由拿到它的人自己在交回名单位时一起放（room/ttt_release）。',
    '# 代价是「进了房又退服、再也没回来」的人会占着位子到本轮结束 ——',
    '# 每轮的开局与轮末都会调 room/ttt_reset 把整张表连同名单位一起清空，漏不了一整局',
    '',
  ];
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    lines.push(
      `execute ${AT_ROOM} as @a[tag=ybih_player,scores={${T_SEAT}=${i}},distance=..12] run scoreboard players set #rs${i} ybih.ttt 1`,
    );
  }
  lines.push('');
  lines.push('# 从 1 号位往下试，坐上第一个空位就成了；后面几位看到「已经有位子」自然跳过。');
  lines.push('# 空位判据写 unless ... matches 1.. 而不是 matches 0：条目可能压根不存在');
  lines.push('# （reset * 会把它删掉），「matches 0」对没有条目的人不成立');
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    lines.push(
      `execute ${AT_ROOM} unless score @s ${T_SEAT} matches 1.. unless score #rs${i} ybih.ttt matches 1.. run scoreboard players set @s ${T_SEAT} ${i}`,
    );
  }
  lines.push('');
  lines.push('# 坐上位子就立刻把表补上，同 tick 里后面的人不会再抢同一个号');
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    lines.push(
      `execute ${AT_ROOM} if score @s ${T_SEAT} matches ${i} run scoreboard players set #rs${i} ybih.ttt 1`,
    );
  }
  lines.push('');
  lines.push('# 满员要说一声，不然他按了刷新却看不到自己，只会以为坏了。');
  lines.push('# 判据写 unless ... matches 1.. 而不是 matches 0：');
  lines.push('# room/ttt_reset 用的是 reset *（那是唯一能清掉离线玩家的写法），');
  lines.push('# 它会把条目整个删掉而不只是置 0，没分到位子的人这时**根本没有这一项** ——');
  lines.push('# 「matches 0」对没有条目的人是不成立的，照那样写满员时就一句提示都没有');
  lines.push(
    `execute ${AT_ROOM} unless score @s ${T_SEAT} matches 1.. run tellraw @s {{TXT_S}}等待室名单满了（${TTT_ROSTER} 位），先看别人下{{TXT_M}}yellow{{TXT_E}}`,
  );
  return file(...lines);
}

// 交回名单位：本人的 rseat 与对应那一个 #rsN 必须一起放。
// 只清 rseat 不清 #rsN 的话，位子会被永久占着（分配只看 #rsN），
// 房里明明有空位，新来的人却被告知「名单满了」
function genTttRelease() {
  const lines = [
    '# ybih:room/ttt_release —— 交回名单位（执行者本人）',
    '# 名单位的占用表是只增不减的（见 room/ttt_seat 里的说明），',
    '# 所以放掉一个位子只能在这里做，而且两处状态必须成对清',
    '',
  ];
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    lines.push(
      `execute if score @s ${T_SEAT} matches ${i} run scoreboard players set #rs${i} ybih.ttt 0`,
    );
  }
  lines.push(`scoreboard players set @s ${T_SEAT} 0`);
  return file(...lines);
}

// ── 邀请 ─────────────────────────────────────────────────────────

function genTttInviteDispatch() {
  const lines = [
    '# ybih:room/ttt_invite —— 邀请名单上某一位：按点击值分派到 ttt_invite_<i>',
    '# 名单位是常量，所以这里可以逐位写死，不必按编号去找人',
    '',
  ];
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    lines.push(
      `execute if score @s ybih.trigger matches ${TR_INVITE_BASE + i} run function ybih:room/ttt_invite_${i}`,
    );
  }
  return file(...lines);
}

function genTttInvite(i) {
  // 「能坐下」的两种状态，我和他各自独立成立即可 —— 必须取交叉组合。
  // 曾经写成「两边状态相同」（都空闲或都刚下完），于是「我一直等着、他刚打完一局」
  // 这种再常见不过的组合会被拒掉：他明明有空位，却回一句「这个人现在没空」。
  // 双方分别是 {空闲, 刚下完} 的 4 种组合都要放行
  const openStates = [ST_FREE, ST_DONE];
  const lines = [
    `# ybih:room/ttt_invite_${i} —— 邀请名单第 ${i} 位`,
    '# 只要「我空闲或刚下完」且「他也空闲或刚下完」就邀请得动：',
    '# 我这边带上一局也没关系（那局会被 ttt_abort 收掉），他那边必须是空着的。',
    '# 受邀人用写死的名单位选择器锁定，所以这里不需要按编号找他',
    '',
    'scoreboard players set #t_ok ybih.ttt 0',
  ];
  for (const mine of openStates) {
    for (const his of openStates) {
      lines.push(
        `execute if score @s ${T_STATE} matches ${mine} ${AT_ROOM} if entity ${seatIn(i, his)} run scoreboard players set #t_ok ybih.ttt 1`,
      );
    }
  }
  lines.push('# 不能邀请自己');
  lines.push(`execute if score @s ${T_SEAT} matches ${i} run scoreboard players set #t_ok ybih.ttt 0`);
  lines.push(
    'execute if score #t_ok ybih.ttt matches 0 run tellraw @s {{TXT_S}}这个人现在没空，点【刷新名单】再看看{{TXT_M}}gray{{TXT_E}}',
  );
  lines.push('');
  lines.push('# 我若还停在「刚下完」（上一局的对手还在等着再来一局），先把它作废再登记新的。');
  lines.push('# 不先清掉，旧对手那边会一直等不到我，得靠每秒核对才发现 —— 这里当场收干净。');
  lines.push('# abort 里那句通知正好是发给旧对手的：他会当场知道这局散了，不必干等着');
  lines.push(
    `execute if score #t_ok ybih.ttt matches 1 if score @s ${T_STATE} matches ${ST_DONE} run function ybih:room/ttt_abort`,
  );
  lines.push('');
  lines.push('# 取出我自己的编号与名单位，后面要写进对方那边');
  lines.push(
    'execute if score #t_ok ybih.ttt matches 1 run scoreboard players operation #me ybih.ttt = @s ybih.id',
  );
  lines.push(
    `execute if score #t_ok ybih.ttt matches 1 run scoreboard players operation #myslot ybih.ttt = @s ${T_SEAT}`,
  );
  lines.push('# 对方编号从名单位上直接读出来');
  for (const his of openStates) {
    lines.push(
      `execute if score #t_ok ybih.ttt matches 1 ${AT_ROOM} as ${seatIn(i, his, ',limit=1')} run scoreboard players operation #t_opp ybih.ttt = @s ybih.id`,
    );
  }
  lines.push('');
  lines.push('# 我这边：登记邀请');
  lines.push(
    `execute if score #t_ok ybih.ttt matches 1 run scoreboard players operation @s ${T_OPP} = #t_opp ybih.ttt`,
  );
  lines.push(`execute if score #t_ok ybih.ttt matches 1 run scoreboard players set @s ${T_OPPS} ${i}`);
  lines.push(
    `execute if score #t_ok ybih.ttt matches 1 run scoreboard players set @s ${T_STATE} ${ST_INVITED}`,
  );
  lines.push(`execute if score #t_ok ybih.ttt matches 1 run scoreboard players set @s ${T_TOLD} 0`);
  lines.push('');
  lines.push('# 他那边：登记「有人邀请我」。这一步同样要过 #t_ok ——');
  lines.push('# 少了它，邀请没成功也照样把对方置成「有人邀请我」，导出一个假的邀请')
  for (const st of [ST_FREE, ST_DONE]) {
    const prefix = `execute if score #t_ok ybih.ttt matches 1 ${AT_ROOM} as ${seatIn(i, st, ',limit=1')}`;
    lines.push(`${prefix} run scoreboard players operation @s ${T_OPP} = #me ybih.ttt`);
    lines.push(`${prefix} run scoreboard players operation @s ${T_OPPS} = #myslot ybih.ttt`);
    lines.push(`${prefix} run scoreboard players set @s ${T_STATE} ${ST_INVITING}`);
    lines.push(`${prefix} run scoreboard players set @s ${T_TOLD} 0`);
  }
  lines.push('');
  lines.push('execute if score #t_ok ybih.ttt matches 1 run function ybih:room/ttt_status');
  return file(...lines);
}

// ── 同意 / 再来 ──────────────────────────────────────────────────

function genTttAccept() {
  const lines = [
    '# ybih:room/ttt_accept —— 同意邀请：定角色、开局',
    '# 邀请方执 ✕、受邀方执 ◯ —— 谁主动邀请是玩家自己的选择，不必再掷随机',
    '# 找到邀请方只能按编号找：他的 topp 正指着我',
    '',
    'scoreboard players operation #me ybih.ttt = @s ybih.id',
    'scoreboard players set #t_ok ybih.ttt 0',
    `execute if score @s ${T_STATE} matches ${ST_INVITING} if score @s ${T_OPP} matches 1.. run scoreboard players set #t_ok ybih.ttt 1`,
    '# 邀请方必须还在房里、还指着我、并且还停在「已邀请」上；三条缺一不可',
    `execute if score #t_ok ybih.ttt matches 1 run scoreboard players set #t_found ybih.ttt 0`,
    `execute if score #t_ok ybih.ttt matches 1 ${AT_ROOM} as @a[tag=ybih_player,scores={${T_STATE}=${ST_INVITED}},distance=..12] if score @s ${T_OPP} = #me ybih.ttt run scoreboard players set #t_found ybih.ttt 1`,
    `execute if score #t_ok ybih.ttt matches 1 if score #t_found ybih.ttt matches 0 run scoreboard players set #t_ok ybih.ttt 0`,
    '',
    'execute if score #t_ok ybih.ttt matches 0 run tellraw @s {{TXT_S}}这个邀请已经失效了，点【刷新名单】重新挑人{{TXT_M}}gray{{TXT_E}}',
    '',
    '# 角色：我执 ◯，邀请方执 ✕。先手统一从 ✕ 开始，ttt_start 每开一局翻一面',
    `execute if score #t_ok ybih.ttt matches 1 run scoreboard players set @s ${T_ROLE} ${ROLE_O}`,
    `execute if score #t_ok ybih.ttt matches 1 run scoreboard players set @s ${T_FIRST} ${ROLE_X}`,
    `execute if score #t_ok ybih.ttt matches 1 ${AT_ROOM} as @a[tag=ybih_player,scores={${T_STATE}=${ST_INVITED}},distance=..12] if score @s ${T_OPP} = #me ybih.ttt run scoreboard players set @s ${T_ROLE} ${ROLE_X}`,
    `execute if score #t_ok ybih.ttt matches 1 ${AT_ROOM} as @a[tag=ybih_player,scores={${T_STATE}=${ST_INVITED}},distance=..12] if score @s ${T_OPP} = #me ybih.ttt run scoreboard players set @s ${T_FIRST} ${ROLE_X}`,
    'execute if score #t_ok ybih.ttt matches 1 run function ybih:room/ttt_start',
  ];
  return file(...lines);
}

function genTttAgain() {
  const lines = [
    '# ybih:room/ttt_again —— 再来一局：同一对手原地重开，先手换人',
    '# 两个人都停在「刚下完」而且互相指着对方，才开得起来',
    '',
    'scoreboard players operation #me ybih.ttt = @s ybih.id',
    `scoreboard players operation #topp ybih.ttt = @s ${T_OPP}`,
    'scoreboard players set #t_ok ybih.ttt 0',
    `execute if score @s ${T_STATE} matches ${ST_DONE} if score @s ${T_OPP} matches 1.. ${AT_ROOM} as @a[tag=ybih_player,scores={${T_STATE}=${ST_DONE}},distance=..12] if score @s ybih.id = #topp ybih.ttt if score @s ${T_OPP} = #me ybih.ttt run scoreboard players set #t_ok ybih.ttt 1`,
    'execute if score #t_ok ybih.ttt matches 0 run tellraw @s {{TXT_S}}对手还没准备好，或者他已经离开了{{TXT_M}}gray{{TXT_E}}',
    'execute if score #t_ok ybih.ttt matches 1 run function ybih:room/ttt_start',
  ];
  return file(...lines);
}

// 退出这一局：拒绝邀请 / 取消邀请 / 对局中离座，机械上都是「把这一对拆掉」
function genTttExit(name, head, message, notes = []) {
  return file(
    `# ybih:room/${name} —— ${head}`,
    ...notes.map((s) => `# ${s}`),
    '# 机械上都是「把这一对拆掉」：先把自己的话说了，再让 ttt_abort 收干净两边。',
    '# 这两句通知的收件人不同 —— 上面那句给执行者、abort 里那句给对手，',
    '# 所以没有「说重了」的问题，任何形式的抑制开关都是多余的',
    '',
    `execute if score @s ${T_STATE} matches 1.. run tellraw @s {{TXT_S}}${message}{{TXT_M}}yellow{{TXT_E}}`,
    'function ybih:room/ttt_abort',
  );
}

// ── 刷新 ─────────────────────────────────────────────────────────

function genTttRefresh() {
  return file(
    '# ybih:room/ttt_refresh —— 【刷新名单】：补名单位、重贴名单、再贴一次自己的状态',
    '# 这就是给书加的那个刷新机制：书页内容改不动，但按一下就能让聊天栏跟上房里现在的情况。',
    '# 没有名单位的人（进房时满员、或位子被收回）在这里补一个 ——',
    '# 免得出现「名单上有别人、别人却点不到你」',
    '',
    'function ybih:room/ttt_seat',
    'function ybih:room/ttt_roster',
    'function ybih:room/ttt_status',
    `execute if score @s ${T_STATE} matches ${ST_PLAYING} run function ybih:room/ttt_board`,
  );
}

// ── 只看棋盘 ─────────────────────────────────────────────────────

function genTttShow() {
  return file(
    '# ybih:room/ttt_show —— 【看我的棋盘】：只把棋盘重贴一遍，不动状态、不贴名单',
    '# 与 ttt_refresh 的区别是不重贴名单 —— 只想把被刷上去的棋盘找回来时用它，话少',
    '# 对局中贴棋盘；刚下完也贴（能看到最后一手）；还没开局就说清楚现在没得看',
    '',
    `execute if score @s ${T_STATE} matches ${ST_PLAYING} run function ybih:room/ttt_board`,
    `execute if score @s ${T_STATE} matches ${ST_DONE} run function ybih:room/ttt_board`,
    `execute if score @s ${T_STATE} matches 0 run tellraw @s {{TXT_S}}你还没开局，先在名单里点某个人的【邀请】{{TXT_M}}gray{{TXT_E}}`,
    `execute if score @s ${T_STATE} matches ${ST_INVITED} run tellraw @s {{TXT_S}}还在等对方点头，开局后就有棋盘了{{TXT_M}}gray{{TXT_E}}`,
    `execute if score @s ${T_STATE} matches ${ST_INVITING} run tellraw @s {{TXT_S}}先点【同意】开局，棋盘就出来了{{TXT_M}}gray{{TXT_E}}`,
  );
}

// ── 复位 ─────────────────────────────────────────────────────────

const FAKES = [
  '#t_pick',
  '#me',
  '#topp',
  '#mturn',
  '#mres',
  '#need',
  '#tok',
  '#tslot',
  '#t_move',
  '#t_tmp',
  '#t_ok',
  '#t_found',
  '#has_opp',
  '#t_opp',
  '#myslot',
  '#opprole',
];

function genTttReset() {
  const lines = [
    '# ybih:room/ttt_reset —— 棋局全部归零：每个人的棋盘与状态、名单位，以及全部暂存',
    '# 每一处「清空对局数据」的地方都要调它，少一处就会把上一局的残局带进下一局',
    '',
  ];
  for (const obj of [T_STATE, T_ROLE, T_OPP, T_OPPS, T_TURN, T_RES, T_FIRST, T_TOLD]) {
    lines.push(`scoreboard players set @a ${obj} 0`);
  }
  // 名单位用 reset * 而不是 set @a 0：@a 够不到离线玩家，掉线者身上那份旧的 rseat
  // 会跨过这次清零留下来，他重连时就会顶掉别人已经坐上的号（见 room/ttt_seat）
  lines.push(`scoreboard players reset * ${T_SEAT}`);
  // 再给在线的人补一个 0 —— 两条缺一不可：
  // reset * 删掉的是**条目本身**，而「读一个不存在的条目」会让 operation 静默失败、
  // 目标保留旧值（ttt_invite 里 `#myslot = @s rseat` 就踩这个）。补上 0 之后
  // 在线者的读必定成功，离线者则保持「没有条目」，重连时照样会被重新分配
  lines.push(`scoreboard players set @a ${T_SEAT} 0`);
  for (let n = 1; n <= TTT_CELLS; n += 1) {
    lines.push(`scoreboard players set @a ${cell(n)} 0`);
  }
  lines.push('');
  lines.push('# 全局暂存一并归零，免得上一局的半截值被下一局读到');
  const fakes = [...FAKES];
  for (let n = 1; n <= TTT_CELLS; n += 1) fakes.push(`#m${n}`);
  for (let i = 1; i <= TTT_ROSTER; i += 1) fakes.push(`#rs${i}`);
  for (const f of fakes) {
    lines.push(`scoreboard players set ${f} ybih.ttt 0`);
  }
  return file(...lines);
}

// ── 每秒调度 ─────────────────────────────────────────────────────

function genTttTick() {
  return file(
    '# ybih:room/ttt_tick —— 每秒三件事：核对对局、提示邀请、收回离场者的名单位',
    '# 由 room/second_tick 每秒调用；所有判断都按 @s 取数，与同时开了几局无关',
    '',
    '# ① 在房里且有局面的人：算对手名单位 + 核对这一局还在不在',
    `execute ${AT_ROOM} as @a[tag=ybih_player,tag=!ybih_current,scores={${T_STATE}=1..},distance=..12] run function ybih:room/ttt_verify`,
    '# ② 刚进入邀请状态的人：提示一次（told 标记防重发）',
    `execute ${AT_ROOM} as @a[tag=ybih_player,tag=!ybih_current,scores={${T_STATE}=1..2},distance=..12] run function ybih:room/ttt_notice`,
    '',
    '# ③ 不在房里却还挂着局面的（被拎去藏、走出房间、掉线重连）一律作废',
    `execute ${AT_ROOM} as @a[tag=ybih_player,scores={${T_STATE}=1..}] unless entity @s[distance=..12] run function ybih:room/ttt_abort`,
    '# 名单位跟着收回：离开房间的人不该再占着一个位子。',
    '# 掉线的人够不到（@a 只遍历在线玩家），他那份 rseat 会留到下次开局或轮末的',
    '# ttt_reset —— 那一步用的是 reset *，离线的人一样清得掉',
    `execute ${AT_ROOM} as @a[tag=ybih_player,scores={${T_SEAT}=1..}] unless entity @s[distance=..12] run function ybih:room/ttt_release`,
  );
}

// ── 说明书 ───────────────────────────────────────────────────────

function genTttBook(pack, tttBookCommand) {
  return file(
    '# ybih:room/ttt_book —— 发一本《九宫格棋》',
    '# 聊天栏里的棋盘与名单都会被后面的消息顶上去，书是随时能翻开的常驻入口',
    '# 每人只发一次：等待室每轮换人都可能重走一遍这里，不设门会变成人手一摞书。',
    '# 书里塞不进玩家名（书页内容构建期就写死了），所以选人只能在聊天栏；',
    '# 书里放的是玩法说明与【刷新名单】',
    '',
    `execute unless entity @s[tag=ybih_ttt_booked] run ${tttBookCommand(pack)}`,
    'tag @s add ybih_ttt_booked',
  );
}

// ── 汇总 ─────────────────────────────────────────────────────────

export function buildTttGenerated(tttBookCommand) {
  const out = {
    'data/ybih/function/room/ttt_board.mcfunction': () => genTttBoard(),
    'data/ybih/function/room/ttt_click.mcfunction': () => genTttClick(),
    'data/ybih/function/room/ttt_sync.mcfunction': () => genTttSync(),
    'data/ybih/function/room/ttt_start.mcfunction': () => genTttStart(),
    'data/ybih/function/room/ttt_abort.mcfunction': () => genTttAbort(),
    'data/ybih/function/room/ttt_verify.mcfunction': () => genTttVerify(),
    'data/ybih/function/room/ttt_status.mcfunction': () => genTttStatus(),
    'data/ybih/function/room/ttt_notice.mcfunction': () => genTttNotice(),
    'data/ybih/function/room/ttt_roster.mcfunction': () => genTttRoster(),
    'data/ybih/function/room/ttt_seat.mcfunction': () => genTttSeat(),
    'data/ybih/function/room/ttt_release.mcfunction': () => genTttRelease(),
    'data/ybih/function/room/ttt_invite.mcfunction': () => genTttInviteDispatch(),
    'data/ybih/function/room/ttt_refresh.mcfunction': () => genTttRefresh(),
    'data/ybih/function/room/ttt_show.mcfunction': () => genTttShow(),
    'data/ybih/function/room/ttt_accept.mcfunction': () => genTttAccept(),
    'data/ybih/function/room/ttt_again.mcfunction': () => genTttAgain(),
    'data/ybih/function/room/ttt_decline.mcfunction': () =>
      genTttExit('ttt_decline', '拒绝邀请', '已经拒绝了他的邀请'),
    'data/ybih/function/room/ttt_cancel.mcfunction': () =>
      genTttExit('ttt_cancel', '取消自己发出的邀请', '已经取消邀请'),
    'data/ybih/function/room/ttt_leave.mcfunction': () =>
      genTttExit('ttt_leave', '离座：退出当前这一局', '你退出了这一局', [
        '对局中、刚下完、以及还在等对方点头的时候都能按',
      ]),
    'data/ybih/function/room/ttt_reset.mcfunction': () => genTttReset(),
    'data/ybih/function/room/ttt_tick.mcfunction': () => genTttTick(),
    'data/ybih/function/room/ttt_book.mcfunction': (pack) => genTttBook(pack, tttBookCommand),
  };
  for (let i = 1; i <= TTT_ROSTER; i += 1) {
    out[`data/ybih/function/room/ttt_invite_${i}.mcfunction`] = () => genTttInvite(i);
  }
  return out;
}
