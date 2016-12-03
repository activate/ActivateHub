module ControllerHelper
  def default_url_options
    {}
  end

  def get(action, params: {}, **others)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, params: default_url_options.merge(params), **others)
  end

  def put(action, params: {}, **others)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, params: default_url_options.merge(params), **others)
  end

  def post(action, params: {}, **others)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, params: default_url_options.merge(params), **others)
  end

  def delete(action, params: {}, **others)
    @request.host = ENV['TEST_REQ_HOST']
    super(action, params: default_url_options.merge(params), **others)
  end

end
