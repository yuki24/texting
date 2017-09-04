class BaseTexter < Texting::Base
  def welcome(hash = {})
    text to: '909-390-0003', body: 'Welcome!'
  end

  def without_text_call
    # no-op.
  end
end
