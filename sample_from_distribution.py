import pickle
import sys

DIST_FILE = "profile_distribution.pickle"
profiles = pickle.load(open(DIST_FILE, "rb"))

# Parse Args
_, operator, country, rat, quality = sys.argv

# Test profile exists
try:
    _ = profiles.loc[(operator,country,rat, quality, "no_roaming")]
except:
    print("error")
    exit(1)
    
# Sample
while True:
    down, up, rtt = profiles.loc[(operator,country,rat, quality, "no_roaming")].kde.resample(1).transpose().squeeze()
    if down > 0 and up > 0 and rtt > 0:
        break

# Output
print(down*1000, up*1000, rtt)

