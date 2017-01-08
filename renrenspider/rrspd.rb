# coding: utf-8
require 'nokogiri'
require 'open-uri'
require 'logger'
require 'yaml'

MAX_RETRY_TIMES = 8 
logger = Logger.new('running.log')

#read File
obj = YAML.load(File.open('universityjson.txt'))

rst = Hash.new
obj.each do |o|
  uns = Hash.new
  o["univs"].each do |u|

    search_link = "http://www.renren.com/GetDep.do?id=#{u['id']}"
    
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
    
    clg = Array.new
    doc.css('option')[1..-1].each do |div|
      begin
        clg << div['value'].to_s
      rescue
        logger.error "parse search page error: #{div.children}"
        next
      end
    
    end
    uns[u['name'].to_s] = clg
    sleep 0.5
  end

  rst[o['name'].to_s] = uns
end
#write File
File.open('unres.yaml','a+'){|f| YAML.dump(rst,f)}
