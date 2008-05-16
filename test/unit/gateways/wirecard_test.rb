require File.dirname(__FILE__) + '/../../test_helper'

# This is the unit test class for the WireCard Gateway
#
# In the test cases the job and transaction ids of the response
# do not match the job and transaction ids of the request. This
# is du to the fact that we use dummy response messages.
#
class WirecardTest < Test::Unit::TestCase
  def setup
    @gateway = WirecardGateway.new(
                                   :login => 'login',
                                   :password => 'password',
                                   :business_case_signature => '123'
               )

    @credit_card = credit_card
    @amount = 100

    # :billing_address => address,

    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Unit Tests of WireCard Gateway Usage',
      :currency => 'CHF',
      :country => 'CH'
    }
  end

  def test_successful_authorize
    # Default Currency => Euro
    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Unit Tests of WireCard Gateway Usage'
    }
    @gateway.expects(:ssl_post).returns(successful_authorization_response_ack)
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'C242720181323966504820', response.authorization
    assert response.test?
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'C242720181323966504820', response.authorization
    assert response.test?
  end

  def test_failed_purchase
    @gateway.expects(:ssl_post).returns(failed_purchase_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end


  def test_successful_authorize_pending
    @gateway.expects(:ssl_post).returns(successful_authorization_response_pending)
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'C242720181323966504820', response.authorization
    assert response.test?
  end

  def test_failed_authorize
    @gateway.expects(:ssl_post).returns(failed_authorization_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_successful_capture
    @gateway.expects(:ssl_post).returns(successful_capture_response)
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response

    assert_equal 'C305830112714411123351', response.authorization
    assert response.test?
  end

  def test_failed_capture
    @gateway.expects(:ssl_post).returns(failed_capture_response)
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_supported_countries
    assert_equal ['DE'], WirecardGateway.supported_countries
  end

  def test_supported_card_types
    assert_equal [:visa, :master], WirecardGateway.supported_cardtypes
  end

  # more tests required.

  private

  # request is here for documentation purpose.
=begin
    request =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_REQUEST>
    <W_JOB>
      <JobID>user-assigned job-ID</JobID>
      <BusinessCaseSignature>0123456789ABCDEF</BusinessCaseSignature>
      <FNC_CC_TRANSACTION>
        <FunctionID>user-assigned function-ID</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>unique user-assigned transaction-ID</TransactionID>
          <CountryCode>DE</CountryCode>
          <CommerceType></CommerceType>
          <Amount minorunits="2">50000</Amount>
          <Currency>EUR</Currency>
          <Usage>DE</Usage>
          <CREDIT_CARD_DATA>
            <CreditCardNumber>4200000000000000</CreditCardNumber>
            <CVC2>1234</CVC2>
            <ExpirationYear>2009</ExpirationYear>
            <ExpirationMonth>01</ExpirationMonth>
            <CardHolderName>John Doe</CardHolderName>
          </CREDIT_CARD_DATA>
          <CONTACT_DATA>
            <IPAddress>192.168.1.1</IPAddress>
          </CONTACT_DATA>
        </CC_TRANSACTION>
      </FNC_CC_TRANSACTION>
    </W_JOB>
  </W_REQUEST>
</WIRECARD_BXML>
EOF
=end

  ###################################################
  # Purchase

  # Place raw successful response from gateway here
  # RESPONS HAS ACK
  def successful_purchase_response
    response =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>job 1</JobID>
      <FNC_CC_PURCHASE>
        <FunctionID>function 1</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>9457892347623478</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C242720181323966504820</GuWID>
            <FunctionResult>ACK</FunctionResult>
            <TimeStamp>2001-01-31 20:39:24</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_PURCHASE>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

  # Place raw failed response from gateway here
  def failed_purchase_response
    response =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>job 1</JobID>
      <FNC_CC_PURCHASE>
        <FunctionID>function 1</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>9457892347623478</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C242720181323966504827</GuWID>
            <StatusType>INFO</StatusType>
            <FunctionResult>NOK</FunctionResult>
            <ERROR>
              <Type>REJECTED</Type>
              <Number>05</Number>
              <Message>Authorization Declined.</Message>
              <Advice>It is not possible to book the given amount from the
              credit account, e. g. limit is exceeded.</Advice>
            </ERROR>
            <TimeStamp>2001-01-31 20:39:24</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_PURCHASE>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

  ###################################################
  # Authorization

  # Success with an ACK
  def  successful_authorization_response_ack
    response = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>job 1</JobID>
      <FNC_CC_AUTHORIZATION>
        <FunctionID>function 1</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>9457892347623478</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C242720181323966504820</GuWID>
            <AuthorizationCode>153620</AuthorizationCode>
            <FunctionResult>ACK</FunctionResult>
            <TimeStamp>2001-01-31 20:39:24</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_AUTHORIZATION>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

  # Success with PENDING
  def successful_authorization_response_pending
    response = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>job 1</JobID>
      <FNC_CC_AUTHORIZATION>
        <FunctionID>function 1</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>9457892347623478</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C242720181323966504820</GuWID>
            <AuthorizationCode>153620</AuthorizationCode>
            <FunctionResult>PENDING</FunctionResult>
            <TimeStamp>2001-01-31 20:39:24</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_AUTHORIZATION>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

  # Response with NOK and detailed error message
  def failed_authorization_response
    response =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>job 1</JobID>
      <FNC_CC_AUTHORIZATION>
        <FunctionID>function 1</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>9457892347623478</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C242720181323966504827</GuWID>
            <AuthorizationCode>799961</AuthorizationCode>
            <StatusType>INFO</StatusType>
            <FunctionResult>NOK</FunctionResult>
            <ERROR>
              <Type>REJECTED</Type>
              <Number>05</Number>
              <Message>Authorization Declined.</Message>
              <Advice>It is not possible to book the given amount from the
              credit account, e. g. limit is exceeded.</Advice>
            </ERROR>
            <TimeStamp>2001-01-31 20:39:24</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_AUTHORIZATION>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

  ###################################################
  # Capture

  def successful_capture_response
    response =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>ACCEPTANCE_TEST</JobID>
      <FNC_CC_CAPTURE_AUTHORIZATION>
        <FunctionID>CITI-KAAI</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>8</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C305830112714411123351</GuWID>
            <StatusType>INFO</StatusType>
            <FunctionResult>ACK</FunctionResult>
            <TimeStamp>2005-09-19 17:32:22</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_CAPTURE_AUTHORIZATION>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

  def failed_capture_response
    response =<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<WIRECARD_BXML xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="wirecard.xsd">
  <W_RESPONSE>
    <W_JOB>
      <JobID>job 1</JobID>
      <FNC_CC_CAPTURE_AUTHORIZATION>
        <FunctionID>function 1</FunctionID>
        <CC_TRANSACTION mode="demo">
          <TransactionID>9457892347623478</TransactionID>
          <PROCESSING_STATUS>
            <GuWID>C242720181323966504827</GuWID>
            <StatusType>INFO</StatusType>
            <FunctionResult>NOK</FunctionResult>
            <ERROR>
              <Type>REJECTED</Type>
              <Number>21</Number>
              <Message>No action taken.</Message>
            </ERROR>
            <TimeStamp>2001-01-31 20:39:24</TimeStamp>
          </PROCESSING_STATUS>
        </CC_TRANSACTION>
      </FNC_CC_CAPTURE_AUTHORIZATION>
    </W_JOB>
  </W_RESPONSE>
</WIRECARD_BXML>
EOF
    response
  end

end
