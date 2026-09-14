import test from 'node:test';
import assert from 'node:assert/strict';
import {registerDelivery} from '../extensions/delivery/extension.mjs';
const routes={planning:'openai-codex/gpt-6-astra',coder:'custom/c',spec:'custom/r',quality:'custom/r',security:'custom/s'};
const plan={title:'Fixture',tasks:[{title:'Add',instructions:'Add one',files:['a'],acceptance:['works']}],checks:['node --test'],risk:'low',security:true};
function harness(config={version:1,routes,evidence:{},repos:['/repo']}) {
 const events={},commands={},tools={},entries=[],statuses=[],messages=[],calls=[];
 let model={provider:'openai-codex',id:'gpt-5.5'};
 const models=[...new Set(Object.values(routes))].map(s=>{const [provider,...id]=s.split('/');return {provider,id:id.join('/')};});
 const ctx={cwd:'/repo',hasUI:true,mode:'tui',isIdle:()=>true,isProjectTrusted:()=>true,modelRegistry:{getAll:()=>models,getAvailable:()=>models},get model(){return model;},sessionManager:{getSessionId:()=> 'session',getBranch:()=>entries},ui:{setStatus:(k,v)=>statuses.push(v),notify:()=>{},confirm:async()=>true,select:async(t,opts)=>opts[0],input:async()=> 'trial'}};
 const pi={on:(e,h)=>events[e]=h,registerCommand:(n,c)=>commands[n]=c,registerTool:t=>tools[t.name]=t,appendEntry:(customType,data)=>entries.push({type:'custom',customType,data:structuredClone(data)}),setModel:async m=>{model=m;return true;},sendMessage:m=>messages.push(m),sendUserMessage:m=>messages.push(m),getActiveTools:()=>['read','bash','edit','write','delivery_plan'],setActiveTools:()=>{},events:{}};
 const deps={configPath:()=>'/unused',loadConfig:()=>structuredClone(config),saveConfig:(_,c)=>Object.assign(config,c),repoRoot:()=>'/repo',fingerprint:()=> 'hash',diff:()=> 'diff',reviewPatch:()=>'/fake/full.diff',validateCommands:()=>{},verifyCommand:async()=>({code:0,output:'PASS'}),rpc:async(_e,method,params)=>{calls.push({method,params});return method==='spawn'?{details:{runId:'r'+calls.length,asyncDir:'/fake'}}:{};},readOutcome:()=>({status:'approved',summary:'ok',findings:[]}),pollMs:1,child:false};
 const controller=registerDelivery(pi,{plan:{},empty:{}},deps);
 return {pi,ctx,events,commands,tools,entries,statuses,messages,calls,controller,deps,config};
}
test('real command, auto activation, Astra selection and shell gate',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 assert.ok(h.commands.delivery);assert.equal(h.ctx.model.id,'gpt-6-astra');assert.match(h.statuses.at(-1),/planning/);
 assert.equal((await h.events.tool_call({toolName:'bash',input:{command:'echo x > a'}},h.ctx)).block,true);
 await h.events.session_shutdown({},h.ctx);
});
test('missing routes visibly block implementation, not inherited GPT',async()=>{
 const h=harness({version:1,routes:{planning:routes.planning},evidence:{},repos:['/repo']});await h.events.session_start({},h.ctx);
 await assert.rejects(h.tools.delivery_plan.execute('id',plan,null,null,h.ctx),/route/);
 assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
});
test('proposal alone cannot launch; approval runs all stages and verification',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 await h.tools.delivery_plan.execute('id',plan,null,null,h.ctx);
 assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
 await h.commands.delivery.handler('approve',h.ctx);
 await h.controller.settled();
 assert.deepEqual(h.calls.filter(c=>c.method==='spawn').map(c=>c.params.agent),['delivery-coder','delivery-reviewer','delivery-reviewer','delivery-security']);
 assert.deepEqual(h.calls.filter(c=>c.method==='spawn').map(c=>c.params.model),[routes.coder,routes.spec,routes.quality,routes.security]);
 assert.equal(h.controller.state().stage,'complete');
 for(const c of h.calls.filter(c=>c.method==='spawn')) {assert.equal(c.params.context,'fresh');assert.equal(c.params.async,true);}
 await h.events.session_shutdown({},h.ctx);
});
test('failed host check requests bounded fix without inventing a spec review',async()=>{
 const h=harness();let checks=0;h.deps.verifyCommand=async()=>({code:checks++===0?1:0,output:'check result'});
 await h.events.session_start({},h.ctx);await h.tools.delivery_plan.execute('id',plan,null,null,h.ctx);
 await h.commands.delivery.handler('approve',h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');
 assert.equal(h.controller.state().reports.find(r=>r.report.status==='changes_requested').stage,'checks');
});
test('CLI/no-UI cannot auto approve plan',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);await h.tools.delivery_plan.execute('id',plan,null,null,h.ctx);h.ctx.hasUI=false;
 await h.commands.delivery.handler('approve',h.ctx);assert.equal(h.controller.state().stage,'awaiting-approval');
});
test('unconfigured repo remains OFF; child registers nothing',async()=>{
 const h=harness({version:1,routes,evidence:{},repos:[]});await h.events.session_start({},h.ctx);assert.equal(h.controller.state().enabled,false);assert.match(h.statuses.at(-1),/OFF/);
 const result=registerDelivery({on:()=>assert.fail('child hook'),registerCommand:()=>assert.fail('child command')},{},{child:true});assert.equal(result,undefined);
});
test('reload during verification resumes checks without relaunching a coder',async()=>{
 const h=harness();
 h.entries.push({type:'custom',customType:'delivery-mode-v1',data:{version:1,enabled:true,stage:'verification',task:0,round:0,plan,routes,snapshot:'hash',active:null,reports:[],reason:'',workspace:'/repo',owner:'session'}});
 await h.events.session_start({},h.ctx);assert.equal(h.controller.state().stage,'blocked');
 await h.commands.delivery.handler('resume',h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
});
test('retained coder is reconciled, never launched a second time on resume',async()=>{
 const h=harness();
 h.entries.push({type:'custom',customType:'delivery-mode-v1',data:{version:1,enabled:true,stage:'coder',task:0,round:0,plan,routes,snapshot:'hash',active:{id:'old',dir:'/fake',model:routes.coder,stage:'coder'},reports:[],reason:'',workspace:'/repo',owner:'session'}});
 await h.events.session_start({},h.ctx);await h.commands.delivery.handler('resume',h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');assert.equal(h.calls.filter(c=>c.method==='spawn'&&c.params.agent==='delivery-coder').length,0);
});
test('legacy orchestration skill invocation activates the real mode',async()=>{
 const h=harness({version:1,routes,evidence:{},repos:[]});await h.events.session_start({},h.ctx);
 await h.events.input({text:'/skill:orchestrate-delivery feature',source:'interactive'},h.ctx);
 assert.equal(h.controller.state().enabled,true);assert.equal(h.ctx.model.id,'gpt-6-astra');
});
test('setup saves explicit selected routes and repo opt-in without inference',async()=>{
 const h=harness({version:1,routes:{},evidence:{},repos:[]});await h.events.session_start({},h.ctx);
 await h.commands.delivery.handler('setup',h.ctx);
 assert.equal(h.config.routes.planning,routes.planning);
 for(const role of ['coder','spec','quality','security'])assert.ok(h.config.routes[role]);
 assert.deepEqual(h.config.repos,['/repo']);assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
});
test('setup explains roles and model capabilities without evidence prompts',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 const selections=[],confirmations=[];
 h.ctx.ui.input=async()=>assert.fail('No evidence/trial questions');
 const models=h.ctx.modelRegistry.getAvailable().map(m=>({...m,contextWindow:272000,maxTokens:32000,reasoning:true,input:['text','image'],cost:{input:2,output:8}}));
 h.ctx.modelRegistry.getAvailable=()=>models;
 h.ctx.ui.select=async(title,options)=>{selections.push({title,options});return options[0];};
 h.ctx.ui.confirm=async(title,body)=>{confirmations.push(body);return true;};
 await h.commands.delivery.handler('setup',h.ctx);
 assert.equal(selections.length,5);
 assert.match(selections[1].title,/implements.*tests/i);
 assert.match(selections[2].title,/acceptance criteria/i);
 assert.match(selections[3].title,/correctness/i);
 assert.match(selections[4].title,/security/i);
 assert.match(selections[0].options[0],/272k.*32k.*reasoning.*image.*\$2.*\$8/i);
 assert.equal(h.config.routes.planning,routes.planning);
 assert.ok(confirmations.every(t=>!/attestation|trial|evidence reference/i.test(t)));
});
test('legacy trial markers do not block high-risk tasks; approval and security remain mandatory',async()=>{
 const h=harness({version:1,routes,evidence:{coder:'trial',spec:'trial',quality:'trial',security:'trial'},repos:['/repo']});
 await h.events.session_start({},h.ctx);
 await h.tools.delivery_plan.execute('id',{...plan,risk:'high',security:false},null,null,h.ctx);
 assert.equal(h.controller.state().stage,'awaiting-approval');assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
 assert.equal(h.controller.state().plan.security,true);
 await h.commands.delivery.handler('approve',h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');assert.ok(h.calls.some(c=>c.params?.agent==='delivery-security'));
});
test('planner interprets raw request and starts only reviewers for the pinned range',async()=>{
 const h=harness();const range={base:'a'.repeat(40),head:'b'.repeat(40)};
 h.deps.revisionRange=(_root,n)=>{assert.equal(n,2);return range;};h.deps.assertCommittedWorkspace=()=>{};
 let checked=0;h.deps.verifyCommand=async()=>{checked++;return {code:0,output:'PASS'};};
 h.deps.diff=(_root,r)=>{assert.deepEqual(r,range);return 'committed diff';};
 await h.events.session_start({},h.ctx);await h.commands.delivery.handler('validate last 2 commits',h.ctx);
 assert.equal(h.messages.at(-1),'validate last 2 commits');
 assert.match((await h.tools.delivery_diff.execute('diff',{commits:2})).content[0].text,/committed diff/);
 await h.tools.delivery_plan.execute('id',{...plan,mode:'review',commits:2},null,null,h.ctx);
 assert.equal(h.controller.state().plan.mode,'review');assert.deepEqual(h.controller.state().plan.reviewRange,range);
 await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');assert.ok(checked>0);
 assert.deepEqual(h.calls.filter(c=>c.method==='spawn').map(c=>c.params.agent),['delivery-reviewer','delivery-reviewer','delivery-security']);
 assert.ok(h.calls.filter(c=>c.method==='spawn').every(c=>c.params.task.includes('Host verification evidence: [{') && c.params.task.includes('committed diff')));
});
test('read-only check failure stops without dispatching an automatic fix',async()=>{
 const h=harness();h.deps.verifyCommand=async()=>({code:1,output:'failing test'});
 await h.events.session_start({},h.ctx);await h.commands.delivery.handler('review',h.ctx);
 await h.tools.delivery_plan.execute('id',{...plan,mode:'review'},null,null,h.ctx);
 await h.controller.settled();
 assert.equal(h.controller.state().stage,'blocked');assert.match(h.controller.state().reason,/failing test/);
 assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
});
test('ordinary user review request executes without an approval command',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 await h.events.input({text:'Please validate these changes without fixing anything',source:'interactive'},h.ctx);
 await h.tools.delivery_plan.execute('id',{...plan,mode:'review'},null,null,h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');
 assert.ok(h.calls.some(c=>c.method==='spawn'));assert.ok(h.calls.every(c=>c.params?.agent!=='delivery-coder'));
});
test('conversational execution needs a fresh user reply to the exact pending plan',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 await h.tools.delivery_plan.execute('id',plan,null,null,h.ctx);
 assert.ok(h.tools.delivery_execute,'execution tool exists');
 await assert.rejects(h.tools.delivery_execute.execute('go',{},null,null,h.ctx),/user reply/i);
 await h.events.input({text:'Yes, implement the plan',source:'extension'},h.ctx);
 await assert.rejects(h.tools.delivery_execute.execute('go',{},null,null,h.ctx),/user reply/i);
 await h.events.input({text:'Yes, implement the plan',source:'interactive'},h.ctx);
 await h.tools.delivery_execute.execute('go',{},null,null,h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');assert.ok(h.calls.some(c=>c.params?.agent==='delivery-coder'));
});
test('explicit file execution after reload adopts the document and starts derived tasks without another approval',async()=>{
 const h=harness();const path='docs/spark/plans/banking.md';
 h.deps.readPlan=()=>({path,hash:'doc-hash',content:'# Banking plan\n## Task 1\nImplement Add.'});
 await h.events.session_start({},h.ctx);
 await h.events.input({text:`Execute the plan ${path}`,source:'interactive'},h.ctx);
 const adopted=await h.tools.delivery_execute.execute('go',{planFile:path},null,null,h.ctx);
 assert.match(adopted.content[0].text,/Banking plan/);assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
 await h.tools.delivery_plan.execute('plan',{...plan,planFile:path},null,null,h.ctx);await h.controller.settled();
 assert.equal(h.controller.state().stage,'complete');assert.equal(h.controller.state().plan.sourcePlan.hash,'doc-hash');
 assert.ok(h.calls.some(c=>c.params?.agent==='delivery-coder'));
});
test('file execution consent cannot survive a new message or changed document',async()=>{
 const h=harness();const path='docs/spark/plans/banking.md';let hash='one';
 h.deps.readPlan=()=>({path,hash,content:'# Banking'});
 await h.events.session_start({},h.ctx);await h.events.input({text:`Execute ${path}`,source:'interactive'},h.ctx);
 await h.tools.delivery_execute.execute('go',{planFile:path},null,null,h.ctx);hash='two';
 await assert.rejects(h.tools.delivery_plan.execute('plan',{...plan,planFile:path},null,null,h.ctx),/plan.*changed/i);
 assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
 hash='one';await h.tools.delivery_execute.execute('go',{planFile:path},null,null,h.ctx);
 await h.events.input({text:'Wait, only explain it',source:'interactive'},h.ctx);
 await h.tools.delivery_plan.execute('plan',{...plan,planFile:path},null,null,h.ctx);
 assert.equal(h.controller.state().stage,'awaiting-approval');assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
});
test('implementation and review checks keep their ordering and stop on failure',async()=>{
 for(const mode of ['implementation','review']) {
  const h=harness(),ran=[];
  h.deps.verifyCommand=async(_cwd,command)=>{ran.push(command);return {command,code:0,output:'PASS'};};
  await h.events.session_start({},h.ctx);
  await h.tools.delivery_plan.execute('plan',{...plan,mode,checks:['first','second']},null,null,h.ctx);
  await h.commands.delivery.handler('approve',h.ctx);await h.controller.settled();
  assert.deepEqual(ran,['first','second','first','second']);assert.equal(h.controller.state().stage,'complete');
 }
 const h=harness(),ran=[];
 h.deps.verifyCommand=async(_cwd,command)=>{ran.push(command);return {command,code:1,output:'FAIL'};};
 await h.events.session_start({},h.ctx);
 await h.tools.delivery_plan.execute('plan',{...plan,mode:'review',checks:['first','second']},null,null,h.ctx);
 await h.commands.delivery.handler('approve',h.ctx);await h.controller.settled();
 assert.deepEqual(ran,['first']);assert.equal(h.controller.state().stage,'blocked');
});
test('shared approval validation still rejects workspace changes during confirmation',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 await h.tools.delivery_plan.execute('plan',plan,null,null,h.ctx);
 h.ctx.ui.confirm=async()=>{h.deps.fingerprint=()=> 'changed';return true;};
 await h.commands.delivery.handler('approve',h.ctx);await h.controller.settled();
 assert.equal(h.calls.filter(c=>c.method==='spawn').length,0);
 assert.equal(h.controller.state().stage,'awaiting-approval');
});
test('approval preview is readable rather than a JSON object dump',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);await h.tools.delivery_plan.execute('id',plan,null,null,h.ctx);
 let body;h.ctx.ui.confirm=async(_title,text)=>{body=text;return false;};
 await h.commands.delivery.handler('approve',h.ctx);
 assert.match(body,/Tasks/);assert.match(body,/node --test/);assert.doesNotMatch(body,/"tasks"\s*:/);
});
test('human supervisor reply is confirmed; parent cannot authorize it silently',async()=>{
 const h=harness();await h.events.session_start({},h.ctx);
 const response=await h.events.tool_call({toolName:'subagent_supervisor',input:{action:'reply',message:'approve scope'}},h.ctx);
 assert.equal(response.block,true);
});
test('runtime failed child cannot become approved from prose',async()=>{
 const h=harness();h.deps.readOutcome=()=>{throw new Error('child failed');};await h.events.session_start({},h.ctx);await h.tools.delivery_plan.execute('id',plan,null,null,h.ctx);
 await h.commands.delivery.handler('approve',h.ctx);await h.controller.settled();assert.equal(h.controller.state().stage,'blocked');assert.match(h.controller.state().reason,/child failed/);
});
