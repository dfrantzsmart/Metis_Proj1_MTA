import pandas
import sys
def get_data(week_nums):
    """ Takes a list of weeknums and pulls data from mta
    inputs = list of weeknums in format of: '190803'
    outputs = Joined Dataframe of all weeks
    """
    url = 'http://web.mta.info/developers/data/nyct/turnstile/turnstile_{}.txt'
    dfs = []
    for week_num in week_nums:
        file_url = url.format(week_num)
        dfs.append(pandas.read_csv(file_url))
    return pandas.concat(dfs)


def Add_Weekday(data_frame, column='DATE'):
    """
    Takes the Date column, converts to a date and adds a weekday
    input: Dataframe, Column Name
    output: Updated Dataframe with new columns
    """
    dmap = {0:'Mon', 1: 'Tue', 2: 'Wed', 3:'Thu', 4:'Fri', 5:'Sat', 6:'Sun'}
    data_frame['Day_Number'] = data_frame[column].apply(lambda x: x.dayofweek)
    data_frame['Weekday'] = data_frame['Day_Number'].map(dmap)
    return data_frame

def daytype(day):
    """Takes the day column and applies Weekday or Weekend
    input: Day
    output: Weekday or Weekend
    """
    if day == 'Sat' or day == 'Sun':
        return 'Weekend'
    else:
        return 'Weekday'

def convertTimeBuckets(time):

    """
    This function creates a new column that groups time intervals into categories:

    00:00 < late night <= 4:00
    4:00 < early risers <= 8:00
    8:00 < morning <= 12:00
    12:00 < afternoon <= 16:00
    16:00 < evening  <= 20:00
    20:00 < late night <= 00:00
    """

    hour = time.hour
    if hour > 20 or hour == 0:
        category = 'Late Night'
    elif hour > 16:
        category = 'Evening'
    elif hour > 12:
        category = 'Afternoon'
    elif hour > 8:
        category = 'Morning'
    elif hour > 4:
        category = 'Early Morning'
    elif hour > 0:
        category = 'Late Night'

    return category
