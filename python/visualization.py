from matplotlib import pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
# read the activation data
data=[]
with open('activation_col.txt') as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])
        # print(len(line.split()))
# print(len(data))
# print(data[0])
zero_num=sum([data[i].count(0) for i in range(len(data))])
print('The density of activation is {:.2%}'.format(1-zero_num/len(data)/len(data[0])))
A=np.array(data)
#draw heat map
plt.subplot(221)
plt.yticks(fontproperties = 'Times New Roman', size = 6)
plt.xticks(fontproperties = 'Times New Roman', size = 6)
data=pd.DataFrame(data)
plot=sns.heatmap(data)
plt.xlabel("column",size=8)
plt.ylabel("row",size=8,rotation=90)
plt.title("The value of activation",size=10)
plt.plot()
plt.subplot(222)
plt.yticks(fontproperties = 'Times New Roman', size = 6)
plt.xticks(fontproperties = 'Times New Roman', size = 6)
data0=pd.DataFrame(np.where(np.array(data)>0,1,0))
plot=sns.heatmap(data0)
plt.xlabel("column",size=8)
plt.ylabel("row",size=8,rotation=90)
plt.title("The binary value of activation",size=10)
plt.plot()




# read the weight data
data=[]
with open('weight.txt') as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])
        # print(len(line.split()))
# print(len(data))
# print(data[0])
zero_num=sum([data[i].count(0) for i in range(len(data))])
print('The density of weight is {:.2%}'.format(1-zero_num/len(data)/len(data[0])))
W=np.array(data)
#draw heat map
plt.subplot(223)
plt.yticks(fontproperties = 'Times New Roman', size = 6)
plt.xticks(fontproperties = 'Times New Roman', size = 6)
data=pd.DataFrame(data)
plot=sns.heatmap(data)
plt.xlabel("column",size=8)
plt.ylabel("row",size=8,rotation=90)
plt.title("The value of weight",size=10)
plt.plot()
plt.subplot(224)
plt.yticks(fontproperties = 'Times New Roman', size = 6)
plt.xticks(fontproperties = 'Times New Roman', size = 6)
data0=pd.DataFrame(np.where(np.array(data)>0,1,0))
plot=sns.heatmap(data0)
plt.xlabel("column",size=8)
plt.ylabel("row",size=8,rotation=90)
plt.title("The binary value of weight",size=10)

plt.show()



# O=np.matmul(W,A)


# read the weight data
data=[]
with open('output_col.txt') as f:
    for line in f.readlines():
        data.append([int(x) for x in line.split()])
        # print(len(line.split()))
# print(len(data))
# print(data[0])
zero_num=sum([data[i].count(0) for i in range(len(data))])
print('The density of output is {:.2%}'.format(1-zero_num/len(data)/len(data[0])))
O0=np.array(data)
# print(np.sum(O0!=O))
# print(A.shape)
# print(W.shape)
# print(O.shape)