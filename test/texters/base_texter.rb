class BaseTexter < Texting::Base
  def welcome(hash = {})
    text to: '909-390-0003', body: 'Welcome!'
  end
end
