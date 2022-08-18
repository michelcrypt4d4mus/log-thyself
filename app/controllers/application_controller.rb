class ApplicationController < ActionController::Base
  before_action :there_is_no_spoon

  def there_is_no_spoon
    raise 'There is no spoon'
  end
end
