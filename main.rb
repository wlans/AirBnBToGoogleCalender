require 'mechanize' # Used for logging into AirBnB and finding the data 
#Gooole Calender API Require
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'
require 'base32'
#End Calender Api Require

# Convert a month in letters to the numerical REFACT (Are the Letters right?)
def convert_month_to_number(month)
	case month
		when "Jan"
			month = 1
		when "Feb"
			month = 2
		when "Mar"
			month = 3
		when "Apr"
			month = 4
		when "May"
			month = 5
		when "Jun"
			month = 6
		when "Jul"
			month = 7
		when "Aug"
			month = 8
		when "Sep"
			month = 9
		when "Oct"
			month = 10
		when "Nov"
			month = 11
		when "Dec"
			month = 12
		else
			month = nil
	end	
end
# End convert month to number function

#Google Calender API Setup

APPLICATION_NAME = 'AirBnB Reservations To Google Calendar'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-airbnb_to_google_calender.json")
SCOPE = 'https://www.googleapis.com/auth/calendar'

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization request via InstalledAppFlow.
# If authorization is required, the user's default browser will be launched
# to approve the request.
#
# @return [Signet::OAuth2::Client] OAuth2 credentials
def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
  storage = Google::APIClient::Storage.new(file_store)
  auth = storage.authorize

  if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
    app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
    flow = Google::APIClient::InstalledAppFlow.new({
      :client_id => app_info.client_id,
      :client_secret => app_info.client_secret,
      :scope => SCOPE})
    auth = flow.authorize(storage)
    puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
  end
  auth
end

# Initialize the API
client = Google::APIClient.new(:application_name => APPLICATION_NAME)
client.authorization = authorize
calendar_api = client.discovered_api('calendar', 'v3')

# End Google Calender API

agent = Mechanize.new
puts "Get Data From AirBnB? (Type yes)"
input = gets
if input.strip == "yes"
	#Login Part
	page = agent.get('https://www.airbnb.com/login')
	forms = page.forms
	form =  forms[3]   #AirBnB keeps changing where the form is located if this fails change to 3 or 4 REFACT
	puts "Enter Email For AirBnB Account"
	form.email = gets.chomp
	puts "Enter Password For AirBnB Account"
	form.password= gets.chomp
	form.submit
	#End Login

	page = agent.get('https://www.airbnb.com/my_reservations?all=1')

	File.open("main.html", 'w') { |file| file.write("#{agent.page.body}") }
	puts "Connected to #{page.title}"
end

page = agent.get('file:///home/wyatt/Apps/rubycal/main.html')

reservations = page.search("tr.reservation")

reservations.each do  |reservation|
	
	cols = reservation.search("td").map(&:text)

	status =  cols[0]
	date_location =  cols[1]
	name =  cols[2]
	price = cols[3]

	if status.include?("Accepted") # If accpted reservation then it gets put it


			# puts date_location

			# Reg Ex Stuff
		monthstart = /\w{3}/.match(date_location).to_s
		monthend = /- \w{3}/.match(date_location)
		daystart = /\d+/.match(date_location)
		dayend =/ \d{1,2},/.match(date_location)
		year =/\d{4}/.match(date_location)
		price =/[0-9]+/.match(price)
		# End Reg Ex Stuff

		# Convert Day 1 and Day 2 from matchdata to string and then to int [0] gets a string
		daystart = daystart[0].to_i
		dayend = dayend[0].delete(",").to_i
		name = /\w+[[:blank:]]*\w*/.match(name).to_s
		# May need two years if there is a res that spans two years REFACT
		year = year[0].to_i

		# If month two is nill then it make monthend = to monthstart 
		monthend.nil? ? monthend = monthstart  :  monthend = monthend[0][2..-1]

		# puts "This booking is from #{monthstart} #{daystart} to #{monthend} #{dayend}"
		# puts year
		# puts price

		reservation_id = Base32.encode("#{year}#{name.delete(" ").downcase}da#{convert_month_to_number(monthstart)}#{daystart}s").downcase.delete("w,x,y,z,=") 



		# Create event
		event = {
			'summary' => "AirBnB Reservation for #{name} $#{price} ",
			'start' => {
				'date' => "#{year}-#{convert_month_to_number(monthstart)}-#{daystart}"
			},
			'end' => {
				'date' => "#{year}-#{convert_month_to_number(monthend)}-#{dayend}"
			
			},
			'id' => "#{reservation_id}",
		}

		result = client.execute(:api_method => calendar_api.events.delete,
		                        :parameters => {:calendarId => 'primary', :eventId => 'eventId'})

		puts event

		begin
			results = client.execute!(
			
				:api_method => calendar_api.events.insert,
				:parameters => {
					:calendarId => 'primary'},
				:body_object => event)

				event = results.data
				puts "Event Created: #{event.id}"

			rescue

			results = client.execute(
			
			  :api_method => calendar_api.events.update,
			  :parameters => {
					:calendarId => 'primary',
					:eventId => '11bcqd7pe6e7s0rnabd7h92r1i1i'},
				:body_object => event)

				event = results.data
				puts "Event Updated: #{event.id}"
			else
				puts "Unknown Error" 
		end

		# puts monthend
		# puts convert_month_to_number(monthstart)
		#puts monthend.class
		# puts "Date1 #{date1.nil?}"
		# puts "Date2 #{date2.nil?}"
		# puts date1
		# if (daystart == 18)
		# 	puts "Yes it is "
		# end
	end  # End if statment for
end # End Each for reservations









