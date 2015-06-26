require 'mechanize'
require 'google/api_client'

agent = Mechanize.new
# Login Part
# page = agent.get('https://www.airbnb.com/login')
# forms = page.forms
# form =  forms[4]
# form.email = 'info@ihspusa.com'
# form.password= '9993chicago'
# form.submit
# # End Login

# page = agent.get('https://www.airbnb.com/my_reservations?all=1')

page = agent.get('file:///home/wyatt/Apps/rubycal/main.html')
# # Click on "Your Listings"
# agent.page.link_with(:text => 'Your Listings').click

# # Click on "Your Reservations"
# agent.page.link_with(:text => 'Your Reservations').click
# agent.page.link_with(:text => 'Your Reservations').click

# # Click on "View all reservation history"
# agent.page.link_with(:text => "View all reservation history").click

reservations = page.search("tr.reservation")

reservation = reservations[0]

cols = reservation.search("td").map(&:text)

status =  cols[0]
date_location =  "#{cols[1]} One"
puts "#{cols[2]} Two"
puts "#{cols[3]} Three"

puts date_location

# Reg Ex Stuuf
monthstart = /\w{3}/.match(date_location)
monthend = /- \w{3}/.match(date_location)
daystart = /\d\d/.match(date_location)
dayend =/ \d{1,2},/.match(date_location)
# End Reg Ex Stuff

# Convert Day 1 and Day 2 from matchdata to string and then to int [0] gets a string
daystart = daystart[0].to_i
dayend = dayend[0].delete(",").to_i

# If month two is nill then it make monthend = to monthstart 
monthend.nil? ? monthend = monthstart  :  monthend = monthend[0][2..-1]

puts "This booking is from #{monthstart} #{daystart} to #{monthend} #{dayend}"

# puts "Date1 #{date1.nil?}"
# puts "Date2 #{date2.nil?}"
# puts date1

# if (daystart == 18)
# 	puts "Yes it is "
# end







File.open("main.html", 'w') { |file| file.write("#{agent.page.body}") }



