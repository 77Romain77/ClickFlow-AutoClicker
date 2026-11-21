// Functional smoke tests for the independently wired compact control panel.
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
const start=html.indexOf('// Contrôle compact : composants indépendants');
const end=html.indexOf('function renderProfiles() {',start);
assert(start!==-1&&end>start);
const block=html.slice(start,end);
const model={profiles:[
    {id:1,name:'Long named profile for compact testing',settings:{mode:'natural',min:8,max:14,intensity:'medium',hotkey:'F6'}},
    {id:2,name:'Other',settings:{mode:'fixed',min:10,max:10,intensity:'low',hotkey:'F9'}}
],selected:1,emergencyKey:'F12',capturing:false,captureTarget:'activation',compact:true,preferences:{compactChart:true}};
const commands=[],calls={stop:0,capture:0,emergency:0,rpm:0};
function element(id='') {
    const set=new Set();
    return {
        id,dataset:{},value:'',textContent:'',children:[],
        classList:{toggle(k,bool){if(bool)set.add(k);else set.delete(k);},contains:k=>set.has(k)},
        append(child){this.children.push(child);},
        replaceChildren(){this.children=[];},
        click(){},onchange:null,onclick:null
    };
}
const nodes=new Map(),get=id=>{if(!nodes.has(id))nodes.set(id,element(id));return nodes.get(id);};
get('demoToggle').click=()=>calls.stop++;
get('captureButton').click=()=>calls.capture++;
get('emergencyCapture').click=()=>calls.emergency++;
const buttons=[];
for(const [kind,key,values] of [
    ['mode','compactMode',['fixed','random','natural','rapid']],
    ['intensity','compactIntensity',['low','medium','high']],
    ['rapid','compactRapid',['precision','balanced','soft','custom']]
])for(const v of values){const e=element();e.dataset[key]=v;e.kind=kind;buttons.push(e);}
const context={
    model,active:()=>model.profiles.find(x=>x.id===model.selected),
    config:()=>model.profiles.find(x=>x.id===model.selected).settings,
    $:get,send:(...args)=>commands.push(args),drawLiveMonitor:()=>{},
    setTimeout:()=>{},
    document:{
        createElement:()=>element(),
        querySelectorAll:selector=>selector==='[data-compact-mode]'?buttons.filter(x=>x.kind==='mode')
            :selector==='[data-compact-intensity]'?buttons.filter(x=>x.kind==='intensity')
            :selector==='[data-compact-rapid]'?buttons.filter(x=>x.kind==='rapid'):[]
    },
    selectedButtons:(group,field,value)=>{
        for(const b of buttons)if((group==='compactModeSeg'&&b.kind==='mode')||
            (group==='compactIntensitySeg'&&b.kind==='intensity')||
            (group==='compactRapidPresetSeg'&&b.kind==='rapid'))
            b.classList.toggle('active',b.dataset[field]===value);
    },
    render(){context.renderCompactPanel();},
    changeCps(field,v){context.config()[field]=Number(v);},
    rapidPresetChange(value){context.config().rapidPreset=value;commands.push(['set','rapidPreset',value]);context.render();},
    rapidApplyRpm(){calls.rpm++;},
    rapidChange(field,value){context.config()[field]=Number(value);commands.push(['set',field,value]);context.render();},
    chooseProfile(id){model.selected=id;context.renderCompactPanel();}
};
vm.runInNewContext(block+'\nthis.renderCompactPanel=renderCompactPanel;',context,
    {filename:'ClickFlow compact panel',timeout:2000});
context.renderCompactPanel();
assert.equal(get('compactProfileSelect').children.length,2);
assert.equal(get('compactProfileSelect').value,'1');
assert.equal(get('compactMin').value,8);
assert.equal(get('compactMax').value,14);
assert.equal(get('compactIntensity').classList.contains('hidden'),false);
buttons.find(x=>x.dataset.compactMode==='fixed').onclick();
assert.equal(model.profiles[0].settings.mode,'fixed');
assert.equal(commands.at(-1).join(','),'set,mode,fixed');
assert.equal(get('compactMaxWrap').classList.contains('hidden'),true);
buttons.find(x=>x.dataset.compactMode==='natural').onclick();
buttons.find(x=>x.dataset.compactIntensity==='high').onclick();
assert.equal(model.profiles[0].settings.intensity,'high');
assert.equal(commands.at(-1).join(','),'set,intensity,high');
get('compactMin').onchange({target:{value:'9'}});
assert.equal(model.profiles[0].settings.min,9);
buttons.find(x=>x.dataset.compactMode==='rapid').onclick();
assert.equal(model.profiles[0].settings.mode,'rapid');
assert.equal(get('compactMinLabel').textContent,'CPS cible');
assert.equal(get('compactMaxWrap').classList.contains('hidden'),true);
assert.equal(get('compactRapid').classList.contains('hidden'),false);
buttons.find(x=>x.dataset.compactRapid==='precision').onclick();
assert.equal(model.profiles[0].settings.rapidPreset,'precision');
get('compactRapidRpmApply').onclick();
assert.equal(calls.rpm,1);
get('compactStop').onclick();
get('compactCapture').onclick();
get('compactCaptureStop').onclick();
assert.deepEqual(calls,{stop:1,capture:1,emergency:1,rpm:1});
get('compactProfileSelect').onchange({target:{value:'2'}});
assert.equal(model.selected,2);
assert.equal(get('compactIntensity').classList.contains('hidden'),true);
model.preferences.compactChart=false;
context.renderCompactPanel();
assert.equal(get('compactChartTile').classList.contains('hidden'),true);
console.log('Compact profile, modes, intensity, CPS, stop, hotkeys and chart preference passed.');
