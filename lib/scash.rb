require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "scash/version"

class Scash
  include Enumerable
  delegate  :each, :empty?, :eql?, :has_key?, :has_value?, :include?, :index,
            :keys, :merge, :reject, :replace, :select, :size, :values, :to => :to_hash

  attr_reader :stack

  def initialize(variables = {})
    raise NotImplementedError if variables.any?
    @stack = []
  end

  def to_hash
    @stack.inject(HashWithIndifferentAccess.new) do |hash, variables|
      variables.merge hash
    end
  end

  def to_inverse_hash
    @stack.inject(HashWithIndifferentAccess.new) do |hash, variables|
      hash.merge variables
    end
  end

  def scope(variables)
    @stack.unshift variables.with_indifferent_access
    yield
  ensure
    @stack.shift
  end
  alias :with :scope

  def [](key, inverse = false)
    if inverse
      to_inverse_hash[key]
    else
      to_hash[key]
    end
  end

  def define_global_variable(key, value)
    define_global_variables key => value
  end

  def define_global_variables(variables)
    variables.each do |key, value|
      delete_key(key)
    end

    @stack.push variables.with_indifferent_access
  end

  private

  def delete_key(key)
    @stack.each{|hash|hash.delete(key)}
  end
end
