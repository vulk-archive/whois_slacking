require 'rspec'
require 'vcr'
require './lib/whois_slacking'
#require 'webmock/rspec'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :typhoeus
  c.filter_sensitive_data("<API_KEY>") { WhoIsSlacking.apikey } 
end

RSpec.configure do |config|


  config.mock_with :rspec

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.around(:each, :vcr) do |example|
    #name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").downcase.gsub(/\s+/,"_")
    #options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    options = example.metadata.reduce({}){ |acc, x| [:record,:match_requests_on].include?(x[0]) ? acc.merge({x[0] => x[1]}) : acc } 
    VCR.use_cassette(name, options) { example.call }
    #VCR.use_cassette(name) { example.call }
  end

  # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  #WebMock.disable_net_connect!(:allow => 'coveralls.io')

  #RSpec.configure do |config|
  #  config.expect_with :rspec do |c|
  #    c.syntax = :expect
  #  end
  #end


end
