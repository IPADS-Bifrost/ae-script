import numpy as np
import os


class MemtierTestSuite1:
    machines = ["intel"]
    #mode_opt = ["vanilla-2", "vp-2"]
    baselines = {
        "intel": ["vanilla-0"],
        "amd": ["vanilla-0"]
    }
    testers = {
        "intel""vanilla-0": ["vanilla-1", "numatx-1", "vg-1", "ng-1"],
        "amd""vanilla-0": ["vanilla-2"]
    }
    breakdown_types = ["bd-0", "bd-1", "nbd-1", "vgbd-1", "ngbd-1"]
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
               "bd-1":"CVM+PI",
               "bd-0":"Vanilla",
               "vanilla-2":"CVM",
               "vo-2":"CVM+RIF",
               "vgbd-1":"+PRPR",
               "vgo-2":"+PRPR",
               "ngbd-1":"Bifrost",
               "nbd-1":"+ZC",
               "no-2":"+ZC",
               "numatx-1":"+ZC",
               "ngo-1":"Bifrost",
               "ngo-2":"Bifrost",
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
    tls_opt= ['rx', 'tx']
    breakdown=['VM-Exit', 'SWIOTLB', 'Kernel-Pre-NS-Processing', 'App-Workload']
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
    def cal(cls, machine, mode, type, test_type, log=False, idx=0):
        data = []
        if test_type == "vmexit-latency":
            test_type = "memtier"
        file_name = "{}-{}-{}-{}.stat" \
        .format(machine, test_type, type, mode) 
        path = "../../../data/" + ('' if test_type == 'redis' else '') + file_name
        try:
            with open(path, 'r') as f:
                for line in f:
                    if float(line.split()[idx]) > 1:
                        data.append(float(line.split()[idx]))
                if test_type == 'tls':
                    insts = 4
                    data1 = []
                    tmp = 0.0
                    #print(type(data))
                    for i in range(len(data)):
                        tmp = tmp + data[i] * 8 / 1000
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
        folder = "res"
        output = folder + '/' + test_type + ".res"
        os.system("mkdir -p {}".format(folder))
        f=open(output, 'w')
        f.write('')
        f.close()
        
        cls.myprint("Title", output, '    ')
        for type in cls.breakdown:
            cls.myprint('%s' % type, output, '    ')
        cls.myprint('', output)

        data, std = [], []
        # print(machine, baseline)
        for machine in cls.breakdown_types:
            cls.myprint('%s' % cls.titles[machine], output, '    ')
            vmexit=0.0
            swiotlb=0.0
            pre_ns=0.0
            app=0.0

            file_name = "intel-memtier-{}-breakdown-guest.stat".format(machine)
            path = "../../../data/" + ('' if test_type == 'redis' else '') + file_name
            total_guest=0.0
            netrx=0.0
            tcp_send=0.0
            
            try:
                with open(path, 'r') as f:
                    state = ''
                    for line in f:
                        if state == '':
                            if line == 'Total\n':
                                state='Total'
                            elif line == 'netrx\n':
                                state='netrx'
                            elif line == 'tcp_send\n':
                                state='tcp_send'
                            elif line == 'swiotlb_tx\n':
                                state='swiotlb'
                            elif line == 'swiotlb_rx\n':
                                state='swiotlb'
                            elif line == 'swiotlb_memcpy\n':
                                state='swiotlb'
                            elif line == 'swiotlb_find\n':
                                state='swiotlb'
                            elif line == 'swiotlb_release\n':
                                state='swiotlb'
                        elif state == 'Total':
                            total_guest=float(line.split()[0])
                            state=''
                            pass
                        elif state == 'netrx':
                            if line == 'end\n':
                                state=''
                            else:
                                netrx+=float(line.split()[1])
                            pass
                        elif state == 'tcp_send': # sum of 4 VCPUs
                            if line == 'end\n':
                                state=''
                            else:
                                tcp_send+=float(line.split()[1])/4
                            pass
                        elif state == 'swiotlb':
                            if line == 'end\n':
                                state=''
                            else:
                                swiotlb+=float(line.split()[1])
                            pass
            
            except EnvironmentError:
                print("oops, can't find {}".format(path))

            file_name = "intel-memtier-{}-breakdown-host.stat".format(machine)
            path = "../../../data/" + ('' if test_type == 'redis' else '') + file_name
            total_host=0.0
            cycles=0.0
            
            try:
                with open(path, 'r') as f:
                    state = ''
                    for line in f:
                        if state == '':
                            if line == 'Total\n':
                                state='Total'
                            elif line == 'vmexit\n':
                                state='vmexit'
                        elif state == 'Total':
                            total_host=float(line.split()[0])
                            state=''
                            pass
                        elif state == 'vmexit':
                            if line == 'end\n':
                                state=''
                            else:
                                cycles+=float(line.split()[2])
            
            except EnvironmentError:
                print("oops, can't find {}".format(path))

            vmexit=cycles/4/total_host
            swiotlb=swiotlb/4/total_guest
            pre_ns=(netrx/4+tcp_send)/total_guest-swiotlb
            app=1.0-pre_ns-vmexit-swiotlb
            
            cls.myprint(vmexit*100, output, '    ')
            cls.myprint(swiotlb*100, output, '    ')
            cls.myprint(pre_ns*100, output, '    ')
            cls.myprint(app*100, output, '    ')
            
            cls.myprint('', output)


def main():
    MemtierTestSuite1.draw('4vcpu')
    # MemtierTestSuite1.draw('tls', relative=False)
    # MemtierTestSuite1.draw('memtier')
    # MemtierTestSuite1.draw('redis')
    # MemtierTestSuite1.draw('nginx')
    #MemtierTestSuite1.draw('netperf-tx')
    #MemtierTestSuite1.draw('netperf-rx')
    #MemtierTestSuite1.draw('netperf-tx', relative=False)

    
if __name__ == '__main__':
    main()
