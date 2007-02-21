require File.dirname(__FILE__) + '/../test_helper'

class PaypalTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  
  def setup
    Base.gateway_mode = :test
    
    #cert = File.read(File.join(File.dirname(__FILE__), 'certificate.pem'))
    
     @gateway = PaypalGateway.new(
        :login     => 'login',
        :password  => 'password',
        :subject => 'third_party_account',
        :pem => '' #cert
     )

     @creditcard = CreditCard.new(
       :type                => "Visa",
       :number              => "4381258770269608", # Use a generated CC from the paypal Sandbox
       :verification_value => "000",
       :month               => 1,
       :year                => 2008,
       :first_name          => 'Fred',
       :last_name           => 'Brooks'
      )
       
      @params = {
        :order_id => '1230123',
        :email => 'buyer@jadedpallet.com',
        :address => { :name => 'Fred Brooks',
                      :address1 => '1234 Penny Lane',
                      :city => 'Jonsetown',
                      :state => 'NC',
                      :country => 'US',
                      :zip => '23456'
                    } ,
        :description => 'Stuff that you purchased, yo!',
        :ip => '10.0.0.1',
        :return_url => 'http://example.com/return',
        :cancel_return_url => 'http://example.com/cancel'
      }
  end

  def test_successful_purchase
    response = @gateway.purchase(Money.new(300), @creditcard, @params)
    assert response.success?
    assert response.params['transaction_id']
  end
  
  def test_failed_purchase
    @creditcard.number = '234234234234'
    response = @gateway.purchase(Money.new(300), @creditcard, @params)
    assert !response.success?
    assert_nil response.params['transaction_id']
  end

  def test_successful_authorization
    response = @gateway.authorize(Money.new(300), @creditcard, @params)
    assert response.success?
    assert response.params['transaction_id']
    assert_equal '3.00', response.params['amount']
    assert_equal 'USD', response.params['amount_currency_id']
  end
  
  def test_failed_authorization
    @creditcard.number = '234234234234'
    response = @gateway.authorize(Money.new(300), @creditcard, @params)
    assert !response.success?
    assert_nil response.params['transaction_id']
  end
  
  def test_successful_capture
    auth = @gateway.authorize(Money.new(300), @creditcard, @params)
    assert auth.success?
    response = @gateway.capture(Money.new(300), auth.authorization)
    assert response.success?
    assert response.params['transaction_id']
    assert_equal '3.00', response.params['gross_amount']
    assert_equal 'USD', response.params['gross_amount_currency_id']
  end
  
  def test_successful_voiding
    auth = @gateway.authorize(Money.new(300), @creditcard, @params)
    assert auth.success?
    response = @gateway.void(auth.authorization)
    assert response.success?
  end
  
  def test_purchase_and_full_credit
    amount = Money.new(300)
    
    purchase = @gateway.purchase(amount, @creditcard, @params)
    assert purchase.success?
    
    credit = @gateway.credit(amount, purchase.authorization, :note => 'Sorry')
    assert credit.success?
    assert credit.test?
    assert_equal 'USD',  credit.params['net_refund_amount_currency_id']
    assert_equal '2.61', credit.params['net_refund_amount']
    assert_equal 'USD',  credit.params['gross_refund_amount_currency_id']
    assert_equal '3.00', credit.params['gross_refund_amount']
    assert_equal 'USD',  credit.params['fee_refund_amount_currency_id']
    assert_equal '0.39', credit.params['fee_refund_amount']
  end
  
  def test_failed_voiding
    response = @gateway.void('foo')
    assert !response.success?
  end
end 
