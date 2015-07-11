VCR.configure do |c|
  # temporarily allows calls to go directly to facebook
  #c.ignore_hosts 'facebook.com', 'graph.facebook.com'
  
  c.cassette_library_dir  = Rails.root.join("spec", "vcr")
  #c.hook_into :fakeweb
  c.hook_into :typheous
end
