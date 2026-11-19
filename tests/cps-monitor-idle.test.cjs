// Regression: the dashboard CPS monitor must not sample or draw while idle.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
const start=html.indexOf('const liveMonitor={');
const end=html.indexOf("window.addEventListener('resize',drawLiveMonitor);",start);
assert(start>=0&&end>start,'Live CPS monitoring section must exist');
const source=html.slice(start,end);
const elements=new Map(),paint={expanded:0,compact:0};
let time=1000;
function element(id) {
    const classes=new Set();
    return {
        id, textContent:'',
        classList:{
            toggle(name,enabled){if(enabled)classes.add(name);else classes.delete(name);},
            contains:name=>classes.has(name)
        },
        getBoundingClientRect(){return{width:460,height:115};},
        getContext(){
            return {
                setTransform(){},clearRect(){},
                beginPath(){},moveTo(){},lineTo(){},stroke(){
                    paint[id==='liveCpsChart'?'expanded':'compact']++;
                }
            };
        }
    };
}
function get(id) {
    if(!elements.has(id))elements.set(id,element(id));
    return elements.get(id);
}
get('liveCpsChart').classList.toggle('hidden',true);
get('compactCpsChart').classList.toggle('hidden',true);
const model={compact:false,preferences:{liveMonitor:true,compactChart:true}};
const context={
    $:get,model,config:()=>({hotkey:'F6'}),
    performance:{now:()=>time},window:{devicePixelRatio:1},
    Math,Number,String
};
vm.runInNewContext(source+
    '\n;globalThis.monitorTests={liveMonitor,drawLiveMonitor,updateLiveMonitor};',
    context,{timeout:3000,filename:'ClickFlow CPS idle monitor'});
const m=context.monitorTests;
function stats(cps,total=0){return {cps,total,armed:cps>0,waiting:false,hotkey:'F6'};}
for(let i=0;i<12;i++) {
    time+=200;
    m.updateLiveMonitor(stats(0,0));
}
assert.equal(m.liveMonitor.samples.length,0,'Idle must never collect samples');
assert.equal(m.liveMonitor.lastStamp,0,'Idle must not run sampling clock');
assert.equal(paint.expanded,0,'Idle must never paint a canvas');
assert.equal(get('liveCpsChart').classList.contains('hidden'),true);
assert.equal(get('liveMonitorIdle').classList.contains('hidden'),false);
time+=200;m.updateLiveMonitor(stats(9,3));
assert.equal(m.liveMonitor.active,true);
assert.equal(m.liveMonitor.samples.length,1);
assert(paint.expanded>0,'First real CPS must trigger graph rendering');
const paintBefore=paint.expanded;
time+=200;m.updateLiveMonitor(stats(14,8));
assert.equal(m.liveMonitor.samples.length,2);
assert(paint.expanded>paintBefore,'A subsequent CPS sample must redraw the graph');
const count=paint.expanded;
time+=200;m.updateLiveMonitor(stats(0,8));
assert.equal(m.liveMonitor.active,false);
assert.equal(m.liveMonitor.samples.length,0,'Last burst must be discarded on idle');
assert.equal(get('liveCpsChart').classList.contains('hidden'),true);
assert.equal(get('liveMonitorIdle').classList.contains('hidden'),false);
for(let i=0;i<12;i++){time+=200;m.updateLiveMonitor(stats(0,8));}
assert.equal(paint.expanded,count,'No extra rendering after activity stops');
assert.equal(get('compactClicks').textContent,'8','Total click count should remain visible');
model.compact=true;
time+=200;m.updateLiveMonitor(stats(4,12));
assert(paint.compact>0,'Compact graph must respond when real clicks arrive');
time+=200;m.updateLiveMonitor(stats(0,12));
const compactBefore=paint.compact;
model.preferences.compactChart=false;
time+=200;m.updateLiveMonitor(stats(6,18));
assert.equal(paint.compact,compactBefore,'Disabled compact graph should not render');
assert.equal(m.liveMonitor.samples.length,0,'Do not collect when graph is disabled');
console.log('CPS idle monitor sleeps at zero clicks, wakes on activity, and retains totals.');