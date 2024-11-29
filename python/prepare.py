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
# read the weight data
data=[]
with open('weight.txt') as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])
Rows=len(data)
Columns=len(data[0])
data=np.array(data)

p_max=0
#To write the three vectors
fw=open("w_bin.txt","w")#8bits*4*(4*8)
fz=open("z_bin.txt","w")#3bits*4*(4*8)
fp=open("p_bin.txt","w")#6bits*4*(8+1)
for i in tqdm(range(round(Rows/W_ROW))):
    for j in range(round(Columns/W_COL)):
        tmp=data[i*W_ROW:(i+1)*W_ROW,j*W_COL:(j+1)*W_COL]
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
                if(p>p_max):
                    p_max=p
                fw.write(int2complement(0))
                fw.write('\n')
                fz.write(int2complement(0,3))
                fz.write('\n')
fw.close()
fz.close()
fp.close()
print('The max nonzero length of w and z is {}'.format(p_max))

data=[]
with open("output_col.txt","r") as f:
    for line in f.readlines():
        data.append([int(x)//256 for x in line.split()])
with open("output_col_bin.txt","w") as f:
    for x in tqdm(data):
        for y in x:
            if y>127:
                y=127
            if y<-128:
                y=-128
            f.write(int2complement(y))
            f.write('\n')
data=[]
with open("activation_col.txt","r") as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])
with open("activation_col_bin.txt","w") as f:
    for x in tqdm(data):
        for y in x:
            if y>127:
                y=127
            if y<-128:
                y=-128
            f.write(int2complement(y))
            f.write('\n')
data=[]
with open("weight.txt","r") as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])
with open("weight_bin.txt","w") as f:
    for x in tqdm(data):
        for y in x:
            if y>127:
                y=127
            if y<-128:
                y=-128
            f.write(int2complement(y))
            f.write('\n')


