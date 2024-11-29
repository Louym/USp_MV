import numpy as np
from tqdm import tqdm

#Transform function
def int2complement(n,bits=8):
    # Ensure n is within the range
    if n < -2**(bits-1) or n > 2**(bits-1)-1:
        raise ValueError("Input integer must be in the range!")
    # Handle negative numbers using two's complement
    if n < 0:
        n = (1 << bits) + n
    # Convert to binary string
    s='0'+str(bits)+'b'
    binary_string = format(n, s)
    return binary_string

def int2bin(n,bits=2):
    # Ensure n is within the range
    if n < 0 or n > 2**bits-1:
        raise ValueError("Input integer must be in the range!")
    # Convert to binary string
    s='0'+str(bits)+'b'
    binary_string = format(n, s)
    return binary_string



#parameters
PE_NUM=4
W_ROW=16
W_COL=8
A_COL=W_COL
BW_P=3
BW_Z=6
BW_W=8
# read the weight data
data=[]
with open('weight.txt') as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])

Rows=64
Columns=16
data=np.array(data)
data=data[0:64,0:16]


with open('weight_bin1.txt','w') as f:
    for i in tqdm(range(64)):
        for j in range(16):
            f.write(int2complement(data[i,j],bits=8))
            f.write('\n')

#To write the three vectors
fw=open("w1.txt","w")#8bits*4*(4*8)
fz=open("z1.txt","w")#3bits*4*(4*8)
fp=open("p1.txt","w")#6bits*4*(8+1)
for i in tqdm(range(round(Rows/W_ROW))):
    for j in range(round(Columns/W_COL)):
        tmp=data[i*W_ROW:(i+1)*W_ROW,j*W_COL:(j+1)*W_COL]
        # if(i==0 and j==1):
        #     print(tmp)
        for k in range(PE_NUM):
            tmp1=tmp[k::PE_NUM,:]
            fp.write('000000\n')
            p=0
            for n in range(W_COL):
                tmp2=tmp1[:,n]#each row
                p=p+np.count_nonzero(tmp2)
                fp.write(int2complement(p,7))
                fp.write('\n')
                z=0
                for m in range(round(W_ROW/PE_NUM)):
                    if tmp2[m]:
                        fw.write(int2complement(tmp2[m],8))
                        fw.write('\n')
                        fz.write(int2complement(z,3))
                        fz.write('\n')
                        z=0
                    else:
                        z=z+1
            for h in range(32-p):
                fw.write(int2complement(0))
                fw.write('\n')
                fz.write(int2complement(0,3))
                fz.write('\n')
fw.close()
fz.close()
fp.close()

act=[]
with open('activation_col.txt','r') as f:
    for line in f.readlines():
        act.append([int(x) for x in line.split()])
act=np.array(act)

act=act[0:16,0:3]


f=open('a1.txt','w')
for i in tqdm(range(16)):
    for j in range(3):
        f.write(int2complement(act[i,j],bits=8))
        f.write('\n')
f.close()

o=np.matmul(data,act)
f=open('o1.txt','w')
for i in tqdm(range(32)):
    for j in range(3):
        f.write(int2complement(np.clip(o[i,j]//256,-128,127),bits=8))
        f.write('\n')
f.close()
