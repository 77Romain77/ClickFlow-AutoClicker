// Regression tests for CPS test UI (profile engine + manual mode + sound).
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'..','ui','index.html'),'utf8');
const start=html.indexOf('// Test CPS : profil ClickFlow ou souris manuelle');
const end=html.indexOf('function navigatePage(page) {',start);
assert(start>=0&&end>start,'CPS JavaScript section must exist');
const script=html.slice(start,end);
const rapidBegin=html.indexOf('const rapidPresets=');
const rapidEnd=html.indexOf('function rapidChange(',rapidBegin);
assert(rapidBegin>=0&&rapidEnd>rapidBegin,'Rapid naturel helpers missing');
const rapidHelpers=html.slice(rapidBegin,rapidEnd);
let time=0, timerId=0, sounds=0;
const timers=new Map(),sent=[],nodes=new Map();
const durations=[2,5,10,30,60];
function node(id='') {
    const events={},classes=new Set();
    const el={
        id,style:{},dataset:{},value:'',textContent:'',disabled:false,hidden:false,
        children:[],events,className:'',onclick:null,
        classList:{
            add:x=>classes.add(x),remove:x=>classes.delete(x),
            contains:x=>classes.has(x),
            toggle(x,on){if(on===undefined)on=!classes.has(x);on?classes.add(x):classes.delete(x);}
        },
        addEventListener(n,f){events[n]=f;},
        setAttribute(){},append(...children){this.children.push(...children);
            if(this.id==='cpsProfileSelect'&&children.length&&this.value==='')this.value=children[0].value;
        },
        appendChild(child){this.children.push(child);return child;},
        replaceChildren(){this.children=[];this.value='';},
        remove(){},getBoundingClientRect(){return{left:0,top:0,width:900,height:250};},
        getContext(){return{
            setTransform(){},clearRect(){},beginPath(){},moveTo(){},lineTo(){},
            stroke(){},fill(){},fillText(){},closePath(){},
            createLinearGradient(){return{addColorStop(){}};}
        };}
    };
    return el;
}
const get=id=>{
    if(!nodes.has(id))nodes.set(id,node(id));
    return nodes.get(id);
};
const durationButtons=durations.map(d=>{
    const n=node();n.dataset.cpsDuration=String(d);return n;
});
class MockAudioContext {
    constructor(){this.sampleRate=48000;this.currentTime=0;this.state='running';this.destination={};}
    createBuffer(channels,count){return{getChannelData:()=>new Float32Array(count)};}
    createBufferSource(){return{connect(){},start(){sounds++;},disconnect(){},onended:null};}
    resume(){return Promise.resolve();}
}
const ctx={
    $:get,
    model:{profiles:[{id:1,name:'Principal',settings:{mode:'natural',min:8,max:14,intensity:'medium'}},{id:2,name:'Gaming',settings:{mode:'fixed',min:10,max:10,intensity:'low'}}],selected:1},
    document:{
        getElementById:get,createElement:()=>node(),
        querySelector:s=>{
            const match=s.match(/^\[data-cps-duration="(\d+)"\]$/);
            return match?durationButtons.find(x=>x.dataset.cpsDuration===match[1]):null;
        },
        querySelectorAll:s=>s==='[data-cps-duration]'?durationButtons:[]
    },
    window:{
        devicePixelRatio:1,AudioContext:MockAudioContext,
        matchMedia:()=>({matches:false}),addEventListener(){}
    },
    performance:{now:()=>time},connected:true,send:(...args)=>sent.push(args),
    toast:()=>{},setTimeout:()=>{},
    setInterval:f=>{let id=++timerId;timers.set(id,f);return id;},
    clearInterval:id=>timers.delete(id),
    Math,Number,String,Array,console
};
vm.runInNewContext(rapidHelpers+'\n'+script+
    '\n;globalThis.exports={cpsTest,cpsRender,cpsResetTest,cpsFinish,cpsSetSource,cpsHandleEngineMessage,cpsHandleRealMessage,cpsQuickLoad,cpsIntervalStats};',
    ctx,{timeout:3000,filename:'ui/index.html CPS test'});
const api=ctx.exports,st=api.cpsTest;
const quickMode=get('cpsQuickMode');
assert.equal(quickMode.value,'natural','Quick editor starts with selected profile mode');
get('cpsQuickMin').value='9';
get('cpsQuickMin').events.input();
assert.equal(get('cpsQuickApply').disabled,false,'Draft should allow apply');
assert.equal(get('cpsStartProfile').disabled,true,'Unsaved draft must block tests');
get('cpsQuickRevert').onclick();
assert.equal(get('cpsQuickMin').value,8,'Cancel restores saved settings');
assert.equal(get('cpsStartProfile').disabled,false);
get('cpsQuickMax').value='5';
get('cpsQuickMax').events.input();
assert.equal(get('cpsQuickApply').disabled,true,'Invalid min/max must not apply');
get('cpsQuickRevert').onclick();
get('cpsQuickMode').value='random';
get('cpsQuickMode').events.change();
get('cpsQuickApply').onclick();
assert.equal(sent.at(-1)[0],'quickSettings','Apply must send atomic config update');
assert.equal(sent.at(-1)[1],1,'Apply must target selected profile');
assert.equal(sent.at(-1)[2],'random');
sent.pop();

