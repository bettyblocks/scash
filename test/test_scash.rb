require 'helper'

class TestScash < Minitest::Test
  describe "basics" do
    it "should be instantiable" do
      assert scash = Scash.new
    end

    it "should be scopable" do
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

    it "should keep scope instact when an error occurs" do
      scash = Scash.new
      assert_raises(NoMethodError) do
        scash.with(["a" => 1]) do
        end
      end

      assert_equal({}, scash.to_hash)
    end

    it "should accept variables in initializer" do
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

    it "should reuse instances" do
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
  end

  describe "global variables" do
    it "should be able to define a global variable" do
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

    it "should overwrite a global variable with same name" do
      scash = Scash.new
      scash.with({:a => 1}) do
        scash.define_global_variables :result => 1337
        assert_equal 1337, scash[:result]

        scash.with({:b => 2}) do
          assert_equal 1337, scash[:result]
          scash.define_global_variables :result => "foo"
          assert_equal "foo", scash[:result]
        end

        assert_equal "foo", scash[:result]
      end
    end
  end

  describe "behave like a hash" do
    it "should respond to merge" do
      scash = Scash.new
      scash.with({:a => 1}) do
        assert_equal({:a => 1, :b => 2}.with_indifferent_access, scash.merge(:b => 2))
      end
    end
  end

end