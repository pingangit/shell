#/basn/bin

# Method 1
free | awk '/Mem/{printf("used: %.2f%"), $3/$2*100} /buffers\/cache/{printf(", buffers: %.2f%"), $4/($3+$4)*100} /Swap/{printf(", swap: %.2f%"), $3/$2*100}'

# Method 2
free | grep Mem | awk '{print $3/$2 * 100.0}'


