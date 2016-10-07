module ReverseXSLT::Error
  class ConsecutiveValueOfToken < StandardError; end
  class DisallowedMatch < StandardError; end
  class IllegalToken < StandardError; end # when tree contains illegal token
  class MalformedTree < StandardError; end

  # match function require array on the input, this error is raised otherwise
  class IllegalMatchUse < StandardError; end

  # throw when there are two value-of matches with the same name
  class DuplicatedTokenName < StandardError; end

  # raised when if/for-each token produce multiple matching
  class AmbiguousMatch < StandardError; end
end
