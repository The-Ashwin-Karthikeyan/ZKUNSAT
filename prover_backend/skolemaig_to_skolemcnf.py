import sys
from array import array
from dataclasses import dataclass
from math import floor

dependencies = {}
indices = {}
num_ins = 0
num_outs = 0

@dataclass
class AIGERline:
    index: int;
    var : int;
    support : array;

    def print(self):
        if self.support:
            print("index: ", self.index, " var: ", self.var, " support: ", " ".join([str(i) for i in self.support]), " dep: ", " ".join([str(i) for i in dependencies[self.var]]))
        else:
            print("index: ", self.index, " var: ", self.var, " support: ", " dep: ", " ".join([str(i) for i in dependencies[self.var]]))


def read_aiger_line(line, index):
    var = int(line[0])/2
    indices[var] = index
    support = []
    sup_1 = floor(int(line[1])/2)
    sup_2 = floor(int(line[2])/2)

    dep = set(dependencies[(sup_1)])
    dep = dep.union(set(dependencies[(sup_2)]))
    dependencies[var] = dep
    if int(line[1])%2 == 0:
        support.append(indices[(sup_1)])
    else:
        if(indices[sup_1] != 0):
            support.append(-indices[(sup_1)])
        else:
            support.append("-0")
    if int(line[2])%2 == 0:
        support.append(indices[(sup_2)])
    else:
        if(indices[sup_2] != 0):
            support.append(-indices[(sup_2)])
        else:
            support.append("-0")
    return AIGERline(index, int(var), support)


def parse(skofile):
    aig = []
    cert = open(skofile, 'r')
    Lines = cert.readlines()
    counter = 1
    global num_ins
    global num_outs
    global indices
    global dependencies

    indices[0] = 0
    dependencies[0] = [0]

    for str in Lines:
        line = str.split(" ")
        if line[0] == "aag":
            num_ins = int(line[2])
            num_outs = int(line[4])
        elif counter <= num_ins:
            var = int(line[0])/2
            indices[var] = counter
            dependencies[var] = [int(var)]
            aig.append(AIGERline(counter, int(var), []))
            counter += 1
        elif counter <= (num_outs + num_ins):
            counter += 1
        else:
            #print(str)
            aig.append(read_aiger_line(line, counter-num_outs))
            counter += 1
    
    return aig


skofile = sys.argv[1]
final_skolem = parse(skofile)
for line in final_skolem:
    line.print()
