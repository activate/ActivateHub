require 'spec_helper'

RSpec.describe ActsAsTaggableOn::Tag, type: :model do
  describe "handling machine tags" do
    before do
      @valid_machine_tag = ActsAsTaggableOn::Tag.new(:name => 'lanyrd:event=1234')
    end

    it "should return an empty hash when the tag is not a machine tag" do
      expect(ActsAsTaggableOn::Tag.new(:name => 'not a machine tag').machine_tag).to eq({})
    end

    it "should parse a machine tag into components" do
      expect(@valid_machine_tag.machine_tag[:namespace]).to eq 'lanyrd'
      expect(@valid_machine_tag.machine_tag[:predicate]).to eq 'event'
      expect(@valid_machine_tag.machine_tag[:value]).to eq '1234'
    end

    it "should generate a url for supported namespaces/predicates" do
      expect(@valid_machine_tag.machine_tag[:url]).to eq "http://lanyrd.com/1234"
    end
  end
end
