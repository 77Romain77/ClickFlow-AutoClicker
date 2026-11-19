// Node.js regression tests for the real CPS tester JavaScript embedded in ui/index.html.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const html = fs.readFileSync(path.join(__dirname, '..', 'ui', 'index.html'), 'utf8');
const marker = '// Test CPS : clics manuels uniquement';
const start = html.indexOf(marker);
const end = html.indexOf("document.querySelectorAll('.nav-item').forEach", start);
assert(start >= 0 && end > start, 'CPS tester script must exist in the HTML');
const js = html.slice(start, end);

let time = 0;
let nextTimerId = 0;
const timers = new Map();
const messages = [];
const elements = new Map();
const durations = [2,5,10,30,60];
function element(id = '') {
    const events = {};
    const classes = new Set();
    const el = {
        id, events, className:'', style:{}, dataset:{}, disabled:false,
        textContent:'', children:[], width:900, height:250,
        classList:{
            add:v=>classes.add(v),
            remove:v=>classes.delete(v),
            contains:v=>classes.has(v),
            toggle(v,on) {
                if(on === undefined)on=!classes.has(v);
                if(on)classes.add(v);else classes.delete(v);
            }
        },
        addEventListener(name,callback){events[name]=callback;},
        setAttribute(){},
        appendChild(child){this.children.push(child);},
        replaceChildren(){this.children=[];},
        getBoundingClientRect(){return {left:0,top:0,width:850,height:250};},
        getContext(){
            return {
                setTransform(){},clearRect(){},beginPath(){},moveTo(){},lineTo(){},
                stroke(){},fill(){},fillText(){},closePath(){},
                createLinearGradient(){return {addColorStop(){}};}
            };
        },
        remove(){}
    };
    return el;
}
function get(id){
    if(!elements.has(id))elements.set(id,element(id));
    return elements.get(id);
}
const durationButtons = durations.map(n=>{
    const e=element('duration-'+n);
    e.dataset.cpsDuration=String(n);
    return e;
});
const ctx={
    performance:{now:()=>time},
    document:{
        getElementById:get,
        createElement:()=>element(),
        querySelectorAll:selector=>selector==='[data-cps-duration]'?durationButtons:[]
    },
    window:{
        devicePixelRatio:1,
        matchMedia:()=>({matches:false}),
        addEventListener(){}
    },
    connected:true,
    send:(...parts)=>messages.push(parts),
    setInterval:fn=>{const id=++nextTimerId;timers.set(id,fn);return id;},
    clearInterval:id=>timers.delete(id),
    setTimeout:()=>{},
    Date, Math, Number, String, Array, Set, console
};
vm.runInNewContext(js + '\n;globalThis.__cpsTestExports={cpsTest,cpsRender,cpsResetTest,cpsFinish};',ctx,
    {timeout:3000,filename:'ui/index.html CPS tester'});
const state=ctx.__cpsTestExports.cpsTest;
const clickArea=get('cpsClickArea');
assert.equal(state.seconds,5);
assert.equal(state.phase,'ready');
assert.equal(state.clicks.length,0);
function press(at, overrides={}) {
    time=at;
    let prevented=false;
    clickArea.events.pointerdown({
        pointerType:'mouse',button:0,isPrimary:true,clientX:50,clientY:50,
        preventDefault(){prevented=true;},...overrides
    });
    return prevented;
}
assert.equal(press(0,{button:2}),false,'Right-click should be ignored');
assert.equal(press(0,{pointerType:'touch'}),false,'Touch should be ignored');
assert.equal(press(0),true,'Left mouse press should be handled');
assert.equal(state.phase,'running');
assert.equal(state.clicks.length,1,'First click must count');
for(const t of [100,200,300,400])press(t);
assert.equal(state.clicks.length,5);
assert.equal(state.peak,5);
time=1000;
for(const callback of timers.values())callback();
assert.equal(get('cpsInstant').textContent,'4.0','Rolling CPS must drop oldest click after 1s');
time=5100;
for(const callback of [...timers.values()])callback();
assert.equal(state.phase,'done','Test must finish after chosen duration');
assert.equal(state.history.length,1);
assert.equal(state.history[0].average,1);
assert.equal(get('cpsAverage').textContent,'1.0');
assert.equal(get('cpsRemaining').textContent,'0.0 s restantes');
assert.equal(state.best[5],5);
assert(messages.some(x=>x.join('|')==='cpsTest|result|5|5'),'Result must reach AHK backend');
press(5300);
assert.equal(state.clicks.length,5,'Clicks after finish must be ignored');
durationButtons[0].onclick();
assert.equal(state.seconds,2);
assert.equal(state.phase,'ready');
press(6000);
press(6500);
time=8001;
for(const callback of [...timers.values()])callback();
assert.equal(state.phase,'done');
assert.equal(state.history.length,2);
assert.equal(state.history[0].seconds,2);
assert.equal(state.history[0].clicks,2);
assert.equal(get('cpsRecord').textContent,'1.0 CPS');
assert(messages.some(x=>x.join('|')==='cpsTest|result|2|2'));
get('cpsReset').onclick();
assert.equal(state.phase,'ready');
assert.equal(state.clicks.length,0);
assert.equal(state.history.length,2,'Restart must preserve session history');
console.log('CPS test durations, left-only input, 1s rolling CPS, records and chart passed.');
