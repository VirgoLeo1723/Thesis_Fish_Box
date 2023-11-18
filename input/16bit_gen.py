import random

weight_1 = open("weight_bram_1.coe", "w")
weight_2 = open("weight_bram_2.coe", "w")
weight_3 = open("weight_bram_3.coe", "w")
weight_4 = open("weight_bram_4.coe", "w")
feature_1 = open("feature_bram_1.coe", "w")
feature_2 = open("feature_bram_2.coe", "w")
feature_3 = open("feature_bram_3.coe", "w")
feature_4 = open("feature_bram_4.coe", "w")

file_list = [weight_1, weight_2, weight_3, weight_4,feature_1, feature_2, feature_3,feature_4]


for file in file_list:
    file.writelines("memory_initialization_radix=16;\n")
    file.writelines("memory_initialization_vector=\n")
    for i in range(0,8192):
        gen_temp=""
        for j in range (0,4):
            temp = random.randrange(0,15,1)
            if (temp==10): temp ="A"
            elif (temp==11): temp ="B"
            elif (temp==12): temp ="C"
            elif (temp==13): temp ="D"
            elif (temp==14): temp ="E"
            elif (temp==15): temp ="F"
            gen_temp = f"{gen_temp}0{temp}"
        if (i!=8191): file.writelines(f"{gen_temp},\n")
        else : file.writelines(f"{gen_temp};\n")
    file.close()
    print(f"end of file")
