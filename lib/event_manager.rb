require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone(phone)
  phone = phone.to_s.scan(/\d+/).join('')
  digits = phone.length
  condition = digits < 10 || digits > 11 || (digits == 11 && phone[0] != '1')

  if condition
    'Bad number'
  elsif digits == 11 && phone[0] == '1'
    phone[1..10]
  else phone
  end
end

def format_time(time)
  Time.parse(time).hour
end

def format_date(date)
  date = date.to_s.scan(/\d+/).each {
      |item| item.length < 2? item.rjust(2,'0').to_i : item.to_i
    }
  y = date[2]
  m = date [0]
  d = date[1]
  weekday = Date.parse([y, m, d].join('-'), true).wday
  days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
  days[weekday]
end

def find_pop_day(csv_file)
  day_hash = Hash.new(0)
  csv_file.each do |row|
    day_hash[format_date(row[:regdate].split(' ').first)] += 1
  end
  day_hash
end

def find_pop_time(csv_file)
  time_hash = Hash.new(0)
  csv_file.each do |row|
    time_hash[format_time(row[:regdate].split(' ').last)] += 1
  end
  time_hash
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyBtm72DQfDXAS6tqj6rIGCLWNsa0Pq9phw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
).to_a

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  telephone = clean_phone(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  regdate = format_date(row[:regdate].split(' ').first)
  regtime = format_time(row[:regdate].split(' ').last)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id,form_letter)
  puts "#{regdate} & #{regtime}"
end

puts find_pop_time(contents)
puts find_pop_day(contents)


