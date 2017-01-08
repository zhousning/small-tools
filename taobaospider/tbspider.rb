# coding: utf-8
require 'restclient'
require 'nokogiri'
require 'open-uri'
require 'logger'
require 'yaml'
#require 'pry'
#require 'pry-debugger'

MAX_RETRY_TIMES = 5
logger = Logger.new('running.log')

keyword = "初中视频"
search_link = "http://mosaic.re.taobao.com/search?keyword=#{URI.escape(keyword)}&_input_charset=utf-8"
#search_link = "http://mosaic.re.taobao.com/search?keyword=%E4%BA%BA%E5%8F%82%E9%85%92&_input_charset=utf-8"
logger.info "list page: #{search_link}"
retry_times = 0

begin
  doc = Nokogiri::HTML(open(search_link))
rescue
  logger.error "download search page error: #{search_link}"
  retry_times += 1
  retry if retry_times < MAX_RETRY_TIMES
end

if doc.nil?
  logger.error "download search page error: #{search_link}"
  exit
end

count = 0
doc.css('#searchResult .item').each do |div|
  count += 1
  begin
    item_title = div.css('div.info a.title')[0]['title']
    item_shopname = div.css('div.info p.shopName a.shopNick')[0].content
  rescue
    logger.error "parse search page error: #{div.children}"
    next
  end

  logger.info "[#{count}] title: #{item_title} shopname: #{item_shopname}"

  #sleep 0.5
end

