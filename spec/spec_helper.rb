require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'reverse_xslt'

require 'token_helper'

RSpec.configure do |c|
  c.extend TokenHelper
end
