#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = problem trial
## Author:: Itsuki Noda
## Version:: 0.0 2017/03/06 I.Noda
##
## === History
## * [2017/03/06]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

$LOAD_PATH.push("~/lib/ruby");

require 'optparse' ;
require 'pp' ;

#------------------------------------------------------------------------
#++
$conf = {
  :foo => false,
  :bar => 1,
  :baz => "test",
} ;

#------------------------------------------------------------------------
#++
$op = OptionParser.new() {|op|
  op.banner = <<_END_
  Usage: #{$0} [Options]*
_END_

  op.separator("Options:") ;
  op.set_summary_indent("") ;
  op.set_summary_width(60) ;
  sep = "\n\t\t" ;

  op.on("-f","--[no-]foo", sep + "switch foo.") {|foo|
    $conf[:foo] = foo ;
  }
  op.on("-b","--bar BarVal", Integer, sep + "bar int value.") {|bar|
    $conf[:bar] = bar ;
  }
  op.on("-z","--baz BazVal", String, sep + "baz str value.") {|baz|
    $conf[:baz] = baz ;
  }
  op.on_tail("--help", sep + "show this message.") { |h|
    puts(op)
    puts("Defaults:")
    pp $conf ;
    exit(1)
  }
}

$op.parse!(ARGV) ;
$restArg = ARGV ;
p [:rest, ARGV], [:conf,$conf] ; 

#------------------------------------------------------------------------
#++
## check mod

def checkMod(x, y)
  r = x.to_i % y.to_i ;
  return r == 0 ;
end
  
#------------------------------------------------------------------------
#++
## check dividable by 3m_2

def checkDiv3m_2(x)
  m = 0 ;
  y = 0 ;
  flag = false ;
  begin
    y = 3 * m + 2 ;
    flag = checkMod(x, y) ;
    m += 1 ;
  end until(flag || y > x / 2)
  return flag ;
end

#------------------------------------------------------------------------
#++
## check n

def checkN(n)
  x = n * n + n + 1 ;
  f = checkDiv3m_2(x) ;
  p [n, x, f]
  return 
end

#------------------------------------------------------------------------
#++
## check all

def checkAll(max)
  (0...max).each{|n|
    checkN(n) ;
  }
end


########################################################################
########################################################################
########################################################################

checkAll(1000) ;
