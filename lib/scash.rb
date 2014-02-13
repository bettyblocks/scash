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
    @stack = [convert(variables), global_variables].compact
    build!
  end

  def to_hash
    @hashes.first
  end

  def to_inverse_hash
    @inverse_hashes.first
  end

  def scope(variables)
    @stack.unshift convert(variables)
    added = true
    build!
    yield
  ensure
    @stack.shift if added
    build!
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
    build!
  end

  private

  def global_variables
    @global_variables ||= @klass.new
  end

  def any?
    @stack.any?
  end

  def build_hash(stack_index = 0)
    @stack[stack_index..-1].each_with_index.inject(@klass.new) do |hash, (variables, index)|
      last = stack_index + index == @stack.size-1
      variables = variables.reject{|key, value| variables[key].nil? && !last && @stack.last.key?(key) }
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
    return if variables.nil?

    raise(ArgumentError, "Variables should respond to `keys`") unless variables.respond_to?("keys")
    variables.is_a?(@klass) ? variables : @klass.new(variables)
  end

  def build!
    @hashes = stack.size.times.map do |index|
      build_hash(index)
    end

    @inverse_hashes = stack.size.times.map do |index|
      build_inverse_hash(index)
    end
  end

end
