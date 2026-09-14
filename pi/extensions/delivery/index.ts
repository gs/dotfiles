import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import { registerDelivery } from './extension.mjs';

export default function (pi: ExtensionAPI) {
  registerDelivery(pi, {
    empty: Type.Object({}),
    execute: Type.Object({planFile: Type.Optional(Type.String({description:'Existing Markdown plan under docs/spark/plans/ explicitly requested for execution; no prior registration needed.'}))}),
    diff: Type.Object({ offset: Type.Optional(Type.Integer({minimum:0,description:'Continue a truncated diff from this character offset.'})), commits: Type.Optional(Type.Integer({ minimum: 1, maximum: 20, description: 'Read the last N committed changes rather than the working-tree diff.' })) }),
    plan: Type.Object({
      planFile: Type.Optional(Type.String({description:'Authoritative existing Markdown plan. After delivery_execute adopts it, derive its tasks here without changing scope; execution starts without repeated approval.'})),
      mode: Type.String({enum:['implementation','review'],description:'Infer from the request/context: review runs immediately without a coder; implementation waits for conversational approval.'}),
      start: Type.Optional(Type.Boolean({description:'Set false only when the user requested a plan without execution.'})),
      commits: Type.Optional(Type.Integer({minimum:1,maximum:20,description:'In review mode, pin the last N commits for validation.'})),
      title: Type.String({ maxLength: 200 }),
      tasks: Type.Array(Type.Object({
        title: Type.String({ maxLength: 200 }),
        instructions: Type.String({ maxLength: 16000 }),
        files: Type.Array(Type.String(), { minItems: 1, maxItems: 100 }),
        acceptance: Type.Array(Type.String(), { minItems: 1, maxItems: 30 }),
      }), { minItems: 1, maxItems: 12 }),
      checks: Type.Array(Type.String({description:'An actual executable test command, e.g. bundle exec rails test. NEVER a checklist sentence. Put human review criteria in task.acceptance.'}), { minItems: 0, maxItems: 10, description:'Executable test commands only. [] permits static review without claiming tests ran.' }),
      risk: Type.String({ description: 'low for ordinary bounded changes; high for security-sensitive work', enum: ['low', 'high'] }),
      security: Type.Boolean({ description: 'Request independent security review; sensitive paths force it on.' }),
    }),
  });
}
