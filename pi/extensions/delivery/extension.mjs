import {join} from 'node:path';
import {accessSync,constants} from 'node:fs';
import {ROLES,ASTRA,AGENTS,REPORT_SCHEMA,catalog,validateRoutes,validatePlan,initialState,approve,advance,parentToolAllowed,timeoutPolicy,attemptBudget} from './policy.mjs';
import * as io from './io.mjs';
import {rpc} from './rpc.mjs';
import {ROLE_HELP,modelLabel} from './setup.mjs';

const ENTRY='delivery-mode-v1';
const result=(text,details={})=>({content:[{type:'text',text}],details});
const modelId=m=>m?`${m.provider}/${m.id}`:'';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

export function registerDelivery(pi,schemas,deps={}) {
  if(deps.child ?? process.env.PI_SUBAGENT_CHILD==='1') return;
  for(const [k,v] of Object.entries({...io,rpc,pollMs:1500,now:Date.now})) if(!(k in deps)) deps[k]=v;
  const d=deps;
  let s=initialState(),ctx,root,config,originalTools,job=null,closed=false,checking,requestText='',approvalTurn=null,fileIntent=null;
  function snapshot(plan=s.plan,warnings=[]) {
    if(plan?.sourcePlan && d.readPlan(root,plan.sourcePlan.path).hash!==plan.sourcePlan.hash)throw new Error('Source plan changed; read the updated document and obtain fresh execution approval.');
    return d.fingerprint(root,{scope:plan?.tasks.flatMap(t=>t.files) || [],commands:plan?.checks || [],warnings});
  }
  const planKey=()=>JSON.stringify({plan:s.plan,snapshot:s.snapshot});
  function readablePlan(routes) {
    const p=s.plan;
    return [p.title,`Workspace: ${root}`,`Mode: ${p.mode==='review'?'Read-only review — no fixes':'Implementation'}`,
      p.reviewRange?`Commits: ${p.reviewRange.base.slice(0,10)}..${p.reviewRange.head.slice(0,10)}`:'',
      p.sourcePlan?`Source plan: ${p.sourcePlan.path}`:'',
      ...(s.coverageWarnings || []).map(w=>`Coverage warning: ${w}`),
      'Tasks',...p.tasks.map((t,i)=>`${i+1}. ${t.title}\n   ${t.instructions}\n   Files: ${t.files.join(', ')}\n   Acceptance: ${t.acceptance.join('; ')}`),
      `Time budget: coder ${timeoutPolicy(config.timeouts).coderMs/60000}m + one ${timeoutPolicy(config.timeouts).continuationMs/60000}m continuation per task; reviewers ${timeoutPolicy(config.timeouts).reviewMs/60000}m per run.`,
      'Test commands',...(p.checks.length?p.checks.map(c=>`  ${c}`):['  None — static review only; no test pass will be claimed.']),
      'Models',...Object.entries(routes).filter(([role])=>p.mode!=='review'||role!=='coder').map(([role,model])=>`  ${role}: ${model}`),
      'Commands run with your account permissions. No automatic commit, push, merge or deployment.'
    ].filter(Boolean).join('\n');
  }
  function pendingExecution() {
    guardIdle();
    if(s.stage!=='awaiting-approval')throw new Error(s.stage==='blocked'?'The previous run stopped. Ask to retry; I must prepare corrected checks before execution.':'No pending plan to execute.');
    const routes=routeCheck(),hash=snapshot();
    if(hash!==s.snapshot)throw new Error('Workspace changed since proposal; refresh the plan first');
    d.validateCommands(root,s.plan.checks);
    return {routes,hash,timeouts:timeoutPolicy(config.timeouts)};
  }
  async function launchApproved() {
    const {routes,hash,timeouts}=pendingExecution();
    await d.rpc(pi.events,'ping');
    if(hash!==snapshot())throw new Error('Workspace changed before execution');
    const warnings=s.coverageWarnings || [];
    s=approve(s,routes,hash);s.coverageWarnings=warnings;s.timeouts=timeouts;approvalTurn=null;fileIntent=null;save();start();
  }
  function display(text) {pi.sendMessage({customType:'delivery',content:text,display:true});}
  function status() {
    const route=s.routes?.[s.stage] || config?.routes?.planning || ASTRA;
    return !s.enabled?'Delivery OFF · /delivery setup':`Delivery ${s.reason?'BLOCKED':'ON'} · ${s.stage} · ${route} · ${s.plan?`task ${s.task+1}/${s.plan.tasks.length}`:'awaiting plan'}${s.reason?' · '+s.reason:''}`;
  }
  function save() {pi.appendEntry(ENTRY,{...structuredClone(s),workspace:root,owner:ctx.sessionManager.getSessionId()});ctx.ui.setStatus('delivery',status());}
  function block(error) {s.stage='blocked';s.reason=error instanceof Error?error.message:String(error);save();display(`Delivery blocked: ${s.reason}${s.active?.id?'\nRun: '+s.active.id:''}`);}
  function restrict() {
    if(!originalTools) originalTools=pi.getActiveTools();
    const discovered=pi.getAllTools?.().map(t=>t.name) || [];
    const candidates=new Set([...originalTools,...pi.getActiveTools(),...discovered,'delivery_plan','delivery_execute','delivery_resume','delivery_status','delivery_diff']);
    pi.setActiveTools([...candidates].filter(name=>parentToolAllowed(name,{action:'status'}) || name==='subagent_supervisor'));
  }
  function available() {return ctx.modelRegistry.getAvailable().map(modelId);}
  async function selectPlanning() {
    const id=config?.routes?.planning || ASTRA;
    const m=ctx.modelRegistry.getAvailable().find(m=>modelId(m)===id);
    if(!m || !await pi.setModel(m)) {s.reason=`Planning model unavailable: ${id}. Use /delivery setup or /login.`;save();return false;}
    return true;
  }
  async function activate() {
    s.enabled=true;restrict();
    if(await selectPlanning()) {
      try {validateRoutes(config.routes,available());s.reason='';}
      catch(e){s.reason=e.message;}
    }
    save();
  }
  function guardIdle() {if(job || s.active) throw new Error('An owned run is active or unresolved; inspect status before changing the plan.');}
  function routeCheck() {
    const r=validateRoutes(config.routes,available());
    const limits=timeoutPolicy(config.timeouts);
    if(s.timeouts && JSON.stringify(limits)!==JSON.stringify(s.timeouts))throw new Error('Time budget changed; reapproval required');
    if(s.routes && JSON.stringify(r)!==JSON.stringify(s.routes)) throw new Error('Routes changed; reapproval required');
    return r;
  }
  function briefing(stage) {
    const task=s.plan.tasks[s.task];
    const scope={title:s.plan.title,mode:s.plan.mode || 'implementation',sourcePlan:s.plan.sourcePlan,coverageWarnings:s.coverageWarnings,reviewRange:s.plan.reviewRange,taskIndex:s.task,task,interruptions:(s.interruptions || []).filter(r=>r.task===s.task),completedTasks:s.plan.tasks.slice(0,s.task),checks:s.plan.checks};
    return [
      stage==='coder'?'Implement only this approved task. Follow selected SPARK TDD/debugging/verification skills.':`Independent ${stage} review. Inspect actual source and the full current diff, including earlier tasks for regressions. No edits or commands.`,
      'No commit, push, merge, deploy, credentials access or delegation. Preserve unrelated changes. Stop for scope questions; do not widen scope.',
      'Return your result using the supplied structured_output schema. status=approved requires findings=[]; put successful checks, completed work and informational evidence in summary, never in findings. Use changes_requested for actionable fixes; blocked for missing evidence. findings are concise strings with severity, file:line, evidence, impact and fix. This schema replaces prose/fenced/JSON-only report formatting from role skills.',
      JSON.stringify(scope),
      s.plan.sourcePlan?`Read the authoritative Markdown plan at ${s.plan.sourcePlan.path}; preserve its global constraints and task boundaries. Do not edit this approved document, including checkboxes; report progress separately.`:'',
      'Uncovered symlink targets are not dependencies you may silently use. Stop if this task needs one. Do not delete or repair unrelated links.',
      s.feedback?'Prior actionable findings: '+s.feedback:'',
      s.pendingContinuation || s.active?.continuation?`Continue the same approved task from its partial changes. Start with verification of the partial workspace, inspect the previous tool logs, and finish only remaining work. Do not discard or reimplement completed work. Previous interrupted runs: ${JSON.stringify((s.interruptions || []).filter(r=>r.task===s.task))}`:'',
      stage==='coder'?'':d.diff(root,s.plan.reviewRange),
      s.plan.mode==='review'?`Read-only validation: report findings only. Do not implement or fix anything. For a committed range, untracked files are out of scope. Read the FULL diff in chunks from ${d.reviewPatch(root,s.plan.reviewRange)}; the inline preview may be truncated.`:'',
      stage==='coder'?'':'Host verification evidence: '+JSON.stringify(s.checks || []),
      stage==='coder'?'':'Actual coder session/tool-output evidence: '+JSON.stringify(s.reports.filter(r=>r.stage==='coder' && r.task===s.task).map(r=>r.report.executionEvidence).filter(Boolean))+'. Read these logs for pre-fix failing tests or other execution evidence not present in post-fix host checks. Do not replace them with coder prose claims.',
      'Use the repository instruction files. Review paths not shown in truncated diffs yourself. Never treat a prior agent claim as test evidence.'
    ].join('\n\n');
  }
  function codingLedger() {
    s.coding ||= {};
    return s.coding[s.task] ||= {spentMs:0,continuations:0};
  }
  function chargeCoding(progress) {
    if(s.active?.stage!=='coder' || s.active.charged)return;
    const grant=s.active.budgetMs ?? progress?.timeoutMs ?? 15*60000;
    if(!Number.isFinite(grant) || grant<=0)throw new Error('Cannot establish previous coding budget');
    const started=s.active.startedAt ?? progress?.startedAt;
    const elapsed=progress?.durationMs ?? (Number.isFinite(started)?d.now()-started:grant);
    codingLedger().spentMs+=Math.min(grant,Math.max(0,elapsed));
    s.active.charged=true;save();
  }
  function queueContinuation(progress) {
    if(s.active?.stage!=='coder' || !progress?.timedOut)throw new Error('Only confirmed coding timeouts can continue automatically');
    if(!d.isSettled(s.active))throw new Error('Previous writer has not been confirmed closed; no replacement launched');
    if(progress.model!==s.active.model || !progress.attemptedModels?.length || progress.attemptedModels.some(m=>m!==s.active.model))throw new Error('Timed-out worker model evidence does not match the approved route');
    chargeCoding(progress);
    s.recoverySnapshot=snapshot();save();
    if(!s.timeouts)throw new Error('Legacy timeout budget requires explicit recovery via delivery_resume before continuing');
    const ledger=codingLedger();
    if(ledger.continuations>=1)throw new Error('One coding continuation already used; preserve changes and request a new budget/plan');
    const budget=attemptBudget(s.timeouts,'coder',ledger.spentMs,true);
    s.interruptions ||= [];
    s.interruptions.push({id:s.active.id,task:s.task,model:s.active.model,sessionFiles:progress.sessionFiles || [],snapshot:s.recoverySnapshot});
    ledger.continuations++;
    s.snapshot=s.recoverySnapshot;s.active=null;s.pendingContinuation=true;s.stage='coder';s.reason='';save();
    display(`Previous timed-out runner is closed. Continuing task ${s.task+1} from partial changes with ${s.routes.coder}, for up to ${Math.ceil(budget/60000)}m. Scope unchanged.`);
  }
  async function watchProgress(progress) {
    if(!progress || !['running','queued'].includes(progress.state))return;
    const now=d.now(),limits=s.timeouts || timeoutPolicy(config.timeouts);
    const deadline=progress.deadlineAt ?? (s.active.startedAt+s.active.budgetMs);
    const lead=Math.min(limits.deadlineWarningMs,(s.active.budgetMs || limits.coderMs)/5);
    if(Number.isFinite(deadline) && deadline>now && deadline-now<=lead && !s.active.deadlineWarned) {
      s.active.deadlineWarned=true;save();
      display(`Worker budget ends in about ${Math.ceil((deadline-now)/60000)}m. Requesting verification or a precise handoff; no deadline extension.`);
      try {await d.rpc(pi.events,'steer',{id:s.active.id,message:'Your current attempt is nearing its hard time limit. Prioritize verification of existing changes. Do not widen scope or skip tests. If unable to finish, preserve work and record exact remaining checks/blockers and evidence for continuation.'},5000);}
      catch(e){display(`Budget warning could not be delivered to the worker: ${e.message}`);}
    }
    const last=progress.lastActivityAt ?? progress.startedAt ?? s.active.startedAt;
    if(!progress.currentTool && Number.isFinite(last) && now-last>=limits.idleWarningMs && s.active.idleWarnedAt!==last) {
      s.active.idleWarnedAt=last;save();
      display('No recent recorded worker activity. It may still be generating or waiting on the provider; inspect status. This warning does not kill the run.');
    }
  }
  async function approveRecoveryPolicy() {
    const routes=validateRoutes(config.routes,available()),limits=timeoutPolicy(config.timeouts);
    if(JSON.stringify(routes)===JSON.stringify(s.routes) && JSON.stringify(limits)===JSON.stringify(s.timeouts))return;
    const baseline=snapshot();
    const changes=ROLES.filter(r=>routes[r]!==s.routes?.[r]).map(r=>`${r}: ${s.routes?.[r] || 'unset'} → ${routes[r]}`);
    const text=[`Continue task ${s.task+1}/${s.plan.tasks.length}; preserve and verify partial changes.`,...changes,`Recovery allowance: up to ${limits.continuationMs/60000}m, within the ${(limits.coderMs+limits.continuationMs)/60000}m total coding budget.`,`Selected providers receive the task context and previous run evidence. The old writer is confirmed closed. No new scope, commits or deployment.`].join('\n');
    if(!ctx.hasUI || !await ctx.ui.confirm('Approve changed recovery routes/budget?',text))throw new Error('Changed recovery routes/budget were not approved; partial work preserved');
    if(snapshot()!==baseline)throw new Error('Workspace changed during recovery approval; inspect changes first');
    s.routes=routes;s.timeouts=limits;save();
  }
  async function resumeOwned() {
    if(job)throw new Error('Delivery is already running');
    config=d.loadConfig(d.configPath());
    if(s.active?.id) {
      await d.rpc(pi.events,'status',{id:s.active.id});
      const progress=d.runProgress(s.active);
      if(progress?.timedOut && s.active.stage==='coder') {
        if(s.recoverySnapshot && snapshot()!==s.recoverySnapshot)throw new Error('Workspace changed after timeout; inspect changes and obtain fresh approval');
        if(!d.isSettled(s.active))throw new Error('Previous writer has not been confirmed closed; no replacement launched');
        await approveRecoveryPolicy();
        routeCheck();queueContinuation(progress);start();return;
      }
      s.stage=s.active.stage;
    } else if(s.pendingContinuation) {
      if(snapshot()!==s.snapshot)throw new Error('Workspace changed before continuation; inspect changes and obtain fresh approval');
      await approveRecoveryPolicy();s.stage='coder';
    }
    else if(s.resumeStage==='verification')s.stage='verification';
    else throw new Error('No retained run or safe continuation to resume');
    delete s.resumeStage;s.reason='';save();start();
  }
  async function runChecks({failureLabel,mutationLabel,fixable=false}) {
    checking=new AbortController();s.checks=[];save();
    for(const command of s.plan.checks) {
      const check=await d.verifyCommand(root,command,checking.signal);
      if(closed)return false;
      s.checks.push(check);save();
      if(mutationLabel && snapshot()!==s.snapshot)throw new Error(mutationLabel);
      if(check.code!==0 || check.terminated) {
        if(!fixable)throw new Error(`${failureLabel}: ${command}\n${check.output}`);
        s=advance({...s,stage:'checks'},{status:'changes_requested',summary:'Host verification failed',findings:[`${command}: ${check.output}`.slice(0,2000)]},s.snapshot);
        save();break;
      }
    }
    return true;
  }
  async function pump() {
    try {
      while(!closed && s.enabled && !['blocked','complete'].includes(s.stage)) {
        routeCheck();
        if(s.plan.reviewRange)d.assertCommittedWorkspace(root,s.plan.reviewRange);
        if(s.plan.mode==='review' && s.stage==='spec' && !s.reviewChecksDone) {
          if(snapshot()!==s.snapshot)throw new Error('Workspace changed before validation');
          if(!await runChecks({failureLabel:'Read-only validation check failed',mutationLabel:'Validation check modified source; review stopped'}))return;
          s.reviewChecksDone=true;save();
        }
        if(s.stage==='verification') {
          if(snapshot()!==s.snapshot) throw new Error('Workspace changed since review; reapproval required');
          if(!await runChecks({failureLabel:'Verification failed'}))return;
          s=advance(s,{verified:true},snapshot());save();
          display([s.plan.checks.length?'Delivery complete: required reviews and test commands passed.':'Static review complete. Tests were NOT run.',...s.reports.map(r=>`- ${r.stage}, task ${r.task+1}: ${r.report.status}`),...s.checks.map(c=>`- Test: ${c.command || 'approved command'} — exit ${c.code}`)].join('\n'));
          break;
        }
        if(!AGENTS[s.stage]) throw new Error('No approved execution stage');
        if(!s.active) {
          if(snapshot()!==s.snapshot) throw new Error('Workspace changed outside the approved run; reapproval required');
          // Persist launch reservation before RPC. A crash/timeout here must never replay a writer.
          const continuation=Boolean(s.pendingContinuation);
          const budgetMs=attemptBudget(s.timeouts || timeoutPolicy(config.timeouts),s.stage,s.stage==='coder'?codingLedger().spentMs:0,continuation);
          s.active={id:null,dir:null,model:s.routes[s.stage],stage:s.stage,budgetMs,startedAt:d.now(),continuation};delete s.pendingContinuation;save();
          const params={agent:AGENTS[s.stage],agentScope:'user',cwd:root,model:s.routes[s.stage],context:'fresh',async:true,task:briefing(s.stage),outputSchema:REPORT_SCHEMA,output:false,timeoutMs:budgetMs,share:false,acceptance:{level:'none',reason:'Delivery owns structured review and host verification gates'}};
          const launched=await d.rpc(pi.events,'spawn',params,60000);
          const details=launched.details;
          if(!details?.runId || !details?.asyncDir) throw new Error('Launch did not return a run ID and artifact directory; inspect subagent status before recovery');
          s.active={...s.active,id:details.runId,dir:details.asyncDir};
          if(closed) return;
          save();
        }
        if(!s.active.id) throw new Error('Uncertain launch; inspect subagent status. Automatic replay refused.');
        // Reconcile through the package before consuming its durable lifecycle artifacts.
        await d.rpc(pi.events,'status',{id:s.active.id});
        if(closed) return;
        const progress=d.runProgress(s.active);
        if(progress?.timedOut && s.stage==='coder') {
          if(!d.isSettled(s.active)) {
            if(s.active.awaitingCloseAt===undefined){s.active.awaitingCloseAt=d.now();save();}
            if(d.now()-s.active.awaitingCloseAt>60000)throw new Error('Timed-out writer closure is still unconfirmed; no replacement launched. Inspect runner status before recovery.');
            await sleep(d.pollMs);continue;
          }
          queueContinuation(progress);continue;
        }
        await watchProgress(progress);
        if(closed)return;
        const report=d.readOutcome(s.active);
        if(!report) {await sleep(d.pollMs);continue;}
        chargeCoding(progress);
        const id=s.active.id,wasCoder=s.stage==='coder';
        s=advance(s,report,snapshot());
        s.reports.at(-1).runId=id;save();
        if(wasCoder && s.stage==='spec') {
          if(!await runChecks({fixable:true,mutationLabel:'Verification changed reviewed source; reapproval required'}))return;
        }
        if(s.stage==='blocked') display(`Delivery blocked: ${s.reason}`);
      }
    } catch(e) {if(!closed)block(e);}
    finally {checking=undefined;}
  }
  function start() {if(job) return;job=pump().finally(()=>{job=null;});}

  pi.registerTool({name:'delivery_plan',label:'Delivery plan',description:'Route the requested task. mode=review starts read-only validation immediately; mode=implementation presents a readable plan for conversational approval. commits=N pins recent commits. checks are executable test commands only, not review criteria. start=false records a plan without executing it.',parameters:schemas.plan,
    async execute(_id,params,_signal,_update,c) {
      ctx=c;if(!s.enabled) throw new Error('Activate /delivery first');guardIdle();
      routeCheck();if(modelId(ctx.model)!==config.routes.planning) throw new Error('Wrong planning model; activate /delivery again');
      const plan=validatePlan(params);
      d.validateCommands(root,plan.checks);
      delete plan.sourcePlan;
      if(params.planFile) {
        const document=d.readPlan(root,params.planFile);
        if(fileIntent && (document.path!==fileIntent.path || document.hash!==fileIntent.hash))throw new Error('Source plan changed since the execution request; ask for approval of the changed document.');
        plan.sourcePlan={path:document.path,hash:document.hash};
      }
      delete plan.reviewRange; // Only this extension resolves and pins revision identities.
      if(plan.mode==='review' && plan.commits) {
        plan.reviewRange=d.revisionRange(root,plan.commits);
        d.assertCommittedWorkspace(root,plan.reviewRange);
      }
      const coverageWarnings=[],hash=snapshot(plan,coverageWarnings);
      const timeouts=timeoutPolicy(config.timeouts);
      const fileApproved=fileIntent && plan.sourcePlan?.path===fileIntent.path && plan.sourcePlan.hash===fileIntent.hash;
      if(fileApproved && (hash!==fileIntent.snapshot || JSON.stringify(routeCheck())!==JSON.stringify(fileIntent.routes) || JSON.stringify(timeouts)!==JSON.stringify(fileIntent.timeouts)))throw new Error('Workspace or routes changed since the file execution request; refresh approval.');
      s={...initialState(),enabled:true,plan,coverageWarnings,timeouts,stage:'awaiting-approval',snapshot:hash};approvalTurn=null;save();
      display(readablePlan(config.routes));
      if(fileApproved && params.start!==false) {
        await launchApproved();
        return result('Execution of the requested Markdown plan started. No additional approval needed. Use delivery_status for progress.');
      }
      if(plan.mode==='review' && requestText && params.start!==false) {
        await launchApproved();
        return result('Read-only validation started. No coder or automatic fixes. Use delivery_status for progress.');
      }
      return result('Plan ready. Ask for conversational approval. After the user agrees, call delivery_execute; do not send them to a slash command.',{plan,routes:config.routes,workspace:root});
    }});
  pi.registerTool({name:'delivery_execute',label:'Execute requested plan',description:'Use ONLY for an explicit real-user request to execute a plan, never a question, rejection or planning-only request. For an existing Markdown document pass planFile: it is read and bound to this execution request; then derive its tasks via delivery_plan with the same planFile. No prior registration or repeated approval is required. Without planFile, execute the conversationally approved pending plan. Do not widen scope or resolve real product ambiguities silently.',parameters:schemas.execute || schemas.empty,async execute(_id,params={},_signal,_update,c){
    ctx=c;if(!s.enabled)throw new Error('Activate delivery first');guardIdle();
    if(modelId(ctx.model)!==config.routes.planning)throw new Error('Wrong planning model; reactivate delivery');
    const references=[...new Set(requestText.match(/docs\/spark\/plans\/[^\s"'`]+\.md/g) || [])];
    const path=params.planFile || (s.stage!=='awaiting-approval' && references.length===1?references[0]:undefined);
    if(path) {
      if(!requestText.trim())throw new Error('A real user request to execute this document is required');
      const document=d.readPlan(root,path);
      const baseline=snapshot(null),routes=routeCheck(),timeouts=timeoutPolicy(config.timeouts);
      if(fileIntent && (document.path!==fileIntent.path || document.hash!==fileIntent.hash || baseline!==fileIntent.snapshot || JSON.stringify(routes)!==JSON.stringify(fileIntent.routes) || JSON.stringify(timeouts)!==JSON.stringify(fileIntent.timeouts)))throw new Error('Plan, workspace or routes changed since this execution request; a fresh user request is required.');
      fileIntent={path:document.path,hash:document.hash,snapshot:baseline,routes,timeouts};
      approvalTurn=null;
      return result(`Execution request accepted for ${document.path}. Read this authoritative plan, resolve genuine ambiguities if any, and call delivery_plan with planFile="${document.path}", preserving its task boundaries and constraints. Supply actual executable tests, not prose. Do not combine the entire plan into one task or expand scope. The unchanged requested document will execute without asking for approval again. No work has launched yet.\n\n${document.content}`,{sourcePlan:{path:document.path,hash:document.hash}});
    }
    if(!approvalTurn || approvalTurn.key!==planKey())throw new Error('A fresh user reply approving this pending plan is required; for an existing Markdown plan supply planFile');
    await launchApproved();return result('Execution started. Use delivery_status for actual progress.');
  }});
  pi.registerTool({name:'delivery_resume',label:'Continue approved delivery',description:'Continue an already approved interrupted task without changing scope or models. Confirmed coding timeouts allow one bounded same-model continuation after runner closure. Legacy budget changes require user confirmation; arbitrary failures are not auto-retried.',parameters:schemas.empty,async execute(_id,_params,_signal,_update,c){ctx=c;if(!s.enabled)throw new Error('Activate delivery first');await resumeOwned();return result('Recovery started. Use delivery_status for actual progress.');}});
  pi.registerTool({name:'delivery_status',label:'Delivery status',description:'Read actual delivery state, approved routes and evidence.',parameters:schemas.empty,async execute(){return result(status(),structuredClone(s));}});
  pi.registerTool({name:'delivery_diff',label:'Delivery diff',description:'Read git status and diff in 40k-character pages; pass offset to continue. Pass commits=N for the last N commits with pinned revisions and subjects. Defaults to proposed committed range or working-tree changes.',parameters:schemas.diff || schemas.empty,async execute(_id,params={}){if(!s.enabled)throw new Error('Activate /delivery');const count=params.commits ?? s.reviewCommits;const range=params.commits!==undefined?d.revisionRange(root,params.commits):(s.plan?.reviewRange || (count?d.revisionRange(root,count):undefined));const offset=params.offset ?? 0;if(!Number.isInteger(offset)||offset<0)throw new Error('Invalid diff offset');return result(d.diff(root,range,40000,offset),range || {});}});

  pi.registerCommand('delivery',{
    description:'Delivery: describe a task; setup, models, status, resume, off',
    getArgumentCompletions:prefix=>['setup','models','status','resume','off'].filter(x=>x.startsWith(prefix)).map(x=>({value:x,label:x})),
    async handler(args,c) {
      ctx=c;
      try {
        if(!root) root=d.repoRoot(ctx.cwd);
        config=d.loadConfig(d.configPath());
        const command=args.trim();
        if(command==='status') {display(status()+'\n'+JSON.stringify(s,null,2));return;}
        if(command==='models') {
          const rows=catalog(ctx.modelRegistry.getAll(),ctx.modelRegistry.getAvailable());
          const cli=['claude','codex','cursor-agent'].map(name=>({name,installed:(process.env.PATH||'').split(':').some(dir=>{try{accessSync(join(dir,name),constants.X_OK);return true;}catch{return false;}})}));
          display(JSON.stringify({models:rows,externalCli:cli,note:'Available means locally configured, not tested/qualified. External CLIs are discovery-only, not delivery execution routes. No inference was run.'},null,2));return;
        }
        if(command==='setup') {
          guardIdle();if(!ctx.hasUI){display('Run /delivery setup in interactive pi to select routes and approve provider access.');return;}
          const models=ctx.modelRegistry.getAvailable();
          const choices=models.map(modelId).sort();if(!choices.length)throw new Error('No configured models. Configure a provider with /login, then reload.');
          const next=structuredClone(config);
          delete next.evidence; // Retire legacy trial/evidence markers without changing saved routes.
          for(const role of ROLES) {
            const preferred=next.routes[role] || (role==='planning'?ASTRA:null);
            const ordered=[...choices].sort((a,b)=>a===preferred?-1:b===preferred?1:a.localeCompare(b));
            const options=ordered.map(id=>({id,label:modelLabel(models.find(m=>modelId(m)===id))}));
            const selected=await ctx.ui.select(`Delivery ${role}: ${ROLE_HELP[role]}\nContext/output are token limits; prices are catalog estimates, not actual billing. Availability is not a quality ranking.`,options.map(o=>o.label));
            if(!selected)return;
            const choice=options.find(o=>o.label===selected);
            if(!choice)throw new Error('Selected model is no longer available; rerun setup.');
            next.routes[role]=choice.id;
          }
          if(!await ctx.ui.confirm('Save delivery routes and provider permission?',JSON.stringify(next.routes,null,2)+'\nSelected providers receive project context. No inference probes are run. Model metadata is not a performance guarantee. Plan approval, tests and independent reviews remain required; sensitive changes require security review.'))return;
          if(await ctx.ui.confirm('Enable automatic delivery in this repository?',root))next.repos=[...new Set([...next.repos,root])];
          d.saveConfig(d.configPath(),next);config=next;s=initialState();await activate();display('Delivery setup saved. Describe your task normally. Reviews run directly; implementation waits for your conversational approval.');return;
        }
        if(command==='off') {
          if(s.active && !d.isSettled(s.active)) {
            if(!s.active.id)throw new Error('Uncertain child launch. Inspect subagent status before disabling delivery.');
            await d.rpc(pi.events,'stop',{id:s.active.id});
            throw new Error('Stop requested; keep delivery active until the child settles. Inspect status before retrying off.');
          }
          if(job)throw new Error('Wait for delivery to settle before disabling it.');
          s.active=null;s.enabled=false;if(originalTools)pi.setActiveTools(originalTools);save();return;
        }
        if(command==='approve') {
          if(!ctx.hasUI){display('Approval requires the interactive command confirmation.');return;}
          const {routes}=pendingExecution();
          if(!await ctx.ui.confirm('Run this delivery plan?',readablePlan(routes)))return;
          await launchApproved();return;
        }
        if(command==='resume') {
          await resumeOwned();return;
        }
        guardIdle();
        requestText=command;approvalTurn=null;fileIntent=null;
        s={...initialState(),enabled:true};await activate();
        if(command && !s.reason)pi.sendUserMessage(command,{deliverAs:'followUp'});
        else display(status());
      } catch(e) {display(`Delivery: ${e.message}`);ctx.ui.notify(e.message,'error');}
    }
  });
  pi.on('session_start',async(_e,c)=>{
    ctx=c;closed=false;
    try {
      root=d.repoRoot(ctx.cwd);config=d.loadConfig(d.configPath());
      const entries=ctx.sessionManager.getBranch();
      const saved=entries.filter(e=>e.type==='custom'&&e.customType===ENTRY).at(-1)?.data;
      if(saved?.workspace===root && saved.owner===ctx.sessionManager.getSessionId())s=structuredClone(saved);
      else s=initialState();
      if(saved?.active && saved.owner!==ctx.sessionManager.getSessionId()) {s.enabled=true;s.reason='Forked delivery run: return to owning session; no automatic replay';s.stage='blocked';}
      else if(!saved)s.enabled=config.repos.includes(root);
      if(s.enabled) {
        restrict();await selectPlanning();
        if(s.active) {s.stage='blocked';s.reason='Retained child requires /delivery resume reconciliation';}
        else if(!['planning','awaiting-approval','complete','blocked'].includes(s.stage)) {s.resumeStage=s.stage;s.stage='blocked';s.reason=s.resumeStage==='verification'?'Interrupted verification; /delivery resume reruns approved checks':'Interrupted between stages; propose a fresh plan, no automatic replay';}
        else {try{validateRoutes(config.routes,available());}catch(e){s.reason=e.message;}}
      }
      save();
    }catch(e){ctx.ui.setStatus('delivery',`Delivery OFF · ${e.message}`);}
  });
  pi.on('input',async(e,c)=>{
    ctx=c;
    if(['interactive','rpc'].includes(e.source)) {
      requestText=e.text || '';fileIntent=null;
      approvalTurn=s.stage==='awaiting-approval' && requestText.trim()?{key:planKey(),text:requestText}:null;
    }
    if(!s.enabled && /^\/skill:orchestrate-delivery(?:\s|$)/.test(e.text || '')) {
      try {root=d.repoRoot(ctx.cwd);config=d.loadConfig(d.configPath());await activate();}
      catch(error){display(`Delivery activation failed: ${error.message}`);return {action:'handled'};}
    }
    if(!s.enabled)return;
    if(!await selectPlanning()){display(status());return {action:'handled'};}
    // Discussion stays possible with missing coder routes; proposing/executing a plan remains blocked.
    return {action:'continue'};
  });
  pi.on('before_agent_start',async(e,c)=>{
    ctx=c;if(!s.enabled)return;restrict();
    if(modelId(ctx.model)!==(config.routes.planning||ASTRA) && !await selectPlanning()){ctx.abort?.();return;}
    return {systemPrompt:e.systemPrompt+'\n\nDELIVERY MODE ACTIVE. You are the planning/orchestration parent, never the implementer. Infer task intent from the user message AND conversation, not a command or keyword. Select relevant installed SPARK skills lazily: reviews use requesting-code-review/audit, bugs use debugging, new features use brainstorming/planning. UI work also uses available frontend/design/accessibility skills; pass selected skill paths and design requirements in task instructions. Do not invent missing skills. For review/validation requests, inspect delivery_diff (commits=N for recent commits), then call delivery_plan with mode=review: this starts reviewers automatically, with no coder or fixes. Do not ask for approval for the requested read-only review. Set start=false ONLY if the user asked for a plan without execution. Review criteria go in task.acceptance; checks contains actual executable test commands, NEVER prose. Use checks=[] for static review and disclose tests not run. When the user explicitly requests execution of an existing Markdown plan, call delivery_execute with planFile even after reload; it adopts the file and returns instructions for deriving its tasks through delivery_plan. Preserve all task boundaries and global constraints. Do not demand prior registration or another approval for the same unchanged document. If unresolved scope/product decisions genuinely prevent execution, clarify rather than guess. Out-of-scope broken/external symlinks are coverage warnings, not reasons to demand repository repairs; do not follow or depend on their targets. For new changes, show a concise human-readable plan using delivery_plan with mode=implementation; wait for the user to agree in conversation, then CALL delivery_execute immediately. Do not merely promise to execute. Rejections, questions and requested revisions are not approval; clarify genuinely ambiguous intent. Never instruct the user to run /delivery approve or select a review mode. If a run blocked because checks were invalid, prepare corrected executable checks and retry the requested review through delivery_plan, not another approval command. Read/search and delivery tools are available; parent shell/edit/write and direct child execution are blocked. The extension owns coder/reviewer execution. During a run, answer without changing scope. Coding timeouts have one bounded same-model continuation; do not request approval again for that already approved allowance. For retained interrupted work, use delivery_resume, not a new implementation plan or direct subagent launch. If configured routes or budgets changed, delivery_resume offers a single explicit confirmation while retaining the partial workspace; do not try to replace an owned run with delivery_plan. Budget warnings are not proof of a stalled provider; a quiet running tool must not be killed. Only delivery_status establishes completion; never claim unrun checks or blocked work passed.\nCurrent state: '+status()};
  });
  pi.on('tool_call',async(e,c)=>{
    if(s.enabled && e.toolName==='subagent_supervisor' && e.input?.action==='reply') {
      const ok=s.active?.id && c.hasUI && await c.ui.confirm('Approve supervisor reply?',JSON.stringify(e.input)+'\nDo not approve scope/model changes here; those require a new delivery plan.');
      return ok?undefined:{block:true,reason:'Supervisor response needs explicit user approval'};
    }
    if(s.enabled && !parentToolAllowed(e.toolName,e.input)) return {block:true,reason:'Delivery mode: parent mutation/unmanaged delegation is blocked. Use delivery_plan to route work; after explicit conversational approval use delivery_execute.',terminate:true};
  });
  pi.on('user_bash',()=>s.enabled?{result:{output:'Delivery mode blocks shell shortcuts. Use /delivery off explicitly for manual work.',exitCode:1,cancelled:false,truncated:false}}:undefined);
  pi.on('session_before_tree',()=>s.enabled?{cancel:true}:undefined);
  pi.on('session_shutdown',()=>{closed=true;checking?.abort();});
  return {state:()=>structuredClone(s),settled:()=>job||Promise.resolve()};
}
