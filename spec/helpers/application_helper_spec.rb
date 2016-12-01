require 'spec_helper'
include ApplicationHelper

RSpec.describe ApplicationHelper, type: :helper do
  describe "when escaping HTML while preserving entities (cleanse)" do
    it "should preserve plain text" do
      expect(cleanse("Allison to Lillia")).to eq "Allison to Lillia"
    end

    it "should escape HTML" do
      expect(cleanse("<Fiona>")).to eq "&lt;Fiona&gt;"
    end

    it "should preserve HTML entities" do
      expect(cleanse("Allison &amp; Lillia")).to eq "Allison &amp; Lillia"
    end

    it "should handle text, HTML and entities together" do
      expect(cleanse("&quot;<Allison> &amp; Lillia&quot;")).to eq "&quot;&lt;Allison&gt; &amp; Lillia&quot;"
    end
  end

  describe "#helper.mobile_stylesheet_media" do
    def mobile_cookie(value=nil)
      cookie_name = ApplicationController::MOBILE_COOKIE_NAME
      if value
        @request.cookies[cookie_name] = value
      end
      return @request.cookies[cookie_name]
    end

    before :each do
      @request.cookies.delete(:mobile)
    end

    after :each do
      @request.cookies.delete(:mobile)
    end

    it "should use default media if no overrides in params or cookies were specified" do
      expect(helper.mobile_stylesheet_media("hello")).to eq "hello"
    end

    it "should force rendering of mobile site if given a param of '1' and save it as cookie" do
      controller.params[:mobile] = "1"

      expect(helper.mobile_stylesheet_media("hello")).to eq :all

      expect(mobile_cookie).to eq "1"
    end

    it "should force rendering of non-mobile site if given a param of '0' and save it as cookie" do
      controller.params[:mobile] = "0"

      expect(helper.mobile_stylesheet_media("hello")).to be false

      expect(mobile_cookie).to eq "0"
    end

    it "should use default media if given a param of '' and clear :mobile cookie" do
      mobile_cookie "1"
      controller.params[:mobile] = "-1"

      expect(helper.mobile_stylesheet_media("hello")).to eq "hello"

      expect(mobile_cookie).to be_nil
    end

    it "should use mobile rendering if cookie's mobile preference is set to '1'" do
      mobile_cookie "1"

      expect(helper.mobile_stylesheet_media("hello")).to eq :all

      expect(mobile_cookie).to eq "1"
    end

    it "should use non-mobile rendering if cookie's mobile preference is set to '0'" do
      mobile_cookie "0"

      expect(helper.mobile_stylesheet_media("hello")).to be false

      expect(mobile_cookie).to eq "0"
    end
  end

  describe "#format_description" do
    it "should autolink" do
      expect(helper.format_description("foo http://mysite.com/~user bar")).to eq \
        '<p>foo <a href="http://mysite.com/~user">http://mysite.com/~user</a> bar</p>'
    end

    it "should process Markdown links" do
      expect(helper.format_description("[ClojureScript](https://github.com/clojure/clojurescript), the Clojure to JS compiler")).to eq \
        '<p><a href="https://github.com/clojure/clojurescript">ClojureScript</a>, the Clojure to JS compiler</p>'
    end

    it "should process Markdown references" do
      expect(helper.format_description("
[SocketStream][1], a phenomenally fast real-time web framework for Node.js

[1]: https://github.com/socketstream/socketstream
      ")).to eq \
        '<p><a href="https://github.com/socketstream/socketstream">SocketStream</a>, a phenomenally fast real-time web framework for Node.js</p>'
    end
  end
end
