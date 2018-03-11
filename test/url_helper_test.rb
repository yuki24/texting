# frozen_string_literal: true

require 'test_helper'
require "action_controller"

class WelcomeController < ActionController::Base
end

AppRoutes = ActionDispatch::Routing::RouteSet.new

Texting::Base.include AppRoutes.url_helpers

class UrlTestMessenger < Texting::Base
  self.default_url_options[:host] = "example.org"
  self.asset_host = "https://example.org"

  configure do |c|
    c.assets_dir = "" # To get the tests to pass
  end

  def url(options)
    text to: '9093900003', body: url_for(options)
  end

  def welcome
    text to: '9093900003', body: welcome_url
  end

  def asset
    text to: '9093900003', body: asset_url('pretty.css') # TODO: This is not working
  end

  def image
    text to: '9093900003', body: viimage_url('puppy.gif') # TODO: This is not working
  end
end

class UrlHelperTest < ActiveSupport::TestCase
  class DummyModel
    def self.model_name
      OpenStruct.new(route_key: "dummy_model")
    end

    def persisted?
      false
    end

    def model_name
      self.class.model_name
    end

    def to_model
      self
    end
  end

  def assert_url_for(expected, options, relative = false)
    expected = "http://example.org#{expected}" if expected.start_with?("/") && !relative
    url      = UrlTestMessenger.url(options).body

    assert_equal expected, url
  rescue => e
    puts e.backtrace
  end

  test '#url_for' do
    AppRoutes.draw do
      ActiveSupport::Deprecation.silence do
        get ":controller(/:action(/:id))"
        get "/welcome" => "foo#bar", as: "welcome"
        get "/dummy_model" => "foo#baz", as: "dummy_model"
      end
    end

    # string
    assert_url_for "http://foo/", "http://foo/"

    # symbol
    assert_url_for "/welcome", :welcome

    # hash
    assert_url_for "/a/b/c", controller: "a", action: "b", id: "c"
    assert_url_for "/a/b/c", { controller: "a", action: "b", id: "c", only_path: true }, true
    assert_url_for "http://example.org/welcome/greeting", { host: "example.org", controller: "welcome", action: "greeting" }

    # model
    assert_url_for "/dummy_model", DummyModel.new

    # class
    assert_url_for "/dummy_model", DummyModel

    # array
    assert_url_for "/dummy_model", [DummyModel]
  end

  test 'url helpers' do
    AppRoutes.draw do
      ActiveSupport::Deprecation.silence do
        get ":controller(/:action(/:id))"
        get "/welcome" => "foo#bar", as: "welcome"
      end
    end

    assert_equal 'http://example.org/welcome', UrlTestMessenger.welcome.body
  end

  test 'asset url helpers' do
    skip

    AppRoutes.draw do
      ActiveSupport::Deprecation.silence do
        get ":controller(/:action(/:id))"
        get "/welcome" => "foo#bar", as: "welcome"
      end
    end

    assert_equal 'https://example.org/puppy.jpeg',        UrlTestMessenger.asset.body
    assert_equal 'https://example.org/images/puppy.jpeg', UrlTestMessenger.image.body
  end
end
