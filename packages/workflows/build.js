const { bundleWorkflowCode } = require("@temporalio/worker");
const { mkdir, writeFile } = require("fs/promises");
const path = require("path");

async function bundle() {
  const { code } = await bundleWorkflowCode({
    workflowsPath: path.join(__dirname, "./src"),
  });
  const codePath = path.join(__dirname, "./dist/index.js");

  await mkdir(path.dirname(codePath), { recursive: true });
  await writeFile(codePath, code);

  console.log(`Bundle written to ${codePath}`);
}

bundle().catch((err) => {
  console.error(err);
  process.exit(1);
});
