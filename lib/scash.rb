require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/hash/slice"
require "active_support/core_ext/module/delegation"
require "scash/version"

class Scash
  include Enumerable
  delegate  :each, :empty?, :eql?, :has_key?, :has_value?, :include?, :index,
            :keys, :merge, :reject, :replace, :select, :size, :values, :to => :to_hash

  attr_reader :stack

  def initialize(variables = {}, klass = HashWithIndifferentAccess)
    @klass = klass
    @hash = convert(variables)
    @inverse_hash = convert(variables)
  end

  def to_hash
    @hash
  end

  def to_inverse_hash
    @inverse_hash
  end

  def scope(variables)
    previous_hash = @hash.slice *variables.keys.select{|key| @hash.key?(key)}
    previous_inverse_hash = @inverse_hash.slice *variables.keys.select{|key| @inverse_hash.key?(key)}
    @hash.merge! variables
    @inverse_hash.merge!(variables.reject{|key| @inverse_hash.key?(key)})
    yield
  ensure
    variables.each_key{|key| @hash.delete(key)}
    variables.each_key{|key| @inverse_hash.delete(key)}
    @inverse_hash.merge!(previous_inverse_hash)
    @hash.merge!(previous_hash)
    @hash.merge!(global_variables.reject { |k| @hash.has_key?(k) })
  end
  alias :with :scope

  def [](key, inverse = false)
    if inverse
      @inverse_hash[key]
    else
      @hash[key]
    end
  end

  def define_global_variable(key, value)
    define_global_variables key => value
  end

  def define_global_variables(variables)
    @hash.merge! variables
    global_variables.merge! variables
  end

  private

  def global_variables
    @global_variables ||= @klass.new
  end

  def convert(variables)
    variables.is_a?(@klass) ? variables : @klass.new(variables)
  end
end
