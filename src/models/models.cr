module Workr::Models
  record JobInfo,
    name : String,
    path : String,
    entrypoint : String

  record JobExecutionInfo,
    id : String
end
