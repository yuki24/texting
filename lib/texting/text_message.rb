module Texting
  class TextMessage
    attr_accessor :from, :to, :body, :options

    def initialize(from: , to: , body: , **options)
      @from, @to, @body, @options = from, to, body, options
    end

    def process
      yield
    end
  end
end
