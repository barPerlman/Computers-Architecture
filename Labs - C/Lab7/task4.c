int digit_cnt(char * number) {
	int i = 0;
	int counter = 0;
	while (number[i] != '\0') {
		if (number[i] >= '0' && number[i] <= '9') {
			counter++;
		}
		i++;
	}
	return counter;
}

int main(int argc, char **argv){
	if (argc == 2) {
		digit_cnt(argv[1]);
	}
	return 0;
}
