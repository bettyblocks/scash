require_relative 'helper'

describe Scash do
  it "is instantiable" do
    assert Scash.new
  end

  it "is scopable" do
    scash = Scash.new

    assert_equal %w(), scash.keys
    scash.with({:a => 1}) do
      assert_equal 1, scash[:a]
      assert_equal 1, scash[:a, true]
      assert_equal 1, scash['a', true]
      assert_equal %w(a), scash.keys

      scash.with({"a" => 2}) do
        assert_equal 2, scash[:a]
        assert_equal 1, scash[:a, true]
        assert_equal 1, scash['a', true]
        assert_equal %w(a), scash.keys

        scash.with({"b" => 3}) do
          assert_equal 3, scash[:b]
          assert_equal 3, scash[:b, true]
          assert_equal 3, scash[:b, true]

          scash.with({"b" => 4}) do
            assert_equal 4, scash[:b]
            assert_equal 3, scash[:b, true]
            assert_equal 3, scash[:b, true]
          end
        end
      end

      scash.with({"b" => 3}) do
        assert_equal 1, scash[:a]
        assert_equal %w(a b), scash.keys
        assert_equal 3, scash["b"]
        assert_equal 1, scash[:a, true]
        assert_equal 1, scash['a', true]
        assert_equal 3, scash[:b, true]
        assert_equal 3, scash['b', true]
      end

      assert_equal 1, scash[:a]
      assert_equal %w(a), scash.keys
    end
    assert_equal %w(), scash.keys
  end

  it "keeps scope instact when an error occurs" do
    scash = Scash.new
    assert_raises(ArgumentError) do
      scash.with(["a" => 1]) do
      end
    end

    assert_equal({}, scash.to_hash)
  end

  it "accepts variables in initializer" do
    scash = Scash.new({:a => 1})
    assert_equal 1, scash[:a]
    assert_equal({"a" => 1}, scash.to_hash)
    scash.with({:b => 2}) do
      assert_equal 1, scash[:a]
      assert_equal 2, scash[:b]
      scash.define_global_variables :c => 3
    end
    assert_equal 1, scash[:a]
    assert_equal 3, scash[:c]
  end

  it "typecasts correctly" do
    scash = Scash.new({:a => 1})
    assert_equal({"a" => 1}, scash.to_hash)
    assert_equal HashWithIndifferentAccess, scash.to_hash.class

    scash = Scash.new({:a => 1})
    assert_equal({"a" => 1}, scash.to_inverse_hash)
    assert_equal HashWithIndifferentAccess, scash.to_inverse_hash.class

    class SubHash < HashWithIndifferentAccess
    end

    scash = Scash.new({:a => 1}, SubHash)
    assert_equal({"a" => 1}, scash.to_hash)
    assert_equal SubHash, scash.to_hash.class

    scash = Scash.new({:a => 1}, SubHash)
    assert_equal({"a" => 1}, scash.to_inverse_hash)
    assert_equal SubHash, scash.to_inverse_hash.class
  end

  it "reuses instances" do
    class Foo
      attr_accessor :bar
    end

    foo1 = Foo.new
    foo2 = Foo.new
    foo1id = foo1.object_id
    foo2id = foo2.object_id

    scash = Scash.new
    scash.with({"a" => foo1}) do
      assert_equal foo1id, scash["a"].object_id
      scash["a"].bar = "bar1"
      scash.with({"b" => foo2}) do
        assert_equal "bar1", scash["a"].bar
        assert_equal foo1id, scash["a"].object_id
        assert_equal foo2id, scash["b"].object_id
        scash["b"].bar = "bar2"
      end
      assert_equal foo1id, scash["a"].object_id
      assert_equal "bar1", scash["a"].bar
      assert_equal "bar2", foo2.bar
    end

    assert_equal "bar1", foo1.bar
    assert_equal "bar2", foo2.bar
  end

  describe "global variables" do
    it "is able to define a global variable" do
      scash = Scash.new
      scash.with({:a => 1}) do
        scash.define_global_variables :result => 1337
        assert_equal 1, scash[:a]
        assert_equal 1337, scash[:result]

        scash.with({:b => 2}) do
          assert_equal 1, scash[:a]
          assert_equal 2, scash[:b]
          assert_equal 1337, scash[:result]
        end

        assert_equal 1, scash[:a]
        assert_nil scash[:b]
        assert_equal 1337, scash[:result]
      end

      assert_nil scash[:a]
      assert_nil scash[:b]
      assert_equal 1337, scash[:result]
    end

    it "overwrite a nil value with same name" do
      # initial values can never be overwritten with a global-variable, except nil values
      scash = Scash.new(:initial_a => 1337, :initial_b => nil)
      scash.with({:a => 1, :b => nil}) do
        assert_equal [1337, nil, 1, nil], scash.values
        assert_equal 1337, scash[:initial_a]
        assert_equal nil, scash[:initial_b]

        scash.define_global_variables :a => "global a", :b => "global b"
        scash.define_global_variables :initial_a => "new a", :initial_b => "new b"

        assert_equal [1, "global b", 1337, "new b"], scash.values

        scash.with(:a => "a", :b => nil, :c => nil) do
          assert_equal ["a", "global b", 1337, "new b", nil], scash.values # NOTE: only 1 nil value (b)
          assert_equal "a", scash[:a]
          assert_equal "global b", scash[:b]
          assert_equal nil, scash[:c]
        end

        assert_equal 1, scash[:a]
        assert_equal "global b", scash[:b]
        assert_equal 1337, scash[:initial_a]
        assert_equal "new b", scash[:initial_b]
      end
      assert_equal "global a", scash[:a]
      assert_equal "global b", scash[:b]

      assert_equal 1337, scash[:initial_a]
      assert_equal "new b", scash[:initial_b]
    end

    it "overwrites a global variable with same name" do
      scash = Scash.new
      scash.with({:a => 1}) do
        scash.define_global_variables :result => 1337
        assert_equal 1337, scash[:result]

        scash.with({:b => 2}) do
          assert_equal 1337, scash[:result]
          assert_equal 2, scash[:b]
          scash.define_global_variables :result => "foo"
          scash.define_global_variables :b => "bar"
          assert_equal 2, scash[:b]
          assert_equal "foo", scash[:result]
        end

        assert_equal "foo", scash[:result]
      end

      assert_equal "foo", scash[:result]
      assert_equal "bar", scash[:b]
    end
  end

  it "responds to merge" do
    scash = Scash.new
    scash.with({:a => 1}) do
      assert_equal({:a => 1, :b => 2}.with_indifferent_access, scash.merge(:b => 2))
    end
  end
end