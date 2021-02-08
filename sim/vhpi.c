#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
/* Not technically required, but needed on some UNIX distributions */
#include <sys/types.h>
#include <sys/stat.h>

int read_fd=-1;
int write_fd=-1;
void send_byte(int data) {
	if(write_fd==-1){
		write_fd=open("pipe.out", O_WRONLY|O_NONBLOCK);
	}
	char c=(int)data;
//printf("send_byte(%d)\n",data);
	write(write_fd,&c,1);
}



int receive_byte() {
	if(read_fd==-1){
		printf("UART: ready to receive\n");
		read_fd=open("pipe.in", O_RDONLY|O_NONBLOCK);
	}
//int flags = fcntl(read_fd, F_GETFL, 0);

//	fcntl(read_fd, F_SETFL, flags | O_NONBLOCK);

	char x=0;
	int n=read(read_fd,&x,1);
//	printf("read: %d %d\n",x,n);
	if(n!=1){
	return 0x100;
	}else{
	return x&0xFF;
	}
/*	counter2++;
if(counter2>100){
	counter++;
	switch(counter){
	case 0:return 0x011;
	case 1:
	case 2:
	case 3:
	case 4:return 0x000;
	default:return 0x100;
	}
	}*/
//return 0x33;
}
