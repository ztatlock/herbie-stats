import sys
import json
import matplotlib.pyplot as plt
import numpy as np

jsonp = sys.argv[1]
field = sys.argv[2]

with open(jsonp, 'r') as f:
    data = json.load(f)

fig, ax = plt.subplots()
ax.violinplot(data)
ax.set_xlabel('{} seeds'.format(len(data)))
ax.set_ylabel('sum({})'.format(field))

plt.tight_layout()
plt.savefig('by-seed-{}-violin.pdf'.format(field))
