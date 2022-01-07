#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <bits/stdc++.h>

using namespace std;

int main(int argc, char *argv[]) {
	ifstream ifile;
	ofstream ofile, ofile_1;
	string output;
	char temp;
	stringstream ss;
	int input_len = 0, str_len = 0, flag = 0, count = 0;
	
	ifile.open(argv[1]);
	ofile.open(argv[2]);
	ofile_1.open(argv[3]);

	ofile_1 << "0 ";
	int input;
	while(ifile >> input) {
		/*
		if(flag == 0) {
			flag = 1;
			continue;
		}
		*/
		count += input;
		ss << std::hex << count;
		output = ss.str();
		ofile_1 << output << " ";
		ss.str("");
		ss.clear();

		for(int i = 0; i < input; ++i) {
			int temp;
			ifile >> temp;
		        ss << std::hex << temp;
	       		output = ss.str();
	 		ofile << output << endl;
			ss.str("");
			ss.clear();		
		}
		flag = 0;
	}

	ifile.close();
	ofile.close();
	ofile_1.close();
	
	return 0;
}
