require 'net/http'
require 'net/https'

USERNAME = 'YOUR_USERNAME'
PASSWORD = 'YOUR_PASSWORD'
AUTH_COOKIE = 'AUTH_COOKIE_VALUE'

BASE_URL = 'https://loboplus.com'
CATALOG_URL = "https://loboplus.com/es/los-miembros/descargar-las-zonas-de-escalada.html?layout=columns&filter_order=tbl.created_time&filter_order_Dir=DESC"

class Downloader
  class << self
    def download
      pages = Array(0..8)
      pages.each do |page_number|
        download_topos(page_number)
      end
    end

    private

    def download_topos(page_number)
      puts "Downloading page #{page_number + 1}..."
      page = get(page_url(page_number))
      links = get_links_from(page.body)
      links.each do |link|
        download_topo(link)
      end
    end

    def page_url(page_number)
      offset = 20
      "#{CATALOG_URL}&start=#{page_number * offset}"
    end

    def get_links_from(page_content)
      page_content.scan(/\/.*download.html/).uniq
    end

    def download_topo(link)
      full_url = URI.escape(full_url_for(link))
      filename = "#{link.split('/')[-2]}.pdf"
      puts "Downloading #{filename}..."
      file_content = get(full_url).body

      save_pdf(filename, file_content)
      puts "Download complete"
    end

    def full_url_for(link)
      "#{BASE_URL}#{link}"
    end

    def save_pdf(filename, content)
      file = File.new(filename, 'w')
      file.syswrite(content)
      file.close()
    end

    def get(url)
      uri = URI(url)

      http = http_for(uri)

      request = Net::HTTP::Get.new(uri.request_uri)
      request.add_field('Cookie', "#{AUTH_COOKIE}")

      response = http.request(request)
      return get(URI.escape(response.header['location'])) if response.code == '303'
      response
    end

    def http_for(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end
  end
end

Downloader.download
