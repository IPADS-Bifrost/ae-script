import pandas as pd
import sys


def get_val(df, row, col):
    v = df.loc[row, df.columns[0]].split()[col]
    return float(v)

def work():
    cvm_df = pd.read_csv('res/4vcpu-cvm.res', sep='\t')
    postedirq_df = pd.read_csv('res/4vcpu-postirq.res', sep='\t')
    swiotlb_df = pd.read_csv('res/4vcpu-swiotlb.res', sep='\t')

    h = {
        1: (cvm_df, 0, 1), 2: (cvm_df, 0, 3), 3: (cvm_df, 0, 4),
        4: (cvm_df, 1, 1), 5: (cvm_df, 1, 2), 6: (cvm_df, 1, 3), 7: (cvm_df, 1, 4),
        8: (postedirq_df, 0, 3), 9: (postedirq_df, 0, 4),
        10: (postedirq_df, 1, 2), 11: (postedirq_df, 1, 3), 12: (postedirq_df,1, 4),
        13: (swiotlb_df, 0, 1), 14: (swiotlb_df, 0, 2),
    }

    lines = []
    with open('4vcpu-breakdown.gp', 'r') as f:
        lines = f.readlines()
    
    with open('4vcpu-breakdown.gp', 'w') as f:
        for line in lines:
            for num in range(len(h), 0, -1):
                sign = "##%d" % num
                if sign in line:
                    cols = line.split()
                    val = get_val(h[num][0], h[num][1], h[num][2])
                    cols[2] = '"%.2f"' % val
                    line = ' '.join(cols) + '\n'
                    break
            f.write(line)

if __name__ == "__main__":
    work()
