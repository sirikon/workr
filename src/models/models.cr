module Workr::Models
  record JobInfo,
    name : String,
    path : String,
    entrypoint : String

  record JobData,
    name : String,
    latest_execution_id : UInt32

  record JobExecutionData,
    id : UInt32,
    start_date : Time,
    end_date : Time?,
    finished : Bool,
    exit_code : Int32?
end
