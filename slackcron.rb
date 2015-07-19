require 'whois_slacking'
require 'moneta'

@store = Moneta.new(:File, :dir => 'moneta')
WhoIsSlacking::Pivotal.connect_to_pivotal
WhoIsSlacking::Start.now
puts 'job finished'
