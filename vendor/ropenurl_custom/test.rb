# run the ropenurl test suite!

# use local ropenurl in preference to installed one
$LOAD_PATH.unshift("lib")

# load testing framework
require 'test/unit'

# load ropenurl 
require 'ropenurl'

# now load and execute each test case
require 'test/tc_context_object'