// RPM calculator in the quick profile editor must preserve decimal targets.
const original=ctx.model.profiles[0].settings;
ctx.model.profiles[0].settings={...original,mode:'rapid',rapidTarget:10,
    rapidRpm:0,rapidPreset:'custom',rapidBetween:10,rapidWithin:5};
api.cpsQuickLoad();
assert.equal(get('cpsQuickMinLabel').textContent,'CPS cible');
assert.equal(get('cpsQuickRapidRpmWrap').classList.contains('hidden'),false);
get('cpsQuickRapidRpm').value='750';
get('cpsQuickRapidRpm').events.input();
assert.equal(get('cpsQuickApply').disabled,true,'An unapplied RPM cannot be saved with a stale CPS target');
get('cpsQuickRapidRpmApply').onclick();
assert.equal(get('cpsQuickMin').value,12.5);
assert.equal(get('cpsQuickApply').disabled,false);
get('cpsQuickApply').onclick();
assert.equal(sent.at(-1)[2],'rapid');
assert.equal(sent.at(-1)[6],12.5);
assert.equal(sent.at(-1)[10],750);
sent.pop();
ctx.model.profiles[0].settings=original;
api.cpsQuickLoad();

assert.equal(st.source,'profile','A saved profile is the default mode');
assert.equal(get('cpsClickArea').disabled,true);
assert.equal(get('cpsProfileSelect').children.length,2,'Profiles must be selectable');
assert.equal(st.audioEnabled,true,'Gentle sound should be enabled by default');
get('cpsStartProfile').onclick();
assert.equal(st.phase,'pending');
const begin=sent.at(-1);
assert.equal(begin[0],'cpsTest');assert.equal(begin[1],'start');
assert.equal(begin[2],5);assert.equal(begin[4],1);
let run=begin[3];
time=10;
api.cpsHandleEngineMessage({type:'cpsTest',state:'started',run,profile:'Principal'});
assert.equal(st.phase,'running');
time=510;
api.cpsHandleEngineMessage({state:'ticks',run,ticks:[0,50,100,150,200]});
assert.equal(st.clicks.length,5,'Engine ticks should drive the graph and count');
assert.equal(api.cpsIntervalStats(st.clicks).average,50);
assert.equal(api.cpsIntervalStats(st.clicks).min,50);
assert.equal(api.cpsIntervalStats(st.clicks).max,50);
assert(get('cpsIntervalsSummary').textContent.includes('50.00 ms'),
    'Simulation must show intervals from actual engine ticks');
assert.equal(st.peak,5);
assert.equal(sounds,5,'Every generated click should play its subtle sound');
time=5110;
api.cpsHandleEngineMessage({state:'finished',run,ticks:[0,50,100,150,200]});
assert.equal(st.phase,'done');
assert.equal(st.last.clicks,5);
assert.equal(st.last.profile,'Principal');
assert.equal(st.last.average,1);
assert.equal(get('cpsLast').textContent.includes('Principal'),true);
assert.equal(sent.length,1,'Results must never be sent to disk storage');
const last=st.last;
get('cpsReset').onclick();
assert.equal(st.phase,'ready');
assert.equal(st.last,last,'Reset should preserve the last finished result');
get('cpsSound').onclick();
assert.equal(st.audioEnabled,false);
get('cpsSound').onclick();
assert.equal(st.audioEnabled,true);
get('cpsProfileSelect').value='2';
durationButtons[0].onclick();
assert.equal(st.seconds,2);
get('cpsStartProfile').onclick();
const secondRun=sent.at(-1)[3];
assert.equal(sent.at(-1)[4],2,'Selected profile id should reach the engine');
time=5200;
api.cpsHandleEngineMessage({state:'started',run:secondRun,profile:'Gaming'});
api.cpsHandleEngineMessage({state:'ticks',run:secondRun,ticks:[0,100]});
const previousCount=st.clicks.length;
api.cpsHandleEngineMessage({state:'ticks',run,ticks:[100,200]});
assert.equal(st.clicks.length,previousCount,'Messages from an old run must be ignored');
get('cpsReset').onclick();
assert.equal(sent.at(-1)[1],'stop','Reset must stop the engine');
assert.equal(st.phase,'ready');
assert.equal(st.last,last,'Aborting a run must preserve the last completed one');
api.cpsHandleEngineMessage({state:'finished',run:secondRun,ticks:[0,100]});
assert.equal(st.phase,'ready','A late finish must not revive a cancelled test');
api.cpsSetSource('manual');
assert.equal(st.source,'manual');
assert.equal(get('cpsClickArea').disabled,false);
function press(at,overrides={}){
    time=at;
    let prevented=false;
    get('cpsClickArea').events.pointerdown({
        pointerType:'mouse',button:0,isPrimary:true,clientX:80,clientY:80,
        preventDefault(){prevented=true;},...overrides
    });
    return prevented;
}
assert.equal(press(6000,{button:2}),false);
assert.equal(press(6000,{pointerType:'touch'}),false);
assert.equal(press(6000),true);
assert.equal(st.phase,'running');
assert.equal(st.clicks.length,1,'First manual click must count');
press(6200);press(6400);
time=8001;
for(const tick of [...timers.values()])tick();
assert.equal(st.phase,'done');
assert.equal(st.last.profile,'Clics manuels');
assert.equal(st.last.clicks,3);
assert.equal(st.last.average,1.5);
assert.equal(api.cpsIntervalStats(st.clicks).average,200);
assert(get('cpsIntervalsSummary').textContent.includes('200.00 ms'),
    'Manual clicks should be visualized independently of profile test');
