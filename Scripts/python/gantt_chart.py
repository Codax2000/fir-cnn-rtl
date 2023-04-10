import pandas as pd
import altair as alt

def get_data():
    data = pd.read_excel("../data/ECE478_526 Status.xlsx", 1, parse_dates=['Start Date', 'End Date'])
    print(data.info())
    return data

def gantt_chart(data):
    alt.Chart(data).mark_bar().encode(
        x='Start Date:Q',
        x2='End Date:Q',
        y='Task:N'
    ).save('../data/gantt_chart.html')

def main():
    data = get_data()
    gantt_chart(data)

if __name__ == '__main__':
    main()