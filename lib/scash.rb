require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "scash/version"

class Scash
  include Enumerable
  delegate  :each, :empty?, :eql?, :has_key?, :has_value?, :include?, :index,
            :keys, :merge, :reject, :replace, :select, :size, :values, :to => :to_hash

  def initialize(variables = {})
    raise NotImplementedError if variables.any?
    @stack, @hashes, @inverse_hashes = [], [{}], [{}]
  end

  def to_hash
    @hashes[0]
  end

  def to_inverse_hash
    @inverse_hashes[0]
  end

  def scope(variables)
    @stack.unshift variables.with_indifferent_access
    @hashes.unshift build_hash
    @inverse_hashes.unshift build_inverse_hash
    before_scope
    yield
  ensure
    @stack.shift
    @hashes.shift
    @inverse_hashes.shift
    after_scope
  end
  alias :with :scope

  def before_scope
  end

  def after_scope
  end

  def [](key, inverse = false)
    if inverse
      to_inverse_hash[key]
    else
      to_hash[key]
    end
  end

private

  def build_hash
    @stack.inject({}) do |hash, variables|
      variables.merge hash
    end
  end

  def build_inverse_hash
    @stack.inject({}) do |hash, variables|
      hash.merge variables
    end
  end
end
