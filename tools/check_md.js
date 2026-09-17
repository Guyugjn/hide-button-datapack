const fs = require('fs');
const file = process.argv[2] || 'README.md';
const raw = fs.readFileSync(file, 'utf8');
const lines = raw.split('\n');
let issues = 0;

const bt = String.fromCharCode(96); // 反引号

// 连续空行
for (let i = 1; i < lines.length; i++) {
  if (lines[i] === '' && lines[i - 1] === '') {
    console.log('连续空行 @' + (i + 1));
    issues++;
  }
}

// 行内元素只检查围栏外的正文行；加粗允许跨行，按整篇配对
let inFence = false;
let boldCount = 0;
let prevHeading = 0;

lines.forEach((l, i) => {
  const fence = l.trimStart().startsWith(bt + bt + bt);
  if (fence) {
    inFence = !inFence;
    return;
  }
  if (inFence) return;

  if (/^-\s*$/.test(l)) {
    console.log('空列表项 @' + (i + 1));
    issues++;
  }

  const nbt = l.split(bt).length - 1;
  if (nbt % 2 !== 0) {
    console.log('反引号不成对 @' + (i + 1) + ': ' + l.slice(0, 70));
    issues++;
  }

  boldCount += (l.match(/\*\*/g) || []).length;

  const m = l.match(/^(#{1,6})\s/);
  if (m) {
    const lvl = m[1].length;
    if (prevHeading && lvl > prevHeading + 1) {
      console.log('标题跳级 @' + (i + 1) + ': ' + l.slice(0, 60));
      issues++;
    }
    prevHeading = lvl;
  }
});

if (inFence) {
  console.log('代码围栏未闭合');
  issues++;
}
if (boldCount % 2 !== 0) {
  console.log('整篇加粗标记总数是奇数（' + boldCount + '），有未闭合的 **');
  issues++;
}

console.log(issues ? '\n共 ' + issues + ' 处问题' : '格式检查通过');
