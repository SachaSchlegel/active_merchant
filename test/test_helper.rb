#!/usr/bin/env ruby
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/mocks')
$:.unshift(File.dirname(__FILE__) + '/extra')

require 'rubygems'
require 'money'
require 'yaml'
require 'net/http'
require 'net/https'
require 'test/unit'
require 'binding_of_caller'
require 'breakpoint'
require 'openssl'
require 'mocha'
require 'digest/md5'

require File.dirname(__FILE__) + '/../lib/active_merchant'

ActiveMerchant::Billing::Base.mode = :test

module Test
  module Unit
    class TestCase
      LOCAL_CREDENTIALS = ENV['HOME'] + '/.active_merchant/fixtures.yml' unless defined?(LOCAL_CREDENTIALS)
      DEFAULT_CREDENTIALS = File.dirname(__FILE__) + '/fixtures.yml' unless defined?(DEFAULT_CREDENTIALS)
      
      include ActiveMerchant::Billing
    
      private
      def generate_order_id
        md5 = Digest::MD5.new
        now = Time.now
        md5 << now.to_s
        md5 << String(now.usec)
        md5 << String(rand(0))
        md5 << String($$)
        md5 << self.class.name
        md5.hexdigest
      end
      
      def credit_card(number, options = {})
        defaults = {
          :number => number,
          :month => 9,
          :year => Time.now.year + 1,
          :first_name => 'Longbob',
          :last_name => 'Longsen',
          :verification_value => '123'
        }.update(options)

        ActiveMerchant::Billing::CreditCard.new(defaults)
      end
      
      def all_fixtures
        @@fixtures ||= load_fixtures
      end
      
      def fixtures(key)
        data = all_fixtures[key] || raise(StandardError, "No fixture data was found for '#{key}'")
        
        data.dup
      end
          
      def load_fixtures
        file = File.exists?(LOCAL_CREDENTIALS) ? LOCAL_CREDENTIALS : DEFAULT_CREDENTIALS
        yaml_data = YAML.load(File.read(file))
        symbolize_keys(yaml_data)
      
        yaml_data
      end
      
      def symbolize_keys(hash)
        return unless hash.is_a?(Hash)
        
        hash.symbolize_keys!
        hash.each{|k,v| symbolize_keys(v)}
      end
    end

    module Assertions
      def assert_field(field, value)
        clean_backtrace do 
          assert_equal value, @helper.fields[field]
        end
      end

      private
      def clean_backtrace(&block)
        yield
      rescue AssertionFailedError => e
        path = File.expand_path(__FILE__)
        raise AssertionFailedError, e.message, e.backtrace.reject { |line| File.expand_path(line) =~ /#{path}/ }
      end
    end
  end
end
