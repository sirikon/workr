module Workr::Models
  record JobInfo,
    name : String,
    path : String,
    entrypoint : String

  record JobExecutionData,
    id : UInt32,
    start_date : Time,
    end_date : Time?,
    finished : Bool
end
