# coding: utf-8
require 'nokogiri'
require 'open-uri'
require 'logger'
require 'yaml'
require 'fileutils'

MAX_RETRY_TIMES = 8 
BASE_URL = 'http://www.cssmoban.com'
LOCAL_IMAGE_DIR = 'CssTemplateImages'
LOCAL_SOURCE_FILE_DIR = 'SourceFiles'
LOCAL_PREVIEW_FILE_DIR = 'PreviewFiles'

FileUtils.makedirs(LOCAL_IMAGE_DIR) unless File.exists?LOCAL_IMAGE_DIR
FileUtils.makedirs(LOCAL_SOURCE_FILE_DIR) unless File.exists?LOCAL_SOURCE_FILE_DIR
FileUtils.makedirs(LOCAL_PREVIEW_FILE_DIR) unless File.exists?LOCAL_PREVIEW_FILE_DIR
@logger = Logger.new('templaterunning.log')

def get_doc(link) 
  search_link = "#{BASE_URL}#{link}"
  @logger.info "list page: #{search_link}"
  retry_times = 0
  begin
    doc = Nokogiri::HTML(open(search_link))
  rescue
    @logger.error "download search page error: #{search_link}"
    retry_times += 1
    retry if retry_times < MAX_RETRY_TIMES
  end
  
  if doc.nil?
    File.open('errorlinks.yml', 'a+'){|f| YAML.dump(link, f)}
  end

  return doc
end

links = YAML.load(File.open('templatelinks.yml'))
links.each do |link|
  doc = get_doc(link) 
  if doc
    begin
      title = doc.css("div.con-right > h1")[0].text

      preview_link = doc.css("a.btn-demo")[0]['href']
      preview_index = preview_link.slice(/[^\/]+$/)  

      keys = doc.css("div.tags > a")
      keywords = Array.new
      keys.each do |key|
        keywords << key.text unless key.text == "更多>>"
      end

      image_src = doc.css("div.large-Imgs > img")[0]['src']
      image = image_src.slice(/[^\/]+$/)
      File.open("#{LOCAL_IMAGE_DIR}/#{image}", "w") do |f|
        f.write(open("#{BASE_URL}#{image_src}").read)
      end

      download_link = doc.css("a.btn-down")[0]['href']
      source = download_link.slice(/[^\/]+$/)
      source_name = source.slice(/[^\.]+/)
      File.open("#{LOCAL_SOURCE_FILE_DIR}/#{source}", "w") do |f|
        f.write(open("#{download_link}").read)
      end

      template_info = Hash.new
      template_info['title'] = title 
      template_info['keywords'] = keywords 
      template_info['image'] = "/#{LOCAL_IMAGE_DIR}/#{image}"
      template_info['download'] = "/#{LOCAL_SOURCE_FILE_DIR}/#{source}"
      template_info['preview'] = "/#{LOCAL_PREVIEW_FILE_DIR}/#{source_name}/#{preview_index}"

      File.open('templates.yml', 'a+'){|f| YAML.dump(template_info, f)}
    rescue
      @logger.error "doc find content error: #{link}"
    end
  end
  sleep(0.5)
end
