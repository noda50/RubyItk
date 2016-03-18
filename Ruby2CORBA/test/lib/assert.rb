 
 module TestUtil
 
  module Assertions
    def assert(message = 'Assertion failed', boolean = nil, &block)
      raise ArgumentError, '#assert requires a boolean or a block' unless !boolean.nil? or block_given?
      boolean = yield if boolean.nil?
      raise message unless boolean
    end
    
    def assert_not(message = 'Assertion failed', boolean = nil, &block)
      raise ArgumentError, '#assert requires a boolean or a block' unless !boolean.nil? or block_given?
      boolean = yield if boolean.nil?
      raise message unless !boolean
    end
  end
  
end

