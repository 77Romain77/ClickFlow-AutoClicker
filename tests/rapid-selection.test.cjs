// Checks the real selection helper with dash-case data attributes.
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
const start=html.indexOf('function selectedButtons(');
const end=html.indexOf('function setSwitch(',start);
assert(start>=0&&end>start,'The selection helper must be present');

function mockButton(value,attribute,key){
    const classes=new Set(),attrs={};
    return {dataset:{[key]:value},attribute,
        classList:{toggle(name,enabled){if(enabled)classes.add(name);else classes.delete(name);},
            contains:name=>classes.has(name)},
        setAttribute:(name,value)=>{attrs[name]=value;},
        getAttribute:name=>attrs[name]};
}
const groups={
    rapidPresetSeg:['precision','balanced','soft','custom'].map(v=>mockButton(v,'data-rapid-preset','rapidPreset')),
    compactRapidPresetSeg:['precision','balanced','soft','custom'].map(v=>mockButton(v,'data-compact-rapid','compactRapid')),
    compactModeSeg:['fixed','random','natural','rapid'].map(v=>mockButton(v,'data-compact-mode','compactMode'))
};
const queried=[];
const context={document:{
    querySelectorAll(selector){
        queried.push(selector);
        const match=/^#([a-zA-Z]+) \[([^\]]+)\]$/.exec(selector);
        assert(match,'Unexpected selector: '+selector);
        return (groups[match[1]]||[]).filter(button=>button.attribute===match[2]);
    }
}};
vm.runInNewContext(html.slice(start,end)+'\nthis.select=selectedButtons;',context,{timeout:1000});
function check(group,attribute,key,selected){
    context.select(group,key,selected);
    for(const b of groups[group]){
        assert.equal(b.classList.contains('active'),b.dataset[key]===selected,
            'Selected class did not follow '+selected+' in '+group);
        assert.equal(b.getAttribute('aria-pressed'),String(b.dataset[key]===selected));
    }
    assert.equal(queried.at(-1),'#'+group+' ['+attribute+']');
}
check('rapidPresetSeg','data-rapid-preset','rapidPreset','precision');
check('rapidPresetSeg','data-rapid-preset','rapidPreset','balanced');
check('rapidPresetSeg','data-rapid-preset','rapidPreset','soft');
check('rapidPresetSeg','data-rapid-preset','rapidPreset','custom');
check('compactRapidPresetSeg','data-compact-rapid','compactRapid','balanced');
check('compactModeSeg','data-compact-mode','compactMode','rapid');
assert(html.includes('#rapidPresetSeg button.active')&&html.includes('#compactRapidPresetSeg button.active'),
    'A visually distinct active rapid variation style is required');
for(const id of ['rapidBurstRange','rapidClickRange','compactRapidBurstRange','compactRapidClickRange']){
    assert(html.includes('id="'+id+'"'),'Missing CPS range in the UI: '+id);
}
console.log('Rapid variation active highlighting, accessibility, compact mode and range display passed.');
