#include <iostream>
#include "clause.h"
#include "clauseRAM.h"
#include "commons.h"

int port, party;
const int threads = 8;
int DEGREE = 4;
block *mac, *data;
uint64_t data_mac_pointer;
SVoleF2k <BoolIO<NetIO>> *svole;
F2kOSTriple <BoolIO<NetIO>> *ostriple;
uint64_t constant;
BoolIO <NetIO> *io;

int main(int argc, char **argv) {
    cout << "---- begin ----" << endl;
    constant = 1UL << (VAL_SZ - 2);
    parse_party_and_port(argv, &party, &port);
    BoolIO <NetIO> *ios[threads];
    for (int i = 0; i < threads; ++i)
        ios[i] = new BoolIO<NetIO>(new NetIO(party == ALICE ? nullptr : argv[3], port + i), party == ALICE);       
    char *skolemfile = argv[4];    
    char *prooffile = argv[5];

    setup_zk_bool < BoolIO < NetIO >> (ios, threads, party);
    ZKBoolCircExec <BoolIO<NetIO>> *exec = (ZKBoolCircExec < BoolIO < NetIO >> *)(CircuitExecution::circ_exec);
    io = exec->ostriple->io;

    ostriple = new F2kOSTriple <BoolIO<NetIO>>(party, exec->ostriple->threads, exec->ostriple->ios,
                                               exec->ostriple->ferret, exec->ostriple->pool);
    svole = ostriple->svole;

    data_mac_pointer = 0;
    uint64_t test_n = svole->param.n;;
    uint64_t mem_need = svole->byte_memory_need_inplace(test_n);

    data = new block[svole->param.n];
    mac = new block[svole->param.n];
    svole->extend_inplace(data, mac, svole->param.n);
    cout << endl << "----set up----" << endl << endl;

    GF2X P;
//    random(P, 128);
    SetCoeff(P, 128, 1);
    SetCoeff(P, 7, 1);
    SetCoeff(P, 2, 1);
    SetCoeff(P, 1, 1);
    SetCoeff(P, 0, 1);
    GF2E::init(P);


    int ncls = 0, nres = 0;
    int skolem_deg = 0;

    vector <CLS> clauses;
    vector <SPT> supports;
    vector <SPT> pivots;

    vector <int64_t> dependencies;
    vector <CLS> vars;
    vector <SPT> skolem_supports;
    int num_ands = 0, num_ins = 0, num_outs = 0, max_var = 0;

    if (party == ALICE) {
        readskolem(string(skolemfile), vars, dependencies, skolem_supports, num_ands, num_ins, num_outs, max_var);
        cout << string(skolemfile) << endl;
        io->send_data(&num_ins, 4);
        io->send_data(&num_outs, 4);
        io->send_data(&num_ands, 4);
    }
    if (party == BOB) {
        io->recv_data(&num_ins, 4);
        io->recv_data(&num_outs, 4);
        io->recv_data(&num_ands, 4);
        dependencies = vector<int64_t>(num_ins+num_ands);
    }
    cout << "----Skolem Function----" << endl;
    cout << "number of input variables: " << num_ins << endl;
    cout << "number of output variables: " << num_outs << endl;
    cout << "number of and gates: " << num_ands << endl << endl;

    if (party == ALICE) {
        readproof(string(prooffile), DEGREE, clauses, supports, pivots, ncls, nres);
        cout << string(prooffile) << endl;
        io->send_data(&nres, 4);
        io->send_data(&ncls, 4);
        io->send_data(&DEGREE, 4);

    }

    if (party == BOB) {
        io->recv_data(&nres, 4);
        io->recv_data(&ncls, 4);
        io->recv_data(&DEGREE, 4);

        clauses = vector<CLS>(ncls);
        supports = vector<SPT>(ncls);
        pivots = vector < vector < int64_t >> (ncls);
    }
    cout << "----input proof----" << endl;
    cout << "number of resolution steps: " << nres << endl;
    cout << "total number of clauses: " << ncls << endl;
    cout << "DEGREE for ZKUNSAT: " << DEGREE << endl << endl;
    cout << "----end set up----" << endl << endl;
    cout << "----loading input----" << endl;
    //if ( ncls > 524287) return 0; 

    double cost_input = 0;
    double cost_resolve = 0;
    double cost_access = 0 ;

/*
 * encode the formula and resolution proof
 * */
    auto timer_0 = chrono::high_resolution_clock::now();
    vector<clause> raw_formula;

    vector<Integer> pvt_deps;
    vector<clause> variables;
    for (int i = 0; i < num_ands+num_ins; i++) {
        pvt_deps.push_back(Integer(INDEX_SZ, dependencies[i], ALICE));
        vector<uint64_t> variable;
        for (int64_t lit: vars[i]){
            variable.push_back(wrap(lit));
        }
        padding(variable, 3);

    }


    float delta = 0 ;


    for (int i = 0; i < ncls; i++) {
        delta = delta + 1;
        if ((delta / ncls) > 0.1){
            float  progress = (float(i) / ncls);
            delta = 0;
            int barWidth = 70;
            std::cout << "[";
            int pos = barWidth * progress;
            for (int i = 0; i < barWidth; ++i) {
                if (i < pos) std::cout << "=";
                else if (i == pos) std::cout << ">";
                else std::cout << " ";
            }
            std::cout << "] " << int(progress * 100.0) << " %\r";
            cout << endl;
        }


        vector <uint64_t> literals;
        for (int64_t lit: clauses[i]) {
            literals.push_back((wrap(lit)));
        }
        padding(literals, DEGREE);
        clause c(literals, DEGREE);
        raw_formula.push_back(c);
    }
    clauseRAM<BoolIO<NetIO>>* formula = new clauseRAM<BoolIO<NetIO>>(party, INDEX_SZ, DEGREE);
    formula->init(raw_formula);
    cout <<"finish  input!\n";
    auto timer_1 = chrono::high_resolution_clock::now();
    cost_input = chrono::duration<double>(timer_1 - timer_0).count();

    delta = 0;


    for (int64_t i = ncls - nres; i < ncls; i++) {
	    delta = delta + 1;
        if ((delta / nres) > 0.1){
            float  progress = (float(i) / ncls);
            delta = 0;
            int barWidth = 70;
            std::cout << "[";
            int pos = barWidth * progress;
            for (int i = 0; i < barWidth; ++i) {
                if (i < pos) std::cout << "=";
                else if (i == pos) std::cout << ">";
                else std::cout << " ";
            }
            std::cout << "] " << int(progress * 100.0) << " %\r";
            cout << endl;
        }

        int64_t chain_length = 0L;
        vector<uint64_t> pvt;
        vector<Integer> chain;

        if (party == ALICE) {
            chain_length = supports[i].size();
            io->send_data(&chain_length, 8);
        }else{
            io->recv_data(&chain_length, 8);
        }

        SPT s = supports[i];
        PVT p = pivots[i];


        if (party == BOB) {
            for (int j = s.size(); j < chain_length; j++) {
                s.push_back(0L);
            }
            for (int j = p.size(); j < chain_length - 1; j++) {
                p.push_back(0L);
            }
        }


        assert(s.size() == p.size() +1);
        for (uint64_t index: s) {
            chain.push_back(Integer(INDEX_SZ, index, ALICE));
        }

        pvt.push_back(0UL);
        for(uint64_t pp: p){
            pvt.push_back(pp);
        }

        bool last_clause = (i == (ncls - 1));
        auto cost = check_chain(chain, pvt, i, formula, last_clause);
        cost_resolve = cost_resolve + cost.second;
        cost_access = cost_access + cost.first;
    }

    check_zero_MAC(zero_block, 1);
    auto timer_4 = chrono::high_resolution_clock::now();

    formula->check();

    auto timer_5 = chrono::high_resolution_clock::now();
    cost_access = cost_access +  chrono::duration<double>(timer_5 - timer_4).count();
    cout << "a "<< cost_access << " " << "r " << cost_resolve << " "<< "i "<< cost_input << " t "<< cost_access + cost_resolve + cost_input << endl;


    bool cheat = finalize_zk_bool<BoolIO<NetIO>>();
    if(cheat)error("cheat!\n");

    uint64_t  counter = 0;

    for(int i = 0; i < threads; ++i) {
        counter = ios[i]->counter + counter;
        delete ios[i]->io;
        delete ios[i];
    }
    cout << "communication:" << counter << endl;
    cout << "----end----" << endl;
    return 0;

}
