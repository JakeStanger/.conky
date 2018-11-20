"""
Shows basic usage of the Google Calendar API. Creates a Google Calendar API
service object and outputs a list of the next 10 events on the user's calendar.
"""
from apiclient.discovery import build
from httplib2 import Http
from oauth2client import file, client, tools
from datetime import datetime
import calendar

# Setup the Calendar API
SCOPES = 'https://www.googleapis.com/auth/calendar.readonly'
store = file.Storage('credentials.json')
creds = store.get()
if not creds or creds.invalid:
    flow = client.flow_from_clientsecrets('client_secret.json', SCOPES)
    creds = tools.run_flow(flow, store)
service = build('calendar', 'v3', http=creds.authorize(Http()))

# Call the Calendar API
now = datetime.utcnow().isoformat() + 'Z'  # 'Z' indicates UTC time
print('Getting the upcoming 10 events')
events_result = service.events().list(calendarId='primary', timeMin=now,
                                      maxResults=10, singleEvents=True,
                                      orderBy='startTime').execute()
events = events_result.get('items', [])

if not events:
    print('No upcoming events found.')
for event in events:
    start = event['start'].get('dateTime', event['start'].get('date'))
    print(start, event['summary'])


print()
cal = calendar.Calendar()
print(cal.yeardayscalendar(year=2018, width=4))

print()
print()

textcal = calendar.TextCalendar()
print(textcal.formatyear(2018))


first_of_month = datetime.today().replace(day=1)
calendar = calendar.monthcalendar(first_of_month.year, first_of_month.month)



# for week in calendar:
#     print(week)

# day_of_first = first_of_month.weekday()
# name_of_first = first_of_month.strftime("%A")
#
# print(day_of_first)
# print(name_of_first)
#
# for i in range(1 - day_of_first, 7*5):
#     if i < 1 print(monthrange())
#     print(i)