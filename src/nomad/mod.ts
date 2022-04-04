import { JobDefinition, NomadConfiguration } from "../core/models.ts";

export async function queueJob(
  config: NomadConfiguration,
  job: JobDefinition,
): Promise<{ allocationId: string }> {
  const evaluation = await fetchApi<{ EvalID: string }>(
    config,
    "POST",
    "/v1/jobs",
    {
      Job: {
        ID: `${job.name}-${job.execution}`,
        Datacenters: config.datacenters,
        Type: "batch",
        TaskGroups: [
          {
            Name: "tasks",
            Tasks: [
              {
                Name: "task",
                ...(() => {
                  const kind = job.work.kind;

                  if (kind === "docker") {
                    return {
                      Driver: "docker",
                      Config: {
                        image: job.work.image,
                        command: job.work.cmd[0],
                        args: job.work.cmd.slice(1),
                      },
                    };
                  }

                  if (kind === "raw_exec") {
                    return {
                      Driver: "raw_exec",
                      Config: {
                        command: job.work.cmd[0],
                        args: job.work.cmd.slice(1),
                      },
                    };
                  }

                  ((x: never) => {})(kind);
                })(),
              },
            ],
            RestartPolicy: {
              Attempts: 0,
              Mode: "fail",
            },
            ReschedulePolicy: {
              Attempts: 0,
              Unlimited: false,
            },
          },
        ],
      },
    },
  );

  const allocations = await fetchApi<{ ID: string }[]>(
    config,
    "GET",
    "/v1/evaluation/" + evaluation.EvalID + "/allocations",
  );

  const firstAllocation = allocations.length > 0 ? allocations[0] : null;
  if (firstAllocation == null) {
    throw new Error("No allocations after creation");
  }

  return { allocationId: firstAllocation.ID };
}

async function fetchApi<R extends unknown>(
  config: NomadConfiguration,
  method: "GET" | "POST",
  path: string,
  body?: unknown,
): Promise<R> {
  const response = await fetch(config.apiUrl + path, {
    method,
    body: method === "POST" && body ? JSON.stringify(body) : null,
    headers: {
      "Content-Type": "application/json",
    },
  });
  if (response.status >= 400) {
    throw new Error(await response.text());
  }
  return await response.json();
}
