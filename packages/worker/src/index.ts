import { NativeConnection, Worker } from "@temporalio/worker";
import * as activities from "@example/activities";

async function run() {
  const connection = await NativeConnection.connect({ address: "temporalite" });

  const worker = await Worker.create({
    connection,
    workflowBundle: {
      codePath: "/app/node_modules/@example/workflows/dist/index.js",
      sourceMapPath:
        "/app/node_modules/@example/workflows/dist/index.sourcemap.js",
    },
    activities,
    taskQueue: "example-queue",
  });

  await worker.run();
}

console.log(`Worker -- Starting.`);
run()
  .catch((err) => {
    console.error(err);
  })
  .finally(() => {
    console.log(`Worker -- Exiting.`);
  });
