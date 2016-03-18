## -*- mode: ruby -*-
## short sleep mode
##  shorten sleep duration uniformly.
## usage: % ruby shortsleep <script>

alias origSleep sleep ;

$sleepShortenFactor = 100.0 ;

def sleep(sec)
  origSleep(sec/$sleepShortenFactor)
end

if($0 == __FILE__) then
  load(ARGV[0])
end
