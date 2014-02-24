# encoding utf-8
require 'nokogiri'
require 'open-uri'
require 'json'

def cite?(page_tables)
  if page_tables.empty? or page_tables.size < 3
    false
  else
    true
  end
end

while(true)
  puts "please input the patent number and input q for quit the program"
  patent_number = gets.chomp
  break if patent_number == 'q'
  path = "http://ajax.googleapis.com/ajax/services/search/patent?v=1.0&q=#{patent_number}"
  response = URI.parse(path).read
  json = JSON.parse(response)
  real_url = json["responseData"]["results"]
  if real_url.empty?
    puts "has no result"
    next
  elsif real_url[0]["unescapedUrl"] =~ /google/
    patent_url = real_url[0]["unescapedUrl"].gsub(/cl=en/,'cl=zh')
    page = Nokogiri::HTML(open(patent_url))
  else
    puts "has no result"
    next
  end
  page_tables = page.css('div.patent-tabular-section.patent-section table.patent-data-table')
  if cite?(page_tables)
    content = page_tables.first.css('tr')
    puts "引用本专利,申请日期,发布日期,申请者,专利名称"

    content.drop(1).each do |row|
      row.css('td').each do |con|
        print "#{con.text.gsub(/,/,' ').gsub(/\s{1,}/,' ')},"
      end
      puts
    end
  else
    puts "此专利暂时无人引用"
  end
end
