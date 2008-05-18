require File.dirname(__FILE__) + '/../../test_helper'

class RemoteWirecardTest < Test::Unit::TestCase

  def setup
    # WireCard requires a user to provide the IP address of server
    #
    # A TestAccount can be created at WireCard.

    @gateway = WirecardGateway.new(fixtures(:wirecard))

    @amount = 100
    @credit_card = credit_card('4200000000000000')
    @declined_card = credit_card('4200000000000001')

    @options = {
      :order_id => '1',
      :billing_address => address,
      :currency => 'CHF',
      :country => 'CH',
      :description => 'ActiveMerchant Wirecard Gateway Remote Test'
    }
  end

  def test_invalid_login
    gateway = WirecardGateway.new(
                                  :login => '',
                                  :password => '',
                                  :business_case_signature => ''
              )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal 'Authentication Error', response.message
  end

  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.', response.message
  end

  def test_unsuccessful_purchase
    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'Credit card number invalid.', response.message
  end

  def test_authorize_and_capture
    amount = @amount
    assert auth = @gateway.authorize(amount, @credit_card, @options)
    assert_success auth
    assert_equal 'THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.', auth.message
    assert auth.authorization
    assert capture = @gateway.capture(amount, auth.authorization, @options)
    assert_success capture
    assert_equal 'THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.', auth.message
  end

  def test_failed_capture
    assert response = @gateway.capture(@amount, '')
    assert_failure response
    assert_equal 'Content of GuWID is not according to the given content restrictions.', response.message
  end

  # Default initial recurring is a authorize action
  def test_successful_initial_recurring_authorize
    @options[:initial_request] = true
    assert response = @gateway.recurring(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.', response.message
  end

  def test_successful_initial_recurring_purchase
    @options[:initial_request] = true
    @options[:action] = :purchase
    assert response = @gateway.recurring(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.', response.message
  end

  def test_failed_initial_recurring
    @options[:initial_request] = true
    assert response = @gateway.recurring(@amount, @declined_card, @options)
    assert_failure response
    assert_equal "Credit card number invalid.", response.message
  end


  def test_successful_repeated_recurring
    @options[:initial_request] = true
    assert response = @gateway.recurring(@amount, @credit_card, @options)
    assert_success response
    @options[:initial_request] = false
    @options[:guwid] = response.authorization
    assert response = @gateway.recurring(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'THIS IS A DEMO TRANSACTION USING CREDIT CARD NUMBER 420000****0000. NO REAL MONEY WILL BE TRANSFERED.', response.message
  end


  def test_failed_repeated_recurring_wrong_guwid
    @options[:initial_request] = false
    guwid = 'C305830112714411123300'
    @options[:guwid] =  guwid
    assert response = @gateway.recurring(@amount, @credit_card, @options)
    assert_failure response
    assert_equal "Could not find referenced transaction for GuWID #{guwid}.", response.message
  end

end
