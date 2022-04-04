const resp = await fetch("http://127.0.0.1:4646/v1/jobs", {
  method: "POST",
  body: JSON.stringify({
    Job: {
      ID: "example-2",
      Datacenters: ["dc1"],
      Type: "batch",
      TaskGroups: [
        {
          Name: "example-g",
          Tasks: [
            {
              Name: "example-t2",
              Driver: "docker",
              Config: {
                image: "ubuntu:focal",
                command: "bash",
                args: [
                  "-c",
                  'for i in {1..100000}\ndo\necho "Log line number #$i"\nsleep 1\ndone',
                ],
              },
              Restart: {
                Attempts: 0,
              },
              Reschedule: {
                Attempts: 0,
              },
            },
          ],
        },
      ],
    },
  }),
  headers: {
    "Content-Type": "application/json",
    "Accepts": "application/json",
  },
});
if (resp.status >= 400) {
  console.log(await resp.text());
}
const result = await resp.json();
const resp2 = await fetch(
  "http://127.0.0.1:4646/v1/evaluation/" + result.EvalID + "/allocations",
);
if (resp2.status >= 400) {
  console.log(await resp.text());
}

const result2 = await resp2.json();
console.log(
  `http://localhost:4646/ui/allocations/${result2[0].ID}/example-t2`,
);
