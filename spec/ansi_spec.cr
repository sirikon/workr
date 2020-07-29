require "spec"
require "../src/web/utils"

module Workr::Web::Utils
  describe "ansi_filter" do
    it "returns an empty string, given an empty string" do
      ansi_filter("").should eq ""
    end
    it "returns a string with contents, without ansi codes, untouched" do
      ansi_filter("Hello World!").should eq "Hello World!"
    end
    it "returns a string with contents and without ansi codes, given text with ansi codes for color" do
      ansi_filter("\e[32mHello\e[0m World!").should eq "Hello World!"
    end
    it "returns a string with contents and without ansi codes, given text with many ansi codes" do
      ansi_filter("\e[32mHello\e[1B\e[2A\e[2K\e[0m World!\e[32m").should eq "Hello World!"
    end
    it "returns a string with escape codes, respecting them as long as they are not valid ansi escapes" do
      ansi_filter("\e[32mHello \e World!").should eq "Hello \e World!"
    end
  end
end
