import pandas as pd
import sys

h = {
    "amd-1":
    {
        1: (0, 1), 2: (0, 3), 3: (0, 4), 4: (0, 5),
        5: (1, 1), 6: (1, 2), 7: (1, 3), 8: (1, 4), 9: (1, 5),
        10: (2, 1), 11: (2, 3), 12: (2, 4), 13: (2, 5),
        14: (3, 1), 15: (3, 2), 16: (3, 3), 17: (3, 4), 18: (3, 5),
        19: (4, 1), 20: (4, 3), 21: (4, 4), 22: (4, 5),
    },
    "amd-4":
    {
        1: (0, 3), 2: (0, 4),
        3: (1, 2), 4: (1, 3), 5: (1, 4),
        6: (2, 1), 7: (2, 3), 8: (2, 4),
        9: (3, 1), 10: (3, 2), 11: (3, 3), 12: (3, 4),
        13: (4, 1), 14: (4, 3), 15: (4, 4),
    },
    "intel-1":
    {
        1: (0, 3), 2: (0, 4), 3: (0, 5),
        4: (1, 2), 5: (1, 3), 6: (1, 4), 7: (1, 5),
        8: (2, 3), 9: (2, 4), 10: (2, 5),
        11: (3, 2), 12: (3, 3), 13: (3, 4), 14: (3, 5),
        15: (4, 3), 16: (4, 4), 17: (4, 5),
    },
    "intel-4":
    {
        1: (0, 3), 2: (0, 4),
        3: (1, 2), 4: (1, 3), 5: (1, 4),
        6: (2, 3), 7: (2, 4),
        8: (3, 2), 9: (3, 3), 10: (3, 4),
        11: (4, 3), 12: (4, 4),
    },
}

def get_val(df, row, col):
    v = df.loc[row, df.columns[0]].split()[col]
    return float(v)

def work(arch, vcpu_nr):
    df = pd.read_csv('res/%dvcpu.res' % vcpu_nr, sep='\t')
    test_type =  "%s-%d" % (arch, vcpu_nr)
    
    lines = []
    with open('%dvcpu-breakdown.gp' % vcpu_nr, 'r') as f:
        lines = f.readlines()
    
    with open('%dvcpu-breakdown.gp' % vcpu_nr, 'w') as f:
        for line in lines:
            for num in range(len(h[test_type]), 0, -1):
                sign = "##%d" % num
                if sign in line:
                    cols = line.split()
                    val = get_val(df, h[test_type][num][0], h[test_type][num][1])
                    cols[2] = '"%.2f"' % val
                    line = ' '.join(cols) + '\n'
                    break
            f.write(line)

if __name__ == "__main__":
    arch = sys.argv[1]
    vcpu_nr = int(sys.argv[2])
    work(arch, vcpu_nr)