assert.equal(get('cpsAverage').textContent,'1.5');
assert.equal(get('cpsLast').textContent.includes('3 clics'),true);
assert.equal(sent.filter(x=>x[1]==='result').length,0,'No scores should be persisted');
const sample=api.cpsIntervalStats([0,81,163,244,325]);
assert.equal(sample.min,81);
assert.equal(sample.max,82);
assert.equal(sample.average,81.25);
assert.equal(api.cpsIntervalStats([]).intervals.length,0);
assert.equal(api.cpsIntervalStats([15]).intervals.length,0);
assert.equal(api.cpsIntervalStats([0,10,30,60],2).intervals.length,2);
assert(html.includes('id="cpsIntervalsChart"')&&html.includes('id="cpsIntervalsSummary"'),
    'Click timeline and interval summary must be present in CPS tab');
// Reception reelle : bouton distinct, profil sélectionné et messages natifs.
api.cpsSetSource('real');
assert.equal(st.source,'real');
assert.equal(get('cpsClickArea').disabled,true,'Native receiver must not use WebView2 hit area');
assert.equal(get('cpsProfileControls').hidden,false);
assert.equal(get('cpsQuickSettings').hidden,false);
assert.equal(get('cpsStartReal').classList.contains('hidden'),false);
get('cpsStartReal').onclick();
assert.equal(st.phase,'pending');
const realStart=sent.at(-1);
assert.equal(realStart[0],'cpsReal');
assert.equal(realStart[1],'open');
const realRun=realStart[3];
api.cpsHandleRealMessage({state:'opened',run:realRun,profile:'Gaming',trigger:'LButton'});
assert.equal(st.phase,'pending','Native test starts only on a physical button-down');
time=8100;
api.cpsHandleRealMessage({state:'started',run:realRun,profile:'Gaming'});
assert.equal(st.phase,'running');
api.cpsHandleRealMessage({state:'ticks',run:realRun,sent:6,received:4,ticks:[0,20,40,60]});
assert.equal(st.clicks.length,4,'Only received Windows messages should contribute to CPS');
assert.equal(st.sent,6,'Sent clicks must be tracked separately from received');
assert.equal(get('cpsRealSent').textContent,'6');
assert.equal(get('cpsClicks').textContent,'4');
assert.equal(api.cpsIntervalStats(st.clicks).average,20);
api.cpsHandleRealMessage({state:'ticks',run:realRun-1,sent:999,received:999,ticks:[70]});
assert.equal(st.sent,6,'Messages from an old real test must be ignored');
time=10200;
api.cpsHandleRealMessage({state:'finished',run:realRun,duration:2,
    profile:'Gaming',sent:6,received:4,ticks:[0,20,40,60]});
assert.equal(st.phase,'done');
assert.equal(st.last.sent,6);
assert.equal(st.last.clicks,4);
assert.equal(st.last.source,'real');
assert(get('cpsLast').textContent.includes('6 envoyés / 4 reçus'));
assert(get('cpsPrecision').textContent.includes('fenêtre native'));
get('cpsReset').onclick();
assert.equal(st.phase,'ready');
get('cpsStartReal').onclick();
const abandonedRun=sent.at(-1)[3];
get('cpsReset').onclick();
assert.equal(sent.at(-1)[0],'cpsReal');
assert.equal(sent.at(-1)[1],'stop');
api.cpsHandleRealMessage({state:'finished',run:abandonedRun,duration:2,
    profile:'Gaming',sent:100,received:100,ticks:[0]});
