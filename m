<!DOCTYPE html>
<html lang="uz">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Olma qurti</title>
<style>
:root{
  --bg:#dff0c8; --board:#a9d46f; --board2:#9ccb60; --ink:#27401a; --worm:#e8806a; --worm2:#c75f4b; --apple:#d6342c; --card:#f6fbe9;
  color-scheme: light;
  box-sizing:border-box;
  padding-top:env(safe-area-inset-top,0px);
  padding-bottom:env(safe-area-inset-bottom,0px);
}
@media (prefers-color-scheme: dark){
  :root:not([data-theme="light"]){
    --bg:#1b2a14; --board:#3f6b2a; --board2:#386226; --ink:#e6f3d3; --worm:#f0907a; --worm2:#d46f59; --apple:#ff5a4d; --card:#26391c; color-scheme: dark;
  }
}
:root[data-theme="dark"]{
  --bg:#1b2a14; --board:#3f6b2a; --board2:#386226; --ink:#e6f3d3; --worm:#f0907a; --worm2:#d46f59; --apple:#ff5a4d; --card:#26391c; color-scheme: dark;
}
*{box-sizing:border-box}
html{scroll-padding-top:env(safe-area-inset-top,0px)}
body{margin:0;min-height:100vh;background:var(--bg);color:var(--ink);font-family:"Trebuchet MS","Segoe UI",system-ui,sans-serif;display:flex;flex-direction:column;align-items:center;padding:16px;gap:12px}
h1{margin:4px 0 0;font-size:1.7rem;font-weight:800;letter-spacing:.2px}
.bar{display:flex;gap:10px;width:min(92vw,440px);justify-content:space-between}
.pill{background:var(--card);border-radius:999px;padding:6px 16px;font-weight:700}
.wrap{position:relative;width:min(92vw,440px);aspect-ratio:1}
canvas{width:100%;height:100%;border-radius:18px;display:block;background:var(--board);touch-action:none}
.overlay{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;background:rgba(20,35,10,.55);border-radius:18px;color:#fff;text-align:center;padding:20px}
.overlay.hidden{display:none}
.overlay h2{margin:0;font-size:1.6rem}
.overlay p{margin:0;max-width:30ch}
button{font:inherit;font-weight:800;border:0;border-radius:12px;padding:10px 22px;background:var(--apple);color:#fff;cursor:pointer}
button:focus-visible{outline:3px solid var(--ink);outline-offset:2px}
.pad{display:grid;grid-template-columns:repeat(3,64px);grid-template-rows:repeat(2,56px);gap:8px}
.pad button{background:var(--card);color:var(--ink);font-size:1.3rem;padding:0}
.pad .u{grid-column:2;grid-row:1}
.pad .l{grid-column:1;grid-row:2}
.pad .d{grid-column:2;grid-row:2}
.pad .r{grid-column:3;grid-row:2}
.hint{margin:0;font-size:.9rem;opacity:.8;text-align:center}
</style>
</head>
<body>
<h1>🍎 Olma qurti</h1>
<div class="bar"><div class="pill">Hisob: <span id="score">0</span></div><div class="pill">Rekord: <span id="best">0</span></div></div>
<div class="wrap">
  <canvas id="c" width="440" height="440"></canvas>
  <div class="overlay" id="ov">
    <h2 id="ovt">Olma qurti</h2>
    <p id="ovp">Qurtni boshqarib, olmalarni yeng. Devor va o’zingizga urilmang.</p>
    <button id="go">Boshlash</button>
  </div>
</div>
<div class="pad" aria-label="Boshqaruv">
  <button class="u" data-d="up" aria-label="Yuqoriga">▲</button>
  <button class="l" data-d="left" aria-label="Chapga">◀</button>
  <button class="d" data-d="down" aria-label="Pastga">▼</button>
  <button class="r" data-d="right" aria-label="O’ngga">▶</button>
</div>
<p class="hint">Strelkalar yoki W A S D tugmalari. Pauza: probel.</p>
<script>
(function(){
  var cv=document.getElementById('c'), ctx=cv.getContext('2d');
  var N=16, S=cv.width/N;
  var scoreEl=document.getElementById('score'), bestEl=document.getElementById('best');
  var ov=document.getElementById('ov'), ovt=document.getElementById('ovt'), ovp=document.getElementById('ovp'), go=document.getElementById('go');
  var worm, dir, next, apple, score, best=0, timer, running=false, paused=false, speed=140;
  try{ best=parseInt(localStorage.getItem('olmaqurti-best'),10)||0; }catch(e){}
  bestEl.textContent=best;
  var V={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]};

  function css(n){return getComputedStyle(document.documentElement).getPropertyValue(n).trim();}
  function reset(){
    worm=[{x:6,y:8},{x:5,y:8},{x:4,y:8}]; dir=V.right; next=dir; score=0; speed=140;
    scoreEl.textContent=0; placeApple();
  }
  function placeApple(){
    var f; do{ f={x:Math.floor(Math.random()*N),y:Math.floor(Math.random()*N)}; }
    while(worm.some(function(s){return s.x===f.x&&s.y===f.y;}));
    apple=f;
  }
  function turn(name){
    var d=V[name]; if(!d) return;
    if(d[0]===-dir[0]&&d[1]===-dir[1]) return;
    next=d;
  }
  function tick(){
    if(paused) return;
    dir=next;
    var h={x:worm[0].x+dir[0],y:worm[0].y+dir[1]};
    var eat=(h.x===apple.x&&h.y===apple.y);
    var body=eat?worm:worm.slice(0,-1);
    if(h.x<0||h.y<0||h.x>=N||h.y>=N||body.some(function(s){return s.x===h.x&&s.y===h.y;})){ return over(); }
    worm.unshift(h);
    if(eat){
      score++; scoreEl.textContent=score;
      if(score>best){best=score;bestEl.textContent=best;try{localStorage.setItem('olmaqurti-best',best);}catch(e){}}
      speed=Math.max(70,speed-4); placeApple(); restart();
    } else worm.pop();
    draw();
  }
  function restart(){ clearInterval(timer); timer=setInterval(tick,speed); }
  function start(){
    reset(); running=true; paused=false; ov.classList.add('hidden'); restart(); draw();
  }
  function over(){
    running=false; clearInterval(timer);
    ovt.textContent='O’yin tugadi'; ovp.textContent='Hisobingiz: '+score+' ta olma.'; go.textContent='Qayta o’ynash';
    ov.classList.remove('hidden'); draw();
  }
  function pause(){
    if(!running) return;
    paused=!paused;
    if(paused){ ovt.textContent='Pauza'; ovp.textContent='Davom etish uchun probel yoki tugmani bosing.'; go.textContent='Davom etish'; ov.classList.remove('hidden'); }
    else ov.classList.add('hidden');
  }
  function draw(){
    var a=css('--board'), b=css('--board2');
    for(var y=0;y<N;y++)for(var x=0;x<N;x++){ ctx.fillStyle=(x+y)%2?a:b; ctx.fillRect(x*S,y*S,S,S); }
    // apple
    var ax=apple.x*S+S/2, ay=apple.y*S+S/2+1;
    ctx.fillStyle=css('--apple'); ctx.beginPath(); ctx.arc(ax-4,ay,S*.34,0,7); ctx.arc(ax+4,ay,S*.34,0,7); ctx.fill();
    ctx.strokeStyle='#5a3a1a'; ctx.lineWidth=2.5; ctx.beginPath(); ctx.moveTo(ax,ay-S*.3); ctx.lineTo(ax+2,ay-S*.5); ctx.stroke();
    ctx.fillStyle='#3f9a35'; ctx.beginPath(); ctx.ellipse(ax+7,ay-S*.42,6,3,-.5,0,7); ctx.fill();
    // worm
    for(var i=worm.length-1;i>=0;i--){
      var s=worm[i], cx=s.x*S+S/2, cy=s.y*S+S/2, r=S*(i===0?.46:.42);
      ctx.fillStyle=i%2?css('--worm2'):css('--worm');
      ctx.beginPath(); ctx.arc(cx,cy,r,0,7); ctx.fill();
    }
    var h=worm[0], hx=h.x*S+S/2, hy=h.y*S+S/2, px=-dir[1]*6, py=dir[0]*6;
    [[1,1],[-1,-1]].forEach(function(k,idx){
      var ex=hx+dir[0]*4+(idx?-px:px), ey=hy+dir[1]*4+(idx?-py:py);
      ctx.fillStyle='#fff'; ctx.beginPath(); ctx.arc(ex,ey,4.2,0,7); ctx.fill();
      ctx.fillStyle='#222'; ctx.beginPath(); ctx.arc(ex+dir[0]*1.5,ey+dir[1]*1.5,2,0,7); ctx.fill();
    });
  }
  go.addEventListener('click',function(){ if(running&&paused) pause(); else start(); });
  document.addEventListener('keydown',function(e){
    var m={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right',w:'up',s:'down',a:'left',d:'right',W:'up',S:'down',A:'left',D:'right'};
    if(m[e.key]){ e.preventDefault(); if(!running&&ov.classList.contains('hidden')===false&&false){} turn(m[e.key]); }
    else if(e.key===' '){ e.preventDefault(); if(!running) start(); else pause(); }
  });
  document.querySelectorAll('.pad button').forEach(function(b){
    b.addEventListener('click',function(){ turn(b.dataset.d); });
  });
  var tx,ty;
  cv.addEventListener('touchstart',function(e){tx=e.touches[0].clientX;ty=e.touches[0].clientY;},{passive:true});
  cv.addEventListener('touchend',function(e){
    var dx=e.changedTouches[0].clientX-tx, dy=e.changedTouches[0].clientY-ty;
    if(Math.max(Math.abs(dx),Math.abs(dy))<20) return;
    turn(Math.abs(dx)>Math.abs(dy)?(dx>0?'right':'left'):(dy>0?'down':'up'));
  },{passive:true});
  reset(); draw();
})();
</script>
</body>
</html>
