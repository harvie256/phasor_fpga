"""
Created on Wed Jun 17 10:18:06 2020

@author: derryn harvie

Plot the output of Pulseview ADC annotation

"""

import numpy as np
import matplotlib.pyplot as plt

path = r'C:\Users\derry\Documents\ch0.txt'
sample_freq = 16000


with open(path, 'r') as input_file:
    input_lines = input_file.readlines()

values = [float(line[line.rfind(':')+1:].strip()) for line in input_lines]

p = 1/sample_freq
t = np.linspace(0, len(values)*p, len(values), endpoint=False)


plt.plot(t, values)
plt.ylim(-(2**23), (2**23-1)) # Limits of 24 bit integer which the ADC uses
plt.show()
