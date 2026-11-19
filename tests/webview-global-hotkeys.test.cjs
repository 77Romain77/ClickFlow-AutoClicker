// End-to-end UI control regression for WebView2 keyboard shortcut capture.
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
function block(start,end){
    const a=html.indexOf(start),z=html.indexOf(end,a);
    assert(a>=0&&z>a,'Missing JavaScript block '+start);
    return html.slice(a,z);
}
const capture=block('function shortcutKeyFromEvent(e) {','function setLiveAppearance() {');
const commands=[],listeners={},els=new Map();
const model={capturing:false,captureTarget:'activation',emergencyKey:'F12',
    profiles:[{settings:{hotkey:'F6'}}],
    globalHotkeys:{next:'',previous:'',overlay:'',test:'',open:''}};
function el(id){
    if(!els.has(id)){
        const item={id,textContent:'',disabled:false,onclick:null,
            dataset:{},click(){this.onclick?.()}};
        els.set(id,item);
    }
    return els.get(id);
}
const captures=['next','previous','overlay','test','open'].map(action=>({
    dataset:{globalCapture:action},onclick:null}));
const clears=['next','previous','overlay','test','open'].map(action=>({
    dataset:{globalClear:action},onclick:null}));
const context={model,connected:true,window:{},render(){},renderGlobalHotkeys(){},
    config:()=>model.profiles[0].settings,send:(...args)=>commands.push(args),
    toast:()=>{},$:el,
    document:{
        addEventListener:(type,callback)=>listeners[type]=callback,
        querySelectorAll:(selector)=>{
            if(selector==='[data-global-capture]')return captures;
            if(selector==='[data-global-clear]')return clears;
            return [];
        }
    }};
vm.createContext(context);
vm.runInContext(capture,context,{timeout:3000});
vm.runInContext(block('const globalKeySuffix=','function renderShortcutSettings() {'),
    context,{timeout:3000});
vm.runInContext(block("$('emergencyCapture').onclick=()=>{","$('viewToggle').onclick=()=>{"),
    context,{timeout:3000});
function keyboard(key,code,opts={}){
    const event={key,code:opts.code||key,keyCode:code,which:code,
        repeat:false,prevented:false,stopped:false,
        preventDefault(){this.prevented=true},
        stopPropagation(){this.stopped=true},...opts};
    assert.equal(typeof listeners.keydown,'function');
    listeners.keydown(event);
    return event;
}
function last(){return Array.from(commands.at(-1)||[])}
captures[0].onclick();
assert.deepEqual(last(),['globalHotkey','begin','next']);
assert.equal(model.captureTarget,'global:next');
let event=keyboard('F9',120);
assert(event.prevented&&event.stopped,'WebView must consume captured hotkeys');
assert.deepEqual(last(),['globalHotkey','set','next','vk78'],
    'The physical F9 must be transmitted to backend even while connected');
assert.equal(model.globalHotkeys.next,'',
    'UI must not claim a shortcut was saved without backend confirmation');
model.capturing=false;
captures[1].onclick();
let n=commands.length;
keyboard('Shift',16);
assert.equal(commands.length,n,'Modifier-only key must not complete capture');
keyboard('Escape',27);
assert.deepEqual(last(),['globalHotkey','cancel'],
    'Escape must cancel WebView capture through native bridge');
model.capturing=false;
el('globalClearEmergency').onclick();
assert.deepEqual(last(),['globalHotkey','clear','emergency'],
    'Emergency Aucun must send native clear, not only change the label');
el('globalCaptureEmergency').onclick();
assert.deepEqual(last(),['globalHotkey','begin','emergency'],
    'Emergency capture must use the same reliable WebView pipeline');
event=keyboard('F10',121);
assert.deepEqual(last(),['globalHotkey','set','emergency','vk79']);
model.capturing=false;
captures[2].onclick();
event=keyboard('ArrowLeft',37);
assert.deepEqual(last(),['globalHotkey','set','overlay','vk25']);
model.capturing=false;
clears[2].onclick();
assert.deepEqual(last(),['globalHotkey','clear','overlay']);
assert(html.includes("model.emergencyKey=msg.emergencyKey??'F12'"),
    'An intentionally blank emergency binding must remain blank');
console.log('WebView2 keyboard capture, native shortcut set/cancel and emergency/global Aucun buttons passed.');
