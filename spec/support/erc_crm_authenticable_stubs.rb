# frozen_string_literal: true

module ErcCrmAuthenticableStubs
  def stub_valid_request
    stub_request(:get, file_fixture("request.txt").read)
      .with(
        headers:
      ).to_return(
        status: 200,
        body: file_fixture("valid_response.txt").read,
        headers: {}
      )
  end

  def stub_invalid_request_not_member
    stub_request(:get, file_fixture("request.txt").read)
      .with(
        headers:
      ).to_return(
        status: 200,
        body: file_fixture("invalid_response_not_member.txt").read,
        headers: {}
      )
  end

  def stub_invalid_request_not_militant
    stub_request(:get, file_fixture("request.txt").read)
      .with(
        headers:
      ).to_return(
        status: 200,
        body: file_fixture("invalid_response_mbsp_name.txt").read,
        headers: {}
      )
  end

  def stub_invalid_request_was_member
    stub_request(:get, file_fixture("request.txt").read)
      .with(
        headers:
      ).to_return(
        status: 200,
        body: file_fixture("invalid_response_mbsp_status_id.txt").read,
        headers: {}
      )
  end

  def stub_invalid_request_not_enough_seniority
    stub_request(:get, file_fixture("request.txt").read)
      .with(
        headers:
      ).to_return(
        status: 200,
        body: file_fixture("invalid_response_mbsp_join_date.txt").read,
        headers: {}
      )
  end

  def stub_invalid_request_connection_error
    stub_request(:get, file_fixture("request.txt").read)
      .with(
        headers:
      ).to_return(
        status: 200,
        body: file_fixture("invalid_response_connection_error.txt").read,
        headers: {}
      )
  end

  private

  # This will change depending on your gems versions.
  def headers
    {
      "Accept" => "*/*",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Host" => "api.base",
      "User-Agent" => "rest-client/2.1.0 (linux-gnu x86_64) ruby/2.7.2p137"
    }
  end
end
