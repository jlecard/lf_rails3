require 'sys/proctable'
include Sys

nb = 0
ProcTable.ps{|proc_struct|
  proc_struct.cmdline
  if proc_struct.cmdline.match(/bash/) && proc_struct.pid != $$
    nb += 1
  end

}

p nb 