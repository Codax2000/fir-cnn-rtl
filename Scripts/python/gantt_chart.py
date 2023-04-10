import pandas as pd
import altair as alt

def get_data():
    start_date = pd.to_datetime('3/27/2023')
    data = pd.read_excel("./Scripts/data/ECE478_526 Status.xlsx", 1, parse_dates=['Start Date', 'End Date'])
    print(data.info())
    return data

def gantt_chart(data):
    alt.Chart(data, title='Neural Net Gantt Chart').mark_bar().encode(
        x='Start Date:T',
        x2='End Date:T',
        y=alt.Y('Task:N', sort='x'),
        color=alt.Color('Assignee:N',
                        scale=alt.Scale(
                            domain=['Alex', 'Eugene', 'Alex, Eugene'],
                            range=['blue', 'red', 'green']
                        ))
    ).properties(

    ).save('./Scripts/data/gantt_chart.html')

def main():
    data = get_data()
    gantt_chart(data)

if __name__ == '__main__':
    main()