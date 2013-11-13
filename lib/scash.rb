require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module/delegation"
require "scash/version"

class Scash
  include Enumerable
  delegate  :each, :empty?, :eql?, :has_key?, :has_value?, :include?, :index,
            :keys, :merge, :reject, :replace, :select, :size, :values, :to => :to_hash

  attr_reader :stack

  def initialize(variables = nil, klass = HashWithIndifferentAccess)
    @klass = klass
    @stack = variables ? [convert(variables)] : []
    @hashes = variables ? [build_hash] : []
    @inverse_hashes = variables ? [build_inverse_hash] : []
  end

  def to_hash
    any? ? @hashes.first.merge(global_variables) : global_variables
  end

  def to_inverse_hash
    any? ? @inverse_hashes.first.merge(global_variables) : global_variables
  end

  def scope(variables)
    @stack.unshift convert(variables)
    added = true
    @hashes.unshift build_hash
    @inverse_hashes.unshift build_inverse_hash
    yield
  ensure
    @stack.shift
    if added
      @hashes.shift
      @inverse_hashes.shift
    end
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
    global_variables.merge! convert(variables)
  end

  private

  def global_variables
    @global_variables ||= @klass.new
  end

  def any?
    @stack.any?
  end

  def build_hash(index = 0)
    @stack[index..-1].inject(@klass.new) do |hash, variables|
      variables.merge hash
    end
  end

  def build_inverse_hash(index = 0)
    @stack[index..-1].inject(@klass.new) do |hash, variables|
      hash.merge variables
    end
  end

  def delete_key(key)
    @stack.each{|hash|hash.delete(key)}
  end

  def convert(variables)
    raise(ArgumentError, "Variables should respond to `keys`") unless variables.respond_to?("keys")
    @klass.new(variables)
  end

end
