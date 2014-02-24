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

log_file = open('log.txt','a')

puts "请输入保存有专利号的文件名，默认是patents.txt"
input = gets.chomp
input = 'patents.txt' if input.empty?
puts "请输入保存结果的文件名，默认是patents_record.csv"
output = gets.chomp
output = 'patents_record.csv' if output.empty?
puts "开始运行程序"
start_time = Time.now
ans = open(output,'w')
ans.puts "本专利,引用次数,引用专利,申请日期,发布日期,申请者,专利名称"
n = 0;
File.open(input).each_line do |line|
  n += 1
  next if line.strip.empty?
  path = "http://ajax.googleapis.com/ajax/services/search/patent?v=1.0&q=#{line}"
  response = URI.parse(path).read
  json = JSON.parse(response)
  real_url = json["responseData"]["results"]
  if real_url.empty?
    log_file.puts "#{Time.now},line #{n},patent: #{line.chomp},error: has no result"
    ans.puts "#{line.chomp},0, , , , ,has no result,"
    ans.puts
    next
  elsif real_url[0]["unescapedUrl"] =~ /google/
    patent_url = real_url[0]["unescapedUrl"].gsub(/cl=en/,'cl=zh')
    page = Nokogiri::HTML(open(patent_url))
  else
    log_file.puts "#{Time.now},line #{n},patent: #{line.chomp},error: not a google result"
    ans.puts "#{line.chomp},0, , , , ,not a google result,"
    ans.puts
    next
  end
  #page = get_page(line)
  page_tables = page.css('div.patent-tabular-section.patent-section table.patent-data-table')
  if cite?(page_tables)
    content = page_tables.first.css('tr')
    cite_count = content.size - 1
    content.drop(1).each do |row|
      ans.print "#{line.chomp},#{cite_count},"
      td_set = row.css('td')
      if td_set.size == 6
        td_set.delete(td_set[-2])
      end
      td_set.each do |con|
        ans.print "#{con.text.gsub(/,/,' ').gsub(/\s{1,}/,' ')},"
      end
      ans.puts
    end
  else
    ans.puts "#{line.chomp},0, , , , ,"
  end
  ans.puts
  puts n if n % 10 == 0
end
ans.close
log_file.close
end_time = Time.now
puts "程序运行时间为#{end_time - start_time}" 
