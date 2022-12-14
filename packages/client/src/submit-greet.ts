import { Connection, WorkflowClient } from "@temporalio/client";
import type * as workflows from "@example/workflows";
import { nanoid } from "nanoid";

async function run() {
  const connection = await Connection.connect({ address: "temporalite" });

  const client = new WorkflowClient({ connection });

  const handle = await client.start<typeof workflows.example>("example", {
    args: ["Temporal"],
    taskQueue: "hello-world",
    workflowId: "workflow-" + nanoid(),
  });
  console.log(`Started workflow ${handle.workflowId}`);

  console.log(await handle.result());
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
