module Texting
  class TextMessage
    attr_accessor :to, :body

    def initialize(to:, body: )
      @to, @body = to, body
    end

    def process
      yield
    end
  end
end
