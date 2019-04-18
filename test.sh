my_name="xzy"

echo $my_name

#readonly variable
readonly my_name
#can not use like this
# my_name="xxx"

#delete this variable,
#but still can not do like this
#cause my_name is readonly varible
# unset my_name

#string variable
str_1='my name is \"xzy\"'
str_2="my name is \"xzy\""
echo $str_1
echo $str_2

#string join
str_3="hello,$str_2"
echo $str_3

#string length
echo ${#str_3}

#get substring
#first variable is start
#second variable is the length of substring
echo ${str_3:18:3}

#search substring
#find the first index of x,z or y
echo `expr index "$str_3" xzy`

#array
val_1=1
val_2=2
val_3=3
array=($val_1,$val_2,$val_3)

#get all elements
echo ${array[@]}

#get length of array
echo ${#array[*]}

#get parameter pass to shell script 
#$0 is file's name
echo $0
echo $1
#$# is count of parameter
echo $#
#$$ is progress'ID
echo $$

#process control
if test $str_3 =  $str_2
then 
	echo "same"
else
	echo "diff"
fi

for var in array
do
	echo $var
done

#function
func(){
	echo "function"
	echo $1
}

func xzy

#include file
. ./test_2.sh

echo $url
