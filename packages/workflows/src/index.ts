import { proxyActivities } from "@temporalio/workflow";
import type * as activities from "@example/activities";

const { greet } = proxyActivities<typeof activities>({
  startToCloseTimeout: "1 minute",
});

export async function example(name: string): Promise<string> {
  return await greet(name);
}
