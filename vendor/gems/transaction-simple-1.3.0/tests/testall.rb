#!/usr/bin/env ruby
#--
# Ruwiki
#   Copyright © 2002 - 2003, Digikata and HaloStatue
#   Alan Chen (alan@digikata.com)
#   Austin Ziegler (ruwiki@halostatue.ca)
#
# Licensed under the same terms as Ruby.
#
# $Id: testall.rb,v 1.1 2005/05/05 16:16:49 austin Exp $
#++

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

$stderr.puts "Checking for test cases:"
Dir['tc_*.rb'].each do |testcase|
  $stderr.puts "\t#{testcase}"
  load testcase
end
$stderr.puts " "
