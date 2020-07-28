module Workr::Models
  record JobInfo,
    name : String,
    path : String,
    entrypoint : String

  record JobExecutionData,
    id : UInt32
end
