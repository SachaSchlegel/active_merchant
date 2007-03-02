# Author::    MoneySpyder, www.moneyspyder.co.uk

require File.dirname(__FILE__) + '/../test_helper'

class RemoteDataCashTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  LOGIN = ''      #Datacash supplied login
  PASSWORD = ''   #Datacash supplied password
  
  def setup
    #gateway to connect to Datacash
    @gateway = DataCashGateway.new(
      :login => LOGIN,
      :password => PASSWORD,
      :test => true
    )
  
    @mastercard = CreditCard.new(
      :number => '5473000000000007',
      :month => 3,
      :year => 2010,              
      :first_name => 'Mark',      
      :last_name => 'McBride',
      :type => :master,
      :verification_value => '547'
    )
    
    @solo = CreditCard.new(
      :first_name => 'Cody',
      :last_name => 'Fauser',
      :number => 633499100000000004,
      :type => :solo,
      :issue_number => 5,
      :start_month => 12,
      :start_year => 2006,
      :verification_value => 444
    )
    
    @address = { 
      :name     => 'Mark McBride',
      :address1 => 'Flat 12/3',
      :address2 => '45 Main Road',
      :address3 => 'Sometown',
      :address4 => 'Somecounty',
      :city     => 'London',
      :state    => 'None',
      :country  => 'GBR',
      :zip      => 'A987AA',
      :phone    => '(555)555-5555'
    }
    
    @params = {
      :order_id => generate_order_id,
      :billing_address => @address
    }
  end
  
  # Testing that we can successfully make a purchase in a one step
  # operation
  def test_successful_purchase
    response = @gateway.purchase(Money.new(198, 'GBP'), @mastercard, @params)
    assert response.success?
    assert response.test?
  end
  
  #the amount is changed to £1.99 - the DC test server won't check the
  #address details - this is more a check on the passed ExtendedPolicy
  def test_successful_purchase_without_address_check
    response = @gateway.purchase(Money.new(199, 'GBP'), @mastercard, @params)
    assert response.success?
    assert response.test?
  end
  
  def test_successful_purchase_with_solo_card
    response = @gateway.purchase(Money.new(198, 'GBP'), @solo, @params)
    assert response.success?
    assert response.test?
  end
  
  # this card number won't check the address details - testing extended
  # policy
  def test_successful_purchase_without_address_check2
    @mastercard.number = 633499110000000003
    
    response = @gateway.purchase(Money.new(198, 'GBP'), @mastercard, @params)
    assert response.success?
    assert response.test?
  end
  
  def test_invalid_verification_number
    @mastercard.verification_value = 123
    response = @gateway.purchase(Money.new(198, 'GBP'), @mastercard, @params)
    assert !response.success?
    assert response.test?
  end
  
  def test_invalid_expiry_month
    @mastercard.month = 13
    response = @gateway.purchase(Money.new(198, 'GBP'), @mastercard, @params)
    assert !response.success?
    assert response.test?
  end
  
  def test_invalid_expiry_year
    @mastercard.year = 1999
    response = @gateway.purchase(Money.new(198, 'GBP'), @mastercard, @params)
    assert !response.success?
    assert response.test?
  end
  
  def test_successful_authorization_and_capture
    amount = Money.new(198, 'GBP')
    
    authorization = @gateway.authorize(amount, @mastercard, @params)
    assert authorization.success?
    assert authorization.test?
    
    capture = @gateway.capture(amount, authorization.authorization, @params)
    assert capture.success?
    assert capture.test?
  end
  
  def test_unsuccessful_capture
    response = @gateway.capture(Money.new(198, 'GBP'), '1234', @params)
    assert !response.success?
    assert response.test?
  end
  
  def test_successful_authorization_and_void
    amount = Money.new(198, 'GBP')
    
    authorization = @gateway.authorize(amount, @mastercard, @params)
    assert authorization.success?
    assert authorization.test?
    
    void = @gateway.void(authorization.authorization, @params)
    assert void.success?
    assert void.test?
  end
  
  def test_successfuly_purchase_and_void
    purchase = @gateway.purchase(Money.new(198, 'GBP'), @mastercard, @params)
    assert purchase.success?
    assert purchase.test?
    
    void = @gateway.void(authorization.authorization, @params)
    assert void.success?
    assert void.test?
  end
end
