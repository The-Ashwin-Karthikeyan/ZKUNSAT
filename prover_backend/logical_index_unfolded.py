import sys
from array import array
from dataclasses import dataclass
from math import floor

logical_sort = {}

@dataclass
class ResolutionTuple:
    index: int
    clause : set
    support : array
    pivot: array
    num_lits: int
    logical_index : int

    def print(self, deg):
        print("lindex: ", self.logical_index, "deg: ", deg, "index: ", self.index, " clause: ", " ".join([str(i) for i in self.clause]), " support: ", " ".join([str(i) for i in self.support]), " pivot: ", " ".join([str(i) for i in self.pivot]), "end: ", str(0))

def parse(str):
    #ResTuple = resolution()
    global logical_sort
    line_tmp = str.split(" ")
    line = []
    for e in line_tmp:
        if e != '':
            line.append(e)
    index = int(line[1])
    clause = set();
    num_lits = 0
    pivots = []
    support = []
    i = 3
    while (line[i].strip(" ") != 'support:'):
        clause.add(int(line[i]))
        num_lits = num_lits + 1
        i = i + 1
    i = i + 1
    while (line[i].strip(" ") != 'pivot:'):
        support.append(int(line[i]))
        i = i + 1
    i = i + 1
    while (line[i].strip(" ") != 'end:'):
        pivots.append(int(line[i]))
        i = i + 1
    if len(clause) == 0:
        clause.add(0)
    res = ResolutionTuple(index, clause, support, pivots, num_lits, -1)
    if (num_lits in logical_sort.keys()):
        logical_sort[num_lits].append(res)
    else:
        logical_sort[num_lits] = [res]
    return res

def add_logical_id(prooffile):
    resolution_list = []
    proof = open(prooffile, 'r')
    Lines = proof.readlines()

    for line in Lines:
        str = line.split(" ")
        if str[0] == "DEGREE:":
            degree = int(str[1])
            break
        res = parse(line)
        resolution_list.append(res)
    return resolution_list, degree

#This code takes the proof file and the number of degrees we want to have and outputs the 
#sorted proof file as required for the multiple-degree-ZKUNSAT.
prooffile = sys.argv[1]
k = int(sys.argv[2])
resolution_list, degree = add_logical_id(prooffile)

print("Number of lines in this file: " + str(len(resolution_list)))
print("Original Degree: " + str(degree))

batch_size = len(resolution_list)/k
sorted_degs = sorted(logical_sort.keys()) #This is a list of all the degrees sorted
sorted_clauses = []
k_degs = []
k_sizes = []

count = 0

for i in sorted_degs:
    for res in logical_sort[i]:
        sorted_clauses.append(res)
        res.logical_index = count
        count += 1
        

for i in range(1, k+1):
    print("ClauseRAM " + str(i) + " deg: ", sorted_clauses[floor(batch_size*(i))-1].num_lits + 1)
    k_degs.append(sorted_clauses[floor(batch_size*(i))-1].num_lits + 1)
    print("ClauseRAM " + str(i) + " num_elements: ", floor(batch_size*(i))-floor(batch_size*(i-1)))
    k_sizes.append(floor(batch_size*(i))-floor(batch_size*(i-1)))

print('\n\n')

original_stdout = sys.stdout
f = open(prooffile+".logical_unfold_"+str(k), "w")
sys.stdout = f
count = 0
count2 = 0
for i in sorted_degs:
    for r in logical_sort[i]:
        count += 1
        r.print(k_degs[count2])
        if (count == k_sizes[count2]):
            count2 += 1
            count = 0
print("DEGREE: "+ str(degree))
f.close()
sys.stdout = original_stdout
index = 0

