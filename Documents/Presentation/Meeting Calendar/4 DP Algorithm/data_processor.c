//
//  maximum-adjacent.c
//  Signal_Processing
//
//  Created by 朱欣瑞 on 2025/11/27.
//

#include <stdio.h>
#define length 7


int main(int argc, const char* argv[]){
    int buffer[length] = {0, 0, 0, 0, 0, 0, 0};
    int result[length] = {0, 0, 0, 0, 0, 0, 0};
    int max_value = 0;
    /*Max_value must be initialised to be the first valid data,
     The assignment here is for the purpose of cheating the compiler*/
    int max_index;
    int amount;
    int centre_valid = 0, max_found = 0;
    scanf("%d", &amount);
    
    int iterator;
    
    for(iterator = 1; iterator <= amount + 3; iterator ++){
        int data;
        if(iterator <= amount){
            scanf("%d", &data);
            
        }else{
            data = -200; //Padding dummy value;
        }
        
        /*Fill the data acquired into the buffer*/
        for(int index = 0; index <= 5; index ++){
            buffer[index] = buffer[index + 1];
        }
        buffer[6] = data;
            
        if(iterator >= 4 && iterator <= amount + 3){
            centre_valid = 1;
        }
        
        if(centre_valid == 1){
            if(max_found == 0){
                max_value = buffer[3];
                max_found = 1;
                
                for(int index = 0; index < length; index ++){
                    result[index] = buffer[index];
                }
                
            }else{
                if(buffer[3] > max_value){
                    max_value = buffer[3];
                    max_index = iterator - 4;
                    
                    for(int index = 0; index < length; index ++){
                        result[index] = buffer[index];
                    }
                }
            }
        }
    }

    for(int index = 0; index < length; index ++){
        printf("%d ", result[index]);
    }
    
    
    
    
    
//    int buf[length];
//    int result[length];
// //   int max;
//    int first;
//    /*Deal with firsr 3 numbers, boundary*/
//    scanf("%d", &first);
//    buf[0] = first;
//    result[0] = first;
//    max = first;
//    for(int cnt = 1; cnt < 3; cnt++){
//        scanf("%d", &buf[cnt]);
//        result[cnt] = buf[cnt];
//        if(buf[cnt] > max){
//            max = buf[cnt];
//        }
//    }
//    /*Process the subsequent values until meeting the end*/
//    int value;
//    while((value = getchar()) != '\n'){
//        if(value != ' '){
//            value = value - '0';
//            buf[0] = buf[1];
//            buf[1] = buf[2];
//            buf[2] = value;
//            if(buf[1] > max){
//                max = buf[1];
//                for(int cnt = 0; cnt < 3; cnt++){
//                    result[cnt] = buf[cnt];
//                }
//            }
//        }
//    }
//
//    /*Pad the last two values with the dummy ones*/
//    if(buf[2] > max){
//        result[0] = buf[1];
//        result[1] = buf[2];
//        result[2] = -99999;
//    }
//
//    printf("Output\n");
//    for(int cnt =0; cnt < 3; cnt++){
//        printf("%d\n", result[cnt]);
//    }
    return 0;
    
}
