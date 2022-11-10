import random

file0 = [r'C:\Users\datee\Documents\GitHub\LSDJAM-2022\prompt_gen\styles.txt']
file1 = [r'C:\Users\datee\Documents\GitHub\LSDJAM-2022\prompt_gen\adjectives.txt']       
file2 = [r'C:\Users\datee\Documents\GitHub\LSDJAM-2022\prompt_gen\surfaces.txt']
file3 = [r'C:\Users\datee\Documents\GitHub\LSDJAM-2022\prompt_gen\artists.txt']


for file in file0:
    with open(file) as f:
        styles=(random.choice(f.readlines()).strip())

for file in file1:
    with open(file) as f:
        adjectives=(random.choice(f.readlines()).strip())

for file in file2:
    with open(file) as f:
        surfaces=(random.choice(f.readlines()).strip())

for file in file3:
    with open(file) as f:
        artists=(random.choice(f.readlines()).strip())

#add {adjectives} if you want
prompt= f"A game texture of a {surfaces} by {artists}, {styles}"

print(prompt)
