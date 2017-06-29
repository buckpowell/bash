#!/bin/bash


#transponder data 
=========================================================================

echo "preparing transponder working files..."

#prepare files for joining

cat 201610_transponder.txt | grep -v ^0 | sed -e's/,/~/1' | sort -t~ -k1,1 -u > transponder
cat 201610_activity.txt | egrep -ve'^(-|0)' | sed -e's/,/~/1' | sort -t~ -k1,1 -u > activity


#join the transponder records with the ufm_activity records
join -t~ -11 -21  transponder activity > transponder_activity

]
#prepare file for joining

cat 201610_history.txt | grep -v ^0 | sed -e's/,/~/1' | sort -t~ -k1,1  -u > history


#combine all the txt files

join -t~ -11 -21 -a1 transponder_activity history | tr '~' ',' | awk -F, 'NF!=5{print $0",NULL,NULL"}NF==5{print}'| cut -d, -f2- | sort -u >  transponder_final.txt

echo "getting transponder unique count..."
#count number of unique transponder records
transponder_unique=$(cut -d, -f1 transponder_final.txt | sort -u | wc -l)

echo "getting transponder average transactions..."
transponder_trans=$(cut -f 1 transponder_final.txt | sort | uniq | wc -l)

transponder_avg_trans=$(printf %.2f $(echo "$transponder_trans/$transponder_unique" | bc -l))

echo "getting transponder average tolls..."
transponder_avg_tolls=$(awk -F, '{ total += $3; count++ } END { print total/count }' transponder_final.txt)
transponder_avg_tolls_d=$(printf %.2f $(echo "$transponder_avg_trans" | bc -l))

#Commuter penetration for transponder-----------------------------------
echo "getting transponder commuter penetration..."

#get the transponder and datetime
awk -F, '{print $1, $2}' transponder_final.txt > transponder_trans.txt

#get the am records

egrep ' 0[0-9]:| 1[0-1]:' transponder_trans.txt | sort -u -k1,1 > transponder_trans_am.txt

#get the pm records

egrep ' 1[2-9]:| 2[0-3]:' transponder_trans.txt | sort -u -k1,1 > transponder_trans_pm.txt

#get the unique transponder transactions

join -11 -21  transponder_trans_am.txt transponder_trans_pm.txt > transponder_pene.txt

#get the transponder count

t=$(cat transponder_pene.txt | wc -l)

#non-revenue transactions 
echo "getting transponder non-rev count..."

#split lpns into exempt records

awk -F, '$4 == "EXEMPT" { print $1, $2, $3, $4 }' transponder_final.txt > transponder_non_rev.txt


echo "getting transponder average transactions..."

#count number of lpn non-rev transactions

transponder_non_rev=$(cut -d, -f1 transponder_non_rev.txt | sort -u | wc -l)


echo "cleaning up transponder files..."
rm -f transponder

rm -f activity

rm -f transponder_activity

rm -f history

rm -f transponder_final.txt

rm -f transponder_trans.txt

rm -f transponder_trans_am.txt

rm -f transponder_trans_pm.txt

rm -f transponder_pene.txt

rm -f transponder_non_rev.txt


#lpn data ===================================================================================

echo "preparing lpn working files..."


#prepare files for joining

cat 201610_lpn.txt | grep -v ^0 | sed -e's/,/~/1' | sort -t~ -k1,1 -u > lpn
cat 201610_activity.txt | egrep -ve'^(-|0)' | sed -e's/,/~/1' | sort -t~ -k1,1 -u > activity

#join the lpn/transponder records with the ufm_activity records
join -t~ -11 -21  lpn activity > lpn_activity

#prepare file for joining
cat 201610_history.txt | grep -v ^0 | sed -e's/,/~/1' | sort -t~ -k1,1  -u > history

#combine all the txt files
join -t~ -11 -21 -a1 lpn_activity history | tr '~' ',' | awk -F, 'NF!=5{print $0",NULL,NULL"}NF==5{print}'| cut -d, -f2- | sort -u >  lpn_final.txt

echo "getting lpn unique count..."

#count number of unique lpn records
lpn_unique=$(cut -d, -f1 lpn_final.txt | sort -u | wc -l)

echo "getting lpn average transactions..."
lpn_trans=$(cut -f 1 lpn_final.txt | sort | uniq | wc -l)

lpn_avg_trans=$(printf %.2f $(echo "$lpn_trans/$lpn_unique" | bc -l))

echo "getting lpn average tolls..."
lpn_avg_tolls=$(awk -F, '{ total += $3; count++ } END { print total/count }' lpn_final.txt)
lpn_avg_tolls_d=$(printf %.2f $(echo "$lpn_avg_tolls" | bc -l))


#Commuter penetration for lpn--------------------------------------------------

echo "getting lpn commuter penetration..."


#get the lpn and datetime

awk -F, '{print $1, $2}' lpn_final.txt > lpn_trans.txt

#get the lpn am records

egrep ' 0[0-9]:| 1[0-1]:' lpn_trans.txt | sort -u -k1,1 > lpn_trans_am.txt

#get the lpn pm records

egrep ' 1[2-9]:| 2[0-3]:' lpn_trans.txt | sort -u -k1,1 > lpn_trans_pm.txt

#get the unique lpn transactions

join -11 -21  lpn_trans_am.txt lpn_trans_pm.txt > lpn_pene.txt


l=$(cat lpn_pene.txt | wc -l)


echo "getting lpn non-rev count..."


#split lpns into exempt records

awk -F, '$4 == "EXEMPT" { print $1, $2, $3, $4 }' lpn_final.txt > lpn_non_rev.txt


#count number of lpn non-rev transactions

lpn_non_rev=$(cut -d, -f1 lpn_non_rev.txt | sort -u | wc -l)


rm -f lpn

rm -f activity

rm -f lpn_activity

rm -f history

rm -f lpn_final.txt

rm -f lpn_trans.txt

rm -f lpn_trans_am.txt

rm -f lpn_trans_pm.txt

rm -f lpn_pene.txt

rm -f lpn_non_rev.txt


echo "computing totals..."

total=$(($l+$t))

t_percent=$(printf %.2f $(echo "$t/$total*100" | bc -l ))

l_percent=$(printf %.2f $(echo "$l/$total*100" | bc -l))


transponder_header="Transponder"

lpn_header="License_Plate"


echo "writing to output file..."

echo $transponder_header $lpn_header $transponder_unique $lpn_unique $transponder_avg_trans $lpn_avg_trans $transponder_avg_tolls_d $lpn_avg_tolls_d $t_percent $l_percent $transponder_non_rev $lpn_non_rev > output.txt


printf "%14s %14s\n" 
$(cat output.txt) > output.csv

rm -f output.txt

echo "finished"