assert.equal(st.phase,'ready','A cancelled native test cannot revive from late messages');
// Régression v1.9.28 : une confirmation native manquante ne doit plus
// effacer les mesures. Une confirmation tardive remplace le résultat provisoire.
get('cpsStartReal').onclick();
const recoverRun=sent.at(-1)[3];
time=15000;
api.cpsHandleRealMessage({state:'started',run:recoverRun,profile:'Gaming'});
api.cpsHandleRealMessage({state:'ticks',run:recoverRun,sent:5,received:4,
    ticks:[0,200,400,600]});
time=17380;
for(const tick of [...timers.values()])tick();
assert.equal(st.phase,'running','Native test must wait briefly for final confirmation');
assert(sent.some(x=>x[0]==='cpsReal'&&x[1]==='status'&&x[2]===recoverRun),
    'Frontend must request a missing native completion');
time=17600;
for(const tick of [...timers.values()])tick();
assert.equal(st.phase,'running','Status retry must not reset native CPS metrics');
time=19650;
for(const tick of [...timers.values()])tick();
assert.equal(st.phase,'done','Expired final confirmation must freeze the test');
assert.equal(st.last.incomplete,true,'Timeout results must be identified as provisional');
assert.equal(st.last.clicks,4,'Already received clicks must survive the timeout');
assert(get('cpsLast').textContent.includes('MESURE INCOMPLÈTE'));
assert(sent.some(x=>x[0]==='cpsReal'&&x[1]==='stop'),
    'Timeout must stop native injection without resetting displayed results');
api.cpsHandleRealMessage({state:'stopped',run:recoverRun,reason:'Test réel annulé.'});
assert.equal(st.phase,'done','Late native stop must not erase provisional results');
api.cpsHandleRealMessage({state:'finished',run:recoverRun,duration:2,
    profile:'Gaming',sent:6,received:5,ticks:[0,200,400,600,800]});
assert.equal(st.last.clicks,5,'Late final confirmation must replace incomplete data');
assert.equal(st.last.incomplete,undefined,'Confirmed results must no longer be provisional');
assert.equal(st.phase,'done');
get('cpsReset').onclick();
// Une fermeture/erreur en cours de test doit conserver les clics reçus.
get('cpsStartReal').onclick();
const stopRun=sent.at(-1)[3];
time=22000;
api.cpsHandleRealMessage({state:'started',run:stopRun,profile:'Gaming'});
api.cpsHandleRealMessage({state:'ticks',run:stopRun,sent:3,received:2,ticks:[0,250]});
api.cpsHandleRealMessage({state:'stopped',run:stopRun,reason:'Fenêtre de test non active.'});
assert.equal(st.phase,'done','Interrupted native run must remain visible');
assert.equal(st.last.incomplete,true);
assert.equal(st.last.clicks,2);
assert(get('cpsPrecision').textContent.includes('Fenêtre de test non active.'));
get('cpsReset').onclick();
// v1.9.29 : distinguer un moteur régulier d'une réception native figée.
get('cpsReset').onclick();
get('cpsStartReal').onclick();
const timedRun=sent.at(-1)[3];
time=27000;
api.cpsHandleRealMessage({state:'started',run:timedRun,profile:'Gaming'});
api.cpsHandleRealMessage({state:'ticks',run:timedRun,sent:7,received:7,
    sentTicks:[0,80,160,240,320,400,480],
    ticks:[0,80,160,550,550.05,630,710]});
assert.equal(st.sentClicks.length,7,'Sent timestamps should be collected separately');
assert.equal(st.clicks.length,7,'Received messages must remain independent');
assert(get('cpsIntervalsSummary').textContent.includes('Envoi moteur'),
    'Live chart must compare both timelines');
time=28400;
api.cpsHandleRealMessage({state:'finished',run:timedRun,duration:2,
    profile:'Gaming',sent:7,received:7,
    sentTicks:[0,80,160,240,320,400,480],
    ticks:[0,80,160,550,550.05,630,710]});
assert.equal(st.phase,'done');
assert.equal(st.last.sending.count,6);
assert.equal(st.last.sending.longGaps,0);
assert.equal(st.last.receiving.longGaps,1);
assert.equal(st.last.receiving.shortGaps,1);
assert(get('cpsTimingDiagnostics').textContent.includes('Envoi moteur'));
assert(get('cpsTimingDiagnostics').textContent.includes('Traitement dans la fenêtre Windows'));
assert.equal(get('cpsTimingDiagnostics').classList.contains('hidden'),false);
get('cpsReset').onclick();
api.cpsSetSource('manual');
assert.equal(get('cpsTimingDiagnostics').classList.contains('hidden'),false,
    'Last finished native diagnostic is retained across source changes');
console.log('CPS simulation, manual clicking and native sent/received Windows test passed.');
