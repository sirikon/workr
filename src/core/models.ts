export type NomadConfiguration = {
  apiUrl: string;
  datacenters: string[];
};

export type JobDefinition = {
  name: string;
  execution: number;
  work:
    | {
      kind: "docker";
      image: string;
      cmd: [string, ...string[]];
    }
    | {
      kind: "raw_exec";
      cmd: [string, ...string[]];
    };
};
