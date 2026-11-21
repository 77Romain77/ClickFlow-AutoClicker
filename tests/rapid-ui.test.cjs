// The actual RPM -> CPS handlers are extracted from the shipped UI.
const assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'..','ui','index.html'),'utf8');
const a=html.indexOf('function clamp(v)');
const b=html.indexOf('function updateRanges() {',a);
assert(a>=0&&b>a,'Rapid naturel calculation helpers missing');
const script=html.slice(a,b);
const profile={mode:'rapid',rapidTarget:10,rapidRpm:0,rapidPreset:'custom',rapidBetween:10,rapidWithin:5};
const inputs={rapidRpm:{value:''},compactRapidRpm:{value:''}};
const sent=[],toasts=[];
const context={
    config:()=>profile,
    $:id=>inputs[id]||(inputs[id]={value:''}),
    render:()=>{},
    send:(...args)=>sent.push(args),
    toast:s=>toasts.push(s),
    Math,Number,Object,String
};
vm.runInNewContext(script+
    '\nthis.exported={rpmToCps,rpmIsValid,rapidChange,rapidApplyRpm,rapidPresetChange,rapidPercents,rapidTargetClamp,rapidEstimatedRanges,rapidEstimateText};',
    context,{timeout:2000,filename:'Rapid naturel calculator'});
const app=context.exported;
assert.equal(app.rpmToCps(600),10);
assert.equal(app.rpmToCps(750),12.5);
assert.equal(app.rpmToCps(625),10.4);
assert.equal(app.rpmToCps(900),15);
assert.equal(app.rpmIsValid(59),false);
assert.equal(app.rpmIsValid(6001),false);
assert.equal(app.rpmIsValid(750.5),false);
inputs.rapidRpm.value='750';
app.rapidApplyRpm('full');
assert.equal(profile.rapidTarget,12.5);
assert.equal(profile.rapidRpm,750);
assert.deepEqual(sent.at(-1),['set','rapidRpm',750]);
app.rapidChange('rapidTarget','13.4');
assert.equal(profile.rapidTarget,13.4);
assert.equal(profile.rapidRpm,0,'Manual CPS target must disconnect any old RPM source');
assert.deepEqual(sent.at(-1),['set','rapidTarget',13.4]);
app.rapidPresetChange('balanced');
assert.equal(profile.rapidPreset,'balanced');
assert.deepEqual(Array.from(app.rapidPercents(profile)),[4,2]);
app.rapidPresetChange('custom');
assert.deepEqual(Array.from(app.rapidPercents(profile)),[10,5]);
app.rapidChange('rapidBetween','8.7');
app.rapidChange('rapidWithin','9.2');
assert.equal(profile.rapidBetween,8.5);
assert.equal(profile.rapidWithin,9);
app.rapidChange('rapidBetween','50');
app.rapidChange('rapidWithin','25');
assert.equal(profile.rapidBetween,50);
assert.equal(profile.rapidWithin,25);
const wider=app.rapidEstimateText({...profile,rapidTarget:10});
assert.equal(wider.burst,'5.00 - 15.00 CPS');
assert.equal(wider.click,'3.75 - 18.75 CPS');
app.rapidChange('rapidBetween','99');
app.rapidChange('rapidWithin','99');
assert.equal(profile.rapidBetween,50,'Custom between-burst variation caps at 50%');
assert.equal(profile.rapidWithin,25,'Custom per-click variation caps at 25%');
inputs.compactRapidRpm.value='600';
app.rapidApplyRpm('compact');
assert.equal(profile.rapidTarget,10);
assert.equal(profile.rapidRpm,600);
// The two ranges must combine per-burst and per-click variations, with
// exactly the same 1-100 CPS bounds as the actual scheduling engine.
const example={rapidTarget:10,rapidPreset:'custom',rapidBetween:10,rapidWithin:5};
const estimated=app.rapidEstimateText(example);
assert.equal(estimated.burst,'9.00 - 11.00 CPS');
assert.equal(estimated.click,'8.55 - 11.55 CPS');
assert.deepEqual(Array.from(app.rapidPercents({...example,rapidPreset:'precision'})),[2,1]);
assert.equal(app.rapidEstimateText({...example,rapidPreset:'precision'}).burst,'9.80 - 10.20 CPS');
assert.equal(app.rapidEstimateText({...example,rapidPreset:'precision'}).click,'9.70 - 10.30 CPS');
assert.equal(app.rapidEstimateText({...example,rapidPreset:'balanced'}).burst,'9.60 - 10.40 CPS');
assert.equal(app.rapidEstimateText({...example,rapidPreset:'soft'}).burst,'9.40 - 10.60 CPS');
assert.equal(app.rapidEstimateText({...example,rapidBetween:0,rapidWithin:0}).click,'10.00 - 10.00 CPS');
const bounded=app.rapidEstimatedRanges({...example,rapidTarget:100});
assert.equal(bounded.burstMax,100);
assert.equal(bounded.clickMax,100);
assert.equal(app.rapidEstimateText({...example,rapidTarget:9.3}).burst,'8.37 - 10.23 CPS');

const before=sent.length;
inputs.rapidRpm.value='12';
app.rapidApplyRpm('full');
assert.equal(sent.length,before,'Invalid RPM must not edit engine settings');
assert.equal(profile.rapidTarget,10);
assert(toasts.some(s=>s.includes('RPM')));
console.log('Rapid mode RPM conversion, custom variations, manual override and compact UI actions passed.');
