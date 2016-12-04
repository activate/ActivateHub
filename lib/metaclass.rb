# http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html

class Object
  # The hidden singleton lurks behind everyone
  def metaclass; class << self; self; end; end
  def meta_eval(&blk); metaclass.instance_eval(&blk); end
end
