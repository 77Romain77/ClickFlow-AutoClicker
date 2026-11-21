const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../ui/index.html'),'utf8');
const begin=html.indexOf('function changeCps(which,input) {');
const end=html.indexOf("for(const which of ['min','max'])",begin);
assert(begin>=0&&end>begin,'CPS input handler missing');
const c={mode:'fixed',min:8,max:14},sent=[];
const context={
    config:()=>c,
    clamp:v=>Math.max(1,Math.min(100,Math.round((Number(v)||1)*10)/10)),
    send:(...args)=>sent.push(args),
    updateRanges:()=>{},
    rapidChange:()=>{throw Error('Legacy mode must not use rapid control');}
};
vm.runInNewContext(html.slice(begin,end)+'\nthis.changeCps=changeCps;',context);
context.changeCps('min','12.5');
assert.equal(c.min,12.5);
assert.deepEqual(sent.at(-1),['set','min',12.5]);
context.changeCps('max','18.7');
assert.equal(c.max,18.7);
context.changeCps('min','13.28');
assert.equal(c.min,13.3,'Only a single decimal must be retained');
context.changeCps('max','12.2');
assert.equal(c.min,12.2,'Min must follow max on inverted limits');
c.mode='random';
context.changeCps('min','9.7');
assert.equal(c.min,9.7);
c.mode='natural';
context.changeCps('max','16.4');
assert.equal(c.max,16.4);
for(const id of ['minRange','minNumber','maxRange','maxNumber','compactMin','compactMax','cpsQuickMin','cpsQuickMax']){
    const match=html.match(new RegExp('<input[^>]*id="'+id+'"[^>]*>'));
    assert(match,'Missing decimal CPS input '+id);
    assert(match[0].includes('step="0.1"'),id+' is missing decimal step');
}
const quick=html.slice(html.indexOf('function cpsQuickValid()'),html.indexOf('function cpsQuickDirty()'));
assert(quick.includes('d.min*10')&&quick.includes('d.max*10'),
    'Quick profile settings must validate tenth-CPS precision');
console.log('Decimal CPS fixed, random, natural UI updates and all editors passed.');
