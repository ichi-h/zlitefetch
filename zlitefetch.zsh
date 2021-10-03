#!/bin/zsh

function sedAll() {
  input=`cat -`
  for val in $@; do
    input=`echo ${input} | sed -e "s/$val//g"`
  done
  echo $input
}

function kb2gb() {
  echo $1 | awk '{ printf("%4.1f", $1 / (1024 * 1024)) }'
}

function getOS() {
  if [ `uname -s` = "Darwin" ]; then
    name=`sw_vers -productName`
    ver=`sw_vers -productVersion`
    echo "$name $ver"
  elif [ `uname -s` = "Linux" ]; then
    echo `cat /etc/os-release | grep PRETTY_NAME | sedAll PRETTY_NAME= '"'`
  else
    echo "unknown"
  fi
}

function getCPU() {
  if [ `uname -s` = "Darwin" ]; then
    echo `sysctl machdep.cpu.brand_string | sed s/"machdep.cpu.brand_string: "//g`
  elif [ `uname -s` = "Linux" ]; then
    echo `lscpu | grep "Model name:" | sed -e "s/Model name:[ ]*//g"`
  else
    echo "unknown"
  fi
}

function getRAM() {
  if [ `uname -s` = "Darwin" ]; then
    memTotal=`sysctl hw.memsize | sed -e s/"[a-zA-Z:. ]*"//g | awk '{ printf("%d\n", $1 / 1024) }'`

    free=`vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//'`
    inactive=`vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//'`
    speculative=`vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//'`
    memUnused=$((($free + speculative + $inactive) * 4096 / 1024))
    memUsed=$(($memTotal - $memUnused))

    echo $(kb2gb $memUsed) / $(kb2gb $memTotal) GB
  elif [ `uname -s` = "Linux" ]; then
    memTotal=`cat /proc/meminfo | grep MemTotal: | sedAll kB MemTotal: " "`
    memFree=`cat /proc/meminfo | grep MemFree: | sedAll kB MemFree: " "`
    memUsed=$(($memTotal - $memFree))
    echo $(kb2gb $memUsed) / $(kb2gb $memTotal) GB
  else
    echo "unknown"
  fi
}

function getDisk() {
  if [ `uname -r | grep WSL` ]; then
    diskTotal=`df --output=source,size`
    diskUsed=`df --output=source,used`

    if [ `echo $diskTotal | grep "C:"` ]; then
      diskTotal=`echo $diskTotal | grep "C:" | sed -e 's/C:[\\ ]*//g'`
      diskUsed=`echo $diskUsed | grep "C:" | sed -e 's/C:[\\ ]*//g'`
    else
      diskTotal=`echo $diskTotal | grep "drvfs" | sed -e 's/drvfs[ ]*//g'`
      diskUsed=`echo $diskUsed | grep "drvfs" | sed -e 's/drvfs[ ]*//g'`
    fi

    echo $(kb2gb $diskUsed) / $(kb2gb $diskTotal) GB
  elif [ `uname -s` = "Darwin" ]; then
    diskTotal=$(
      df | grep "/dev/" | awk '
        BEGIN { size=0; }
        $2~/[0-9]/ { size = $2; }
        END { printf "%lu\n", size / 2; }'
    )
    diskUsed=$(
      df | grep "/dev/" | awk '
        BEGIN { used=0; }
        $3~/[0-9]/ { used += $3; }
        END { printf "%lu\n", used / 2; }'
    )
    echo $(kb2gb $diskUsed) / $(kb2gb $diskTotal) GB
  elif [ `uname -s` = "Linux" ]; then
    diskTotal=`df --total --output=source,size | grep total | sed -e "s/total *//g"`
    diskUsed=`df --total --output=source,used | grep total | sed -e "s/total *//g"`
    echo $(kb2gb $diskUsed) / $(kb2gb $diskTotal) GB
  else
    echo "unknown"
  fi
}

function display {
  user="$(whoami)@$(uname -n)"
  os=`getOS`
  karnel=`uname -rs`
  zsh=`zsh --version`
  cpu=`getCPU`
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
    *mac* )
      c1="\033[0m\033[32m"
      c2="\033[0m\033[33m"
      c3="\033[0m\033[1;31m"
      c4="\033[0m\033[31m"
      c5="\033[0m\033[35m"
      c6="\033[0m\033[1;36m"
      logo=(
        "${c1}                   .:/         \e[m"
        "${c1}                 +mMMd         \e[m"
        "${c1}               \`dMMMN-         \e[m"
        "${c1}               yMMMy.          \e[m"
        "${c1}     \`/osso+:-\`sso++syyso:\`    \e[m"
        "${c1}   -hMMMMMMMMMMMMMMMMMMMMMNs\`  \e[m"
        "${c2}  +MMMMMMMMMMMMMMMMMMMMMMMNo\`  \e[m"
        "${c2} :MMMMMMMMMMMMMMMMMMMMMMMm.    \e[m"
        "${c2} hMMMMMMMMMMMMMMMMMMMMMMM.     \e[m"
        "${c3} NMMMMMMMMMMMMMMMMMMMMMMM      \e[m"
        "${c3} dMMMMMMMMMMMMMMMMMMMMMMM:     \e[m"
        "${c3} oMMMMMMMMMMMMMMMMMMMMMMMN:    \e[m"
        "${c4} \`NMMMMMMMMMMMMMMMMMMMMMMMMh/\` \e[m"
        "${c4}  \\MMMMMMMMMMMMMMMMMMMMMMMMMN/ \e[m"
        "${c5}   :NMMMMMMMMMMMMMMMMMMMMMMN/  \e[m"
        "${c5}    \\mMMMMMMMMMMMMMMMMMMMMd.   \e[m"
        "${c6}     \`oNMMMMMMmddmMMMMMMm+     \e[m"
        "${c6}        -++/-      -/+/-       \e[m"
      )
      ;;

    *debian* )
      c1="\033[0m\033[1;31m"
      logo=(
        "${c1}            .--.\`..\`           \e[m"
        "${c1}        ./oyyyyyyyyys++/.      \e[m"
        "${c1}     \`/yyyys+:.....-:+yyyy/\`   \e[m"
        "${c1}    :yyyo:\`            :syyy:  \e[m"
        "${c1} \` /yy/\`                \`+yyo: \e[m"
        "${c1}  oy+\`         -::-.\`     oy+\` \e[m"
        "${c1} /ys\`        :/.          -ys  \e[m"
        "${c1} yy.        /-        \`   .yy. \e[m"
        "${c1} yy         y             .y+  \e[m"
        "${c1} ys         o:       \`   .oo\`  \e[m"
        "${c1} sy\`       \`.+/\`  \`\`   \`:o:    \e[m"
        "${c1} /y:        \`\`:o+:--:/o+-      \e[m"
        "${c1} \`sy+.         \`...-\`          \e[m"
        "${c1}  .yy+                         \e[m"
        "${c1}   .sy:                        \e[m"
        "${c1}     /y+\`                      \e[m"
        "${c1}      \`+s+.                    \e[m"
        "${c1}        \`:++:\`                 \e[m"
        "${c1}            .-..\`              \e[m"
      )
      ;;

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

    *)
      logo=("" "" "" "" "" "" "");;

  esac

  echo ""
  infoLen=${#info[@]}
  logoLen=${#logo[@]}
  for i in `seq $logoLen`; do
    j=`echo $i $logoLen $infoLen | awk '{ printf("%d\n", $1 - ($2 / 2) + ($3 / 2) + 0.5) }'`
    if [ $j -lt 0 ]; then
      j=0
    fi
    echo ${logo[$i]} ${info[$j]}
  done
}

display
