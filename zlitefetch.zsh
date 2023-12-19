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
    echo "Unknown"
  fi
}

function getCPU() {
  if [ `uname -s` = "Darwin" ]; then
    echo `sysctl machdep.cpu.brand_string | sed s/"machdep.cpu.brand_string: "//g`
  elif [ `uname -s` = "Linux" ]; then
    cpuModel=`lscpu | grep "Model name:" | sed -e "s/Model name:[ ]*//g"`
    if [ $cpuModel -ne "" ]; then
      echo $cpuModel
    else
      echo "Unknown"
    fi
  else
    echo "Unknown"
  fi
}

function getRAM() {
  if [ `uname -s` = "Darwin" ]; then
    total=`sysctl hw.memsize | sed -e s/"[a-zA-Z:. ]*"//g | awk '{ printf("%d\n", $1 / 1024) }'`

    free=`vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//'`
    inactive=`vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//'`
    speculative=`vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//'`
    available=$((($free + speculative + $inactive) * 4096 / 1024))
    used=$(($total - $available))

    echo $(kb2gb $used) / $(kb2gb $total) GB
  elif [ `uname -s` = "Linux" ]; then
    total=`cat /proc/meminfo | grep MemTotal: | sedAll kB MemTotal: " "`
    available=`cat /proc/meminfo | grep MemAvailable: | sedAll kB MemAvailable: " "`
    used=$(($total - $available))
    echo $(kb2gb $used) / $(kb2gb $total) GB
  else
    echo "Unknown"
  fi
}

function getDisk() {
  diskTotal=""
  diskUsed=""

  if [ `uname -r | grep WSL` ]; then
    diskTotal=`df --output=source,size`
    diskUsed=`df --output=source,used`

    if [ `echo $diskTotal | grep "C:"` ]; then
      diskTotal=`kb2gb $(echo $diskTotal | grep "C:" | sed -e 's/C:[\\ ]*//g')`
      diskUsed=`kb2gb $(echo $diskUsed | grep "C:" | sed -e 's/C:[\\ ]*//g')`
    else
      diskTotal=`kb2gb $(echo $diskTotal | grep "drvfs" | sed -e 's/drvfs[ ]*//g')`
      diskUsed=`kb2gb $(echo $diskUsed | grep "drvfs" | sed -e 's/drvfs[ ]*//g')`
    fi
  elif [ `uname -s` = "Darwin" ]; then
    diskTotal=`kb2gb $(
      df | grep "/dev/" | awk '
        BEGIN { size=0; }
        $2~/[0-9]/ { size = $2; }
        END { printf "%lu\n", size / 2; }'
    )`
    diskUsed=`kb2gb $(
      df | grep "/dev/" | awk '
        BEGIN { used=0; }
        $3~/[0-9]/ { used += $3; }
        END { printf "%lu\n", used / 2; }'
    )`
  elif [ `uname -s` = "Linux" ]; then
    diskTotal=`kb2gb $(df --total --output=source,size | grep total | sed -e "s/total *//g")`
    diskUsed=`kb2gb $(df --total --output=source,used | grep total | sed -e "s/total *//g")`
  else
    diskTotal="0"
    diskUsed="0"
  fi

  usageRate=`echo $diskTotal $diskUsed | awk '{ printf("%4.1f", 100 * $2 / $1) }'`
  echo $diskUsed / $diskTotal GB "($usageRate%)"
}

