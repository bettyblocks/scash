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
        assert_equal %w(a), scash.keys

        scash.with({"a" => 2}) do
          assert_equal 2, scash[:a]
          assert_equal %w(a), scash.keys
        end

        scash.with({"b" => 3}) do
          assert_equal 1, scash[:a]
          assert_equal %w(a b), scash.keys
          assert_equal 3, scash["b"]
        end

        assert_equal 1, scash[:a]
        assert_equal %w(a), scash.keys
      end
      assert_equal %w(), scash.keys
    end
  end

  describe "behave like a hash" do
    it "should respond to merge" do
      scash = Scash.new
      scash.with(:a => 1) do
        assert_equal({:a => 1, :b => 2}.with_indifferent_access, scash.merge(:b => 2))
      end
    end
  end

end