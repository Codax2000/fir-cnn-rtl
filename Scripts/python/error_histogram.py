import pandas as pd
import matplotlib as plt
import altair as alt
from bitstring import BitArray
import numpy as np

def get_expected_values():
    file_path = "./mem/toplevel/test_outputs_expected.mif"
    result = list()
    with open(file_path) as f:
        lines = f.readlines()
        for i in range(len(lines)):    
            new_result_line = dict()
            new_result_line['index'] = i
            str_test = lines[i].strip()
            vals = [str_test[i:i+4] for i in range(0, len(str_test), 4)]
            vals.reverse()
            for j in range(len(vals)):
                key = f"col_{j}"
                new_result_line[key] = twos_complement(vals[j])
            result.append(new_result_line)
    return pd.DataFrame(result).set_index('index').melt(var_name='column').rename(columns={'value': 'expected'})


def get_actual_values():
    file_path = "./mem/test_values/test_outputs_actual.csv"
    result = list()
    with open(file_path) as f:
        lines = f.readlines()
        for i in range(len(lines)):    
            new_result_line = dict()
            str_test = lines[i].strip().split(',')
            new_result_line['index'] = str_test[0]
            vals = [str_test[i] for i in range(1, len(str_test))]
            for j in range(len(vals)):
                key = f"col_{j}"
                new_result_line[key] = twos_complement(vals[j])
            result.append(new_result_line)
    return pd.DataFrame(result).set_index('index').melt(var_name='column').rename(columns={'value': 'actual'})

def get_actual_error_values():
    file_path = "./mem/test_values/test_outputs_errors.csv"
    result = list()
    with open(file_path) as f:
        lines = f.readlines()
        for i in range(len(lines)):    
            new_result_line = dict()
            str_test = lines[i].strip().split(',')
            new_result_line['index'] = str_test[0]
            vals = [str_test[i] for i in range(1, len(str_test))]
            for j in range(len(vals)):
                key = f"col_{j}"
                new_result = float(vals[j])
                if (new_result) < -15:
                    new_result += 16
                elif (new_result) > 15:
                    new_result -= 16
                new_result_line[key] = new_result
            result.append(new_result_line)
    return pd.DataFrame(result).set_index('index').melt(var_name='column').rename(columns={'value': 'actual'})

def twos_complement(hexstr):
    value = BitArray(hex=hexstr)
    return value.int / (2 ** 12)


def plot_calculated_error_histogram():
    actual = get_actual_values()
    expected = get_expected_values()[:len(actual)]
    data = actual.copy()
    data['expected'] = expected['expected']
    data['error'] = (data['expected'] - data['actual'])
    data_filter = data['error'] > 0.05
    data[data_filter].to_csv('./Scripts/data/error_data.csv')
    alt.Chart(data).mark_bar().encode(
        x=alt.X('error:Q',
                bin=alt.BinParams(maxbins=40)),
        y='count()'
    ).properties(
        title='Normalized Error'
    ).save("./Scripts/data/measured_error_histogram.html")


def plot_measured_error_histogram():
    df = get_actual_error_values()
    df_filter_5 = df['actual'].abs() < 0.05
    df_filter_10 = df['actual'].abs() < 0.1
    df_filtered_5 = df[df_filter_5]
    df_filtered_10 = df[df_filter_10]
    print(f"Percent of Values Within 0.05: {100 * len(df_filtered_5) / len(df)}")
    print(f"Percent of Values Within 0.10: {100 * len(df_filtered_10) / len(df)}")
    chart = alt.Chart(df_filtered_10).mark_bar().encode(
        x=alt.X('actual:Q',
                bin=alt.BinParams(maxbins=40),
                title='Absolute Error'),
        y=alt.Y('count()',
                title='Count')
    ).properties(
        title='Histogram of Error'
    )

    (chart).save('Scripts/data/calc_error_histogram.html')

    

def main():
    plot_measured_error_histogram()

if __name__ == '__main__':
    main()