function display {
  LANG=en_US

  user="$(whoami)@$(uname -n)"
  os=`getOS`
  karnel=`uname -rs`
  zsh=`zsh --version`
  cpu=`getCPU`
  disk=`getDisk`
  ram=`getRAM`

  info=(
    "${ZLITEFETCH_COLOR}  User   \e[m: $user"
    "${ZLITEFETCH_COLOR}  OS     \e[m: $os"
    "${ZLITEFETCH_COLOR}  Karnel \e[m: $karnel"
    "${ZLITEFETCH_COLOR}  Shell  \e[m: $zsh"
    "${ZLITEFETCH_COLOR}  CPU    \e[m: $cpu"
    "${ZLITEFETCH_COLOR}  Disk   \e[m: $disk"
    "${ZLITEFETCH_COLOR}  RAM    \e[m: $ram"
  )

  logo=()
  osLowerCase=`echo $os | sed 's/.\+/\L\0/'`

  for arg in $@; do
    case $arg in
      "--off" )
        osLowerCase=""
    esac
  done

  case $osLowerCase in
    *mac* )
      green="\033[0m\033[32m"
      yellow="\033[0m\033[33m"
      orange="\033[0m\033[1;31m"
      red="\033[0m\033[31m"
      purple="\033[0m\033[35m"
      skyblue="\033[0m\033[1;36m"
      logo=(
        "${green}                   .:/         \e[m"
        "${green}                 +mMMd         \e[m"
        "${green}               \`dMMMN-         \e[m"
        "${green}               yMMMy.          \e[m"
        "${green}     \`/osso+:-\`sso++syyso:\`    \e[m"
        "${green}   -hMMMMMMMMMMMMMMMMMMMMMNs\`  \e[m"
        "${yellow}  +MMMMMMMMMMMMMMMMMMMMMMMNo\`  \e[m"
        "${yellow} :MMMMMMMMMMMMMMMMMMMMMMMm.    \e[m"
        "${yellow} hMMMMMMMMMMMMMMMMMMMMMMM.     \e[m"
        "${orange} NMMMMMMMMMMMMMMMMMMMMMMM      \e[m"
        "${orange} dMMMMMMMMMMMMMMMMMMMMMMM:     \e[m"
        "${orange} oMMMMMMMMMMMMMMMMMMMMMMMN:    \e[m"
        "${red} \`NMMMMMMMMMMMMMMMMMMMMMMMMh/\` \e[m"
        "${red}  \\MMMMMMMMMMMMMMMMMMMMMMMMMN/ \e[m"
        "${purple}   :NMMMMMMMMMMMMMMMMMMMMMMN/  \e[m"
        "${purple}    \\mMMMMMMMMMMMMMMMMMMMMd.   \e[m"
        "${skyblue}     \`oNMMMMMMmddmMMMMMMm+     \e[m"
        "${skyblue}        -++/-      -/+/-       \e[m"
      )
      ;;

    *debian* )
      red="\033[0m\033[1;31m"
      logo=(
        "${red}            .--.\`..\`           \e[m"
        "${red}        ./oyyyyyyyyys++/.      \e[m"
        "${red}     \`/yyyys+:.....-:+yyyy/\`   \e[m"
        "${red}    :yyyo:\`            :syyy:  \e[m"
        "${red} \` /yy/\`                \`+yyo: \e[m"
        "${red}  oy+\`         -::-.\`     oy+\` \e[m"
        "${red} /ys\`        :/.          -ys  \e[m"
        "${red} yy.        /-        \`   .yy. \e[m"
        "${red} yy         y             .y+  \e[m"
        "${red} ys         o:       \`   .oo\`  \e[m"
        "${red} sy\`       \`.+/\`  \`\`   \`:o:    \e[m"
        "${red} /y:        \`\`:o+:--:/o+-      \e[m"
        "${red} \`sy+.         \`...-\`          \e[m"
        "${red}  .yy+                         \e[m"
        "${red}   .sy:                        \e[m"
        "${red}     /y+\`                      \e[m"
        "${red}      \`+s+.                    \e[m"
        "${red}        \`:++:\`                 \e[m"
        "${red}            .-..\`              \e[m"
      )
      ;;

    *manjaro* )
      green="\033[0m\033[32m"
      logo=(
        "${green}■■■■■■■■■■■■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■■■■■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■■■■■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■■■■■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■              ■■■■■■■■\e[m"
        "${green}■■■■■■■■              ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
        "${green}■■■■■■■■   ■■■■■■■■   ■■■■■■■■\e[m"
      )
      ;;

    *arch* )
      skyblue="\033[0m\033[1;36m"
      blue="\033[0m\033[36m"
      logo=(
        "${skyblue}                /\`              \e[m"
        "${skyblue}               /s+              \e[m"
        "${skyblue}              :sss:             \e[m"
        "${skyblue}             -sssss-            \e[m"
        "${skyblue}             +ssssso-           \e[m"
        "${skyblue}           .+//osssso.          \e[m"
        "${skyblue}          .ossooosssso.         \e[m"
        "${skyblue}         .ossssssssssso.        \e[m"
        "${skyblue}        .oss${blue}sssssssss${skyblue}sso.       \e[m"
        "${skyblue}       .o${blue}sssss+:-:+sssss${skyblue}o.      \e[m"
        "${blue}      .osssss+\`    /ssssso.     \e[m"
        "${blue}     .ossssss\`     \`ssssooo.    \e[m"
        "${blue}    .osssssss\`      osssso+:\`   \e[m"
        "${blue}   -osssoo/:-       -:/+osss+-  \e[m"
        "${blue}  -so+:.\`               \`.:+os- \e[m"
        "${blue} .:.                         .:-\e[m"
      )
      ;;

    *fedora* )
      blue="\033[0m\033[1;36m"
      white="\033[0m\033[37m"
      logo=(
        "${blue}           .^!7?JYYYYYYJ?7!^.          \e[m"
        "${blue}        :!?YYYYYYYYYYYYYYYYYY?!:       \e[m"
        "${blue}     .~JYYYYYYYYYYYYYYYYYYYYYYYYJ~.    \e[m"
        "${blue}    ~JYYYYYYYYYYYYYY${white}5PGBGGP5${blue}YYYYYYJ~   \e[m"
        "${blue}   7YYYYYYYYYYYYYY${white}5B@@@&&@@&B5${blue}YYYYYY7  \e[m"
        "${blue}  7YYYYYYYYYYYYYYY${white}&@@B5${blue}YY${white}5B@@&${blue}YYYYYYY7 \e[m"
        "${blue} ~YYYYYYYYYYYYYYY${white}5@@@5${blue}YYYY${white}5&@&5${blue}YYYYYYY~\e[m"
        "${blue} JYYYYYYYYYYYYYYY${white}5@@@5${blue}YYYYY${white}555${blue}YYYYYYYYJ\e[m"
        "${blue} YYYYYYYYY${white}PGB###${blue}G${white}5@@@####5${blue}YYYYYYYYYYYYY\e[m"
        "${blue} YYYYYYY${white}G&@@&###${blue}P${white}5@@@####5${blue}YYYYYYYYYYYYJ\e[m"
        "${blue} YYYYYY${white}B@@#5${blue}YYYYY${white}5@@@5${blue}YYYYYYYYYYYYYYYY!\e[m"
        "${blue} YYYYYY${white}@@@5J${blue}YYYYY${white}5@@@5${blue}YYYYYYYYYYYYYYY? \e[m"
        "${blue} YYYYYY${white}B@@#P${blue}YYYY${white}P#@@B${blue}YYYYYYYYYYYYYYY7  \e[m"
        "${blue} YYYYYYY${white}G&@@@&&&@@&G${blue}YYYYYYYYYYYYYYJ~   \e[m"
        "${blue} YYYYYYYYY${white}5GBBBBG5${blue}YYYYYYYYYYYYYYJ~.    \e[m"
        "${blue} JYYYYYYYYYYYYYYYYYYYYYYYYYYY?!^       \e[m"
        "${blue} .!JYYYYYYYYYYYYYYYYYYYJ?7!^.          \e[m"
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

display $@
