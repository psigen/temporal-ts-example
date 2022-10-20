import { Connection, WorkflowClient } from "@temporalio/client";
import type * as workflows from "@example/workflows";
import { nanoid } from "nanoid";

async function run() {
  const connection = await Connection.connect({ address: "temporalite" });

  const client = new WorkflowClient({ connection });

  const handle = await client.start<typeof workflows.example>("example", {
    // type inference works! args: [name: string]
    args: ["Temporal"],
    taskQueue: "hello-world",
    // in practice, use a meaningful business id, eg customerId or transactionId
    workflowId: "workflow-" + nanoid(),
  });
  console.log(`Started workflow ${handle.workflowId}`);

  // optional: wait for client result
  console.log(await handle.result()); // Hello, Temporal!
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
