import sys
import json
import matplotlib.pyplot as plt
import numpy as np

jsonp = sys.argv[1]
field = sys.argv[2]

with open(jsonp, 'r') as f:
    data = json.load(f)

fig, ax = plt.subplots()
x = np.arange(len(data))
ax.bar(x, data)
ax.set_xlabel('seed')
ax.set_ylabel('sum({})'.format(field))

ax.set_xticks(x)
ax.set_xticklabels(range(1, len(data) + 1))

plt.tight_layout()
plt.savefig('by-seed-{}-bar.pdf'.format(field))
