import numpy as np
from tqdm import tqdm
W_Sparsity=0.5
A_Sparsity=0.5
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

# generate the weight data
Rows=128
Columns=32
data=np.random.randint(-128, 128, [Rows,Columns])
for i in tqdm(range(Rows)):
        for j in range(Columns):
            while(data[i][j]==0):#make sure all are nonzero
                data[i][j]=np.random.randint(-128, 128)
            x=np.random.uniform(0,1)
            if(x<W_Sparsity):
                data[i][j]=0


with open('diverse_sparsity/weight_d.txt','w') as f:
    for i in tqdm(range(Rows)):
        for j in range(Columns):
            f.write(int2complement(data[i,j],bits=8))
            f.write('\n')

#To write the three vectors
fw=open("diverse_sparsity/wd.txt","w")#8bits*4*(4*8)
fz=open("diverse_sparsity/zd.txt","w")#3bits*4*(4*8)
fp=open("diverse_sparsity/pd.txt","w")#6bits*4*(8+1)
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

act=np.random.randint(-128, 128, [Columns,Columns])
for i in tqdm(range(Columns)):
        for j in range(Columns):
            while(act[i][j]==0):#make sure all are nonzero
                act[i][j]=np.random.randint(-128, 128)
            x=np.random.uniform(0,1)
            if(x<A_Sparsity):
                act[i][j]=0



f=open('diverse_sparsity/ad.txt','w')
for i in tqdm(range(32)):
    for j in range(32):
        f.write(int2complement(act[i,j],bits=8))
        f.write('\n')
f.close()

o=np.matmul(data,act)
f=open('diverse_sparsity/od.txt','w')
for i in tqdm(range(128)):
    for j in range(32):
        f.write(int2complement(np.clip(o[i,j]//256,-128,127),bits=8))
        f.write('\n')
f.close()
