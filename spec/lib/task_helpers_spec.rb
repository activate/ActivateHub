require 'spec_helper'
require 'task_helpers'

require 'rake/task_arguments'

describe TaskHelpers do
  let(:args) { {} }
  let(:task_args) { Rake::TaskArguments.new(args.keys, args.values) }

  describe "::parse_var_args" do
    it "returns empty hash if no args" do
      TaskHelpers.parse_var_args(task_args).should eq({})
    end

    it "returns empty hash if empty args" do
      TaskHelpers.parse_var_args(task_args).should eq({})
    end

    it "named args should be passed through as-is" do
      args.merge!(:foo => 123, :bar => 456)
      TaskHelpers.parse_var_args(task_args).should eq ({
        :foo => 123,
        :bar => 456,
      })
    end
    context "with unnamed args" do
      it "ignores any unnamed args without a key (arg value)" do
        args.merge!(:argv0 => '', :argv1 => nil, :argv2 => '=4', :argv3 => ':3')
        TaskHelpers.parse_var_args(task_args).keys.should eq []
      end

      it "treats any arg key starting with 'argv' as unnamed" do
        args.merge!(:argv => 'a', :argv74 => 'b', :argvfoo => 'c')
        args.merge!(:argx => 'd') # parser should leave this arg alone
        TaskHelpers.parse_var_args(task_args).keys.should eq [:a, :b, :c, :argx]
      end

      it "splits key-val pairs on first separator (':' and '=')" do
        args.merge!(:argv0 => 'abc=1==:23', :argv1 => 'def:four=five:six')
        TaskHelpers.parse_var_args(task_args).should eq ({
          :abc => '1==:23', :def => 'four=five:six'
        })
      end

      it "assigns value of true if not key-val" do
        args.merge!(:argv0 => 'amoeba')
        TaskHelpers.parse_var_args(task_args).should eq ({ :amoeba => true })
      end

      it "assigns value of false if not key-val, but prefixed w/ '!'" do
        args.merge!(:argv0 => '!sin')
        TaskHelpers.parse_var_args(task_args).should eq ({ :sin => false })
      end
    end


    it "should not change the original args list" do
      args.merge!(:foo => 'bar', :argv0 => 'baz')
      expect { TaskHelpers.parse_var_args(task_args) } \
        .to_not change { task_args.to_hash }
    end

  end

end
