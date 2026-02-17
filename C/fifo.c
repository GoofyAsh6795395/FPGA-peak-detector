//
//  fifo.c
//  C
//
//  Created by 朱欣瑞 on 2026/02/14.
//

#include <stdio.h>
#include <string.h>
#define depth 8

void print(int* queue){
    for(int offset = 0; offset < depth; offset++){
        int value = *(queue + offset);
        printf("%d ", value);
    }
    printf("\n");
}

void push(int input, int* queue, int* tail){
    (*(queue + (*tail))) = input;
    (*tail) = ((*tail) + 1) % depth;
}

int pop(int* queue, int* head, int* tail){
    int output = 0;
    output = (*(queue + (*head)));
    (*(queue + (*head))) = 0;
    (*head) = ((*head) + 1) % depth;
    return output;
}

int main(int argc, const char* argv[]){
    int queue[depth];
    int head = 0, tail = 0;
    int counter = 0;
    for(int index = 0; index < depth; index ++){
        queue[index] = 0;
    }
    char command[128];
    while(fgets(command, sizeof(command), stdin) != NULL){
        command[strcspn(command, "\n")] = '\0';
        if(strcmp(command, "read") == 0){
            int output = 0;
            if(counter > 0){
                output = pop(queue, &head, &tail);
                printf("Output: %d\n", output);
                counter -= 1;
            }else{
                printf("Access Deined\n");
            }
            print(queue);
        }else{
            int input = 0;
            if(sscanf(command, "write %d", &input) == 1){
                if(counter < depth){
                    counter += 1;
                    push(input, queue, &tail);
                }else{
                    printf("Access Deined\n");
                }
                print(queue);
            }
        }
    }
    return 0;
}
