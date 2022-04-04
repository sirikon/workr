import { NomadConfiguration } from "./core/models.ts";
import { queueJob } from "./nomad/mod.ts";

const config: NomadConfiguration = {
  apiUrl: "http://127.0.0.1:4646",
  datacenters: ["dc1"],
};

const result = await queueJob(config, {
  name: "example",
  execution: new Date().getTime(),
  work: {
    kind: "docker",
    image: "ubuntu:focal",
    cmd: [
      "bash",
      "-c",
      'for i in {1..10}\ndo\necho "Log line number #$i"\nsleep 1\ndone\nexit 1',
    ],
  },
});

console.log(
  `${config.apiUrl}/ui/allocations/${result.allocationId}/task/logs`,
);
