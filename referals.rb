require 'rubygems'
require 'sinatra'
require 'yaml'
require 'garu'

# Configuration
SETTINGS = YAML.load_file('settings.yml')

before '/*' do
  # Garu handles the google analytics communication
  @garu = Garu.new(SETTINGS["ga_code"], request)
  begin
    @resp = @garu.trackPageView()
  rescue
    # An exception has been throw from the GA request,
    # => but we redirect regardless at the moment.
    # => Maybe do somwthing else instead of continuing?
  end
end

get '/*' do
  if @resp
    # Setting the tracker cookie if returned by Garu
    if !@resp["cookie"].nil?
      c = @resp["cookie"]
      response.set_cookie(c["name"],
        :value => c["value"],
        :domain => c["domain"],
        :path => c["path"],
        :expires => c["expires"])
    end
  
    # Setting response headers from Garu
    if !@resp["headers"].nil?
      @resp["headers"].each do |h, value|
        response[h] = value
      end
    end
    response.body = @resp["body"]
  else
    response.body = 'error'
  end
  
  # Attemps to identify a redirect in the config file
  # => from the request path
  # => If no redirect is found, redirect to the default
  # => redirect (set on github for the public repo settings)
  slicedPath = request.path.gsub(/^\//, "")
  
  if !SETTINGS["redirects"][slicedPath].nil?
    redirect SETTINGS["redirects"][slicedPath] and return
  else
    redirect SETTINGS["default_redirect"] and return
  end
end