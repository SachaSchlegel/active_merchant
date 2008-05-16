module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class WirecardGateway < Gateway
      TEST_URL = 'https://c3-test.wirecard.com/secure/ssl-gateway'
      LIVE_URL = 'still unknown'

      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['DE']

      # The card types supported by the payment gateway
      self.supported_cardtypes = [:visa, :master]

      # The homepage URL of the gateway
      self.homepage_url = 'http://www.wirecard.com/'

      # The name of the gateway
      self.display_name = 'WireCard'

      # Setting the default mony format
      self.money_format = :cents

      # Setting the default currency
      self.default_currency = 'EUR'

      # Some default settings.
      DEFAULT_USAGE_DESCRIPTION = 'Default Usage description'
      DEFAULT_COUNTRY_CODE = 'DE'
      DO_CONTACT_DATA = false

      # WireCard uses a business_case_signature so we require it
      def initialize(options = {})
        requires!(options, :login, :password, :business_case_signature)
        @options = options
        super
      end

      # This method commits an authorization
      #
      def authorize(money, creditcard, options = {})
        commit(build_authorization(money, creditcard, options))
      end

      # This method commits a capture
      #
      def capture(money, authorization, options = {})
        commit(build_capture(money, authorization, options))
      end

      # This method commits a purchase
      #
      def purchase(money, creditcard, options = {})
        commit(build_purchase(money, creditcard, options))
      end

      # This method commits a recurring message
      #
      # There are two types of recurring actions
      # a) the initial request
      # b) the repeated request
      # the type must be set in the options attribute
      #
      # Initial request
      # ---------------
      # * option attribute requirements:
      #   * :initial_request => true
      # * requires credit card
      # * requires money
      #
      # -> an authorization request is sent
      #
      # Repeated request
      # ----------------
      # * option attribute requirements:
      #   * :initial_request => false
      #   * :guwid => <number>
      # * requires money
      #
      # -> currently only purchase is supported. A purchase request is sent
      #
      def recurring(money, creditcard, options)
        requires!(options, :initial_request)
        options[:recurring] = true
        if options[:initial_request] == true
          # initial request
          return commit(build_authorization(money, creditcard, options))
        else
          # repeated request
          requires!(options, :guwid)
          return commit(build_purchase(money, creditcard, options))
        end
      end

      private

      # This method creates an authorization request message
      #
      def build_authorization money, creditcard, options
        recurring = options[:recurring] || false

        xml = Builder::XmlMarkup.new :indent => 2
        xml.instruct!
        xml.tag! 'WIRECARD_BXML', { 'xmlns:xsi' => 'http://www.w3.org/1999/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => 'wirecard.xsd' } do
          xml.tag! 'W_REQUEST' do
            xml.tag! 'W_JOB' do
              xml.tag! 'JobID', get_job_id
              xml.tag! 'BusinessCaseSignature', @options[:business_case_signature]
              xml.tag! 'FNC_CC_AUTHORIZATION' do
                xml.tag! 'FunctionID', get_function_id
                xml.tag! 'CC_TRANSACTION' do
                  xml.tag! 'TransactionID', (options[:transaction_id] || get_transaction_id)
                  xml.tag! 'Amount', { :minorunits => 2 }, amount(money)
                  xml.tag! 'Currency', (options[:currency] || default_currency)
                  xml.tag! 'CountryCode', (options[:country] || DEFAULT_COUNTRY_CODE)
                  xml.tag! 'Usage', (options[:description] || DEFAULT_USAGE_DESCRIPTION)
                  if recurring
                    if options[:guwid].blank?
                      xml.tag! 'RECURRING_TRANSACTION' do
                        xml.tag! 'Type', 'Initial'
                      end
                      add_creditcard xml, creditcard
                    else
                      xml.tag! 'RECURRING_TRANSACTION' do
                        xml.tag! 'Type', 'Repeated'
                      end
                    end
                  else
                    add_creditcard xml, creditcard
                  end
                  if DO_CONTACT_DATA
                    xml.tag! 'CONTACT_DATA' do
                      xml.tag! 'IPAddress'
                    end
                  end
                end
              end
            end
          end
        end

      end

      # This method creates the capture request message
      #
      def build_capture money, authorization, options
        xml = Builder::XmlMarkup.new :indent => 2
        xml.instruct!
        xml.tag! 'WIRECARD_BXML', { 'xmlns:xsi' => 'http://www.w3.org/1999/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => 'wirecard.xsd' } do
          xml.tag! 'W_REQUEST' do
            xml.tag! 'W_JOB' do
              xml.tag! 'JobID', get_job_id
              xml.tag! 'BusinessCaseSignature', @options[:business_case_signature]
              xml.tag! 'FNC_CC_CAPTURE_AUTHORIZATION' do
                xml.tag! 'FunctionID', get_function_id
                xml.tag! 'CC_TRANSACTION' do
                  xml.tag! 'TransactionID', (options[:transaction_id] || get_transaction_id)
                  xml.tag! 'GuWID', authorization
                  xml.tag! 'Amount', { :minorunits => 2 }, amount(money)
                  xml.tag! 'Currency', (options[:currency] || default_currency)
                  xml.tag! 'CountryCode', (options[:country] || DEFAULT_COUNTRY_CODE)
                  xml.tag! 'Usage', (options[:description] || DEFAULT_USAGE_DESCRIPTION)
                end
              end
            end
          end
        end

      end

      # This method creates the purchase request message
      #
      def build_purchase money, creditcard, options
        recurring = options[:recurring] || false

        xml = Builder::XmlMarkup.new :indent => 2
        xml.instruct!
        xml.tag! 'WIRECARD_BXML', { 'xmlns:xsi' => 'http://www.w3.org/1999/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => 'wirecard.xsd' } do
          xml.tag! 'W_REQUEST' do
            xml.tag! 'W_JOB' do
              xml.tag! 'JobID', get_job_id
              xml.tag! 'BusinessCaseSignature', @options[:business_case_signature]
              xml.tag! 'FNC_CC_PURCHASE' do
                xml.tag! 'FunctionID', get_function_id
                xml.tag! 'CC_TRANSACTION' do
                  xml.tag! 'TransactionID', (options[:transaction_id] || get_transaction_id)
                  xml.tag! 'Amount', { :minorunits => 2 }, amount(money)
                  xml.tag! 'Currency', (options[:currency] || default_currency)
                  xml.tag! 'CountryCode', (options[:country] || DEFAULT_COUNTRY_CODE)
                  xml.tag! 'Usage', (options[:description] || DEFAULT_USAGE_DESCRIPTION)
                  if recurring
                    if options[:guwid].blank?
                      xml.tag! 'RECURRING_TRANSACTION' do
                        xml.tag! 'Type', 'Initial'
                      end
                      add_creditcard xml, creditcard
                    else
                      xml.tag! 'GuWID', options[:guwid]
                      xml.tag! 'RECURRING_TRANSACTION' do
                        xml.tag! 'Type', 'Repeated'
                      end
                    end
                  else
                    add_creditcard xml, creditcard
                  end
                  if DO_CONTACT_DATA
                    xml.tag! 'CONTACT_DATA' do
                      xml.tag! 'IPAddress'
                    end
                  end
                end
              end
            end
          end
        end

      end


      # from Net::HTTPHeader.basic_encode method
      def basic_encode account, password
        'Basic ' + ["#{account}:#{password}"].pack('m').delete("\r\n")
      end

      def commit(request, options = nil)
        puts "Request:"
        puts request

        url = test? ? TEST_URL : LIVE_URL
        uri = URI.parse(url)

        headers = {}
        headers['Content-length'] = "#{request.size}"
        headers['Content-type'] = "text/xml"
        headers['Host'] = uri.host
        headers['Connection'] = 'close'
        headers['authorization'] = basic_encode(@options[:login], @options[:password])

        raw_response = ssl_post(url, request, headers)
        puts "Response:"
        puts raw_response

        # not sure if this is the best way.
        response_hash = parse(raw_response)

        puts "Response Hash:"
        puts response_hash.inspect
        puts "done."

        success = authorization = message = nil

        # A typical authentication error
        if raw_response =~ /This is an error page/ then
          return Response.new(false, 'Authentication Error', {}, { :test => test?, :authorization => nil } )
        end

        # FunctionResult can have:
        # * ACK (acknowledgment)
        # * NOK (not OK)
        # * PENDING (seems to be a success ...)

        success = case response_hash[:FunctionResult]
                  when 'ACK'
                    true
                  when 'PENDING'
                    true
                  when 'NOK'
                    false
                  else
                    false
                  end

        if success
          message = response_hash[:Info]
          # not sure what AuthorizationCode is used for.
          # authorization = response_hash[:AuthorizationCode]
          authorization = response_hash[:GuWID]
        else
          message = response_hash[:Message]
        end

        Response.new(success, message, response_hash, { :test => test?, :authorization => authorization, :fraud_review => raw_response } )
      end

      def add_creditcard(xml, creditcard)
        xml.tag! 'CREDIT_CARD_DATA' do
          xml.tag! 'CreditCardNumber', creditcard.number
          (xml.tag! 'CVC2', creditcard.verification_value) if creditcard.verification_value
          xml.tag! 'ExpirationYear', format( creditcard.year, :four_digits)
          xml.tag! 'ExpirationMonth', format( creditcard.month, :two_digits)
          xml.tag! 'CardHolderName', "#{creditcard.last_name} #{creditcard.first_name}"
        end
      end

      # Technique inspired by the Paypal Gateway
      # hope to not get an overwrite (element with same name will overwrite previous one)
      def parse(xml)
        reply = {}
        xml = REXML::Document.new(xml)
        xml.root.elements.to_a.each do |node|
          case node.name
          when 'Advice'
            # advice error code
            reply[:message] = reply(node.text)
          else
            parse_element(reply, node)
          end
        end
        return reply
      end

      def parse_element(reply, node)
        if node.has_elements?
          node.elements.each{|e| parse_element(reply, e) }
        else
          reply[node.name.to_sym] = node.text
        end
        return reply
      end

      alias_method :get_transaction_id, :generate_unique_id
      alias_method :get_job_id, :generate_unique_id

      def get_function_id
        'A WireCard Function'
      end

    end
  end
end

