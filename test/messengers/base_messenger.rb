class BaseMessenger < Texting::Base
  def welcome(hash = {})
    text to: hash[:to] || '909-390-0003', body: 'Welcome!'
  end

  def without_text_call
    # no-op.
  end
end
