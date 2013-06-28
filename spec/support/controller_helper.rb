module ControllerHelper
  def default_url_options
    {}
  end

  def get(action, params = {}, session = nil, flash = nil)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, default_url_options.merge(params), session, flash)
  end

  def put(action, params = {}, session = nil, flash = nil)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, default_url_options.merge(params), session, flash)
  end

  def post(action, params = {}, session = nil, flash = nil)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, default_url_options.merge(params), session, flash)
  end

  def delete(action, params = {}, session = nil, flash = nil)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, default_url_options.merge(params), session, flash)
  end

end
