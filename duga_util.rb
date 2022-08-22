require 'net/http'
require 'uri'
require 'json'

module DugaUtil

  VERSION = '1.2'

  def self.search_title(params)
    params.store('version', VERSION)
    params.store('appid', ENV['DUGA_APPID'])
    params.store('agentid', ENV['DUGA_AGENTID'])
    params.store('bannerid', '01')
    params.store('format', 'json')
    params.store('adult', '1')

    uri = URI.parse("http://affapi.duga.jp/search?#{URI.encode_www_form(params)}")
    hash = get_hash(uri)
    return hash
  end

  private
  def self.get_hash(uri)
    begin
      response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.open_timeout = 5
        http.read_timeout = 10
        http.get(uri.request_uri)
      end

      case response
      when Net::HTTPSuccess
        hash = JSON.parse(response.body)
        return hash
      else
        puts "#{response.code} : #{response.message}"
      end
    rescue => e
      puts e
    end
  end
end
