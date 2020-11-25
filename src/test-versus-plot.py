import sys
import json
import matplotlib.pyplot as plt
import numpy as np

jsonp = sys.argv[1]
x_field = sys.argv[2]
y_field = sys.argv[3]

with open(jsonp, 'r') as f:
    ts = json.load(f)

for t in ts:
    fig, ax = plt.subplots(figsize=(20,20))
    ax.scatter(t['x'], t['y'])

    ax.set_title('{}: {} vs. {}'.format(t['test'], x_field, y_field))
    ax.set_xlabel(x_field)
    ax.set_ylabel(y_field)

    plt.tight_layout()
    plt.savefig('by-test-{}-{}-versus{}.pdf'.format(t['test'], x_field, y_field))
    plt.close(fig)
