#!/bin/zsh

function sedAll() {
  input=`cat -`
  for val in $@; do
    input=`echo ${input} | sed -e "s/$val//g"`
  done
  echo $input
}

function kb2gb() {
  bc <<< "scale=1; $1 / (1024 * 1024)"
}

function getRAM() {
  memTotal=`cat /proc/meminfo | grep MemTotal: | sedAll kB MemTotal: " "`
  memFree=`cat /proc/meminfo | grep MemFree: | sedAll kB MemFree: " "`
  memUsed=$(($memTotal - $memFree))
  echo $(kb2gb $memUsed) / $(kb2gb $memTotal) GB
}

function getDisk() {
  diskTotal=`df --total --output=source,size | grep total | sed -e "s/total *//g"`
  diskUsed=`df --total --output=source,used | grep total | sed -e "s/total *//g"`
  echo $(kb2gb $diskUsed) / $(kb2gb $diskTotal) GB
}

function display {
  user="$(whoami)@$(uname -n)"
  os=`cat /etc/os-release | grep PRETTY_NAME | sedAll PRETTY_NAME= '"'`
  karnel=`uname -rs`
  zsh=`zsh --version`
  cpu=`lscpu | grep "Model name:" | sed -e "s/Model name: *//g"`
  disk=`getDisk`
  ram=`getRAM`

  info=(
    "User   : $user"
    "OS     : $os"
    "Karnel : $karnel"
    "Shell  : $zsh"
    "CPU    : $cpu"
    "Disk   : $disk"
    "RAM    : $ram"
  )

  logo=()
  osLowerCase=`echo $os | sed 's/.\+/\L\0/'`

  case $osLowerCase in
    *arch* )
      c1="\033[0m\033[1;36m"
      c2="\033[0m\033[36m"
      logo=(
        "${c1}                /\`              \e[m"
        "${c1}               /s+              \e[m"
        "${c1}              :sss:             \e[m"
        "${c1}             -sssss-            \e[m"
        "${c1}             +ssssso-           \e[m"
        "${c1}           .+//osssso.          \e[m"
        "${c1}          .ossooosssso.         \e[m"
        "${c1}         .ossssssssssso.        \e[m"
        "${c1}        .oss${c2}sssssssss${c1}sso.       \e[m"
        "${c1}       .o${c2}sssss+:-:+sssss${c1}o.      \e[m"
        "${c2}      .osssss+\`    /ssssso.     \e[m"
        "${c2}     .ossssss\`     \`ssssooo.    \e[m"
        "${c2}    .osssssss\`      osssso+:\`   \e[m"
        "${c2}   -osssoo/:-       -:/+osss+-  \e[m"
        "${c2}  -so+:.\`               \`.:+os- \e[m"
        "${c2} .:.                         .:-\e[m"
      )
      ;;

  esac

  echo ""
  for ix in `seq ${#logo[@]}`; do
    echo ${logo[$ix]} ${info[$ix]}
  done
}

display
