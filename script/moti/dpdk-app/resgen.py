import numpy as np
import os


class MemtierTestSuite1:
    machines = ["amd", "intel"]
    #mode_opt = ["vanilla-2", "vp-2"]
    baselines = {
        "intel": ["vanilla-0"],
        "amd": ["vanilla-0"]
    }
    testers = {
        "intel""vanilla-0": ["vanilla-1"],
        "amd""vanilla-0": ["vanilla-2"]
    }

    mode_opt_vmexit = ["swiotlb", "swiotlb-vmexit-2000", "swiotlb-vmexit-4000", "swiotlb-vmexit-6000"]

    titles = { "swiotlb":"swiotlb",
               "vanilla":'no-swiotlb',
               'dma-mapping':'swiotlb-lockopt',
               'percpu':'percpu',
               "swiotlb-vmexit-2000":'2000',
               "swiotlb-vmexit-4000":'4000',
               "swiotlb-vmexit-6000":'6000',
               "swiotlb-sev":"sev",
               "swiotlb-sev-es":"sev-es",
               "swiotlb-sev-es-snp":"sev-snp",
               "vanilla-1":"CVM+PI",
               "vanilla-2":"CVM",
               "vp-2":"+optIRQ"
    }
    #output="res/overhead.res"

    # cpu_nr, threads, connection
    concurrency_opt = [[1, 4, 32], [4, 8, 64]]
    # data_sz_opt = [32, 8192, 16384, 32768, 65536, 131072, 262144, 524288]
    data_sz_opt = {
        #"memtier": [1, 32, 131072, 262144],
        "memtier": [32768, 65536, 131072, 262144],
        "redis": [32768, 65536, 131072, 262144],
        "nginx": ["32kb", "64kb", "128kb", "256kb"],
        "netperf-rx": [16384, 65536, 131072],
        "netperf-tx": [16384, 65536, 131072],
        "vmexit-latency": [1, 32, 131072, 262144]
    }
    name = {
        8192:"8K",
        16384:"16K",
        32768:"32K",
        65536:"64K",
        131072:"128K",
        262144:"256K",
        524288:"512K",
        "1kb":"1K",
        "2kb":"2K",
        "4kb":"4K",
        "8kb":"8K",
        "16kb":"16K",
        "32kb":"32K",
        "64kb":"64K",
        "128kb":"128K",
        "256kb":"256K",
        "512kb":"512K",
        "1mb":"1M"
    }
    netperf_inst = {
        1:4,
        4:32
    }

    @classmethod
    def cal(cls, machine, mode, cpu_nr, threads, conn, data_sz, test_type, log=False, idx=0):
        data = []
        if test_type == "vmexit-latency":
            test_type = "memtier"
        file_name = "{}-{}-{}-{}vcpu-{}{}.stat" \
        .format(machine, test_type, mode, cpu_nr, "0.1-" if test_type != "nginx" else "", data_sz) \
        if test_type != 'netperf-rx' and test_type != 'netperf-tx' else \
        "{}-{}vcpu-{}-{}.stat" \
        .format(test_type, cpu_nr, mode, data_sz)
        path = "../../data/" + ('' if test_type == 'redis' else '') + file_name
        try:
            with open(path, 'r') as f:
                for line in f:
                    if float(line.split()[idx]) > 1:
                        data.append(float(line.split()[idx]))
                if test_type == 'netperf-rx' or test_type == 'netperf-tx':
                    insts = cls.netperf_inst[cpu_nr]
                    data1 = []
                    tmp = 0.0
                    #print(type(data))
                    for i in range(len(data)):
                        tmp = tmp + data[i]
                        if i % insts == insts - 1:
                            data1.append(tmp)
                            print(tmp)
                            tmp=0.0
                    data=data1
                    print(np.mean(data))
                if log:
                    print(file_name + " " + "[mean] " + \
                          str(round(np.mean(data), 2)) + " [wave] " + \
                          str(round(np.std(data) * 100 / np.mean(data), 2)) \
                          + "%" + " [tot] " + str(len(data)))
        except EnvironmentError:
            print("oops, can't find {}".format(path))
            return 0, 0, 0
        return np.mean(data), np.std(data), len(data)

    @classmethod
    def myprint(cls, s, output, end='\n'):
        f = open(output, "a")
        f.write(str(s))
        f.write(end)
        f.close()
        #print(s, end=end)

    @classmethod
    def draw(cls, test_type, relative=True):
        folder = "res" if relative else 'eval'
        output = folder + '/' + test_type + ".res"
        os.system("mkdir -p {}".format(folder))
        f=open(output, 'w')
        f.write('')
        f.close()
        
        cls.myprint("Title", output, '    ')
        if relative is False:
            cls.myprint('vanilla', output, '    ')
        for machine in cls.machines:
            for baseline in cls.baselines[machine]:
                modes=cls.mode_opt_vmexit if test_type == 'vmexit-latency' else cls.testers[machine + baseline]
                for mode in modes:
                    if mode == "swiotlb" and test_type == "vmexit-latency":
                        cls.myprint('0', output, '    ')
                    else:
                        cls.myprint(cls.titles[mode] if mode in cls.titles else mode, output, '    ')
        cls.myprint('', output)
        
        for concurrency in cls.concurrency_opt:
            for data_sz in cls.data_sz_opt[test_type]:
                cls.myprint('%sB' % (cls.name[data_sz] if data_sz in cls.name else data_sz), output, '    ')
                fig_title = "{}/{}-{}vcpu-{}-{}-{}.res".\
                        format(folder, test_type, concurrency[0], concurrency[1], concurrency[2], data_sz)
                data, std = [], []
                # print(machine, baseline)
                for machine in cls.machines:
                    for baseline in cls.baselines[machine]:
                        modes=cls.mode_opt_vmexit if test_type == 'vmexit-latency' else cls.testers[machine + baseline]
                        d, s, l = cls.cal(machine, baseline, concurrency[0], concurrency[1], concurrency[2], data_sz, test_type)
                        b=d
                        if relative is False:
                            cls.myprint(d, output, '    ')
                        # vanilla=0
                        for mode in modes:
                            d, s, l = cls.cal(machine, mode, concurrency[0], concurrency[1], concurrency[2], data_sz, test_type)
                            data.append(d)
                            std.append(s)
                            # if mode == 'vanilla':
                            #     vanilla=d
                            if relative:
                                cls.myprint((b-d)/b*100, output, '    ')
                            else:
                                cls.myprint(d, output, '    ')
                                #print((b-d)/b)
                            # if mode == 'swiotlb':
                            #     print((vanilla-d)/vanilla)
                cls.myprint('', output)


def main():
    MemtierTestSuite1.draw('memtier')
    MemtierTestSuite1.draw('redis')
    MemtierTestSuite1.draw('nginx')
    #MemtierTestSuite1.draw('netperf-tx')
    #MemtierTestSuite1.draw('netperf-rx')
    #MemtierTestSuite1.draw('netperf-tx', relative=False)

    
if __name__ == '__main__':
    main()